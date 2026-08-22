import Foundation

/// The six daily prayer markers, in chronological order.
public enum Prayer: String, Codable, CaseIterable, Identifiable, Sendable {
    case fajr, sunrise, dhuhr, asr, maghrib, isha

    public var id: String { rawValue }

    /// English identifier — do not show in UI. Use `localizedName`.
    public var displayName: String {
        switch self {
        case .fajr: "Fajr"
        case .sunrise: "Sunrise"
        case .dhuhr: "Dhuhr"
        case .asr: "Asr"
        case .maghrib: "Maghrib"
        case .isha: "Isha"
        }
    }

    /// Schedule-row name (TR: İmsak / Güneş / Öğle / İkindi / Akşam / Yatsı).
    public var localizedName: String {
        switch self {
        case .fajr: L10n.prayerFajr
        case .sunrise: L10n.prayerSunrise
        case .dhuhr: L10n.prayerDhuhr
        case .asr: L10n.prayerAsr
        case .maghrib: L10n.prayerMaghrib
        case .isha: L10n.prayerIsha
        }
    }

    /// Namaz name for countdowns (TR: Sabah / Güneş / Öğle / İkindi / Akşam / Yatsı).
    public var localizedNamazName: String {
        switch self {
        case .fajr: L10n.namazFajr
        case .sunrise: L10n.namazSunrise
        case .dhuhr: L10n.namazDhuhr
        case .asr: L10n.namazAsr
        case .maghrib: L10n.namazMaghrib
        case .isha: L10n.namazIsha
        }
    }

    /// Countdown caption (TR: "İkindiye kalan"). Never a catalog key.
    public var countdownLabel: String {
        switch self {
        case .fajr: L10n.countdownFajr
        case .sunrise: L10n.countdownSunrise
        case .dhuhr: L10n.countdownDhuhr
        case .asr: L10n.countdownAsr
        case .maghrib: L10n.countdownMaghrib
        case .isha: L10n.countdownIsha
        }
    }

    public var shortName: String {
        switch self {
        case .fajr: L10n.shortFajr
        case .sunrise: L10n.shortSunrise
        case .dhuhr: L10n.shortDhuhr
        case .asr: L10n.shortAsr
        case .maghrib: L10n.shortMaghrib
        case .isha: L10n.shortIsha
        }
    }

    public var arabicName: String {
        switch self {
        case .fajr: "الفجر"
        case .sunrise: "الشروق"
        case .dhuhr: "الظهر"
        case .asr: "العصر"
        case .maghrib: "المغرب"
        case .isha: "العشاء"
        }
    }

    public var turkishName: String {
        switch self {
        case .fajr: "İmsak"
        case .sunrise: "Güneş"
        case .dhuhr: "Öğle"
        case .asr: "İkindi"
        case .maghrib: "Akşam"
        case .isha: "Yatsı"
        }
    }

    public var symbolName: String {
        switch self {
        case .fajr: "moon.stars.fill"
        case .sunrise: "sunrise.fill"
        case .dhuhr: "sun.max.fill"
        case .asr: "sun.min.fill"
        case .maghrib: "sunset.fill"
        case .isha: "moon.fill"
        }
    }

    /// Prayers that carry notifications (Sunrise is a marker, not a prayer).
    public var isNotifiable: Bool { self != .sunrise }
}

public enum CalculationMethod: Int, Codable, CaseIterable, Identifiable, Sendable {
    case diyanet = 13
    case ummAlQura = 4
    case isna = 2
    case mwl = 3
    case egypt = 5
    case karachi = 1

    public var id: Int { rawValue }

    public var displayName: String { localizedName }

    public var localizedName: String {
        switch self {
        case .diyanet: L10n.methodDiyanet
        case .ummAlQura: L10n.methodUmmAlQura
        case .isna: L10n.methodISNA
        case .mwl: L10n.methodMWL
        case .egypt: L10n.methodEgypt
        case .karachi: L10n.methodKarachi
        }
    }
}

public enum Madhab: Int, Codable, CaseIterable, Identifiable, Sendable {
    case shafi = 0
    case hanafi = 1

    public var id: Int { rawValue }

    public var displayName: String { localizedName }

