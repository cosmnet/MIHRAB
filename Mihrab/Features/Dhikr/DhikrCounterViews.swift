import QuartzCore
import SwiftUI
import UIKit

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

// MARK: - Tasbih strand: layout

/// Where every piece sits on the loop.
///
/// A real 99-bead tasbih is three runs of 33 separated by flat *durak* discs and
/// closed by the long *imame*; a 33-bead one is three runs of 11 with the same
/// furniture. The strand on screen is the 33-bead kind, so the loop is
///
///     imame · 11 beads · durak · 11 beads · durak · 11 beads
///
/// which is 36 pieces carrying 33 counts. Only the beads count; the durak and
/// the imame pass under the thumb and are *felt*, exactly as they are in the
/// hand, which is what tells you a third — or a whole round — has gone by.
struct TasbihStrandLayout: Equatable, Sendable {
    enum Piece: Equatable, Sendable {
        case bead
        case durak
        case imame

        var counts: Bool { self == .bead }
    }

    let pieces: [Piece]
    /// Countable index → the slot position that leaves exactly that many behind.
    private let positionForCount: [Int]

    init(beadsPerRun: Int = 11, runs: Int = 3) {
        var built: [Piece] = [.imame]
        for run in 0..<max(runs, 1) {
            built.append(contentsOf: Array(repeating: Piece.bead, count: max(beadsPerRun, 1)))
            // The last run closes on the imame, so it needs no durak of its own.
            if run < max(runs, 1) - 1 { built.append(.durak) }
        }
        pieces = built

        var offsets: [Int] = [0]
        for (index, piece) in built.enumerated() where piece.counts {
            offsets.append(index + 1)
        }
        positionForCount = offsets
    }

    var slotCount: Int { pieces.count }
    /// Counts in one full turn of the strand — 33.
    var countableCount: Int { positionForCount.count - 1 }

    func piece(atSlot slot: Int) -> Piece {
        let wrapped = ((slot % slotCount) + slotCount) % slotCount
        return pieces[wrapped]
    }

    /// The slot position at which `count` beads have passed the marker.
    func slotPosition(forCount count: Int) -> Double {
        guard countableCount > 0 else { return 0 }
        let turns = count / countableCount
        let remainder = count % countableCount
        return Double(turns * slotCount + positionForCount[remainder])
    }

    /// What crossed the marker moving forward from `from` to `to`.
    ///
    /// Crossing boundary *k* means slot *k − 1* has just gone under the thumb,
    /// so that is the piece whose kind is reported.
    func crossings(from: Double, to: Double) -> TasbihCrossing {
        guard to > from else { return .none }
        let first = Int(from.rounded(.down)) + 1
        let last = Int(to.rounded(.down))
        guard last >= first else { return .none }
        // A single flick can never legitimately cross hundreds of slots; the
        // clamp keeps a pathological timestamp from spinning the loop.
        let bounded = min(last, first + slotCount * 4)

        var beads = 0
        var durak = false
        var imame = false
        for boundary in first...bounded {
            switch piece(atSlot: boundary - 1) {
            case .bead: beads += 1
            case .durak: durak = true
            case .imame: imame = true
            }
        }
        return TasbihCrossing(beads: beads, passedDurak: durak, passedImame: imame)
    }
}

/// What went under the thumb in one step of the simulation.
struct TasbihCrossing: Equatable, Sendable {
    var beads: Int = 0
    var passedDurak = false
    var passedImame = false

    static let none = TasbihCrossing()

    var isEmpty: Bool { beads == 0 && !passedDurak && !passedImame }
}

// MARK: - Tasbih strand: physics

/// The feel of the strand, as a value type so it can be reasoned about — and
/// tested — without a screen.
///
/// One number does the work: `position`, measured in *slots* travelled past the
/// marker. Dragging sets it directly; letting go leaves it with a velocity that
/// decays exponentially under `friction` until it is slow enough to settle onto
/// the nearest slot, the way a real strand comes to rest with a bead against
/// the finger rather than half-way between two.
struct TasbihPhysics: Sendable {
    let layout: TasbihStrandLayout

