import Foundation
import UserNotifications

/// Honest trial bookkeeping: we tell people *before* the free week ends, so
/// nobody is surprised by a charge. Two reminders — day 5 and the final morning.
///
/// ⚠️ `NotificationEngine.rescheduleAll()` calls
/// `removeAllPendingNotificationRequests()`, which also clears these. Call
/// `TrialReminder.ensureScheduled()` after any reschedule (and on launch) to
/// re-arm them. Identifiers are namespaced `mihrab-trial-*` so they never
/// collide with `prayer-*`, `daily-hadith`, `religious-*` or `jumuah`.
enum TrialReminder {
    static let reminderIdentifier = "mihrab-trial-reminder-day5"
    static let finalIdentifier = "mihrab-trial-reminder-final"

    /// Reminder points, measured in days from the trial start.
    private static let firstReminderDay: Double = 5
    private static let finalReminderLeadHours: Double = 12

    /// Schedules both reminders for a trial that started at `trialStart`.
    static func scheduleTrialReminders(
        trialStart: Date,
        duration: TimeInterval = 7 * 86_400
    ) {
        let center = UNUserNotificationCenter.current()
        cancelTrialReminders()

        let end = trialStart.addingTimeInterval(duration)

        // Day 5 — two days of runway left.
        let day5 = trialStart.addingTimeInterval(firstReminderDay * 86_400)
        add(
            identifier: reminderIdentifier,
            title: L10n.trialReminderTitle,
            body: L10n.trialReminderBody,
            fireAt: day5,
            center: center
        )

        // Final morning — 12 hours before the trial closes.
        let finalDate = end.addingTimeInterval(-finalReminderLeadHours * 3_600)
        add(
            identifier: finalIdentifier,
            title: L10n.trialEndingTitle,
            body: L10n.trialEndingBody,
            fireAt: finalDate,
            center: center
        )
    }

    /// Re-arms the reminders if they went missing (e.g. after a full reschedule).
    static func ensureScheduled(trialStart: Date?, duration: TimeInterval = 7 * 86_400) {
        guard let trialStart, trialStart.addingTimeInterval(duration) > Date() else { return }
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = Set(requests.map(\.identifier))
            guard !ids.contains(reminderIdentifier) || !ids.contains(finalIdentifier) else { return }
            Task { @MainActor in
                scheduleTrialReminders(trialStart: trialStart, duration: duration)
            }
        }
    }

    static func cancelTrialReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [reminderIdentifier, finalIdentifier]
        )
    }

    // MARK: - Private

    private static func add(
        identifier: String,
        title: String,
        body: String,
        fireAt: Date,
        center: UNUserNotificationCenter
    ) {
        // Nudge into daylight hours — nobody wants a billing reminder at 03:00.
        let target = daytime(fireAt)
        guard target > Date().addingTimeInterval(60) else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: target
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    /// Clamps a fire date to 11:00 local time on the same day.
    private static func daytime(_ date: Date) -> Date {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month, .day], from: date)
        comps.hour = 11
        comps.minute = 0
        return calendar.date(from: comps) ?? date
    }
}
