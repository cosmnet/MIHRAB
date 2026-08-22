import SwiftUI

/// The signature Mihrab background: abyss base + two out-of-phase drifting
/// radial auroras + fine grain so Liquid Glass has something to refract.
struct AuroraBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var ramadanMode: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            let drift1 = Angle(radians: t * 2 * .pi / 24)
            let drift2 = Angle(radians: t * 2 * .pi / 31)

            ZStack {
                (ramadanMode ? MihrabColor.ramadanViolet.opacity(0.55) : MihrabColor.abyss)

                RadialGradient(
                    colors: [accent.opacity(0.55), .clear],
                    center: UnitPoint(
                        x: 0.5 + 0.35 * cos(drift1.radians),
                        y: 0.28 + 0.22 * sin(drift1.radians)
                    ),
                    startRadius: 20,
                    endRadius: 420
                )

                RadialGradient(
                    colors: [MihrabColor.moss.opacity(0.8), .clear],
                    center: UnitPoint(
                        x: 0.5 + 0.4 * cos(drift2.radians + .pi),
                        y: 0.75 + 0.25 * sin(drift2.radians)
                    ),
                    startRadius: 10,
                    endRadius: 500
                )

                GrainOverlay()
            }
            .drawingGroup()
        }
        .ignoresSafeArea()
    }

    private var accent: Color { ramadanMode ? MihrabColor.ramadanGold.opacity(0.35) : MihrabColor.forest }
}

/// Deterministic 2%-opacity noise so glass refraction reads as "wet".
private struct GrainOverlay: View {
    var body: some View {
        Canvas { context, size in
            var rng = SeededGenerator(seed: 42)
            let dotCount = Int(size.width * size.height / 900)
            for _ in 0..<dotCount {
                let x = CGFloat.random(in: 0...size.width, using: &rng)
                let y = CGFloat.random(in: 0...size.height, using: &rng)
                let shade = Double.random(in: 0...1, using: &rng)
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(.white.opacity(0.02 + 0.02 * shade))
                )
            }
        }
        .allowsHitTesting(false)
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
