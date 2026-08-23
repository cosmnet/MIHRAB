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
    @State private var showMonthly = false

    /// "Vakit girdi" celebration — the prayer that just came in, if any.
    @State private var enteredPrayer: Prayer?
    @State private var celebrationTrigger = 0

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

    private var isLoadingFirstTimes: Bool {
        repository.today == nil && repository.lastError == nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MihrabBackdrop(surface: .today, ramadanMode: theme.isRamadanMode)

                ScrollView {
                    VStack(spacing: 20) {
                        homeHeader
                            .cardEntrance(index: 0, appeared: appeared, reduceMotion: reduceMotion)

                        if isLoadingFirstTimes {
                            TodaySkeleton()
                                .padding(.horizontal, 16)
                                .transition(.opacity)
                        } else {
                            HeroCountdownCard(onTap: { selectedTab = .times })
                                .padding(.horizontal, 16)
                                .cardEntrance(index: 1, appeared: appeared, reduceMotion: reduceMotion)

                            DaySummaryRow()
                                .padding(.horizontal, 16)
                                .cardEntrance(index: 2, appeared: appeared, reduceMotion: reduceMotion)

                            PrayerStrip()
                                .cardEntrance(index: 3, appeared: appeared, reduceMotion: reduceMotion)

                            PrayerLogCard()
                                .padding(.horizontal, 16)
                                .cardEntrance(index: 4, appeared: appeared, reduceMotion: reduceMotion)
                        }

                        quickActions
                            .padding(.horizontal, 16)
                            .cardEntrance(index: 5, appeared: appeared, reduceMotion: reduceMotion)

                        if repository.today != nil {
                            SunArcView(times: repository.today, date: Date())
                                .padding(.horizontal, 16)
                                .cardEntrance(index: 6, appeared: appeared, reduceMotion: reduceMotion)
                        }

                        DailyHadithCard(onTap: { showHadith = true })
                            .padding(.horizontal, 16)
                            .cardEntrance(index: 7, appeared: appeared, reduceMotion: reduceMotion)

                        if isRamadanSeason {
                            RamadanCard(onTap: { showRamadan = true })
                                .padding(.horizontal, 16)
                                .cardEntrance(index: 8, appeared: appeared, reduceMotion: reduceMotion)
                        }

                        if let upcoming = upcomingReligiousDay {
                            ReligiousDayBanner(day: upcoming.day, daysUntil: upcoming.daysUntil)
                                .padding(.horizontal, 16)
                                .cardEntrance(index: 9, appeared: appeared, reduceMotion: reduceMotion)
                        }

                        DhikrSummaryCard(onTap: { selectedTab = .dhikr })
                            .padding(.horizontal, 16)
                            .cardEntrance(index: 10, appeared: appeared, reduceMotion: reduceMotion)

                        prayerEntryWatcher
                    }
                    .animation(reduceMotion ? nil : MihrabMotion.standardAnimation, value: isLoadingFirstTimes)
                }
                .mihrabTabScroll()
                .mihrabTabSafeContent()
                .refreshable {
                    await repository.refresh()
                }

                if let enteredPrayer {
                    PrayerEnteredOverlay(
                        prayer: enteredPrayer,
                        trigger: celebrationTrigger,
                        reduceMotion: reduceMotion
                    )
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .tint(MihrabColor.textSecondary)
                    .accessibilityLabel(Text(L10n.settings))
                }
            }
            .sheet(isPresented: $showMosques) { MosquesView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showHadith) { HadithDetailSheet(hadith: BundledContent.hadith()) }
            .sheet(isPresented: $showRamadan) { RamadanHubView() }
            .sheet(isPresented: $showMonthly) { MonthlyTimesView(anchorDate: Date()) }
        }
        .onAppear {
            withAnimation { appeared = true }
            if CommandLine.arguments.contains("openSettings") { showSettings = true }
        }
    }

    // MARK: - Header

    private var homeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.title2.weight(.semibold))
                .foregroundStyle(MihrabColor.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            HStack(spacing: 8) {
                Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                if let hijri = repository.today?.hijriDate {
                    Circle()
                        .fill(MihrabColor.brass.opacity(0.8))
                        .frame(width: 3, height: 3)
                    Text(hijri.formatted)
                }
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(MihrabColor.textSecondary)

            locationRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
    }

    /// City + method, tappable straight into Settings. Honest when we do not
    /// know the city yet — never a placeholder name.
    private var locationRow: some View {
        Button { showSettings = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.caption2)
                Text(
                    locationManager.effectiveCityName.isEmpty
                        ? L10n.homeLocatingCity
                        : locationManager.effectiveCityName
                )
                .lineLimit(1)
                Circle()
                    .fill(MihrabColor.textTertiary)
                    .frame(width: 2.5, height: 2.5)
                Text(settings.calculationMethod.localizedName)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(MihrabColor.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .frame(minHeight: 34)
            .background(Capsule().fill(MihrabColor.moss.opacity(0.85)))
            .overlay {
                Capsule().strokeBorder(MihrabColor.mint.opacity(0.2), lineWidth: 1)
            }
        }
        .pressable(reduceMotion)
        .accessibilityHint(Text(L10n.settings))
    }

    // MARK: - Quick actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.homeQuickCaps)
                .ornamentalCaps()
                .padding(.leading, 4)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                QuickActionTile(icon: "map.fill", label: L10n.mosques) {
                    HapticsEngine.shared.light()
                    showMosques = true
                }
                QuickActionTile(icon: "camera.viewfinder", label: L10n.qiblaAR) {
                    HapticsEngine.shared.light()
                    selectedTab = .qibla
                }
                QuickActionTile(icon: "calendar", label: L10n.homeMonthlyTimes) {
                    HapticsEngine.shared.light()
                    showMonthly = true
                }
                QuickActionTile(icon: "circle.grid.3x3.fill", label: L10n.dhikr) {
                    HapticsEngine.shared.light()
                    selectedTab = .dhikr
                }
            }
        }
    }

    // MARK: - "Vakit girdi"

    /// A zero-height clock that notices the next prayer rolling over and fires
    /// the celebration once. Cheap: one tick every five seconds.
    private var prayerEntryWatcher: some View {
        TimelineView(.periodic(from: .now, by: 5)) { context in
            let next = repository.today?.nextPrayer(after: context.date, tomorrow: repository.tomorrow)?.prayer
            Color.clear
                .frame(height: 0)
                .onChange(of: next) { previous, _ in
                    guard let previous, previous.isNotifiable else { return }
                    celebrate(previous)
                }
        }
        .accessibilityHidden(true)
    }

    private func celebrate(_ prayer: Prayer) {
        HapticsEngine.shared.setComplete()
        celebrationTrigger += 1
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : MihrabMotion.standardAnimation) {
            enteredPrayer = prayer
        }
        Task {
            try? await Task.sleep(for: .seconds(3.2))
            withAnimation(.easeInOut(duration: 0.4)) { enteredPrayer = nil }
        }
    }

    // MARK: - Season helpers

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
    var onTap: () -> Void = {}

    @Environment(PrayerTimesRepository.self) private var repository
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ringReveal: Double = 0

    var body: some View {
        Button(action: onTap) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let now = context.date
                let next = repository.today?.nextPrayer(after: now, tomorrow: repository.tomorrow)
                let previous = repository.today?.previousPrayer(before: now)
                let remaining = next.map { remainingHoursMinutes(from: now, to: $0.date) }
                    ?? (hours: 0, minutes: 0)

                VStack(spacing: 14) {
                    if let next {
                        VStack(spacing: 4) {
                            Text(next.prayer.localizedNamazName)
                                .font(.system(size: 28, weight: .semibold, design: .rounded))
                                .foregroundStyle(MihrabColor.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .contentTransition(.opacity)

                            if !L10n.isArabic {
                                Text(next.prayer.arabicName)
                                    .font(MihrabFont.arabic(22))
                                    .foregroundStyle(MihrabColor.textSecondary)
                            }

                            Text(next.prayer.countdownLabel)
                                .ornamentalCaps(theme.isRamadanMode ? MihrabColor.ramadanGold : MihrabColor.brass)
                                .padding(.top, 4)
                        }
                        .animation(reduceMotion ? nil : MihrabMotion.standardAnimation, value: next.prayer)

                        ZStack {
                            BreathingRing(
                                progress: progress(now: now, previous: previous, next: next) * ringReveal,
                                accent: theme.accent,
                                reduceMotion: reduceMotion
                            )
                            HeroRemainingTime(
                                hours: remaining.hours,
                                minutes: remaining.minutes,
                                reduceMotion: reduceMotion
                            )
                        }
                        .frame(
                            width: BreathingRing.diameter + BreathingRing.lineWidth,
                            height: BreathingRing.diameter + BreathingRing.lineWidth
                        )

                        Text(next.date, format: .dateTime.hour().minute())
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(MihrabColor.textSecondary)
                            .contentTransition(.numericText())
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
                .padding(.vertical, 32)
                .padding(.horizontal, 16)
                .mihrabShaderPanel(.ripple, cornerRadius: MihrabSpace.cardRadius, opacity: 0.28)
                .mihrabSolidCard(cornerRadius: MihrabSpace.cardRadius)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(next.map {
                    "\($0.prayer.localizedNamazName) \(L10n.remainingHoursMinutes(remaining.hours, remaining.minutes))"
                } ?? L10n.loadingTimes)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(Text(L10n.tabTimes))
            }
        }
        .pressable(reduceMotion)
        .onAppear {
            if reduceMotion {
                ringReveal = 1
            } else {
                withAnimation(.easeOut(duration: 1.1)) { ringReveal = 1 }
            }
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

/// One centered duration (`4:19`) so the ring never collides with a second column.
private struct HeroRemainingTime: View {
    let hours: Int
    let minutes: Int
    let reduceMotion: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            if hours > 0 {
                unit(hours, L10n.hourShort, padded: false)
                Text(":")
                    .font(MihrabFont.countdown(40))
                    .foregroundStyle(MihrabColor.mint.opacity(0.55))
                    .padding(.top, 6)
            }
            unit(minutes, L10n.minuteShort, padded: hours > 0)
        }
        .accessibilityHidden(true)
    }

    private func unit(_ value: Int, _ label: String, padded: Bool) -> some View {
        VStack(spacing: 2) {
            Text(padded ? String(format: "%02d", value) : "\(value)")
                .font(MihrabFont.countdown(52))
                .foregroundStyle(MihrabColor.mint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .contentTransition(.numericText(countsDown: true))
                .animation(reduceMotion ? nil : .snappy(duration: 0.35), value: value)
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(MihrabColor.brass)
        }
    }
}

/// Flat Fitness-style ring. No glass, no scale — the stroke must stay a clean circle.
private struct BreathingRing: View {
    let progress: Double
    var accent: Color = MihrabColor.emerald
    let reduceMotion: Bool

    static let diameter: CGFloat = 216
    static let lineWidth: CGFloat = 10

    var body: some View {
        ZStack {
            Circle()
                .stroke(MihrabColor.moss, lineWidth: Self.lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [accent, MihrabColor.mint, MihrabColor.sprout],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: MihrabColor.mint.opacity(reduceMotion ? 0 : 0.28), radius: 10)

            // The travelling head — a single dot reads as "now" better than a
            // brighter stroke ever does.
            if progress > 0.01 {
                Circle()
                    .fill(MihrabColor.sprout)
                    .frame(width: Self.lineWidth - 2.5, height: Self.lineWidth - 2.5)
                    .offset(y: -Self.diameter / 2)
                    .rotationEffect(.degrees(progress * 360))
                    .shadow(color: MihrabColor.sprout.opacity(0.7), radius: 5)
            }
        }
        .frame(width: Self.diameter, height: Self.diameter)
        .padding(Self.lineWidth / 2)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.9), value: progress)
        .allowsHitTesting(false)
    }
}

