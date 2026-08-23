import Foundation
import SwiftData

/// Dhikr rewards derived from `DhikrSession` aggregates — no extra SwiftData model.
enum DhikrAchievementID: String, CaseIterable, Identifiable, Codable {
    case firstTap
    case first33
    case first99
    case first100
    case day500
    case streak7
    case afterPrayer
    case allTime1000
    case streak30
    case allPhrases
    case allTime10000
    case set500

    var id: String { rawValue }
}

struct DhikrAchievementSnapshot: Identifiable {
    let id: DhikrAchievementID
    let unlocked: Bool
    let current: Int
    let goal: Int
    let symbol: String?
    let sealText: String

    var progress: Double {
        guard goal > 0 else { return unlocked ? 1 : 0 }
        return min(Double(current) / Double(goal), 1)
    }

    var title: String { L10n.achievementTitle(id.rawValue) }
    var lemma: String { L10n.achievementLemma(id.rawValue) }
    var detail: String { L10n.achievementDetail(id.rawValue) }
}

enum DhikrSessionMetrics {
    static func recited(_ session: DhikrSession) -> Int {
        session.recited
    }

    static func allTime(_ sessions: [DhikrSession]) -> Int {
        sessions.reduce(0) { $0 + recited($1) }
    }

    static func totalsByDay(_ sessions: [DhikrSession], calendar: Calendar) -> [Date: Int] {
        var map: [Date: Int] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.date)
            map[day, default: 0] += recited(session)
        }
        return map
    }

    static func bestDay(_ sessions: [DhikrSession], calendar: Calendar) -> Int {
        totalsByDay(sessions, calendar: calendar).values.max() ?? 0
    }

    static func streak(_ sessions: [DhikrSession], now: Date, calendar: Calendar) -> Int {
        var days = Set(
            sessions.filter { recited($0) > 0 }.map { calendar.startOfDay(for: $0.date) }
        )
        var count = 0
        var cursor = calendar.startOfDay(for: now)
        while days.contains(cursor) {
            count += 1
            days.remove(cursor)
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        return count
    }

    static func afterPrayerPhraseHits(_ sessions: [DhikrSession], calendar: Calendar) -> Int {
        let needed: Set<String> = ["subhanallah", "alhamdulillah", "allahu-akbar"]
        var byDay: [Date: [String: Int]] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.date)
            byDay[day, default: [:]][session.dhikrID, default: 0] += recited(session)
        }
        var best = 0
        for phrases in byDay.values {
            let hit = needed.filter { (phrases[$0] ?? 0) >= 33 }.count
            best = max(best, hit)
        }
        return best
    }

    static func phraseVariety(_ sessions: [DhikrSession]) -> Int {
        let ids = Set(DhikrCatalog.core.map(\.id))
        var used: Set<String> = []
        for session in sessions where recited(session) > 0 && ids.contains(session.dhikrID) {
            used.insert(session.dhikrID)
        }
        return used.count
    }

    static func set500Progress(_ sessions: [DhikrSession]) -> Int {
        sessions.reduce(0) { best, session in
            guard session.target == 500 else { return best }
            if session.completedSets >= 1 { return max(best, 500) }
            return max(best, min(session.count, 500))
        }
    }
}

enum DhikrAchievements {
    private static let inscribedKey = "dhikr.inscribedAchievements"