    /// Points of drag per piece.
    var pitch: Double = 26
    /// e-foldings per second — how quickly a flick dies.
    var friction: Double = 3.4
    /// Ceiling on the throw, in slots per second. Without it a hard flick on a
    /// 120 Hz display can run a whole loop in three frames.
    var maxSpeed: Double = 24
    /// Below this the strand stops coasting and settles.
    var restSpeed: Double = 0.9
    /// How hard the settle pulls, per second.
    var settleRate: Double = 18
    /// Reduce Motion: no coasting, and the strand steps piece by piece.
    var stepwise = false

    private(set) var position: Double = 0
    private(set) var velocity: Double = 0

    /// The last boundary we have reported. The strand may be pulled back
    /// visually, but never behind a bead that has already been counted — the
    /// finger is in the way.
    private var floorSlot: Int = 0
    private var dragOrigin: Double = 0
    private var lastSample: (position: Double, time: TimeInterval)?

    init(layout: TasbihStrandLayout = TasbihStrandLayout()) {
        self.layout = layout
    }

    var isMoving: Bool {
        velocity != 0 || abs(position - position.rounded()) > 0.0005
    }

    /// 0…1 — how fast the strand is running, for scaling feedback.
    var speedFraction: Double {
        min(abs(velocity) / maxSpeed, 1)
    }

    // MARK: Drag

    mutating func beginDrag() {
        dragOrigin = position
        velocity = 0
        lastSample = nil
    }

    /// `travel` is the drag translation in points, already signed so that
    /// positive means "towards the next bead" in the current writing direction.
    mutating func drag(travel: Double, at time: TimeInterval) -> TasbihCrossing {
        let raw = dragOrigin + travel / max(pitch, 1)
        let target = stepwise ? raw.rounded(.down) : raw
        let clamped = max(target, Double(floorSlot))

        if let last = lastSample, time > last.time {
            let dt = min(max(time - last.time, 1.0 / 240.0), 0.1)
            let instant = (clamped - last.position) / dt
            // Weighted to the newest sample: the throw should follow the last
            // few milliseconds of the gesture, not its average.
            velocity = min(max(velocity * 0.35 + instant * 0.65, -maxSpeed), maxSpeed)
        }
        lastSample = (clamped, time)

        return commit(to: clamped)
    }

    mutating func endDrag(at time: TimeInterval) {
        defer { lastSample = nil }
        guard !stepwise else {
            velocity = 0
            _ = commit(to: position.rounded())
            return
        }
        // A finger that stopped before it lifted is not a flick.
        if let last = lastSample, time - last.time > 0.09 {
            velocity = 0
        }
    }

    // MARK: Coasting

    /// One frame of free motion. Returns whatever passed the marker.
    mutating func advance(by dt: Double) -> TasbihCrossing {
        guard dt > 0, isMoving else { return .none }
        let step = min(dt, 0.05)

        if abs(velocity) > restSpeed {
            let next = position + velocity * step
            velocity *= exp(-friction * step)
            return commit(to: next)
        }

        velocity = 0
        let target = position.rounded()
        let pull = min(1, step * settleRate)
        var next = position + (target - position) * pull
        if abs(target - next) < 0.0005 { next = target }
        return commit(to: next)
    }

    // MARK: External changes

    /// Realigns the strand after the count changed somewhere else — a reset, a
    /// phrase swap, a tap on the dial. The equivalent position in the *nearest*
    /// turn is chosen so a reset from 99 unwinds a third of a loop, not three.
    mutating func sync(toCount count: Int) {
        let base = layout.slotPosition(forCount: max(count, 0))
        let loop = Double(layout.slotCount)
        let turns = ((position - base) / loop).rounded()
        position = base + turns * loop
        velocity = 0
        floorSlot = Int(position.rounded())
        dragOrigin = position
        lastSample = nil
    }

