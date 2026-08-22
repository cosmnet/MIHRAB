import SwiftUI

struct TimesView: View {
    @Environment(PrayerTimesRepository.self) private var repository
    @Environment(LocationManager.self) private var locationManager
    @Environment(AppSettings.self) private var settings
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var dayOffset = 0
    @State private var displayedDay: DayPrayerTimes?
    @State private var showMonthly = false
    @State private var showSettings = false
    @State private var appeared = false
    @State private var isLoadingDay = false

    private var displayedDate: Date {
        Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground(ramadanMode: theme.isRamadanMode)

                ScrollView {
                    VStack(spacing: 20) {
                        header
                        dayPager

                        if let displayedDay {
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
                    .padding(.horizontal, 16)
                    .mihrabTabGutter()
                }
                .mihrabTabScroll()
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
            .buttonStyle(.plain)
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
            .buttonStyle(.plain)
            .accessibilityHint(Text(L10n.settings))
        }
    }

    // MARK: - Day pager

    private var dayPager: some View {
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
                .contentTransition(.numericText())

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
                .accessibilityLabel(Text(L10n.nextDay))
            }

            if dayOffset != 0 {
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
        VStack(spacing: 8) {
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

                if isCurrent {
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
                .rotationEffect(.degrees(bellRinging ? 15 : 0))
                .animation(
                    bellRinging
                        ? .easeInOut(duration: 0.1).repeatCount(4, autoreverses: true)
                        : .default,
                    value: bellRinging
                )
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
