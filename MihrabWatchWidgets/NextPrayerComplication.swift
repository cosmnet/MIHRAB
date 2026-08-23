import SwiftUI
import WidgetKit

/// The next prayer, in all four watch accessory families.
///
/// ClockKit is deprecated and is not used: `CLKComplicationDataSource`,
/// `CLKComplicationTemplate` and the principal-class Info.plist keys appear
/// nowhere in this target. Every family below is a WidgetKit accessory family.
struct NextPrayerComplication: Widget {

    static let kind = "MihrabNextPrayerComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: NextPrayerProvider()) { entry in
            NextPrayerComplicationView(entry: entry)
                .containerBackground(Color.clear, for: .widget)
        }
        .configurationDisplayName(L10n.wComplicationNextName)
        .description(L10n.wComplicationNextDescription)
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            // watchOS only — the curved corner slot. Listing it on any other
            // platform is a build error, which is one more reason the watch
            // complications live in their own target.
            .accessoryCorner,
        ])
    }
}

struct NextPrayerComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NextPrayerEntry

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .accessoryInline: inline
        case .accessoryCorner: corner
        default: circular
        }
    }

    // MARK: - Circular

    private var circular: some View {
        ZStack {
            // The system-provided tint-aware plate. Drawing our own fill here
            // would fight the watch face's tint and look wrong on half of them.
            AccessoryWidgetBackground()
            if let prayer = entry.prayer, let range = entry.interval {
                // A `ProgressView(timerInterval:)` advances on its own — the
                // ring keeps filling with no timeline entry and no wake-up.
                ProgressView(timerInterval: range, countsDown: true) {
                    EmptyView()
                } currentValueLabel: {
                    VStack(spacing: -1) {
                        Image(systemName: prayer.symbolName)
                            .font(.caption2)
                        Text(prayer.shortName)
                            .font(.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
                .progressViewStyle(.circular)
            } else if let prayer = entry.prayer, let prayerDate = entry.prayerDate {
                VStack(spacing: -1) {
                    Text(prayer.shortName)
                        .font(.caption2)
                    Text(prayerDate, style: .time)
                        .font(.caption2.monospacedDigit())
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            } else {
                Image(systemName: "moon.stars")
            }
        }
        .widgetAccentable()
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Rectangular

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let prayer = entry.prayer, let prayerDate = entry.prayerDate {
                HStack(spacing: 3) {
                    Image(systemName: prayer.symbolName)
                    Text(prayer.localizedNamazName)
                        .fontWeight(.semibold)
                    Spacer(minLength: 0)
                    Text(prayerDate, style: .time)
                        .monospacedDigit()
                }
                .font(.caption)
                .widgetAccentable()

                if let range = entry.countdownRange {
                    Text(timerInterval: range, countsDown: true)
                        .font(.caption2.monospacedDigit())
                } else {
                    Text(L10n.wNow).font(.caption2)
                }

                if !entry.cityName.isEmpty {
                    Text(entry.cityName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } else {
                Text(L10n.wTimes).font(.caption).fontWeight(.semibold)
                Text(L10n.wWaitingForPhone)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Inline

    private var inline: some View {
        // One line, one font, system-styled. Anything fancier is discarded.
        Group {
            if let prayer = entry.prayer, let prayerDate = entry.prayerDate {
                // Concatenated rather than interpolated: a `Text("\(…)")`
                // literal is a `LocalizedStringKey`, and the composed string
                // would be looked up as a catalogue key.
                Text(prayer.shortName) + Text(verbatim: " ") + Text(prayerDate, style: .time)
            } else {
                Text(L10n.wTimes)
            }
        }
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Corner

    private var corner: some View {
        Group {
            if let prayer = entry.prayer {
                Image(systemName: prayer.symbolName)
                    .font(.title3)
                    .widgetAccentable()
                    .widgetLabel {
                        if let range = entry.interval {
                            // The curved label around the corner doubles as a
                            // gauge when given a timer interval.
                            ProgressView(timerInterval: range, countsDown: true) {
                                Text(prayer.shortName)
                            }
                            .tint(MihrabColor.emerald)
                        } else {
                            Text(prayer.localizedNamazName)
                        }
                    }
            } else {
                Image(systemName: "moon.stars")
                    .widgetLabel { Text(L10n.wTimes) }
            }
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        guard let prayer = entry.prayer, let prayerDate = entry.prayerDate else {
            return L10n.wTimes
        }
        return "\(prayer.localizedNamazName) \(WatchScheduleBuilder.clock(prayerDate))"
    }
}
