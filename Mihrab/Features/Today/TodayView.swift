import SwiftUI

struct TodayView: View {
    @Binding var selectedTab: AppTab

    @Environment(PrayerTimesRepository.self) private var repository
    @Environment(LocationManager.self) private var locationManager
    @Environment(AppSettings.self) private var settings
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appeared = false
    @State private var showMosques = false
    @State private var showSettings = false
    @State private var showHadith = false
    @State private var showRamadan = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let base: String = switch hour {
        case 5...11: L10n.goodMorning
        case 12...17: L10n.goodAfternoon
        case 18...21: L10n.goodEvening
        default: L10n.goodNight
        }
        let name = settings.userName
        return name.isEmpty ? base : "\(base), \(name)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground(ramadanMode: theme.isRamadanMode)

                ScrollView {
                    VStack(spacing: 16) {
                        HeroCountdownCard()
                            .padding(.horizontal, 16)
                            .cardEntrance(index: 0, appeared: appeared, reduceMotion: reduceMotion)
                            .onTapGesture { selectedTab = .times }

                        PrayerStrip()
                            .cardEntrance(index: 1, appeared: appeared, reduceMotion: reduceMotion)

                        DailyHadithCard(onTap: { showHadith = true })
                            .padding(.horizontal, 16)
                            .cardEntrance(index: 2, appeared: appeared, reduceMotion: reduceMotion)

                        quickActions
                            .padding(.horizontal, 16)
                            .cardEntrance(index: 3, appeared: appeared, reduceMotion: reduceMotion)

                        if isRamadanSeason {
                            RamadanCard(onTap: { showRamadan = true })
                                .padding(.horizontal, 16)
                                .cardEntrance(index: 4, appeared: appeared, reduceMotion: reduceMotion)
                        }

                        if let upcoming = upcomingReligiousDay {
                            ReligiousDayBanner(day: upcoming.day, daysUntil: upcoming.daysUntil)
                                .padding(.horizontal, 16)
                                .cardEntrance(index: 5, appeared: appeared, reduceMotion: reduceMotion)
                        }

                        DhikrSummaryCard(onTap: { selectedTab = .dhikr })
                            .padding(.horizontal, 16)
                            .cardEntrance(index: 6, appeared: appeared, reduceMotion: reduceMotion)
                    }
                    .padding(.bottom, MihrabSpace.tabClearance)
                }
                .mihrabTabScroll()
            }
            .navigationTitle(greeting)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .tint(MihrabColor.textSecondary)
                }
            }
            .sheet(isPresented: $showMosques) { MosquesView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showHadith) { HadithDetailSheet(hadith: BundledContent.hadith()) }
            .sheet(isPresented: $showRamadan) { RamadanHubView() }
        }
        .onAppear {
            withAnimation { appeared = true }
        }
        .refreshable {
            await repository.refresh()
        }
    }

    private var quickActions: some View {
        HStack(spacing: 28) {
            QuickActionButton(icon: "map.fill", label: L10n.mosques) { showMosques = true }
            QuickActionButton(icon: "camera.fill", label: L10n.qiblaAR) { selectedTab = .qibla }
            QuickActionButton(icon: "circle.grid.3x3.fill", label: L10n.zikirmatik) { selectedTab = .dhikr }
        }
        .frame(maxWidth: .infinity)
    }

    private var isRamadanSeason: Bool {
        guard let hijri = repository.today?.hijriDate else { return false }
        return hijri.month == 9 || (hijri.month == 8 && hijri.day >= 26) || (hijri.month == 10 && hijri.day <= 3)
    }

    private var upcomingReligiousDay: (day: ReligiousDay, daysUntil: Int)? {
        guard let hijri = repository.today?.hijriDate else { return nil }
        return BundledContent.upcomingReligiousDays(from: hijri)
            .first { $0.daysUntil > 0 && $0.daysUntil <= 7 }
    }
}

// MARK: - Hero countdown card

struct HeroCountdownCard: View {
    @Environment(PrayerTimesRepository.self) private var repository
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let next = repository.today?.nextPrayer(after: now, tomorrow: repository.tomorrow)
            let previous = repository.today?.previousPrayer(before: now)
            let remaining = next.map { remainingHoursMinutes(from: now, to: $0.date) }
                ?? (hours: 0, minutes: 0)

