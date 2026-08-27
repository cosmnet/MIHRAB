import SwiftUI

struct TimesView: View {
    @Environment(PrayerTimesRepository.self) private var repository
    @Environment(LocationManager.self) private var locationManager
    @Environment(AppSettings.self) private var settings
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Day list or month table. One screen, two densities.
    enum Mode: String, CaseIterable, Identifiable {
        case day, month
        var id: String { rawValue }
        var localizedName: String { self == .day ? L10n.tmzModeDay : L10n.tmzModeMonth }
    }

    @State private var dayOffset = 0
    @State private var displayedDay: DayPrayerTimes?
    @State private var showMonthly = false
    @State private var showSettings = false
    @State private var appeared = false
    @State private var isLoadingDay = false
    @State private var mode: Mode = .day
    /// The prayer whose transparency panel is open.
    @State private var detailPrayer: Prayer?
    /// The day after `displayedDate`, for the night divisions.
    @State private var followingDay: DayPrayerTimes?

    private var displayedDate: Date {
        Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MihrabBackdrop(surface: .times, ramadanMode: theme.isRamadanMode)

                ScrollView {
                    VStack(spacing: 14) {
                        contextRow

                        if mode == .month {
                            InlineMonthTable(anchorDate: displayedDate) { showMonthly = true }
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        } else {
                            dayNavigator

                            if let displayedDay {
                                if isFriday { fridayBanner }
                                nextUpBanner(for: displayedDay)
                                prayerRows(for: displayedDay)
                                TimesFreshnessBadge(
                                    isOffline: repository.isUsingOfflineEngine,
                                    lastRefresh: repository.lastSuccessfulRefresh
                                )
                                SunArcView(times: displayedDay, date: displayedDate)
                                    .padding(.top, 4)
                                if let coordinate = locationManager.effectiveCoordinate {
                                    MakruhTimesCard(day: displayedDay,
                                                    coordinate: coordinate,
                                                    highlightsNow: dayOffset == 0)
                                }
                                NightDivisionsCard(day: displayedDay,
                                                   tomorrow: nightFollowingDay)
                            } else if repository.engineUnavailable {
                                // Polar day / polar night: the engine has no
                                // sunrise to anchor to. Say that, do not spin.
                                MihrabEmptyState(
                                    symbol: "sun.horizon",
                                    title: L10n.tmxEngineUnavailableTitle,
                                    message: L10n.tmxEngineUnavailableBody,
                                    retryTitle: L10n.settings
                                ) { showSettings = true }
                                .padding(.top, 24)
                            } else if isLoadingDay || repository.isLoading {
                            MihrabEmptyState(
                                symbol: "clock.arrow.2.circlepath",
                                title: L10n.loadingTimes,
                                message: L10n.fetchingSchedule
                            )
                            .padding(.top, 24)
                        } else if locationManager.effectiveCoordinate == nil {
                            MihrabEmptyState(
                                symbol: "location.slash",
                                title: L10n.locationNeeded,
                                message: L10n.locationNeededBody,
                                retryTitle: L10n.enableLocation
                            ) {
                                locationManager.requestAuthorization()
                                locationManager.startUpdating()
                            }
                            .padding(.top, 24)
                        } else {
                            MihrabEmptyState(
                                symbol: "wifi.exclamationmark",
                                title: L10n.timesUnavailable,
                                message: L10n.checkConnection,
                                retryTitle: L10n.tryAgain
                            ) {
                                Task {
                                    await repository.refresh()
                                    await loadDay()
                                }
                            }
                            .padding(.top, 24)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .animation(reduceMotion ? nil : MihrabMotion.standardAnimation, value: mode)
                }
                .mihrabTabScroll()
                .mihrabTabSafeContent()
                .refreshable {
                    await repository.refresh()
                    await loadDay()
                }
            }
            .navigationTitle(L10n.prayerTimesTitle)
            // The tab is already called "Times". A 96pt large-title block on top
            // of that pushed the first prayer row off a small screen, which is
            // the one thing this tab exists to show.
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // One control instead of two: the lone calendar icon and the
                    // separate day/month segment were the same decision spelled
                    // twice. The full, shareable table still opens from inside
                    // the month view.
                    Button {
                        HapticsEngine.shared.light()
                        withAnimation(reduceMotion ? nil : MihrabMotion.snappyAnimation) {
                            mode = mode == .day ? .month : .day
                        }
                    } label: {
                        Label(mode == .day ? L10n.tmzModeMonth : L10n.tmzModeDay,
                              systemImage: mode == .day ? "calendar" : "list.bullet")
                            .labelStyle(.titleAndIcon)
                            .font(.subheadline.weight(.semibold))
                    }
                    .tint(theme.accent)
                    .accessibilityAddTraits(mode == .month ? [.isButton, .isSelected] : .isButton)
                }
            }
            .sheet(isPresented: $showMonthly) {
                MonthlyTimesView(anchorDate: displayedDate)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(item: $detailPrayer) { prayer in
                if let displayedDay {
                    PrayerDetailSheet(
                        prayer: prayer,
                        day: displayedDay,
                        resolution: repository.resolution(for: displayedDate)
                    ) {
                        // Source or ± correction changed: everything downstream
                        // (this day, the widgets, the notifications) has to be
                        // rebuilt, not just re-rendered.
                        Task {
                            await repository.refresh()
                            await loadDay()
                            await NotificationEngine.shared.rescheduleAll()
                        }
                    }
                }
            }
        }
        .task(id: dayOffset) { await loadDay() }
        .onChange(of: repository.today?.id) { _, _ in
            if dayOffset == 0 { displayedDay = repository.today }
        }
        .onAppear {
            withAnimation { appeared = true }
        }
    }

