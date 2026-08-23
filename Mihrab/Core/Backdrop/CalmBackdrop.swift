import SwiftUI

/// The default Mihrab background: an abyss floor, one or two very low-contrast
/// radial washes that drift on a ~40 second breath, and a static film of grain.
///
/// Deliberately **not** a `TimelineView`. The drift is a single Core Animation
/// keyframe on two `offset` values, so the CPU does no per-frame work at all —
/// this is the cheapest possible way to make a background feel alive, and it
/// stays smooth while the rest of the screen is busy.
struct CalmBackdrop: View {
    var surface: BackdropSurface = .sheet
    var ramadanMode: Bool = false
    var intensity: AppSettings.BackdropIntensity = .calm

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @State private var drifted = false

    var body: some View {
        ZStack {
            surface.baseColor(ramadan: ramadanMode)

            if !reduceTransparency {
                GeometryReader { geo in
                    ZStack {
                        ForEach(Array(surface.glows(ramadan: ramadanMode).enumerated()), id: \.offset) { item in
                            wash(item.element, in: geo.size, index: item.offset)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    // Compositing the washes once keeps the blend cheap and
                    // avoids banding where two of them cross.
                    .compositingGroup()
                }
                .blendMode(.plusLighter)

                MihrabGrain()
                    .opacity(intensity == .calm ? 0.7 : 1)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear(perform: startDrift)
    }

    // MARK: - Pieces

    @ViewBuilder
    private func wash(_ glow: BackdropGlow, in size: CGSize, index: Int) -> some View {
        let minEdge = min(size.width, size.height)
        let radius = max(minEdge * glow.radius, 1)
        let opacity = min(glow.opacity * intensity.glowScale, 0.34)
        let travel: CGFloat = drifted ? 1 : -1
        let breath: Animation? = reduceMotion
            ? nil
            : Animation
                .easeInOut(duration: glow.period * intensity.periodScale)
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 1.5)

        RadialGradient(
            colors: [glow.color.opacity(opacity), glow.color.opacity(opacity * 0.35), .clear],
            center: .center,
            startRadius: 0,
            endRadius: radius
        )
        .frame(width: radius * 2, height: radius * 2)
        .scaleEffect(x: glow.stretch.width, y: glow.stretch.height)
        .position(
            x: size.width * glow.center.x,
            y: size.height * glow.center.y
        )
        .offset(
            x: reduceMotion ? 0 : size.width * glow.drift.width * intensity.driftScale * travel,
            y: reduceMotion ? 0 : size.height * glow.drift.height * intensity.driftScale * travel
        )
        .animation(breath, value: drifted)
    }

    private func startDrift() {
        guard !reduceMotion, !drifted else { return }
        drifted = true
    }
}

/// Deterministic, *static* film grain. Drawn once into a `Canvas` and then left
/// alone — it exists so Liquid Glass has something to refract, not to animate.
struct MihrabGrain: View {
    var intensity: Double = 1

    var body: some View {
        Canvas { context, size in
            var rng = MihrabSeededGenerator(seed: 42)
            let dotCount = Int(size.width * size.height / 900)
            for _ in 0..<dotCount {
                let x = CGFloat.random(in: 0...max(size.width, 1), using: &rng)
                let y = CGFloat.random(in: 0...max(size.height, 1), using: &rng)
                let shade = Double.random(in: 0...1, using: &rng)
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(.white.opacity((0.015 + 0.018 * shade) * intensity))
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct MihrabSeededGenerator: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
