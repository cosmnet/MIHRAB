import SwiftUI

/// The single thing the hero card asks you to do right now.
///
/// The hero used to be a third of the screen carrying nothing but information.
/// One action lives there instead — and it changes with the hour, so it is
/// almost always the thing you already came to do.
enum TodayPrimaryAction: Equatable {
    /// A fard prayer whose time has come and that is not marked yet.
    case markPrayed(Prayer)
    /// The next prayer is close — face the qibla.
    case showQibla
    /// Nothing due; keep the tongue busy instead.
    case startDhikr

    /// How close the next prayer has to be before we offer the compass.
    static let qiblaWindow: TimeInterval = 45 * 60

    /// Picks the action for `now`. Pure — no side effects, no stored state.
    static func resolve(now: Date = Date(),
                        today: DayPrayerTimes?,
                        tomorrow: DayPrayerTimes?,
                        log: PrayerLogStore) -> TodayPrimaryAction {
        if let current = today?.previousPrayer(before: now),
           current.prayer.isNotifiable,
           !log.isLogged(current.prayer) {
            return .markPrayed(current.prayer)
        }

        if let next = today?.nextPrayer(after: now, tomorrow: tomorrow),
           next.date.timeIntervalSince(now) <= qiblaWindow {
            return .showQibla
        }

        return .startDhikr
    }

    var title: String {
        switch self {
        case .markPrayed(let prayer): L10n.homeActionMarkPrayed(prayer.localizedNamazName)
        case .showQibla: L10n.homeActionShowQibla
        case .startDhikr: L10n.homeActionStartDhikr
        }
    }

    var symbolName: String {
        switch self {
        case .markPrayed: "checkmark.circle.fill"
        case .showQibla: "location.north.line.fill"
        case .startDhikr: "circle.grid.3x3.fill"
        }
    }
}