// MARK: - Day summary

/// Two calm facts under the hero: how much of the day is left, and how long
/// the daylight actually is. Both derived — never invented.
struct DaySummaryRow: View {
    @Environment(PrayerTimesRepository.self) private var repository

    private var remainingPrayers: Int {
        guard let today = repository.today else { return 0 }
        let now = Date()
        return PrayerLogStore.fardPrayers.filter { (today.time(for: $0) ?? .distantPast) > now }.count
    }

    private var daylight: (hours: Int, minutes: Int)? {
        guard let today = repository.today,
              let sunrise = today.time(for: .sunrise),
              let maghrib = today.time(for: .maghrib) else { return nil }
        let span = maghrib.timeIntervalSince(sunrise)
        guard span > 0 else { return nil }
        let minutes = Int(span / 60)
        return (minutes / 60, minutes % 60)
    }

    var body: some View {
        HStack(spacing: 10) {
            tile(
                symbol: "checklist",
                caption: L10n.homeSummaryCaps,
                value: remainingPrayers > 0
                    ? L10n.homePrayersLeft(remainingPrayers)
                    : L10n.homeAllPrayersDone
            )

            if let daylight {
                tile(
                    symbol: "sun.horizon.fill",
                    caption: L10n.homeDaylightCaps,
                    value: L10n.homeDaylight(daylight.hours, daylight.minutes)
                )
            }
        }
    }

