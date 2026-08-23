import SwiftData
import SwiftUI
import WidgetKit

@main
struct MihrabApp: App {
    @State private var settings = AppSettings.shared
    @State private var locationManager = LocationManager.shared
    @State private var repository = PrayerTimesRepository.shared
    @State private var theme = Theme.shared
    @State private var splashFinished = false

    /// Kept alive for the process lifetime — see `KeyValueSync.startObserving`.
    private nonisolated(unsafe) static var cloudObserver: NSObjectProtocol?
    private nonisolated(unsafe) static var quranObserver: NSObjectProtocol?

    init() {
        // Background prayer refresh must register its handlers before the app
        // finishes launching, or BGTaskScheduler rejects them.
        BackgroundRefresh.registerHandlers()
        _ = KeyValueSync.pull()
        // Token must outlive the initialiser; the app runs for the process
        // lifetime, so holding it in a static is the right scope.
        Self.cloudObserver = KeyValueSync.startObserving {
            WidgetCenter.shared.reloadAllTimelines()
        }
        Self.quranObserver = QuranSync.startObserving {}
        // The watch computes its own times; this pushes the settings it needs.
        PhoneWatchBridge.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environment(settings)
                    .environment(locationManager)
                    .environment(repository)
                    .environment(theme)
                    .opacity(splashFinished ? 1 : 0)

                if !splashFinished {
                    SplashOverlay {
                        withAnimation(.easeInOut(duration: 0.45)) { splashFinished = true }
                    }
                    .transition(.opacity)
                    .zIndex(10)
                }
            }
            .preferredColorScheme(settings.themeMode == .light ? .light : .dark)
        }
        .modelContainer(Persistence.container)
    }
}

/// Seasonal theme state — drives the Ramadan violet/gold shift (§9 recipe #9).
@Observable
final class Theme: @unchecked Sendable {
    static let shared = Theme()

    private(set) var isRamadanMode = false

    func update(hijri: HijriDate?) {
        guard let hijri else { return }
        let inSeason = hijri.month == 9 || hijri.month == 10 && hijri.day <= 3
        let enabled = AppSettings.shared.ramadanThemeEnabled
        if inSeason && enabled != isRamadanMode {
            withAnimation(.easeInOut(duration: 0.6)) {
                isRamadanMode = inSeason && enabled
            }
        }
    }

    var accent: Color {
        if isRamadanMode { return MihrabColor.ramadanGold }
        return AppSettings.shared.accentTheme.color
    }

    var accentSecondary: Color {
        if isRamadanMode { return MihrabColor.ramadanGold }
        return AppSettings.shared.accentTheme.secondary
    }
}
