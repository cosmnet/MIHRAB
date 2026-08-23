import SwiftData
import SwiftUI

@main
struct MihrabApp: App {
    @State private var settings = AppSettings.shared
    @State private var locationManager = LocationManager.shared
    @State private var repository = PrayerTimesRepository.shared
    @State private var theme = Theme.shared
    @State private var splashFinished = false

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
