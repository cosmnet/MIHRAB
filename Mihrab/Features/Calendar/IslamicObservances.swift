import Foundation

// MARK: - Kinds

/// What sort of day this is. Drives iconography and grouping, never the maths.
enum ObservanceKind: String, Codable, Sendable, CaseIterable {
    /// "Kandil" — a night the Turkish tradition marks with worship.
    case kandil
    /// Start / end markers of the three sacred months (Recep, Şaban, Ramazan).
    case sacredMonth
    /// Bayram (eid) days.
    case eid
    /// Arefe — the day before a bayram.
    case eve
    /// Hicri new year and Ashura.
    case muharram

    var symbolName: String {
        switch self {
        case .kandil: "moon.stars.fill"
        case .sacredMonth: "moon.circle.fill"
        case .eid: "sparkles"
        case .eve: "sunset.fill"
        case .muharram: "calendar"
        }
    }
}

// MARK: - Observance

/// One dated religious day, resolved onto the Gregorian calendar.
///
/// ## The evening rule — the whole point of this type
///
/// An Islamic day begins at **maghrib (sunset) of the preceding Gregorian
/// day**, not at midnight. So "Berat Kandili is 15 Şaban" means the night that
/// people actually spend in worship starts at maghrib on the Gregorian day
/// *before* the one 15 Şaban maps to. Apps that treat the Hijri→Gregorian
/// mapping as a midnight-to-midnight day fire their kandil reminder a full
/// evening late; this is the single most common mistake in the category.
///
/// `gregorianDay` is therefore only the *daytime* half of the Hijri day, and
/// `nightGregorianDay` / `start(maghrib:)` carry the real beginning.
struct Observance: Identifiable, Hashable, Sendable {
    let key: String
    let kind: ObservanceKind
    let hijriYear: Int
    let hijriMonth: Int
    let hijriDay: Int

    /// Start of the Gregorian day that the Hijri date maps onto (local midnight).
    let gregorianDay: Date

    /// True when the observance is kept **at night** (kandils, Kadir Gecesi,
    /// bayram gecesi). For these the evening before is the event, not the day.
    let isNightObservance: Bool

    var id: String { "\(key)-\(hijriYear)" }

    var localizedName: String { L10n.observanceName(key) }
    var localizedNote: String { L10n.observanceNote(key) }
    /// Where the *dating rule* comes from — never a narrated tradition.
    var localizedRule: String { L10n.observanceRule(key) }

    /// The Gregorian day whose **maghrib** opens this Hijri day.
    var nightGregorianDay: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: gregorianDay) ?? gregorianDay
    }

    /// The exact instant the observance begins.
    ///
    /// - Parameter maghrib: maghrib on `nightGregorianDay`, if the caller has
    ///   real prayer times. When it is `nil` we fall back to 18:00 local —
    ///   an admitted placeholder, never presented as a computed prayer time.
    func start(maghrib: Date?) -> Date {
        if let maghrib { return maghrib }
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 18, minute: 0, second: 0, of: nightGregorianDay)
            ?? nightGregorianDay
    }

    /// The day the user should be reminded on: the evening before for night
    /// observances, the day itself otherwise.
    var reminderGregorianDay: Date {
        isNightObservance ? nightGregorianDay : gregorianDay
    }

    /// Whole days from `date` to `reminderGregorianDay`. Negative once passed.
    func daysUntil(from date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let from = calendar.startOfDay(for: date)
        let to = calendar.startOfDay(for: reminderGregorianDay)
        return calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }

    /// Still relevant today? A night observance stays "live" through the
    /// following daytime, so nothing disappears from the list at midnight.
    func isActive(on date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        return day == calendar.startOfDay(for: gregorianDay)
            || (isNightObservance && day == calendar.startOfDay(for: nightGregorianDay))
    }
}

// MARK: - Definitions

/// Static rules. Every entry is a *calendar rule*, not a claim about merit.
private struct ObservanceRule {
    let key: String
    let kind: ObservanceKind
    let month: Int
    /// `nil` when the day is computed (Regaib falls on a weekday, not a date).
    let day: Int?
    let isNight: Bool
}

// MARK: - Engine

/// Hijri ↔ Gregorian resolution for Turkish religious days.
///
/// ## Calendar choice and its honest limits
///
/// We use `Calendar(identifier: .islamicUmmAlQura)`, the tabular Umm al-Qura
/// calendar shipped by Apple. Turkey's Diyanet İşleri Başkanlığı publishes its
/// own *hesaplamalı* (calculated) calendar, whose month starts can differ from
/// Umm al-Qura by **±1 day**. Countdown pills and reminders must be presented
/// with that tolerance stated (`L10n.calendarAccuracyNote`), and the Diyanet
/// printed calendar remains the authority for Turkey.
enum IslamicCalendar {
    static let hijri: Calendar = {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.timeZone = .current
        return calendar
    }()

