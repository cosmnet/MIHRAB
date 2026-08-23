import SwiftUI

/// The tonal wash that carries the day's journey across the backdrop.
///
/// Two gradients — a soft light source where the sun would be, and a deeper
/// floor rising from the bottom — composited with `.plusLighter` over the
/// emerald base. Because `plusLighter` only ever *adds*, a dark veil (night)
/// changes almost nothing and a warm one (maghrib) tips the whole screen
/// without touching the contrast of the type sitting on top of it.
///
/// Crossfading is done with **opacity on two layers**, never by interpolating
/// colours: opacity is the one thing SwiftUI animates reliably here, so the
/// boundary between two prayers dissolves over several seconds instead of
/// snapping.
struct DaySegmentVeil: View {
    var segment: DaySegment?
    var ramadanMode: Bool
    var intensity: AppSettings.BackdropIntensity = .calm
    /// Seconds for one segment to dissolve into the next.
    var crossfade: Double = 8

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var current: DaySegment?
    @State private var previous: DaySegment?
    @State private var blend: Double = 1

    /// Ramadan keeps its violet/gold identity; the day's tone only whispers.
    private var strengthScale: Double {
        (ramadanMode ? 0.45 : 1.0) * min(intensity.glowScale, 1.35)
    }

    private var isStatic: Bool { reduceMotion || MihrabPower.isLowPowerMode }

    var body: some View {
        ZStack {
            if let previous, blend < 1 {
                layer(previous).opacity(1 - blend)
            }
            if let current {
                layer(current).opacity(blend)
            }
        }
        .blendMode(.plusLighter)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            // First paint lands on the right tone immediately — no fade-in
            // from "no time of day" to the current one.
            current = segment
            previous = nil
            blend = 1
        }
        .onChange(of: segment) { old, new in
            guard old != new else { return }
            guard !isStatic else {
                previous = nil
                current = new
                blend = 1
                return
            }
            previous = old
            current = new
            blend = 0
            withAnimation(.easeInOut(duration: crossfade)) { blend = 1 }
        }
    }

    @ViewBuilder
    private func layer(_ segment: DaySegment) -> some View {
        let palette = segment.palette
        let strength = palette.strength * strengthScale
        let sky = min(DaySegment.veilCeiling * strength, 0.24)
        let ground = min(DaySegment.veilCeiling * strength * 0.7, 0.18)

        ZStack {
            // The light source. Sits where the sun would be for this segment,
            // so the screen quietly tracks the sky over a day.
            RadialGradient(
                colors: [
                    palette.sky.opacity(sky),
                    palette.sky.opacity(sky * 0.38),
                    .clear
                ],
                center: palette.lightCenter,
                startRadius: 0,
                endRadius: 620
            )

            // Ground tone — always bottom-weighted, so type at the top of the
            // screen keeps the darkest, calmest field behind it.
            LinearGradient(
                colors: [
                    .clear,
                    palette.ground.opacity(ground * 0.55),
                    palette.ground.opacity(ground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .compositingGroup()
    }
}
