import CoreLocation
import SwiftUI

struct QiblaCompassView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var showsAREntry: Bool = true

    @State private var showAR = false
    @State private var hasLockedOn = false
    @State private var lastTickDegree = 0
    @State private var burstTrigger = 0

    private var qiblaBearing: Double {
        guard let c = locationManager.effectiveCoordinate else { return 0 }
        return QiblaMath.bearing(fromLatitude: c.latitude, longitude: c.longitude)
    }

    private var distanceKm: Double {
        guard let c = locationManager.effectiveCoordinate else { return 0 }
        return QiblaMath.distanceToMakkah(fromLatitude: c.latitude, longitude: c.longitude)
    }

    private var heading: Double { locationManager.smoothedHeading }
    private var dialHeading: Double { locationManager.continuousHeading }

    private var qiblaDelta: Double {
        QiblaMath.shortestDelta(from: heading, to: qiblaBearing)
    }

    private var isAligned: Bool { abs(qiblaDelta) <= 3 }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground(ramadanMode: theme.isRamadanMode)

                VStack(spacing: 20) {
                    Spacer(minLength: 8)

                    if locationManager.effectiveCoordinate == nil {
                        MihrabEmptyState(
                            symbol: "location.slash",
                            title: L10n.locationNeeded,
                            message: L10n.locationNeededBody,
                            retryTitle: L10n.enableLocation
                        ) {
                            locationManager.requestAuthorization()
                            locationManager.startUpdating()
                        }
                        .padding(.horizontal, 24)
                    } else {
                        VStack(spacing: 20) {
                            QiblaCompassDial(
                                heading: heading,
                                dialHeading: dialHeading,
                                qiblaBearing: qiblaBearing,
                                isAligned: isAligned,
                                burstTrigger: burstTrigger,
                                reduceMotion: reduceMotion
                            )
                            .frame(width: 300, height: 300)
                            .onTapGesture {
                                guard showsAREntry else { return }
                                HapticsEngine.shared.light()
                                showAR = true
                            }
                            .accessibilityAddTraits(.isButton)
                            .accessibilityHint(Text(L10n.viewInAR))

                            readout
                        }
                        .padding(20)
                        .mihrabCardScene("qibla-bg", opacity: 0.45)
                        .mihrabCard()
                    }

                    Spacer()
                }
                .padding(.bottom, showsAREntry ? MihrabSpace.tabClearance : 32)

                if showsAREntry, locationManager.effectiveCoordinate != nil {
                    VStack {
                        Spacer()
                        Button { showAR = true } label: {
                            Label(L10n.viewInAR, systemImage: "camera.viewfinder")
                                .font(.subheadline.weight(.semibold))
                                .frame(minHeight: MihrabSpace.hit)
                                .padding(.horizontal, 20)
                                .glassEffect(.regular.interactive(), in: .capsule)
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, MihrabSpace.tabClearance)
                    }
                }
            }
            .navigationTitle(L10n.tabQibla)
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(isPresented: $showAR) {
            QiblaARGate(qiblaBearing: qiblaBearing, distanceKm: distanceKm)
        }
        .onAppear {
            locationManager.startHeading()
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestAuthorization()
            }
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

    private var readout: some View {
        VStack(spacing: 8) {
            Text("\(Int(heading.rounded()))°")
                .font(MihrabFont.countdown(48))
                .foregroundStyle(isAligned ? MihrabColor.mint : MihrabColor.textPrimary)

            Text(L10n.qiblaDegrees(Int(qiblaBearing.rounded()), L10n.cardinal(for: qiblaBearing)))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(MihrabColor.mint)

            if distanceKm > 0 {
                Label {
                    Text(L10n.kmToMakkah(Int(distanceKm.rounded())))
                } icon: {
                    Image(systemName: "point.topleft.down.to.point.bottomright.curvepath.fill")
                }
                .font(.caption)
                .foregroundStyle(MihrabColor.textTertiary)
            }

            if isAligned {
                Text(L10n.facingQibla)
                    .font(.headline)
                    .foregroundStyle(MihrabColor.mint)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Capsule().fill(MihrabColor.moss))
                    .overlay {
                        Capsule().strokeBorder(MihrabColor.mint.opacity(0.45), lineWidth: 1)
                    }
                    .transition(.opacity.combined(with: .scale))
            } else if locationManager.heading == nil {
                Text(L10n.holdFlat)
                    .font(.caption)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .animation(reduceMotion ? nil : MihrabMotion.snappyAnimation, value: isAligned)
        .accessibilityElement(children: .combine)
    }

}