    public var localizedName: String {
        self == .hanafi ? L10n.madhabHanafi : L10n.madhabShafi
    }
}

/// A single day's prayer schedule, normalized to the device time zone.
public struct DayPrayerTimes: Codable, Sendable, Identifiable {
    public var id: String { ISO8601DateFormatter().string(from: date) }
    public let date: Date
    public let times: [Prayer: Date]
    public let hijriDate: HijriDate?
    public let cityName: String?

    public init(date: Date, times: [Prayer: Date], hijriDate: HijriDate? = nil, cityName: String? = nil) {
        self.date = date
        self.times = times
        self.hijriDate = hijriDate
        self.cityName = cityName
    }

    public func time(for prayer: Prayer) -> Date? { times[prayer] }

    /// The next upcoming prayer after `now`, rolling to the next day's Fajr if provided.
    public func nextPrayer(after now: Date, tomorrow: DayPrayerTimes? = nil) -> (prayer: Prayer, date: Date)? {
        for prayer in Prayer.allCases {
            if let t = times[prayer], t > now { return (prayer, t) }
        }
        if let tomorrow, let fajr = tomorrow.times[.fajr] { return (.fajr, fajr) }
        return nil
    }

    public func previousPrayer(before now: Date) -> (prayer: Prayer, date: Date)? {
        for prayer in Prayer.allCases.reversed() {
            if let t = times[prayer], t <= now { return (prayer, t) }
        }
        return nil
    }
}

public struct HijriDate: Codable, Sendable, Equatable {
    public let day: Int
    public let month: Int
    public let year: Int
    public let monthNameEn: String
    public let monthNameAr: String

    public init(day: Int, month: Int, year: Int, monthNameEn: String, monthNameAr: String) {
        self.day = day
        self.month = month
        self.year = year
        self.monthNameEn = monthNameEn
        self.monthNameAr = monthNameAr
    }

    public var formatted: String { "\(day) \(localizedMonthName) \(year)" }

    public var localizedMonthName: String {
        L10n.hijriMonth(month)
    }

    public static let monthNamesEn = [
        "Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani",
        "Jumada al-Ula", "Jumada al-Akhirah", "Rajab", "Sha'ban",
        "Ramadan", "Shawwal", "Dhul-Qa'dah", "Dhul-Hijjah",
    ]

    public static var localizedMonthNames: [String] {
        (1...12).map { L10n.hijriMonth($0) }
    }

    public var isRamadan: Bool { month == 9 }
}

public enum QiblaMath {
    public static let kaabaLatitude = 21.422487
    public static let kaabaLongitude = 39.826206

    /// Great-circle initial bearing from a coordinate to the Kaaba, in degrees [0, 360).
    public static func bearing(fromLatitude lat: Double, longitude lon: Double) -> Double {
        let φ1 = lat * .pi / 180
        let φ2 = kaabaLatitude * .pi / 180
        let Δλ = (kaabaLongitude - lon) * .pi / 180
        let y = sin(Δλ)
        let x = cos(φ1) * tan(φ2) - sin(φ1) * cos(Δλ)
        let θ = atan2(y, x) * 180 / .pi
        return (θ.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Great-circle distance to Makkah in kilometers.
    public static func distanceToMakkah(fromLatitude lat: Double, longitude lon: Double) -> Double {
        let r = 6371.0
        let φ1 = lat * .pi / 180
        let φ2 = kaabaLatitude * .pi / 180
        let Δφ = (kaabaLatitude - lat) * .pi / 180
        let Δλ = (kaabaLongitude - lon) * .pi / 180
        let a = sin(Δφ / 2) * sin(Δφ / 2) + cos(φ1) * cos(φ2) * sin(Δλ / 2) * sin(Δλ / 2)
        return r * 2 * atan2(sqrt(a), sqrt(1 - a))
    }

    /// Shortest-path angular difference from `from` to `to`, in (-180, 180].
    public static func shortestDelta(from: Double, to: Double) -> Double {
        var delta = (to - from).truncatingRemainder(dividingBy: 360)
        if delta > 180 { delta -= 360 }
        if delta <= -180 { delta += 360 }
        return delta
    }
}
