import Foundation

/// The watch's own copy of everything the phone sent, plus the small counters
/// the complications read.
///
/// This *is* an App Group — but the watch's own. The container the watch app
/// and `MihrabWatchWidgets` share lives on the watch; the identically-named
/// container on the iPhone is a different directory on a different device and
/// is never visible from here. That is precisely why the settings arrive over
/// WatchConnectivity and are re-persisted locally: once written here, both the
/// app and its complications work with no phone in range at all.
enum WatchSharedState {

    private enum Key {
        static let settings = "mihrab.watch.settings"
        static let dhikrDay = "mihrab.watch.dhikr.day"
        static let dhikrCount = "mihrab.watch.dhikr.count"
        static let dhikrPhrase = "mihrab.watch.dhikr.phrase"
        /// Watch-side dhikr taps not yet handed to the phone.
        static let dhikrOutbox = "mihrab.watch.dhikr.outbox"
        static let logPrefix = "mihrab.watch.prayerLog."
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: WatchBridge.appGroupID) ?? .standard
    }

    // MARK: - Settings

    static func save(_ payload: WatchSettingsPayload) {
        guard let data = try? WatchBridge.encoder.encode(payload) else { return }
        defaults.set(data, forKey: Key.settings)
    }

    static func loadSettings() -> WatchSettingsPayload? {
        guard let data = defaults.data(forKey: Key.settings) else { return nil }
        return try? WatchBridge.decoder.decode(WatchSettingsPayload.self, from: data)
    }

    // MARK: - Dhikr tally

    private static func rollDhikrIfNeeded(_ defaults: UserDefaults) {
        let today = WatchBridge.dayKey(for: Date())
        guard defaults.string(forKey: Key.dhikrDay) != today else { return }
        defaults.set(today, forKey: Key.dhikrDay)
        defaults.set(0, forKey: Key.dhikrCount)
    }

    static var dhikrTodayCount: Int {
        let defaults = defaults
        rollDhikrIfNeeded(defaults)
        return defaults.integer(forKey: Key.dhikrCount)
    }

    static var dhikrPhraseID: String {
        get { defaults.string(forKey: Key.dhikrPhrase) ?? WatchDhikrCatalog.default.id }
        set { defaults.set(newValue, forKey: Key.dhikrPhrase) }
    }

    /// Adds to today's watch tally and to the outbox awaiting the phone.
    /// Returns the new total.
    @discardableResult
    static func addDhikr(_ amount: Int, phraseID: String) -> Int {
        guard amount != 0 else { return dhikrTodayCount }
        let defaults = defaults
        rollDhikrIfNeeded(defaults)
        let total = max(0, defaults.integer(forKey: Key.dhikrCount) + amount)
        defaults.set(total, forKey: Key.dhikrCount)
        defaults.set(phraseID, forKey: Key.dhikrPhrase)
        if amount > 0 {
            defaults.set(defaults.integer(forKey: Key.dhikrOutbox) + amount, forKey: Key.dhikrOutbox)
        }
        return total
    }

    /// Takes the pending taps and clears them, so a flush that succeeds is
    /// never sent twice and one that fails can be re-queued by the caller.
    static func drainDhikrOutbox() -> Int {
        let defaults = defaults
        let pending = defaults.integer(forKey: Key.dhikrOutbox)
        defaults.set(0, forKey: Key.dhikrOutbox)
        return pending
    }

    static func returnToDhikrOutbox(_ amount: Int) {
        guard amount > 0 else { return }
        let defaults = defaults
        defaults.set(defaults.integer(forKey: Key.dhikrOutbox) + amount, forKey: Key.dhikrOutbox)
    }

    // MARK: - Prayer log

    private static func logKey(_ dayKey: String) -> String { Key.logPrefix + dayKey }

    static func loggedPrayers(on date: Date = Date()) -> Set<Prayer> {
        let raw = defaults.stringArray(forKey: logKey(WatchBridge.dayKey(for: date))) ?? []
        return Set(raw.compactMap(Prayer.init(rawValue:)))
    }

    static func setLogged(_ logged: Set<Prayer>, on date: Date = Date()) {
        defaults.set(logged.map(\.rawValue).sorted(), forKey: logKey(WatchBridge.dayKey(for: date)))
    }

    /// Mirrors the phone's marks for the day they were captured. Only applied
    /// forward — the watch never rewrites a day the phone did not talk about.
    static func mergePhoneLog(ids: [String], dayKey: String) {
        guard let date = WatchBridge.date(fromDayKey: dayKey) else { return }
        let phone = Set(ids.compactMap(Prayer.init(rawValue:)))
        setLogged(phone.union(loggedPrayers(on: date)), on: date)
    }
}
