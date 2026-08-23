import SwiftUI

/// The main screen: what is next, how long is left, and the rest of the day
/// under it. The Digital Crown scrolls the list — no extra wiring needed, a
/// `ScrollView` on watchOS is crown-driven by default.
struct WatchTimesView: View {

    @Environment(WatchAppModel.self) private var model

    var body: some View {
        NavigationStack {
            ScrollView {
                switch model.state {
                case .loading:
                    ProgressView()
                        .padding(.top, 40)

                case .needsLocation:
                    WatchNotice(symbol: "location.slash",
                                title: L10n.wNoLocation,
                                detail: model.isWaitingForPhone ? L10n.wWaitingForPhone : L10n.wNoLocationDetail)

                case .unavailableAtLatitude:
                    WatchNotice(symbol: "sun.horizon",
                                title: L10n.wTimes,
                                detail: L10n.wPolarUnavailable)

                case let .ready(schedule):
                    content(schedule)
                }
            }
            .navigationTitle(L10n.wTimes)
            .containerBackground(WatchPalette.timesGradient, for: .navigation)
        }
    }

    @ViewBuilder
    private func content(_ schedule: WatchSchedule) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            countdownCard(schedule)
            scheduleList(schedule)
            footer(schedule)
        }
        .padding(.horizontal, 2)
    }

    // MARK: - Countdown

    @ViewBuilder
    private func countdownCard(_ schedule: WatchSchedule) -> some View {
        if let next = schedule.next() {
            VStack(alignment: .leading, spacing: 2) {
                Text(next.prayer.countdownLabel)
                    .font(.caption2)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                // `Text(timerInterval:)` is ticked by the system: the countdown
                // stays live without the app running a timer, and it keeps
                // counting in Always-On without a single wake-up.
                CountdownText(to: next.date)
                    .font(.title2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(MihrabColor.sprout)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                HStack(spacing: 4) {
                    Image(systemName: next.prayer.symbolName)
                    Text(next.prayer.localizedNamazName)
                    Text(WatchScheduleBuilder.clock(next.date))
                        .monospacedDigit()
                        .foregroundStyle(MihrabColor.textSecondary)
                }
                .font(.caption)
                .foregroundStyle(MihrabColor.mint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(WatchPalette.card, in: .rect(cornerRadius: 14))
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: - Day list

    private func scheduleList(_ schedule: WatchSchedule) -> some View {
        let now = Date()
        let next = schedule.next()?.prayer
        return VStack(spacing: 0) {
            ForEach(schedule.rows, id: \.prayer) { row in
                HStack {
                    Image(systemName: row.prayer.symbolName)
                        .frame(width: 18)
                        .foregroundStyle(row.prayer == next ? MihrabColor.emerald : MihrabColor.textTertiary)
                    Text(row.prayer.localizedName)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 4)
                    Text(WatchScheduleBuilder.clock(row.date))
                        .monospacedDigit()
                        .foregroundStyle(row.date <= now ? MihrabColor.textTertiary : MihrabColor.textPrimary)
                }
                .font(.footnote)
                .fontWeight(row.prayer == next ? .semibold : .regular)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(row.prayer == next ? WatchPalette.highlight : Color.clear,
                            in: .rect(cornerRadius: 9))
                .accessibilityElement(children: .combine)
            }
        }
        .background(WatchPalette.card, in: .rect(cornerRadius: 14))
    }

    // MARK: - Footer

    @ViewBuilder
    private func footer(_ schedule: WatchSchedule) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(WatchScheduleBuilder.dayCaption(schedule.today.date))
            if !schedule.cityName.isEmpty {
                Text(schedule.cityName)
            }
            // Honest provenance: when the phone never sent a coordinate and the
            // watch fell back to its own GPS, the two can disagree while
            // travelling. Say which one produced these numbers.
            if schedule.usesWatchLocation {
                Label(L10n.wUsingWatchLocation, systemImage: "applewatch.radiowaves.left.and.right")
            }
        }
        .font(.caption2)
        .foregroundStyle(MihrabColor.textTertiary)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}

// MARK: - Shared bits

/// The one empty/failure presentation the watch uses, so "we cannot answer"
/// always looks the same and never resembles a loaded screen.
struct WatchNotice: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(MihrabColor.brass)
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(MihrabColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 6)
        .padding(.top, 16)
        .frame(maxWidth: .infinity)
    }
}

/// Watch-only surfaces. The phone's `MihrabBackdrop` is a Metal shader stack —
/// far too expensive for a wrist, and invisible under Always-On dimming anyway.
/// These are flat fills built from the same `MihrabColor` tokens.
enum WatchPalette {
    static let card = MihrabColor.moss.opacity(0.55)
    static let highlight = MihrabColor.emerald.opacity(0.22)

    static var timesGradient: LinearGradient {
        LinearGradient(colors: [MihrabColor.forest, MihrabColor.abyss],
                       startPoint: .top, endPoint: .bottom)
    }

    static var qiblaGradient: LinearGradient {
        LinearGradient(colors: [MihrabColor.moss, MihrabColor.abyss],
                       startPoint: .top, endPoint: .bottom)
    }

    static var dhikrGradient: LinearGradient {
        LinearGradient(colors: [MihrabColor.forest, MihrabColor.abyss],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
