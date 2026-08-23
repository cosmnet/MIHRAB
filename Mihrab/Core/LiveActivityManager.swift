// @preconcurrency: ActivityKit's `Activity` is a plain non-Sendable class, so
// awaiting its `update`/`end` from this @MainActor type reads as a cross-
// isolation send under Swift 6. The calls are all serialised through this
// main-actor singleton, which is exactly the guarantee the compiler wants.
@preconcurrency import ActivityKit
import Foundation
import UIKit

/// Owns the prayer-countdown Live Activity for its whole life.
///
/// The old version was called once from `RootView.task`, which meant: open the
/// app 31 minutes before Maghrib and no activity ever appeared; open it 20
/// minutes before and the activity appeared and then stayed on the Lock Screen
/// indefinitely, counting down to a moment that had already passed.
///
/// This version drives itself:
/// * a **tick** re-evaluates on a timer while the app is in the foreground, and
///   once more each time the app becomes active or goes to the background;
/// * the activity **starts** exactly when the countdown window opens, even if
///   the app was opened long before it;
/// * it **ends** on its own at prayer time via `ActivityUIDismissalPolicy
///   .after(_:)`, so the card lingers for a couple of minutes and then leaves;
/// * a **hard ceiling** keeps us inside ActivityKit's 8-hour active / 12-hour
///   total budget even if something goes wrong with the timer.
@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    /// The countdown card appears this long before the prayer.
    static let windowBeforePrayer: TimeInterval = 30 * 60

    /// The card stays on the Lock Screen this long after the prayer, then the
    /// system removes it.
    static let lingerAfterPrayer: TimeInterval = 3 * 60

    /// ActivityKit allows 8 h active / 12 h total. A prayer countdown needs
    /// half an hour; anything older than this is a bug and gets cleaned up.
    static let hardCeiling: TimeInterval = 4 * 3_600

    /// How often the foreground tick re-evaluates.
    private static let tickInterval: TimeInterval = 60

    private var activity: Activity<PrayerActivityAttributes>?
    private var startedAt: Date?
    private var currentPrayerTime: Date?

    private var tickTask: Task<Void, Never>?
    private var observersInstalled = false

    private init() {}

    // MARK: - Entry point

    /// **The single line `RootView` (or `MihrabApp`) needs:**
    /// `LiveActivityManager.activate()`
    ///
    /// Idempotent — call it from `.task`, `.onAppear`, wherever. It installs the
    /// scene-phase observers, runs one immediate evaluation and then keeps
    /// itself honest without further help.
    static func activate() {
        shared.start()
    }

    private func start() {
        installObservers()
        scheduleTick()
        Task { await self.evaluate() }
    }

    private func installObservers() {
        guard !observersInstalled else { return }
        observersInstalled = true

        let center = NotificationCenter.default
        center.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { _ in
            Task { @MainActor in
                LiveActivityManager.shared.scheduleTick()
                await LiveActivityManager.shared.evaluate()
            }
        }
        center.addObserver(
            forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main
        ) { _ in
            Task { @MainActor in
                // One last evaluation, then stop burning a timer in the
                // background — the dismissal policy takes it from here.
                await LiveActivityManager.shared.evaluate()
                LiveActivityManager.shared.cancelTick()
            }
        }
    }

    private func scheduleTick() {
        cancelTick()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.tickInterval))
                guard !Task.isCancelled else { return }
                await self?.evaluate()
            }
        }
    }

    private func cancelTick() {
        tickTask?.cancel()
        tickTask = nil
    }

    // MARK: - Evaluation

    /// Reads the repository and brings the activity in line with the clock.
    func evaluate(now: Date = Date()) async {
        let repository = PrayerTimesRepository.shared
        await update(for: repository.today, tomorrow: repository.tomorrow, now: now)
    }

    /// Kept for the existing `RootView.task` call site.
    func update(for day: DayPrayerTimes?, tomorrow: DayPrayerTimes?) async {
        await update(for: day, tomorrow: tomorrow, now: Date())
    }

    func update(for day: DayPrayerTimes?, tomorrow: DayPrayerTimes?, now: Date) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            await end()
            return
        }

        // Safety net for the 8 h / 12 h budget.
        if let startedAt, now.timeIntervalSince(startedAt) > Self.hardCeiling {
            await end()
        }

        guard let next = day?.nextPrayer(after: now, tomorrow: tomorrow) else {
            await end()
            return
        }

        let timeUntil = next.date.timeIntervalSince(now)
        guard timeUntil <= Self.windowBeforePrayer else {
            // Too early. Nothing on screen, and the tick will come back.
            await end()
            return
        }

        let content = makeContent(prayer: next.prayer, at: next.date, now: now)

        if let activity, currentPrayerTime == next.date {
            await activity.update(content)
        } else {
            // A different prayer than the one on screen: retire the old card
            // first so two never coexist.
            if activity != nil { await end() }
            let attributes = PrayerActivityAttributes(
                cityName: LocationManager.shared.effectiveCityName
            )
            activity = try? Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            startedAt = activity == nil ? nil : now
            currentPrayerTime = activity == nil ? nil : next.date
        }
    }

    private func makeContent(
        prayer: Prayer, at date: Date, now: Date
    ) -> ActivityContent<PrayerActivityAttributes.ContentState> {
        let state = PrayerActivityAttributes.ContentState(
            prayerName: prayer.localizedNamazName,
            prayerArabic: prayer.arabicName,
            prayerTime: date
        )
        // Relevance rises as the prayer approaches, so on a crowded Lock Screen
        // the card climbs while it matters and sinks once it does not.
        let remaining = max(0, date.timeIntervalSince(now))
        let closeness = 1 - min(1, remaining / Self.windowBeforePrayer)
        return ActivityContent(
            state: state,
            // The countdown is meaningless past the prayer moment — after that
            // the system may show the card greyed rather than lying.
            staleDate: date,
            relevanceScore: 50 + closeness * 50
        )
    }

    // MARK: - Teardown

    /// Ends the current activity, letting it linger briefly on the Lock Screen
    /// when the prayer moment has just passed.
    func end() async {
        guard let current = activity else {
            startedAt = nil
            currentPrayerTime = nil
            return
        }
        let policy: ActivityUIDismissalPolicy
        if let prayerTime = currentPrayerTime, prayerTime <= Date() {
            policy = .after(prayerTime.addingTimeInterval(Self.lingerAfterPrayer))
        } else {
            policy = .immediate
        }
        activity = nil
        startedAt = nil
        currentPrayerTime = nil
        await current.end(nil, dismissalPolicy: policy)
    }

    /// Clears any activity left over from a previous launch (a crash, or a
    /// force-quit mid-countdown). Cheap; call alongside `activate()`.
    func cleanUpOrphans() async {
        for stale in Activity<PrayerActivityAttributes>.activities where stale.id != activity?.id {
            await stale.end(nil, dismissalPolicy: .immediate)
        }
    }
}
