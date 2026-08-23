import SwiftUI

/// Today, at six blocks instead of eleven.
///
/// The old screen stacked every card at the same `mihrabCard` weight, so there
/// was no hierarchy — only reading. Now there is exactly one primary card (the
/// hero, which carries the day's single action), one secondary strip, and a
/// short tail of quiet rows. Everything that was a card but is really a
/// destination (month grid, mosques) moved into the toolbar; the sun arc lives
/// on the Times tab, where it was already drawn.
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
    @State private var log = PrayerLogStore.shared

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

    /// Only true before the very first schedule ever lands. A cached day plus a
    /// network error is *not* loading — it is a working screen with a stale
    /// badge on it.
    private var isLoadingFirstTimes: Bool {
        repository.today == nil && repository.lastError == nil && !repository.engineUnavailable
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backdrop

                ScrollView {
                    VStack(spacing: 20) {
                        homeHeader
                            .cardEntrance(index: 0, appeared: appeared, reduceMotion: reduceMotion)

                        // 1 · seasonal band (only when it is actually the season)
                        seasonalBand
                            .cardEntrance(index: 1, appeared: appeared, reduceMotion: reduceMotion)

                        // 2 · hero — the only primary-weight card on the screen
                        heroBlock
                            .padding(.horizontal, 16)
                            .cardEntrance(index: 2, appeared: appeared, reduceMotion: reduceMotion)

                        // 3 · schedule strip + one-line day summary + provenance
                        TodayScheduleBlock()
                            .cardEntrance(index: 3, appeared: appeared, reduceMotion: reduceMotion)

                        // 4 · prayer log & streak
                        PrayerLogCard()
                            .padding(.horizontal, 16)
                            .cardEntrance(index: 4, appeared: appeared, reduceMotion: reduceMotion)

                        // 5 · hadith of the day
                        DailyHadithCard(onTap: { showHadith = true })
                            .padding(.horizontal, 16)
                            .cardEntrance(index: 5, appeared: appeared, reduceMotion: reduceMotion)

                        // 6 · quiet tail row
                        DhikrSummaryCard(onTap: { selectedTab = .dhikr })
                            .padding(.horizontal, 16)
                            .cardEntrance(index: 6, appeared: appeared, reduceMotion: reduceMotion)

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
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button { showMonthly = true } label: {
                        Image(systemName: "calendar")
                    }
                    .tint(MihrabColor.textSecondary)
                    .accessibilityLabel(Text(L10n.homeMonthlyTimes))

                    Button { showMosques = true } label: {
                        Image(systemName: "map")
                    }
                    .tint(MihrabColor.textSecondary)
                    .accessibilityLabel(Text(L10n.mosques))
                }

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

    // MARK: - Backdrop

    /// The day's tone, recomputed every five minutes. Deliberately not a
    /// per-second clock: the veil crossfades over seconds anyway, and the drift
    /// underneath is still a single Core Animation keyframe.
    private var backdrop: some View {
        TimelineView(.periodic(from: .now, by: 300)) { context in
            MihrabBackdrop(
                surface: .today,
                segment: DaySegment.resolve(
                    now: context.date,
                    today: repository.today,
                    tomorrow: repository.tomorrow
                ),
                ramadanMode: theme.isRamadanMode
            )
        }
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroBlock: some View {
        if isLoadingFirstTimes {
            TodayHeroSkeleton()
                .transition(.opacity)
        } else if repository.today == nil {
            // The error is confined to this card. Everything below — the log,
            // the hadith, dhikr, and both other tabs — keeps working offline.
            MihrabEmptyState(
                symbol: repository.engineUnavailable ? "sun.max.trianglebadge.exclamationmark" : "wifi.slash",
                title: repository.engineUnavailable
                    ? L10n.timesUnavailableShort
                    : L10n.homeTimesErrorTitle,
                message: repository.engineUnavailable
                    ? L10n.homeTimesUnavailableHere
                    : L10n.homeTimesErrorBody,
                retry: repository.engineUnavailable ? nil : { Task { await repository.refresh() } }
            )
        } else {
            HeroCountdownCard(
                onOpenTimes: { selectedTab = .times },
                onPrimary: perform(_:)
            )
        }
    }

    private func perform(_ action: TodayPrimaryAction) {
        switch action {
        case .markPrayed(let prayer):
            let nowLogged = log.toggle(prayer)
            if nowLogged, log.completedCount() == PrayerLogStore.fardPrayers.count {
                HapticsEngine.shared.setComplete()
            } else {
                HapticsEngine.shared.success()
            }
        case .showQibla:
            HapticsEngine.shared.light()
            selectedTab = .qibla
        case .startDhikr:
            HapticsEngine.shared.light()
            selectedTab = .dhikr
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
                Text(Date.now.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted).locale(L10n.appLocale)))
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
            .frame(minHeight: MihrabSpace.hit * 0.78)
            .background(Capsule().fill(MihrabColor.moss.opacity(0.85)))
            .overlay {
                Capsule().strokeBorder(MihrabColor.mint.opacity(0.2), lineWidth: 1)
            }
        }
        .pressable(reduceMotion)
        .accessibilityHint(Text(L10n.settings))
    }

    // MARK: - Seasonal band

    /// One seasonal slot, at the top where the season belongs. Ramadan wins; a
    /// religious day inside the week takes the slot otherwise. Nothing shows
    /// when neither is true.
    @ViewBuilder
    private var seasonalBand: some View {
        if isRamadanSeason {
            RamadanBand(onTap: { showRamadan = true })
                .padding(.horizontal, 16)
        } else if let upcoming = upcomingReligiousDay {
            ReligiousDayBanner(day: upcoming.day, daysUntil: upcoming.daysUntil)
                .padding(.horizontal, 16)
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

/// The one primary-weight card on Today: how long is left, and the single
/// thing worth doing about it.
struct HeroCountdownCard: View {
    var onOpenTimes: () -> Void = {}
    var onPrimary: (TodayPrimaryAction) -> Void = { _ in }

    @Environment(PrayerTimesRepository.self) private var repository
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ringReveal: Double = 0
    @State private var log = PrayerLogStore.shared

    @ScaledMetric(relativeTo: .title) private var prayerNameSize: CGFloat = 28
    @ScaledMetric(relativeTo: .title2) private var arabicNameSize: CGFloat = 22
    @ScaledMetric(relativeTo: .largeTitle) private var ringDiameter: CGFloat = 216

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let next = repository.today?.nextPrayer(after: now, tomorrow: repository.tomorrow)
            let previous = repository.today?.previousPrayer(before: now)
            let remaining = next.map { remainingHoursMinutes(from: now, to: $0.date) }
                ?? (hours: 0, minutes: 0)
            let action = TodayPrimaryAction.resolve(
                now: now,
                today: repository.today,
                tomorrow: repository.tomorrow,
                log: log
            )

            VStack(spacing: 16) {
                Button(action: onOpenTimes) {
                    VStack(spacing: 14) {
                        if let next {
                            VStack(spacing: 4) {
                                Text(next.prayer.localizedNamazName)
                                    .font(.system(size: prayerNameSize, weight: .semibold, design: .rounded))
                                    .foregroundStyle(MihrabColor.textPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .contentTransition(.opacity)

                                if !L10n.isArabic {
                                    Text(next.prayer.arabicName)
                                        .font(MihrabFont.arabic(arabicNameSize))
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
                                    diameter: ringDiameter,
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
                                width: ringDiameter + BreathingRing.lineWidth,
                                height: ringDiameter + BreathingRing.lineWidth
                            )

                            Text(next.date, format: .dateTime.hour().minute())
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(MihrabColor.textSecondary)
                                .contentTransition(.numericText())
                        } else {
                            ProgressView()
                                .tint(MihrabColor.mint)
                                .frame(height: ringDiameter * 0.68)
                            Text(repository.lastError == nil ? L10n.locating : L10n.timesUnavailableShort)
                                .font(.subheadline)
                                .foregroundStyle(MihrabColor.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    // VoiceOver reads the hero as one sentence, then finds the
                    // action button beneath it as a separate element.
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(next.map {
                        "\($0.prayer.localizedNamazName), \(L10n.remainingHoursMinutes(remaining.hours, remaining.minutes)), \($0.date.formatted(date: .omitted, time: .shortened))"
                    } ?? L10n.loadingTimes)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint(Text(L10n.tabTimes))
                }
                .pressable(reduceMotion)

                if next != nil {
                    primaryActionBar(action)
                }
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 16)
            .mihrabShaderPanel(.ripple, cornerRadius: MihrabSpace.cardRadius, opacity: 0.28)
            .mihrabSolidCard(cornerRadius: MihrabSpace.cardRadius)
        }
        .onAppear {
            if reduceMotion || MihrabPower.isLowPowerMode {
                ringReveal = 1
            } else {
                withAnimation(.easeOut(duration: 1.1)) { ringReveal = 1 }
            }
        }
    }

    /// Full-width capsule under the ring — the most valuable pixels on the
    /// screen finally carry a verb.
    private func primaryActionBar(_ action: TodayPrimaryAction) -> some View {
        Button {
            onPrimary(action)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: action.symbolName)
                    .font(.subheadline.weight(.semibold))
                Text(action.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: MihrabSpace.hit)
            .background(Capsule().fill(theme.accent))
            .overlay {
                Capsule().strokeBorder(MihrabColor.sprout.opacity(0.35), lineWidth: 1)
            }
        }
        .pressable(reduceMotion)
        .accessibilityLabel(Text(action.title))
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

    @ScaledMetric(relativeTo: .largeTitle) private var digitSize: CGFloat = 52
    @ScaledMetric(relativeTo: .largeTitle) private var colonSize: CGFloat = 40
    @ScaledMetric(relativeTo: .caption2) private var unitSize: CGFloat = 11

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            if hours > 0 {
                unit(hours, L10n.hourShort, padded: false)
                Text(":")
                    .font(MihrabFont.countdown(colonSize))
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
                .font(MihrabFont.countdown(digitSize))
                .foregroundStyle(MihrabColor.mint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText(countsDown: true))
                .animation(reduceMotion ? nil : .snappy(duration: 0.35), value: value)
            Text(label)
                .font(.system(size: unitSize, weight: .semibold, design: .rounded))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(MihrabColor.brass)
        }
    }
}

/// Flat Fitness-style ring. No glass, no scale — the stroke must stay a clean circle.
private struct BreathingRing: View {
    let progress: Double
    var diameter: CGFloat = 216
    var accent: Color = MihrabColor.emerald
    let reduceMotion: Bool

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
                    .offset(y: -diameter / 2)
                    .rotationEffect(.degrees(progress * 360))
                    .shadow(color: MihrabColor.sprout.opacity(0.7), radius: 5)
            }
        }
        .frame(width: diameter, height: diameter)
        .padding(Self.lineWidth / 2)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.9), value: progress)
        .allowsHitTesting(false)
    }
}

