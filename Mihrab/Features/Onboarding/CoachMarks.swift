import SwiftUI
import UIKit

// MARK: - Controller

/// Drives a one-shot coach-mark tour and remembers that it ran.
/// Two ready-made scopes ship with the app: `.shared` for in-screen marks
/// registered with `.coachMark(id:title:message:order:)`, and `.tabTour` for the
/// tab-bar tour shown at the root. Both are resettable from Settings.
@MainActor
@Observable
final class CoachMarkController {
    static let shared = CoachMarkController(storageKey: "coachMarks.main")
    static let tabTour = CoachMarkController(storageKey: "coachMarks.tabTour")

    private let storageKey: String
    private let defaults: UserDefaults

    private(set) var isRunning = false
    private(set) var index = 0
    private(set) var isCompleted: Bool

    init(storageKey: String, defaults: UserDefaults = .standard) {
        self.storageKey = storageKey
        self.defaults = defaults
        isCompleted = defaults.bool(forKey: storageKey)
    }

    /// Whether a tour may start *by itself*.
    ///
    /// It may not while VoiceOver is running. VoiceOver has its own model for
    /// discovering a screen — the rotor, and reading the elements in order —
    /// and a modal scrim that traps focus on a tip card is not a help but an
    /// obstruction laid over it. Starting the tour by hand from Settings still
    /// works, because then it is what the user asked for.
    static var autoStartAllowed: Bool { !UIAccessibility.isVoiceOverRunning }

    /// Starts once per install. Safe to call on every appearance.
    func startIfNeeded(markCount: Int) {
        guard !isCompleted, !isRunning, markCount > 0 else { return }
        guard Self.autoStartAllowed else { return }
        start()
    }

    func start() {
        index = 0
        isRunning = true
    }

    /// Advances, finishing when the last mark has been seen.
    func advance(total: Int) {
        guard isRunning else { return }
        if index + 1 >= total {
            finish()
        } else {
            index += 1
            HapticsEngine.shared.light()
        }
    }

    func finish() {
        isRunning = false
        index = 0
        isCompleted = true
        defaults.set(true, forKey: storageKey)
        HapticsEngine.shared.success()
    }

    /// Settings → "Show tips again".
    func reset() {
        isRunning = false
        index = 0
        isCompleted = false
        defaults.set(false, forKey: storageKey)
        if self === Self.shared { Self.tabTour.reset() }
    }
}

// MARK: - Anchor plumbing

struct CoachMarkItem: Identifiable, Equatable {
    let id: String
    let title: String
    let message: String
    let order: Int
}

struct CoachMarkAnchor: Identifiable {
    let item: CoachMarkItem
    let bounds: Anchor<CGRect>
    var id: String { item.id }
}

struct CoachMarkPreferenceKey: PreferenceKey {
    static var defaultValue: [CoachMarkAnchor] { [] }

    static func reduce(value: inout [CoachMarkAnchor], nextValue: () -> [CoachMarkAnchor]) {
        value.append(contentsOf: nextValue())
    }
}

extension View {
    /// Registers this view as a stop on the coach-mark tour. Entirely optional —
    /// screens that never call it simply have no marks.
    func coachMark(id: String, title: String, message: String, order: Int) -> some View {
        anchorPreference(key: CoachMarkPreferenceKey.self, value: .bounds) { anchor in
            [
                CoachMarkAnchor(
                    item: CoachMarkItem(id: id, title: title, message: message, order: order),
                    bounds: anchor
                ),
            ]
        }
    }

    /// Hosts the spotlight overlay for every `.coachMark` registered beneath it.
    func coachMarkHost(
        _ controller: CoachMarkController = .shared,
        autoStart: Bool = true,
        startDelay: Double = 0.9
    ) -> some View {
        modifier(CoachMarkHostModifier(controller: controller, autoStart: autoStart, startDelay: startDelay))
    }
}

private struct CoachMarkHostModifier: ViewModifier {
    let controller: CoachMarkController
    let autoStart: Bool
    let startDelay: Double

