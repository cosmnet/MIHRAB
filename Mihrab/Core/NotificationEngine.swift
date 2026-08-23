import Foundation
import Observation
import UserNotifications

/// Local notification engine.
///
/// Three things this type is careful about:
///
/// 1. **It only ever deletes its own work.** `removeAllPendingNotificationRequests()`
///    used to wipe the trial reminders too; now every request we create carries
///    a `mihrab-` prefix from `ManagedPrefix` and cleanup is targeted, so
///    `mihrab-trial-*` (owned by `TrialReminder`) survives untouched.
/// 2. **It respects the 64-pending cap explicitly.** iOS silently drops the
///    64th-and-beyond request. During a kandil month, 50 prayer alerts plus the
///    repeating extras plus religious days sail straight past it. The budget is
///    computed, split between worship-critical and optional reminders, and the
///    plan is truncated *before* anything is submitted.
/// 3. **It never double-announces.** If `AlarmScheduler` has an AlarmKit alarm
///    covering a prayer instance, no notification is scheduled for it.
@MainActor
@Observable
final class NotificationEngine {
    static let shared = NotificationEngine()

    /// iOS keeps at most this many pending local notifications per app.
    static let systemPendingLimit = 64

    /// Head-room left to other subsystems (`mihrab-trial-*`, future features)
    /// plus a couple of slots so we never sit exactly on the ceiling.
    static let reservedSlots = 4

    /// Slots held back for the optional reminders so a busy prayer schedule
    /// cannot starve the Friday reminder out of existence.
    // nonisolated: used as a default argument by the nonisolated `fit(_:budget:)`.
    nonisolated static let extrasReserve = 8

    /// Every identifier prefix this engine owns. Cleanup matches on these and
    /// on `LegacyPrefix` — and on nothing else.
    /// Kept in step with `ReminderPlanner.managedPrefixes` — that type is the
    /// one the tests compile against.
    enum ManagedPrefix {
        static let prayer = ReminderPlanner.Prefix.prayer
        static let preReminder = ReminderPlanner.Prefix.preReminder
        static let karahat = ReminderPlanner.Prefix.karahat
        static let hadith = ReminderPlanner.Prefix.hadith
        static let religious = ReminderPlanner.Prefix.religious
        static let jumuah = ReminderPlanner.Prefix.jumuah

        static let all = ReminderPlanner.managedPrefixes
    }

    private let center = UNUserNotificationCenter.current()
    private let preferences: ReminderPreferences

    /// Last plan's outcome, surfaced by `NotificationSettingsSection`.
    private(set) var lastScheduledCount = 0
    private(set) var lastBudget = 0
    private(set) var lastFailureCount = 0
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    init(preferences: ReminderPreferences = .shared) {
        self.preferences = preferences
    }

    // MARK: - Authorization

    @discardableResult
    func requestAuthorization() async -> Bool {
        let granted = (try? await center.requestAuthorization(
            options: [.alert, .sound, .badge, .timeSensitive]
        )) ?? false
        await refreshAuthorizationStatus()
        return granted
    }

    func refreshAuthorizationStatus() async {
        authorizationStatus = await center.notificationSettings().authorizationStatus
    }

    // MARK: - Planning

    /// One request, not yet submitted.
    struct Planned {
        enum Kind: Int, Sendable {
            /// Worship-critical.
            case prayer = 0
            case preReminder = 1
            /// Optional extras.
            case jumuah = 2
            case religiousDay = 3
            case karahat = 4
            case dailyHadith = 5

            var isEssential: Bool { self == .prayer || self == .preReminder }
        }

        let identifier: String
        let kind: Kind
        /// When it will fire. Repeating requests use their next occurrence,
        /// purely for ordering.
        let fireDate: Date
        let content: UNMutableNotificationContent
        let trigger: UNNotificationTrigger
    }

    /// Splits `budget` between essential and optional requests and truncates.
    /// The arithmetic lives in `ReminderPlanner.fit` so the tests can exercise
    /// it without dragging UserNotifications into the test target.
    nonisolated static func fit(
        _ planned: [Planned],
        budget: Int,
        extrasReserve: Int = NotificationEngine.extrasReserve
    ) -> [Planned] {
        ReminderPlanner.fit(
            planned,
            budget: budget,
            extrasReserve: extrasReserve,
            isEssential: { $0.kind.isEssential },
            rank: { $0.kind.rawValue },
            fireDate: { $0.fireDate }
        )
    }

    // MARK: - Reschedule

