import ARKit
import AVFoundation
import RealityKit
import SwiftUI

/// Delays AR construction until the cover is actually on screen —
/// iOS 26 TabView can preload `fullScreenCover` content and trip the camera prompt on Today.
struct QiblaARGate: View {
    let qiblaBearing: Double
    let distanceKm: Double
    @State private var armed = false

    var body: some View {
        Group {
            if armed {
                QiblaARView(qiblaBearing: qiblaBearing, distanceKm: distanceKm)
            } else {
                MihrabColor.abyss.ignoresSafeArea()
            }
        }
        .onAppear { armed = true }
    }
}

/// AR Qibla: camera + a thin 2D HUD. No chunky debug meshes.
struct QiblaARView: View {
    let qiblaBearing: Double
    let distanceKm: Double

    @Environment(\.dismiss) private var dismiss
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL

    @State private var cameraDenied = false
    @State private var hasLockedOn = false
    @State private var burstTrigger = 0
    @State private var lastTickDegree = 0

    private var heading: Double { locationManager.smoothedHeading }
    private var dialHeading: Double { locationManager.continuousHeading }
    private var qiblaDelta: Double { QiblaMath.shortestDelta(from: heading, to: qiblaBearing) }
    private var isAligned: Bool { abs(qiblaDelta) <= 8 }

    var body: some View {
        ZStack {
            if cameraDenied {
                fallback
            } else {
                QiblaARCamera()
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                topBar
                if isAligned {
                    lockBanner
                        .padding(.top, 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    Text(L10n.alignQibla)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(MihrabColor.textPrimary)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(.black.opacity(0.45)))
                        .padding(.top, 10)
                }

                Spacer()

                hudCompass
                    .padding(.bottom, 10)

                if distanceKm > 0 {
                    Text(L10n.kmToMakkah(Int(distanceKm.rounded())))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(MihrabColor.textPrimary)
                        .padding(.bottom, 8)
                }

                Text(L10n.cameraPrivacy)
                    .font(.caption2)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
            .animation(reduceMotion ? nil : MihrabMotion.snappyAnimation, value: isAligned)
        }
        .task {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: break
            case .notDetermined:
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                cameraDenied = !granted
            default:
                cameraDenied = true
            }
        }
        .onAppear {
            locationManager.startHeading()
        }
        .onDisappear { locationManager.stopHeading() }
        .onChange(of: isAligned) { _, aligned in
            if aligned && !hasLockedOn {
                hasLockedOn = true
                HapticsEngine.shared.qiblaLockOn()
                burstTrigger += 1
            } else if !aligned {
                hasLockedOn = false
            }
        }
        .onChange(of: heading) { _, newHeading in
            let bucket = Int(newHeading) / 5
            if bucket != lastTickDegree {
                lastTickDegree = bucket
                HapticsEngine.shared.compassTick()
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(MihrabColor.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(MihrabColor.moss.opacity(0.8)))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(heading.rounded()))°")
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(isAligned ? MihrabColor.mint : MihrabColor.textPrimary)
                Text("\(Int(qiblaBearing.rounded()))° \(L10n.cardinal(for: qiblaBearing))")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(MihrabColor.mint)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Capsule().fill(.black.opacity(0.45)))
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var lockBanner: some View {
        Label(L10n.facingQibla, systemImage: "checkmark")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(MihrabColor.abyss)
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background(Capsule().fill(MihrabColor.mint))
    }

    private var hudCompass: some View {
        ZStack {
            Circle()
                .strokeBorder(MihrabColor.textPrimary.opacity(0.35), lineWidth: 1)
                .frame(width: 128, height: 128)

            Image("qibla-arrow")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .rotationEffect(.degrees(qiblaDelta))
                .opacity(isAligned ? 1 : 0.88)
                .accessibilityHidden(true)
        }
        .frame(width: 140, height: 140)
    }

    private var fallback: some View {
        ZStack {
            AuroraBackground()
            VStack(spacing: 18) {
                QiblaCompassDial(
                    heading: heading,
                    dialHeading: dialHeading,
                    qiblaBearing: qiblaBearing,
                    isAligned: isAligned,
                    burstTrigger: burstTrigger,
                    reduceMotion: reduceMotion
                )
                .frame(width: 260, height: 260)

                Text(L10n.arNeedsCamera)
                    .font(.headline)
                    .foregroundStyle(MihrabColor.textPrimary)
                Text(L10n.arCameraBody)
                    .font(.subheadline)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button(L10n.openSettings) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .background(Capsule().fill(MihrabColor.emerald))
                    .foregroundStyle(.white)

                    Button(L10n.backToCompass) { dismiss() }
                        .padding(.horizontal, 18).padding(.vertical, 12)
                        .background(Capsule().fill(MihrabColor.moss))
                        .foregroundStyle(MihrabColor.textPrimary)
                }
            }
            .padding(28)
            .mihrabSolidCard(cornerRadius: 28)
            .padding(24)
        }
    }
}

private struct QiblaARCamera: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.worldAlignment = .gravityAndHeading
        arView.session.run(config)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
