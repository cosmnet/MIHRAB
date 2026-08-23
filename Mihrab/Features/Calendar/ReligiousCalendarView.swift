import SwiftUI

/// Full religious calendar: what is coming, the whole Hijri year, and the
/// voluntary fasts. Presented as a sheet from Deen and from Settings.
struct ReligiousCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PrayerTimesRepository.self) private var repository: PrayerTimesRepository?

    @State private var selected: Observance?
    @State private var hijriYear = IslamicCalendar.hijriYear()

    private var upcoming: [Observance] { IslamicCalendar.nextOccurrences() }
    private var yearList: [Observance] { IslamicCalendar.observances(hijriYear: hijriYear) }
    private var fasts: [VoluntaryFastDay] { IslamicCalendar.upcomingVoluntaryFasts(limit: 8) }

    var body: some View {
        NavigationStack {
            ZStack {
                MihrabBackdrop(surface: .deen)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: MihrabSpace.unit * 2.5) {
                        threeMonthsBanner
                        section(L10n.calendarUpcoming) {
                            observanceList(Array(upcoming.prefix(6)))
                        }
                        section(L10n.calendarThisYear) {
                            yearPicker
                            observanceList(yearList)
                        }
                        section(L10n.calendarFasts) {
                            fastList
                        }
                        footnotes
                    }
                    .padding(.horizontal, MihrabSpace.unit * 2)
                    .padding(.vertical, MihrabSpace.unit * 2)
                }
                .scrollEdgeEffectStyle(.soft, for: .top)
            }
            .navigationTitle(L10n.calendarTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.done) { dismiss() }
                }
            }
            .sheet(item: $selected) { observance in
                ObservanceDetailSheet(observance: observance, maghrib: maghrib(for: observance))
            }
        }
    }

    // MARK: - Maghrib lookup

    /// Real maghrib for the evening the observance opens, when the repository
    /// happens to hold that day. We never *estimate* one — `Observance.start`
    /// falls back to a labelled placeholder instead.
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

    // MARK: - Pieces

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: MihrabSpace.unit) {
            Text(title)
                .ornamentalCaps()
                .padding(.horizontal, 4)
            content()
        }
    }

    @ViewBuilder
    private var threeMonthsBanner: some View {
        if let interval = IslamicCalendar.threeMonthsInterval(hijriYear: hijriYear) {
            let isNow = IslamicCalendar.isInThreeMonths()
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "moon.circle.fill")
                        .foregroundStyle(MihrabColor.brass)
                    Text(L10n.calendarThreeMonths)
                        .font(.headline)
                        .foregroundStyle(MihrabColor.textPrimary)
                    if isNow {
                        Text(L10n.calendarToday)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(MihrabColor.abyss)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Capsule().fill(MihrabColor.brass))
                    }
                }
                Text(L10n.calendarThreeMonthsRange(Self.rangeFormatter.string(from: interval.start, to: interval.end)))
                    .font(.footnote)
                    .foregroundStyle(MihrabColor.textSecondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .mihrabSolidCard()
            .accessibilityElement(children: .combine)
        }
    }

    private var yearPicker: some View {
        HStack {
            Button {
                HapticsEngine.shared.light()
                hijriYear -= 1
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: MihrabSpace.hit, height: MihrabSpace.hit)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(L10n.calendarPreviousYear)

            Spacer()
            Text("\(hijriYear) H")
                .font(.headline.monospacedDigit())
                .foregroundStyle(MihrabColor.textPrimary)
            Spacer()

            Button {
                HapticsEngine.shared.light()
                hijriYear += 1
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: MihrabSpace.hit, height: MihrabSpace.hit)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(L10n.calendarNextYear)
        }
        .buttonStyle(.plain)
        .foregroundStyle(MihrabColor.mint)
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func observanceList(_ items: [Observance]) -> some View {
        if items.isEmpty {
            MihrabEmptyState(
                symbol: "moon.stars",
                title: L10n.calendarNoUpcoming,
                message: L10n.calendarNoUpcomingBody
            )
        } else {
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, observance in
                    ObservanceRow(observance: observance) { selected = observance }
                    if index < items.count - 1 { MihrabHairline() }
                }
            }
            .padding(.horizontal, 14)
            .mihrabSolidCard()
        }
    }

    private var fastList: some View {
        VStack(spacing: 0) {
            ForEach(Array(fasts.enumerated()), id: \.element.id) { index, day in
                HStack(spacing: 12) {
                    Image(systemName: day.kinds.first?.symbolName ?? "calendar")
                        .foregroundStyle(MihrabColor.mint)
                        .frame(width: 26)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(day.kinds.map(\.localizedName).joined(separator: " · "))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MihrabColor.textPrimary)
                        Text(Self.dayFormatter.string(from: day.date))
                            .font(.caption)
                            .foregroundStyle(MihrabColor.textTertiary)
                    }
                    Spacer()
                    Text(L10n.calendarDaysLeft(max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: day.date).day ?? 0)))
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(MihrabColor.textSecondary)
                }
                .padding(.vertical, 12)
                .frame(minHeight: MihrabSpace.hit)
                .accessibilityElement(children: .combine)

                if index < fasts.count - 1 { MihrabHairline() }
            }
        }
        .padding(.horizontal, 14)
        .mihrabSolidCard()
    }

    private var footnotes: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(L10n.calendarEveningRule, systemImage: "sunset.fill")
            Label(L10n.calendarAccuracyNote, systemImage: "info.circle")
            Label(L10n.calendarFastsNote, systemImage: "leaf")
        }
        .font(.caption)
        .foregroundStyle(MihrabColor.textSecondary)
        .labelStyle(.titleAndIcon)
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }

    // MARK: - Formatters

    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: L10n.localeIdentifier)
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMMM")
        return formatter
    }()

    static let rangeFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.locale = Locale(identifier: L10n.localeIdentifier)
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: L10n.localeIdentifier)
        formatter.setLocalizedDateFormatFromTemplate("HH:mm")
        return formatter
    }()
}

