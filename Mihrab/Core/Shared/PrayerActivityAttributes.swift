import ActivityKit
import Foundation

/// Live Activity attributes for the prayer countdown (Dynamic Island + Lock Screen).
public struct PrayerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public let prayerName: String
        public let prayerArabic: String
        public let prayerTime: Date

        public init(prayerName: String, prayerArabic: String, prayerTime: Date) {
            self.prayerName = prayerName
            self.prayerArabic = prayerArabic
            self.prayerTime = prayerTime
        }
    }

    public let cityName: String

    public init(cityName: String) {
        self.cityName = cityName
    }
}
