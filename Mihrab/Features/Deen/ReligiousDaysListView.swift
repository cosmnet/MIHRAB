import SwiftUI

struct ReligiousDaysListView: View {
    @Environment(PrayerTimesRepository.self) private var repository
    @State private var selected: ReligiousDay?

    private var upcoming: [(day: ReligiousDay, daysUntil: Int)] {
        guard let hijri = repository.today?.hijriDate else { return [] }
        return BundledContent.upcomingReligiousDays(from: hijri)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.religiousDays)
                .ornamentalCaps()
                .padding(.horizontal, 4)
                .padding(.bottom, 4)

            if upcoming.isEmpty {
                MihrabEmptyState(
                    symbol: "moon.stars",
                    title: L10n.noUpcomingDays,
                    message: L10n.noUpcomingDaysBody
                )
                .padding(.top, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(upcoming.enumerated()), id: \.element.day.id) { index, item in
                        Button { selected = item.day } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "moon.stars.fill")
                                    .foregroundStyle(MihrabColor.brass)
                                    .symbolRenderingMode(.hierarchical)
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.day.localizedName)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(MihrabColor.textPrimary)
                                    Text("\(item.day.hijriDay) \(HijriDate.localizedMonthNames[max(0, min(item.day.hijriMonth - 1, 11))])")
                                        .font(.caption)
                                        .foregroundStyle(MihrabColor.textTertiary)
                                }

                                Spacer()

                                Text(item.daysUntil == 0 ? L10n.today : L10n.daysShort(item.daysUntil))
                                    .font(.caption.weight(.bold).monospacedDigit())
                                    .foregroundStyle(item.daysUntil < 7 ? .white : MihrabColor.textSecondary)
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background {
                                        if item.daysUntil < 7 {
                                            Capsule().fill(MihrabColor.brass)
                                        }
                                    }
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 4)
                            .frame(minHeight: MihrabSpace.hit)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < upcoming.count - 1 {
                            MihrabHairline()
                        }
                    }
                }
            }
        }
        .sheet(item: $selected) { day in
            ReligiousDayInfoSheet(day: day)
        }
    }
}

struct ReligiousDayInfoSheet: View {
    let day: ReligiousDay
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Image(systemName: "moon.stars.fill")
                            .font(.largeTitle)
                            .foregroundStyle(MihrabColor.brass)
                        Text(day.localizedName)
                            .font(.title.bold())
                        if !Locale.mihrabIsArabic {
                            Text(day.nameAr)
                                .font(MihrabFont.arabic(28))
                                .foregroundStyle(MihrabColor.brass)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .environment(\.layoutDirection, .rightToLeft)
                        }
                        if day.nameEn != day.localizedName {
                            Text(day.nameEn)
                                .font(.title3)
                                .foregroundStyle(MihrabColor.textSecondary)
                        } else {
                            Text(day.nameTr)
                                .font(.title3)
                                .foregroundStyle(MihrabColor.textSecondary)
                        }
                        Text(day.localizedDescription)
                            .font(MihrabFont.quote(18))
                            .foregroundStyle(MihrabColor.textPrimary)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollEdgeEffectStyle(.soft, for: .top)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.done) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(.ultraThinMaterial)
    }
}
