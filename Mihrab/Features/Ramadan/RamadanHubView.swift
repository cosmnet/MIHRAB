import SwiftData
import SwiftUI

struct RamadanHubView: View {
    @Environment(PrayerTimesRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var khatam: KhatamProgress?

    private let microcopy = [
        L10n.ramadanQuote1,
        L10n.ramadanQuote2,
        L10n.ramadanQuote3,
        L10n.ramadanQuote4,
        L10n.ramadanQuote5,
    ]

    private var hijri: HijriDate? { repository.today?.hijriDate }
    private var ramadanDay: Int { hijri?.month == 9 ? hijri?.day ?? 0 : 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground(ramadanMode: true)
                ScrollView {
                    VStack(spacing: 16) {
                        heroCountdown
                        dualTimes
                        fastingDayCounter
                        duasCard
                        khatamTracker
                        if ramadanDay >= 20 { eidCountdown }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 48)
                }
                .scrollEdgeEffectStyle(.soft, for: .top)
            }
            .navigationTitle(L10n.ramadanTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.done) { dismiss() }
                }
            }
        }
        .presentationBackground(.ultraThinMaterial)
        .task { loadKhatam() }
    }

    // MARK: - Hero

    private var heroCountdown: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let maghrib = repository.today?.time(for: .maghrib)
            let fajrTomorrow = repository.tomorrow?.time(for: .fajr)
            let toIftar = maghrib.map { $0 > now } ?? false

            VStack(spacing: 12) {
                MihrabOrnament(name: "lantern", opacity: 0.92, side: 64)

                Text(toIftar ? L10n.iftarIn : L10n.suhoorEndsIn)
                    .ornamentalCaps(MihrabColor.ramadanGold)

                if toIftar, let maghrib, let range = SafeCountdown.range(from: now, to: maghrib) {
                    Text(timerInterval: range, countsDown: true)
                        .font(MihrabFont.countdown(56))
                        .foregroundStyle(MihrabColor.ramadanGold)
                } else if let fajrTomorrow, let range = SafeCountdown.range(from: now, to: fajrTomorrow) {
                    Text(timerInterval: range, countsDown: true)
                        .font(MihrabFont.countdown(56))
                        .foregroundStyle(MihrabColor.ramadanGold)
                } else {
                    Text("–")
                        .font(MihrabFont.countdown(56))
                        .foregroundStyle(MihrabColor.ramadanGold)
                }

                Text(microcopy[Calendar.current.component(.day, from: now) % microcopy.count])
                    .font(MihrabFont.quoteItalic(15))
                    .foregroundStyle(MihrabColor.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .mihrabCardScene("today-hero", opacity: 0.4)
            .mihrabCard()
        }
    }

    // MARK: - Dual times

    private var dualTimes: some View {
        HStack(spacing: 12) {
            TimeTile(title: L10n.suhoorEndsCaps, time: repository.today?.time(for: .fajr))
            TimeTile(title: L10n.iftarCaps, time: repository.today?.time(for: .maghrib))
        }
    }

    // MARK: - Fasting day counter with crescent fill

    private var fastingDayCounter: some View {
        HStack(spacing: 20) {
            CrescentFillMark(progress: Double(ramadanDay) / 29.0)
                .animation(reduceMotion ? .none : MihrabMotion.gentleAnimation, value: ramadanDay)

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.fastingCaps)
                    .ornamentalCaps(MihrabColor.ramadanGold)
                Text(L10n.ramadanDayOf(ramadanDay))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(MihrabColor.textPrimary)
            }
            Spacer()
        }
        .padding(20)
        .mihrabCard()
    }

    // MARK: - Duas

    private var duasCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.dailyDuas)
                .ornamentalCaps(MihrabColor.ramadanGold)

            DuaRow(title: L10n.iftarDua, dua: BundledContent.adhkar.iftarDua)
            MihrabHairline()
            DuaRow(title: L10n.suhoorIntention, dua: BundledContent.adhkar.suhoorIntention)
        }
        .padding(20)
        .mihrabCard()
    }

    // MARK: - Khatam tracker

    private var khatamTracker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.khatamTracker)
                    .ornamentalCaps(MihrabColor.ramadanGold)
                Spacer()
                Text(L10n.juzCount(khatam?.completedJuz ?? 0))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
            }

            ProgressView(value: Double(khatam?.completedJuz ?? 0), total: 30)
                .tint(MihrabColor.ramadanGold)

            HStack(spacing: 12) {
                Button {
                    adjustKhatam(-1)
                } label: {
                    Image(systemName: "minus")
                        .frame(width: MihrabSpace.hit, height: MihrabSpace.hit)
                        .background(Capsule().fill(MihrabColor.moss))
                }
                Button {
                    adjustKhatam(1)
                } label: {
                    Label(L10n.logJuz, systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: MihrabSpace.hit)
                        .padding(.horizontal, 20)
                        .background(Capsule().fill(MihrabColor.moss))
                }
            }
        }
        .padding(20)
        .mihrabCard()
    }

    // MARK: - Eid countdown

    private var eidCountdown: some View {
        HStack(spacing: 14) {
            Image(systemName: "party.popper.fill")
                .font(.title2)
                .foregroundStyle(MihrabColor.ramadanGold)
            Text(L10n.eidInDays(max(30 - ramadanDay, 0)))
                .font(.headline)
            Spacer()
        }
        .padding(20)
        .mihrabCard()
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(MihrabColor.ramadanGold.opacity(0.5), lineWidth: 1)
        }
    }

    private func loadKhatam() {
        let descriptor = FetchDescriptor<KhatamProgress>()
        if let existing = try? modelContext.fetch(descriptor).first {
            khatam = existing
        } else {
            let new = KhatamProgress()
            modelContext.insert(new)
            try? modelContext.save()
            khatam = new
        }
    }

    private func adjustKhatam(_ delta: Int) {
        guard let khatam else { return }
        khatam.completedJuz = min(max(khatam.completedJuz + delta, 0), 30)
        khatam.updatedAt = Date()
        try? modelContext.save()
        HapticsEngine.shared.light()
    }
}

// MARK: - Components

private struct TimeTile: View {
    let title: String
    let time: Date?

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .ornamentalCaps(MihrabColor.ramadanGold)
            if let time {
                Text(time, format: .dateTime.hour().minute())
                    .font(MihrabFont.timeDisplay(30))
                    .foregroundStyle(MihrabColor.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } else {
                Text("–")
                    .font(MihrabFont.timeDisplay(30))
                    .foregroundStyle(MihrabColor.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .mihrabCard(cornerRadius: 22)
    }
}

private struct DuaRow: View {
    let title: String
    let dua: Dua

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(dua.arabic)
                .font(MihrabFont.arabic(20))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
            Text(Locale.mihrabIsTurkish ? dua.tr : dua.en)
                .font(MihrabFont.quoteItalic(15))
                .foregroundStyle(MihrabColor.textSecondary)
        }
    }
}