    /// Moves the strand on by whole beads without a gesture — the VoiceOver
    /// increment, and the Watch crown if it ever reaches this screen.
    mutating func step(beads: Int) -> TasbihCrossing {
        guard beads > 0 else { return .none }
        var travelled = position
        var found = 0
        var guardRail = 0
        while found < beads, guardRail < layout.slotCount * (beads + 2) {
            travelled += 1
            if layout.piece(atSlot: Int(travelled.rounded()) - 1).counts { found += 1 }
            guardRail += 1
        }
        velocity = 0
        return commit(to: travelled)
    }

    // MARK: Bookkeeping

    private mutating func commit(to next: Double) -> TasbihCrossing {
        let crossing = layout.crossings(from: position, to: next)
        position = next
        if !crossing.isEmpty || next > Double(floorSlot) {
            floorSlot = max(floorSlot, Int(next.rounded(.down)))
        }
        return crossing
    }
}

// MARK: - Tasbih strand: frame driver

/// Steps the physics on the display's own clock, and only while there is
/// something to step. A strand at rest costs nothing.
@MainActor
final class TasbihDriver: NSObject {
    private var link: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private let onTick: (Double) -> Void

    init(onTick: @escaping (Double) -> Void) {
        self.onTick = onTick
        super.init()
    }

    var isRunning: Bool { link != nil }

    func start() {
        guard link == nil else { return }
        lastTimestamp = 0
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    func stop() {
        link?.invalidate()
        link = nil
        lastTimestamp = 0
    }

    @objc private func tick(_ link: CADisplayLink) {
        let now = link.timestamp
        defer { lastTimestamp = now }
        guard lastTimestamp > 0 else { return }
        onTick(now - lastTimestamp)
    }

    // No `deinit` cleanup: a live `CADisplayLink` retains its target, so the
    // driver cannot be deallocated while it is running. `stop()` on disappear
    // is what ends it.
}

// MARK: - Tasbih strand: view

/// The alternative counting mode: a strand you actually turn.
///
/// The gesture is not a proxy for a count — it *is* the count. Drag and the
/// beads follow the thumb; flick and they keep going, slowing under friction
/// and settling against the marker, so a fast flick runs several beads by the
/// way a real tasbih does. Every piece that passes gives one dry tick; the
/// durak and the imame give a fuller one, which is how you know a third or a
/// whole round has gone by without looking.
struct DhikrStrandView: View {
    let count: Int
    let target: Int
    let accent: Color
    let reduceMotion: Bool
    /// Called with the number of beads that just passed — batched, because a
    /// flick can move five in one frame and each one used to cost a save.
    let onAdvance: (Int) -> Void

    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    @State private var store = DhikrStore.shared
    @State private var model = StrandModel()