    private func tile(symbol: String, caption: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.caption)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(MihrabColor.brass)
                Text(caption)
                    .ornamentalCaps()
                    .lineLimit(1)
            }
            Text(value)
                .font(.footnote.weight(.medium))
                .foregroundStyle(MihrabColor.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Prayer strip

struct PrayerStrip: View {
    @Environment(PrayerTimesRepository.self) private var repository
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var nextPrayer: Prayer? {
        repository.today?.nextPrayer(after: Date(), tomorrow: repository.tomorrow)?.prayer
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Prayer.allCases) { prayer in
                        pill(for: prayer)
                            .id(prayer)
                    }
                }
                // Wider than the fade so the first and last pill can both scroll
                // clear of the dissolve — nothing ever ends mid-word.
                .padding(.horizontal, 22)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .softHorizontalFade(edgeWidth: 14)
            .onAppear { scroll(proxy, animated: false) }
            .onChange(of: nextPrayer) { _, _ in scroll(proxy, animated: true) }
        }
    }

    private func scroll(_ proxy: ScrollViewProxy, animated: Bool) {
        Task {
            try? await Task.sleep(for: .seconds(animated ? 0.05 : 0.35))
            guard !Task.isCancelled, let next = nextPrayer else { return }
            withAnimation(reduceMotion ? nil : MihrabMotion.gentleAnimation) {
                proxy.scrollTo(next, anchor: .center)
            }
        }
    }

    private func pill(for prayer: Prayer) -> some View {
        let now = Date()
        let time = repository.today?.time(for: prayer)
        let isNext = nextPrayer == prayer
        let isPassed = (time ?? .distantFuture) <= now

        return VStack(spacing: 6) {
            Image(systemName: prayer.symbolName)
                .font(.callout)
                .symbolRenderingMode(.hierarchical)
            Text(prayer.localizedName)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if let time {
                Text(time, format: .dateTime.hour().minute())
                    .font(.caption.monospacedDigit())
            } else {
                Text("–")
                    .font(.caption.monospacedDigit())
            }
        }
        .foregroundStyle(isNext ? .white : MihrabColor.textPrimary)
        .frame(width: 78, height: 88)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isNext ? theme.accent : MihrabColor.moss)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(isNext ? MihrabColor.mint : MihrabColor.mint.opacity(0.22), lineWidth: 1)
        }
        .animation(reduceMotion ? nil : MihrabMotion.standardAnimation, value: isNext)
        .opacity(isPassed && !isNext ? 0.7 : 1)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Prayer log