            VStack(spacing: 12) {
                if let next {
                    VStack(spacing: 4) {
                        Text(next.prayer.localizedNamazName)
                            .font(.system(size: 32, weight: .semibold, design: .rounded))
                            .foregroundStyle(MihrabColor.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        if !L10n.isArabic {
                            Text(next.prayer.arabicName)
                                .font(MihrabFont.arabic(22))
                                .foregroundStyle(MihrabColor.textSecondary)
                        }

                        Text(next.prayer.countdownLabel)
                            .ornamentalCaps()
                            .padding(.top, 4)
                    }

                    ZStack {
                        BreathingRing(
                            progress: progress(now: now, previous: previous, next: next),
                            reduceMotion: reduceMotion
                        )
                        HeroRemainingTime(hours: remaining.hours, minutes: remaining.minutes)
                    }
                    .frame(width: BreathingRing.diameter, height: BreathingRing.diameter)

                    if let hijri = repository.today?.hijriDate {
                        Text("\(now.formatted(date: .abbreviated, time: .omitted)) · \(hijri.formatted)")
                            .font(.subheadline)
                            .foregroundStyle(MihrabColor.textSecondary)
                    }
                } else {
                    ProgressView()
                        .tint(MihrabColor.mint)
                        .frame(height: 148)
                    Text(repository.lastError == nil ? L10n.locating : L10n.timesUnavailableShort)
                        .font(.subheadline)
                        .foregroundStyle(MihrabColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .padding(.horizontal, 16)
            .background {
                BrassCrescent(diameter: 96, opacity: 0.07)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 10)
                    .padding(.bottom, 8)
            }
            .mihrabCardScene("today-hero", opacity: 0.45)
            .mihrabCard()
            .accessibilityElement(children: .combine)
            .accessibilityLabel(next.map {
                "\($0.prayer.localizedNamazName) \(L10n.remainingHoursMinutes(remaining.hours, remaining.minutes))"
            } ?? L10n.loadingTimes)
        }
    }

    private func progress(now: Date, previous: (prayer: Prayer, date: Date)?,
                          next: (prayer: Prayer, date: Date)) -> Double {
        guard let previous else { return 0 }
        let span = next.date.timeIntervalSince(previous.date)
        guard span > 0 else { return 0 }
        return min(max(now.timeIntervalSince(previous.date) / span, 0), 1)
    }

    /// Floors seconds away. `SafeCountdown` gates finished/invalid ranges — never `Text(timerInterval:)`.
    private func remainingHoursMinutes(from now: Date, to date: Date) -> (hours: Int, minutes: Int) {
        guard SafeCountdown.range(from: now, to: date) != nil else { return (0, 0) }
        let totalMinutes = Int(max(0, date.timeIntervalSince(now)) / 60)
        return (totalMinutes / 60, totalMinutes % 60)
    }
}

/// Hours + minutes as labeled columns (TR: `1 sa` / `35 dk`). Never `:SS`.
private struct HeroRemainingTime: View {
    let hours: Int
    let minutes: Int

    var body: some View {
        Group {
            if hours > 0 {
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    unitColumn(value: hours, label: L10n.hourShort, padded: false)
                    unitColumn(value: minutes, label: L10n.minuteShort, padded: true)
                }
            } else {
                unitColumn(value: minutes, label: L10n.minuteShort, padded: false)
            }
        }
        .accessibilityHidden(true)
    }

    private func unitColumn(value: Int, label: String, padded: Bool) -> some View {
        VStack(spacing: 2) {
            Text(padded ? String(format: "%02d", value) : "\(value)")
                .font(MihrabFont.countdown(58))
                .foregroundStyle(MihrabColor.mint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(MihrabColor.brass)
        }
    }
}

/// Fitness-weight progress ring. Digits sit in the center; stroke is thick, not a hairline.
private struct BreathingRing: View {
    let progress: Double
    let reduceMotion: Bool

    static let diameter: CGFloat = 208
    static let lineWidth: CGFloat = 16

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: reduceMotion)) { context in
            let breath = reduceMotion ? 1.0 : 1.0 + 0.012 * sin(context.date.timeIntervalSinceReferenceDate * 2 * .pi / 4)
            let trackRadius = Self.diameter / 2 - Self.lineWidth / 2
            ZStack {
                Circle()
                    .stroke(MihrabColor.moss, lineWidth: Self.lineWidth)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [MihrabColor.emerald, MihrabColor.mint, MihrabColor.sprout],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [MihrabColor.mint.opacity(0.5), MihrabColor.mint.opacity(0.06)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
                    .padding(Self.lineWidth * 0.42)
                Circle()
                    .fill(MihrabColor.brass)
                    .frame(width: 12, height: 12)
                    .shadow(color: MihrabColor.brass.opacity(0.45), radius: 3)
                    .offset(y: -trackRadius)
                    .rotationEffect(.degrees(progress * 360))
            }
            .frame(width: Self.diameter, height: Self.diameter)
            .scaleEffect(breath)
        }
    }
}

// MARK: - Prayer strip