    private static let layout = TasbihStrandLayout()

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                strand(side: side)
                marker(side: side)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(dragGesture)
            // Two taps change what the strand is made of. Quiet on purpose —
            // it is a preference, not a control that deserves screen space.
            .simultaneousGesture(TapGesture(count: 2).onEnded { cycleMaterial() })
        }
        .onAppear {
            model.reduceMotion = reduceMotion
            model.sync(toCount: count)
            model.onBeads = { beads in onAdvance(beads) }
        }
        .onDisappear { model.stop() }
        .onChange(of: reduceMotion) { _, value in model.reduceMotion = value }
        .onChange(of: count) { _, value in model.reconcile(externalCount: value) }
        .onChange(of: store.tasbihMaterial) { _, _ in DhikrFeedback.light() }
        .accessibilityElement()
        .accessibilityLabel(Text(L10n.dhkModeStrand))
        .accessibilityValue(Text(L10n.dhikrA11y(count, target)))
        .accessibilityHint(Text(L10n.dhkStrandHint))
        .accessibilityAdjustableAction { direction in
            if direction == .increment { model.stepOneBead() }
        }
        .accessibilityAction(named: Text(L10n.dhkMaterialNext)) { cycleMaterial() }
    }

    private var material: TasbihMaterial { store.tasbihMaterial }

    private func cycleMaterial() {
        store.tasbihMaterial = store.tasbihMaterial.next
        AccessibilityNotification.Announcement(store.tasbihMaterial.localizedName).post()
    }

    // MARK: Drawing

    private func strand(side: CGFloat) -> some View {
        // `position` is the only thing that changes per frame, and it is passed
        // in as a value — the canvas redraws when it moves and at no other time.
        StrandCanvas(
            position: model.position,
            layout: Self.layout,
            material: material,
            accent: accent,
            highContrast: differentiateWithoutColor,
            side: side
        )
        .frame(width: side, height: side)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    // MARK: Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                // Either axis works; the strand reads whichever the thumb moves
                // more. Vertical drag counts the same way everywhere; horizontal
                // drag follows the reading direction, so an Arabic thumb turns
                // the strand the way an Arabic tasbih actually turns.
                let horizontal = layoutDirection == .rightToLeft
                    ? value.translation.width
                    : -value.translation.width
                let travel = abs(value.translation.height) > abs(value.translation.width)
                    ? value.translation.height
                    : horizontal
                model.drag(travel: Double(travel), at: value.time.timeIntervalSinceReferenceDate)
            }
            .onEnded { value in
                model.endDrag(at: value.time.timeIntervalSinceReferenceDate)
            }
    }
}

// MARK: - Tasbih strand: model

/// Owns the physics, the frame driver and the feedback budget. Kept out of the
/// view so the canvas depends on one `Double` and nothing else.
@MainActor
@Observable
private final class StrandModel {
    private(set) var position: Double = 0

    var onBeads: (Int) -> Void = { _ in }
    var reduceMotion = false {
        didSet { physics.stepwise = reduceMotion }
    }

    @ObservationIgnored private var physics = TasbihPhysics()
    @ObservationIgnored private var expectedCount = 0
    @ObservationIgnored private var dragging = false
    @ObservationIgnored private lazy var driver = TasbihDriver { [weak self] dt in
        self?.tick(dt)
    }

    // MARK: Gesture

    func drag(travel: Double, at time: TimeInterval) {
        if !dragging {
            dragging = true
            driver.stop()
            physics.beginDrag()
            DhikrFeedback.strandGrip()
        }
        apply(physics.drag(travel: travel, at: time))
    }

    func endDrag(at time: TimeInterval) {
        dragging = false
        physics.endDrag(at: time)
        if physics.isMoving { driver.start() } else { position = physics.position }
    }

    func stepOneBead() {
        apply(physics.step(beads: 1))
    }

    func stop() { driver.stop() }

    // MARK: External count

    func sync(toCount count: Int) {
        physics.sync(toCount: count)
        expectedCount = count
        position = physics.position
    }

    /// The count changed outside the strand — a reset, a phrase swap, a Siri
    /// tap. Anything we did not cause ourselves realigns the beads.
    func reconcile(externalCount count: Int) {
        guard count != expectedCount else { return }
        driver.stop()
        sync(toCount: count)
    }

    // MARK: Frame

    private func tick(_ dt: Double) {
        apply(physics.advance(by: dt))
        position = physics.position
        if !physics.isMoving { driver.stop() }
    }

    private func apply(_ crossing: TasbihCrossing) {
        position = physics.position
        guard !crossing.isEmpty else { return }

        if crossing.beads > 0 {
            expectedCount += crossing.beads
            onBeads(crossing.beads)
        }
        // One haptic per frame at most, whatever crossed — several transients
        // inside 16 ms read as mush, not as beads.
        DhikrFeedback.strandPass(
            beads: crossing.beads,
            passedDurak: crossing.passedDurak,
            passedImame: crossing.passedImame,
            speed: physics.speedFraction
        )
    }
}