    // MARK: - Context row

    /// Everything that used to be a two-column header block — city, hijri date,
    /// calculation method — collapsed into one 48pt tappable line. It answers
    /// "where and by whose reckoning", which is context, not content.
    private var contextRow: some View {
        Button { showSettings = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.footnote)
                    .foregroundStyle(MihrabColor.mint)
                    .accessibilityHidden(true)

                Text(locationManager.effectiveCityName.isEmpty
                     ? L10n.locating
                     : locationManager.effectiveCityName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MihrabColor.textPrimary)
                    .lineLimit(1)
                    .layoutPriority(2)

                if let hijri = displayedDay?.hijriDate {
                    Text(verbatim: "·")
                        .font(.subheadline)
                        .foregroundStyle(MihrabColor.textSecondary)
                        .accessibilityHidden(true)
                    Text(hijri.formatted)
                        .font(.subheadline)
                        .foregroundStyle(MihrabColor.brass)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .layoutPriority(1)
                }

                Spacer(minLength: 4)

                // City and Hijri date always win the row; a long method name
                // truncated to one letter ("M…") told the reader nothing, so it
                // is dropped whenever it cannot be shown whole. It is still on
                // the prayer detail sheet and in Settings, one tap away.
                ViewThatFits(in: .horizontal) {
                    Text(settings.calculationMethod.localizedName)
                        .font(.footnote)
                        .foregroundStyle(MihrabColor.textSecondary)
                        .lineLimit(1)
                    Color.clear.frame(width: 0, height: 0)
                }
                .fixedSize(horizontal: true, vertical: false)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MihrabColor.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 48)
            .contentShape(Capsule())
            .background(Capsule().fill(MihrabColor.moss))
            .overlay {
                Capsule().strokeBorder(MihrabColor.mint.opacity(0.28), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .pressable(reduceMotion)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text(L10n.settings))
    }

    // MARK: - Next up

    /// The one line people actually open this tab for: what is next, and how
    /// long is left. Only shown for today — a countdown on a past day is a lie.
    @ViewBuilder
    private func nextUpBanner(for day: DayPrayerTimes) -> some View {
        if dayOffset == 0,
           let next = day.nextPrayer(after: Date(), tomorrow: repository.tomorrow) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                HStack(spacing: 12) {
                    Image(systemName: next.prayer.symbolName)
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(theme.accent)
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.tmzNextCaps)
                            .ornamentalCaps()
                        Text(next.prayer.localizedNamazName)
                            .font(.headline)
                            .foregroundStyle(MihrabColor.textPrimary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 2) {
                        CountdownText(from: context.date, to: next.date)
                            .font(MihrabFont.timeDisplay(22))
                            .foregroundStyle(MihrabColor.mint)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(next.date, format: .dateTime.hour().minute())
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(MihrabColor.textSecondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .mihrabShaderPanel(.caustics, cornerRadius: MihrabSpace.rowRadius, opacity: 0.22)
                .mihrabSolidCard(
                    cornerRadius: MihrabSpace.rowRadius,
                    stroke: MihrabColor.mint.opacity(0.4)
                )
                .accessibilityElement(children: .combine)
            }
        }
    }

    // MARK: - Day navigator

