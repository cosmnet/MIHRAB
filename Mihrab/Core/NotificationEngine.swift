import Foundation
import UserNotifications

/// Local notification engine: prayer alerts 10 days ahead, daily hadith,
/// religious days, Jumu'ah. Respects the iOS 64-pending cap by prioritizing
/// prayer alerts (§10).
@MainActor
final class NotificationEngine {
    static let shared = NotificationEngine()

    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge, .timeSensitive])) ?? false
    }

    func rescheduleAll() async {
        let settings = await MainActor.run { AppSettings.shared }
        let repository = await MainActor.run { PrayerTimesRepository.shared }

        center.removeAllPendingNotificationRequests()

        // 1. Prayer alerts from the cached month (highest priority).
        if let snapshot = SharedPrayerCache.load() {
            var scheduled = 0
            for day in snapshot.days {
                for prayer in Prayer.allCases where prayer.isNotifiable {
                    guard scheduled < 50 else { break }
                    guard settings.isNotificationEnabled(for: prayer),
                          let time = day.time(for: prayer), time > Date() else { continue }
                    schedulePrayerAlert(prayer: prayer, at: time)
                    scheduled += 1
                }
            }
        }

        // 2. Daily hadith at 09:00.
        scheduleDailyHadith()

        // 3. Religious-day alerts (day before 18:00 + morning of 09:00).
        if let hijri = repository.today?.hijriDate {
            for item in BundledContent.upcomingReligiousDays(from: hijri) where item.daysUntil > 0 && item.daysUntil <= 30 {
                scheduleReligiousDay(item.day, daysUntil: item.daysUntil)
            }
        }

        // 4. Jumu'ah reminder on Friday morning.
        scheduleJumuah()
    }

    private func schedulePrayerAlert(prayer: Prayer, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = L10n.prayerAlertTitle(prayer.localizedNamazName)
        content.body = L10n.prayerAlertBody(prayer.localizedNamazName)
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: "prayer-\(prayer.rawValue)-\(date.timeIntervalSince1970)",
            content: content, trigger: trigger
        )
        center.add(request)
    }

    private func scheduleDailyHadith() {
        let hadith = BundledContent.hadith()
        let content = UNMutableNotificationContent()
        content.title = L10n.dailyHadith
        content.body = String((Locale.mihrabIsTurkish ? hadith.tr : hadith.en).prefix(180))
        content.sound = .default

        var comps = DateComponents()
        comps.hour = 9
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: "daily-hadith", content: content, trigger: trigger))
    }

    private func scheduleReligiousDay(_ day: ReligiousDay, daysUntil: Int) {
        guard let targetDate = Calendar.current.date(byAdding: .day, value: daysUntil, to: Date()) else { return }
        let calendar = Calendar.current

        for (offset, hour, suffix) in [(-1, 18, "tomorrow"), (0, 9, "today")] {
            guard let date = calendar.date(byAdding: .day, value: offset, to: targetDate),
                  date > Date() else { continue }
            let content = UNMutableNotificationContent()
            content.title = day.localizedName
            content.body = "\(day.localizedName) — \(day.localizedDescription.prefix(100))"
            content.sound = .default
            let comps = calendar.dateComponents([.year, .month, .day], from: date)
            var full = comps
            full.hour = hour
            let trigger = UNCalendarNotificationTrigger(dateMatching: full, repeats: false)
            center.add(UNNotificationRequest(
                identifier: "religious-\(day.id)-\(offset)", content: content, trigger: trigger))
        }
    }

    private func scheduleJumuah() {
        let content = UNMutableNotificationContent()
        content.title = L10n.jumuahTitle
        content.body = L10n.jumuahBody
        content.sound = .default

        var comps = DateComponents()
        comps.weekday = 6 // Friday
        comps.hour = 10
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: "jumuah", content: content, trigger: trigger))
    }
}
