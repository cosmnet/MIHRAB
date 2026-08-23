import SwiftUI

// MARK: - Progress ring

/// The dial's rim. Under 100 it draws individual beads so the eye can *count*
/// them; above that it falls back to a single arc, because 500 dots is noise.
struct DhikrDialRing: View {
    let side: CGFloat
    /// `nil` for a free count — the rim then breathes instead of filling.
    let progress: Double?
    let target: Int
    /// 0…1 golden wash during a milestone or set completion.
    let flash: Double
    let accent: Color
    let reduceMotion: Bool
    /// Draws a rim tick every `tickStride` counts, so a 33 or 99 set can be read
    /// in thirds without looking at the number — the tasbih's knotted markers.
    var tickStride: Int = 11

    var body: some View {
        ZStack {
            if let progress, target > 0, target <= 99 {
                beads(progress: progress)
            } else {
                arc(progress: progress)
            }
            if let count = tickCount {
                ticks(count: count)
            }
        }
        .frame(width: side, height: side)
        .allowsHitTesting(false)
    }

    private var litColor: Color { accent.mix(with: MihrabColor.ramadanGold, by: flash) }

    /// Only when the target divides cleanly — a tick that lands between counts
    /// would lie about where you are.
    private var tickCount: Int? {
        guard target > 0, tickStride > 1, target % tickStride == 0 else { return nil }
        let count = target / tickStride
        return count > 1 ? count : nil
    }

    private func ticks(count: Int) -> some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let outer = size.width / 2 - 3
            let inner = outer - 7
            let reached = progress ?? 0

            for index in 0..<count {
                let fraction = Double(index) / Double(count)
                let angle = fraction * 2 * .pi - .pi / 2
                var path = Path()
                path.move(to: CGPoint(x: center.x + inner * cos(angle), y: center.y + inner * sin(angle)))
                path.addLine(to: CGPoint(x: center.x + outer * cos(angle), y: center.y + outer * sin(angle)))
                // The tick you have already passed lights brass; the one ahead
                // stays a hairline.
                let passed = fraction <= reached + 0.0001
                context.stroke(
                    path,
                    with: .color(
                        passed
                            ? MihrabColor.brass.opacity(0.85)
                            : MihrabColor.mint.opacity(0.28)
                    ),
                    lineWidth: passed ? 2 : 1.2
                )
            }
        }
        .animation(reduceMotion ? nil : MihrabMotion.snappyAnimation, value: progress)
        .accessibilityHidden(true)
    }

    private func beads(progress: Double) -> some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let orbit = size.width / 2 - 16
            let lit = Int((progress * Double(target)).rounded(.down))
            let radius: CGFloat = target > 66 ? 3.4 : 4.4

            for index in 0..<max(target, 1) {
                let angle = Double(index) / Double(max(target, 1)) * 2 * .pi - .pi / 2
                let point = CGPoint(x: center.x + orbit * cos(angle), y: center.y + orbit * sin(angle))
                let bead = Path(ellipseIn: CGRect(
                    x: point.x - radius, y: point.y - radius,
                    width: radius * 2, height: radius * 2
                ))
                if index < lit {
                    var glowing = context
                    glowing.addFilter(.shadow(color: litColor.opacity(0.55), radius: 5))
                    glowing.fill(bead, with: .color(litColor))
                } else {
                    context.fill(
                        bead,
                        with: .color(MihrabColor.textTertiary.mix(with: MihrabColor.brass, by: flash).opacity(0.45))
                    )
                }
            }
        }
        .animation(reduceMotion ? nil : MihrabMotion.snappyAnimation, value: progress)
    }

    private func arc(progress: Double?) -> some View {
        let diameter = side - 22
        let gradient = AngularGradient(
            colors: [accent, MihrabColor.mint, accent],
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
        return ZStack {
            Circle()
                .stroke(MihrabColor.textTertiary.opacity(0.22), lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress ?? 1)
                .stroke(gradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .opacity(progress == nil ? 0.30 : 1)
                .shadow(color: accent.opacity(0.35), radius: 8)
            Circle()
                .trim(from: 0, to: progress ?? 1)
                .stroke(MihrabColor.ramadanGold, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .opacity(flash)
        }
        .frame(width: diameter, height: diameter)
        .animation(reduceMotion ? nil : MihrabMotion.snappyAnimation, value: progress)
    }
}

// MARK: - Tap ripple

/// One expanding hairline per tap. Cheap enough to fire on every count.
struct DhikrRipple: View {
    let born: Date
    let side: CGFloat
    var color: Color = MihrabColor.mint

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let elapsed = context.date.timeIntervalSince(born)
            let u = min(max(elapsed / 0.45, 0), 1)
            Circle()
                .stroke(color.opacity(0.5 * (1 - u)), lineWidth: 2.8 * (1 - u) + 0.6)
                .padding(22)
                .scaleEffect(0.5 + 0.5 * u)
        }
        .frame(width: side, height: side)
        .clipShape(Circle())
        .allowsHitTesting(false)
    }
}