// MARK: - Tasbih strand: canvas

/// The strand itself. One `Canvas`, one pass, no per-bead filters: the old
/// version added a `.shadow` filter per bead, which forces an offscreen buffer
/// thirty-three times a frame. Contact shadows are plain fills now.
private struct StrandCanvas: View {
    let position: Double
    let layout: TasbihStrandLayout
    let material: TasbihMaterial
    let accent: Color
    let highContrast: Bool
    let side: CGFloat

    /// How far the loop is tipped away from the viewer. 1 would be face-on and
    /// flat; this is enough to read as a strand held in the hand.
    private let tilt: Double = 0.82

    var body: some View {
        Canvas(opaque: false, rendersAsynchronously: false) { context, size in
            draw(in: &context, size: size)
        }
        .allowsHitTesting(false)
    }

    private var stepAngle: Double { 2 * .pi / Double(layout.slotCount) }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let orbit = Double(min(size.width, size.height)) / 2 - 34
        guard orbit > 4 else { return }

        cord(in: &context, center: center, orbit: orbit)

        // Far pieces first, so the near ones overlap them and the strand reads
        // as a loop with a back and a front instead of a flat ring.
        let placed = (0..<layout.slotCount)
            .map { place(slot: $0, center: center, orbit: orbit) }
            .sorted { $0.depth < $1.depth }

