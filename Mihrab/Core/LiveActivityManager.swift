import ActivityKit
import Foundation

/// Starts/ends the prayer-countdown Live Activity in the last 30 minutes
/// before a prayer (§5).
final class LiveActivityManager: @unchecked Sendable {
    static let shared = LiveActivityManager()

    // Activity is not Sendable in this SDK; access is serialized through
    // this singleton which is only touched from the main actor in practice.
    private nonisolated(unsafe) var activity: Activity<PrayerActivityAttributes>?

    func update(for day: DayPrayerTimes?, tomorrow: DayPrayerTimes?) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let now = Date()
        guard let next = day?.nextPrayer(after: now, tomorrow: tomorrow) else {
            await end()
            return
        }

        let thirtyMinutes: TimeInterval = 30 * 60
        let withinWindow = next.date.timeIntervalSince(now) <= thirtyMinutes

        if withinWindow {
            let state = PrayerActivityAttributes.ContentState(
                prayerName: next.prayer.localizedNamazName,
                prayerArabic: next.prayer.arabicName,
                prayerTime: next.date
            )
            if let activity {
                await activity.update(.init(state: state, staleDate: next.date))
            } else {
                let attributes = PrayerActivityAttributes(
                    cityName: LocationManager.shared.effectiveCityName
                )
                activity = try? Activity.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: next.date),
                    pushType: nil
                )
            }
        } else {
            await end()
        }
    }

    func end() async {
        let current = activity
        activity = nil
        await current?.end(nil, dismissalPolicy: .immediate)
    }
}