    /// Rebuilds the whole reminder set: alarms first (they take priority and
    /// decide what notifications must *not* cover), then the notification plan.
    func rescheduleAll() async {
        await refreshAuthorizationStatus()

        let snapshot = SharedPrayerCache.load()
        let days = snapshot?.days ?? []

        // 1. AlarmKit owns whatever it can take.
        let covered = await AlarmScheduler.shared.sync(days: days)

        // 2. Targeted cleanup — trial reminders and anything else stay.
        let pending = await center.pendingNotificationRequests()
        let ours = pending.map(\.identifier).filter(Self.isManaged)
        if !ours.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: ours)
        }
        let foreignCount = pending.count - ours.count

        // 3. Budget.
        let budget = max(0, Self.systemPendingLimit - Self.reservedSlots - foreignCount)
        lastBudget = budget

        // 4. Build, fit, submit.
        let planned = buildPlan(days: days, alarmCoveredKeys: covered)
        let fitted = Self.fit(planned, budget: budget)
        await submit(fitted)
    }

    nonisolated static func isManaged(_ identifier: String) -> Bool {
        ReminderPlanner.isManaged(identifier)
    }

    private func buildPlan(days: [DayPrayerTimes], alarmCoveredKeys: Set<String>) -> [Planned] {
        var planned: [Planned] = []
        let now = Date()
        let settings = AppSettings.shared

        // --- Prayer alerts + heads-up ------------------------------------
        let preMinutes = preferences.preReminderMinutes
        for day in days {
            for prayer in Prayer.allCases where prayer.isNotifiable {
                guard settings.isNotificationEnabled(for: prayer),
                      let time = day.time(for: prayer),
                      time > now
                else { continue }

                let key = AlarmScheduler.PlanEntry(prayer: prayer, date: time).key
                if !alarmCoveredKeys.contains(key) {
                    planned.append(prayerAlert(prayer: prayer, at: time))
                }

                // The heads-up is a different moment, so it is never a duplicate
                // of the alarm — it stays even in alarm mode.
                if preMinutes > 0 {
                    let lead = time.addingTimeInterval(-Double(preMinutes) * 60)
                    if lead > now {
                        planned.append(preReminder(prayer: prayer, at: lead, minutes: preMinutes))
                    }
                }
            }
        }

        // --- Makruh windows (today only — they are hints, not obligations) --
        if preferences.karahatEnabled, let today = days.first(where: {
            Calendar.current.isDateInToday($0.date)
        }) {
            planned.append(contentsOf: karahatReminders(for: today, now: now))
        }

        // --- Extras ------------------------------------------------------
        if preferences.jumuahEnabled, let jumuah = jumuahReminder() {
            planned.append(jumuah)
        }
        if preferences.dailyHadithEnabled, let hadith = dailyHadith() {
            planned.append(hadith)
        }
        if preferences.religiousDaysEnabled,
           let hijri = PrayerTimesRepository.shared.today?.hijriDate {
            for item in BundledContent.upcomingReligiousDays(from: hijri)
            where item.daysUntil > 0 && item.daysUntil <= 30 {
                planned.append(contentsOf: religiousDay(item.day, daysUntil: item.daysUntil, now: now))
            }
        }

        return planned
    }

    /// Submits the fitted plan, checking every `add` instead of firing and
    /// forgetting. A silent failure here is a missed prayer call.
    private func submit(_ plan: [Planned]) async {
        var scheduled = 0
        var failed = 0
        for item in plan {
            let request = UNNotificationRequest(
                identifier: item.identifier,
                content: item.content,
                trigger: item.trigger
            )
            do {
                try await center.add(request)
                scheduled += 1
            } catch {
                failed += 1
                #if DEBUG
                print("[NotificationEngine] add failed for \(item.identifier): \(error)")
                #endif
            }
        }
        lastScheduledCount = scheduled
        lastFailureCount = failed
        #if DEBUG
        print("[NotificationEngine] scheduled \(scheduled)/\(plan.count), budget \(lastBudget), failures \(failed)")
        #endif
    }

    // MARK: - Builders

    private func prayerAlert(prayer: Prayer, at date: Date) -> Planned {
        let content = UNMutableNotificationContent()
        content.title = L10n.prayerAlertTitle(prayer.localizedNamazName)
        content.body = L10n.prayerAlertBody(prayer.localizedNamazName)
        // Silent selection means vibration only: leaving `sound` nil is exactly
        // that, not "system default".
        content.sound = AdhanLibrary.shared.sound(for: prayer).notificationSound
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 1.0

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: date
        )
        return Planned(
            identifier: "\(ManagedPrefix.prayer)\(prayer.rawValue)-\(Int(date.timeIntervalSince1970))",
            kind: .prayer,
            fireDate: date,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        )
    }

    private func preReminder(prayer: Prayer, at date: Date, minutes: Int) -> Planned {
        let content = UNMutableNotificationContent()
        content.title = prayer.localizedNamazName
        content.body = L10n.ntfPreReminderBody(prayer.localizedNamazName, minutes)
        content.sound = .default
        content.interruptionLevel = .active
        content.relevanceScore = 0.8

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: date
        )
        return Planned(
            identifier: "\(ManagedPrefix.preReminder)\(prayer.rawValue)-\(Int(date.timeIntervalSince1970))",
            kind: .preReminder,
            fireDate: date,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        )
    }

    /// The three windows in which voluntary prayer is discouraged: as the sun
    /// rises, as it stands at its zenith, and as it sets. Offsets are leads, so
    /// the note lands *before* the window opens.
    private func karahatReminders(for day: DayPrayerTimes, now: Date) -> [Planned] {
        let windows: [(Prayer, TimeInterval, String)] = [
            (.sunrise, -10 * 60, L10n.ntfKarahatSunrise),
            (.dhuhr, -20 * 60, L10n.ntfKarahatZenith),
            (.maghrib, -25 * 60, L10n.ntfKarahatSunset),
        ]
        return windows.compactMap { prayer, lead, label in
            guard let anchor = day.time(for: prayer) else { return nil }
            let fire = anchor.addingTimeInterval(lead)
            guard fire > now, !preferences.isQuiet(fire) else { return nil }

            let content = UNMutableNotificationContent()
            content.title = L10n.ntfKarahat
            content.body = L10n.ntfKarahatBody(label)
            content.sound = .default
            content.interruptionLevel = .passive
            content.relevanceScore = 0.3

            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: fire
            )
            return Planned(
                identifier: "\(ManagedPrefix.karahat)\(prayer.rawValue)-\(Int(fire.timeIntervalSince1970))",
                kind: .karahat,
                fireDate: fire,
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            )
        }
    }

    private func dailyHadith() -> Planned? {
        var comps = DateComponents()
        comps.hour = 9
        comps.minute = 0
        guard let next = Calendar.current.nextDate(
            after: Date(), matching: comps, matchingPolicy: .nextTime
        ), !preferences.isQuiet(next) else { return nil }

        let hadith = BundledContent.hadith()
        let content = UNMutableNotificationContent()
        content.title = L10n.dailyHadith
        content.body = String((Locale.mihrabIsTurkish ? hadith.tr : hadith.en).prefix(180))
        content.sound = .default
        content.interruptionLevel = .passive
        content.relevanceScore = 0.2

        return Planned(
            identifier: ManagedPrefix.hadith,
            kind: .dailyHadith,
            fireDate: next,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        )
    }

    private func jumuahReminder() -> Planned? {
        var comps = DateComponents()
        comps.weekday = 6 // Friday
        comps.hour = 10
        comps.minute = 0
        guard let next = Calendar.current.nextDate(
            after: Date(), matching: comps, matchingPolicy: .nextTime
        ), !preferences.isQuiet(next) else { return nil }

        let content = UNMutableNotificationContent()
        content.title = L10n.jumuahTitle
        content.body = L10n.jumuahBody
        content.sound = .default
        content.interruptionLevel = .active
        content.relevanceScore = 0.5

        return Planned(
            identifier: ManagedPrefix.jumuah,
            kind: .jumuah,
            fireDate: next,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        )
    }

    private func religiousDay(_ day: ReligiousDay, daysUntil: Int, now: Date) -> [Planned] {
        guard let targetDate = Calendar.current.date(byAdding: .day, value: daysUntil, to: now)
        else { return [] }
        let calendar = Calendar.current

        return [(-1, 18), (0, 9)].compactMap { offset, hour in
            guard let base = calendar.date(byAdding: .day, value: offset, to: targetDate)
            else { return nil }
            var comps = calendar.dateComponents([.year, .month, .day], from: base)
            comps.hour = hour
            comps.minute = 0
            guard let fire = calendar.date(from: comps), fire > now,
                  !preferences.isQuiet(fire) else { return nil }

            let content = UNMutableNotificationContent()
            content.title = day.localizedName
            content.body = "\(day.localizedName) — \(day.localizedDescription.prefix(100))"
            content.sound = .default
            content.interruptionLevel = .active
            content.relevanceScore = 0.4

            return Planned(
                identifier: "\(ManagedPrefix.religious)\(day.id)-\(offset)",
                kind: .religiousDay,
                fireDate: fire,
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            )
        }
    }
}
