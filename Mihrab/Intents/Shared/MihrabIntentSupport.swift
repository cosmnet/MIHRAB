import Foundation
import WidgetKit

/// Plumbing shared by every App Intent and by the widget extension.
///
/// Everything here reads through the App Group, never through the app's own
/// singletons, so an intent can answer "when is the next prayer" while the app
/// is not running at all. Nothing in this file may reference an app-target type.

// MARK: - Strings

extension LocalizedStringResource {
    /// Wraps an already-localized `L10n` string.
    ///
    /// `L10n` resolves en/tr/ar itself at runtime; App Intents insists on
    /// `LocalizedStringResource`. A key with no catalog entry resolves to the
    /// key itself, which here *is* the finished translation.
    static func mihrab(_ text: String) -> LocalizedStringResource {
        LocalizedStringResource(stringLiteral: text)
    }
}

// MARK: - Errors

/// Honest failures. An intent that cannot answer says so instead of guessing.
enum MihrabIntentError: Error, CustomLocalizedStringResourceConvertible {
    /// No cached schedule in the App Group yet — the app has never refreshed.
    case noSchedule
    /// A schedule exists but carries no usable coordinate.
    case noLocation
    /// The requested prayer is not in today's cached schedule.
    case missingPrayer

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noSchedule: LocalizedStringResource(stringLiteral: L10n.intErrNoSchedule)
        case .noLocation: LocalizedStringResource(stringLiteral: L10n.intErrNoLocation)
        case .missingPrayer: LocalizedStringResource(stringLiteral: L10n.intErrMissingPrayer)
        }
    }
}

// MARK: - Shared reads

/// Read-only view of the App Group cache, shaped for intents and widgets.
enum MihrabIntentData {

    static var snapshot: SharedPrayerSnapshot? { SharedPrayerCache.load() }

    static func day(containing date: Date = Date()) -> DayPrayerTimes? {
        snapshot?.day(containing: date)
    }

    static func tomorrow(after date: Date = Date()) -> DayPrayerTimes? {
        guard let next = Calendar.current.date(byAdding: .day, value: 1, to: date) else { return nil }
        return snapshot?.day(containing: next)
    }

    /// Next prayer, rolling over to tomorrow's Fajr once Isha has passed.
    static func nextPrayer(after date: Date = Date()) -> (prayer: Prayer, date: Date)? {
        guard let today = day(containing: date) else { return nil }
        return today.nextPrayer(after: date, tomorrow: tomorrow(after: date))
    }

    static var cityName: String? {
        let name = snapshot?.cityName.trimmingCharacters(in: .whitespaces)
        return (name?.isEmpty == false) ? name : nil
    }

    /// Latitude/longitude last used for a real calculation. `nil` when the user
    /// has never granted location and never picked a city.
    static var coordinate: (latitude: Double, longitude: Double)? {
        guard let snapshot else { return nil }
        guard snapshot.latitude != 0 || snapshot.longitude != 0 else { return nil }
        return (snapshot.latitude, snapshot.longitude)
    }

    /// `HH:mm` in the user's locale — the one format every spoken answer uses.
    static func clock(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .hour(.defaultDigits(amPM: .abbreviated))
                .minute(.twoDigits)
                .locale(Locale(identifier: L10n.localeIdentifier))
        )
    }

    /// "2 sa 15 dk" — coarse on purpose; a spoken answer with seconds is noise.
    static func remaining(from now: Date, to target: Date) -> String {
        let seconds = max(0, Int(target.timeIntervalSince(now)))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 { return L10n.intHoursMinutes(hours, minutes) }
        return L10n.intMinutes(minutes)
    }
}

// MARK: - Dhikr counter shared across processes

/// The dhikr tally an intent (or an interactive widget button) can move without
/// launching the app.
///
/// The app's own counter lives in SwiftData, whose store is **not** in the App
/// Group, so a widget process cannot touch it. This is the bridge: increments
/// land here, and the app drains `pending` into SwiftData the next time it runs.
enum SharedDhikrCounter {

    private enum Key {
        static let day = "mihrab.shared.dhikr.day"
        static let count = "mihrab.shared.dhikr.count"
        static let pending = "mihrab.shared.dhikr.pending"
        static let phrase = "mihrab.shared.dhikr.phrase"
    }

