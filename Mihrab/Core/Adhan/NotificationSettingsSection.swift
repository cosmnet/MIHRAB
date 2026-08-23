import SwiftUI
import UIKit
import UserNotifications

/// Drop-in `Section`s for the Settings `Form`: permission state, how prayer
/// time is announced (alarm vs notification), per-prayer switches, the heads-up
/// lead, the optional extras and quiet hours.
///
/// Embed with `NotificationSettingsSection()`. It is deliberately separate from
/// `AdhanSettingsSection` (which sound) — this one is about when and whether.
struct NotificationSettingsSection: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.openURL) private var openURL

    @State private var preferences = ReminderPreferences.shared
    @State private var scheduler = AlarmScheduler.shared
    @State private var engine = NotificationEngine.shared

    init() {}

    private let rowBackground = MihrabColor.moss.opacity(0.72)

    /// Heads-up options, in minutes. 0 is "off".
    private let leadOptions = [0, 5, 10, 15, 20, 30, 45]

    var body: some View {
        Group {
            permissionSection
            modeSection
            perPrayerSection
            extrasSection
            quietSection
        }
        .task {
            await engine.refreshAuthorizationStatus()
            scheduler.refreshAvailability()
            scheduler.startObservingAuthorization()
        }
    }

    // MARK: - Permission

    private var permissionSection: some View {
        Section {
            LabeledContent(L10n.ntfPermissionTitle) {
                Text(permissionLabel)
                    .foregroundStyle(permissionColor)
            }
            .frame(minHeight: 44)

            if engine.authorizationStatus == .notDetermined {
                Button(L10n.ntfRequestPermission) {
                    Task {
                        await engine.requestAuthorization()
                        await engine.rescheduleAll()
                    }
                }
                .frame(minHeight: 44)
            }

            if engine.authorizationStatus == .denied {
                Button(L10n.ntfOpenSystemSettings) {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                .frame(minHeight: 44)
            }
        } header: {
            Text(L10n.ntfSectionAlerts)
        } footer: {
            Text(L10n.ntfBudgetFooter(engine.lastScheduledCount, max(engine.lastBudget, 1)))
                .font(.caption)
                .foregroundStyle(MihrabColor.textSecondary)
        }
        .listRowBackground(rowBackground)
    }

    private var permissionLabel: String {
        switch engine.authorizationStatus {
        case .authorized, .provisional, .ephemeral: L10n.ntfPermissionGranted
        case .denied: L10n.ntfPermissionDenied
        default: L10n.ntfPermissionNotDetermined
        }
    }

    private var permissionColor: Color {
        switch engine.authorizationStatus {
        case .authorized, .provisional, .ephemeral: MihrabColor.mint
        case .denied: MihrabColor.danger
        default: MihrabColor.textSecondary
        }
    }

    // MARK: - Mode

    private var modeSection: some View {
        Section {
            Picker(L10n.ntfModeTitle, selection: Binding(
                get: { preferences.preferredMode },
                set: { newValue in
                    preferences.preferredMode = newValue
                    HapticsEngine.shared.light()
                    Task {
                        if newValue == .alarm, scheduler.availability == .notDetermined {
                            await scheduler.requestAuthorization()
                        }
                        scheduler.refreshAvailability()
                        await NotificationEngine.shared.rescheduleAll()
                    }
                }
            )) {
                ForEach(ReminderPreferences.Mode.allCases) { mode in
                    Text(mode.localizedName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if scheduler.isFallingBack, let message = scheduler.statusMessage {
                fallbackNote(message)
            }

            if preferences.preferredMode == .alarm,
               scheduler.availability == .notDetermined {
                Button(L10n.ntfEnableAlarms) {
                    Task {
                        await scheduler.requestAuthorization()
                        await NotificationEngine.shared.rescheduleAll()
                    }
                }
                .frame(minHeight: 44)
            }

            if preferences.preferredMode == .alarm, scheduler.availability == .denied {
                Button(L10n.ntfOpenSystemSettings) {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                .frame(minHeight: 44)
            }
        } footer: {
            Text(L10n.ntfModeAlarmFooter)
                .font(.caption)
                .foregroundStyle(MihrabColor.textSecondary)
        }
        .listRowBackground(rowBackground)
    }

    /// Honest, not alarming: says what is happening and what to do about it.
    private func fallbackNote(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(MihrabColor.brass)
                .accessibilityHidden(true)
            Text(message)
                .font(.footnote)
                .foregroundStyle(MihrabColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Per prayer

    private var perPrayerSection: some View {
        Section {
            ForEach(Prayer.allCases.filter(\.isNotifiable)) { prayer in
                Toggle(prayer.localizedName, isOn: Binding(
                    get: { settings.isNotificationEnabled(for: prayer) },
                    set: { _ in
                        settings.toggleNotification(for: prayer)
                        HapticsEngine.shared.light()
                        Task { await NotificationEngine.shared.rescheduleAll() }
                    }
                ))
                .frame(minHeight: 44)
            }

            Picker(L10n.ntfPreReminder, selection: Binding(
                get: { preferences.preReminderMinutes },
                set: {
                    preferences.preReminderMinutes = $0
                    Task { await NotificationEngine.shared.rescheduleAll() }
                }
            )) {
                ForEach(leadOptions, id: \.self) { minutes in
                    Text(minutes == 0 ? L10n.ntfPreReminderOff : L10n.ntfMinutesBefore(minutes))
                        .tag(minutes)
                }
            }
            .frame(minHeight: 44)
        } header: {
            Text(L10n.setSectionNotifications)
        }
        .listRowBackground(rowBackground)
    }

    // MARK: - Extras

    private var extrasSection: some View {
        Section {
            toggle(L10n.ntfJumuah, isOn: Binding(
                get: { preferences.jumuahEnabled },
                set: { preferences.jumuahEnabled = $0 }
            ))
            toggle(L10n.ntfDailyHadith, isOn: Binding(
                get: { preferences.dailyHadithEnabled },
                set: { preferences.dailyHadithEnabled = $0 }
            ))
            toggle(L10n.ntfReligiousDays, isOn: Binding(
                get: { preferences.religiousDaysEnabled },
                set: { preferences.religiousDaysEnabled = $0 }
            ))
            toggle(L10n.ntfKarahat, isOn: Binding(
                get: { preferences.karahatEnabled },
                set: { preferences.karahatEnabled = $0 }
            ))
        } header: {
            Text(L10n.ntfSectionExtras)
        } footer: {
            Text(L10n.ntfKarahatFooter)
                .font(.caption)
                .foregroundStyle(MihrabColor.textSecondary)
        }
        .listRowBackground(rowBackground)
    }

    // MARK: - Quiet hours

    private var quietSection: some View {
        Section {
            toggle(L10n.ntfQuietHours, isOn: Binding(
                get: { preferences.quietHoursEnabled },
                set: { preferences.quietHoursEnabled = $0 }
            ))

            if preferences.quietHoursEnabled {
                hourPicker(L10n.ntfQuietFrom, selection: Binding(
                    get: { preferences.quietStartHour },
                    set: { preferences.quietStartHour = $0 }
                ))
                hourPicker(L10n.ntfQuietTo, selection: Binding(
                    get: { preferences.quietEndHour },
                    set: { preferences.quietEndHour = $0 }
                ))
            }
        } header: {
            Text(L10n.ntfSectionQuiet)
        } footer: {
            Text(L10n.ntfQuietFooter)
                .font(.caption)
                .foregroundStyle(MihrabColor.textSecondary)
        }
        .listRowBackground(rowBackground)
    }

    private func hourPicker(_ title: String, selection: Binding<Int>) -> some View {
        Picker(title, selection: Binding(
            get: { selection.wrappedValue },
            set: {
                selection.wrappedValue = $0
                Task { await NotificationEngine.shared.rescheduleAll() }
            }
        )) {
            ForEach(0..<24, id: \.self) { hour in
                Text(String(format: "%02d:00", hour)).tag(hour)
            }
        }
        .frame(minHeight: 44)
    }

    private func toggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: Binding(
            get: { isOn.wrappedValue },
            set: {
                isOn.wrappedValue = $0
                HapticsEngine.shared.light()
                Task { await NotificationEngine.shared.rescheduleAll() }
            }
        ))
        .frame(minHeight: 44)
    }
}