    func body(content: Content) -> some View {
        content.overlayPreferenceValue(CoachMarkPreferenceKey.self) { anchors in
            GeometryReader { proxy in
                let stops = anchors.sorted { $0.item.order < $1.item.order }
                ZStack {
                    if controller.isRunning, controller.index < stops.count {
                        let stop = stops[controller.index]
                        CoachMarkSpotlight(
                            // Resolved from the anchor against this proxy — the
                            // real frame the view ended up with, whatever the
                            // scroll offset, the safe-area inset or the text
                            // size did to it.
                            focus: proxy[stop.bounds],
                            safeArea: CoachMarkGeometry.safeArea(from: proxy),
                            title: stop.item.title,
                            message: stop.item.message,
                            step: controller.index + 1,
                            total: stops.count,
                            onAdvance: { controller.advance(total: stops.count) },
                            onSkip: { controller.finish() }
                        )
                    }
                }
                .task(id: stops.count) {
                    guard autoStart, !stops.isEmpty else { return }
                    try? await Task.sleep(for: .seconds(startDelay))
                    controller.startIfNeeded(markCount: stops.count)
                }
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Geometry helpers

/// The two measurements the tour cannot get from SwiftUI alone.
@MainActor
enum CoachMarkGeometry {

    /// Safe-area insets that survive `ignoresSafeArea`.
    ///
    /// The hosts deliberately expand to the full screen so anchors and the
    /// scrim share one coordinate space; the price is that the proxy inside can
    /// report zero insets. The window's own insets are the ground truth, so the
    /// larger of the two is used and the tip card can never be parked under the
    /// notch or the home indicator.
    static func safeArea(from proxy: GeometryProxy) -> EdgeInsets {
        let window = windowInsets()
        return EdgeInsets(
            top: max(proxy.safeAreaInsets.top, window.top),
            leading: max(proxy.safeAreaInsets.leading, window.left),
            bottom: max(proxy.safeAreaInsets.bottom, window.bottom),
            trailing: max(proxy.safeAreaInsets.trailing, window.right)
        )
    }

    static func windowInsets() -> UIEdgeInsets {
        keyWindow()?.safeAreaInsets ?? .zero
    }

    /// The frames of the real tab-bar buttons, in the coordinate space of
    /// `proxy`.
    ///
    /// The tour used to guess: screen width minus a fixed inset, divided by the
    /// number of tabs. That guess is wrong on any device whose bar is not that
    /// width, wrong when Dynamic Type makes the bar taller, wrong when a longer
    /// language makes the items wider, and wrong in right-to-left, where the
    /// first tab is on the *right*. Asking UIKit for the frames it actually
    /// laid out is right in all four cases.
    ///
    /// Returns `nil` when there is no tab bar to measure — a minimised bar, or
    /// a host that is not a tab controller — and the caller falls back.
    static func tabItemFrames(in proxy: GeometryProxy) -> [CGRect]? {
        guard let window = keyWindow(),
              let bar = firstTabBar(in: window),
              bar.window != nil,
              !bar.isHidden,
              bar.alpha > 0.05
        else { return nil }

        var frames = bar.subviews
            .filter { isTabButton($0) }
            .map { bar.convert($0.frame, to: window) }
            .filter { $0.width > 1 && $0.height > 1 }
        guard !frames.isEmpty else { return nil }

        // Subview order is not guaranteed to be visual order; position is.
        frames.sort { $0.minX < $1.minX }
        if UIView.userInterfaceLayoutDirection(for: bar.semanticContentAttribute) == .rightToLeft {
            frames.reverse()
        }

        // `.global` in SwiftUI is the window's space, so one translation lands
        // the UIKit frames in the overlay's own coordinates.
        let origin = proxy.frame(in: .global).origin
        return frames.map { $0.offsetBy(dx: -origin.x, dy: -origin.y) }
    }

    private static func isTabButton(_ view: UIView) -> Bool {
        // iOS has renamed the private button class more than once, so match on
        // behaviour — a control that answers as a button — and keep the class
        // name only as a second chance.
        if view is UIControl { return true }
        if view.accessibilityTraits.contains(.button) { return true }
        return String(describing: type(of: view)).contains("TabBarButton")
    }

    private static func firstTabBar(in view: UIView) -> UITabBar? {
        if let bar = view as? UITabBar { return bar }
        for child in view.subviews {
            if let found = firstTabBar(in: child) { return found }
        }
        return nil
    }

    private static func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
    }
}

// MARK: - Spotlight

/// Dimmed scrim with a punched-out rounded window plus a glass tip card.
/// Tapping anywhere advances; the card carries explicit controls for VoiceOver.
struct CoachMarkSpotlight: View {
    let focus: CGRect
    /// Passed in rather than read locally: the host ignores the safe area so the
    /// scrim can cover the screen, which leaves the inner proxy with nothing to
    /// report.
    var safeArea: EdgeInsets = EdgeInsets()
    let title: String
    let message: String
    let step: Int
    let total: Int
    let onAdvance: () -> Void
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    /// The card's real height, measured. Everything about where the card sits
    /// depends on how tall it turned out to be, and at accessibility text sizes
    /// with a long message that is nothing like the 118pt the old code assumed.
    @State private var cardSize: CGSize = .zero

    /// Breathing room around the highlighted view.
    private let halo: CGFloat = 10
    /// Gap between the spotlight and the card.
    private let gap: CGFloat = 16
    /// Margin from the screen edge.
    private let margin: CGFloat = 20

    private var padded: CGRect { focus.insetBy(dx: -halo, dy: -halo * 0.8) }

    private var corner: CGFloat {
        min(max(padded.height, 1) / 2, MihrabSpace.rowRadius)
    }

    var body: some View {
        GeometryReader { proxy in
            let placement = cardPlacement(in: proxy.size)
            ZStack(alignment: .topLeading) {
                scrim
                haloRing
                card
                    .frame(width: placement.width, alignment: .leading)
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { cardSize = $0 }
                    .offset(x: placement.x, y: placement.y)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .contentShape(Rectangle())
            .onTapGesture { onAdvance() }
        }
        .opacity(appeared ? 1 : 0)
        .animation(reduceMotion ? .easeInOut(duration: 0.18) : MihrabMotion.standardAnimation, value: appeared)
        // The spotlight slides from one target to the next instead of cutting,
        // so the eye can follow it — unless the reader asked for no motion, in
        // which case it simply is where it is.
        .animation(reduceMotion ? nil : MihrabMotion.gentleAnimation, value: focus)
        .onAppear { appeared = true }
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) { onSkip() }
    }

    // MARK: Placement

    private struct CardPlacement {
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
    }

    /// Puts the card wherever it actually fits.
    ///
    /// Vertically it prefers the side of the target with more room, and only
    /// falls back to the other side when the card genuinely does not fit — so a
    /// target near the bottom of the screen (the tab bar) is described from
    /// above, and one near the top from below, at every text size rather than
    /// only at the default one. Horizontally it centres on the target and then
    /// clamps inside the margins, which keeps a card describing an edge control
    /// on screen instead of half off it.
    private func cardPlacement(in size: CGSize) -> CardPlacement {
        let width = max(min(size.width - margin * 2, 360), 200)
        let height = cardSize.height > 0 ? cardSize.height : 0

        let top = safeArea.top + 12
        let bottom = size.height - safeArea.bottom - 12
        let roomAbove = padded.minY - gap - top
        let roomBelow = bottom - (padded.maxY + gap)

        let below: Bool
        if roomBelow >= height, roomAbove >= height {
            // Both fit: describe a target in the top half from below and one in
            // the bottom half from above, so the card never covers what it is
            // pointing at.
            below = padded.midY < size.height / 2
        } else if roomBelow >= height {
            below = true
        } else if roomAbove >= height {
            below = false
        } else {
            below = roomBelow >= roomAbove
        }

        var y = below ? padded.maxY + gap : padded.minY - gap - height
        // Never off the top, never off the bottom, and the top wins if the card
        // is taller than the space between them.
        y = min(y, max(top, bottom - height))
        y = max(y, top)

        var x = padded.midX - width / 2
        x = min(x, size.width - margin - width)
        x = max(x, margin)

        return CardPlacement(x: x, y: y, width: width)
    }

    // MARK: Pieces

    private var scrim: some View {
        Rectangle()
            .fill(MihrabColor.abyss.opacity(0.82))
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .frame(width: padded.width, height: padded.height)
                    .offset(x: padded.minX, y: padded.minY)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }

    private var haloRing: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .strokeBorder(MihrabColor.brass.opacity(0.75), lineWidth: 1.5)
            .frame(width: padded.width, height: padded.height)
            .offset(x: padded.minX, y: padded.minY)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(format: L10n.obStepFormat, step, total))
                .ornamentalCaps()

            Text(title)
                .font(.title3.bold())
                .foregroundStyle(MihrabColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(MihrabColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            controls
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mihrabSolidCard(cornerRadius: MihrabSpace.cardRadius, fill: MihrabColor.forest)
        .accessibilityElement(children: .contain)
        .accessibilitySortPriority(1)
    }

    /// Skip stays on every step, last one included. A way out that disappears on
    /// the step where the reader has had enough is not a way out.
    private var controls: some View {
        HStack(spacing: 12) {
            Button(L10n.coachSkipTour, action: onSkip)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MihrabColor.textSecondary)
                .frame(minHeight: MihrabSpace.hit)
            Spacer(minLength: 8)
            Button(step < total ? L10n.coachNext : L10n.coachGotIt, action: onAdvance)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(MihrabColor.abyss)
                .padding(.horizontal, 20)
                .frame(minHeight: MihrabSpace.hit)
                .background(Capsule().fill(MihrabColor.mint))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab bar tour

struct TabTourStop: Identifiable {
    let id: String
    let systemImage: String
    let title: String
    let message: String

    init(id: String, systemImage: String, title: String, message: String) {
        self.id = id
        self.systemImage = systemImage
        self.title = title
        self.message = message
    }
}

/// First-run tour of the tab bar.
///
/// The tab bar cannot publish SwiftUI anchors, so the spotlight is measured off
/// the real `UITabBar` instead — see `CoachMarkGeometry.tabItemFrames`. The
/// estimate below is only the fallback for when there is nothing to measure.
struct TabBarTourOverlay: View {
    let stops: [TabTourStop]
    var controller: CoachMarkController = .tabTour
    var startDelay: Double = 1.1
    var onFocus: (Int) -> Void = { _ in }
    var onFinish: () -> Void = {}

    @Environment(\.layoutDirection) private var layoutDirection
    @State private var measured: [CGRect] = []

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if controller.isRunning, controller.index < stops.count {
                    let stop = stops[controller.index]
                    CoachMarkSpotlight(
                        focus: slot(at: controller.index, in: proxy),
                        safeArea: CoachMarkGeometry.safeArea(from: proxy),
                        title: stop.title,
                        message: stop.message,
                        step: controller.index + 1,
                        total: stops.count,
                        onAdvance: {
                            let next = controller.index + 1
                            controller.advance(total: stops.count)
                            if next < stops.count { onFocus(next) } else { onFinish() }
                        },
                        onSkip: {
                            controller.finish()
                            onFinish()
                        }
                    )
                }
            }
            .task {
                guard !controller.isCompleted, !stops.isEmpty else { return }
                try? await Task.sleep(for: .seconds(startDelay))
                controller.startIfNeeded(markCount: stops.count)
                guard controller.isRunning else { return }
                remeasure(in: proxy)
                onFocus(0)
            }
            // The bar re-lays itself out when the tab changes, and the tour
            // changes the tab on every step — so measure again each time,
            // after the switch has settled.
            .task(id: controller.index) {
                guard controller.isRunning else { return }
                remeasure(in: proxy)
                try? await Task.sleep(for: .milliseconds(280))
                guard !Task.isCancelled else { return }
                remeasure(in: proxy)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(controller.isRunning)
    }

    private func remeasure(in proxy: GeometryProxy) {
        guard let frames = CoachMarkGeometry.tabItemFrames(in: proxy), frames.count == stops.count
        else { return }
        measured = frames
    }

    private func slot(at index: Int, in proxy: GeometryProxy) -> CGRect {
        if index < measured.count { return measured[index] }
        return estimatedSlot(at: index, in: proxy)
    }

    /// Fallback only. Still better than the old one in the two ways that were
    /// simply wrong: it counts the bar's height off the safe-area inset rather
    /// than a fixed 46/26 pair, and it lays the slots out right-to-left in a
    /// right-to-left layout.
    private func estimatedSlot(at index: Int, in proxy: GeometryProxy) -> CGRect {
        let count = max(stops.count, 1)
        let sideInset = min(max(proxy.size.width * 0.055, 12), 40)
        let usable = max(proxy.size.width - sideInset * 2, 1)
        let width = usable / CGFloat(count)
        // The bar sits directly above the home-indicator inset; without one
        // (older devices, or a bar that reports nothing) it sits on the edge.
        let bottomInset = max(proxy.safeAreaInsets.bottom, CoachMarkGeometry.windowInsets().bottom)
        let height = MihrabSpace.hit
        let centerY = proxy.size.height - max(bottomInset, 12) - height / 2 - 4
        let visualIndex = layoutDirection == .rightToLeft ? count - 1 - index : index
        return CGRect(
            x: sideInset + width * CGFloat(visualIndex),
            y: centerY - height / 2,
            width: width,
            height: height
        )
    }
}
