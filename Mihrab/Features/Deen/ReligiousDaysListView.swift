import SwiftUI

/// Compact "what's coming" card for the Deen tab.
///
/// Rewritten onto `IslamicCalendar`: the old version read
/// `BundledContent.religiousDays`, which counted in whole Hijri days from an
/// approximate 354-day year *and pinned Regaib to 1 Recep*, which is only right
/// by coincidence. It also had no notion of the maghrib rule, so a kandil read
/// "1 day" on the very evening it had already begun.
struct ReligiousDaysListView: View {
    @Environment(PrayerTimesRepository.self) private var repository: PrayerTimesRepository?

    @State private var selected: Observance?
    @State private var showFullCalendar = false

    private var upcoming: [Observance] { Array(IslamicCalendar.nextOccurrences().prefix(5)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L10n.religiousDays)
                    .ornamentalCaps()
                Spacer()
                Button {
                    HapticsEngine.shared.light()
                    showFullCalendar = true
                } label: {
                    Text(L10n.calendarOpenFull)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MihrabColor.mint)
                        .frame(minHeight: MihrabSpace.hit, alignment: .trailing)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)

            if upcoming.isEmpty {
                MihrabEmptyState(
                    symbol: "moon.stars",
                    title: L10n.calendarNoUpcoming,
                    message: L10n.calendarNoUpcomingBody
                )
                .padding(.top, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(upcoming.enumerated()), id: \.element.id) { index, observance in
                        ObservanceRow(observance: observance) { selected = observance }
                            .padding(.horizontal, 4)
                        if index < upcoming.count - 1 { MihrabHairline() }
                    }
                }

                Text(L10n.calendarEveningRule)
                    .font(.caption2)
                    .foregroundStyle(MihrabColor.textTertiary)
                    .padding(.horizontal, 4)
                    .padding(.top, 6)
            }
        }
        .sheet(item: $selected) { observance in
            ObservanceDetailSheet(observance: observance, maghrib: maghrib(for: observance))
        }
        .sheet(isPresented: $showFullCalendar) {
            ReligiousCalendarView()
        }
    }

    /// Only ever a *real* maghrib the repository already holds — never guessed.
    private func maghrib(for observance: Observance) -> Date? {
        guard let repository else { return nil }
        let calendar = Calendar.current
        let target = calendar.startOfDay(for: observance.nightGregorianDay)
        for day in [repository.today, repository.tomorrow].compactMap({ $0 })
        where calendar.startOfDay(for: day.date) == target {
            return day.time(for: .maghrib)
        }
        return nil
    }
}