        for piece in placed {
            drawPiece(piece, in: &context)
        }
    }

    private struct Placement {
        let slot: Int
        let kind: TasbihStrandLayout.Piece
        let point: CGPoint
        let angle: Double
        /// 0 at the far side of the loop, 1 at the marker.
        let depth: Double
        /// 0…1, how close to the marker — drives the glow.
        let nearness: Double
        let radius: Double
    }

    private func place(slot: Int, center: CGPoint, orbit: Double) -> Placement {
        let angle = Double(slot) * stepAngle - position * stepAngle - .pi / 2
        let point = CGPoint(
            x: center.x + orbit * cos(angle),
            y: center.y + orbit * tilt * sin(angle)
        )
        // The marker sits at the top, so the top of the loop is the near edge.
        let depth = (1 - sin(angle)) / 2
        let toMarker = abs(atan2(sin(angle + .pi / 2), cos(angle + .pi / 2)))
        let nearness = max(0, 1 - toMarker / 0.75)
        let base = orbit * 0.135
        let scale = 0.68 + 0.52 * depth + 0.18 * nearness
        return Placement(
            slot: slot,
            kind: layout.piece(atSlot: slot),
            point: point,
            angle: angle,
            depth: depth,
            nearness: nearness,
            radius: max(base * scale, 1.5)
        )
    }

    private func cord(in context: inout GraphicsContext, center: CGPoint, orbit: Double) {
        let rect = CGRect(
            x: center.x - orbit,
            y: center.y - orbit * tilt,
            width: orbit * 2,
            height: orbit * tilt * 2
        )
        context.stroke(
            Path(ellipseIn: rect),
            with: .color(Color(hex: material.cordHex, opacity: 0.85)),
            lineWidth: 2
        )
    }

    private func drawPiece(_ piece: Placement, in context: inout GraphicsContext) {
        // Contact shadow: a plain squashed fill under the piece. Cheap where a
        // shadow *filter* would cost an offscreen pass per bead.
        let shadowRect = CGRect(
            x: piece.point.x - piece.radius * 0.95,
            y: piece.point.y - piece.radius * 0.35 + piece.radius * 0.75,
            width: piece.radius * 1.9,
            height: piece.radius * 0.7
        )
        context.fill(
            Path(ellipseIn: shadowRect),
            with: .color(MihrabColor.abyss.opacity(0.30 * piece.depth))
        )

        if piece.nearness > 0.05 {
            halo(piece, in: &context)
        }

        switch piece.kind {
        case .bead:
            body(piece, in: &context, width: piece.radius * 2, height: piece.radius * 2)
        case .durak:
            // A flat disc lying across the cord: wide along the strand, thin
            // through it.
            body(piece, in: &context, width: piece.radius * 2.5, height: piece.radius * 1.15)
        case .imame:
            // The long terminal bead, standing proud of the loop.
            body(piece, in: &context, width: piece.radius * 1.7, height: piece.radius * 3.0)
        }
    }

    private func halo(_ piece: Placement, in context: inout GraphicsContext) {
        let glow = piece.radius * (2.0 + 1.4 * piece.nearness)
        let rect = CGRect(
            x: piece.point.x - glow,
            y: piece.point.y - glow,
            width: glow * 2,
            height: glow * 2
        )
        context.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(
                Gradient(colors: [
                    accent.opacity(0.34 * piece.nearness),
                    accent.opacity(0)
                ]),
                center: piece.point,
                startRadius: piece.radius * 0.6,
                endRadius: glow
            )
        )
    }

    private func body(
        _ piece: Placement,
        in context: inout GraphicsContext,
        width: Double,
        height: Double
    ) {
        let lit = Color(hex: material.litHex)
        let core = Color(hex: material.coreHex)
        let rim = Color(hex: material.rimHex)

        // Pieces lie along the cord, so they turn with it.
        let tangent = piece.angle + .pi / 2
        var layer = context
        layer.translateBy(x: piece.point.x, y: piece.point.y)
        layer.rotate(by: .radians(tangent))

        let rect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
        let path = Path(ellipseIn: rect)

        // The light comes from the upper left of the loop; in the rotated frame
        // that lands wherever the tangent put it, which is what makes the
        // strand read as one lit object rather than thirty-six of them.
        let lightAngle = -Double.pi / 2 - tangent
        let lightOffset = CGPoint(
            x: cos(lightAngle) * width * 0.28,
            y: sin(lightAngle) * height * 0.28
        )

        let shade = 0.42 + 0.58 * piece.depth
        layer.fill(
            path,
            with: .radialGradient(
                Gradient(colors: [
                    lit.opacity(shade),
                    core.mix(with: lit, by: 0.35 * shade),
                    core
                ]),
                center: lightOffset,
                startRadius: 0,
                endRadius: max(width, height) * 0.85
            )
        )

        // Rim light along the silhouette keeps the far beads from dissolving
        // into the backdrop — and carries the shape when colour is not enough.
        layer.stroke(
            Path(ellipseIn: rect.insetBy(dx: 0.5, dy: 0.5)),
            with: .color(rim.opacity((highContrast ? 0.55 : 0.22) + 0.42 * piece.depth)),
            lineWidth: highContrast ? 1.4 : 1
        )

        // Specular pin-prick, only on the pieces close enough for it to read.
        if piece.depth > 0.45 {
            let r = min(width, height) * 0.16 * material.gloss
            let dot = CGRect(
                x: lightOffset.x - r,
                y: lightOffset.y - r,
                width: r * 2,
                height: r * 2
            )
            layer.fill(
                Path(ellipseIn: dot),
                with: .color(
                    Color(hex: material.sheenHex)
                        .opacity(material.gloss * (piece.depth - 0.45) / 0.55 * 0.9)
                )
            )
        }

        // The imame wears a brass collar, the way a real one is capped.
        if piece.kind == .imame {
            let collar = CGRect(x: -width / 2, y: -height * 0.06, width: width, height: height * 0.12)
            layer.fill(
                Path(roundedRect: collar, cornerRadius: height * 0.06),
                with: .color(MihrabColor.brass.opacity(0.55 + 0.35 * piece.depth))
            )
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
