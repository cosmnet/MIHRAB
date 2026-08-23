import Foundation

/// The dependency-free core of the reminder system: identifier ownership, the
/// 64-slot budget split, and the list of prayer instances an alarm may claim.
///
/// It is deliberately free of UIKit, UserNotifications, AlarmKit and every
/// singleton in the app, so the unit tests can compile it on its own and hold
/// the two rules that actually matter:
///
/// * a plan never exceeds the budget it was given, and
/// * a prayer instance is claimed by exactly one mechanism.
enum ReminderPlanner {

    // MARK: - Identifier ownership

    /// Prefixes owned by `NotificationEngine`. Named, so nothing depends on
    /// the order of the array.
    enum Prefix {
        static let prayer = "mihrab-prayer-"
        static let preReminder = "mihrab-pre-"
        static let karahat = "mihrab-karahat-"
        static let hadith = "mihrab-hadith"
        static let religious = "mihrab-religious-"
        static let jumuah = "mihrab-jumuah"
    }

    static let managedPrefixes = [
        Prefix.prayer,
        Prefix.preReminder,
        Prefix.karahat,
        Prefix.hadith,
        Prefix.religious,
        Prefix.jumuah,
    ]

    /// Identifiers written by builds before the prefix scheme existed.
    static let legacyPrefixes = ["prayer-", "daily-hadith", "religious-", "jumuah"]

    /// Prefixes owned by *other* subsystems, which cleanup must never touch.
    /// `TrialReminder` uses `mihrab-trial-*`.
    static let foreignPrefixes = ["mihrab-trial-"]

    /// True when the engine is allowed to delete this pending request.
    static func isManaged(_ identifier: String) -> Bool {
        if foreignPrefixes.contains(where: identifier.hasPrefix) { return false }
        return managedPrefixes.contains(where: identifier.hasPrefix)
            || legacyPrefixes.contains(where: identifier.hasPrefix)
    }

    // MARK: - Prayer instances

    /// A single prayer at a single moment — the unit of "who announces this".
    struct PrayerInstance: Hashable, Sendable {
        let prayer: Prayer
        let date: Date

        init(prayer: Prayer, date: Date) {
            self.prayer = prayer
            self.date = date
        }

        /// Stable identity shared by the alarm path and the notification path.
        /// If a key is in the alarm set, no notification may be built for it.
        var key: String { "\(prayer.rawValue)|\(Int(date.timeIntervalSince1970))" }
    }

    /// Every enabled, future prayer inside the horizon, nearest first, capped.
    static func alarmPlan(
        days: [DayPrayerTimes],
        now: Date,
        horizonDays: Int,
        limit: Int,
        isEnabled: (Prayer) -> Bool
    ) -> [PrayerInstance] {
        let horizonEnd = now.addingTimeInterval(Double(horizonDays) * 86_400)
        var seen: Set<String> = []
        var entries: [PrayerInstance] = []

        for day in days {
            for prayer in Prayer.allCases where prayer.isNotifiable {
                guard isEnabled(prayer),
                      let time = day.time(for: prayer),
                      time > now, time <= horizonEnd
                else { continue }
                let entry = PrayerInstance(prayer: prayer, date: time)
                // A cached month can legitimately contain the same day twice
                // (refresh overlap); dedupe so one prayer never gets two alarms.
                guard seen.insert(entry.key).inserted else { continue }
                entries.append(entry)
            }
        }
        return Array(entries.sorted { $0.date < $1.date }.prefix(max(0, limit)))
    }

    // MARK: - Budget

    /// Splits `budget` between worship-critical and optional reminders and
    /// truncates. Essentials get everything the extras cannot use; extras keep
    /// `extrasReserve` slots so a crowded prayer schedule cannot starve the
    /// Friday reminder out of existence.
    ///
    /// Generic over the item so `NotificationEngine.Planned` (which carries
    /// non-`Sendable` UserNotifications objects) does not have to live here.
    static func fit<Item>(
        _ items: [Item],
        budget: Int,
        extrasReserve: Int,
        isEssential: (Item) -> Bool,
        rank: (Item) -> Int,
        fireDate: (Item) -> Date
    ) -> [Item] {
        guard budget > 0 else { return [] }

        let essential = items.filter(isEssential)
            .sorted { (fireDate($0), rank($0)) < (fireDate($1), rank($1)) }
        let extras = items.filter { !isEssential($0) }
            .sorted { (rank($0), fireDate($0)) < (rank($1), fireDate($1)) }

        let heldBack = min(extras.count, max(0, min(extrasReserve, budget)))
        let essentialSlots = max(0, budget - heldBack)

        var result = Array(essential.prefix(essentialSlots))
        let remaining = max(0, budget - result.count)
        result.append(contentsOf: extras.prefix(remaining))
        return result
    }
}
