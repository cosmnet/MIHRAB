import StoreKit
import SwiftUI
import UIKit

/// Settings, as seven doors rather than one long scroll.
///
/// Fifteen `Section`s had accumulated in a single `Form` — most of them owned by
/// other surfaces and embedded whole — and the screen had stopped being
/// scannable. The sections themselves are untouched; they now live behind seven
/// `NavigationLink`s grouped by what a person is actually trying to change.
/// `SubscriptionSettingsSection` stays at the top, above the doors, because
/// account state is what people come here to *check* rather than change.
///
/// Searching flattens all of it: every group is a search candidate, so nothing
/// can hide behind a link. Previously eight sections were rendered only under
/// `!isSearching` and so vanished the moment you typed their own name.
struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(LocationManager.self) private var locationManager
    @Environment(Theme.self) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview

    @State private var store = DhikrStore.shared
    @State private var query = ""

    /// One door in the root list. `keywords` is what `.searchable` matches on,
    /// and it must name everything the group contains — that is the contract
    /// that keeps a section findable once it is a link away.
    private enum SettingsGroup: String, CaseIterable, Identifiable {
        case prayer, reminders, location, worship, appearance, account, app

        var id: String { rawValue }

        var title: String {
            switch self {
            case .prayer: L10n.setGroupPrayer
            case .reminders: L10n.setGroupReminders
            case .location: L10n.setGroupLocation
            case .worship: L10n.setGroupWorship
            case .appearance: L10n.setGroupAppearance
            case .account: L10n.setGroupAccount
            case .app: L10n.setGroupApp
            }
        }

        var subtitle: String {
            switch self {
            case .prayer: L10n.setGroupPrayerSub
            case .reminders: L10n.setGroupRemindersSub
            case .location: L10n.setGroupLocationSub
            case .worship: L10n.setGroupWorshipSub
            case .appearance: L10n.setGroupAppearanceSub
            case .account: L10n.setGroupAccountSub
            case .app: L10n.setGroupAppSub
            }
        }

        var symbol: String {
            switch self {
            case .prayer: "moon.stars.fill"
            case .reminders: "bell.badge.fill"
            case .location: "mappin.and.ellipse"
            case .worship: "hands.and.sparkles.fill"
            case .appearance: "paintpalette.fill"
            case .account: "icloud.fill"
            case .app: "gearshape.fill"
            }
        }

        var keywords: [String] {
            switch self {
            case .prayer:
                [title, subtitle, L10n.settingsPrayer, L10n.calculationMethod,
                 L10n.madhab, L10n.madhabAsr, L10n.sourceSectionTitle]
            case .reminders:
                [title, subtitle, L10n.setSectionNotifications, L10n.setNotificationsSystem,
                 L10n.adhSectionSound, L10n.adhSectionPerPrayer, L10n.adhSectionLibrary]
            case .location:
                [title, subtitle, L10n.settingsLocation, L10n.settingsCurrent,
                 L10n.usePreciseLocation, L10n.citiesTitle]
            case .worship:
                [title, subtitle, L10n.quranTitle, L10n.hatimTitle,
                 L10n.qadaTitle, L10n.zakatTitle, L10n.zakatSectionTitle,
                 L10n.calendarTitle, L10n.dhkPrefs, L10n.tabDhikr, L10n.dhkPrefGoal,
                 L10n.dhkPrefSound, L10n.dhkPrefBeadSound, L10n.dhkMaterial,
                 L10n.dhkPrefHaptics, L10n.dhkPrefFocusDim]
            case .appearance:
                [title, subtitle, L10n.apprBackdropSection, L10n.apprTextureSection,
                 L10n.apprColourSection, L10n.setSectionLanguage, L10n.setLanguageCurrent,
                 L10n.setLanguageName]
            case .account:
                [title, subtitle, L10n.syncSectionTitle, L10n.syncToggleTitle]
            case .app:
                [title, subtitle, L10n.setSectionGuide, L10n.setReplayTour,
                 L10n.setReplayOnboarding, L10n.setSectionData, L10n.setDataOnDevice,
                 L10n.setPrivacyPolicy, L10n.setSectionFeedback, L10n.setRateApp,
                 L10n.setSendFeedback, L10n.settingsAbout, L10n.settingsVersion,
                 L10n.setSectionCredits, L10n.setCreditsTitle]
            }
        }
    }

    /// Served from GitHub Pages — see `docs/privacy.html`.
    private static let privacyPolicyURL =
        URL(string: "https://cosmnet.github.io/MIHRAB/privacy.html")!

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
                    if isSearching {
                        let hits = SettingsGroup.allCases.filter { matches($0.keywords) }
                        if hits.isEmpty {
                            Section {
                                Text(L10n.setNoResults)
                                    .foregroundStyle(MihrabColor.textSecondary)
                            }
                            .listRowBackground(MihrabColor.moss.opacity(0.72))
                        }
                        ForEach(hits) { sections(for: $0) }
                    } else {
                        SubscriptionSettingsSection()

                        Section {
                            ForEach(SettingsGroup.allCases) { groupRow($0) }
                        }
                        .listRowBackground(MihrabColor.moss.opacity(0.72))
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
        }
        .presentationBackground(.ultraThinMaterial)
    }

    // MARK: - Groups

    private func groupRow(_ group: SettingsGroup) -> some View {
        NavigationLink {
            SettingsGroupPage(title: group.title) {
                sections(for: group)
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: group.symbol)
                    .font(.body)
                    .foregroundStyle(accent)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.title)
                    Text(group.subtitle)
                        .font(.caption)
                        // textSecondary, not textTertiary: tertiary sits at
                        // 2.9:1 on the moss row background, under 4.5:1.
                        .foregroundStyle(MihrabColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 2)
        }
        .accessibilityLabel(Text(group.title))
        .accessibilityHint(Text(group.subtitle))
    }

    /// The real content of each group. Used twice — inside the group's page and,
    /// flattened, in search results — so a section can never be reachable from
    /// only one of the two.
    @ViewBuilder
    private func sections(for group: SettingsGroup) -> some View {
        switch group {
        case .prayer:
            prayerSection
            // Owned by the prayer-engine surface: calculation source
            // (Diyanet / Fazilet / Türkiye Takvimi) and per-prayer offsets.
            PrayerSourceSettingsSection()
        case .reminders:
            NotificationSettingsSection()
            AdhanSettingsSection()
        case .location:
            locationSection
            CitiesSettingsSection()
        case .worship:
            QuranSettingsSection()
            QadaSettingsSection()
            ZakatSettingsSection()
            CalendarSettingsSection()
            dhikrSection
        case .appearance:
            AppearanceSettingsSection()
            languageSection
        case .account:
            SyncSettingsSection()
        case .app:
            guideSection
            dataSection
            feedbackSection
            aboutSection
        }
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
        Section {
            Stepper(value: Binding(
                get: { settings.dailyDhikrGoal },
                set: { settings.dailyDhikrGoal = $0 }
            ), in: 33...5000, step: 33) {
                HStack {
                    Text(L10n.dhkPrefGoal)
                    Spacer()
                    Text(settings.dailyDhikrGoal.formatted(.number.grouping(.never)))
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
            Toggle(L10n.dhkPrefBeadSound, isOn: Binding(
                get: { store.beadSoundEnabled },
                set: { store.beadSoundEnabled = $0 }
            ))
            Picker(L10n.dhkMaterial, selection: Binding(
                get: { store.tasbihMaterial },
                set: { store.tasbihMaterial = $0 }
            )) {
                ForEach(TasbihMaterial.allCases) { material in
                    Text(material.localizedName).tag(material)
                }
            }
            Toggle(L10n.dhkPrefKeepAwake, isOn: Binding(
                get: { store.keepAwakeWhileCounting },
                set: { store.keepAwakeWhileCounting = $0 }
            ))
            Toggle(L10n.dhkPrefStrandDefault, isOn: Binding(
                get: { store.opensInStrandMode },
                set: { store.opensInStrandMode = $0 }
            ))
            Toggle(L10n.dhkPrefFocusDim, isOn: Binding(
                get: { store.dimsInFocusMode },
                set: { store.dimsInFocusMode = $0 }
            ))
        } header: {
            Text(L10n.dhkPrefs)
        } footer: {
            Text(L10n.dhkPrefFocusDimFooter).font(.caption2)
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
                        .foregroundStyle(MihrabColor.textSecondary)
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
                openURL(Self.privacyPolicyURL)
            } label: {
                HStack {
                    Text(L10n.setPrivacyPolicy)
                    Spacer()
                    Image(systemName: "arrow.up.forward.app")
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textSecondary)
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
                    .foregroundStyle(MihrabColor.textSecondary)
                Text(L10n.setMadeWith)
                    .font(.caption2)
                    .foregroundStyle(MihrabColor.brass)
            }
        } header: {
            Text(L10n.settingsAbout)
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
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

                    creditCard(
                        index: 4,
                        symbol: "text.book.closed.fill",
                        title: L10n.setCreditsQuran,
                        body: L10n.setCreditsQuranBody
                    )
                    // MIT and the SIL OFL both require their notice to travel
                    // with the binary, not just with the repository.
                    creditCard(
                        index: 5,
                        symbol: "shippingbox.fill",
                        title: L10n.setCreditsOpenSource,
                        body: L10n.setCreditsOpenSourceBody
                    )

                    Text(L10n.setCreditsDisclaimer)
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textSecondary)
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
                .font(.headline)
                .foregroundStyle(MihrabColor.brass)
                .frame(width: 26)
                .accessibilityHidden(true)
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

// MARK: - Group page

/// A settings group opened from the root list. Carries the same backdrop and
/// `Form` chrome the root has, so a link never feels like leaving the screen.
private struct SettingsGroupPage<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    @Environment(Theme.self) private var theme
    @Environment(AppSettings.self) private var settings

    private var accent: Color {
        theme.isRamadanMode ? MihrabColor.ramadanGold : settings.accentTheme.color
    }

    var body: some View {
        ZStack {
            MihrabBackdrop(surface: .sheet, ramadanMode: theme.isRamadanMode)

            Form { content }
                .scrollContentBackground(.hidden)
                .scrollEdgeEffectStyle(.soft, for: .top)
                .tint(accent)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
