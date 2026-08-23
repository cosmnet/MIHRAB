import Foundation

/// A light iCloud backup layer for the small stores that live in
/// `UserDefaults` rather than SwiftData.
///
/// Covered stores (all read/written **through their own existing keys** — none
/// of those files is modified by this one):
///
/// | Store             | File                                  | Keys                                            |
/// |-------------------|---------------------------------------|-------------------------------------------------|
/// | `PrayerLogStore`  | `Features/Today/PrayerLogStore.swift` | `prayerLog.yyyy-MM-dd` (`[String]`)             |
/// | `FastingLogStore` | `Features/Ramadan/FastingLogStore.swift` | `ramadanFastedDays` (`[String]`)             |
/// | `EsmaLibrary`     | `Features/Deen/EsmaLibrary.swift`     | `mihrab.esma.favorites`, `mihrab.esma.visited`  |
/// | `DhikrStore`      | `Features/Dhikr/DhikrLibrary.swift`   | `mihrab.dhikr.custom` (Data), `…sound`, `…haptics`, `…keepAwake`, `…strandDefault`, `…lastPhrase` |
///
/// `NSUbiquitousKeyValueStore` is capped at **1 MB total / 1024 keys / 1 MB per
/// value**, so everything is packed into a *single* JSON blob under one key
/// instead of mirroring hundreds of per-day keys.
///
/// Those stores read `UserDefaults` lazily on every access, so a `pull()` is
/// visible to them immediately. Their `@Observable` `revision` counter is not
/// bumped from here (that would mean editing them) — call sites should refresh
/// after a pull; in practice `pull()` runs at launch, before any view exists.
enum KeyValueSync {

    /// Single key holding the whole snapshot.
    static let ubiquitousKey = "mihrab.kv.snapshot.v1"

    /// Local marker so we can tell "we wrote this" from "the cloud did".
    private static let localStampKey = "mihrab.kv.localStamp"

    enum MergeStrategy: Sendable {
        /// Take the cloud copy only when it is newer than our last local write.
        case newerWins
        /// Union sets and take the cloud copy for scalars. Never removes a
        /// logged prayer or a fasted day — additive by design.
        case unionAdditive
        /// Overwrite local unconditionally (used by an explicit "restore").
        case cloudWins
    }

    // MARK: - Snapshot

    struct Snapshot: Codable, Sendable {
        var createdAt: Date
        /// `prayerLog.yyyy-MM-dd` → raw `Prayer` values.
        var prayerLog: [String: [String]]
        var fastedDays: [String]
        var esmaFavorites: [String]
        var esmaVisited: [String]
        /// Base64 of `mihrab.dhikr.custom`.
        var dhikrCustom: String?
        var dhikrFlags: [String: Bool]
        var dhikrLastPhrase: String?

        init(
            createdAt: Date = Date(),
            prayerLog: [String: [String]] = [:],
            fastedDays: [String] = [],
            esmaFavorites: [String] = [],
            esmaVisited: [String] = [],
            dhikrCustom: String? = nil,
            dhikrFlags: [String: Bool] = [:],
            dhikrLastPhrase: String? = nil
        ) {
            self.createdAt = createdAt
            self.prayerLog = prayerLog
            self.fastedDays = fastedDays
            self.esmaFavorites = esmaFavorites
            self.esmaVisited = esmaVisited
            self.dhikrCustom = dhikrCustom
            self.dhikrFlags = dhikrFlags
            self.dhikrLastPhrase = dhikrLastPhrase
        }
    }

    private enum LocalKey {
        static let prayerLogPrefix = "prayerLog."
        static let fasted = "ramadanFastedDays"
        static let esmaFavorites = "mihrab.esma.favorites"
        static let esmaVisited = "mihrab.esma.visited"
        static let dhikrCustom = "mihrab.dhikr.custom"
        static let dhikrSound = "mihrab.dhikr.sound"
        static let dhikrHaptics = "mihrab.dhikr.haptics"
        static let dhikrKeepAwake = "mihrab.dhikr.keepAwake"
        static let dhikrStrand = "mihrab.dhikr.strandDefault"
        static let dhikrLastPhrase = "mihrab.dhikr.lastPhrase"
    }

    private static var local: UserDefaults { .standard }
    private static var cloud: NSUbiquitousKeyValueStore { .default }

    // MARK: - Export