struct PrayerStrip: View {
    @Environment(PrayerTimesRepository.self) private var repository
    @Environment(Theme.self) private var theme

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Prayer.allCases) { prayer in
                        pill(for: prayer)
                            .id(prayer)
                    }
                }
                .padding(.horizontal, 16)
            }
            .softHorizontalFade(edgeWidth: 24)
            .onAppear {
                if let next = repository.today?.nextPrayer(after: Date(), tomorrow: repository.tomorrow) {
                    proxy.scrollTo(next.prayer, anchor: .center)
                }
            }
        }
    }

    private func pill(for prayer: Prayer) -> some View {
        let now = Date()
        let time = repository.today?.time(for: prayer)
        let isNext = repository.today?.nextPrayer(after: now, tomorrow: repository.tomorrow)?.prayer == prayer
        let isPassed = (time ?? .distantFuture) <= now

        return VStack(spacing: 6) {
            Image(systemName: prayer.symbolName)
                .font(.callout)
                .symbolRenderingMode(.hierarchical)
            Text(prayer.localizedName)
                .font(.caption.weight(.semibold))
            if let time {
                Text(time, format: .dateTime.hour().minute())
                    .font(.caption.monospacedDigit())
            } else {
                Text("–")
                    .font(.caption.monospacedDigit())
            }
        }
        .foregroundStyle(isNext ? .white : MihrabColor.textPrimary)
        .frame(width: 76, height: 88)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isNext ? theme.accent : MihrabColor.moss)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(isNext ? MihrabColor.mint : MihrabColor.mint.opacity(0.22), lineWidth: 1)
        }
        .opacity(isPassed && !isNext ? 0.7 : 1)
    }
}

// MARK: - Daily hadith card

struct DailyHadithCard: View {
    let onTap: () -> Void
    @State private var hadith = BundledContent.hadith()

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(L10n.dailyHadith)
                        .ornamentalCaps()
                    Spacer()
                    ShareLink(item: "\"\(hadith.localizedTranslation)\" — \(hadith.narrator), \(hadith.source)") {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body)
                            .foregroundStyle(MihrabColor.textSecondary)
                            .frame(width: MihrabSpace.hit, height: MihrabSpace.hit)
                            .background(Circle().fill(MihrabColor.moss))
                    }
                }
                Text(hadith.localizedTranslation)
                    .font(MihrabFont.quoteItalic(22))
                    .foregroundStyle(MihrabColor.textPrimary)
                    .lineSpacing(6)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(hadith.narrator) · \(hadith.source)")
                    .font(.caption)
                    .foregroundStyle(MihrabColor.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .mihrabCardScene("today-hadith", opacity: 0.38)
            .mihrabCard(interactive: true)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick action button

struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(MihrabColor.mint)
                    .frame(width: 64, height: 64)
                    .glassEffect(.regular.interactive(), in: .circle)
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(MihrabColor.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Ramadan card

struct RamadanCard: View {
    let onTap: () -> Void
    @Environment(PrayerTimesRepository.self) private var repository

    var body: some View {
        Button(action: onTap) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                HStack(spacing: 16) {
                    Image(systemName: "moon.stars.fill")
                        .font(.largeTitle)
                        .foregroundStyle(MihrabColor.ramadanGold)
                        .symbolRenderingMode(.hierarchical)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.ramadan)
                            .ornamentalCaps(MihrabColor.ramadanGold)
                        if let maghrib = repository.today?.time(for: .maghrib), maghrib > context.date {
                            HStack(spacing: 4) {
                                Text(L10n.iftarLeft(maghrib.formatted(date: .omitted, time: .shortened)))
                                CountdownText(from: context.date, to: maghrib, finished: "0:00")
                                Text(L10n.left)
                            }
                            .font(.subheadline.weight(.medium))
                        } else if let fajr = repository.tomorrow?.time(for: .fajr) {
                            Text(L10n.suhoorEnds(fajr.formatted(date: .omitted, time: .shortened)))
                                .font(.subheadline.weight(.medium))
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(MihrabColor.textTertiary)
                }
                .padding(20)
                .background {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(MihrabColor.ramadanViolet.opacity(0.5))
                }
                .mihrabCard(interactive: true)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Religious day banner

struct ReligiousDayBanner: View {
    let day: ReligiousDay
    let daysUntil: Int

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "star.fill")
                .foregroundStyle(MihrabColor.brass)
            Text(L10n.inDays(day.localizedName, daysUntil))
                .font(.subheadline.weight(.medium))
            Spacer()
        }
        .padding(16)
        .mihrabCard(cornerRadius: 20)
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(MihrabColor.brass.opacity(0.5), lineWidth: 1)
        }
    }
}

// MARK: - Dhikr summary card

struct DhikrSummaryCard: View {
    let onTap: () -> Void
    @Environment(AppSettings.self) private var settings

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(MihrabColor.moss, lineWidth: 6)
                        .frame(width: 52, height: 52)
                    Image(systemName: "circle.grid.3x3.fill")
                        .foregroundStyle(MihrabColor.emerald)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.dhikr)
                        .ornamentalCaps()
                    Text(L10n.dailyGoal(settings.dailyDhikrGoal))
                        .font(.subheadline)
                        .foregroundStyle(MihrabColor.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(MihrabColor.textTertiary)
            }
            .padding(16)
            .mihrabCard(interactive: true)
        }
        .buttonStyle(.plain)
    }
}
