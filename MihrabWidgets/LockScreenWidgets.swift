import SwiftUI
import WidgetKit

/// Lock Screen accessories. All three render in `.accented` mode as well as
/// full colour, so every element that must survive the tint pass is marked
/// `widgetAccentable()` rather than relying on its own colour.

struct LockScreenCircularWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockScreenCircular", provider: PrayerTimelineProvider()) { entry in
            LockScreenCircularView(entry: entry)
        }
        .configurationDisplayName("Next Prayer")
        .description("Tells you which prayer is next and how long is left.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct LockScreenCircularView: View {
    let entry: PrayerEntry

    private var next: (prayer: Prayer, date: Date)? {
        entry.snapshot?.day(containing: entry.date)?
            .nextPrayer(after: entry.date, tomorrow: nextDay)
    }

    private var nextDay: DayPrayerTimes? {
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: entry.date) else { return nil }
        return entry.snapshot?.day(containing: tomorrow)
    }

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            if let next {
                VStack(spacing: 1) {
                    Image(systemName: next.prayer.symbolName)
                        .widgetAccentedRenderingMode(.desaturated)
                        .font(.caption)
                    Text(next.date, format: .dateTime.hour().minute())
                        .font(.system(.body, design: .rounded).bold().monospacedDigit())
                }
                .widgetAccentable()
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(next.prayer.localizedNamazName) \(MihrabIntentData.clock(next.date))")
            } else {
                Image(systemName: "moon.stars.fill")
                    .widgetAccentedRenderingMode(.desaturated)
            }
        }
        .widgetURL(MihrabDeepLink.url(for: .times))
    }
}

struct LockScreenRectangularWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockScreenRectangular", provider: PrayerTimelineProvider()) { entry in
            LockScreenRectangularView(entry: entry)
        }
        .configurationDisplayName("Prayer Times by City")
        .description("Returns every prayer time for today.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct LockScreenRectangularView: View {
    let entry: PrayerEntry

    private var day: DayPrayerTimes? { entry.snapshot?.day(containing: entry.date) }

    private var next: (prayer: Prayer, date: Date)? {
        day?.nextPrayer(after: entry.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let next {
                HStack {
                    Text("\(next.prayer.localizedNamazName) \(next.date, format: .dateTime.hour().minute())")
                        .font(.headline.monospacedDigit())
                        .widgetAccentable()
                    Spacer()
                    if let range = SafeCountdown.range(from: entry.date, to: next.date) {
                        Text(timerInterval: range, countsDown: true)
                            .font(.caption.monospacedDigit())
                            .frame(maxWidth: 56, alignment: .trailing)
                    }
                }
                if let day {
                    HStack(spacing: 8) {
                        ForEach(Prayer.allCases) { prayer in
                            if let time = day.time(for: prayer) {
                                Text(time, format: .dateTime.hour())
                                    .font(.caption2.monospacedDigit())
                                    .opacity(prayer == next.prayer ? 1 : 0.6)
                            }
                        }
                    }
                    .accessibilityHidden(true)
                }
            } else {
                Text("Mihrab")
                    .font(.headline)
                    .widgetAccentable()
            }
        }
        .widgetURL(MihrabDeepLink.url(for: .times))
    }
}

struct LockScreenInlineWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockScreenInline", provider: PrayerTimelineProvider()) { entry in
            let next = entry.snapshot?.day(containing: entry.date)?.nextPrayer(after: entry.date)
            if let next {
                Text("\(next.prayer.localizedNamazName) \(next.date, format: .dateTime.hour().minute())")
            } else {
                Text("Mihrab")
            }
        }
        .configurationDisplayName("Next Prayer")
        .description("Tells you which prayer is next and how long is left.")
        .supportedFamilies([.accessoryInline])
    }
}
