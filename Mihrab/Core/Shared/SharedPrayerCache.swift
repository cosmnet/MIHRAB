import Foundation

/// App Group-backed cache so the widgets extension can read prayer times
/// without networking. Pure Foundation — safe for app extensions.
public struct SharedPrayerSnapshot: Codable, Sendable {
    public let fetchedAt: Date
    public let latitude: Double
    public let longitude: Double
    public let cityName: String
    public let methodID: Int
    public let days: [DayPrayerTimes]

    // Added in a later revision. Both are optional so snapshots written by an
    // older build still decode — do not make them non-optional.

    /// `PrayerSource.rawValue` these times were resolved with, when known.
    public let sourceID: String?
    /// `true` when the days were computed on-device rather than fetched.
    /// Widgets can use it to caption "offline".
    public let isOfflineComputed: Bool?

    public init(fetchedAt: Date = Date(), latitude: Double, longitude: Double,
                cityName: String, methodID: Int, days: [DayPrayerTimes],
                sourceID: String? = nil, isOfflineComputed: Bool? = nil) {
        self.fetchedAt = fetchedAt
        self.latitude = latitude
        self.longitude = longitude
        self.cityName = cityName
        self.methodID = methodID
        self.days = days
        self.sourceID = sourceID
        self.isOfflineComputed = isOfflineComputed
    }

    public func day(containing date: Date = Date()) -> DayPrayerTimes? {
        let cal = Calendar.current
        return days.first { cal.isDate($0.date, inSameDayAs: date) }
    }
}

public enum SharedPrayerCache {
    public static let appGroupID = "group.com.caferkarakaya.mihrab"

    private static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    private static var fileURL: URL? { containerURL?.appendingPathComponent("prayer_snapshot.json") }

    public static func save(_ snapshot: SharedPrayerSnapshot) {
        guard let fileURL,
              let data = try? JSONEncoder.prayerEncoder.encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    public static func load() -> SharedPrayerSnapshot? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder.prayerDecoder.decode(SharedPrayerSnapshot.self, from: data)
    }

    /// Drop a snapshot that failed to decode. Cheap self-heal for a truncated
    /// file left behind by a killed background task.
    public static func reset() {
        guard let fileURL else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }
}

public extension JSONEncoder {
    static var prayerEncoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }
}

public extension JSONDecoder {
    static var prayerDecoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}
