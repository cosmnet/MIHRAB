import Foundation
import Observation

// MARK: - Bookmark

struct QuranBookmark: Codable, Hashable, Sendable, Identifiable {
    let ref: AyahRef
    var note: String?
    var createdAt: Date

    var id: String { ref.id }
}

/// "Where I left off", kept separate from bookmarks: a bookmark is a decision,
/// a resume point is a side-effect. Conflating them is why other readers lose
/// your place the moment you tap a search result.
struct QuranResumePoint: Codable, Hashable, Sendable {
    var ref: AyahRef
    var updatedAt: Date
}

// MARK: - Store

/// Bookmarks, the resume point, and the daily reading log.
///
/// **Free, all of it.** Bookmarking an ayah and remembering where you stopped
/// are part of reading the Qur'an, and the free tier is not crippled here. The
/// only Plus surfaces in this feature are the extra typography themes and the
/// rendered verse share-card.
@MainActor
@Observable
final class QuranBookmarkStore {
    static let shared = QuranBookmarkStore()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let bookmarks = "mihrab.quran.bookmarks"
        static let resume = "mihrab.quran.resume"
        /// `["yyyy-MM-dd": ayahsRead]`
        static let dailyAyahs = "mihrab.quran.dailyAyahs"
    }

    private(set) var bookmarks: [QuranBookmark] = []
    private(set) var resume: QuranResumePoint?
    /// Ayahs read per ISO day. Feeds the hatim pace estimate and the streak.
    private(set) var dailyAyahs: [String: Int] = [:]

    private init() {
        load()
    }

    // MARK: Persistence

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private func load() {
        if let data = defaults.data(forKey: Key.bookmarks),
           let decoded = try? Self.decoder.decode([QuranBookmark].self, from: data) {
            bookmarks = decoded.sorted { $0.ref < $1.ref }
        }
        if let data = defaults.data(forKey: Key.resume),
           let decoded = try? Self.decoder.decode(QuranResumePoint.self, from: data) {
            resume = decoded
        }
        dailyAyahs = defaults.dictionary(forKey: Key.dailyAyahs) as? [String: Int] ?? [:]
    }

    private func persistBookmarks() {
        if let data = try? Self.encoder.encode(bookmarks) {
            defaults.set(data, forKey: Key.bookmarks)
        }
        QuranSync.push()
    }

    // MARK: Bookmarks

    func isBookmarked(_ ref: AyahRef) -> Bool {
        bookmarks.contains { $0.ref == ref }
    }

    @discardableResult
    func toggleBookmark(_ ref: AyahRef, note: String? = nil) -> Bool {
        if let index = bookmarks.firstIndex(where: { $0.ref == ref }) {
            bookmarks.remove(at: index)
            persistBookmarks()
            return false
        }
        bookmarks.append(QuranBookmark(ref: ref, note: note, createdAt: Date()))
        bookmarks.sort { $0.ref < $1.ref }
        persistBookmarks()
        return true
    }

    func removeBookmark(_ ref: AyahRef) {
        bookmarks.removeAll { $0.ref == ref }
        persistBookmarks()
    }

    func setNote(_ note: String?, for ref: AyahRef) {
        guard let index = bookmarks.firstIndex(where: { $0.ref == ref }) else { return }
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        bookmarks[index].note = (trimmed?.isEmpty ?? true) ? nil : trimmed
        persistBookmarks()
    }

    // MARK: Resume

    /// Called as the reader scrolls. Throttled to one write per ayah change,
    /// and never persisted more than once every few seconds by the caller.
    func noteReading(_ ref: AyahRef) {
        guard resume?.ref != ref else { return }
        let point = QuranResumePoint(ref: ref, updatedAt: Date())
        resume = point
        if let data = try? Self.encoder.encode(point) {
            defaults.set(data, forKey: Key.resume)
        }
    }

    func clearResume() {
        resume = nil
        defaults.removeObject(forKey: Key.resume)
    }

    // MARK: Reading log

    static func dayKey(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    /// Records ayahs finished today. Additive, never decremented — the log is a
    /// record of worship, not a scoreboard to be corrected.
    func logAyahsRead(_ count: Int, on date: Date = Date()) {
        guard count > 0 else { return }
        let key = Self.dayKey(date)
        dailyAyahs[key, default: 0] += count
        defaults.set(dailyAyahs, forKey: Key.dailyAyahs)
        QuranSync.push()
    }

    func ayahsRead(on date: Date = Date()) -> Int {
        dailyAyahs[Self.dayKey(date)] ?? 0
    }

    /// Consecutive days up to and including today with at least one ayah read.
    /// A gap of a single day ends it — no grace, no fake generosity.
    var streak: Int {
        let calendar = Calendar.current
        var count = 0
        var cursor = Date()
        // Today not counting yet should not break yesterday's streak.
        if (dailyAyahs[Self.dayKey(cursor)] ?? 0) == 0 {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }
        while (dailyAyahs[Self.dayKey(cursor)] ?? 0) > 0 {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    // MARK: Sync payload

    struct Snapshot: Codable, Sendable {
        var bookmarks: [QuranBookmark]
        var resume: QuranResumePoint?
        var dailyAyahs: [String: Int]
    }

    func exportSnapshot() -> Snapshot {
        Snapshot(bookmarks: bookmarks, resume: resume, dailyAyahs: dailyAyahs)
    }

    /// Union-additive merge, same contract as `KeyValueSync`: a bookmark made
    /// on either device survives, a day's ayah count takes the larger of the
    /// two, and the newer resume point wins.
    func merge(_ snapshot: Snapshot) {
        var byRef = Dictionary(uniqueKeysWithValues: bookmarks.map { ($0.ref, $0) })
        for incoming in snapshot.bookmarks {
            if let existing = byRef[incoming.ref] {
                if incoming.createdAt < existing.createdAt { byRef[incoming.ref] = incoming }
            } else {
                byRef[incoming.ref] = incoming
            }
        }
        bookmarks = byRef.values.sorted { $0.ref < $1.ref }
        if let data = try? Self.encoder.encode(bookmarks) {
            defaults.set(data, forKey: Key.bookmarks)
        }

        for (day, count) in snapshot.dailyAyahs {
            dailyAyahs[day] = max(dailyAyahs[day] ?? 0, count)
        }
        defaults.set(dailyAyahs, forKey: Key.dailyAyahs)

        if let incoming = snapshot.resume,
           (resume?.updatedAt ?? .distantPast) < incoming.updatedAt {
            resume = incoming
            if let data = try? Self.encoder.encode(incoming) {
                defaults.set(data, forKey: Key.resume)
            }
        }
    }
}
