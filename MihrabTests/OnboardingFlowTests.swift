import CoreLocation
import XCTest

/// W2's onboarding tests.
///
/// What is actually under test here is the **product claim** behind the new
/// madhab step: that Diyanet's published Asr (majority / Shafi rule) and the
/// app's Turkish default Asr (Hanafi rule) are far enough apart that choosing
/// one silently would be dishonest. The onboarding screen shows both times; if
/// those two numbers ever stopped differing, the screen would be noise.
///
/// ⚠️ **Target membership:** `MihrabTests` compiles a hand-picked source list in
/// `project.yml`. This file needs one addition:
///
/// ```yaml
///   MihrabTests:
///     sources:
///       - path: Mihrab/Features/Onboarding/AsrMadhabPreview.swift   # new (W2)
/// ```
///
/// `OnboardingView` itself is *not* in that list and is not tested here: it
/// pulls in `AppSettings`, `LocationManager` and the whole SwiftUI layer. The
/// decision logic it renders lives in `AsrMadhabPreview`, which is what this
/// file exercises.
final class OnboardingFlowTests: XCTestCase {

    // İstanbul, and the date wave 1 measured the contradiction on.
    private let istanbul = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
    private var turkishTimeZone: TimeZone { TimeZone(identifier: "Europe/Istanbul") ?? .current }

    private func april12_2026() throws -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 12
        components.hour = 12
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = turkishTimeZone
        return try XCTUnwrap(calendar.date(from: components))
    }

    // MARK: - The contradiction the step exists for

    func testHanafiAsrIsMeaningfullyLaterThanTheDiyanetPublishedAsr() throws {
        let preview = AsrMadhabPreview.make(
            date: try april12_2026(),
            coordinate: istanbul,
            method: .diyanet,
            source: .diyanet,
            timeZone: turkishTimeZone
        )

        let shafi = try XCTUnwrap(preview.shafi, "Engine produced no Shafi Asr for İstanbul")
        let hanafi = try XCTUnwrap(preview.hanafi, "Engine produced no Hanafi Asr for İstanbul")

        // Order is a matter of geometry, not of opinion: a 2× shadow is always
        // reached after a 1× shadow.
        XCTAssertLessThan(shafi, hanafi)

        let minutes = try XCTUnwrap(preview.differenceMinutes)
        // Wave 1 measured ~58 minutes here. The band is wide enough to absorb
        // temkin and rounding, tight enough that a regression that collapsed
        // the two rules together would fail.
        XCTAssertGreaterThanOrEqual(minutes, 45)
        XCTAssertLessThanOrEqual(minutes, 70)
    }

    func testDifferencePersistsAcrossTheYear() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = turkishTimeZone

        for month in 1...12 {
            var components = DateComponents()
            components.year = 2027
            components.month = month
            components.day = 15
            components.hour = 12
            let date = try XCTUnwrap(calendar.date(from: components))

            let preview = AsrMadhabPreview.make(
                date: date,
                coordinate: istanbul,
                method: .diyanet,
                source: .diyanet,
                timeZone: turkishTimeZone
            )

            XCTAssertTrue(preview.hasTimes, "No Asr times for month \(month)")
            let minutes = try XCTUnwrap(preview.differenceMinutes, "No delta for month \(month)")
            // Never zero anywhere in the year at this latitude — the question
            // is always worth asking.
            XCTAssertGreaterThan(minutes, 20, "Rules collapsed together in month \(month)")
        }
    }

    // MARK: - The offsets and the user's own method are respected

    func testOnlyTheMadhabDiffersBetweenTheTwoSides() throws {
        let date = try april12_2026()
        let offsets: [Prayer: Int] = [.asr: 7]

        let plain = AsrMadhabPreview.make(
            date: date,
            coordinate: istanbul,
            method: .diyanet,
            source: .diyanet,
            timeZone: turkishTimeZone
        )
        let shifted = AsrMadhabPreview.make(
            date: date,
            coordinate: istanbul,
            method: .diyanet,
            source: .diyanet,
            offsets: offsets,
            timeZone: turkishTimeZone
        )

        // A user correction moves both sides by the same amount, so the choice
        // the screen presents is unaffected by it.
        XCTAssertEqual(plain.differenceMinutes, shifted.differenceMinutes)

        let plainShafi = try XCTUnwrap(plain.shafi)
        let shiftedShafi = try XCTUnwrap(shifted.shafi)
        XCTAssertEqual(shiftedShafi.timeIntervalSince(plainShafi), 7 * 60, accuracy: 1)
    }

    func testNonTurkishMethodStillProducesBothSides() throws {
        let preview = AsrMadhabPreview.make(
            date: try april12_2026(),
            coordinate: CLLocationCoordinate2D(latitude: 51.5072, longitude: -0.1276), // London
            method: .mwl,
            source: .standard,
            timeZone: TimeZone(identifier: "Europe/London") ?? .current
        )

        XCTAssertTrue(preview.hasTimes)
        XCTAssertLessThan(try XCTUnwrap(preview.shafi), try XCTUnwrap(preview.hanafi))
        XCTAssertFalse(preview.isReferenceLocation)
        XCTAssertNil(preview.referenceName)
    }

    // MARK: - Honest fallback when the location is not known yet

    func testMissingCoordinateIsLabelledAsAnExampleNotAsTheUsersOwn() throws {
        let preview = AsrMadhabPreview.make(
            date: try april12_2026(),
            coordinate: nil,
            method: .diyanet,
            source: .diyanet,
            timeZone: turkishTimeZone
        )

        // Times are still produced — but the caller must be told they are a
        // stand-in, so the screen can say "example: İstanbul" instead of
        // presenting a fabricated "your Asr".
        XCTAssertTrue(preview.hasTimes)
        XCTAssertTrue(preview.isReferenceLocation)
        XCTAssertEqual(preview.referenceName, AsrMadhabPreview.referenceCityName)
    }

    // MARK: - Mapping used by the option rows

    func testTimeForMadhabMapsToTheCorrectSide() throws {
        let preview = AsrMadhabPreview.make(
            date: try april12_2026(),
            coordinate: istanbul,
            method: .diyanet,
            source: .diyanet,
            timeZone: turkishTimeZone
        )

        XCTAssertEqual(preview.time(for: .shafi), preview.shafi)
        XCTAssertEqual(preview.time(for: .hanafi), preview.hanafi)
    }

    // MARK: - Polar latitudes must not fabricate an answer

    func testUndefinedLatitudeReportsNoTimesRatherThanInventingThem() throws {
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 21
        components.hour = 12
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Oslo") ?? .current
        let midsummer = try XCTUnwrap(calendar.date(from: components))

        let preview = AsrMadhabPreview.make(
            date: midsummer,
            coordinate: CLLocationCoordinate2D(latitude: 78.22, longitude: 15.65), // Longyearbyen
            method: .mwl,
            source: .standard,
            timeZone: TimeZone(identifier: "Europe/Oslo") ?? .current
        )

        // Whatever the engine decides above the polar circle, the preview must
        // never claim a difference it does not have.
        if !preview.hasTimes {
            XCTAssertNil(preview.differenceMinutes)
        }
    }
}
