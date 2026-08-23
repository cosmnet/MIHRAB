import SwiftUI

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

    /// Starts once per install. Safe to call on every appearance.
    func startIfNeeded(markCount: Int) {
        guard !isCompleted, !isRunning, markCount > 0 else { return }
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
                            focus: proxy[stop.bounds],
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

// MARK: - Spotlight

/// Dimmed scrim with a punched-out rounded window plus a glass tip card.
/// Tapping anywhere advances; the card carries an explicit control for VoiceOver.
struct CoachMarkSpotlight: View {
    let focus: CGRect
    let title: String
    let message: String
    let step: Int
    let total: Int
    let onAdvance: () -> Void
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var padded: CGRect { focus.insetBy(dx: -10, dy: -8) }

    var body: some View {
        GeometryReader { proxy in
            let placeBelow = padded.midY < proxy.size.height * 0.5
            ZStack(alignment: .topLeading) {
                scrim
                halo
                card
                    .frame(maxWidth: min(proxy.size.width - 40, 360))
                    .position(
                        x: proxy.size.width / 2,
                        y: placeBelow
                            ? min(padded.maxY + 118, proxy.size.height - 110)
                            : max(padded.minY - 118, 130)
                    )
            }
            .contentShape(Rectangle())
            .onTapGesture { onAdvance() }
        }
        .ignoresSafeArea()
        .opacity(appeared ? 1 : 0)
        .animation(reduceMotion ? .easeInOut(duration: 0.18) : MihrabMotion.standardAnimation, value: appeared)
        .animation(reduceMotion ? nil : MihrabMotion.gentleAnimation, value: focus)
        .onAppear { appeared = true }
    }

    private var scrim: some View {
        Rectangle()
            .fill(MihrabColor.abyss.opacity(0.82))
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: min(padded.height / 2, MihrabSpace.rowRadius), style: .continuous)
                    .frame(width: padded.width, height: padded.height)
                    .offset(x: padded.minX, y: padded.minY)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
            .ignoresSafeArea()
    }

    private var halo: some View {
        RoundedRectangle(cornerRadius: min(padded.height / 2, MihrabSpace.rowRadius), style: .continuous)
            .strokeBorder(MihrabColor.brass.opacity(0.75), lineWidth: 1.5)
            .frame(width: padded.width, height: padded.height)
            .offset(x: padded.minX, y: padded.minY)
            .allowsHitTesting(false)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(format: L10n.obStepFormat, step, total))
                .ornamentalCaps()

            Text(title)
                .font(.title3.bold())
                .foregroundStyle(MihrabColor.textPrimary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(MihrabColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                if step < total {
                    Button(L10n.coachSkipTour, action: onSkip)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MihrabColor.textSecondary)
                        .frame(minHeight: MihrabSpace.hit)
                }
                Spacer(minLength: 0)
                Button(step < total ? L10n.coachNext : L10n.coachGotIt, action: onAdvance)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(MihrabColor.abyss)
                    .padding(.horizontal, 20)
                    .frame(minHeight: MihrabSpace.hit)
                    .background(Capsule().fill(MihrabColor.mint))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mihrabSolidCard(cornerRadius: MihrabSpace.cardRadius, fill: MihrabColor.forest)
        .accessibilityElement(children: .contain)
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

/// First-run tour of the tab bar. The tab bar itself cannot publish anchors, so
/// the spotlight is placed geometrically over the nth of `stops.count` slots.
struct TabBarTourOverlay: View {
    let stops: [TabTourStop]
    var controller: CoachMarkController = .tabTour
    var startDelay: Double = 1.1
    var onFocus: (Int) -> Void = { _ in }
    var onFinish: () -> Void = {}

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if controller.isRunning, controller.index < stops.count {
                    let stop = stops[controller.index]
                    CoachMarkSpotlight(
                        focus: slot(at: controller.index, in: proxy),
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
                if controller.isRunning { onFocus(0) }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(controller.isRunning)
    }

    private func slot(at index: Int, in proxy: GeometryProxy) -> CGRect {
        let count = max(stops.count, 1)
        let sideInset: CGFloat = 22
        let usable = max(proxy.size.width - sideInset * 2, 1)
        let width = usable / CGFloat(count)
        let height: CGFloat = 46
        let bottomInset = max(proxy.safeAreaInsets.bottom, 12)
        let centerY = proxy.size.height - bottomInset - 26
        return CGRect(
            x: sideInset + width * CGFloat(index),
            y: centerY - height / 2,
            width: width,
            height: height
        )
    }
}
