import SwiftData
import SwiftUI

@main
struct MihrabApp: App {
    @State private var settings = AppSettings.shared
    @State private var locationManager = LocationManager.shared
    @State private var repository = PrayerTimesRepository.shared
    @State private var theme = Theme.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(locationManager)
                .environment(repository)
                .environment(theme)
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

    var accent: Color { isRamadanMode ? MihrabColor.ramadanGold : MihrabColor.emerald }
    var accentSecondary: Color { isRamadanMode ? MihrabColor.ramadanGold : MihrabColor.mint }
}
