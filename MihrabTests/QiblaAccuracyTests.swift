import CoreLocation
import XCTest

/// Agent W5's tests: the accuracy gate, the on-device solar astronomy, and the
/// derived kerahat / night windows.
///
/// The astronomy assertions are all against values that can be checked against
/// an independent source (NOAA's own calculator, or a textbook): solstice
/// declination, the equation-of-time extrema, solar-noon azimuth. Nothing here
/// asserts a number that only this implementation could produce.
final class QiblaAccuracyGateTests: XCTestCase {

    private func makeUTC(_ year: Int, _ month: Int, _ day: Int,
                         _ hour: Int = 0, _ minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: components)!
    }

    // MARK: - Accuracy gate

    func testNegativeAccuracyIsInvalidAndNeverTrusted() {
        let accuracy = QiblaAccuracy.evaluate(trueHeading: 120, magneticHeading: 115, headingAccuracy: -1)
        XCTAssertEqual(accuracy.confidence, .invalid)
        XCTAssertFalse(accuracy.isTrustworthy, "A negative headingAccuracy must never light the lock-on")
        XCTAssertTrue(accuracy.needsCalibration)
        XCTAssertNil(accuracy.reportedError, "We must not print an error bar CoreLocation called meaningless")
    }

    func testThresholdBoundaryIsInclusiveOfTwentyDegrees() {
        let atThreshold = QiblaAccuracy.evaluate(trueHeading: 10, magneticHeading: 10,
                                                 headingAccuracy: QiblaAccuracy.coarseThreshold)
        XCTAssertEqual(atThreshold.confidence, .good)
        XCTAssertTrue(atThreshold.isTrustworthy)

        let justOver = QiblaAccuracy.evaluate(trueHeading: 10, magneticHeading: 10,
                                              headingAccuracy: QiblaAccuracy.coarseThreshold + 0.01)
        XCTAssertEqual(justOver.confidence, .coarse)
        XCTAssertFalse(justOver.isTrustworthy)
        XCTAssertTrue(justOver.needsCalibration)
    }

    func testMagneticFallbackIsReportedNotHidden() {
        // trueHeading < 0 is CoreLocation's way of saying "no location fix, so
        // I cannot correct for declination".
        let accuracy = QiblaAccuracy.evaluate(trueHeading: -1, magneticHeading: 200, headingAccuracy: 5)
        XCTAssertEqual(accuracy.reference, .magnetic)
        XCTAssertTrue(accuracy.isMagneticFallback,
                      "Falling back to magnetic north silently is the exact failure this gate exists to prevent")
        XCTAssertTrue(accuracy.isTrustworthy, "A precise magnetic reading is still usable — just disclosed")
    }

    func testNoHeadingAtAllIsUnavailable() {
        let accuracy = QiblaAccuracy.evaluate(trueHeading: -1, magneticHeading: -1, headingAccuracy: -1)
        XCTAssertEqual(accuracy.confidence, .unavailable)
        XCTAssertEqual(accuracy.reference, .none)
        XCTAssertFalse(accuracy.hasHeading)
        XCTAssertFalse(accuracy.isTrustworthy)
    }

    func testNilHeadingIsUnavailable() {
        let accuracy = QiblaAccuracy.evaluate(nil)
        XCTAssertEqual(accuracy.confidence, .unavailable)
        XCTAssertFalse(accuracy.hasHeading)
    }

    // MARK: - Qibla bearing invariants

    /// Along the Kaaba's own meridian the answer is not a matter of opinion:
    /// due south from the north, due north from the south.
    func testBearingOnKaabaMeridian() {
        let north = QiblaMath.bearing(fromLatitude: 45, longitude: QiblaMath.kaabaLongitude)
        XCTAssertEqual(north, 180, accuracy: 0.001)

        let south = QiblaMath.bearing(fromLatitude: -10, longitude: QiblaMath.kaabaLongitude)
        XCTAssertEqual(south, 0, accuracy: 0.001)
    }

    /// On the equator, a point 90° of longitude to the west of a point on the
    /// equator sees it due east. The Kaaba is not on the equator, so we only
    /// assert the hemisphere, which is still a real regression guard.
    func testBearingHemispheres() {
        // East of Makkah → the Qibla is somewhere westward.
        let jakarta = QiblaMath.bearing(fromLatitude: -6.2088, longitude: 106.8456)
        XCTAssertTrue(jakarta > 180 && jakarta < 360, "Jakarta must face west of north, got \(jakarta)")

        // West of Makkah and north of it → the Qibla is somewhere east of south.
        let london = QiblaMath.bearing(fromLatitude: 51.5074, longitude: -0.1278)
        XCTAssertTrue(london > 90 && london < 180, "London must face south-east, got \(london)")

        // South of Makkah and west of it → north-east.
        let capeTown = QiblaMath.bearing(fromLatitude: -33.9249, longitude: 18.4241)
        XCTAssertTrue(capeTown > 0 && capeTown < 90, "Cape Town must face north-east, got \(capeTown)")
    }

    func testDistanceToMakkahIsZeroAtTheKaaba() {
        let distance = QiblaMath.distanceToMakkah(fromLatitude: QiblaMath.kaabaLatitude,
                                                  longitude: QiblaMath.kaabaLongitude)
        XCTAssertEqual(distance, 0, accuracy: 0.001)
    }

    // MARK: - Solar declination and equation of time

    /// Solstice and equinox declinations. Obliquity is 23.44°, so the June
    /// solstice peaks there and the equinoxes cross zero.
    func testDeclinationAtSolsticesAndEquinoxes() {
        // 2026-06-21 12:00 UTC — within hours of the solstice.
        let june = SolarMath.solarParameters(at: makeUTC(2026, 6, 21, 12)).declination
        XCTAssertEqual(june, 23.44, accuracy: 0.1)

        // 2026-12-21 12:00 UTC.
        let december = SolarMath.solarParameters(at: makeUTC(2026, 12, 21, 12)).declination
        XCTAssertEqual(december, -23.44, accuracy: 0.1)

        // 2026-03-20 — March equinox is 2026-03-20 around 14:46 UTC.
        let march = SolarMath.solarParameters(at: makeUTC(2026, 3, 20, 15)).declination
        XCTAssertEqual(march, 0, accuracy: 0.15)
    }

    /// The equation of time has four well-known turning points; these are the
    /// two extremes, and they are independent of the year to within a minute.
    func testEquationOfTimeExtremes() {
        // Mid-February minimum: about −14.2 minutes.
        let february = SolarMath.solarParameters(at: makeUTC(2026, 2, 11, 12)).equationOfTime
        XCTAssertEqual(february, -14.2, accuracy: 1.0)

        // Early-November maximum: about +16.4 minutes.
        let november = SolarMath.solarParameters(at: makeUTC(2026, 11, 3, 12)).equationOfTime
        XCTAssertEqual(november, 16.4, accuracy: 1.0)
    }

    // MARK: - Solar position

    /// London on the June solstice: the sun tops out at 90 − latitude +
    /// declination = 61.9°, due south. Solar noon there is ~12:02 UTC, so
    /// 12:00 UTC is within a whisker of the maximum.
    func testLondonSolsticeNoon() {
        let london = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
        let position = SolarMath.position(at: makeUTC(2026, 6, 21, 12), coordinate: london)

        XCTAssertEqual(position.altitude, 90 - 51.5074 + 23.44, accuracy: 0.5)
        XCTAssertEqual(position.azimuth, 180, accuracy: 3.0)
    }

    /// At local solar noon the sun is due south for any northern-hemisphere
    /// place further north than the declination — an exact, checkable fact.
    func testAzimuthIsDueSouthAtLocalSolarNoon() {
        let istanbul = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!

        let noon = SolarMath.localSolarNoon(on: makeUTC(2026, 3, 20, 10),
                                            coordinate: istanbul,
                                            calendar: calendar)
        let position = SolarMath.position(at: noon, coordinate: istanbul)
        XCTAssertEqual(position.azimuth, 180, accuracy: 0.3)
        // Equinox: altitude at noon ≈ 90 − latitude.
        XCTAssertEqual(position.altitude, 90 - 41.0082, accuracy: 0.6)
    }

    /// Southern hemisphere: the noon sun stands due *north*.
    func testAzimuthIsDueNorthAtSouthernSolarNoon() {
        let sydney = CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Sydney")!

        let noon = SolarMath.localSolarNoon(on: makeUTC(2026, 6, 21, 2),
                                            coordinate: sydney,
                                            calendar: calendar)
        let position = SolarMath.position(at: noon, coordinate: sydney)
        // Due north is 0°/360° — compare through the wrap.
        let offNorth = abs(QiblaMath.shortestDelta(from: position.azimuth, to: 0))
        XCTAssertLessThan(offNorth, 0.5, "Southern-hemisphere noon sun must be due north, got \(position.azimuth)")
    }

    func testAltitudeIsNegativeAtLocalMidnight() {
        let istanbul = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
        // 00:00 Istanbul time on a summer night = 21:00 UTC the day before.
        let position = SolarMath.position(at: makeUTC(2026, 6, 20, 21), coordinate: istanbul)
        XCTAssertLessThan(position.altitude, 0)
    }

    func testShadowIsOppositeTheSun() {
        let istanbul = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
        let position = SolarMath.position(at: makeUTC(2026, 5, 1, 9), coordinate: istanbul)
        let separation = abs(QiblaMath.shortestDelta(from: position.azimuth, to: position.shadowAzimuth))
        XCTAssertEqual(separation, 180, accuracy: 0.001)
    }

    // MARK: - Rashdul Qibla (Istiwa al-A'zam)

    /// Derived, not hard-coded — but it must land where the published Rashdul
    /// Qibla dates land: late May and mid July.
    func testRashdulQiblaFallsInTheExpectedWindows() {
        let moments = SolarMath.rashdulQiblaMoments(after: makeUTC(2026, 1, 1), limit: 2)
        XCTAssertEqual(moments.count, 2, "There are exactly two per year")

        var mecca = Calendar(identifier: .gregorian)
        mecca.timeZone = TimeZone(identifier: "Asia/Riyadh")!   // UTC+3, Mecca local time

        let first = mecca.dateComponents([.month, .day, .hour], from: moments[0])
        XCTAssertEqual(first.month, 5)
        XCTAssertTrue((26...29).contains(first.day ?? 0),
                      "Expected late May, got day \(first.day ?? -1)")
        XCTAssertTrue((11...13).contains(first.hour ?? 0),
                      "Kaaba transit is around local midday, got hour \(first.hour ?? -1)")

        let second = mecca.dateComponents([.month, .day, .hour], from: moments[1])
        XCTAssertEqual(second.month, 7)
        XCTAssertTrue((14...18).contains(second.day ?? 0),
                      "Expected mid July, got day \(second.day ?? -1)")
    }

    /// The real assertion behind the feature: at those instants the sun really
    /// is (almost exactly) overhead the Kaaba.
    func testSunIsOverheadTheKaabaAtRashdulQibla() {
        let kaaba = CLLocationCoordinate2D(latitude: QiblaMath.kaabaLatitude,
                                           longitude: QiblaMath.kaabaLongitude)
        for moment in SolarMath.rashdulQiblaMoments(after: makeUTC(2026, 1, 1), limit: 2) {
            let position = SolarMath.position(at: moment, coordinate: kaaba)
            XCTAssertGreaterThan(position.altitude, 89.5,
                                 "Sun should be within half a degree of the zenith over the Kaaba")
        }
    }

    func testRashdulQiblaIsStableAcrossYears() {
        // Same two windows next year, computed independently.
        let moments = SolarMath.rashdulQiblaMoments(after: makeUTC(2027, 1, 1), limit: 2)
        XCTAssertEqual(moments.count, 2)
        var mecca = Calendar(identifier: .gregorian)
        mecca.timeZone = TimeZone(identifier: "Asia/Riyadh")!
        XCTAssertEqual(mecca.component(.month, from: moments[0]), 5)
        XCTAssertEqual(mecca.component(.month, from: moments[1]), 7)
    }

    // MARK: - Sun on the local Qibla

    /// Self-consistency: whatever moment we hand the user, the sun's azimuth at
    /// that moment must actually equal the Qibla bearing.
    func testSunOnQiblaMomentsReallyPointAtTheQibla() {
        let istanbul = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
        let bearing = QiblaMath.bearing(fromLatitude: istanbul.latitude, longitude: istanbul.longitude)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!

        let moments = SolarMath.sunOnQiblaMoments(on: makeUTC(2026, 5, 15, 9),
                                                  coordinate: istanbul,
                                                  qiblaBearing: bearing,
                                                  calendar: calendar)
        XCTAssertFalse(moments.isEmpty, "Istanbul's qibla is south-east; the sun crosses it every clear day")

        for moment in moments {
            let position = SolarMath.position(at: moment, coordinate: istanbul)
            let error = abs(QiblaMath.shortestDelta(from: position.azimuth, to: bearing))
            XCTAssertLessThan(error, 0.05, "Crossing solved to \(error)° — bisection did not converge")
            XCTAssertGreaterThanOrEqual(position.altitude, 3,
                                        "A moment with no usable shadow must not be offered")
        }
    }

    /// A bearing the sun can never reach at this latitude must yield nothing
    /// rather than a fabricated time.
    func testNoSunOnQiblaMomentWhenTheBearingIsUnreachable() {
        let istanbul = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!

        // Due north in midwinter: the sun never gets there.
        let moments = SolarMath.sunOnQiblaMoments(on: makeUTC(2026, 12, 15, 9),
                                                  coordinate: istanbul,
                                                  qiblaBearing: 0,
                                                  calendar: calendar)
        XCTAssertTrue(moments.isEmpty)
    }

    // MARK: - Altitude crossings

    func testSpearAltitudeCrossingsBracketSolarNoon() {
        let istanbul = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        let day = makeUTC(2026, 5, 15, 9)

        let rising = SolarMath.time(atAltitude: 5, rising: true, on: day,
                                    coordinate: istanbul, calendar: calendar)
        let falling = SolarMath.time(atAltitude: 5, rising: false, on: day,
                                     coordinate: istanbul, calendar: calendar)
        let noon = SolarMath.localSolarNoon(on: day, coordinate: istanbul, calendar: calendar)

        XCTAssertNotNil(rising)
        XCTAssertNotNil(falling)
        XCTAssertLessThan(rising!, noon)
        XCTAssertGreaterThan(falling!, noon)

        XCTAssertEqual(SolarMath.position(at: rising!, coordinate: istanbul).altitude, 5, accuracy: 0.01)
        XCTAssertEqual(SolarMath.position(at: falling!, coordinate: istanbul).altitude, 5, accuracy: 0.01)
    }

    /// Polar night: no crossing exists, and the solver must say so instead of
    /// returning a plausible-looking date.
    func testNoAltitudeCrossingInPolarNight() {
        let tromso = CLLocationCoordinate2D(latitude: 78.2232, longitude: 15.6267) // Svalbard
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Oslo")!
        let crossing = SolarMath.time(atAltitude: 5, rising: true,
                                      on: makeUTC(2026, 12, 21, 12),
                                      coordinate: tromso, calendar: calendar)
        XCTAssertNil(crossing)
    }

    // MARK: - Derived devotional windows

    func testMakruhWindowsAreOrderedAndDerivedFromRealTransit() {
        let istanbul = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!

        let configuration = PrayerEngineConfiguration(method: .diyanet,
                                                      madhab: .hanafi,
                                                      source: .diyanet,
                                                      timeZone: calendar.timeZone)
        guard let day = PrayerEngine.times(for: makeUTC(2026, 5, 15, 9),
                                          coordinate: istanbul,
                                          configuration: configuration) else {
            return XCTFail("Engine produced no schedule for Istanbul")
        }

        let windows = DevotionalWindows.makruhWindows(for: day, coordinate: istanbul, calendar: calendar)
        XCTAssertEqual(windows.count, 3, "Istanbul in May has all three windows")
        XCTAssertEqual(windows.map(\.kind), [.ishraq, .istiwa, .isfirar])

        for window in windows {
            XCTAssertGreaterThan(window.end, window.start, "\(window.kind) window must have positive length")
        }
        XCTAssertLessThan(windows[0].end, windows[1].start)
        XCTAssertLessThan(windows[1].end, windows[2].start)

        // The istiva window is exactly [true transit, published öğle] — its
        // length is the Diyanet temkin, which adhan-swift sets to +5 minutes.
        let transit = SolarMath.localSolarNoon(on: day.date, coordinate: istanbul, calendar: calendar)
        XCTAssertEqual(windows[1].start.timeIntervalSince(transit), 0, accuracy: 1)
        XCTAssertEqual(windows[1].end, day.time(for: .dhuhr))
        XCTAssertEqual(windows[1].duration / 60, 5, accuracy: 1.5,
                       "Diyanet öğle carries +5 minutes of temkin over the true transit")
    }

    func testNightDivisionsSplitMaghribToNextFajr() {
        let istanbul = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        let configuration = PrayerEngineConfiguration(method: .diyanet,
                                                      madhab: .hanafi,
                                                      source: .diyanet,
                                                      timeZone: calendar.timeZone)

        let today = makeUTC(2026, 5, 15, 9)
        let tomorrow = today.addingTimeInterval(86_400)
        guard let day = PrayerEngine.times(for: today, coordinate: istanbul, configuration: configuration),
              let next = PrayerEngine.times(for: tomorrow, coordinate: istanbul, configuration: configuration),
              let divisions = DevotionalWindows.nightDivisions(day: day, tomorrow: next) else {
            return XCTFail("Engine produced no schedule for Istanbul")
        }

        XCTAssertEqual(divisions.start, day.time(for: .maghrib))
        XCTAssertEqual(divisions.end, next.time(for: .fajr))
        XCTAssertEqual(divisions.middleOfTheNight.timeIntervalSince(divisions.start),
                       divisions.duration / 2, accuracy: 1)
        XCTAssertEqual(divisions.lastThirdOfTheNight.timeIntervalSince(divisions.start),
                       divisions.duration * 2 / 3, accuracy: 1)
        XCTAssertLessThan(divisions.middleOfTheNight, divisions.lastThirdOfTheNight)
    }

    func testNightDivisionsAreNilWithoutTomorrow() {
        let day = DayPrayerTimes(date: makeUTC(2026, 5, 15),
                                 times: [.maghrib: makeUTC(2026, 5, 15, 17)])
        XCTAssertNil(DevotionalWindows.nightDivisions(day: day, tomorrow: nil))
    }
}