    /// One line, three visible targets: back a day, the day itself (tap to
    /// return to today), forward a day. The old two-tier control — a
    /// yesterday/today/tomorrow segment *above* an arrow row that did the same
    /// job — cost 88pt to say one thing twice.
    private var dayNavigator: some View {
        HStack(spacing: 10) {
            navArrow(-1, symbol: "chevron.left", label: L10n.previousDay)

            Button {
                guard dayOffset != 0 else { return }
                HapticsEngine.shared.light()
                withAnimation(reduceMotion ? nil : MihrabMotion.snappyAnimation) { dayOffset = 0 }
            } label: {
                HStack(spacing: 8) {
                    Text(dayName)
                        .font(.headline)
                        .foregroundStyle(MihrabColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(displayedDate, format: .dateTime.day().month(.wide).locale(L10n.appLocale))
                        .font(.subheadline)
                        .foregroundStyle(MihrabColor.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    if dayOffset != 0 {
                        // A visible way back. "Today" used to appear only past
                        // ±2 days, and only as an 11pt caption.
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(theme.accent)
                            .accessibilityHidden(true)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(dayOffset == 0)
            .accessibilityLabel(Text(accessibleDayLabel))
            .accessibilityHint(dayOffset == 0 ? Text("") : Text(L10n.today))

            navArrow(1, symbol: "chevron.right", label: L10n.nextDay)
        }
        .id(dayOffset)
        .transition(.opacity)
        .gesture(
            DragGesture(minimumDistance: 30).onEnded { value in
                if value.translation.width < -40 { shiftDay(1) }
                else if value.translation.width > 40 { shiftDay(-1) }
            }
        )
    }

    private func navArrow(_ delta: Int, symbol: String, label: String) -> some View {
        Button { shiftDay(delta) } label: {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(MihrabColor.textPrimary)
                .frame(width: 52, height: 52)
                .background(Circle().fill(MihrabColor.moss))
                .overlay {
                    Circle().strokeBorder(MihrabColor.mint.opacity(0.28), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .pressable(reduceMotion)
        .accessibilityLabel(Text(label))
    }

    /// "Yesterday" / "Today" / "Tomorrow" close in, the weekday further out.
    private var dayName: String {
        switch dayOffset {
        case -1: L10n.tmzYesterday
        case 0: L10n.today
        case 1: L10n.tmzTomorrow
        default: displayedDate.formatted(.dateTime.weekday(.wide).locale(L10n.appLocale))
        }
    }

    private var accessibleDayLabel: String {
        let full = displayedDate.formatted(Date.FormatStyle(date: .long).locale(L10n.appLocale))
        return "\(dayName), \(full)"
    }

    private func shiftDay(_ delta: Int) {
        HapticsEngine.shared.light()
        withAnimation(MihrabMotion.snappyAnimation) { dayOffset += delta }
    }

    // MARK: - Prayer rows — no GlassEffectContainer, no stacked liquid glass

    private func prayerRows(for day: DayPrayerTimes) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tmzScheduleCaps)
                .ornamentalCaps()
                .padding(.leading, 6)
                .padding(.bottom, 2)

            ForEach(Array(Prayer.allCases.enumerated()), id: \.element) { index, prayer in
                PrayerRow(
                    prayer: prayer,
                    time: day.time(for: prayer),
                    isCurrent: isCurrent(prayer),
                    isNext: isNext(prayer),
                    isPassed: isPassed(prayer),
                    onOpenDetail: { detailPrayer = prayer }
                )
                .cardEntrance(index: index, appeared: appeared, reduceMotion: reduceMotion)
            }

            Text(L10n.tmxDetailHint)
                .font(.caption)
                .foregroundStyle(MihrabColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 2)
        }
        .padding(12)
        .mihrabCardScene("times-bg", opacity: 0.4)
        .id(dayOffset)
        .transition(.opacity.combined(with: .offset(y: 8)))
    }

    // MARK: - Friday

    private var isFriday: Bool {
        Calendar.current.component(.weekday, from: displayedDate) == 6
    }

    /// Cuma is the one day of the week whose öğle means something different.
    private var fridayBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "star.circle.fill")
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(MihrabColor.brass)
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.tmxFridayBadge)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MihrabColor.brass)
                Text(L10n.tmxJumuah)
                    .font(.caption)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius,
                         stroke: MihrabColor.brass.opacity(0.4))
        .accessibilityElement(children: .combine)
    }

    private func isCurrent(_ prayer: Prayer) -> Bool {
        guard dayOffset == 0, let today = displayedDay else { return false }
        return today.previousPrayer(before: Date())?.prayer == prayer
    }

    private func isNext(_ prayer: Prayer) -> Bool {
        guard dayOffset == 0, let today = displayedDay else { return false }
        return today.nextPrayer(after: Date(), tomorrow: repository.tomorrow)?.prayer == prayer
    }

    private func isPassed(_ prayer: Prayer) -> Bool {
        guard dayOffset == 0, let time = displayedDay?.time(for: prayer) else { return false }
        return time <= Date() && !isCurrent(prayer)
    }

    /// The night after the displayed day ends at *its* imsak, so the thirds
    /// need tomorrow relative to the page, not to the wall clock.
    private var nightFollowingDay: DayPrayerTimes? {
        dayOffset == 0 ? repository.tomorrow : followingDay
    }

