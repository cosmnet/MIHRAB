import AppIntents
import SwiftUI
import WidgetKit

/// Lets the user pick *which* city a widget shows — the one configuration
/// question a prayer-times widget actually has.
struct SelectCityIntent: WidgetConfigurationIntent {

    static var title: LocalizedStringResource { "Prayer Times by City" }

    static var description: IntentDescription {
        IntentDescription("Pick which city's prayer times this widget shows.")
    }

    @Parameter(title: "City")
    var city: WidgetCityEntity?

    init() {}

    init(city: WidgetCityEntity?) {
        self.city = city
    }
}

struct CityPrayerEntry: TimelineEntry {
    let date: Date
    let city: WidgetCityEntity
    /// `nil` when nothing is cached for this city — shown honestly, never faked.
    let day: DayPrayerTimes?
    let tomorrow: DayPrayerTimes?

    var next: (prayer: Prayer, date: Date)? {
        day?.nextPrayer(after: date, tomorrow: tomorrow)
    }
}

struct CityPrayerProvider: AppIntentTimelineProvider {

    typealias Entry = CityPrayerEntry
    typealias Intent = SelectCityIntent

    func placeholder(in context: Context) -> CityPrayerEntry {
        CityPrayerEntry(date: Date(), city: .current, day: nil, tomorrow: nil)
    }

    func snapshot(for configuration: SelectCityIntent, in context: Context) async -> CityPrayerEntry {
        entry(at: Date(), for: configuration)
    }

    func timeline(for configuration: SelectCityIntent, in context: Context) async -> Timeline<CityPrayerEntry> {
        let now = Date()
        var entries: [CityPrayerEntry] = []
        for minutes in stride(from: 0, through: 60, by: 15) {
            guard let date = Calendar.current.date(byAdding: .minute, value: minutes, to: now) else { continue }
            entries.append(entry(at: date, for: configuration))
        }
        let first = entries.first
        let reload = first?.next?.date ?? now.addingTimeInterval(3600)
        return Timeline(entries: entries, policy: .after(reload))
    }

    private func entry(at date: Date, for configuration: SelectCityIntent) -> CityPrayerEntry {
        let city = configuration.city ?? .current
        guard let snapshot = SharedPrayerCache.load(), matches(city, snapshot) else {
            return CityPrayerEntry(date: date, city: city, day: nil, tomorrow: nil)
        }
        let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: date)
        return CityPrayerEntry(
            date: date,
            city: city,
            day: snapshot.day(containing: date),
            tomorrow: tomorrowDate.flatMap { snapshot.day(containing: $0) }
        )
    }

    /// The App Group holds one calculated schedule at a time. A city the cache
    /// was not calculated for gets an empty state rather than someone else's
    /// times — being wrong about a prayer time is worse than being blank.
    private func matches(_ city: WidgetCityEntity, _ snapshot: SharedPrayerSnapshot) -> Bool {
        if city.isCurrentLocation { return true }
        if city.name.caseInsensitiveCompare(snapshot.cityName) == .orderedSame { return true }
        return abs(city.latitude - snapshot.latitude) < 0.1 && abs(city.longitude - snapshot.longitude) < 0.1
    }
}

struct CityPrayerWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "CityPrayerWidget",
            intent: SelectCityIntent.self,
            provider: CityPrayerProvider()
        ) { entry in
            CityPrayerWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [MihrabColor.forest, MihrabColor.abyss],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Prayer Times by City")
        .description("Pick which city's prayer times this widget shows.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct CityPrayerWidgetView: View {
    let entry: CityPrayerEntry

    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

    private var accent: Color {
        switch renderingMode {
        case .fullColor: MihrabColor.mint
        default: MihrabColor.textPrimary
        }
    }

    var body: some View {
        Group {
            if entry.day == nil {
                emptyState
            } else {
                switch family {
                case .accessoryRectangular: accessoryView
                case .systemMedium: mediumView
                default: smallView
                }
            }
        }
        .widgetURL(MihrabDeepLink.url(for: .times))
    }

    private var cityLabel: some View {
        Text(entry.city.isCurrentLocation ? (MihrabIntentData.cityName ?? entry.city.name) : entry.city.name)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(MihrabColor.brass)
            .lineLimit(1)
            .widgetAccentable()
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            cityLabel
            Text(L10n.intErrNoSchedule)
                .font(.caption2)
                .foregroundStyle(MihrabColor.textSecondary)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 4) {
            cityLabel
            if let next = entry.next {
                Text(next.prayer.localizedNamazName)
                    .font(.subheadline.weight(.semibold))
                Text(next.date, format: .dateTime.hour().minute())
                    .font(.title.bold().monospacedDigit())
                    .foregroundStyle(accent)
                if let range = SafeCountdown.range(from: entry.date, to: next.date) {
                    Text(timerInterval: range, countsDown: true)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(MihrabColor.textSecondary)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mediumView: some View {
        HStack(spacing: 14) {
            smallView
            Divider().overlay(MihrabColor.textTertiary.opacity(0.3))
            VStack(spacing: 3) {
                ForEach(Prayer.allCases) { prayer in
                    HStack {
                        Text(prayer.localizedName)
                            .font(.caption2)
                        Spacer()
                        Text(entry.day?.time(for: prayer).map { MihrabIntentData.clock($0) } ?? "—")
                            .font(.caption2.monospacedDigit())
                    }
                    .foregroundStyle(entry.next?.prayer == prayer ? accent : MihrabColor.textSecondary)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var accessoryView: some View {
        VStack(alignment: .leading, spacing: 2) {
            cityLabel
            if let next = entry.next {
                Text("\(next.prayer.localizedNamazName) \(next.date, format: .dateTime.hour().minute())")
                    .font(.headline.monospacedDigit())
                if let range = SafeCountdown.range(from: entry.date, to: next.date) {
                    Text(timerInterval: range, countsDown: true)
                        .font(.caption.monospacedDigit())
                }
            }
        }
    }
}
