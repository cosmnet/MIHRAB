import CoreLocation
import Foundation

/// App-facing conveniences that bind the pure engine to the app's singletons.
/// Kept out of `PrayerEngine.swift` so the engine stays compilable in the test
/// target without dragging `AppSettings` (and therefore SwiftUI) along.
extension PrayerEngineConfiguration {
    /// The configuration implied by the user's current settings.
    ///
    /// ⚠️ **Known accuracy limit — multi-city.** `timeZone` defaults to the
    /// *device's* zone, and neither `SavedCity` nor `LocationManager` carries
    /// one. So when the effective location is a manually chosen city in another
    /// zone (Settings → Location, or `CityStore`), the astronomy is correct for
    /// that city but every time is rendered on the device's clock — an
    /// hour-scale error that a user has no way to notice.
    static func current(settings: AppSettings = .shared,
                        preferences: PrayerSourcePreferences = .shared,
                        timeZone: TimeZone = LocationManager.shared.effectiveTimeZone)
        -> PrayerEngineConfiguration {
        PrayerEngineConfiguration(method: settings.calculationMethod,
                                  madhab: settings.madhab,
                                  source: preferences.source,
                                  offsets: preferences.offsets,
                                  timeZone: timeZone)
    }
}

extension PrayerEngine {
    /// Contract signature (`AGENT_BRIEF_W1.md` → "W1 sağlar").
    static func times(for date: Date,
                      coordinate: CLLocationCoordinate2D,
                      settings: AppSettings) -> DayPrayerTimes? {
        times(for: date,
              coordinate: coordinate,
              configuration: .current(settings: settings))
    }

    /// Contract signature (`AGENT_BRIEF_W1.md` → "W1 sağlar").
    static func month(of date: Date,
                      coordinate: CLLocationCoordinate2D,
                      settings: AppSettings) -> [DayPrayerTimes] {
        month(of: date,
              coordinate: coordinate,
              configuration: .current(settings: settings))
    }
}