// MARK: - Row

struct ObservanceRow: View {
    let observance: Observance
    var action: () -> Void

    private var daysUntil: Int { observance.daysUntil() }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: observance.kind.symbolName)
                    .foregroundStyle(observance.kind == .kandil ? MihrabColor.brass : MihrabColor.mint)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(observance.localizedName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(MihrabColor.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textTertiary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                Text(pillText)
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(isImminent ? MihrabColor.abyss : MihrabColor.textSecondary)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background { if isImminent { Capsule().fill(MihrabColor.brass) } }
            }
            .padding(.vertical, 14)
            .frame(minHeight: MihrabSpace.hit)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(observance.localizedName), \(pillText)")
        .accessibilityHint(subtitle)
    }

    private var isImminent: Bool { daysUntil >= 0 && daysUntil < 7 }

    private var pillText: String {
        if daysUntil == 0 { return observance.isNightObservance ? L10n.calendarTonight : L10n.calendarToday }
        if daysUntil == 1 { return L10n.calendarTomorrow }
        return L10n.calendarDaysLeft(daysUntil)
    }

    private var subtitle: String {
        let date = ReligiousCalendarView.dayFormatter.string(from: observance.gregorianDay)
        return "\(observance.localizedRule) · \(date)"
    }
}

// MARK: - Detail

struct ObservanceDetailSheet: View {
    let observance: Observance
    let maghrib: Date?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                MihrabBackdrop(surface: .sheet)
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Image(systemName: observance.kind.symbolName)
                            .font(.largeTitle)
                            .foregroundStyle(MihrabColor.brass)

                        Text(observance.localizedName)
                            .font(.title.bold())
                            .foregroundStyle(MihrabColor.textPrimary)

                        Text(observance.localizedRule)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MihrabColor.mint)

                        Text(startLine)
                            .font(.footnote)
                            .foregroundStyle(MihrabColor.textSecondary)

                        Text(observance.localizedNote)
                            .font(MihrabFont.quote(18))
                            .foregroundStyle(MihrabColor.textPrimary)

                        Divider().overlay(MihrabColor.mint.opacity(0.2))

                        Label(L10n.calendarEveningRule, systemImage: "sunset.fill")
                        Label(L10n.calendarAccuracyNote, systemImage: "info.circle")
                    }
                    .font(.caption)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollEdgeEffectStyle(.soft, for: .top)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button(L10n.done) { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(.ultraThinMaterial)
    }

    private var startLine: String {
        let day = ReligiousCalendarView.dayFormatter.string(from: observance.nightGregorianDay)
        guard let maghrib else { return L10n.calendarBeginsAtMaghribUnknown }
        return L10n.calendarBeginsAt(ReligiousCalendarView.timeFormatter.string(from: maghrib), day: day)
    }
}
