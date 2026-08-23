import Foundation
import Observation

/// Prayer-source choice and per-prayer ± corrections.
///
/// These live here rather than in `AppSettings` (not this agent's file) and are
/// persisted in the App Group so the widgets extension resolves the same times
/// the app shows.
@Observable
public final class PrayerSourcePreferences: @unchecked Sendable {
    public static let shared = PrayerSourcePreferences()

    private let defaults: UserDefaults

    private enum Key {
        static let source = "prayer.source"
        static let offsets = "prayer.offsets"
    }

    /// The tightest correction we let a user dial in. Anything larger stops
    /// being a correction and becomes a different prayer time.
    public static let offsetRange = -30...30

    public var source: PrayerSource {
        didSet {
            guard source != oldValue else { return }
            defaults.set(source.rawValue, forKey: Key.source)
        }
    }

    /// Per-prayer correction in minutes. Absent = 0.
    public private(set) var offsets: [Prayer: Int] {
        didSet { persistOffsets() }
    }

    public init(defaults: UserDefaults? = nil) {
        let store = defaults ?? UserDefaults(suiteName: SharedPrayerCache.appGroupID) ?? .standard
        self.defaults = store

        if let raw = store.string(forKey: Key.source), let value = PrayerSource(rawValue: raw) {
            source = value
        } else {
            // Turkish users overwhelmingly expect Diyanet; everyone else gets
            // whatever method they picked, untouched.
            source = Self.prefersTurkishDefaults ? .diyanet : .standard
        }

        if let stored = store.dictionary(forKey: Key.offsets) as? [String: Int] {
            offsets = stored.reduce(into: [:]) { result, entry in
                if let prayer = Prayer(rawValue: entry.key) { result[prayer] = entry.value }
            }
        } else {
            offsets = [:]
        }
    }

    public func offset(for prayer: Prayer) -> Int { offsets[prayer] ?? 0 }

    public func setOffset(_ minutes: Int, for prayer: Prayer) {
        let clamped = min(max(minutes, Self.offsetRange.lowerBound), Self.offsetRange.upperBound)
        if clamped == 0 {
            offsets.removeValue(forKey: prayer)
        } else {
            offsets[prayer] = clamped
        }
    }

    public func resetOffsets() { offsets = [:] }

    public var hasOffsets: Bool { offsets.contains { $0.value != 0 } }

    private func persistOffsets() {
        let raw = offsets.reduce(into: [String: Int]()) { $0[$1.key.rawValue] = $1.value }
        defaults.set(raw, forKey: Key.offsets)
    }

    private static var prefersTurkishDefaults: Bool {
        if Locale.autoupdatingCurrent.language.languageCode?.identifier == "tr" { return true }
        if Locale.autoupdatingCurrent.region?.identifier == "TR" { return true }
        return Locale.preferredLanguages.contains { $0.hasPrefix("tr") }
    }
}