    static func snapshots(
        from sessions: [DhikrSession],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [DhikrAchievementSnapshot] {
        let inscribed = loadInscribed()
        return DhikrAchievementID.allCases.map { id in
            let live = evaluate(id, sessions: sessions, now: now, calendar: calendar)
            let unlocked = live.unlocked || inscribed.contains(id)
            return DhikrAchievementSnapshot(
                id: id,
                unlocked: unlocked,
                current: unlocked ? live.goal : live.current,
                goal: live.goal,
                symbol: sealSymbol(id),
                sealText: sealText(id)
            )
        }
    }

    /// Marks currently earned rewards as already seen so history does not toast on first launch.
    static func inscribeExisting(from sessions: [DhikrSession], now: Date = .now, calendar: Calendar = .current) {
        _ = reveal(from: sessions, celebrate: false, now: now, calendar: calendar)
    }

    /// Returns newly inscribed rewards (catalog order). Empty when nothing fresh unlocked.
    static func reveal(
        from sessions: [DhikrSession],
        celebrate: Bool,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [DhikrAchievementSnapshot] {
        let all = snapshots(from: sessions, now: now, calendar: calendar)
        var inscribed = loadInscribed()
        let freshIDs = Set(all.filter(\.unlocked).map(\.id)).subtracting(inscribed)
        inscribed.formUnion(all.filter(\.unlocked).map(\.id))
        saveInscribed(inscribed)
        guard celebrate else { return [] }
        return all.filter { freshIDs.contains($0.id) }
    }

    private static func evaluate(
        _ id: DhikrAchievementID,
        sessions: [DhikrSession],
        now: Date,
        calendar: Calendar
    ) -> (current: Int, goal: Int, unlocked: Bool) {
        switch id {
        case .firstTap:
            let total = DhikrSessionMetrics.allTime(sessions)
            return (min(total, 1), 1, total >= 1)
        case .first33:
            let total = DhikrSessionMetrics.allTime(sessions)
            return (min(total, 33), 33, total >= 33)
        case .first99:
            let total = DhikrSessionMetrics.allTime(sessions)
            return (min(total, 99), 99, total >= 99)
        case .first100:
            let total = DhikrSessionMetrics.allTime(sessions)
            return (min(total, 100), 100, total >= 100)
        case .day500:
            let best = DhikrSessionMetrics.bestDay(sessions, calendar: calendar)
            return (min(best, 500), 500, best >= 500)
        case .streak7:
            let days = DhikrSessionMetrics.streak(sessions, now: now, calendar: calendar)
            return (min(days, 7), 7, days >= 7)
        case .afterPrayer:
            let hits = DhikrSessionMetrics.afterPrayerPhraseHits(sessions, calendar: calendar)
            return (min(hits, 3), 3, hits >= 3)
        case .allTime1000:
            let total = DhikrSessionMetrics.allTime(sessions)
            return (min(total, 1000), 1000, total >= 1000)
        case .streak30:
            let days = DhikrSessionMetrics.streak(sessions, now: now, calendar: calendar)
            return (min(days, 30), 30, days >= 30)
        case .allPhrases:
            let used = DhikrSessionMetrics.phraseVariety(sessions)
            return (min(used, 6), 6, used >= 6)
        case .allTime10000:
            let total = DhikrSessionMetrics.allTime(sessions)
            return (min(total, 10_000), 10_000, total >= 10_000)
        case .set500:
            let progress = DhikrSessionMetrics.set500Progress(sessions)
            return (progress, 500, progress >= 500)
        }
    }

    private static func sealSymbol(_ id: DhikrAchievementID) -> String? {
        switch id {
        case .firstTap: "hand.tap.fill"
        case .day500: "sun.max.fill"
        default: nil
        }
    }

    private static func sealText(_ id: DhikrAchievementID) -> String {
        switch id {
        case .firstTap: "1"
        case .first33: "33"
        case .first99: "99"
        case .first100: "100"
        case .day500: "500"
        case .streak7: "7"
        case .afterPrayer: "33×3"
        case .allTime1000: "1K"
        case .streak30: "30"
        case .allPhrases: "6"
        case .allTime10000: "10K"
        case .set500: "500"
        }
    }

    private static func loadInscribed() -> Set<DhikrAchievementID> {
        let raw = UserDefaults.standard.stringArray(forKey: inscribedKey) ?? []
        return Set(raw.compactMap(DhikrAchievementID.init(rawValue:)))
    }

    private static func saveInscribed(_ ids: Set<DhikrAchievementID>) {
        UserDefaults.standard.set(ids.map(\.rawValue).sorted(), forKey: inscribedKey)
    }
}
