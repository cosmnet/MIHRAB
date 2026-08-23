import XCTest

/// Needs `Mihrab/Core/Backdrop/DaySegment.swift` and
/// `Mihrab/Core/Backdrop/L10n+Backdrop.swift` in the test target's sources —
/// this target compiles app files directly rather than importing the module.
///
/// Covers the pure piece behind the redesigned Today backdrop: which part of the
/// day it should be painting, and that it says nothing when it does not know.
final class DaySegmentTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func day(_ hoursAndMinutes: [Prayer: (Int, Int)]) -> DayPrayerTimes {
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 12
        let base = calendar.date(from: components)!
        var times: [Prayer: Date] = [:]
        for (prayer, hm) in hoursAndMinutes {
            times[prayer] = calendar.date(byAdding: DateComponents(hour: hm.0, minute: hm.1), to: base)!
        }
        return DayPrayerTimes(date: base, times: times)
    }

    private var schedule: DayPrayerTimes {
        day([
            .fajr: (5, 10),
            .sunrise: (6, 35),
            .dhuhr: (13, 5),
            .asr: (16, 20),
            .maghrib: (19, 25),
            .isha: (20, 45)
        ])
    }

    private func at(_ hour: Int, _ minute: Int) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 12
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }

    func testSegmentsAcrossTheDay() {
        let cases: [(Int, Int, DaySegment)] = [
            (2, 0, .night),
            (5, 30, .fajr),
            (6, 50, .sunrise),
            (9, 0, .morning),
            (14, 0, .dhuhr),
            (17, 0, .asr),
            (19, 40, .maghrib),
            (21, 30, .isha),
            (23, 30, .night)
        ]
        for (hour, minute, expected) in cases {
            XCTAssertEqual(
                DaySegment.resolve(now: at(hour, minute), today: schedule),
                expected,
                "\(hour):\(minute) should read as \(expected.rawValue)"
            )
        }
    }

    /// With no schedule we say nothing rather than guessing from the clock.
    func testNoScheduleYieldsNoSegment() {
        XCTAssertNil(DaySegment.resolve(now: at(12, 0), today: nil))
    }

    func testEverySegmentHasAVeilInsideTheCeiling() {
        for segment in DaySegment.allCases {
            XCTAssertLessThanOrEqual(segment.palette.strength, 1.0)
            XCTAssertGreaterThan(segment.palette.strength, 0)
        }
    }
}
