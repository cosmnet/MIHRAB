import Foundation

// MARK: - Scope

/// What a plan covers. Everything is expressed as a span of absolute ayah
/// indices (1…6236) so individual and shared plans share one progress maths.
struct HatimScope: Codable, Hashable, Sendable {
    /// First ayah of the span, 1-based absolute index.
    let start: Int
    /// Last ayah of the span, inclusive.
    let end: Int

    static let fullMushaf = HatimScope(start: 1, end: QuranCatalog.totalAyahs)

    /// The span of one juz, 1…30.
    static func juz(_ number: Int) -> HatimScope? {
        guard (1...30).contains(number) else { return nil }
        let division = QuranCatalog.juz[number - 1]
        guard let start = QuranCatalog.absoluteIndex(of: division.start),
              let end = QuranCatalog.absoluteIndex(of: division.end)
        else { return nil }
        return HatimScope(start: start, end: end)
    }

    var ayahCount: Int { max(0, end - start + 1) }

    var isFullMushaf: Bool { start == 1 && end == QuranCatalog.totalAyahs }

    /// Mushaf pages the span touches — the unit people actually plan in.
    var pageCount: Int {
        guard let first = QuranCatalog.ref(atAbsoluteIndex: start),
              let last = QuranCatalog.ref(atAbsoluteIndex: end),
              let firstPage = QuranCatalog.page(containing: first),
              let lastPage = QuranCatalog.page(containing: last)
        else { return 0 }
        return lastPage - firstPage + 1
    }

    func contains(_ absolute: Int) -> Bool { (start...end).contains(absolute) }
}

// MARK: - Shared hatim

/// A shared hatim as this device can honestly model it: **no server**.
///
/// The group definition (name, target date, how many juz) travels in an invite
/// code. Each participant keeps their *own* juz and their own progress locally.
/// Nobody's device can see anybody else's progress, and the app never pretends
/// otherwise — `HatimView` says so in plain words rather than drawing a fake
/// group ring.
///
/// What real-time would need is written up in the agent report: a shared
/// backend, or CloudKit — and note that SwiftData's CloudKit integration does
/// **not** support `CKShare`, so a shared hatim would have to drop to raw
/// `CKRecord`/`CKShare` in a custom zone.
struct HatimGroup: Codable, Hashable, Sendable {
    /// Stable id carried in the invite so two people can tell they joined the
    /// same hatim. Not a server key — nothing resolves it.
    let id: String
    var name: String
    /// How many shares the hatim is split into. 30 is the tradition; smaller
    /// circles split into 10 or 15 and take multiple juz each.
    var shareCount: Int
    var targetDate: Date
    /// The juz numbers this device claimed, 1…30.
    var claimedJuz: [Int]
    /// Who set it up, for the invite text only. Never uploaded anywhere.
    var organiser: String?

    static func newID() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(12).lowercased()
    }
}

// MARK: - Plan

struct HatimPlan: Codable, Hashable, Sendable, Identifiable {
    enum Kind: String, Codable, Sendable {
        case individual
        case shared
    }

    let id: String
    var kind: Kind
    var title: String
    var scope: HatimScope
    var startedAt: Date
    var targetDate: Date
    /// Highest absolute ayah index recorded as read. `scope.start - 1` means
    /// "not started". Monotonic — progress is never rolled back by a sync.
    var position: Int
    var group: HatimGroup?
    var completedAt: Date?

    init(
        id: String = UUID().uuidString,
        kind: Kind,
        title: String,
        scope: HatimScope,
        startedAt: Date = Date(),
        targetDate: Date,
        position: Int? = nil,
        group: HatimGroup? = nil,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.scope = scope
        self.startedAt = startedAt
        self.targetDate = targetDate
        self.position = position ?? (scope.start - 1)
        self.group = group
        self.completedAt = completedAt
    }
}

// MARK: - Derived progress

/// Everything the hatim card shows, computed — never stored, never guessed.
struct HatimProgress: Hashable, Sendable {
    let ayahsRead: Int
    let ayahsTotal: Int
    let pagesRead: Int
    let pagesTotal: Int
    let juzRead: Double
    /// 0…1.
    let fraction: Double
    /// Whole days from `now` to the target, inclusive of today. 0 when the
    /// target is today or past.
    let daysRemaining: Int
    /// Pages that must be read per remaining day to land on the target.
    /// `nil` once finished.
    let pagesPerDay: Double?
    /// Observed pace, pages/day since the plan started. `nil` before any
    /// progress — an estimate from zero data is a lie.
    let observedPagesPerDay: Double?
    /// Projection at the observed pace. `nil` when there is no pace to project.
    let projectedFinish: Date?
    let isComplete: Bool
    /// `true` when the projection lands on or before the target.
    let isOnTrack: Bool?