// MARK: - Dial

struct QiblaCompassDial: View {
    let heading: Double
    let dialHeading: Double
    let qiblaBearing: Double
    let isAligned: Bool
    let burstTrigger: Int
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [MihrabColor.brass.opacity(0.9), MihrabColor.mint.opacity(0.28),
                                 MihrabColor.brass.opacity(0.55), MihrabColor.brass.opacity(0.2),
                                 MihrabColor.brass.opacity(0.9)],
                        center: .center
                    ),
                    lineWidth: 8
                )
                .shadow(color: MihrabColor.brass.opacity(isAligned ? 0.45 : 0.14), radius: isAligned ? 16 : 6)

            Circle()
                .fill(MihrabColor.moss.opacity(0.35))
                .padding(12)
                .glassEffect(.regular, in: .circle)
                .overlay {
                    Circle()
                        .strokeBorder(
                            LinearGradient(colors: [MihrabColor.mint.opacity(0.55), .clear],
                                           startPoint: .top, endPoint: .center),
                            lineWidth: 1
                        )
                        .padding(12)
                }

            MihrabOrnament(name: "compass-rose", opacity: isAligned ? 0.28 : 0.16, side: 268)
                .rotationEffect(.degrees(-dialHeading))
                .animation(reduceMotion ? nil : MihrabMotion.compassAnimation, value: dialHeading)

            ForEach([0.70, 0.52], id: \.self) { scale in
                Circle()
                    .stroke(MihrabColor.brass.opacity(0.16), lineWidth: 0.5)
                    .scaleEffect(scale)
            }

            rotatingFurniture
                .rotationEffect(.degrees(-dialHeading))
                .animation(reduceMotion ? nil : MihrabMotion.compassAnimation, value: dialHeading)

            VStack(spacing: 0) {
                Image("qibla-arrow")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .opacity(isAligned ? 1 : 0.85)
                    .accessibilityHidden(true)
                Spacer()
            }
            .padding(.top, 6)

            if isAligned {
                Circle()
                    .strokeBorder(
                        AngularGradient(colors: [MihrabColor.mint, MihrabColor.emerald, MihrabColor.brass, MihrabColor.mint],
                                        center: .center),
                        lineWidth: 3
                    )
                    .shadow(color: MihrabColor.mint.opacity(reduceMotion ? 0.25 : 0.4), radius: reduceMotion ? 6 : 12)
                    .padding(10)
                    .transition(.opacity)
            }

            if !reduceMotion {
                AmbientTickField(aligned: isAligned)
            }

            ParticleBurst(trigger: burstTrigger)
        }
        .animation(reduceMotion ? nil : MihrabMotion.snappyAnimation, value: isAligned)
    }

    private var rotatingFurniture: some View {
        ZStack {
            ForEach(0..<72, id: \.self) { tick in
                let degrees = Double(tick) * 5
                let major = tick % 18 == 0
                let medium = tick % 6 == 0
                Rectangle()
                    .fill(major ? MihrabColor.brass : MihrabColor.textTertiary.opacity(medium ? 0.7 : 0.35))
                    .frame(width: major ? 2 : 1, height: major ? 16 : (medium ? 11 : 6))
                    .offset(y: -118)
                    .rotationEffect(.degrees(degrees))
            }

            ForEach([0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330], id: \.self) { deg in
                Text("\(deg)")
                    .font(.system(size: 9, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(MihrabColor.textTertiary)
                    .offset(y: -96)
                    .rotationEffect(.degrees(Double(deg)))
                    .rotationEffect(.degrees(dialHeading))
            }

            ForEach(
                Array(zip([0.0, 90.0, 180.0, 270.0],
                          [L10n.compassN, L10n.compassE, L10n.compassS, L10n.compassW])),
                id: \.0
            ) { degrees, label in
                Text(label)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(degrees == 0 ? MihrabColor.brass : MihrabColor.textSecondary)
                    .offset(y: -76)
                    .rotationEffect(.degrees(degrees))
                    .rotationEffect(.degrees(dialHeading))
            }

            Image("qibla-arrow")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .offset(y: -118)
                .rotationEffect(.degrees(qiblaBearing))
                .opacity(isAligned ? 1 : 0.88)
                .scaleEffect(isAligned ? 1.18 : 1)
                .accessibilityHidden(true)

            KaabaGlyph(aligned: isAligned)
                .offset(y: -96)
                .rotationEffect(.degrees(qiblaBearing))
        }
    }
}

// MARK: - Components

private struct KaabaGlyph: View {
    let aligned: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if aligned && !reduceMotion {
                Circle()
                    .fill(MihrabColor.brass.opacity(0.35))
                    .frame(width: 40, height: 40)
                    .blur(radius: 6)
            }
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black)
                .frame(width: 22, height: 22)
                .overlay {
                    Rectangle()
                        .fill(MihrabColor.brass)
                        .frame(height: 3.5)
                        .offset(y: -4)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(MihrabColor.brass, lineWidth: 1.2)
                }
            if aligned {
                Circle()
                    .stroke(MihrabColor.mint.opacity(0.85), lineWidth: 1.5)
                    .frame(width: 34, height: 34)
            }
        }
        .scaleEffect(aligned ? 1.22 : 1)
        .shadow(color: aligned ? MihrabColor.brass.opacity(0.85) : MihrabColor.brass.opacity(0.2), radius: aligned ? 12 : 3)
    }
}

