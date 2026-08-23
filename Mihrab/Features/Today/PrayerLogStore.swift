import Foundation
import SwiftUI

/// "I prayed this" marks plus the daily streak they build.
///
/// Deliberately its own tiny store: the SwiftData layer in `Mihrab/Data` is
/// shared with the widgets and is off-limits here, and a set of five booleans
/// per day is exactly what `UserDefaults` is for.
@Observable
final class PrayerLogStore: @unchecked Sendable {
    static let shared = PrayerLogStore()

    /// The five fard prayers — Sunrise is a marker, never a prayer to log.
    static let fardPrayers: [Prayer] = Prayer.allCases.filter { $0 != .sunrise }

    private let defaults: UserDefaults

    /// Bumped on every write so `@Observable` re-renders views that read
    /// through the `logged(_:on:)` helpers.
    private(set) var revision = 0

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Keys

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private func key(for date: Date) -> String {
        "prayerLog.\(Self.formatter.string(from: date))"
    }

    // MARK: - Reads

    func logged(on date: Date = Date()) -> Set<Prayer> {
        _ = revision
        let raw = defaults.stringArray(forKey: key(for: date)) ?? []
        return Set(raw.compactMap(Prayer.init(rawValue:)))
    }

    func isLogged(_ prayer: Prayer, on date: Date = Date()) -> Bool {
        logged(on: date).contains(prayer)
    }

    func completedCount(on date: Date = Date()) -> Int {
        logged(on: date).intersection(Self.fardPrayers).count
    }

    func isDayComplete(_ date: Date) -> Bool {
        completedCount(on: date) == Self.fardPrayers.count
    }

    // MARK: - Writes

    /// Returns the new state so callers can pick the right haptic.
    @discardableResult
    func toggle(_ prayer: Prayer, on date: Date = Date()) -> Bool {
        guard prayer.isNotifiable else { return false }
        var set = logged(on: date)
        let nowLogged: Bool
        if set.contains(prayer) {
            set.remove(prayer)
            nowLogged = false
        } else {
            set.insert(prayer)
            nowLogged = true
        }
        defaults.set(set.map(\.rawValue), forKey: key(for: date))
        revision &+= 1
        return nowLogged
    }

    // MARK: - History

    /// One entry per day, oldest first, ending today. Used by the week strip so
    /// the streak reads as a *pattern* rather than a single number — and an
    /// empty day stays simply empty, never an accusation.
    struct DaySummary: Identifiable, Hashable {
        let date: Date
        let completed: Int
        var total: Int { PrayerLogStore.fardPrayers.count }
        var isComplete: Bool { completed == total }
        var id: Date { date }
    }

    func recentDays(_ count: Int = 7, endingOn date: Date = Date()) -> [DaySummary] {
        _ = revision
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: date)
        return (0..<max(count, 1)).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: end) else { return nil }
            return DaySummary(date: day, completed: completedCount(on: day))
        }
    }

    // MARK: - Streak

    /// Consecutive complete days ending today (or yesterday, so the streak is
    /// not "lost" before the day is over).
    var streak: Int {
        _ = revision
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: Date())
        var count = 0

        if !isDayComplete(day) {
            // Today still in progress — start counting from yesterday.
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }

        // 400 is a hard stop; nobody needs a longer number on a card.
        while count < 400, isDayComplete(day) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }
}
