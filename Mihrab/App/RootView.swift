import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case today, times, qibla, deen, dhikr
}

struct RootView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(LocationManager.self) private var locationManager
    @Environment(PrayerTimesRepository.self) private var repository
    @Environment(Theme.self) private var theme
    @State private var selectedTab: AppTab = Self.launchTab
    @State private var tabTour = CoachMarkController.tabTour

    private static var launchTab: AppTab {
        let args = CommandLine.arguments
        if args.contains(where: { $0 == "-tabTimes" || $0 == "tabTimes" }) { return .times }
        if args.contains(where: { $0 == "-tabEsma" || $0 == "tabEsma" }) { return .deen }
        if args.contains(where: { $0 == "-tabDhikr" || $0 == "tabDhikr" }) { return .dhikr }
        if args.contains(where: { $0 == "-tabQibla" || $0 == "tabQibla" }) { return .qibla }
        return .today
    }

    var body: some View {
        @Bindable var settings = settings
        Group {
            if settings.hasCompletedOnboarding {
                mainTabs
                    .overlay { tabTourOverlay }
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: settings.hasCompletedOnboarding)
        .environment(\.locale, Locale(identifier: L10n.localeIdentifier))
        .task {
            locationManager.startUpdating()
            await SubscriptionManager.shared.refresh()
            await repository.refresh()
            theme.update(hijri: repository.today?.hijriDate)
            await NotificationEngine.shared.rescheduleAll()
            // rescheduleAll() clears every pending request, trial reminders included.
            TrialReminder.ensureScheduled(trialStart: SubscriptionManager.shared.trialStartedAt)
            await LiveActivityManager.shared.update(for: repository.today, tomorrow: repository.tomorrow)
        }
        .onChange(of: locationManager.location) { _, _ in
            Task {
                await repository.refresh()
                theme.update(hijri: repository.today?.hijriDate)
            }
        }
        .onChange(of: settings.calculationMethod) { _, _ in
            Task {
                await repository.refresh()
                await NotificationEngine.shared.rescheduleAll()
                TrialReminder.ensureScheduled(trialStart: SubscriptionManager.shared.trialStartedAt)
            }
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            Tab(L10n.tabToday, systemImage: "house.fill", value: .today) {
                TodayView(selectedTab: $selectedTab)
            }
            Tab(L10n.tabTimes, systemImage: "clock.fill", value: .times) {
                TimesView()
            }
            Tab(L10n.tabQibla, systemImage: "location.north.circle.fill", value: .qibla) {
                QiblaCompassView()
            }
            Tab(L10n.tabEsma, systemImage: "book.fill", value: .deen) {
                DeenView()
            }
            Tab(L10n.tabDhikr, systemImage: "circle.grid.3x3.fill", value: .dhikr) {
                DhikrView()
            }
        }
        .tint(theme.isRamadanMode ? MihrabColor.ramadanGold : settings.accentTheme.color)
        .tabBarMinimizeBehavior(.onScrollDown)
    }

    // MARK: - First-run tab tour

    /// Introduces the five tabs once, right after onboarding. Advancing the tour
    /// also switches tabs so the user sees what is being described.
    private var tabTourOverlay: some View {
        TabBarTourOverlay(
            stops: Self.tourStops,
            controller: tabTour,
            onFocus: { index in
                let tabs = AppTab.allCases
                guard index < tabs.count else { return }
                withAnimation(.easeInOut(duration: 0.25)) { selectedTab = tabs[index] }
            },
            onFinish: {
                withAnimation(.easeInOut(duration: 0.25)) { selectedTab = Self.launchTab }
            }
        )
    }

    private static var tourStops: [TabTourStop] {
        [
            TabTourStop(id: "today", systemImage: "house.fill", title: L10n.tabToday, message: L10n.coachTodayBody),
            TabTourStop(id: "times", systemImage: "clock.fill", title: L10n.tabTimes, message: L10n.coachTimesBody),
            TabTourStop(
                id: "qibla",
                systemImage: "location.north.circle.fill",
                title: L10n.tabQibla,
                message: L10n.coachQiblaBody
            ),
            TabTourStop(id: "deen", systemImage: "book.fill", title: L10n.tabEsma, message: L10n.coachEsmaBody),
            TabTourStop(
                id: "dhikr",
                systemImage: "circle.grid.3x3.fill",
                title: L10n.tabDhikr,
                message: L10n.coachDhikrBody
            ),
        ]
    }
}
