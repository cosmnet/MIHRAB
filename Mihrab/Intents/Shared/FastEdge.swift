import Foundation

/// Which of the two edges of the fast is next.
enum FastEdge {
    case iftar(Date)
    case suhoor(Date)

    var date: Date {
        switch self {
        case .iftar(let date), .suhoor(let date): date
        }
    }

    var caption: String {
        switch self {
        case .iftar: L10n.iftarIn
        case .suhoor: L10n.suhoorEndsIn
        }
    }

    var symbol: String {
        switch self {
        case .iftar: "sunset.fill"
        case .suhoor: "moon.stars.fill"
        }
    }

    /// Fajr first: before dawn the fast has not begun, so the edge ahead is the
    /// end of suhoor — not iftar, even though maghrib is also still in the
    /// future. After dawn it is iftar, and after maghrib it is tomorrow's fajr.
    static func next(at now: Date, snapshot: SharedPrayerSnapshot?) -> FastEdge? {
        guard let today = snapshot?.day(containing: now) else { return nil }
        if let fajr = today.time(for: .fajr), fajr > now { return .suhoor(fajr) }
        if let maghrib = today.time(for: .maghrib), maghrib > now { return .iftar(maghrib) }
        guard let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: now),
              let fajr = snapshot?.day(containing: tomorrowDate)?.time(for: .fajr)
        else { return nil }
        return .suhoor(fajr)
    }
}