/// Five taps a day. The streak is the reward, so it sits on the same card and
/// only ever counts *complete* days.
struct PrayerLogCard: View {
    @Environment(PrayerTimesRepository.self) private var repository
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var store = PrayerLogStore.shared

    private var done: Int { store.completedCount() }
    private var total: Int { PrayerLogStore.fardPrayers.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.homeLogCaps)
                    .ornamentalCaps()
                Spacer()
                Text(L10n.homeLogProgress(done, total))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(MihrabColor.textSecondary)
                    .contentTransition(.numericText())
            }

            HStack(spacing: 8) {
                ForEach(PrayerLogStore.fardPrayers) { prayer in
                    marker(for: prayer)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: store.streak > 0 ? "flame.fill" : "flame")
                    .font(.footnote)
                    .foregroundStyle(store.streak > 0 ? MihrabColor.brass : MihrabColor.textTertiary)
                    .symbolRenderingMode(.hierarchical)
                Text(store.streak > 0 ? L10n.homeStreakDays(store.streak) : L10n.homeStreakStart)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(store.streak > 0 ? MihrabColor.textPrimary : MihrabColor.textSecondary)
                Spacer()
            }
        }
        .padding(20)
        .mihrabCard(cornerRadius: MihrabSpace.cardRadius)
        .accessibilityHint(Text(L10n.homeLogHint))
    }

    private func marker(for prayer: Prayer) -> some View {
        let isLogged = store.isLogged(prayer)
        let hasArrived = (repository.today?.time(for: prayer) ?? .distantFuture) <= Date()

        return Button {
            let nowLogged = store.toggle(prayer)
            if nowLogged {
                if store.completedCount() == total {
                    HapticsEngine.shared.setComplete()
                } else {
                    HapticsEngine.shared.success()
                }
            } else {
                HapticsEngine.shared.light()
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isLogged ? theme.accent : MihrabColor.moss)
                    Circle()
                        .strokeBorder(
                            isLogged ? MihrabColor.sprout.opacity(0.8) : MihrabColor.mint.opacity(0.22),
                            lineWidth: 1
                        )
                    Image(systemName: isLogged ? "checkmark" : prayer.symbolName)
                        .font(.system(size: isLogged ? 15 : 13, weight: .semibold))
                        .foregroundStyle(isLogged ? .white : MihrabColor.textSecondary)
                        .symbolRenderingMode(.hierarchical)
                        .contentTransition(.symbolEffect)
                }
                .frame(width: 40, height: 40)

                Text(prayer.shortName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isLogged ? MihrabColor.textPrimary : MihrabColor.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: MihrabSpace.hit)
            .opacity(hasArrived || isLogged ? 1 : 0.55)
            .animation(reduceMotion ? nil : MihrabMotion.snappyAnimation, value: isLogged)
        }
        .pressable(reduceMotion)
        .accessibilityLabel(Text(
            isLogged
                ? L10n.homeMarkedPrayed(prayer.localizedNamazName)
                : L10n.homeMarkPrayed(prayer.localizedNamazName)
        ))
        .accessibilityAddTraits(isLogged ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - "Vakit girdi" overlay

/// A short, quiet celebration. Reduce Motion keeps the banner and drops the
/// sparks — the information survives, the spectacle does not.
private struct PrayerEnteredOverlay: View {
    let prayer: Prayer
    let trigger: Int
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            if !reduceMotion {
                ParticleBurst(trigger: trigger)
                    .frame(width: 320, height: 320)
            }

            VStack(spacing: 6) {
                Image(systemName: prayer.symbolName)
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(MihrabColor.brass)
                Text(L10n.homePrayerEntered(prayer.localizedNamazName))
                    .font(.headline)
                    .foregroundStyle(MihrabColor.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .mihrabSolidCard(cornerRadius: 24, stroke: MihrabColor.brass.opacity(0.55))
            .shadow(color: MihrabColor.abyss.opacity(0.5), radius: 24, y: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Skeleton

/// Shown only before the very first schedule lands. Shapes match the real
/// cards so nothing jumps when the data arrives.
struct TodaySkeleton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shimmer = false

    var body: some View {
        VStack(spacing: 20) {
            block(height: 300, radius: MihrabSpace.cardRadius)
            HStack(spacing: 10) {
                block(height: 78, radius: MihrabSpace.rowRadius)
                block(height: 78, radius: MihrabSpace.rowRadius)
            }
            block(height: 150, radius: MihrabSpace.cardRadius)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text(L10n.loadingTimes))
    }

    private func block(height: CGFloat, radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(MihrabColor.moss.opacity(shimmer ? 0.75 : 0.45))
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(MihrabColor.mint.opacity(0.14), lineWidth: 1)
            }
    }
}

// MARK: - Daily hadith card

struct DailyHadithCard: View {
    let onTap: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hadith = BundledContent.hadith()

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(MihrabColor.brass)
                    .frame(width: 3)

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
                        .accessibilityLabel(Text(L10n.shareHadith))
                    }
                    Text(hadith.localizedTranslation)
                        .font(MihrabFont.quoteItalic(24))
                        .foregroundStyle(MihrabColor.textPrimary)
                        .lineSpacing(7)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        Text(hadith.narrator)
                        Circle()
                            .fill(MihrabColor.brass)
                            .frame(width: 3, height: 3)
                        Text(hadith.source)
                    }
                    .font(.caption)
                    .foregroundStyle(MihrabColor.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(28)
            .mihrabShaderPanel(.lantern, cornerRadius: MihrabSpace.cardRadius, opacity: 0.22)
            .mihrabCard(interactive: true)
        }
        .pressable(reduceMotion)
    }
}

// MARK: - Quick action tile

struct QuickActionTile: View {
    let icon: String
    let label: String
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(MihrabColor.mint)
                    .frame(width: 26, height: 26)
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MihrabColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
            .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
        }
        .pressable(reduceMotion)
        .accessibilityLabel(Text(label))
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
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Dhikr summary card

struct DhikrSummaryCard: View {
    let onTap: () -> Void
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "circle.grid.3x3.fill")
                    .foregroundStyle(MihrabColor.emerald)
                    .frame(width: 28, height: 28)
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
            .padding(.horizontal, 16)
            .frame(height: 56)
            .mihrabCard(cornerRadius: 20, interactive: true)
        }
        .pressable(reduceMotion)
    }
}
