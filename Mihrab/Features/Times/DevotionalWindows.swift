import CoreLocation
import Foundation

/// The intervals around a day's prayer times that people actually ask about:
/// the three *kerahat* (disliked) windows, and the night divisions used for
/// tahajjud.
///
/// Design rule for this file: **derive, never invent.**
/// * The *istiva* window is the real solar transit (computed here) up to the
///   öğle time the user's own calendar publishes. Their difference *is* the
///   temkin, so the window is exact for whichever source is selected.
/// * The sunrise and sunset windows use a stated 5° solar-altitude convention
///   — the common modern reading of the classical "length of a spear". That is
///   a convention we disclose in the UI, not a number we made up quietly.
/// * The night divisions are measured from the day's own maghrib to the next
///   day's own imsak, so they inherit the user's source, temkin and offsets
///   instead of being recomputed from a different set of assumptions.
enum DevotionalWindows {

    // MARK: - Makruh

    enum MakruhKind: String, Identifiable, CaseIterable, Sendable {
        case ishraq, istiwa, isfirar

        var id: String { rawValue }

        var localizedName: String {
            switch self {
            case .ishraq: L10n.tmxMakruhIshraq
            case .istiwa: L10n.tmxMakruhIstiwa
            case .isfirar: L10n.tmxMakruhIsfirar
            }
        }

        var symbolName: String {
            switch self {
            case .ishraq: "sunrise"
            case .istiwa: "sun.max"
            case .isfirar: "sunset"
            }
        }
    }

    struct Window: Identifiable, Sendable, Equatable {
        let kind: MakruhKind
        let start: Date
        let end: Date

        var id: String { kind.rawValue }
        var duration: TimeInterval { end.timeIntervalSince(start) }
        func contains(_ date: Date) -> Bool { date >= start && date < end }
    }

    /// Solar altitude, in degrees, at which the sunrise / sunset windows close.
    /// Disclosed to the user in `L10n.tmxMakruhExplain`.
    static let spearAltitude: Double = 5

    /// The three disliked windows for `day`, in chronological order.
    /// Any window we cannot derive honestly is simply absent from the array.
    static func makruhWindows(for day: DayPrayerTimes,
                              coordinate: CLLocationCoordinate2D,
                              calendar: Calendar = .current) -> [Window] {
        var windows: [Window] = []

        if let sunrise = day.time(for: .sunrise),
           let spear = SolarMath.time(atAltitude: spearAltitude,
                                      rising: true,
                                      on: day.date,
                                      coordinate: coordinate,
                                      calendar: calendar),
           spear > sunrise {
            windows.append(Window(kind: .ishraq, start: sunrise, end: spear))
        }

        if let dhuhr = day.time(for: .dhuhr) {
            let transit = SolarMath.localSolarNoon(on: day.date,
                                                   coordinate: coordinate,
                                                   calendar: calendar)
            // A source with no temkin publishes öğle essentially at the
            // transit; a sub-minute "window" is noise, so we drop it rather
            // than pad it out to look substantial.
            if dhuhr.timeIntervalSince(transit) >= 60 {
                windows.append(Window(kind: .istiwa, start: transit, end: dhuhr))
            }
        }

        if let maghrib = day.time(for: .maghrib),
           let spear = SolarMath.time(atAltitude: spearAltitude,
                                      rising: false,
                                      on: day.date,
                                      coordinate: coordinate,
                                      calendar: calendar),
           spear < maghrib {
            windows.append(Window(kind: .isfirar, start: spear, end: maghrib))
        }

        return windows.sorted { $0.start < $1.start }
    }

    // MARK: - Night divisions

    struct NightDivisions: Sendable, Equatable {
        /// Maghrib of `day`.
        let start: Date
        /// Imsak of the following day.
        let end: Date
        let middleOfTheNight: Date
        let lastThirdOfTheNight: Date

        var duration: TimeInterval { end.timeIntervalSince(start) }
    }

    /// Middle and last third of the night, measured maghrib → next imsak.
    ///
    /// Deliberately computed from the app's own displayed times rather than
    /// from `Adhan.SunnahTimes`: the user's source, temkin and ± corrections
    /// are already folded into these, so the thirds line up with the numbers on
    /// screen instead of quietly disagreeing with them by the temkin.
    static func nightDivisions(day: DayPrayerTimes,
                               tomorrow: DayPrayerTimes?) -> NightDivisions? {
        guard let maghrib = day.time(for: .maghrib),
              let nextFajr = tomorrow?.time(for: .fajr),
              nextFajr > maghrib else { return nil }

        let length = nextFajr.timeIntervalSince(maghrib)
        return NightDivisions(
            start: maghrib,
            end: nextFajr,
            middleOfTheNight: maghrib.addingTimeInterval(length / 2),
            lastThirdOfTheNight: maghrib.addingTimeInterval(length * 2 / 3)
        )
    }
}
