import ActivityKit
import AppIntents
import Foundation
import Observation
import SwiftUI

#if canImport(AlarmKit)
import AlarmKit
#endif

// MARK: - Intents

/// Records that a prayer was performed, from the alarm's secondary button.
///
/// Deliberately minimal and namespaced `Mihrab…` so it cannot collide with the
/// App Intents layer Agent W3 is writing. It writes a flag into the App Group
/// and posts a local notification name; whoever owns prayer tracking can adopt
/// it without touching this file.
struct MihrabMarkPrayedIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Mark prayer as performed"
    static let isDiscoverable: Bool = false

    /// `Prayer.rawValue`.
    @Parameter(title: "Prayer") var prayerID: String

    init() {}

    init(prayerID: String) { self.prayerID = prayerID }

    /// Broadcast when a prayer is marked from an alarm.
    static let didMarkNotification = Notification.Name("MihrabDidMarkPrayerPrayed")

    func perform() async throws -> some IntentResult {
        let key = MihrabMarkPrayedIntent.storageKey(prayerID: prayerID, date: Date())
        let defaults = UserDefaults(suiteName: SharedPrayerCache.appGroupID) ?? .standard
        defaults.set(true, forKey: key)
        NotificationCenter.default.post(
            name: Self.didMarkNotification,
            object: nil,
            userInfo: ["prayerID": prayerID]
        )
        return .result()
    }

    static func storageKey(prayerID: String, date: Date) -> String {
        let day = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "prayed.\(day.year ?? 0)-\(day.month ?? 0)-\(day.day ?? 0).\(prayerID)"
    }
}

/// Silences a sounding alarm. AlarmKit stops the alarm itself when this is used
/// as `stopIntent`; the body only clears our own bookkeeping.
struct MihrabStopAdhanIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Stop the adhan"
    static let isDiscoverable: Bool = false

    /// `Alarm.ID` as a string — App Intents parameters must be primitives.
    @Parameter(title: "Alarm") var alarmID: String

    init() {}

    init(alarmID: String) { self.alarmID = alarmID }

    func perform() async throws -> some IntentResult {
        #if canImport(AlarmKit)
        if let uuid = UUID(uuidString: alarmID) {
            try? AlarmManager.shared.stop(id: uuid)
        }
        #endif
        return .result()
    }
}

// MARK: - Scheduler

/// The single source of truth for *how* a prayer moment is announced.
///
/// The one rule that matters: for any given (prayer, time) pair, either an
/// AlarmKit alarm fires or a `UNNotificationRequest` fires — **never both**.
/// `NotificationEngine` asks `alarmCoveredKeys` and skips whatever is in it, so
/// the decision lives here and nowhere else.
@MainActor
@Observable
final class AlarmScheduler {
    static let shared = AlarmScheduler()

    /// How far ahead alarms are placed. Prayer times move daily, so alarms are
    /// scheduled as fixed dates and refreshed on every launch/refresh.
    // nonisolated: default arguments of the nonisolated `plan(...)`.
    nonisolated static let horizonDays = 3

    /// Our self-imposed ceiling. AlarmKit's real cap is undocumented and is
    /// reported through `AlarmError.maximumLimitReached`; staying well under it
    /// leaves room for any alarms the user set in the Clock app.
    nonisolated static let maximumAlarms = 15

    enum Availability: Sendable, Equatable {
        case unsupported
        case notDetermined
        case denied
        case authorized
    }

    private(set) var availability: Availability = .notDetermined

    /// Honest, user-facing note about the current state (permission missing,
    /// system limit hit, alarms unavailable). `nil` when everything is fine.
    private(set) var statusMessage: String?

    /// Keys (`prayer|epochSeconds`) currently covered by a real alarm.
    private(set) var alarmCoveredKeys: Set<String> = []

    private let preferences: ReminderPreferences
    private let defaults: UserDefaults
    private var authorizationTask: Task<Void, Never>?

    private init() {
        preferences = .shared
        defaults = UserDefaults(suiteName: SharedPrayerCache.appGroupID) ?? .standard
        refreshAvailability()
    }

    // MARK: Mode

