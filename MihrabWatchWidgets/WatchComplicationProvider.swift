import Foundation
import WidgetKit

/// One timeline entry: the state of the day at `date`.
struct NextPrayerEntry: TimelineEntry {
    let date: Date
    /// The prayer this entry counts down to, and when it falls.
    let prayer: Prayer?
    let prayerDate: Date?
    /// The prayer that just passed — gives the ring something to fill from.
    let previousDate: Date?
    let cityName: String
    /// `false` when the phone has never sent settings and the watch has no fix.
    let isConfigured: Bool
    let relevance: TimelineEntryRelevance?

    static var placeholder: NextPrayerEntry {
        NextPrayerEntry(
        date: Date(),
        prayer: .asr,
        prayerDate: Date().addingTimeInterval(45 * 60),
        previousDate: Date().addingTimeInterval(-75 * 60),
        cityName: "",
        isConfigured: true,
        relevance: nil
        )
    }

    /// Range for `ProgressView(timerInterval:)` / `Text(timerInterval:)`, or
    /// `nil` when it would be empty or inverted. Never build one by hand:
    /// `Text(timerInterval:)` traps on an inverted range, and a widget that
    /// traps takes the whole complication stack down with it.
    var interval: ClosedRange<Date>? {
        guard let prayerDate, let previousDate else { return nil }
        return SafeCountdown.range(from: previousDate, to: prayerDate)
    }

    var countdownRange: ClosedRange<Date>? {
        guard let prayerDate else { return nil }
        return SafeCountdown.range(from: date, to: prayerDate)
    }
}

/// Builds the complication timeline **entirely on the watch**.
///
/// This is the payoff of syncing settings instead of results: the timeline is
/// produced from `PrayerEngine` locally, so a complication never sits blank
/// waiting for a `transferCurrentComplicationUserInfo` that the phone's daily
/// budget could not afford. The phone's nudge is an optimisation — it makes an
/// updated setting show up promptly — not the data path.
struct NextPrayerProvider: TimelineProvider {

    func placeholder(in context: Context) -> NextPrayerEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (NextPrayerEntry) -> Void) {
        completion(context.isPreview ? .placeholder : entries(from: Date()).first ?? unconfigured())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextPrayerEntry>) -> Void) {
        let entries = entries(from: Date())
        guard !entries.isEmpty else {
            // Nothing to say yet. Ask again in an hour rather than never: the
            // phone may pair or send settings at any moment.
            let retry = Date().addingTimeInterval(3600)
            completion(Timeline(entries: [unconfigured()], policy: .after(retry)))
            return
        }
        // `.atEnd` is right here: the last entry is tomorrow's Isha and the
        // system will come back for more before it lapses. A fixed refresh
        // interval would spend the widget budget for no new information.
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func unconfigured() -> NextPrayerEntry {
        NextPrayerEntry(date: Date(), prayer: nil, prayerDate: nil, previousDate: nil,
                        cityName: "", isConfigured: false, relevance: nil)
    }

    /// An entry at "now" plus one at every prayer boundary through tomorrow.
    private func entries(from now: Date) -> [NextPrayerEntry] {
        let payload = WatchSharedState.loadSettings()
        guard let schedule = WatchScheduleBuilder.schedule(for: now, payload: payload, watchFix: nil) else {
            return []
        }
        let city = schedule.cityName

        // Every boundary in today and tomorrow, ascending, from `now` onward.
        var boundaries: [(prayer: Prayer, date: Date)] = []
        for day in [schedule.today, schedule.tomorrow].compactMap({ $0 }) {
            for prayer in Prayer.allCases {
                if let time = day.times[prayer] { boundaries.append((prayer, time)) }
            }
        }
        boundaries.sort { $0.date < $1.date }

        var entries: [NextPrayerEntry] = []
        // The prayer already behind us anchors the first ring.
        var previousBoundary = schedule.previous(before: now)?.date
        // Each entry becomes current when the previous boundary arrives; the
        // first one is current immediately.
        var entryStart = now

        for boundary in boundaries where boundary.date > now {
            entries.append(NextPrayerEntry(
                date: entryStart,
                prayer: boundary.prayer,
                prayerDate: boundary.date,
                previousDate: previousBoundary,
                cityName: city,
                isConfigured: true,
                relevance: relevance(from: entryStart, to: boundary.date)
            ))
            entryStart = boundary.date
            previousBoundary = boundary.date
            if entries.count >= 14 { break }
        }
        return entries
    }

    /// Smart Stack ordering.
    ///
    /// The complication is worth surfacing in the last stretch before a prayer
    /// and worth nothing three hours out, so the score rises as the window
    /// narrows. `duration` scopes the claim: without it a high score would
    /// pin Mihrab to the top of the stack all day, which is exactly the kind of
    /// thing that gets an app swiped away.
    private func relevance(from start: Date, to prayerDate: Date) -> TimelineEntryRelevance {
        let lead = prayerDate.timeIntervalSince(start)
        let window = min(lead, 30 * 60)
        let score: Float = lead <= 30 * 60 ? 90 : 40
        return TimelineEntryRelevance(score: score, duration: window)
    }
}

// MARK: - Dhikr

struct DhikrEntry: TimelineEntry {
    let date: Date
    let total: Int
    let phrase: WatchDhikrItem

    static let placeholder = DhikrEntry(date: Date(), total: 33, phrase: WatchDhikrCatalog.default)
}

/// The day's dhikr tally, straight out of the watch's shared container.
///
/// Refreshed at midnight because that is the only moment the number changes on
/// its own; every other change comes from the app, which reloads the timeline
/// itself.
struct DhikrProvider: TimelineProvider {

    func placeholder(in context: Context) -> DhikrEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (DhikrEntry) -> Void) {
        completion(context.isPreview ? .placeholder : current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DhikrEntry>) -> Void) {
        let calendar = Calendar(identifier: .gregorian)
        let midnight = calendar.nextDate(after: Date(),
                                         matching: DateComponents(hour: 0, minute: 0),
                                         matchingPolicy: .nextTime)
            ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [current()], policy: .after(midnight)))
    }

    private func current() -> DhikrEntry {
        let phrase = WatchDhikrCatalog.item(id: WatchSharedState.dhikrPhraseID) ?? WatchDhikrCatalog.default
        return DhikrEntry(date: Date(), total: WatchSharedState.dhikrTodayCount, phrase: phrase)
    }
}