    /// Reads every covered key out of `UserDefaults`. Pure read — the stores
    /// themselves are untouched.
    static func exportSnapshot() -> Snapshot {
        var log: [String: [String]] = [:]
        for (key, value) in local.dictionaryRepresentation()
        where key.hasPrefix(LocalKey.prayerLogPrefix) {
            if let days = value as? [String], !days.isEmpty { log[key] = days }
        }

        var flags: [String: Bool] = [:]
        for key in [LocalKey.dhikrSound, LocalKey.dhikrHaptics,
                    LocalKey.dhikrKeepAwake, LocalKey.dhikrStrand] {
            if let value = local.object(forKey: key) as? Bool { flags[key] = value }
        }

        return Snapshot(
            prayerLog: log,
            fastedDays: local.stringArray(forKey: LocalKey.fasted) ?? [],
            esmaFavorites: local.stringArray(forKey: LocalKey.esmaFavorites) ?? [],
            esmaVisited: local.stringArray(forKey: LocalKey.esmaVisited) ?? [],
            dhikrCustom: local.data(forKey: LocalKey.dhikrCustom)?.base64EncodedString(),
            dhikrFlags: flags,
            dhikrLastPhrase: local.string(forKey: LocalKey.dhikrLastPhrase)
        )
    }

    /// JSON for an out-of-band export (share sheet, support ticket, tests).
    static func exportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(exportSnapshot())
    }

    static func decode(_ data: Data) throws -> Snapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Snapshot.self, from: data)
    }

    // MARK: - Import

    /// Writes a snapshot back into `UserDefaults` under the stores' own keys.
    static func importSnapshot(_ snapshot: Snapshot, strategy: MergeStrategy = .unionAdditive) {
        switch strategy {
        case .cloudWins:
            apply(snapshot, merging: false)
        case .unionAdditive:
            apply(snapshot, merging: true)
        case .newerWins:
            let localStamp = local.object(forKey: localStampKey) as? Date ?? .distantPast
            guard snapshot.createdAt > localStamp else { return }
            apply(snapshot, merging: true)
        }
    }

    private static func apply(_ snapshot: Snapshot, merging: Bool) {
        // Prayer log — union of logged prayers per day. A prayer you marked on
        // either device stays marked; nothing is ever un-marked by a sync.
        for (key, days) in snapshot.prayerLog {
            if merging, let existing = local.stringArray(forKey: key) {
                local.set(Array(Set(existing).union(days)), forKey: key)
            } else {
                local.set(days, forKey: key)
            }
        }

        setStrings(snapshot.fastedDays, key: LocalKey.fasted, merging: merging)
        setStrings(snapshot.esmaFavorites, key: LocalKey.esmaFavorites, merging: merging)
        setStrings(snapshot.esmaVisited, key: LocalKey.esmaVisited, merging: merging)

        if let base64 = snapshot.dhikrCustom, let data = Data(base64Encoded: base64) {
            // Custom dhikr is an opaque encoded array owned by `DhikrStore`;
            // we cannot merge it item-by-item without decoding its private
            // shape, so the newer blob wins as a whole.
            if !merging || local.data(forKey: LocalKey.dhikrCustom) == nil {
                local.set(data, forKey: LocalKey.dhikrCustom)
            }
        }

        for (key, value) in snapshot.dhikrFlags {
            if !merging || local.object(forKey: key) == nil {
                local.set(value, forKey: key)
            }
        }

        if let phrase = snapshot.dhikrLastPhrase, !merging || local.string(forKey: LocalKey.dhikrLastPhrase) == nil {
            local.set(phrase, forKey: LocalKey.dhikrLastPhrase)
        }
    }

    private static func setStrings(_ values: [String], key: String, merging: Bool) {
        if merging, let existing = local.stringArray(forKey: key) {
            local.set(Array(Set(existing).union(values)), forKey: key)
        } else {
            local.set(values, forKey: key)
        }
    }

    // MARK: - iCloud key-value store

    /// Pushes the current local state to iCloud. No-op when sync is off or the
    /// user is not entitled — turning Plus off must never *erase* the cloud copy,
    /// only stop updating it.
    @discardableResult
    static func push() -> Bool {
        guard CloudSyncPreference.isEnabled, CloudSyncPreference.isEntitled else { return false }
        guard let data = try? exportData() else { return false }
        guard data.count < 900_000 else { return false }   // 1 MB per-value ceiling
        cloud.set(data, forKey: ubiquitousKey)
        local.set(Date(), forKey: localStampKey)
        return cloud.synchronize()
    }

    /// Pulls whatever iCloud has and merges it in.
    @discardableResult
    static func pull(strategy: MergeStrategy = .newerWins) -> Bool {
        guard CloudSyncPreference.isEnabled, CloudSyncPreference.isEntitled else { return false }
        cloud.synchronize()
        guard let data = cloud.data(forKey: ubiquitousKey),
              let snapshot = try? decode(data) else { return false }
        importSnapshot(snapshot, strategy: strategy)
        return true
    }

    /// Observes external changes. Call once from the app delegate / `MihrabApp`;
    /// the returned token must be kept alive.
    ///
    /// **Wiring note for the main session:** call this from `MihrabApp` after
    /// `SubscriptionManager.refresh()`, and call `pull()` once at launch.
    static func startObserving(onChange: @escaping @Sendable () -> Void) -> NSObjectProtocol {
        cloud.synchronize()
        return NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud,
            queue: .main
        ) { _ in
            _ = pull(strategy: .unionAdditive)
            onChange()
        }
    }
}