    /// What will actually happen at the next prayer, as opposed to what the
    /// user asked for. Falls back silently — the app must remind either way.
    var effectiveMode: ReminderPreferences.Mode {
        guard preferences.preferredMode == .alarm else { return .notification }
        return availability == .authorized ? .alarm : .notification
    }

    /// True when the user wants alarms but the system is not giving them.
    var isFallingBack: Bool {
        preferences.preferredMode == .alarm && effectiveMode == .notification
    }

    // MARK: Authorization

    func refreshAvailability() {
        #if canImport(AlarmKit)
        switch AlarmManager.shared.authorizationState {
        case .authorized: availability = .authorized
        case .denied: availability = .denied
        default: availability = .notDetermined
        }
        #else
        availability = .unsupported
        #endif
        updateStatusMessage()
    }

    /// Asks once. A denial is not an error — it just picks the other path.
    func requestAuthorization() async {
        #if canImport(AlarmKit)
        do {
            let state = try await AlarmManager.shared.requestAuthorization()
            switch state {
            case .authorized: availability = .authorized
            case .denied: availability = .denied
            default: availability = .notDetermined
            }
        } catch {
            // Treat any failure as "not available right now" and fall back.
            availability = .denied
        }
        updateStatusMessage()
        #else
        availability = .unsupported
        updateStatusMessage()
        #endif
    }

    /// Keeps `availability` live while the app runs — the user can revoke the
    /// permission in Settings mid-session and we must fall back immediately.
    func startObservingAuthorization() {
        #if canImport(AlarmKit)
        guard authorizationTask == nil else { return }
        authorizationTask = Task { [weak self] in
            for await state in AlarmManager.shared.authorizationUpdates {
                guard let self else { return }
                await MainActor.run {
                    switch state {
                    case .authorized: self.availability = .authorized
                    case .denied: self.availability = .denied
                    default: self.availability = .notDetermined
                    }
                    self.updateStatusMessage()
                }
            }
        }
        #endif
    }

    private func updateStatusMessage() {
        switch availability {
        case .unsupported:
            statusMessage = preferences.preferredMode == .alarm ? L10n.ntfAlarmUnavailable : nil
        case .denied:
            statusMessage = preferences.preferredMode == .alarm ? L10n.ntfAlarmPermissionDenied : nil
        case .notDetermined:
            statusMessage = preferences.preferredMode == .alarm ? L10n.ntfAlarmPermissionNeeded : nil
        case .authorized:
            statusMessage = nil
        }
    }

    // MARK: Planning (pure — unit tested)

    /// The unit of ownership, shared with `NotificationEngine` so the two can
    /// never announce the same moment.
    typealias PlanEntry = ReminderPlanner.PrayerInstance

    /// The alarms we would like to exist, nearest first.
    nonisolated static func plan(
        days: [DayPrayerTimes],
        now: Date,
        horizonDays: Int = AlarmScheduler.horizonDays,
        limit: Int = AlarmScheduler.maximumAlarms,
        isEnabled: (Prayer) -> Bool
    ) -> [PlanEntry] {
        ReminderPlanner.alarmPlan(
            days: days,
            now: now,
            horizonDays: horizonDays,
            limit: limit,
            isEnabled: isEnabled
        )
    }

    // MARK: Scheduling

    /// Brings the system's alarms in line with the plan. Returns the set of
    /// keys that are now covered by alarms — the notification engine's cue to
    /// stay out of the way.
    @discardableResult
    func sync(days: [DayPrayerTimes], now: Date = Date()) async -> Set<String> {
        refreshAvailability()

        guard effectiveMode == .alarm else {
            await cancelAllAlarms()
            alarmCoveredKeys = []
            return []
        }

        let entries = Self.plan(days: days, now: now) { prayer in
            AppSettings.shared.isNotificationEnabled(for: prayer)
        }
        let desiredKeys = Set(entries.map(\.key))

        // 1. Retire alarms that are no longer wanted (past, disabled, moved).
        var registry = alarmRegistry
        for (key, id) in registry where !desiredKeys.contains(key) {
            cancel(id: id)
            registry.removeValue(forKey: key)
        }

        // 2. Add the missing ones, nearest first.
        var covered: Set<String> = []
        var hitLimit = false
        for entry in entries {
            if let existing = registry[entry.key] {
                covered.insert(entry.key)
                _ = existing
                continue
            }
            guard !hitLimit else { break }
            switch await schedule(entry) {
            case .scheduled(let id):
                registry[entry.key] = id
                covered.insert(entry.key)
            case .limitReached:
                hitLimit = true
            case .failed:
                continue
            }
        }

        alarmRegistry = registry
        alarmCoveredKeys = covered

        if hitLimit {
            statusMessage = L10n.ntfAlarmLimitReached
        } else {
            updateStatusMessage()
        }
        return covered
    }

