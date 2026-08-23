import Foundation
import SwiftUI

/// Missed-prayer (kaza) debt and the daily record of paying it down.
///
/// Kept in `UserDefaults` as one small JSON blob: the SwiftData layer under
/// `Mihrab/Data` is shared with the widgets and owned elsewhere, and this is a
/// handful of counters plus a per-day ledger.
///
/// Tone note for anyone editing this file: nothing here counts *guilt*. There
/// is no "overdue", no red, no shrinking deadline. The only numbers we keep are
/// what is left and what has been made up.
@MainActor
@Observable
final class QadaStore {
    static let shared = QadaStore()

    /// The five fard prayers. Sunrise is a marker, never a prayer.
    static let fardPrayers: [Prayer] = Prayer.allCases.filter { $0 != .sunrise }

    // MARK: - Persisted state

    struct State: Codable, Equatable, Sendable {
        /// Remaining debt per prayer, keyed by `Prayer.rawValue`.
        var remaining: [String: Int] = [:]
        /// Witr (Hanafi: wajib) tracked separately from the five fard.
        var remainingWitr: Int = 0
        /// What the debt was when the user first set it, so progress can be shown.
        var startingTotal: Int = 0
        /// Made-up prayers per day, `yyyy-MM-dd` → `Prayer.rawValue` → count.
        var ledger: [String: [String: Int]] = [:]
        var witrLedger: [String: Int] = [:]
        var setupCompleted = false
        var trackWitr = false
        var completedAt: Date?
        /// Milestone percentages already celebrated, so a party fires once.
        var celebratedMilestones: [Int] = []
    }

    private let defaults: UserDefaults
    private static let storageKey = "qada.state.v1"

