import Foundation

/// Why a given day shows up as a recommended voluntary (nafile) fast.
enum VoluntaryFastKind: String, Codable, Sendable, CaseIterable, Identifiable {
    /// Mondays and Thursdays.
    case weekly
    /// Eyyâm-ı bîd — the "white days", 13, 14 and 15 of every Hijri month.
    case whiteDays
    /// 9 and 10 Muharrem (Tâsûâ and Aşure).
    case ashura
    /// The first nine days of Zilhicce.
    case dhulHijjah
    /// 9 Zilhicce — Arefe, listed separately because it is the strongest of them.
    case arafah
    /// Six days of Şevval, any six after the bayram.
    case shawwalSix

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .weekly: "calendar.badge.clock"
        case .whiteDays: "moon.circle"
        case .ashura: "drop.fill"
        case .dhulHijjah: "sun.haze.fill"
        case .arafah: "mountain.2.fill"
        case .shawwalSix: "sparkles"
        }
    }

    var localizedName: String { L10n.fastKindName(self) }
    var localizedNote: String { L10n.fastKindNote(self) }
}

/// One Gregorian day with the reasons it is (or must not be) fasted.
struct VoluntaryFastDay: Identifiable, Hashable, Sendable {
    let date: Date
    let hijriMonth: Int
    let hijriDay: Int
    let kinds: [VoluntaryFastKind]
    /// Days on which fasting is not permitted: the bayram days themselves.
    let isForbidden: Bool

    var id: Date { date }
}

extension IslamicCalendar {
    /// Days on which fasting is **forbidden**: 1 Şevval (Ramazan Bayramı) and
    /// 10–13 Zilhicce (Kurban Bayramı and the teşrik days).
    static func isFastingForbidden(hijriMonth month: Int, hijriDay day: Int) -> Bool {
        if month == 10, day == 1 { return true }
        if month == 12, (10...13).contains(day) { return true }
        return false
    }

    /// Recommended voluntary fasts in a Gregorian range.
    ///
    /// Ramazan itself is excluded — it is fard, not nafile, and listing it here
    /// would be a category error.
    static func voluntaryFastDays(from start: Date, through end: Date) -> [VoluntaryFastDay] {
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: start)
        let last = calendar.startOfDay(for: end)
        var result: [VoluntaryFastDay] = []

        while day <= last {
            defer { day = calendar.date(byAdding: .day, value: 1, to: day) ?? last.addingTimeInterval(86_400) }
            guard let parts = hijriComponents(for: day) else { continue }
            let forbidden = isFastingForbidden(hijriMonth: parts.month, hijriDay: parts.day)
            if parts.month == 9 { continue } // Ramazan: obligatory, not voluntary.

            var kinds: [VoluntaryFastKind] = []
            let weekday = calendar.component(.weekday, from: day)
            if weekday == 2 || weekday == 5 { kinds.append(.weekly) } // Monday / Thursday
            if (13...15).contains(parts.day) { kinds.append(.whiteDays) }
            if parts.month == 1, parts.day == 9 || parts.day == 10 { kinds.append(.ashura) }
            if parts.month == 12, (1...9).contains(parts.day) { kinds.append(.dhulHijjah) }
            if parts.month == 12, parts.day == 9 { kinds.append(.arafah) }
            // The six days of Şevval may be kept on *any* days of the month.
            // Listing all 29 would drown the calendar, so we surface the run
            // straight after the bayram and say so in the note.
            if parts.month == 10, (2...8).contains(parts.day) { kinds.append(.shawwalSix) }

            guard !kinds.isEmpty || forbidden else { continue }
            result.append(
                VoluntaryFastDay(
                    date: day,
                    hijriMonth: parts.month,
                    hijriDay: parts.day,
                    kinds: kinds,
                    isForbidden: forbidden
                )
            )
        }
        return result
    }

    /// The next few voluntary fast days — a compact reading API for widgets and
    /// the Today screen. Forbidden days are filtered out.
    static func upcomingVoluntaryFasts(limit: Int = 5, from date: Date = Date()) -> [VoluntaryFastDay] {
        let calendar = Calendar.current
        let end = calendar.date(byAdding: .day, value: 45, to: date) ?? date
        return voluntaryFastDays(from: date, through: end)
            .filter { !$0.isForbidden }
            .prefix(limit)
            .map { $0 }
    }
}
