import SwiftUI

/// Full-month glass table of prayer times; today highlighted, Ramadan tinted.
struct MonthlyTimesView: View {
    let anchorDate: Date

    @Environment(PrayerTimesRepository.self) private var repository
    @Environment(LocationManager.self) private var locationManager
    @Environment(AppSettings.self) private var settings
    @Environment(Theme.self) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var days: [DayPrayerTimes] = []
    @State private var isLoading = true
    /// Rendered once when the month lands. Building it inside the `ShareLink`
    /// initialiser rasterised the entire month twice on *every* layout pass —
    /// once for the item and once for the preview.
    @State private var shareCard: ShareImage?

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
            .navigationTitle(anchorDate.formatted(.dateTime.month(.wide).year().locale(L10n.appLocale)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.done) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let shareCard {
                        ShareLink(
                            item: shareCard,
                            preview: SharePreview(L10n.tmxImsakiyeTitle,
                                                  image: Image(uiImage: shareCard.image))
                        ) {
                            Label(L10n.tmxShareImsakiye, systemImage: "square.and.arrow.up")
                                .labelStyle(.iconOnly)
                        }
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(MihrabColor.textSecondary)
                            .accessibilityLabel(Text(L10n.tmxPreparingShare))
                    }
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
        let isFriday = Calendar.current.component(.weekday, from: day.date) == 6
        let sacred = day.hijriDate.flatMap(SacredDayLookup.day(for:))

        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 0) {
                Text(day.date, format: .dateTime.day())
                    .frame(width: 44, alignment: .leading)
                    .foregroundStyle(isFriday ? MihrabColor.brass : MihrabColor.textSecondary)
                ForEach(columns) { prayer in
                    Text(day.time(for: prayer)?.formatted(date: .omitted, time: .shortened) ?? "–")
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .font(.footnote.weight(isToday || isFriday ? .bold : .regular).monospacedDigit())
            .foregroundStyle(isToday ? MihrabColor.textPrimary : MihrabColor.textSecondary)

            if let sacred {
                Label(sacred.localizedName, systemImage: "moon.stars.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(MihrabColor.brass)
                    .padding(.leading, 44)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .frame(minHeight: MihrabSpace.hit)
        .background {
            if isToday {
                RoundedRectangle(cornerRadius: 12).fill(theme.accent.opacity(0.25))
            } else if sacred != nil {
                RoundedRectangle(cornerRadius: 12).fill(MihrabColor.brass.opacity(0.16))
            } else if isRamadan {
                RoundedRectangle(cornerRadius: 12).fill(MihrabColor.ramadanViolet.opacity(0.35))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(rowAccessibility(day, sacred: sacred, isFriday: isFriday)))
    }

    private func rowAccessibility(_ day: DayPrayerTimes,
                                  sacred: ReligiousDay?,
                                  isFriday: Bool) -> String {
        var parts = [day.date.formatted(.dateTime.day().month(.wide).locale(L10n.appLocale))]
        if isFriday { parts.append(L10n.tmxFridayBadge) }
        if let sacred { parts.append(sacred.localizedName) }
        for prayer in columns {
            if let time = day.time(for: prayer) {
                parts.append("\(prayer.localizedName) \(time.formatted(date: .omitted, time: .shortened))")
            }
        }
        return parts.joined(separator: ", ")
    }

    @MainActor
    private func load() async {
        isLoading = true
        days = await repository.month(containing: anchorDate)
        isLoading = false
        shareCard = ImsakiyeRenderer.render(
            days: days,
            monthDate: anchorDate,
            cityName: locationManager.effectiveCityName,
            sourceName: PrayerSourcePreferences.shared.source.localizedName,
            methodName: settings.calculationMethod.localizedName
        ).map(ShareImage.init(image:))
    }
}
