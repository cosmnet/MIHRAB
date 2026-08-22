import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()
                Form {
                    prayerSection
                    locationSection
                    appearanceSection
                    dhikrSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
                .scrollEdgeEffectStyle(.soft, for: .top)
                .tint(MihrabColor.emerald)
            }
            .navigationTitle(L10n.settings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.done) { dismiss() }
                }
            }
        }
        .presentationBackground(.ultraThinMaterial)
    }

    private var prayerSection: some View {
        Section(L10n.settingsPrayer) {
            Picker(L10n.calculationMethod, selection: Binding(
                get: { settings.calculationMethod },
                set: { settings.calculationMethod = $0 }
            )) {
                ForEach(CalculationMethod.allCases) { method in
                    Text(method.localizedName).tag(method)
                }
            }

            Picker(L10n.madhabAsr, selection: Binding(
                get: { settings.madhab },
                set: { settings.madhab = $0 }
            )) {
                ForEach(Madhab.allCases) { Text($0.localizedName).tag($0) }
            }

            ForEach(Prayer.allCases.filter(\.isNotifiable)) { prayer in
                Toggle(L10n.prayerNotification(prayer.localizedName), isOn: Binding(
                    get: { settings.isNotificationEnabled(for: prayer) },
                    set: { _ in
                        settings.toggleNotification(for: prayer)
                        Task { await NotificationEngine.shared.rescheduleAll() }
                    }
                ))
            }
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }

    private var locationSection: some View {
        Section(L10n.settingsLocation) {
            HStack {
                Text(L10n.settingsCurrent)
                Spacer()
                Text(locationManager.effectiveCityName.isEmpty ? L10n.locating : locationManager.effectiveCityName)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Button(L10n.usePreciseLocation) {
                locationManager.requestAuthorization()
                locationManager.startUpdating()
            }
            if settings.manualCityName != nil {
                Button(L10n.clearManualOverride, role: .destructive) {
                    settings.manualCityName = nil
                    settings.manualLatitude = nil
                    settings.manualLongitude = nil
                }
            }
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }

    private var appearanceSection: some View {
        Section(L10n.settingsAppearance) {
            Picker(L10n.settingsTheme, selection: Binding(
                get: { settings.themeMode },
                set: { settings.themeMode = $0 }
            )) {
                Text(L10n.themeAuto).tag(AppSettings.ThemeMode.auto)
                Text(L10n.themeDark).tag(AppSettings.ThemeMode.dark)
                Text(L10n.themeLight).tag(AppSettings.ThemeMode.light)
            }
            Toggle(L10n.ramadanTheme, isOn: Binding(
                get: { settings.ramadanThemeEnabled },
                set: { settings.ramadanThemeEnabled = $0 }
            ))
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }

    private var dhikrSection: some View {
        Section(L10n.tabDhikr) {
            Stepper(L10n.dailyGoal(settings.dailyDhikrGoal), value: Binding(
                get: { settings.dailyDhikrGoal },
                set: { settings.dailyDhikrGoal = $0 }
            ), in: 33...1000, step: 33)
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }

    private var aboutSection: some View {
        Section(L10n.settingsAbout) {
            HStack {
                Text(L10n.settingsVersion)
                Spacer()
                Text("1.0")
                    .foregroundStyle(MihrabColor.textSecondary)
            }
            Text(L10n.settingsAboutBody)
                .font(.caption)
                .foregroundStyle(MihrabColor.textTertiary)
            Button(L10n.resetOnboarding) {
                settings.hasCompletedOnboarding = false
            }
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }
}