// MARK: - Milestone burst

/// The 33 / 66 / 99 moment: a ring of gold sparks thrown outward, fading as
/// they go. Drawn in a `Canvas` so it costs one layer, not thirty views.
struct DhikrMilestoneBurst: View {
    let born: Date
    let side: CGFloat
    var sparkCount: Int = 26

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 40.0)) { context in
            let elapsed = context.date.timeIntervalSince(born)
            let u = min(max(elapsed / 0.95, 0), 1)
            Canvas { canvas, size in
                guard u < 1 else { return }
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let base = size.width / 2 - 26
                let eased = 1 - pow(1 - u, 2.2)

                // Halo.
                let haloRadius = base * (0.9 + 0.35 * eased)
                canvas.stroke(
                    Path(ellipseIn: CGRect(
                        x: center.x - haloRadius, y: center.y - haloRadius,
                        width: haloRadius * 2, height: haloRadius * 2
                    )),
                    with: .color(MihrabColor.ramadanGold.opacity(0.45 * (1 - u))),
                    lineWidth: 2.5 * (1 - u) + 0.5
                )

                for index in 0..<sparkCount {
                    let angle = Double(index) / Double(sparkCount) * 2 * .pi
                    // Deterministic jitter so the burst is never mechanical.
                    let jitter = sin(Double(index) * 12.9898) * 0.5 + 0.5
                    let distance = base * (0.72 + eased * (0.42 + 0.28 * jitter))
                    let point = CGPoint(
                        x: center.x + distance * cos(angle),
                        y: center.y + distance * sin(angle)
                    )
                    let r = (2.6 + 1.6 * jitter) * (1 - u)
                    guard r > 0.2 else { continue }
                    canvas.fill(
                        Path(ellipseIn: CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)),
                        with: .color(
                            (index % 3 == 0 ? MihrabColor.sprout : MihrabColor.ramadanGold)
                                .opacity(0.9 * (1 - u))
                        )
                    )
                }
            }
        }
        .frame(width: side, height: side)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Tasbih strand

/// The alternative counting mode: a real strand you turn with your thumb.
/// Every `beadPitch` points of drag rolls exactly one bead past the brass
/// marker and reports one count — so the gesture *is* the count, not a proxy.
struct DhikrStrandView: View {
    let count: Int
    let target: Int
    let accent: Color
    let reduceMotion: Bool
    let onAdvance: () -> Void

    /// Beads drawn around the loop.
    private let beadsOnLoop = 33
    /// Points of drag per bead.
    private let beadPitch: CGFloat = 26

    @Environment(\.layoutDirection) private var layoutDirection

    @State private var dragBeads = 0
    @State private var dragFraction: Double = 0

    private var stepAngle: Double { 2 * .pi / Double(beadsOnLoop) }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let rotation = (Double(count) + dragFraction) * stepAngle