    /// Widget kinds to refresh after a write.
    static let widgetKinds = ["DhikrCounterWidget"]

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: SharedPrayerCache.appGroupID) ?? .standard
    }

    private static var todayKey: String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    /// Rolls the tally over at midnight without needing a timer.
    private static func rollIfNeeded(_ defaults: UserDefaults) {
        let today = todayKey
        guard defaults.string(forKey: Key.day) != today else { return }
        defaults.set(today, forKey: Key.day)
        defaults.set(0, forKey: Key.count)
    }

    static var todayCount: Int {
        let defaults = defaults
        rollIfNeeded(defaults)
        return defaults.integer(forKey: Key.count)
    }

    /// Id of the phrase the counter is on. Written by the app, read by widgets.
    static var phraseID: String {
        get { defaults.string(forKey: Key.phrase) ?? "subhanallah" }
        set { defaults.set(newValue, forKey: Key.phrase) }
    }

    /// Adds `amount` to today's tally and returns the new total.
    @discardableResult
    static func add(_ amount: Int, phraseID: String? = nil) -> Int {
        let amount = max(1, amount)
        let defaults = defaults
        rollIfNeeded(defaults)
        let total = defaults.integer(forKey: Key.count) + amount
        defaults.set(total, forKey: Key.count)
        defaults.set(defaults.integer(forKey: Key.pending) + amount, forKey: Key.pending)
        if let phraseID { defaults.set(phraseID, forKey: Key.phrase) }
        reloadWidgets()
        return total
    }

    /// Called by the app: returns the increments made outside the app and
    /// clears them, so the same taps are never merged into SwiftData twice.
    @discardableResult
    static func drainPending() -> Int {
        let defaults = defaults
        let pending = defaults.integer(forKey: Key.pending)
        defaults.set(0, forKey: Key.pending)
        return pending
    }

    /// Called by the app so widgets show the in-app total, not just their own.
    static func publishAppTotal(_ total: Int, phraseID: String? = nil) {
        let defaults = defaults
        defaults.set(todayKey, forKey: Key.day)
        defaults.set(max(0, total), forKey: Key.count)
        if let phraseID { defaults.set(phraseID, forKey: Key.phrase) }
        reloadWidgets()
    }

    static func reloadWidgets() {
        for kind in widgetKinds {
            WidgetCenter.shared.reloadTimelines(ofKind: kind)
        }
        ControlCenterRefresh.reloadDhikrControl()
    }
}

/// Control Center surfaces refresh on their own schedule; this nudges them.
enum ControlCenterRefresh {
    static let dhikrControlKind = "com.caferkarakaya.mihrab.control.dhikr"
    static let nextPrayerControlKind = "com.caferkarakaya.mihrab.control.nextPrayer"

    static func reloadDhikrControl() {
        ControlCenter.shared.reloadControls(ofKind: dhikrControlKind)
    }

    static func reloadNextPrayerControl() {
        ControlCenter.shared.reloadControls(ofKind: nextPrayerControlKind)
    }
}

// MARK: - Deep links

/// A hand-off slot for "open the app *here*".
///
/// `OpenIntent` brings the app forward but cannot carry state across the
/// process boundary on its own, so the request is parked in the App Group and
/// the app consumes it on the next foreground pass.
enum MihrabDeepLink {

    private enum Key {
        static let tab = "mihrab.shared.deeplink.tab"
        static let dhikrPhrase = "mihrab.shared.deeplink.dhikrPhrase"
        static let dhikrTarget = "mihrab.shared.deeplink.dhikrTarget"
    }

    /// Raw tab identifiers. Kept as strings because `AppTab` is app-target only.
    enum Tab: String, CaseIterable, Sendable {
        case today, times, qibla, deen, dhikr
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: SharedPrayerCache.appGroupID) ?? .standard
    }

    static func requestTab(_ tab: Tab) {
        defaults.set(tab.rawValue, forKey: Key.tab)
    }

    /// Reads **and clears** the pending tab request.
    static func consumeTab() -> Tab? {
        let raw = defaults.string(forKey: Key.tab)
        defaults.removeObject(forKey: Key.tab)
        return raw.flatMap(Tab.init(rawValue:))
    }

    static func requestDhikrSession(phraseID: String, target: Int?) {
        defaults.set(phraseID, forKey: Key.dhikrPhrase)
        if let target { defaults.set(target, forKey: Key.dhikrTarget) }
        requestTab(.dhikr)
    }

    /// Reads **and clears** the pending dhikr session request.
    static func consumeDhikrSession() -> (phraseID: String, target: Int?)? {
        guard let phrase = defaults.string(forKey: Key.dhikrPhrase) else { return nil }
        let target = defaults.object(forKey: Key.dhikrTarget) as? Int
        defaults.removeObject(forKey: Key.dhikrPhrase)
        defaults.removeObject(forKey: Key.dhikrTarget)
        return (phrase, target)
    }

    /// URL form, for `widgetURL(_:)` and `Link` — those cannot run an intent.
    static func url(for tab: Tab) -> URL? {
        URL(string: "mihrab://\(tab.rawValue)")
    }
}
