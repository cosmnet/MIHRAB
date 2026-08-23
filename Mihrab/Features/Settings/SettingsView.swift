import StoreKit
import SwiftUI
import UIKit
import UserNotifications

/// Settings, rebuilt as a searchable, grouped Form.
///
/// Two sections are owned by other surfaces and embedded whole:
/// `SubscriptionSettingsSection` (Mihrab Plus) sits at the very top, because
/// account state is what people come here to check, and
/// `AppearanceSettingsSection` right below it, because looks are what they come
/// here to change.
struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(LocationManager.self) private var locationManager
    @Environment(Theme.self) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview

    @State private var store = DhikrStore.shared
    @State private var query = ""
    @State private var notificationsAuthorized = true

    private var accent: Color {
        theme.isRamadanMode ? MihrabColor.ramadanGold : settings.accentTheme.color
    }

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    /// Search is a filter over section keywords, not a separate results screen —
    /// the list keeps its shape, it just gets shorter.
    private func matches(_ terms: [String]) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return true }
        let needle = trimmed.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        return terms.contains {
            $0.folding(options: .diacriticInsensitive, locale: .current).lowercased().contains(needle)
        }
    }

    private var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MihrabBackdrop(surface: .sheet, ramadanMode: theme.isRamadanMode)

                Form {
                    if !isSearching {
                        SubscriptionSettingsSection()
                        AppearanceSettingsSection()
                    }

                    if matches([L10n.settingsPrayer, L10n.calculationMethod, L10n.madhab, L10n.madhabAsr]) {
                        prayerSection
                    }
                    if matches([L10n.setSectionNotifications, L10n.setNotificationsMaster, L10n.alertsOn]) {
                        notificationSection
                    }
                    if matches([L10n.settingsLocation, L10n.settingsCurrent, L10n.usePreciseLocation]) {
                        locationSection
                    }
                    if matches([L10n.dhkPrefs, L10n.tabDhikr, L10n.dhkPrefGoal, L10n.dhkPrefSound, L10n.dhkPrefHaptics]) {
                        dhikrSection
                    }
                    if matches([L10n.setSectionLanguage, L10n.setLanguageCurrent, L10n.setLanguageName]) {
                        languageSection
                    }
                    if matches([L10n.setSectionGuide, L10n.setReplayTour, L10n.setReplayOnboarding]) {
                        guideSection
                    }
                    if matches([L10n.setSectionData, L10n.setDataOnDevice, L10n.setPrivacyPolicy]) {
                        dataSection
                    }
                    if matches([L10n.setSectionFeedback, L10n.setRateApp, L10n.setSendFeedback]) {
                        feedbackSection
                    }
                    if matches([L10n.settingsAbout, L10n.settingsVersion, L10n.setSectionCredits, L10n.setCreditsTitle]) {
                        aboutSection
                    }
                }
                .scrollContentBackground(.hidden)
                .scrollEdgeEffectStyle(.soft, for: .top)
                .tint(accent)
            }
            .navigationTitle(L10n.settings)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: Text(L10n.setSearchPrompt))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.done) { dismiss() }
                        .foregroundStyle(MihrabColor.textPrimary)
                }
            }
            .task { await refreshNotificationStatus() }
        }
        .presentationBackground(.ultraThinMaterial)
    }

    // MARK: - Prayer

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
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }

    // MARK: - Notifications

    private var notificationSection: some View {
        Section {
            if !notificationsAuthorized {
                Button(L10n.setNotificationsAllow) {
                    Task {
                        _ = await NotificationEngine.shared.requestAuthorization()
                        await refreshNotificationStatus()
                        await NotificationEngine.shared.rescheduleAll()
                    }
                }
            }

            ForEach(Prayer.allCases.filter(\.isNotifiable)) { prayer in
                Toggle(prayer.localizedName, isOn: Binding(
                    get: { settings.isNotificationEnabled(for: prayer) },
                    set: { _ in
                        settings.toggleNotification(for: prayer)
                        HapticsEngine.shared.light()
                        Task { await NotificationEngine.shared.rescheduleAll() }
                    }
                ))
            }

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                HStack {
                    Text(L10n.setNotificationsSystem)
                    Spacer()
                    Image(systemName: "arrow.up.forward.app")
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textTertiary)
                }
            }
        } header: {
            Text(L10n.setSectionNotifications)
        } footer: {
            Text(L10n.setNotificationsFooter + "\n" + L10n.setNotificationsSystemHint)
                .font(.caption2)
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }

    // MARK: - Location

    private var locationSection: some View {
        Section {
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
        } header: {
            Text(L10n.settingsLocation)
        } footer: {
            Text(L10n.setLocationFooter).font(.caption2)
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }

    // MARK: - Dhikr

    private var dhikrSection: some View {
        Section(L10n.dhkPrefs) {
            Stepper(value: Binding(
                get: { settings.dailyDhikrGoal },
                set: { settings.dailyDhikrGoal = $0 }
            ), in: 33...5000, step: 33) {
                HStack {
                    Text(L10n.dhkPrefGoal)
                    Spacer()
                    Text("\(settings.dailyDhikrGoal)")
                        .monospacedDigit()
                        .foregroundStyle(MihrabColor.textSecondary)
                }
            }

            Toggle(L10n.dhkPrefHaptics, isOn: Binding(
                get: { store.hapticsEnabled },
                set: { store.hapticsEnabled = $0 }
            ))
            Toggle(L10n.dhkPrefSound, isOn: Binding(
                get: { store.soundEnabled },
                set: { store.soundEnabled = $0 }
            ))
            Toggle(L10n.dhkPrefKeepAwake, isOn: Binding(
                get: { store.keepAwakeWhileCounting },
                set: { store.keepAwakeWhileCounting = $0 }
            ))
            Toggle(L10n.dhkPrefStrandDefault, isOn: Binding(
                get: { store.opensInStrandMode },
                set: { store.opensInStrandMode = $0 }
            ))
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }

    // MARK: - Language

    private var languageSection: some View {
        Section {
            HStack {
                Text(L10n.setLanguageCurrent)
                Spacer()
                Text(L10n.setLanguageName)
                    .foregroundStyle(MihrabColor.textSecondary)
            }
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                HStack {
                    Text(L10n.openSettings)
                    Spacer()
                    Image(systemName: "arrow.up.forward.app")
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textTertiary)
                }
            }
        } header: {
            Text(L10n.setSectionLanguage)
        } footer: {
            Text(L10n.setLanguageFooter).font(.caption2)
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }

    // MARK: - Guide

    private var guideSection: some View {
        Section {
            Button {
                CoachMarkController.shared.reset()
                HapticsEngine.shared.success()
                dismiss()
            } label: {
                Label(L10n.setReplayTour, systemImage: "sparkles")
            }
            Button {
                settings.hasCompletedOnboarding = false
                dismiss()
            } label: {
                Label(L10n.setReplayOnboarding, systemImage: "arrow.counterclockwise")
            }
        } header: {
            Text(L10n.setSectionGuide)
        } footer: {
            Text(L10n.setGuideFooter).font(.caption2)
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }

    // MARK: - Data & privacy

    private var dataSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(accent)
                Text(L10n.setDataOnDevice)
            }
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                HStack {
                    Text(L10n.setPrivacyPolicy)
                    Spacer()
                    Image(systemName: "arrow.up.forward.app")
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textTertiary)
                }
            }
        } header: {
            Text(L10n.setSectionData)
        } footer: {
            Text(L10n.setDataFooter).font(.caption2)
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }

    // MARK: - Feedback

    private var feedbackSection: some View {
        Section {
            Button {
                requestReview()
            } label: {
                Label(L10n.setRateApp, systemImage: "star.fill")
            }
            Button {
                let subject = "Mihrab \(appVersion)"
                    .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Mihrab"
                if let url = URL(string: "mailto:mihrab.feedback@icloud.com?subject=\(subject)") {
                    openURL(url)
                }
            } label: {
                Label(L10n.setSendFeedback, systemImage: "envelope.fill")
            }
        } header: {
            Text(L10n.setSectionFeedback)
        } footer: {
            Text(L10n.setFeedbackFooter).font(.caption2)
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            HStack {
                Text(L10n.settingsVersion)
                Spacer()
                Text(appVersion)
                    .monospacedDigit()
                    .foregroundStyle(MihrabColor.textSecondary)
            }
            NavigationLink {
                SettingsCreditsView()
            } label: {
                Label(L10n.setCreditsTitle, systemImage: "text.book.closed.fill")
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.settingsAboutBody)
                    .font(.caption)
                    .foregroundStyle(MihrabColor.textTertiary)
                Text(L10n.setMadeWith)
                    .font(.caption2)
                    .foregroundStyle(MihrabColor.brass)
            }
        } header: {
            Text(L10n.settingsAbout)
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }

    private func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsAuthorized = settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
    }
}