    var percent: Int { Int((fraction * 100).rounded()) }
}

enum HatimMath {

    /// Days from `from` to `to`, counting the current day as one. Uses calendar
    /// day boundaries, not 24-hour blocks, so "finish by Ramadan's last day"
    /// means what a reader means by it.
    static func daysBetween(_ from: Date, _ to: Date, calendar: Calendar = .current) -> Int {
        let a = calendar.startOfDay(for: from)
        let b = calendar.startOfDay(for: to)
        let days = calendar.dateComponents([.day], from: a, to: b).day ?? 0
        return max(0, days) + (days >= 0 ? 1 : 0)
    }

    static func pageIndex(ofAbsolute absolute: Int) -> Int? {
        guard let ref = QuranCatalog.ref(atAbsoluteIndex: absolute) else { return nil }
        return QuranCatalog.page(containing: ref)
    }

    static func progress(
        for plan: HatimPlan,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> HatimProgress {
        let total = plan.scope.ayahCount
        let read = max(0, min(plan.position - plan.scope.start + 1, total))
        let fraction = total > 0 ? Double(read) / Double(total) : 0
        let isComplete = read >= total && total > 0

        let pagesTotal = plan.scope.pageCount
        let pagesRead: Int
        if read <= 0 {
            pagesRead = 0
        } else if isComplete {
            pagesRead = pagesTotal
        } else if let startPage = pageIndex(ofAbsolute: plan.scope.start),
                  let here = pageIndex(ofAbsolute: plan.position) {
            pagesRead = max(0, here - startPage)
        } else {
            pagesRead = Int((Double(pagesTotal) * fraction).rounded(.down))
        }

        let juzRead = fraction * (plan.scope.isFullMushaf
            ? Double(QuranCatalog.totalJuz)
            : Double(plan.scope.ayahCount) / Double(QuranCatalog.totalAyahs) * Double(QuranCatalog.totalJuz))

        let daysRemaining = isComplete ? 0 : daysBetween(now, plan.targetDate, calendar: calendar)
        let pagesLeft = max(0, pagesTotal - pagesRead)
        let pagesPerDay: Double? = isComplete
            ? nil
            : (daysRemaining > 0 ? Double(pagesLeft) / Double(daysRemaining) : Double(pagesLeft))

        // Observed pace. Elapsed days counts today, so a plan started this
        // morning divides by 1 rather than 0.
        let elapsed = max(1, daysBetween(plan.startedAt, now, calendar: calendar))
        let observed: Double? = pagesRead > 0 ? Double(pagesRead) / Double(elapsed) : nil

        var projected: Date?
        var onTrack: Bool?
        if !isComplete, let observed, observed > 0 {
            let daysNeeded = Int((Double(pagesLeft) / observed).rounded(.up))
            projected = calendar.date(byAdding: .day, value: daysNeeded, to: calendar.startOfDay(for: now))
            if let projected {
                onTrack = calendar.startOfDay(for: projected) <= calendar.startOfDay(for: plan.targetDate)
            }
        }

        return HatimProgress(
            ayahsRead: read,
            ayahsTotal: total,
            pagesRead: pagesRead,
            pagesTotal: pagesTotal,
            juzRead: juzRead,
            fraction: fraction,
            daysRemaining: daysRemaining,
            pagesPerDay: pagesPerDay,
            observedPagesPerDay: observed,
            projectedFinish: projected,
            isComplete: isComplete,
            isOnTrack: onTrack
        )
    }

    /// Suggested target for "finish by the end of Ramadan": the 29th/30th of
    /// Ramadan in the current or next Hijri year.
    ///
    /// Derived from the Islamic calendar, never hardcoded — and returns `nil`
    /// rather than a guess if the calendar cannot resolve it.
    static func endOfRamadan(from now: Date = Date()) -> Date? {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.timeZone = .current
        let hijri = calendar.dateComponents([.year, .month], from: now)
        guard let year = hijri.year, let month = hijri.month else { return nil }
        let targetYear = month > 9 ? year + 1 : year
        var components = DateComponents()
        components.year = targetYear
        components.month = 9
        components.day = 29
        return calendar.date(from: components)
    }
}
