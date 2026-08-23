import SwiftUI
import WidgetKit

/// Iftar, then suhoor, then iftar again — the only two moments that matter in
/// Ramadan, on a surface the user never has to open.
struct RamadanCountdownWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RamadanCountdownWidget", provider: PrayerTimelineProvider()) { entry in
            RamadanCountdownView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [MihrabColor.ramadanViolet, MihrabColor.abyss],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .configurationDisplayName("Iftar & Suhoor")
        .description("Countdown to iftar, then to the end of suhoor.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}

struct RamadanCountdownView: View {
    let entry: PrayerEntry

    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode
    @ScaledMetric(relativeTo: .title) private var clockSize: CGFloat = 26

    private var edge: FastEdge? { FastEdge.next(at: entry.date, snapshot: entry.snapshot) }

    private var accent: Color {
        switch renderingMode {
        case .fullColor: MihrabColor.ramadanGold
        default: MihrabColor.textPrimary
        }
    }

    var body: some View {
        Group {
            if let edge {
                switch family {
                case .accessoryCircular: circularView(edge)
                case .accessoryRectangular: rectangularView(edge)
                case .systemMedium: mediumView(edge)
                default: smallView(edge)
                }
            } else {
                Text(L10n.intErrNoSchedule)
                    .font(.caption2)
                    .foregroundStyle(MihrabColor.textSecondary)
            }
        }
        .widgetURL(MihrabDeepLink.url(for: .today))
    }

    private func smallView(_ edge: FastEdge) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(edge.caption, systemImage: edge.symbol)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(accent)
                .widgetAccentable()
            CountdownText(from: entry.date, to: edge.date)
                .font(.system(size: clockSize, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(MihrabColor.textPrimary)
            Text(MihrabIntentData.clock(edge.date))
                .font(.caption.monospacedDigit())
                .foregroundStyle(MihrabColor.textSecondary)
            Spacer(minLength: 0)
            if let hijri = entry.snapshot?.day(containing: entry.date)?.hijriDate {
                Text(hijri.formatted)
                    .font(.caption2)
                    .foregroundStyle(MihrabColor.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func mediumView(_ edge: FastEdge) -> some View {
        HStack(spacing: 16) {
            smallView(edge)
            Divider().overlay(MihrabColor.textTertiary.opacity(0.3))
            VStack(alignment: .leading, spacing: 6) {
                tile(L10n.suhoorEndsCaps, entry.snapshot?.day(containing: entry.date)?.time(for: .fajr))
                tile(L10n.iftarCaps, entry.snapshot?.day(containing: entry.date)?.time(for: .maghrib))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func tile(_ title: String, _ date: Date?) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(MihrabColor.textSecondary)
            Text(date.map { MihrabIntentData.clock($0) } ?? "—")
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(accent)
        }
        .accessibilityElement(children: .combine)
    }

    private func circularView(_ edge: FastEdge) -> some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: edge.symbol)
                    .font(.caption2)
                CountdownText(from: entry.date, to: edge.date)
                    .font(.system(.caption, design: .rounded).bold().monospacedDigit())
            }
        }
    }

    private func rectangularView(_ edge: FastEdge) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(edge.caption, systemImage: edge.symbol)
                .font(.caption2)
                .widgetAccentable()
            HStack {
                CountdownText(from: entry.date, to: edge.date)
                    .font(.headline.monospacedDigit())
                Spacer()
                Text(MihrabIntentData.clock(edge.date))
                    .font(.caption.monospacedDigit())
            }
        }
    }
}
