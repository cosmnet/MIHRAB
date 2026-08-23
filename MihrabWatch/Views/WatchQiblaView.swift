import CoreLocation
import SwiftUI

/// Qibla on the wrist — and an honest answer when the wrist cannot give one.
///
/// The rule this screen exists to keep: **never draw a confident needle on top
/// of a sensor that cannot support it.** Three refusals, in order:
///
/// 1. `CLLocationManager.headingAvailable()` is `false` — this watch has no
///    magnetometer. No needle at all; the user is sent to the iPhone.
/// 2. There is no coordinate, so there is no bearing to point at.
/// 3. `headingAccuracy` is negative or wide — the compass needs calibrating and
///    says so, rather than pointing somewhere plausible and wrong.
///
/// Only past all three does a needle appear. When the heading is magnetic
/// rather than true north, that is disclosed on screen: the local declination
/// is several degrees across Turkey and Europe and far more near the poles.
struct WatchQiblaView: View {

    @Environment(WatchAppModel.self) private var model
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    @State private var provider = WatchLocationProvider.shared
    @State private var lastNudge = Date.distantPast
    @State private var wasAligned = false

    /// Inside this many degrees the user is facing the Qibla. Wider than the
    /// phone's tolerance on purpose: a wrist is never as steady as a held phone,
    /// and a threshold that flickers is worse than one that is slightly loose.
    private let alignedTolerance: Double = 5

    var body: some View {
        NavigationStack {
            Group {
                if !provider.hasCompass {
                    ScrollView {
                        WatchNotice(symbol: "iphone.radiowaves.left.and.right",
                                    title: L10n.wQiblaNoCompass,
                                    detail: L10n.wQiblaNoCompassDetail)
                    }
                } else if let bearing = bearing {
                    compass(bearing: bearing)
                } else {
                    ScrollView {
                        WatchNotice(symbol: "location.slash",
                                    title: L10n.wNoLocation,
                                    detail: model.isWaitingForPhone ? L10n.wWaitingForPhone : L10n.wNoLocationDetail)
                    }
                }
            }
            .navigationTitle(L10n.wQibla)
            .containerBackground(WatchPalette.qiblaGradient, for: .navigation)
        }
        .onAppear {
            provider.startLocation()
            provider.startHeading()
        }
        .onDisappear {
            provider.stopHeading()
            provider.stopLocation()
            wasAligned = false
        }
    }

    // MARK: - Inputs

    private var fallbackCoordinate: CLLocationCoordinate2D? {
        guard let s = model.settings, let lat = s.latitude, let lon = s.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    private var bearing: Double? {
        provider.qiblaBearing(fallback: fallbackCoordinate)
    }

    /// Signed angle from where the wrist points to the Qibla, in (-180, 180].
    private func delta(_ bearing: Double) -> Double? {
        guard let heading = provider.heading else { return nil }
        return QiblaMath.shortestDelta(from: heading, to: bearing)
    }

    // MARK: - Compass

    @ViewBuilder
    private func compass(bearing: Double) -> some View {
        let delta = delta(bearing)
        let aligned = delta.map { abs($0) <= alignedTolerance } ?? false

        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(MihrabColor.moss, lineWidth: 3)

                // Fixed target mark at the top: the user turns until the needle
                // reaches it. Rotating the *needle* rather than the dial is what
                // makes this usable without looking — the haptics do the rest.
                Image(systemName: "triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(aligned ? MihrabColor.emerald : MihrabColor.textTertiary)
                    .offset(y: -46)

                if let delta {
                    QiblaNeedle(aligned: aligned)
                        .rotationEffect(.degrees(delta))
                        // Always-On: the screen is dimmed and updates are
                        // throttled to about once a minute, so an animation
                        // here would only ever be seen mid-jump. Skip it.
                        .animation(isLuminanceReduced ? nil : MihrabMotion.compassAnimation,
                                   value: delta)
                } else {
                    Image(systemName: "location.north.line")
                        .foregroundStyle(MihrabColor.textTertiary)
                }

                VStack(spacing: 0) {
                    Text("\(Int(bearing.rounded()))°")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(aligned ? MihrabColor.sprout : MihrabColor.textPrimary)
                    Text(L10n.wQibla)
                        .font(.caption2)
                        .foregroundStyle(MihrabColor.textTertiary)
                }
            }
            .frame(width: 104, height: 104)
            .accessibilityElement()
            .accessibilityLabel(L10n.wQiblaBearing(Int(bearing.rounded())))
            .accessibilityValue(aligned ? L10n.wQiblaAligned : L10n.wQiblaAlign)

            caption(aligned: aligned)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: provider.heading) { _, _ in
            guard let delta = self.delta(bearing) else { return }
            react(to: delta)
        }
    }

    @ViewBuilder
    private func caption(aligned: Bool) -> some View {
        VStack(spacing: 2) {
            if provider.isCalibrating {
                Text(L10n.wCalibrate)
                    .foregroundStyle(MihrabColor.brass)
            } else if aligned {
                Text(L10n.wQiblaAligned)
                    .foregroundStyle(MihrabColor.sprout)
            } else {
                Text(L10n.wQiblaAlign)
                    .foregroundStyle(MihrabColor.textSecondary)
            }
            if !provider.isTrueNorth && provider.heading != nil {
                Text(L10n.wQiblaMagneticOnly)
                    .foregroundStyle(MihrabColor.textTertiary)
            }
        }
        .font(.caption2)
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.7)
        .padding(.horizontal, 6)
    }

    // MARK: - Haptic guidance

    /// The point of the whole screen: find the Qibla **without looking**.
    ///
    /// Ticks get closer together as the needle narrows, and one `.success`
    /// fires on arrival — once, on the transition, so a hand that wobbles on
    /// the boundary does not buzz continuously.
    private func react(to delta: Double) {
        let magnitude = abs(delta)
        let aligned = magnitude <= alignedTolerance

        if aligned {
            if !wasAligned {
                wasAligned = true
                WatchHaptics.success()
            }
            return
        }
        // Hysteresis: leave the aligned state a little wider than entering it.
        if wasAligned && magnitude > alignedTolerance * 1.8 {
            wasAligned = false
        }

        guard magnitude < 60, !isLuminanceReduced else { return }
        // 60° away → roughly one tick a second; 6° away → about six a second.
        let interval = max(0.16, magnitude / 60)
        guard Date().timeIntervalSince(lastNudge) >= interval else { return }
        lastNudge = Date()
        WatchHaptics.nudge()
    }
}

private struct QiblaNeedle: View {
    let aligned: Bool

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "location.north.fill")
                .font(.title3)
                .foregroundStyle(aligned ? MihrabColor.emerald : MihrabColor.brass)
            Rectangle()
                .fill(MihrabColor.textTertiary.opacity(0.5))
                .frame(width: 1.5, height: 30)
        }
        .offset(y: -18)
    }
}
