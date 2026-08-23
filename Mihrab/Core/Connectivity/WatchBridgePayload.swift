import Foundation

// MARK: - Why this file exists

/// The wire format shared by the iPhone app and the watchOS app.
///
/// Deliberately plain Foundation. It is compiled into **both** targets, so it
/// must never touch UIKit, WatchKit, SwiftUI, WatchConnectivity, `AppSettings`
/// or anything else that only exists on one side.
///
/// The architectural decision it encodes:
///
/// **App Group containers are not shared between an iPhone and its paired Apple
/// Watch.** Each device has its own container, so `SharedPrayerCache` never
/// reaches the watch no matter what entitlement is added. The bridge is
/// `WatchConnectivity`.
///
/// Given that, the bridge carries the **settings, not the results**: coordinate,
/// calculation method, madhab, source, per-prayer offsets, time zone. The watch
/// runs the very same `PrayerEngine` (adhan-swift supports watchOS) and produces
/// its own times. Consequences:
///
/// * the watch works with the phone out of range, or off entirely;
/// * the complication never goes blank waiting for a transfer;
/// * one small, idempotent payload replaces a rolling window of days.
public enum WatchBridge {

    /// Bumped when the payload shape changes in a way an old build cannot read.
    /// The receiver drops anything newer than it understands rather than
    /// guessing at missing fields.
    public static let protocolVersion = 1

    public enum Key {
        /// `updateApplicationContext` — the settings payload, JSON-encoded.
        public static let settings = "mihrab.watch.settings.v1"
        /// `transferUserInfo` — an ordered batch of watch-originated events.
        public static let envelope = "mihrab.watch.envelope.v1"
        /// Marks a `transferCurrentComplicationUserInfo` payload so the watch
        /// can reload timelines instead of only refreshing state.
        public static let complicationNudge = "mihrab.watch.complication.v1"
    }

    /// The App Group used *within* one device (watch app ↔ watch widget
    /// extension, phone app ↔ phone widget extension). Same identifier on both
    /// devices, two entirely separate containers — see the note above.
    public static let appGroupID = "group.com.caferkarakaya.mihrab"

    /// `yyyy-MM-dd`, Gregorian, `en_US_POSIX` — byte-identical to the key
    /// `PrayerLogStore` writes, so a watch-originated log lands on the same row
    /// the phone would have written.
    public static func dayKey(for date: Date) -> String {
        dayKeyFormatter.string(from: date)
    }

    public static func date(fromDayKey key: String) -> Date? {
        dayKeyFormatter.date(from: key)
    }

    private static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    public static var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }

    public static var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}

// MARK: - Settings payload (phone → watch)

/// Everything the watch needs to compute prayer times and Qibla by itself.
///
/// Small on purpose: `updateApplicationContext` keeps only the most recent
/// payload, so this is sent freely whenever anything in it changes.
public struct WatchSettingsPayload: Codable, Sendable, Equatable {

    public var version: Int
    /// Absent when the phone has no location fix yet and no manual city. The
    /// watch then falls back to its own `CLLocationManager`, and if that also
    /// has nothing, it says so instead of inventing a coordinate.
    public var latitude: Double?
    public var longitude: Double?
    public var cityName: String
    /// `CalculationMethod.rawValue`.
    public var methodID: Int
    /// `Madhab.rawValue`.
    public var madhabID: Int
    /// `PrayerSource.rawValue`.
    public var sourceID: String
    /// `Prayer.rawValue` → user correction in minutes.
    public var offsetMinutes: [String: Int]
    public var timeZoneIdentifier: String
    /// `en` / `tr` / `ar`, so the watch matches the phone even when the two
    /// devices have different system languages.
    public var languageCode: String
    /// The phone's `PrayerLogStore` marks for today, so the watch opens already
    /// showing what was ticked off on the phone.
    public var loggedTodayIDs: [String]
    public var loggedDayKey: String
    public var generatedAt: Date