// MARK: - Schedule block

/// Secondary weight by design: a horizontal strip of prayers, one line of
/// summary, and — only when it has something honest to say — a provenance
/// badge. No card, no glass; the hero above it must stay the loudest thing.
struct TodayScheduleBlock: View {
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
        VStack(spacing: 10) {
            PrayerStrip()

            if repository.today != nil {
                summaryLine
                    .padding(.horizontal, 22)
            }

            TodayProvenanceBadge()
                .padding(.horizontal, 22)
        }
    }

    private var summaryLine: some View {
        HStack(spacing: 8) {
            Image(systemName: "checklist")
                .font(.caption2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(MihrabColor.brass)

            Text(remainingPrayers > 0
                 ? L10n.homePrayersLeft(remainingPrayers)
                 : L10n.homeAllPrayersDone)

            if let daylight {
                Circle()
                    .fill(MihrabColor.textTertiary)
                    .frame(width: 2.5, height: 2.5)
                Text(L10n.homeDaylight(daylight.hours, daylight.minutes))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .font(.footnote.weight(.medium))
        .foregroundStyle(MihrabColor.textSecondary)
        .accessibilityElement(children: .combine)
    }
}

/// "Calculated on device" / "Last updated …". Shown only when it changes what
/// the user should believe — never as decoration, never as a warning.
struct TodayProvenanceBadge: View {
    @Environment(PrayerTimesRepository.self) private var repository

    /// Anything fresher than this is simply current; saying so would be noise.
    private static let staleAfter: TimeInterval = 12 * 60 * 60

    private var isStale: Bool {
        guard let last = repository.lastSuccessfulRefresh else { return repository.today != nil }
        return Date().timeIntervalSince(last) > Self.staleAfter
    }

    private var caption: String? {
        guard repository.today != nil else { return nil }
        if repository.isUsingOfflineEngine { return L10n.homeOnDeviceBadge }
        guard isStale else { return nil }
        guard let last = repository.lastSuccessfulRefresh else { return nil }
        return L10n.homeLastUpdated(last.formatted(.relative(presentation: .named)))
    }

    var body: some View {
        if let caption {
            HStack(spacing: 6) {
                Image(systemName: repository.isUsingOfflineEngine ? "cpu" : "clock.arrow.circlepath")
                    .font(.caption2)
                    .symbolRenderingMode(.hierarchical)
                Text(caption)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }
            .font(.caption)
            .foregroundStyle(MihrabColor.textTertiary)
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Prayer strip

struct PrayerStrip: View {
    @Environment(PrayerTimesRepository.self) private var repository
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ScaledMetric(relativeTo: .caption) private var pillWidth: CGFloat = 78
    @ScaledMetric(relativeTo: .caption) private var pillHeight: CGFloat = 88

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
        .frame(width: pillWidth, height: pillHeight)
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

/// Five taps a day, the week behind them, and the streak they build. The week
/// strip turns the streak from a number into a pattern — and an empty day
/// stays empty, never a reproach.
struct PrayerLogCard: View {
    @Environment(PrayerTimesRepository.self) private var repository
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var store = PrayerLogStore.shared

    @ScaledMetric(relativeTo: .body) private var markerSize: CGFloat = 40
    @ScaledMetric(relativeTo: .caption2) private var markerLabelSize: CGFloat = 10

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

            mihrabHairline()

            WeekStreakStrip(days: store.recentDays(), accent: theme.accent)

            HStack(spacing: 8) {
                Image(systemName: store.streak > 0 ? "flame.fill" : "flame")
                    .font(.footnote)
                    .foregroundStyle(store.streak > 0 ? MihrabColor.brass : MihrabColor.textTertiary)
                    .symbolRenderingMode(.hierarchical)
                Text(store.streak > 0 ? L10n.homeStreakDays(store.streak) : L10n.homeStreakStart)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(store.streak > 0 ? MihrabColor.textPrimary : MihrabColor.textSecondary)
                Spacer()

                // Quiet brass chip — only once there is a real number to show.
                let owed = QadaStore.shared.totalRemaining
                if owed > 0 {
                    Text(L10n.homeQadaOwed(owed))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(MihrabColor.brass)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(MihrabColor.brass.opacity(0.14)))
                }
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
                        .font(.system(size: markerSize * (isLogged ? 0.375 : 0.325), weight: .semibold))
                        .foregroundStyle(isLogged ? .white : MihrabColor.textSecondary)
                        .symbolRenderingMode(.hierarchical)
                        .contentTransition(.symbolEffect)
                }
                .frame(width: markerSize, height: markerSize)

                Text(prayer.shortName)
                    .font(.system(size: markerLabelSize, weight: .semibold))
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

/// Seven days as seven small bars. Full days fill; partial days fill by the
/// fraction actually prayed; empty days are just an outline.
struct WeekStreakStrip: View {
    let days: [PrayerLogStore.DaySummary]
    var accent: Color = MihrabColor.emerald

    @ScaledMetric(relativeTo: .caption2) private var barHeight: CGFloat = 26

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.homeWeekCaps)
                .ornamentalCaps()

            HStack(spacing: 6) {
                ForEach(days) { day in
                    bar(for: day)
                }
            }
        }
    }

    private func bar(for day: PrayerLogStore.DaySummary) -> some View {
        let fraction = day.total > 0 ? Double(day.completed) / Double(day.total) : 0
        let weekday = day.date.formatted(
            .dateTime.weekday(.narrow).locale(Locale(identifier: L10n.localeIdentifier))
        )

        return VStack(spacing: 5) {
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(MihrabColor.moss.opacity(0.7))
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(day.isComplete ? accent : accent.opacity(0.55))
                        .frame(height: max(geo.size.height * fraction, fraction > 0 ? 4 : 0))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(MihrabColor.mint.opacity(day.isComplete ? 0.45 : 0.16), lineWidth: 1)
                }
            }
            .frame(height: barHeight)

            Text(weekday)
                .font(.caption2)
                .foregroundStyle(MihrabColor.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.homeWeekDayA11y(
            day.date.formatted(
                .dateTime.weekday(.wide).locale(Locale(identifier: L10n.localeIdentifier))
            ),
            day.completed,
            day.total
        )))
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
            if !reduceMotion && !MihrabPower.isLowPowerMode {
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

/// Shown only before the very first schedule lands, and only where the schedule
/// actually goes — the log, the hadith and dhikr do not wait for the network.
struct TodayHeroSkeleton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shimmer = false

    @ScaledMetric(relativeTo: .largeTitle) private var ringDiameter: CGFloat = 216

    private var motionOff: Bool { reduceMotion || MihrabPower.isLowPowerMode }

    var body: some View {
        VStack(spacing: 18) {
            // A ring silhouette, so even the skeleton is recognisably Mihrab.
            Circle()
                .strokeBorder(MihrabColor.mint.opacity(shimmer ? 0.22 : 0.10), lineWidth: 10)
                .frame(width: ringDiameter, height: ringDiameter)

            RoundedRectangle(cornerRadius: MihrabSpace.pillRadius, style: .continuous)
                .fill(MihrabColor.moss.opacity(shimmer ? 0.75 : 0.45))
                .frame(height: MihrabSpace.hit)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .mihrabSolidCard(cornerRadius: MihrabSpace.cardRadius)
        .onAppear {
            guard !motionOff else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text(L10n.loadingTimes))
    }
}

// MARK: - Daily hadith card

struct DailyHadithCard: View {
    let onTap: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hadith = BundledContent.hadith()

    @ScaledMetric(relativeTo: .title3) private var quoteSize: CGFloat = 24

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
                        .font(MihrabFont.quoteItalic(quoteSize))
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
            .padding(24)
            .mihrabShaderPanel(.lantern, cornerRadius: MihrabSpace.cardRadius, opacity: 0.22)
            .mihrabCard(interactive: true)
        }
        .pressable(reduceMotion)
    }
}

// MARK: - Quick action tile

/// Kept as a component even though Today no longer stacks a 2×2 grid of them —
/// sheets elsewhere still want a plain, tappable row.
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

// MARK: - Ramadan band

/// During Ramadan this sits at the very top of Today — the season's own line,
/// above the greeting's fold, instead of an eighth card halfway down.
struct RamadanBand: View {
    let onTap: () -> Void
    @Environment(PrayerTimesRepository.self) private var repository
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                HStack(spacing: 12) {
                    Image(systemName: "moon.stars.fill")
                        .font(.title3)
                        .foregroundStyle(MihrabColor.ramadanGold)
                        .symbolRenderingMode(.hierarchical)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(L10n.ramadan)
                                .ornamentalCaps(MihrabColor.ramadanGold)
                            if let hijri = repository.today?.hijriDate, hijri.month == 9 {
                                Text("· \(hijri.day)")
                                    .ornamentalCaps(MihrabColor.ramadanGold)
                            }
                        }

                        if let maghrib = repository.today?.time(for: .maghrib), maghrib > context.date {
                            HStack(spacing: 4) {
                                Text(L10n.iftarLeft(maghrib.formatted(date: .omitted, time: .shortened)))
                                CountdownText(from: context.date, to: maghrib, finished: "0:00")
                                Text(L10n.left)
                            }
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(MihrabColor.textPrimary)
                        } else if let fajr = repository.tomorrow?.time(for: .fajr) {
                            Text(L10n.suhoorEnds(fajr.formatted(date: .omitted, time: .shortened)))
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(MihrabColor.textPrimary)
                        }
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(MihrabColor.textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(minHeight: MihrabSpace.hit)
                .background {
                    RoundedRectangle(cornerRadius: MihrabSpace.rowRadius, style: .continuous)
                        .fill(MihrabColor.ramadanViolet.opacity(0.62))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: MihrabSpace.rowRadius, style: .continuous)
                        .strokeBorder(MihrabColor.ramadanGold.opacity(0.42), lineWidth: 1)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .pressable(reduceMotion)
    }
}

// MARK: - Religious day banner

struct ReligiousDayBanner: View {
    let day: ReligiousDay
    let daysUntil: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.footnote)
                .foregroundStyle(MihrabColor.brass)
            Text(L10n.inDays(day.localizedName, daysUntil))
                .font(.footnote.weight(.medium))
                .foregroundStyle(MihrabColor.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: MihrabSpace.hit)
        .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius, stroke: MihrabColor.brass.opacity(0.45))
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
            .padding(.vertical, 12)
            .frame(minHeight: 56)
            .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
        }
        .pressable(reduceMotion)
    }
}
