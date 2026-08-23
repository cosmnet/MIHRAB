import SwiftUI
import WidgetKit

/// Today's dhikr tally as a complication — one tap from the wrist to the
/// counter.
struct DhikrComplication: Widget {

    static let kind = "MihrabDhikrComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: DhikrProvider()) { entry in
            DhikrComplicationView(entry: entry)
                .containerBackground(Color.clear, for: .widget)
        }
        .configurationDisplayName(L10n.wComplicationDhikrName)
        .description(L10n.wComplicationDhikrDescription)
        .supportedFamilies([.accessoryCircular, .accessoryInline, .accessoryCorner])
    }
}

struct DhikrComplicationView: View {
    @Environment(\.widgetFamily) private var family
    /// Always-On Display. `true` means the wrist is down and the screen is
    /// dimmed: filled shapes bloom and burn power, so they become outlines.
    /// This is the whole reason the environment value exists — an
    /// Always-On complication that looks identical wrist-down is doing it wrong.
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    let entry: DhikrEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text(entry.phrase.transliteration) + Text(verbatim: " \(entry.total)")
        case .accessoryCorner:
            Image(systemName: symbol)
                .font(.title3)
                .widgetAccentable()
                .widgetLabel { Text("\(entry.total)") }
        default:
            circular
        }
    }

    private var symbol: String {
        isLuminanceReduced ? "circle.hexagonpath" : "circle.hexagonpath.fill"
    }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            // The two gauge styles are different concrete types, so this is an
            // `if`/`else` rather than a ternary on `.gaugeStyle(_:)`.
            if isLuminanceReduced {
                gauge.gaugeStyle(.accessoryCircular)
            } else {
                gauge.gaugeStyle(.accessoryCircularCapacity)
            }
        }
        .widgetAccentable()
        .accessibilityLabel(L10n.wDhikr)
        .accessibilityValue(L10n.wDhikrTodayTotal(entry.total))
    }

    private var gauge: some View {
        Gauge(value: progress) {
            Image(systemName: symbol)
        } currentValueLabel: {
            Text("\(entry.total)")
                .font(.caption.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }

    private var progress: Double {
        guard entry.phrase.target > 0 else { return 0 }
        return min(1, Double(entry.total) / Double(entry.phrase.target))
    }
}
