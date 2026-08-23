import SwiftUI
import WidgetKit

struct PrayerEntry: TimelineEntry {
    let date: Date
    let snapshot: SharedPrayerSnapshot?
}

struct PrayerTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerEntry {
        PrayerEntry(date: Date(), snapshot: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
        completion(PrayerEntry(date: Date(), snapshot: SharedPrayerCache.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        let snapshot = SharedPrayerCache.load()
        var entries: [PrayerEntry] = []
        let now = Date()

        // Refresh at each prayer boundary + every 15 minutes.
        var boundaries: [Date] = []
        if let today = snapshot?.day(containing: now) {
            boundaries = today.times.values.filter { $0 > now }.sorted()
        }
        for minute in stride(from: 0, through: 60, by: 15) {
            if let date = Calendar.current.date(byAdding: .minute, value: minute, to: now) {
                entries.append(PrayerEntry(date: date, snapshot: snapshot))
            }
        }
        let reloadDate = boundaries.first
            ?? Calendar.current.date(byAdding: .hour, value: 1, to: now)
            ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: entries, policy: .after(reloadDate)))
    }
}

struct PrayerTimesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PrayerTimesWidget", provider: PrayerTimelineProvider()) { entry in
            PrayerTimesWidgetView(entry: entry)
                .containerBackground(MihrabColor.abyss, for: .widget)
        }
        .configurationDisplayName("Today's Prayer Times")
        .description("Tells you which prayer is next and how long is left.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct PrayerTimesWidgetView: View {
    let entry: PrayerEntry
    @Environment(\.widgetFamily) private var family
    @ScaledMetric(relativeTo: .title) private var clockSize: CGFloat = 28

    /// Rolls over to tomorrow's Fajr after Isha, so the tile is never blank
    /// for the six hours that matter least but are noticed most.
    private var next: (prayer: Prayer, date: Date)? {
        guard let today = entry.snapshot?.day(containing: entry.date) else { return nil }
        let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: entry.date)
        let tomorrow = tomorrowDate.flatMap { entry.snapshot?.day(containing: $0) }
        return today.nextPrayer(after: entry.date, tomorrow: tomorrow)
    }

    var body: some View {
        switch family {
        case .systemSmall: smallView
        default: mediumView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let next {
                Text(next.prayer.localizedNamazName.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(MihrabColor.brass)
                    .widgetAccentable()
                Text(next.date, format: .dateTime.hour().minute())
                    .font(.system(size: clockSize, weight: .bold, design: .rounded).monospacedDigit())
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundStyle(MihrabColor.mint)
                if let range = SafeCountdown.range(from: entry.date, to: next.date) {
                    Text(timerInterval: range, countsDown: true)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(MihrabColor.textSecondary)
                }
                if let hijri = entry.snapshot?.day(containing: entry.date)?.hijriDate {
                    Text(hijri.formatted)
                        .font(.caption2)
                        .foregroundStyle(MihrabColor.textTertiary)
                }
            } else {
                Text(L10n.wgtOpenAppHint)
                    .font(.caption)
                    .foregroundStyle(MihrabColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(MihrabDeepLink.url(for: .times))
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            smallView
            Divider().overlay(MihrabColor.textTertiary.opacity(0.3))
            if let day = entry.snapshot?.day(containing: entry.date) {
                VStack(spacing: 4) {
                    ForEach(Prayer.allCases) { prayer in
                        HStack {
                            Text(prayer.localizedName)
                                .font(.caption2)
                            Spacer()
                            if let time = day.time(for: prayer) {
                                Text(time, format: .dateTime.hour().minute())
                                    .font(.caption2.monospacedDigit())
                            } else {
                                Text("–")
                                    .font(.caption2.monospacedDigit())
                            }
                        }
                        .foregroundStyle(next?.prayer == prayer ? MihrabColor.mint : MihrabColor.textSecondary)
                    }
                }
            }
        }
        .widgetURL(MihrabDeepLink.url(for: .times))
    }
}
