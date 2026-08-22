import XCTest

final class QiblaMathTests: XCTestCase {
    /// Reference bearings verified against known qibla directions (§8).
    func testKnownBearings() {
        let cases: [(name: String, lat: Double, lon: Double, expected: Double)] = [
            ("Istanbul", 41.0082, 28.9784, 152.0),
            ("New York", 40.7128, -74.0060, 58.5),
            ("Jakarta", -6.2088, 106.8456, 295.0),
            ("London", 51.5074, -0.1278, 119.0),
            ("Tokyo", 35.6762, 139.6503, 293.0),
            ("Cairo", 30.0444, 31.2357, 136.0),
            ("Karachi", 24.8607, 67.0011, 268.0),
            ("Sydney", -33.8688, 151.2093, 277.0),
            ("Cape Town", -33.9249, 18.4241, 23.0),
            ("Berlin", 52.5200, 13.4050, 138.0),
        ]
        for testCase in cases {
            let bearing = QiblaMath.bearing(fromLatitude: testCase.lat, longitude: testCase.lon)
            XCTAssertEqual(bearing, testCase.expected, accuracy: 2.0,
                           "\(testCase.name): got \(bearing), expected ~\(testCase.expected)")
        }
    }

    func testBearingRange() {
        for lat in stride(from: -60.0, through: 60.0, by: 15) {
            for lon in stride(from: -180.0, through: 180.0, by: 30) {
                let bearing = QiblaMath.bearing(fromLatitude: lat, longitude: lon)
                XCTAssertGreaterThanOrEqual(bearing, 0)
                XCTAssertLessThan(bearing, 360)
            }
        }
    }

    func testDistanceToMakkah() {
        // Istanbul → Makkah ≈ 2,400 km (great-circle).
        let distance = QiblaMath.distanceToMakkah(fromLatitude: 41.0082, longitude: 28.9784)
        XCTAssertEqual(distance, 2400, accuracy: 150)
    }

    func testShortestDelta() {
        XCTAssertEqual(QiblaMath.shortestDelta(from: 350, to: 10), 20, accuracy: 0.001)
        XCTAssertEqual(QiblaMath.shortestDelta(from: 10, to: 350), -20, accuracy: 0.001)
        XCTAssertEqual(QiblaMath.shortestDelta(from: 0, to: 180), 180, accuracy: 0.001)
    }
}

final class PrayerTimesTests: XCTestCase {
    private func makeDay(offsetMinutes: [Prayer: Int]) -> DayPrayerTimes {
        let start = Calendar.current.startOfDay(for: Date())
        var times: [Prayer: Date] = [:]
        for (prayer, minutes) in offsetMinutes {
            times[prayer] = start.addingTimeInterval(TimeInterval(minutes * 60))
        }
        return DayPrayerTimes(date: start, times: times)
    }

    func testNextPrayerOrdering() {
        // Fajr 05:00, Sunrise 06:30, Dhuhr 13:00, Asr 16:00, Maghrib 19:30, Isha 21:00
        let day = makeDay(offsetMinutes: [
            .fajr: 300, .sunrise: 390, .dhuhr: 780, .asr: 960, .maghrib: 1170, .isha: 1260,
        ])
        let noon = Calendar.current.startOfDay(for: Date()).addingTimeInterval(12 * 3600)
        XCTAssertEqual(day.nextPrayer(after: noon)?.prayer, .dhuhr)
        XCTAssertEqual(day.previousPrayer(before: noon)?.prayer, .sunrise)
    }

    func testSafeCountdownRejectsNonIncreasingRange() {
        let now = Date()
        XCTAssertNil(SafeCountdown.range(from: now, to: now))
        XCTAssertNil(SafeCountdown.range(from: now, to: now.addingTimeInterval(-1)))
        XCTAssertNil(SafeCountdown.range(from: now, to: now.addingTimeInterval(0.01)))
        XCTAssertNotNil(SafeCountdown.range(from: now, to: now.addingTimeInterval(1)))
    }

    func testLocalizedPrayerNamesAreNonEmpty() {
        for prayer in Prayer.allCases {
            XCTAssertFalse(prayer.localizedName.isEmpty, prayer.rawValue)
            XCTAssertFalse(prayer.localizedNamazName.isEmpty, prayer.rawValue)
            XCTAssertFalse(prayer.countdownLabel.isEmpty, prayer.rawValue)
        }
    }

    func testPostMidnightRollsToTomorrowFajr() {
        let day = makeDay(offsetMinutes: [
            .fajr: 300, .sunrise: 390, .dhuhr: 780, .asr: 960, .maghrib: 1170, .isha: 1260,
        ])
        let tomorrow = makeDay(offsetMinutes: [
            .fajr: 299, .sunrise: 389, .dhuhr: 780, .asr: 960, .maghrib: 1170, .isha: 1260,
        ])
        let lateNight = Calendar.current.startOfDay(for: Date()).addingTimeInterval(23 * 3600)
        let next = day.nextPrayer(after: lateNight, tomorrow: tomorrow)
        XCTAssertEqual(next?.prayer, .fajr)
        XCTAssertNotNil(next?.date)
    }
}

final class BundledContentTests: XCTestCase {
    func testHadithDatasetLoads() {
        XCTAssertGreaterThanOrEqual(BundledContent.hadiths.count, 30)
        for hadith in BundledContent.hadiths {
            XCTAssertFalse(hadith.arabic.isEmpty)
            XCTAssertFalse(hadith.en.isEmpty)
            XCTAssertFalse(hadith.tr.isEmpty)
            XCTAssertFalse(hadith.source.isEmpty)
        }
    }

    func testEsmaHas99Names() {
        XCTAssertEqual(BundledContent.esma.count, 99)
    }

    func testDailyHadithIsDeterministic() {
        let date = Date(timeIntervalSince1970: 1_750_000_000)
        XCTAssertEqual(BundledContent.hadith(for: date), BundledContent.hadith(for: date))
    }

    func testReligiousDaysLoad() {
        XCTAssertGreaterThanOrEqual(BundledContent.religiousDays.count, 10)
        for day in BundledContent.religiousDays {
            XCTAssertFalse(day.nameEn.isEmpty, day.id)
            XCTAssertFalse(day.nameTr.isEmpty, day.id)
            XCTAssertFalse(day.nameAr.isEmpty, day.id)
        }
    }
}