private struct AmbientTickField: View {
    let aligned: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { canvas, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 28
                for i in 0..<24 {
                    let angle = Double(i) * (.pi / 12) + t * (aligned ? 0.35 : 0.08)
                    let pulse = 0.25 + 0.55 * abs(sin(t * 1.4 + Double(i)))
                    let point = CGPoint(
                        x: center.x + cos(angle) * radius,
                        y: center.y + sin(angle) * radius
                    )
                    canvas.fill(
                        Path(ellipseIn: CGRect(x: point.x - 1.4, y: point.y - 1.4, width: 2.8, height: 2.8)),
                        with: .color((aligned ? MihrabColor.mint : MihrabColor.brass).opacity(pulse * 0.7))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Brass + mint spark burst keyed to the lock-on trigger, not wall-clock remainder.
struct ParticleBurst: View {
    let trigger: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startedAt: Date?

    var body: some View {
        TimelineView(.animation(paused: reduceMotion || trigger == 0)) { context in
            Canvas { canvas, size in
                guard !reduceMotion, trigger > 0, let startedAt else { return }
                let elapsed = context.date.timeIntervalSince(startedAt)
                guard elapsed < 1.15 else { return }
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let spark = canvas.resolve(Image("particle-spark"))
                canvas.blendMode = .plusLighter
                for i in 0..<18 {
                    let angle = Double(i) * (2 * .pi / 18) + elapsed * 0.8
                    let distance = 28 + elapsed * 150 + Double(i % 4) * 6
                    let point = CGPoint(
                        x: center.x + cos(angle) * distance,
                        y: center.y + sin(angle) * distance
                    )
                    canvas.opacity = max(0, 1 - elapsed / 1.15)
                    let side: CGFloat = i.isMultiple(of: 2) ? 36 : 24
                    canvas.draw(
                        spark,
                        in: CGRect(x: point.x - side / 2, y: point.y - side / 2, width: side, height: side)
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in startedAt = Date() }
    }
}