    private func loadDay() async {
        isLoadingDay = displayedDay == nil
        if dayOffset == 0, let today = repository.today {
            displayedDay = today
            followingDay = repository.tomorrow
            isLoadingDay = false
            return
        }
        displayedDay = await repository.day(for: displayedDate)
        let next = Calendar.current.date(byAdding: .day, value: 1, to: displayedDate) ?? displayedDate
        followingDay = await repository.day(for: next)
        isLoadingDay = false
    }
}

// MARK: - Prayer row

struct PrayerRow: View {
    let prayer: Prayer
    let time: Date?
    let isCurrent: Bool
    let isNext: Bool
    let isPassed: Bool
    /// Opens the transparency panel. The row used to swallow the whole tap for
    /// the bell, which left "where did this time come from?" unreachable.
    var onOpenDetail: () -> Void = {}

    @Environment(AppSettings.self) private var settings
    @State private var bellRinging = false

    private var notificationOn: Bool {
        settings.isNotificationEnabled(for: prayer)
    }

    var body: some View {
        rowContent
            .accessibilityElement(children: .combine)
            .accessibilityLabel(rowAccessibility)
            .accessibilityHint(Text(L10n.tmxDetailHint))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: Text(L10n.tmxNotificationToggle)) {
                guard prayer.isNotifiable else { return }
                toggleNotification()
            }
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            Image(systemName: prayer.symbolName)
                .font(.title3)
                .foregroundStyle(isNext ? MihrabColor.mint : MihrabColor.textSecondary)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                // Semantic, so it grows with Dynamic Type instead of staying
                // pinned at 18pt for a reader who set the text larger.
                Text(prayer.localizedName)
                    .font(.title3.weight(isCurrent ? .bold : .semibold))
                    .foregroundStyle(isCurrent ? MihrabColor.brass : MihrabColor.textPrimary)
                    .lineLimit(1)

                if isCurrent, let time, Date().timeIntervalSince(time) < 20 * 60 {
                    Text(L10n.now)
                        .font(.caption.weight(.semibold))
                        .tracking(0.6)
                        .foregroundStyle(MihrabColor.brass)
                        .lineLimit(1)
                } else if isNext, let time {
                    CountdownText(from: .now, to: time)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(MihrabColor.mint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else if !L10n.isArabic {
                    Text(prayer.arabicName)
                        .font(MihrabFont.arabic(15))
                        .foregroundStyle(MihrabColor.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            timeLabel
                .frame(width: MihrabSpace.timeColumn, alignment: .trailing)
                .layoutPriority(1)

            // Two targets, both ≥ 44pt: the bell toggles the alert, the rest of
            // the row opens the provenance panel.
            Button(action: toggleNotification) {
                Image(systemName: notificationOn ? "bell.fill" : "bell.slash")
                    .font(.body)
                    .foregroundStyle(notificationOn ? MihrabColor.brass : MihrabColor.textSecondary)
                    .symbolEffect(.wiggle, options: .speed(3), value: bellRinging)
                    .frame(width: MihrabSpace.hit, height: MihrabSpace.hit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(prayer.isNotifiable ? 1 : 0)
            .disabled(!prayer.isNotifiable)
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: MihrabSpace.rowHeight)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpenDetail)
        .opacity(isPassed ? 0.72 : 1)
        .mihrabSolidCard(
            cornerRadius: MihrabSpace.rowRadius,
            fill: MihrabColor.moss,
            stroke: rowStroke
        )
    }

    @ViewBuilder
    private var timeLabel: some View {
        if let time {
            Text(time, format: .dateTime.hour().minute())
                .font(MihrabFont.timeDisplay(28))
                .foregroundStyle(timeColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
        } else {
            Text("–")
                .font(MihrabFont.timeDisplay(28))
                .foregroundStyle(MihrabColor.textSecondary)
                .lineLimit(1)
        }
    }

    private var timeColor: Color {
        if isCurrent { return MihrabColor.brass }
        if isNext { return MihrabColor.mint }
        if isPassed { return MihrabColor.textSecondary }
        return MihrabColor.textPrimary
    }

    private var rowStroke: Color {
        if isCurrent { return MihrabColor.brass.opacity(0.5) }
        if isNext { return MihrabColor.mint.opacity(0.42) }
        return MihrabColor.mint.opacity(0.22)
    }

    private func toggleNotification() {
        settings.toggleNotification(for: prayer)
        HapticsEngine.shared.light()
        withAnimation(MihrabMotion.snappyAnimation) { bellRinging = true }
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            bellRinging = false
            await NotificationEngine.shared.rescheduleAll()
        }
    }

    private var rowAccessibility: String {
        var parts = [prayer.localizedName]
        if let time {
            parts.append(time.formatted(date: .omitted, time: .shortened))
        }
        if isCurrent { parts.append(L10n.now) }
        if prayer.isNotifiable {
            parts.append(notificationOn ? L10n.alertsOn : L10n.alertsOff)
        }
        return parts.joined(separator: ", ")
    }
}