    private static var gregorian: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    // Ordered by Hijri month so a year's list needs no extra sorting pass.
    private static let rules: [ObservanceRule] = [
        ObservanceRule(key: "hijriNewYear", kind: .muharram, month: 1, day: 1, isNight: false),
        ObservanceRule(key: "ashura", kind: .muharram, month: 1, day: 10, isNight: false),
        ObservanceRule(key: "mawlid", kind: .kandil, month: 3, day: 12, isNight: true),
        ObservanceRule(key: "threeMonthsStart", kind: .sacredMonth, month: 7, day: 1, isNight: false),
        // Regaib has no fixed date — see `regaibObservance(hijriYear:)`.
        ObservanceRule(key: "regaib", kind: .kandil, month: 7, day: nil, isNight: true),
        ObservanceRule(key: "miraj", kind: .kandil, month: 7, day: 27, isNight: true),
        ObservanceRule(key: "shaban", kind: .sacredMonth, month: 8, day: 1, isNight: false),
        ObservanceRule(key: "barat", kind: .kandil, month: 8, day: 15, isNight: true),
        ObservanceRule(key: "ramadanStart", kind: .sacredMonth, month: 9, day: 1, isNight: false),
        ObservanceRule(key: "qadr", kind: .kandil, month: 9, day: 27, isNight: true),
        ObservanceRule(key: "eidFitrEve", kind: .eve, month: 9, day: 29, isNight: false),
        ObservanceRule(key: "eidFitr", kind: .eid, month: 10, day: 1, isNight: false),
        ObservanceRule(key: "arafah", kind: .eve, month: 12, day: 9, isNight: false),
        ObservanceRule(key: "eidAdha", kind: .eid, month: 12, day: 10, isNight: false),
    ]

    // MARK: Conversion

    /// Local midnight of the Gregorian day a Hijri date maps to.
    static func gregorianDay(hijriYear year: Int, month: Int, day: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        guard let date = hijri.date(from: components) else { return nil }
        return gregorian.startOfDay(for: date)
    }

    static func hijriComponents(for date: Date) -> (year: Int, month: Int, day: Int)? {
        let parts = hijri.dateComponents([.year, .month, .day], from: date)
        guard let year = parts.year, let month = parts.month, let day = parts.day else { return nil }
        return (year, month, day)
    }

    static func hijriYear(for date: Date = Date()) -> Int {
        hijriComponents(for: date)?.year ?? 1447
    }

    // MARK: Building

    /// Every tracked observance of one Hijri year, in chronological order.
    static func observances(hijriYear year: Int) -> [Observance] {
        var result: [Observance] = []
        for rule in rules {
            if rule.key == "regaib" {
                if let regaib = regaibObservance(hijriYear: year) { result.append(regaib) }
                continue
            }
            guard let day = rule.day,
                  let gregorianDay = gregorianDay(hijriYear: year, month: rule.month, day: day)
            else { continue }
            result.append(
                Observance(
                    key: rule.key,
                    kind: rule.kind,
                    hijriYear: year,
                    hijriMonth: rule.month,
                    hijriDay: day,
                    gregorianDay: gregorianDay,
                    isNightObservance: rule.isNight
                )
            )
        }
        return result.sorted { $0.gregorianDay < $1.gregorianDay }
    }

    /// Regaib Kandili is **the night joining the first Thursday of Recep to the
    /// first Friday of Recep** — a weekday rule, not 1 Recep. Bundled data that
    /// pins it to 1 Recep is wrong in most years.
    static func regaibObservance(hijriYear year: Int) -> Observance? {
        for day in 1...30 {
            guard let candidate = gregorianDay(hijriYear: year, month: 7, day: day) else { continue }
            // Guard against the tabular calendar rolling into Şaban on day 30.
            guard let parts = hijriComponents(for: candidate), parts.month == 7 else { break }
            if gregorian.component(.weekday, from: candidate) == 6 { // Friday
                return Observance(
                    key: "regaib",
                    kind: .kandil,
                    hijriYear: year,
                    hijriMonth: 7,
                    hijriDay: day,
                    gregorianDay: candidate,
                    isNightObservance: true
                )
            }
        }
        return nil
    }

    /// Observances beginning within the next `days` days — **the reading API
    /// other modules (notifications, Today badges) should use.**
    ///
    /// The window is measured against `reminderGregorianDay`, so a kandil that
    /// starts this evening is returned today, not tomorrow.
    static func upcomingObservances(within days: Int, from date: Date = Date()) -> [Observance] {
        let year = hijriYear(for: date)
        let pool = observances(hijriYear: year - 1)
            + observances(hijriYear: year)
            + observances(hijriYear: year + 1)
        return pool
            .filter { observance in
                let delta = observance.daysUntil(from: date)
                return delta >= 0 && delta <= days
            }
            .sorted { $0.reminderGregorianDay < $1.reminderGregorianDay }
    }

    /// The next occurrence of every tracked observance, one entry per key.
    static func nextOccurrences(from date: Date = Date()) -> [Observance] {
        let year = hijriYear(for: date)
        let pool = observances(hijriYear: year) + observances(hijriYear: year + 1)
        var seen = Set<String>()
        var result: [Observance] = []
        for observance in pool.sorted(by: { $0.reminderGregorianDay < $1.reminderGregorianDay })
        where observance.daysUntil(from: date) >= 0 {
            guard !seen.contains(observance.key) else { continue }
            seen.insert(observance.key)
            result.append(observance)
        }
        return result
    }

    /// Observances that are live right now (tonight's kandil, today's bayram).
    static func activeObservances(on date: Date = Date()) -> [Observance] {
        let year = hijriYear(for: date)
        return (observances(hijriYear: year - 1) + observances(hijriYear: year))
            .filter { $0.isActive(on: date) }
    }

    // MARK: Three months

    /// Recep 1 → the end of Ramazan, the Turkish "üç aylar" span.
    static func threeMonthsInterval(hijriYear year: Int) -> DateInterval? {
        guard let start = gregorianDay(hijriYear: year, month: 7, day: 1),
              let shawwal = gregorianDay(hijriYear: year, month: 10, day: 1),
              let end = gregorian.date(byAdding: .day, value: -1, to: shawwal)
        else { return nil }
        return DateInterval(start: start, end: end)
    }

    static func isInThreeMonths(_ date: Date = Date()) -> Bool {
        guard let parts = hijriComponents(for: date) else { return false }
        return (7...9).contains(parts.month)
    }
}