// MARK: - Credits

/// Where the numbers come from. Prayer apps live or die on trust, and trust is
/// mostly a matter of saying plainly what you calculated and from what.
struct SettingsCreditsView: View {
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            MihrabBackdrop(surface: .sheet, ramadanMode: theme.isRamadanMode)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    creditCard(
                        index: 0,
                        symbol: "clock.badge.checkmark",
                        title: L10n.setCreditsTimes,
                        body: L10n.setCreditsTimesBody
                    )
                    creditCard(
                        index: 1,
                        symbol: "book.closed.fill",
                        title: L10n.setCreditsHadith,
                        body: L10n.setCreditsHadithBody
                    )
                    creditCard(
                        index: 2,
                        symbol: "location.north.line.fill",
                        title: L10n.setCreditsQibla,
                        body: L10n.setCreditsQiblaBody
                    )
                    creditCard(
                        index: 3,
                        symbol: "textformat",
                        title: L10n.setCreditsFont,
                        body: L10n.setCreditsFontBody
                    )

                    Text(L10n.setCreditsDisclaimer)
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textTertiary)
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                }
                .padding()
                .padding(.bottom, 24)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
        }
        .navigationTitle(L10n.setCreditsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task { withAnimation { appeared = true } }
    }

    private func creditCard(index: Int, symbol: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(MihrabColor.brass)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MihrabColor.textPrimary)
                Text(body)
                    .font(.caption)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .mihrabCard()
        .cardEntrance(index: index, appeared: appeared, reduceMotion: reduceMotion)
    }
}
