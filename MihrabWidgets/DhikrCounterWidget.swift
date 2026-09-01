import AppIntents
import SwiftUI
import WidgetKit

/// The interactive one: the big disc is a `Button(intent:)` that counts in
/// place, and only the small "open" affordance is a `Link` — Apple is explicit
/// that a control which merely opens the app must not be a Button.
struct DhikrCounterWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DhikrCounterWidget", provider: DhikrCounterProvider()) { entry in
            DhikrCounterWidgetView(entry: entry)
                // StandBy and CarPlay strip this background; everything the user
                // must read has to live *inside* the container, not behind it.
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [MihrabColor.forest, MihrabColor.abyss],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .configurationDisplayName("Dhikr Counter")
        .description("Tap to count without opening Revak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DhikrCounterEntry: TimelineEntry {
    let date: Date
    let count: Int
    let phrase: String
}

struct DhikrCounterProvider: TimelineProvider {

    private func entry(at date: Date = Date()) -> DhikrCounterEntry {
        let id = SharedDhikrCounter.phraseID
        let name = SharedDhikrDirectory.entries.first { $0.id == id }?.name ?? id
        return DhikrCounterEntry(date: date, count: SharedDhikrCounter.todayCount, phrase: name)
    }

    func placeholder(in context: Context) -> DhikrCounterEntry {
        DhikrCounterEntry(date: Date(), count: 33, phrase: "Subhanallah")
    }

    func getSnapshot(in context: Context, completion: @escaping (DhikrCounterEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DhikrCounterEntry>) -> Void) {
        // The count only changes when someone taps, and a tap reloads this kind
        // directly. Midnight is the one scheduled reason to redraw.
        let midnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        )
        completion(Timeline(entries: [entry()], policy: midnight.map { .after($0) } ?? .atEnd))
    }
}

struct DhikrCounterWidgetView: View {
    let entry: DhikrCounterEntry

    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode
    @ScaledMetric(relativeTo: .largeTitle) private var countSize: CGFloat = 34

    /// `WidgetRenderingMode` is a **struct**, not an enum — a `switch` over it
    /// needs a `default:` or the file will not compile on a future SDK.
    private var countColor: Color {
        switch renderingMode {
        case .fullColor: MihrabColor.mint
        case .accented: MihrabColor.textPrimary
        case .vibrant: MihrabColor.textPrimary
        default: MihrabColor.textPrimary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            counterButton

            if family != .systemSmall {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.phrase)
                        .font(.headline)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Text(L10n.intDhikrTodayCaption)
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textSecondary)
                    Spacer(minLength: 0)
                    Link(destination: MihrabDeepLink.url(for: .dhikr) ?? URL(string: "mihrab://dhikr")!) {
                        Label(L10n.wgtOpenAppHint, systemImage: "arrow.up.forward.app")
                            .font(.caption2)
                    }
                    .accessibilityLabel(L10n.wgtOpenAppHint)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        // Small family has no room for a separate "open" affordance, so the
        // whole tile links; the button still wins on its own hit area.
        .widgetURL(family == .systemSmall ? MihrabDeepLink.url(for: .dhikr) : nil)
    }

    private var counterButton: some View {
        Button(intent: AddDhikrIntent(amount: 1)) {
            VStack(spacing: 2) {
                Text("\(entry.count)")
                    .font(.system(size: countSize, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(countColor)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Image(systemName: "plus.circle.fill")
                    .widgetAccentedRenderingMode(.desaturated)
                    .font(.caption)
                    .foregroundStyle(MihrabColor.brass)
            }
            .frame(minWidth: 88, minHeight: 88)
            .background {
                Circle()
                    .fill(MihrabColor.moss.opacity(renderingMode == .fullColor ? 0.9 : 0.35))
            }
        }
        .buttonStyle(.plain)
        // Tint-mode Lock Screen / StandBy: this is the element that should stay
        // solid when everything else is washed out.
        .widgetAccentable()
        .accessibilityLabel(L10n.intAddDhikrTitle)
        .accessibilityValue("\(entry.count)")
    }
}
