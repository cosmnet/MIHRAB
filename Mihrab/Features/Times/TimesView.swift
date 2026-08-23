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

    private var displayedDate: Date {
        Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MihrabBackdrop(surface: .times, ramadanMode: theme.isRamadanMode)

                ScrollView {
                    VStack(spacing: 20) {
                        header
                        modePicker

                        if mode == .month {
                            InlineMonthTable(anchorDate: displayedDate) { showMonthly = true }
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        } else {
                            dayPager

                            if let displayedDay {
                                nextUpBanner(for: displayedDay)
                                prayerRows(for: displayedDay)
                                SunArcView(times: displayedDay, date: displayedDate)
                                    .padding(.top, 4)
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.month, systemImage: "calendar") { showMonthly = true }
                        .tint(theme.accent)
                }
            }
            .sheet(isPresented: $showMonthly) {
                MonthlyTimesView(anchorDate: displayedDate)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
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

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Button { showSettings = true } label: {
                Label(
                    locationManager.effectiveCityName.isEmpty
                        ? L10n.locating
                        : locationManager.effectiveCityName,
                    systemImage: "location.fill"
                )
                .font(.subheadline.weight(.medium))
                .foregroundStyle(MihrabColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(minHeight: MihrabSpace.hit)
                .background(Capsule().fill(MihrabColor.moss))
                .overlay {
                    Capsule().strokeBorder(MihrabColor.mint.opacity(0.28), lineWidth: 1)
                }
            }
            .pressable(reduceMotion)
            .accessibilityHint(Text(L10n.settings))

            Spacer(minLength: 8)

            Button { showSettings = true } label: {
                VStack(alignment: .trailing, spacing: 3) {
                    if let hijri = displayedDay?.hijriDate {
                        Text(hijri.formatted)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MihrabColor.brass)
                            .lineLimit(1)
                    }
                    Text(settings.calculationMethod.localizedName)
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .pressable(reduceMotion)
            .accessibilityHint(Text(L10n.settings))
        }
    }

    // MARK: - Mode picker

    /// Day ⇄ month without leaving the screen. A sheet still exists for the
    /// full, shareable table — this is the glance.
    private var modePicker: some View {
        HStack(spacing: 6) {
            ForEach(Mode.allCases) { candidate in
                let selected = candidate == mode
                Button {
                    guard !selected else { return }
                    HapticsEngine.shared.light()
                    withAnimation(reduceMotion ? nil : MihrabMotion.snappyAnimation) { mode = candidate }
                } label: {
                    Text(candidate.localizedName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selected ? .white : MihrabColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 38)
                        .background {
                            if selected {
                                Capsule().fill(theme.accent)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(4)
        .background(Capsule().fill(MihrabColor.moss.opacity(0.9)))
        .overlay { Capsule().strokeBorder(MihrabColor.mint.opacity(0.2), lineWidth: 1) }
        .frame(maxWidth: 260)
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
                .padding(.vertical, 14)
                .mihrabShaderPanel(.caustics, cornerRadius: MihrabSpace.rowRadius, opacity: 0.22)
                .mihrabSolidCard(
                    cornerRadius: MihrabSpace.rowRadius,
                    stroke: MihrabColor.mint.opacity(0.4)
                )
                .accessibilityElement(children: .combine)
            }
        }
    }

    // MARK: - Day pager

    /// Yesterday / today / tomorrow as one tap, anything further as arrows or
    /// a horizontal drag.
    private var dayPager: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach([-1, 0, 1], id: \.self) { offset in
                    let selected = dayOffset == offset
                    Button {
                        guard !selected else { return }
                        HapticsEngine.shared.light()
                        withAnimation(reduceMotion ? nil : MihrabMotion.snappyAnimation) { dayOffset = offset }
                    } label: {
                        Text(relativeDayName(offset))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(selected ? MihrabColor.textPrimary : MihrabColor.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 34)
                            .background {
                                Capsule().fill(selected ? MihrabColor.moss : Color.clear)
                            }
                            .overlay {
                                Capsule().strokeBorder(
                                    selected ? MihrabColor.mint.opacity(0.4) : .clear,
                                    lineWidth: 1
                                )
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
                }
            }

            legacyDayPager
        }
    }

    private func relativeDayName(_ offset: Int) -> String {
        switch offset {
        case -1: L10n.tmzYesterday
        case 1: L10n.tmzTomorrow
        default: L10n.today
        }
    }

    private var legacyDayPager: some View {
        VStack(spacing: 8) {
            HStack {
                Button { shiftDay(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(MihrabColor.textPrimary)
                        .frame(width: MihrabSpace.hit, height: MihrabSpace.hit)
                        .background(Circle().fill(MihrabColor.moss))
                        .overlay {
                            Circle().strokeBorder(MihrabColor.mint.opacity(0.28), lineWidth: 1)
                        }
                }
                .pressable(reduceMotion)
                .accessibilityLabel(Text(L10n.previousDay))

                Spacer()

                VStack(spacing: 2) {
                    Text(displayedDate, format: .dateTime.weekday(.wide))
                        .font(.headline)
                        .foregroundStyle(MihrabColor.textPrimary)
                    Text(displayedDate, format: .dateTime.day().month(.wide))
                        .font(.subheadline)
                        .foregroundStyle(MihrabColor.textSecondary)
                }
                .id(dayOffset)
                .transition(.offset(x: 12).combined(with: .opacity))

                Spacer()

                Button { shiftDay(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundStyle(MihrabColor.textPrimary)
                        .frame(width: MihrabSpace.hit, height: MihrabSpace.hit)
                        .background(Circle().fill(MihrabColor.moss))
                        .overlay {
                            Circle().strokeBorder(MihrabColor.mint.opacity(0.28), lineWidth: 1)
                        }
                }
                .pressable(reduceMotion)
                .accessibilityLabel(Text(L10n.nextDay))
            }

            if abs(dayOffset) > 1 {
                Button(L10n.today) {
                    withAnimation(MihrabMotion.snappyAnimation) { dayOffset = 0 }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.accent)
                .frame(minHeight: 28)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 30).onEnded { value in
                if value.translation.width < -40 { shiftDay(1) }
                else if value.translation.width > 40 { shiftDay(-1) }
            }
        )
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
                    isPassed: isPassed(prayer)
                )
                .cardEntrance(index: index, appeared: appeared, reduceMotion: reduceMotion)
            }
        }
        .padding(12)
        .mihrabCardScene("times-bg", opacity: 0.4)
        .id(dayOffset)
        .transition(.opacity.combined(with: .offset(y: 8)))
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

    private func loadDay() async {
        isLoadingDay = displayedDay == nil
        if dayOffset == 0, let today = repository.today {
            displayedDay = today
            isLoadingDay = false
            return
        }
        displayedDay = await repository.day(for: displayedDate)
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

    @Environment(AppSettings.self) private var settings
    @State private var bellRinging = false

    private var notificationOn: Bool {
        settings.isNotificationEnabled(for: prayer)
    }

    var body: some View {
        Group {
            if prayer.isNotifiable {
                Button(action: toggleNotification) {
                    rowContent
                }
                .buttonStyle(.plain)
            } else {
                rowContent
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rowAccessibility)
        .accessibilityHint(prayer.isNotifiable ? L10n.toggleAlertsHint : "")
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            Image(systemName: prayer.symbolName)
                .font(.title3)
                .foregroundStyle(isNext ? MihrabColor.mint : MihrabColor.textSecondary)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(prayer.localizedName)
                    .font(.system(size: 18, weight: isCurrent ? .bold : .semibold))
                    .foregroundStyle(isCurrent ? MihrabColor.brass : MihrabColor.textPrimary)
                    .lineLimit(1)

                if isCurrent, let time, Date().timeIntervalSince(time) < 20 * 60 {
                    Text(L10n.now)
                        .font(.caption2.weight(.semibold))
                        .tracking(0.6)
                        .foregroundStyle(MihrabColor.brass)
                        .lineLimit(1)
                } else if isNext, let time {
                    CountdownText(from: .now, to: time)
                        .font(.caption2.monospacedDigit())
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

            Image(systemName: notificationOn ? "bell.fill" : "bell.slash")
                .font(.body)
                .foregroundStyle(notificationOn ? MihrabColor.brass : MihrabColor.textTertiary)
                .symbolEffect(.wiggle, options: .speed(3), value: bellRinging)
                .frame(width: MihrabSpace.hit, height: MihrabSpace.hit)
                .opacity(prayer.isNotifiable ? 1 : 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: MihrabSpace.rowHeight)
        .contentShape(Rectangle())
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
                .foregroundStyle(MihrabColor.textTertiary)
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
