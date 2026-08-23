import CoreLocation
import Foundation
import Observation
import WidgetKit

/// The single piece of state the watch screens read from.
///
/// It owns the recomputation policy, which is the only interesting decision
/// here: prayer times change once a day, so recomputing them on a timer would
/// be pure waste. The schedule is rebuilt when the inputs change — new settings
/// from the phone, a new coordinate, or the calendar day rolling over — and the
/// countdown itself is drawn by `Text(timerInterval:)`, which the system ticks
/// without waking the app at all.
@MainActor
@Observable
final class WatchAppModel {

    static let shared = WatchAppModel()

    enum ScheduleState: Equatable {
        case loading
        /// No settings from the phone and no fix of our own.
        case needsLocation
        /// A coordinate exists but the sun does not rise or set there today.
        case unavailableAtLatitude
        case ready(WatchSchedule)
    }

    private(set) var state: ScheduleState = .loading
    private(set) var loggedToday: Set<Prayer> = []
    private(set) var dhikrTotal = 0

    private let connectivity = WatchConnectivityClient.shared
    private let location = WatchLocationProvider.shared
    private var lastComputedDayKey: String?
    private var lastFingerprint: String?

    private init() {}

    var schedule: WatchSchedule? {
        if case let .ready(schedule) = state { return schedule }
        return nil
    }

    var settings: WatchSettingsPayload? { connectivity.settings }

    /// `true` when the phone has never talked to this watch. The Times screen
    /// says so plainly instead of showing an empty list.
    var isWaitingForPhone: Bool {
        !connectivity.hasEverReceivedSettings && WatchSharedState.loadSettings() == nil
    }

    // MARK: - Lifecycle

    func onAppear() {
        connectivity.activate()
        loggedToday = WatchSharedState.loggedPrayers()
        dhikrTotal = WatchSharedState.dhikrTodayCount
        refresh()
    }

    /// Recomputes when something that feeds the calculation has changed.
    /// Cheap to call on every foreground and every settings delivery.
    func refresh(force: Bool = false) {
        let payload = connectivity.settings ?? WatchSharedState.loadSettings()
        let watchFix = location.coordinate
        let dayKey = WatchBridge.dayKey(for: Date())
        let fingerprint = [
            payload?.calculationFingerprint ?? "-",
            watchFix.map { String(format: "%.3f,%.3f", $0.latitude, $0.longitude) } ?? "-",
        ].joined(separator: "#")

        if !force, lastComputedDayKey == dayKey, lastFingerprint == fingerprint, schedule != nil {
            return
        }
        lastComputedDayKey = dayKey
        lastFingerprint = fingerprint

        loggedToday = WatchSharedState.loggedPrayers()
        dhikrTotal = WatchSharedState.dhikrTodayCount

        guard payload?.hasCoordinate == true || watchFix != nil else {
            // No coordinate anywhere. Ask the watch's own sensor, and say so
            // meanwhile — never guess a city.
            location.startLocation()
            state = .needsLocation
            return
        }

        if let schedule = WatchScheduleBuilder.schedule(payload: payload, watchFix: watchFix) {
            state = .ready(schedule)
            WidgetCenter.shared.reloadAllTimelines()
        } else {
            // A coordinate exists but `PrayerEngine` refused it: above the polar
            // circles the sun does not cross the horizon and there is no honest
            // answer to give.
            state = .unavailableAtLatitude
        }
    }

    // MARK: - Prayer log

    /// The five fard prayers. Sunrise is a marker, never something to log.
    static let fardPrayers: [Prayer] = Prayer.allCases.filter(\.isNotifiable)

    func isLogged(_ prayer: Prayer) -> Bool { loggedToday.contains(prayer) }

    func toggleLog(_ prayer: Prayer) {
        guard prayer.isNotifiable else { return }
        var set = loggedToday
        let nowLogged: Bool
        if set.contains(prayer) {
            set.remove(prayer)
            nowLogged = false
        } else {
            set.insert(prayer)
            nowLogged = true
        }
        loggedToday = set
        WatchSharedState.setLogged(set)
        // Queued, not sent-and-hoped: `transferUserInfo` survives the phone
        // being out of range and delivers when the pair meets again.
        connectivity.enqueuePrayerLog(prayer, logged: nowLogged)
        nowLogged ? WatchHaptics.success() : WatchHaptics.tick()
        WidgetCenter.shared.reloadAllTimelines()
    }

    var loggedCount: Int { loggedToday.intersection(Self.fardPrayers).count }

    // MARK: - Dhikr

    func addDhikr(_ amount: Int, phraseID: String) {
        dhikrTotal = WatchSharedState.addDhikr(amount, phraseID: phraseID)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Called when the counter screen is left, so a session's taps travel in one
    /// envelope rather than one per bead.
    func flushDhikr() {
        connectivity.enqueueDhikr()
    }
}