    public init(version: Int = WatchBridge.protocolVersion,
                latitude: Double?,
                longitude: Double?,
                cityName: String,
                methodID: Int,
                madhabID: Int,
                sourceID: String,
                offsetMinutes: [String: Int],
                timeZoneIdentifier: String,
                languageCode: String,
                loggedTodayIDs: [String] = [],
                loggedDayKey: String = WatchBridge.dayKey(for: Date()),
                generatedAt: Date = Date()) {
        self.version = version
        self.latitude = latitude
        self.longitude = longitude
        self.cityName = cityName
        self.methodID = methodID
        self.madhabID = madhabID
        self.sourceID = sourceID
        self.offsetMinutes = offsetMinutes
        self.timeZoneIdentifier = timeZoneIdentifier
        self.languageCode = languageCode
        self.loggedTodayIDs = loggedTodayIDs
        self.loggedDayKey = loggedDayKey
        self.generatedAt = generatedAt
    }

    public var hasCoordinate: Bool { latitude != nil && longitude != nil }

    /// Everything except the timestamp and the log mirror. Used to decide
    /// whether a new `updateApplicationContext` is worth sending: WatchConnectivity
    /// silently drops a context identical to the last one, and re-sending on a
    /// timestamp change alone would burn the transfer for nothing.
    public var calculationFingerprint: String {
        let offsets = offsetMinutes.keys.sorted()
            .map { "\($0):\(offsetMinutes[$0] ?? 0)" }
            .joined(separator: ",")
        let lat = latitude.map { String(format: "%.4f", $0) } ?? "-"
        let lon = longitude.map { String(format: "%.4f", $0) } ?? "-"
        return [String(version), lat, lon, cityName, String(methodID), String(madhabID),
                sourceID, offsets, timeZoneIdentifier, languageCode].joined(separator: "|")
    }

    // MARK: Dictionary form

    /// `applicationContext` must be property-list friendly. A single `Data`
    /// value under one key is the smallest thing that always survives the trip.
    public func contextDictionary() throws -> [String: Any] {
        [WatchBridge.Key.settings: try WatchBridge.encoder.encode(self)]
    }

    public static func decode(from context: [String: Any]) -> WatchSettingsPayload? {
        guard let data = context[WatchBridge.Key.settings] as? Data,
              let payload = try? WatchBridge.decoder.decode(WatchSettingsPayload.self, from: data)
        else { return nil }
        // A payload from a newer phone build may have fields this build does not
        // understand. Refusing it is honest; half-applying it is not.
        guard payload.version <= WatchBridge.protocolVersion else { return nil }
        return payload
    }
}

// MARK: - Events (watch → phone)

/// One thing that happened on the wrist. Ordered, replayable, idempotent where
/// it can be: `prayerLog` carries the resulting state rather than a toggle, so a
/// duplicate delivery cannot flip a prayer back off.
public enum WatchBridgeEvent: Codable, Sendable, Equatable {
    /// Counted on the watch; folded into the phone's running tally.
    /// A delta, because two devices counting the same session must add up.
    case dhikrTicks(phraseID: String, amount: Int)
    /// Absolute state, not a toggle. `dayKey` is `WatchBridge.dayKey(for:)`.
    case prayerLog(prayerID: String, dayKey: String, logged: Bool)
}

/// A batch of events with an id, so the receiver can drop a replay.
///
/// `transferUserInfo` guarantees delivery and order but not exactly-once
/// semantics across a reinstall, so the phone keeps a short ring of seen ids.
public struct WatchBridgeEnvelope: Codable, Sendable, Equatable {
    public var id: UUID
    public var sentAt: Date
    public var events: [WatchBridgeEvent]

    public init(id: UUID = UUID(), sentAt: Date = Date(), events: [WatchBridgeEvent]) {
        self.id = id
        self.sentAt = sentAt
        self.events = events
    }

    public func userInfo() throws -> [String: Any] {
        [WatchBridge.Key.envelope: try WatchBridge.encoder.encode(self)]
    }

    public static func decode(from userInfo: [String: Any]) -> WatchBridgeEnvelope? {
        guard let data = userInfo[WatchBridge.Key.envelope] as? Data else { return nil }
        return try? WatchBridge.decoder.decode(WatchBridgeEnvelope.self, from: data)
    }
}
