import CoreLocation
import Foundation

/// One day's times plus enough of tomorrow to answer "what is next" across
/// midnight, computed **on the watch**.
///
/// Nothing here talks to the phone. `PrayerEngine` and adhan-swift both build
/// for watchOS, so given a coordinate and the settings the phone last sent, the
/// watch produces exactly the same numbers the phone would — with the phone in
/// another room, or in Airplane Mode, or dead.
struct WatchSchedule: Equatable, Sendable {
    let today: DayPrayerTimes
    let tomorrow: DayPrayerTimes?
    let cityName: String
    /// `true` when the coordinate came from the watch's own sensor rather than
    /// from the phone — surfaced in the UI, because the two can disagree while
    /// travelling and the user deserves to know which one produced the times.
    let usesWatchLocation: Bool

    func next(after now: Date = Date()) -> (prayer: Prayer, date: Date)? {
        today.nextPrayer(after: now, tomorrow: tomorrow)
    }

    func previous(before now: Date = Date()) -> (prayer: Prayer, date: Date)? {
        today.previousPrayer(before: now)
    }

    /// Ordered rows for the list, sunrise included — it is a marker people look
    /// for even though it is not a prayer.
    var rows: [(prayer: Prayer, date: Date)] {
        Prayer.allCases.compactMap { prayer in
            today.times[prayer].map { (prayer, $0) }
        }
    }
}

enum WatchScheduleBuilder {

    /// Rebuilds the engine configuration the phone was using. Unknown raw
    /// values fall back to the app's own defaults rather than failing: a watch
    /// that shows times computed with a slightly different madhab is far better
    /// than a watch that shows nothing.
    static func configuration(from payload: WatchSettingsPayload) -> PrayerEngineConfiguration {
        var offsets: [Prayer: Int] = [:]
        for (raw, minutes) in payload.offsetMinutes {
            if let prayer = Prayer(rawValue: raw) { offsets[prayer] = minutes }
        }
        return PrayerEngineConfiguration(
            method: CalculationMethod(rawValue: payload.methodID) ?? .diyanet,
            madhab: Madhab(rawValue: payload.madhabID) ?? .hanafi,
            source: PrayerSource(rawValue: payload.sourceID) ?? .standard,
            offsets: offsets,
            timeZone: TimeZone(identifier: payload.timeZoneIdentifier) ?? .current
        )
    }

    /// The coordinate to calculate with. The phone's wins: it carries the
    /// user's manual city choice, which the watch's GPS knows nothing about.
    /// The watch's own fix is the fallback, not the default.
    static func coordinate(payload: WatchSettingsPayload?,
                           watchFix: CLLocationCoordinate2D?) -> (CLLocationCoordinate2D, Bool)? {
        if let payload, let lat = payload.latitude, let lon = payload.longitude {
            return (CLLocationCoordinate2D(latitude: lat, longitude: lon), false)
        }
        if let watchFix { return (watchFix, true) }
        return nil
    }

    /// `nil` means "cannot answer" — no coordinate at all, or a latitude where
    /// the sun does not cross the horizon. Both are shown as such. The one
    /// thing this never does is return plausible-looking invented times.
    static func schedule(for date: Date = Date(),
                         payload: WatchSettingsPayload?,
                         watchFix: CLLocationCoordinate2D?) -> WatchSchedule? {
        guard let (coordinate, isWatchFix) = coordinate(payload: payload, watchFix: watchFix) else {
            return nil
        }
        let configuration = payload.map(configuration(from:))
            ?? PrayerEngineConfiguration(method: .diyanet, madhab: .hanafi, source: .standard)

        guard let today = PrayerEngine.times(for: date,
                                             coordinate: coordinate,
                                             configuration: configuration) else { return nil }

        let calendar = Calendar(identifier: .gregorian)
        let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        let tomorrow = PrayerEngine.times(for: tomorrowDate,
                                          coordinate: coordinate,
                                          configuration: configuration)

        let city = payload?.cityName ?? ""
        return WatchSchedule(today: today,
                             tomorrow: tomorrow,
                             cityName: city,
                             usesWatchLocation: isWatchFix)
    }

    /// Short clock string, e.g. `05:41`.
    ///
    /// `Date.formatted()` is not a SwiftUI view API and ignores the `\.locale`
    /// environment, so the app locale is pinned explicitly — the same rule the
    /// phone follows.
    static func clock(_ date: Date, timeZone: TimeZone = .current) -> String {
        var style = Date.FormatStyle.dateTime.hour().minute()
        style.locale = L10n.appLocale
        style.timeZone = timeZone
        return date.formatted(style)
    }

    /// Weekday + day + month, for the schedule header.
    static func dayCaption(_ date: Date, timeZone: TimeZone = .current) -> String {
        var style = Date.FormatStyle.dateTime.weekday(.abbreviated).day().month(.abbreviated)
        style.locale = L10n.appLocale
        style.timeZone = timeZone
        return date.formatted(style)
    }
}
