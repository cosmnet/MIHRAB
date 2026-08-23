import CoreLocation
import SwiftUI

/// The three kerahat windows, with the honest note about where each boundary
/// came from. Collapsed by default — this is reference material, not the thing
/// people opened the tab for.
struct MakruhTimesCard: View {
    let day: DayPrayerTimes
    let coordinate: CLLocationCoordinate2D
    /// Only "now" on today's page; a live highlight on a past day is a lie.
    var highlightsNow: Bool

    @State private var windows: [DevotionalWindows.Window] = []
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L10n.tmxMakruhCaps).ornamentalCaps()
                Spacer()
                Button {
                    withAnimation(MihrabMotion.snappyAnimation) { expanded.toggle() }
                } label: {
                    Image(systemName: expanded ? "info.circle.fill" : "info.circle")
                        .font(.footnote)
                        .foregroundStyle(MihrabColor.textSecondary)
                        .frame(width: MihrabSpace.hit, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(L10n.tmxMakruhExplain))
            }

            if windows.isEmpty {
                Text(L10n.tmxMakruhUnavailable)
                    .font(.caption)
                    .foregroundStyle(MihrabColor.textTertiary)
            } else {
                ForEach(windows) { window in
                    row(window)
                }
            }

            if expanded {
                Text(L10n.tmxMakruhExplain)
                    .font(.caption)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .offset(y: -4)))
            }
        }
        .padding(14)
        .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
        .task(id: taskKey) { recompute() }
    }

    private var taskKey: String {
        "\(day.date.timeIntervalSince1970)-\(coordinate.latitude)-\(coordinate.longitude)"
    }

    /// Bisection against the real altitude curve is cheap but not free — keep
    /// it out of `body`, which a `TimelineView` elsewhere on the screen can
    /// re-evaluate every second.
    private func recompute() {
        windows = DevotionalWindows.makruhWindows(for: day, coordinate: coordinate)
    }

    @ViewBuilder
    private func row(_ window: DevotionalWindows.Window) -> some View {
        let active = highlightsNow && window.contains(Date())
        HStack(spacing: 10) {
            Image(systemName: window.kind.symbolName)
                .font(.footnote)
                .foregroundStyle(active ? MihrabColor.brass : MihrabColor.textTertiary)
                .frame(width: 22)

            Text(window.kind.localizedName)
                .font(.footnote.weight(active ? .semibold : .regular))
                .foregroundStyle(active ? MihrabColor.brass : MihrabColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 6)

            Text("\(window.start.formatted(date: .omitted, time: .shortened)) – \(window.end.formatted(date: .omitted, time: .shortened))")
                .font(.footnote.monospacedDigit())
                .foregroundStyle(active ? MihrabColor.brass : MihrabColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(minHeight: 32)
        .accessibilityElement(children: .combine)
    }
}

/// Middle and last third of the night — the teheccüd rows.
struct NightDivisionsCard: View {
    let day: DayPrayerTimes
    let tomorrow: DayPrayerTimes?

    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L10n.tmxNightCaps).ornamentalCaps()
                Spacer()
                Button {
                    withAnimation(MihrabMotion.snappyAnimation) { expanded.toggle() }
                } label: {
                    Image(systemName: expanded ? "info.circle.fill" : "info.circle")
                        .font(.footnote)
                        .foregroundStyle(MihrabColor.textSecondary)
                        .frame(width: MihrabSpace.hit, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(L10n.tmxNightExplain))
            }

            if let divisions = DevotionalWindows.nightDivisions(day: day, tomorrow: tomorrow) {
                row(title: L10n.tmxMidnight, date: divisions.middleOfTheNight, symbol: "moon")
                row(title: L10n.tmxLastThird, date: divisions.lastThirdOfTheNight, symbol: "moon.stars")
            } else {
                Text(L10n.tmxNightNeedsTomorrow)
                    .font(.caption)
                    .foregroundStyle(MihrabColor.textTertiary)
            }

            if expanded {
                Text(L10n.tmxNightExplain)
                    .font(.caption)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .offset(y: -4)))
            }
        }
        .padding(14)
        .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
    }

    private func row(title: String, date: Date, symbol: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.footnote)
                .foregroundStyle(MihrabColor.textTertiary)
                .frame(width: 22)
            Text(title)
                .font(.footnote)
                .foregroundStyle(MihrabColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 6)
            Text(date, format: .dateTime.hour().minute())
                .font(.footnote.monospacedDigit())
                .foregroundStyle(MihrabColor.mint)
        }
        .frame(minHeight: 32)
        .accessibilityElement(children: .combine)
    }
}

/// "Computed on this device" / "Last update: …" — the two facts that stop an
/// offline day from looking like a broken day.
struct TimesFreshnessBadge: View {
    let isOffline: Bool
    let lastRefresh: Date?

    @State private var showExplain = false

    var body: some View {
        Button {
            withAnimation(MihrabMotion.snappyAnimation) { showExplain.toggle() }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: isOffline ? "iphone.gen3" : "antenna.radiowaves.left.and.right")
                        .font(.caption2)
                        .foregroundStyle(isOffline ? MihrabColor.mint : MihrabColor.textSecondary)
                    Text(isOffline ? L10n.tmxComputedOnDevice : L10n.tmxFromNetwork)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(MihrabColor.textSecondary)
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textTertiary)
                    Text(lastRefresh.map(L10n.tmxLastUpdated) ?? L10n.tmxNeverUpdated)
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(minHeight: 32)

                if showExplain {
                    Text(L10n.tmxOfflineExplain)
                        .font(.caption2)
                        .foregroundStyle(MihrabColor.textTertiary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text([isOffline ? L10n.tmxComputedOnDevice : L10n.tmxFromNetwork,
                                  lastRefresh.map(L10n.tmxLastUpdated) ?? L10n.tmxNeverUpdated]
            .joined(separator: ", ")))
        .accessibilityHint(Text(L10n.tmxOfflineExplain))
    }
}