            ZStack {
                strand(side: side, rotation: rotation)
                marker(side: side)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(dragGesture)
        }
        .accessibilityElement()
        .accessibilityLabel(Text(L10n.dhkModeStrand))
        .accessibilityValue(Text(L10n.dhikrA11y(count, target)))
        .accessibilityHint(Text(L10n.dhkStrandHint))
        .accessibilityAdjustableAction { direction in
            if direction == .increment { onAdvance() }
        }
    }

    private func strand(side: CGFloat, rotation: Double) -> some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let orbit = side / 2 - 34

            for index in 0..<beadsOnLoop {
                // Beads run clockwise; the strand turns anticlockwise as you count.
                let angle = Double(index) * stepAngle - rotation - .pi / 2
                let point = CGPoint(x: center.x + orbit * cos(angle), y: center.y + orbit * sin(angle))

                // Distance from the marker at the top decides size and light —
                // this is what sells the strand as a physical object.
                let toMarker = abs(atan2(sin(angle + .pi / 2), cos(angle + .pi / 2)))
                let nearness = max(0, 1 - toMarker / 0.9)
                let radius = 8.5 + 4.5 * nearness

                let rect = CGRect(
                    x: point.x - radius, y: point.y - radius,
                    width: radius * 2, height: radius * 2
                )
                var layer = context
                layer.addFilter(.shadow(color: MihrabColor.abyss.opacity(0.5), radius: 4, x: 0, y: 2))
                layer.fill(
                    Path(ellipseIn: rect),
                    with: .radialGradient(
                        Gradient(colors: [
                            MihrabColor.sprout.opacity(0.35 + 0.5 * nearness),
                            accent.opacity(0.9),
                            MihrabColor.forest
                        ]),
                        center: CGPoint(x: point.x - radius * 0.35, y: point.y - radius * 0.4),
                        startRadius: 0,
                        endRadius: radius * 1.6
                    )
                )
                context.stroke(
                    Path(ellipseIn: rect.insetBy(dx: 0.5, dy: 0.5)),
                    with: .color(MihrabColor.mint.opacity(0.18 + 0.35 * nearness)),
                    lineWidth: 1
                )
            }

            // The cord.
            let cordRadius = orbit
            context.stroke(
                Path(ellipseIn: CGRect(
                    x: center.x - cordRadius, y: center.y - cordRadius,
                    width: cordRadius * 2, height: cordRadius * 2
                )),
                with: .color(MihrabColor.brass.opacity(0.20)),
                lineWidth: 1.5
            )
        }
        .animation(reduceMotion ? nil : .interactiveSpring(response: 0.22, dampingFraction: 0.82), value: count)
    }

    private func marker(side: CGFloat) -> some View {
        VStack(spacing: 0) {
            Image(systemName: "chevron.compact.down")
                // Decorative marker inside fixed geometry — a semantic style
                // keeps it in step with the rest of the type without scaling
                // past the strand it points at.
                .font(.title2.weight(.semibold))
                .foregroundStyle(MihrabColor.brass)
                .shadow(color: MihrabColor.brass.opacity(0.5), radius: 6)
            Spacer()
        }
        .frame(width: side, height: side)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                // Either axis works; the strand reads whichever the thumb moves more.
                // Vertical drag counts the same way everywhere; horizontal drag
                // follows the reading direction, so an Arabic thumb turns the
                // strand the way an Arabic tasbih actually turns.
                let horizontal = layoutDirection == .rightToLeft
                    ? value.translation.width
                    : -value.translation.width
                let travel = abs(value.translation.height) > abs(value.translation.width)
                    ? value.translation.height
                    : horizontal
                let raw = Double(travel / beadPitch)
                dragFraction = raw - Double(dragBeads)
                let whole = Int(raw.rounded(.towardZero))
                guard whole > dragBeads else { return }
                for _ in dragBeads..<whole { onAdvance() }
                dragBeads = whole
                dragFraction = raw - Double(whole)
            }
            .onEnded { _ in
                dragBeads = 0
                withAnimation(reduceMotion ? nil : MihrabMotion.snappyAnimation) {
                    dragFraction = 0
                }
            }
    }
}

// MARK: - Goal bar

/// Today's progress against the daily goal, plus the streak. Small on purpose —
/// the counter is the hero, this is the footnote that gives it stakes.
struct DhikrGoalBar: View {
    let todayTotal: Int
    let goal: Int
    let streak: Int
    let accent: Color

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var fraction: Double {
        guard goal > 0 else { return 0 }
        return min(Double(todayTotal) / Double(goal), 1)
    }

    private var reached: Bool { goal > 0 && todayTotal >= goal }

    var body: some View {
        VStack(spacing: 8) {
            // At accessibility text sizes label + streak + count cannot share a
            // line. `ViewThatFits` cannot judge it — the row carries a `Spacer`
            // and so always claims to fit — so branch on the size directly.
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) { headerItems }
            } else {
                HStack(spacing: 8) { headerItems }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(MihrabColor.abyss.opacity(0.45))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: reached
                                    ? [MihrabColor.brass, MihrabColor.ramadanGold]
                                    : [accent, MihrabColor.mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(6, geo.size.width * fraction))
                }
            }
            .frame(height: 6)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(L10n.dhkGoalToday))
        .accessibilityValue(Text(L10n.dhkGoalProgress(todayTotal, goal)))
    }

    @ViewBuilder
    private var headerItems: some View {
        Text(reached ? L10n.dhkGoalReached : L10n.dhkGoalToday)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(reached ? MihrabColor.ramadanGold : MihrabColor.textSecondary)
        if !dynamicTypeSize.isAccessibilitySize {
            Spacer(minLength: 8)
        }
        if streak > 1 {
            Label(L10n.dhkStreakDays(streak), systemImage: "flame.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(MihrabColor.brass)
                .labelStyle(.titleAndIcon)
        }
        Text(L10n.dhkGoalProgress(todayTotal, goal))
            .font(.caption2.monospacedDigit())
            // textTertiary measures 2.9:1 on moss — under the 4.5:1 floor.
            .foregroundStyle(MihrabColor.textSecondary)
    }
}
