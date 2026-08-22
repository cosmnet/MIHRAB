import SwiftUI

enum AppTab: Hashable {
    case today, times, qibla, deen, dhikr
}

struct RootView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(LocationManager.self) private var locationManager
    @Environment(PrayerTimesRepository.self) private var repository
    @Environment(Theme.self) private var theme
    @State private var selectedTab: AppTab = Self.launchTab

    private static var launchTab: AppTab {
        #if DEBUG
        if CommandLine.arguments.contains("-tabTimes") { return .times }
        if CommandLine.arguments.contains("-tabEsma") { return .deen }
        if CommandLine.arguments.contains("-tabDhikr") { return .dhikr }
        #endif
        return .today
    }

    var body: some View {
        @Bindable var settings = settings
        Group {
            if settings.hasCompletedOnboarding {
                mainTabs
            } else {
                OnboardingView()
            }
        }
        .environment(\.locale, Locale(identifier: L10n.localeIdentifier))
        .task {
            locationManager.startUpdating()
            await repository.refresh()
            theme.update(hijri: repository.today?.hijriDate)
            await NotificationEngine.shared.rescheduleAll()
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
        .tint(theme.accent)
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}
