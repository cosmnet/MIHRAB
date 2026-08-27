import SwiftUI

/// The month, in place. Same data as `MonthlyTimesView`, but living inside the
/// Times tab so switching Day ⇄ Month never costs a modal presentation.
struct InlineMonthTable: View {
    let anchorDate: Date
    /// Opens the full, shareable month sheet.
    var onOpenFull: () -> Void = {}

    @Environment(PrayerTimesRepository.self) private var repository
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var days: [DayPrayerTimes] = []
    @State private var isLoading = true

    private let columns: [Prayer] = [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha]

    var body: some View {
        VStack(spacing: 12) {
            header

            if isLoading {
                loadingRows
            } else if days.isEmpty {
                MihrabEmptyState(
                    symbol: "calendar.badge.exclamationmark",
                    title: L10n.noTimesMonth,
                    message: L10n.noTimesMonthBody
                )
            } else {
                table
            }
        }
        .task(id: monthKey) { await load() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(anchorDate.formatted(.dateTime.month(.wide).year().locale(L10n.appLocale)))
                .font(.headline)
                .foregroundStyle(MihrabColor.textPrimary)
            Spacer()
            Button(action: onOpenFull) {
                Label(L10n.tmzOpenFullMonth, systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.accent)
                    .frame(minHeight: MihrabSpace.hit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Table

    private var table: some View {
        VStack(spacing: 4) {
            headerRow
            MihrabHairline()
            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                row(day)
                    .cardEntrance(
                        index: min(index, 12),
                        appeared: !isLoading,
                        reduceMotion: reduceMotion
                    )
            }
        }
        .padding(12)
        .mihrabSolidCard(cornerRadius: MihrabSpace.cardRadius)
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text(L10n.day)
                .frame(width: 30, alignment: .leading)
            ForEach(columns) { prayer in
                Text(prayer.shortName)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(MihrabColor.brass)
        .padding(.vertical, 4)
    }

    private func row(_ day: DayPrayerTimes) -> some View {
        let isToday = Calendar.current.isDateInToday(day.date)
        let isRamadan = day.hijriDate?.isRamadan ?? false
        let isFriday = Calendar.current.component(.weekday, from: day.date) == 6
        let sacred = day.hijriDate.flatMap(SacredDayLookup.day(for:))

        return VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 0) {
                Text(day.date, format: .dateTime.day())
                    .frame(width: 30, alignment: .leading)
                    .foregroundStyle(isFriday ? MihrabColor.brass : MihrabColor.textSecondary)
                ForEach(columns) { prayer in
                    Text(day.time(for: prayer)?.formatted(date: .omitted, time: .shortened) ?? "–")
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .font(.caption.weight(isToday || isFriday ? .bold : .regular).monospacedDigit())
            .foregroundStyle(isToday ? MihrabColor.textPrimary : MihrabColor.textSecondary)

            // Kandil / religious day, named rather than reduced to a dot —
            // this table is the one place people look for them.
            if let sacred {
                Label(sacred.localizedName, systemImage: "moon.stars.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(MihrabColor.brass)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.leading, 30)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background {
            if isToday {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.accent.opacity(0.28))
            } else if sacred != nil {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(MihrabColor.brass.opacity(0.16))
            } else if isRamadan {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(MihrabColor.ramadanViolet.opacity(0.35))
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Loading

    private var loadingRows: some View {
        VStack(spacing: 6) {
            ForEach(0..<10, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(MihrabColor.moss.opacity(0.55))
                    .frame(height: 22)
            }
        }
        .padding(12)
        .mihrabSolidCard(cornerRadius: MihrabSpace.cardRadius)
        .accessibilityElement()
        .accessibilityLabel(Text(L10n.tmzLoadingMonth))
    }

    // MARK: - Data

    /// Re-fetch only when the *month* changes, not on every day nudge.
    private var monthKey: String {
        let comps = Calendar.current.dateComponents([.year, .month], from: anchorDate)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)"
    }

    private func load() async {
        isLoading = true
        let fetched = await repository.month(containing: anchorDate)
        days = fetched
        withAnimation(reduceMotion ? nil : MihrabMotion.standardAnimation) {
            isLoading = false
        }
    }
}
