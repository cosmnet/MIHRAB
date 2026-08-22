import SwiftUI
import WidgetKit

struct LockScreenCircularWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockScreenCircular", provider: PrayerTimelineProvider()) { entry in
            let next = entry.snapshot?.day(containing: entry.date)?.nextPrayer(after: entry.date)
            ZStack {
                AccessoryWidgetBackground()
                if let next {
                    VStack(spacing: 1) {
                        Image(systemName: next.prayer.symbolName)
                            .font(.caption)
                        Text(next.date, format: .dateTime.hour().minute(.omitted))
                            .font(.system(.body, design: .rounded).bold().monospacedDigit())
                    }
                }
            }
            .widgetURL(URL(string: "mihrab://times"))
        }
        .configurationDisplayName("Next Prayer")
        .description("Next prayer at a glance.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct LockScreenRectangularWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockScreenRectangular", provider: PrayerTimelineProvider()) { entry in
            let day = entry.snapshot?.day(containing: entry.date)
            let next = day?.nextPrayer(after: entry.date)
            VStack(alignment: .leading, spacing: 2) {
                if let next {
                    HStack {
                        Text("\(next.prayer.localizedName) \(next.date, format: .dateTime.hour().minute())")
                            .font(.headline.monospacedDigit())
                        Spacer()
                        if let range = SafeCountdown.range(from: entry.date, to: next.date) {
                            Text(timerInterval: range, countsDown: true)
                                .font(.caption.monospacedDigit())
                        }
                    }
                    if let day {
                        HStack(spacing: 8) {
                            ForEach(Prayer.allCases) { prayer in
                                if let time = day.time(for: prayer) {
                                    Text(time, format: .dateTime.hour())
                                        .font(.system(size: 9).monospacedDigit())
                                        .opacity(prayer == next.prayer ? 1 : 0.6)
                                }
                            }
                        }
                    }
                } else {
                    Text("Mihrab")
                        .font(.headline)
                }
            }
            .widgetURL(URL(string: "mihrab://times"))
        }
        .configurationDisplayName("Prayer Schedule")
        .description("Next prayer and today's times.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct LockScreenInlineWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockScreenInline", provider: PrayerTimelineProvider()) { entry in
            let next = entry.snapshot?.day(containing: entry.date)?.nextPrayer(after: entry.date)
            if let next {
                Text("\(next.prayer.localizedName) \(next.date, format: .dateTime.hour().minute())")
            } else {
                Text("Mihrab")
            }
        }
        .configurationDisplayName("Next Prayer Inline")
        .description("Next prayer, inline.")
        .supportedFamilies([.accessoryInline])
    }
}
