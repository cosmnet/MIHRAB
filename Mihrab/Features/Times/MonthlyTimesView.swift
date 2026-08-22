import SwiftUI

/// Full-month glass table of prayer times; today highlighted, Ramadan tinted.
struct MonthlyTimesView: View {
    let anchorDate: Date

    @Environment(PrayerTimesRepository.self) private var repository
    @Environment(Theme.self) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var days: [DayPrayerTimes] = []
    @State private var isLoading = true

    private let columns: [Prayer] = [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha]

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground(ramadanMode: theme.isRamadanMode)

                Group {
                    if isLoading {
                        ProgressView()
                            .tint(MihrabColor.mint)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if days.isEmpty {
                        MihrabEmptyState(
                            symbol: "calendar.badge.exclamationmark",
                            title: L10n.noTimesMonth,
                            message: L10n.noTimesMonthBody
                        )
                        .padding(24)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 6) {
                                headerRow
                                ForEach(days) { day in
                                    monthRow(day)
                                }
                            }
                            .padding()
                        }
                        .scrollEdgeEffectStyle(.soft, for: .top)
                    }
                }
            }
            .navigationTitle(anchorDate.formatted(.dateTime.month(.wide).year()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.done) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: ShareImage(image: renderShareImage()), preview: SharePreview("Prayer Times", image: Image(uiImage: renderShareImage()))) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(days.isEmpty)
                }
            }
        }
        .presentationBackground(.ultraThinMaterial)
        .task { await load() }
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text(L10n.day).frame(width: 44, alignment: .leading)
            ForEach(columns) { prayer in
                Text(prayer.shortName)
                    .frame(maxWidth: .infinity)
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(MihrabColor.brass)
        .padding(.vertical, 8)
    }

    private func monthRow(_ day: DayPrayerTimes) -> some View {
        let isToday = Calendar.current.isDateInToday(day.date)
        let isRamadan = day.hijriDate?.isRamadan ?? false
        return HStack(spacing: 0) {
            Text(day.date, format: .dateTime.day())
                .frame(width: 44, alignment: .leading)
            ForEach(columns) { prayer in
                Text(day.time(for: prayer)?.formatted(date: .omitted, time: .shortened) ?? "–")
                    .frame(maxWidth: .infinity)
            }
        }
        .font(.system(size: 12, weight: isToday ? .bold : .regular, design: .rounded).monospacedDigit())
        .foregroundStyle(isToday ? MihrabColor.textPrimary : MihrabColor.textSecondary)
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background {
            if isToday {
                RoundedRectangle(cornerRadius: 12).fill(theme.accent.opacity(0.25))
            } else if isRamadan {
                RoundedRectangle(cornerRadius: 12).fill(MihrabColor.ramadanViolet.opacity(0.35))
            }
        }
    }

    @MainActor
    private func renderShareImage() -> UIImage {
        let renderer = ImageRenderer(content:
            VStack(spacing: 12) {
                Text("MIHRAB")
                    .font(MihrabFont.ornamental)
                    .tracking(3)
                    .foregroundStyle(MihrabColor.brass)
                Text(anchorDate.formatted(.dateTime.month(.wide).year()))
                    .font(.title.bold())
                    .foregroundStyle(MihrabColor.textPrimary)
                VStack(spacing: 4) {
                    headerRow
                    ForEach(days) { monthRow($0) }
                }
            }
            .padding(32)
            .frame(width: 800)
            .background(MihrabColor.abyss)
        )
        renderer.scale = 2
        return renderer.uiImage ?? UIImage()
    }

    private func load() async {
        isLoading = true
        days = await repository.month(containing: anchorDate)
        isLoading = false
    }
}