    private(set) var state: State {
        didSet { persist() }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(State.self, from: data) {
            state = decoded
        } else {
            state = State()
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    // MARK: - Reads

    var isSetUp: Bool { state.setupCompleted }
    var tracksWitr: Bool { state.trackWitr }

    func remaining(_ prayer: Prayer) -> Int {
        max(0, state.remaining[prayer.rawValue] ?? 0)
    }

    var remainingWitr: Int { max(0, state.remainingWitr) }

    /// **Reading point for other modules** (Today badge, widgets, Settings row).
    /// Total prayers still owed, witr included when the user tracks it.
    var totalRemaining: Int {
        Self.fardPrayers.reduce(0) { $0 + remaining($1) } + (state.trackWitr ? remainingWitr : 0)
    }

    var startingTotal: Int { state.startingTotal }

    var totalPaid: Int { max(0, state.startingTotal - totalRemaining) }

    /// 0…1. Returns 0 rather than a divide-by-zero when nothing was ever owed.
    var progress: Double {
        guard state.startingTotal > 0 else { return 0 }
        return min(1, Double(totalPaid) / Double(state.startingTotal))
    }

    var isComplete: Bool { state.setupCompleted && totalRemaining == 0 && state.startingTotal > 0 }

    var completedAt: Date? { state.completedAt }

    // MARK: - Daily ledger

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private func key(_ date: Date) -> String { Self.dayFormatter.string(from: date) }

    func paid(_ prayer: Prayer, on date: Date = Date()) -> Int {
        state.ledger[key(date)]?[prayer.rawValue] ?? 0
    }

    func paidWitr(on date: Date = Date()) -> Int {
        state.witrLedger[key(date)] ?? 0
    }

    func paidTotal(on date: Date = Date()) -> Int {
        let day = state.ledger[key(date)]?.values.reduce(0, +) ?? 0
        return day + (state.trackWitr ? paidWitr(on: date) : 0)
    }

    /// Consecutive days ending today (or yesterday, so a day in progress never
    /// "loses" the streak) on which at least one prayer was made up.
    var streak: Int {
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: Date())
        var count = 0
        if paidTotal(on: day) == 0 {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        while paidTotal(on: day) > 0 {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    /// Average made up per day over the last `window` days, ignoring days
    /// before setup. Zero when there is nothing to average.
    func dailyAverage(window: Int = 30) -> Double {
        let calendar = Calendar.current
        var total = 0
        var day = calendar.startOfDay(for: Date())
        for _ in 0..<max(1, window) {
            total += paidTotal(on: day)
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return Double(total) / Double(max(1, window))
    }

    /// "At this pace, you finish on …". `nil` when the pace is zero — we show
    /// an encouraging prompt instead of an infinite date.
    func projectedCompletion(window: Int = 30) -> Date? {
        let pace = dailyAverage(window: window)
        guard pace > 0.05, totalRemaining > 0 else { return nil }
        let days = Double(totalRemaining) / pace
        guard days.isFinite, days < 365 * 80 else { return nil }
        return Calendar.current.date(byAdding: .day, value: Int(days.rounded(.up)), to: Date())
    }

    // MARK: - Writes

    /// Record one made-up prayer. Returns `false` when there is nothing left to
    /// make up, so the caller can skip the haptic.
    @discardableResult
    func markPaid(_ prayer: Prayer, on date: Date = Date()) -> Bool {
        guard remaining(prayer) > 0 else { return false }
        state.remaining[prayer.rawValue] = remaining(prayer) - 1
        var day = state.ledger[key(date)] ?? [:]
        day[prayer.rawValue] = (day[prayer.rawValue] ?? 0) + 1
        state.ledger[key(date)] = day
        finishIfComplete()
        return true
    }

    /// Undo a mark made today — a mis-tap must never cost the user a prayer.
    @discardableResult
    func undoPaid(_ prayer: Prayer, on date: Date = Date()) -> Bool {
        guard paid(prayer, on: date) > 0 else { return false }
        var day = state.ledger[key(date)] ?? [:]
        day[prayer.rawValue] = (day[prayer.rawValue] ?? 1) - 1
        if day[prayer.rawValue] == 0 { day[prayer.rawValue] = nil }
        state.ledger[key(date)] = day.isEmpty ? nil : day
        state.remaining[prayer.rawValue] = remaining(prayer) + 1
        state.completedAt = nil
        return true
    }

    @discardableResult
    func markWitrPaid(on date: Date = Date()) -> Bool {
        guard state.trackWitr, remainingWitr > 0 else { return false }
        state.remainingWitr = remainingWitr - 1
        state.witrLedger[key(date)] = paidWitr(on: date) + 1
        finishIfComplete()
        return true
    }

    @discardableResult
    func undoWitrPaid(on date: Date = Date()) -> Bool {
        guard paidWitr(on: date) > 0 else { return false }
        state.witrLedger[key(date)] = paidWitr(on: date) - 1
        if state.witrLedger[key(date)] == 0 { state.witrLedger[key(date)] = nil }
        state.remainingWitr = remainingWitr + 1
        state.completedAt = nil
        return true
    }

    /// Manual correction from the debt editor. Never goes below zero.
    func setRemaining(_ count: Int, for prayer: Prayer) {
        let clamped = max(0, count)
        let delta = clamped - remaining(prayer)
        state.remaining[prayer.rawValue] = clamped
        // Keep the "starting" figure consistent so progress stays honest when
        // the user remembers more debt later.
        state.startingTotal = max(0, state.startingTotal + delta)
        finishIfComplete()
    }

    func setRemainingWitr(_ count: Int) {
        let clamped = max(0, count)
        let delta = clamped - remainingWitr
        state.remainingWitr = clamped
        state.startingTotal = max(0, state.startingTotal + delta)
        finishIfComplete()
    }

    /// Apply a wizard estimate. Existing debt is replaced, existing history kept.
    func apply(_ estimate: QadaEstimate, trackWitr: Bool) {
        var remaining: [String: Int] = [:]
        for prayer in Self.fardPrayers { remaining[prayer.rawValue] = estimate.perPrayer }
        state.remaining = remaining
        state.remainingWitr = trackWitr ? estimate.witr : 0
        state.trackWitr = trackWitr
        state.startingTotal = estimate.perPrayer * 5 + (trackWitr ? estimate.witr : 0)
        state.setupCompleted = true
        state.completedAt = nil
        state.celebratedMilestones = []
    }

    /// Wipe everything — offered in Settings with a confirmation.
    func reset() {
        state = State()
    }

    private func finishIfComplete() {
        if totalRemaining == 0, state.startingTotal > 0, state.completedAt == nil {
            state.completedAt = Date()
        }
    }

    // MARK: - Milestones

    /// Percentages worth celebrating, in the order they are reached.
    static let milestones = [10, 25, 50, 75, 90, 100]

    /// The milestone crossed by the most recent mark, if it has not been shown
    /// before. Consuming it records it, so the sheet appears exactly once.
    func consumeNewMilestone() -> Int? {
        guard state.startingTotal > 0 else { return nil }
        let percent = Int((progress * 100).rounded(.down))
        guard let reached = Self.milestones.last(where: { $0 <= percent }) else { return nil }
        guard !state.celebratedMilestones.contains(reached) else { return nil }
        state.celebratedMilestones.append(reached)
        return reached
    }
}