    private enum ScheduleOutcome {
        case scheduled(UUID)
        case limitReached
        case failed
    }

    private func schedule(_ entry: PlanEntry) async -> ScheduleOutcome {
        #if canImport(AlarmKit)
        let id = UUID()
        let sound = AdhanLibrary.shared.sound(for: entry.prayer)
        let metadata = MihrabAlarmMetadata(
            prayerID: entry.prayer.rawValue,
            prayerDisplayName: entry.prayer.localizedNamazName,
            prayerArabicName: entry.prayer.arabicName,
            cityName: LocationManager.shared.effectiveCityName,
            soundID: sound.id,
            prayerTime: entry.date
        )

        let stopButton = AlarmButton(
            text: LocalizedStringResource(stringLiteral: L10n.adhAlarmStop),
            textColor: MihrabColor.textPrimary,
            systemImageName: "speaker.slash.fill"
        )
        let secondaryButton = AlarmButton(
            text: LocalizedStringResource(stringLiteral: L10n.adhAlarmMarkPrayed),
            textColor: MihrabColor.mint,
            systemImageName: "checkmark.circle.fill"
        )
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(
                stringLiteral: L10n.adhAlarmTitle(entry.prayer.localizedNamazName)
            ),
            stopButton: stopButton,
            secondaryButton: secondaryButton,
            secondaryButtonBehavior: .custom
        )
        let attributes = MihrabAlarmAttributes(
            presentation: AlarmPresentation(alert: alert),
            metadata: metadata,
            tintColor: AppSettings.shared.accentTheme.color
        )

        let configuration = AlarmManager.AlarmConfiguration<MihrabAlarmMetadata>(
            schedule: .fixed(entry.date),
            attributes: attributes,
            stopIntent: MihrabStopAdhanIntent(alarmID: id.uuidString),
            secondaryIntent: MihrabMarkPrayedIntent(prayerID: entry.prayer.rawValue),
            sound: Self.alertSound(for: sound)
        )

        do {
            _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
            return .scheduled(id)
        } catch AlarmManager.AlarmError.maximumLimitReached {
            return .limitReached
        } catch {
            #if DEBUG
            print("[AlarmScheduler] schedule failed for \(entry.key): \(error)")
            #endif
            return .failed
        }
        #else
        return .failed
        #endif
    }

    #if canImport(AlarmKit)
    /// A silent sound would leave the alarm mute, so silence is expressed by
    /// the user picking the notification path instead; here `.default` is the
    /// honest fallback when there is no file to name.
    private static func alertSound(for sound: AdhanSound) -> AlertConfiguration.AlertSound {
        guard let fileName = sound.fileName, !sound.isSilent else { return .default }
        return .named(fileName)
    }
    #endif

    private func cancel(id: UUID) {
        #if canImport(AlarmKit)
        try? AlarmManager.shared.cancel(id: id)
        #endif
    }

    func cancelAllAlarms() async {
        for (_, id) in alarmRegistry { cancel(id: id) }
        alarmRegistry = [:]
        alarmCoveredKeys = []
    }

    // MARK: Registry

    /// `PlanEntry.key → Alarm.ID`, persisted so alarms scheduled in a previous
    /// launch can still be cancelled.
    private var alarmRegistry: [String: UUID] {
        get {
            let raw = defaults.dictionary(forKey: RegistryKey.map) as? [String: String] ?? [:]
            return raw.compactMapValues(UUID.init(uuidString:))
        }
        set {
            defaults.set(newValue.mapValues(\.uuidString), forKey: RegistryKey.map)
        }
    }

    private enum RegistryKey {
        static let map = "alarm.registry"
    }
}
