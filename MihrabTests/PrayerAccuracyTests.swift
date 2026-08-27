import Adhan
import CoreLocation
import XCTest

/// Religious / astronomical correctness of the calculation methods.
///
/// `PrayerEngineTests` proves the engine *runs*. This file proves it produces
/// the numbers the published authorities actually specify:
///
/// 1. Every `CalculationMethod` case maps to the right adhan-swift preset.
/// 2. The twilight angles that come out of that preset equal the angles those
///    authorities publish (MWL 18/17, ISNA 15/15, Umm al-Qura 18.5 + 90 min,
///    Egypt 19.5/17.5, Karachi 18/18, Diyanet 18/17).
/// 3. Diyanet's temkin is really applied, and really equals the table Mihrab
///    shows in the transparency panel — measured against the library rather
///    than transcribed and hoped for. (`CalculationParameters.methodAdjustments`
///    is `internal` to the Adhan module, so the only honest check is a
///    differential one.)
/// 4. The *relative* behaviour is right: a shallower fajr angle must give a
///    later imsak, a deeper isha angle a later yatsı, and so on. This is the
///    check that catches a two-cases-swapped mapping, which absolute range
///    assertions would sail straight past.
/// 5. Chronological order holds for every method, city and season we test.
///
/// Nothing here touches the network.
final class PrayerAccuracyTests: XCTestCase {

    // MARK: - Fixtures

    private let istanbul = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
    private let ankara = CLLocationCoordinate2D(latitude: 39.9334, longitude: 32.8597)
    private let makkah = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)
    private let cairo = CLLocationCoordinate2D(latitude: 30.0444, longitude: 31.2357)
    private let karachiCity = CLLocationCoordinate2D(latitude: 24.8607, longitude: 67.0011)
    private let chicago = CLLocationCoordinate2D(latitude: 41.8781, longitude: -87.6298)

    private let istanbulTZ = "Europe/Istanbul"

    /// Equinox-ish, well away from any DST edge and from the short summer
    /// nights that make high-latitude rules kick in.
    private func date(_ year: Int, _ month: Int, _ day: Int, timeZone: String) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZone)!
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private func configuration(method: CalculationMethod,
                               madhab: Madhab = .shafi,
                               source: PrayerSource = .standard,
                               offsets: [Prayer: Int] = [:],
                               timeZone: String = "Europe/Istanbul") -> PrayerEngineConfiguration {
        PrayerEngineConfiguration(method: method,
                                  madhab: madhab,
                                  source: source,
                                  offsets: offsets,
                                  timeZone: TimeZone(identifier: timeZone)!)
    }

    private func params(_ method: CalculationMethod,
                        source: PrayerSource = .standard,
                        at coordinate: CLLocationCoordinate2D) -> CalculationParameters {
        PrayerEngine.parameters(
            for: configuration(method: method, source: source),
            coordinates: Coordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)
        )
    }

    private func day(_ method: CalculationMethod,
                     source: PrayerSource = .standard,
                     madhab: Madhab = .shafi,
                     at coordinate: CLLocationCoordinate2D,
                     on when: Date,
                     timeZone: String = "Europe/Istanbul") throws -> DayPrayerTimes {
        try XCTUnwrap(
            PrayerEngine.times(for: when,
                               coordinate: coordinate,
                               configuration: configuration(method: method,
                                                            madhab: madhab,
                                                            source: source,
                                                            timeZone: timeZone)),
            "\(method) produced no schedule"
        )
    }

    /// Signed difference in whole minutes, `a − b`.
    private func minutes(_ a: Date, _ b: Date) -> Int {
        Int((a.timeIntervalSince(b) / 60).rounded())
    }

    // MARK: - 1. Method → adhan-swift preset mapping

    /// A swapped case here would silently give every user of that method the
    /// wrong times, with no crash and no visible symptom.
    func testEveryMethodMapsToTheExpectedAdhanPreset() {
        let expected: [CalculationMethod: Adhan.CalculationMethod] = [
            .diyanet: .turkey,
            .ummAlQura: .ummAlQura,
            .isna: .northAmerica,
            .mwl: .muslimWorldLeague,
            .egypt: .egyptian,
            .karachi: .karachi,
        ]
        XCTAssertEqual(Set(expected.keys), Set(CalculationMethod.allCases),
                       "A CalculationMethod case was added or removed without updating this test")
        for (mihrab, adhan) in expected {
            XCTAssertEqual(mihrab.adhanMethod, adhan, "\(mihrab) maps to the wrong adhan-swift preset")
        }
    }

    /// The raw values double as Aladhan API method ids — `AladhanClient` sends
    /// them straight down the wire, so they are not free to change.
    func testMethodRawValuesMatchAladhanMethodIDs() {
        XCTAssertEqual(CalculationMethod.karachi.rawValue, 1)
        XCTAssertEqual(CalculationMethod.isna.rawValue, 2)
        XCTAssertEqual(CalculationMethod.mwl.rawValue, 3)
        XCTAssertEqual(CalculationMethod.ummAlQura.rawValue, 4)
        XCTAssertEqual(CalculationMethod.egypt.rawValue, 5)
        XCTAssertEqual(CalculationMethod.diyanet.rawValue, 13)
    }

    func testMadhabMapsToTheExpectedAdhanSchool() {
        XCTAssertEqual(Madhab.shafi.adhanMadhab, Adhan.Madhab.shafi)
        XCTAssertEqual(Madhab.hanafi.adhanMadhab, Adhan.Madhab.hanafi)
        // Aladhan `school` parameter: 0 = Shafi, 1 = Hanafi.
        XCTAssertEqual(Madhab.shafi.rawValue, 0)
        XCTAssertEqual(Madhab.hanafi.rawValue, 1)
    }

    // MARK: - 2. Published angles

    /// Each authority's own published twilight angles.
    ///
    /// - Muslim World League: fajr 18°, isha 17°.
    /// - ISNA: fajr 15°, isha 15°.
    /// - Umm al-Qura: fajr 18.5°, isha = maghrib + 90 minutes (no angle).
    /// - Egyptian General Authority of Survey: fajr 19.5°, isha 17.5°.
    /// - University of Islamic Sciences, Karachi: fajr 18°, isha 18°.
    /// - Diyanet İşleri Başkanlığı: fajr 18°, isha 17°.
    func testPublishedAnglesPerMethod() {
        let expected: [CalculationMethod: (fajr: Double, isha: Double?, interval: Int)] = [
            .mwl: (18, 17, 0),
            .isna: (15, 15, 0),
            .ummAlQura: (18.5, nil, 90),
            .egypt: (19.5, 17.5, 0),
            .karachi: (18, 18, 0),
            .diyanet: (18, 17, 0),
        ]
        XCTAssertEqual(Set(expected.keys), Set(CalculationMethod.allCases),
                       "A CalculationMethod case was added or removed without updating this test")
        for method in CalculationMethod.allCases {
            guard let want = expected[method] else { continue }
            let p = params(method, at: istanbul)
            XCTAssertEqual(p.fajrAngle, want.fajr, accuracy: 0.0001, "\(method) fajr angle")
            XCTAssertEqual(p.ishaInterval, want.interval, "\(method) isha interval")
            if let ishaAngle = want.isha {
                XCTAssertEqual(p.ishaAngle, ishaAngle, accuracy: 0.0001, "\(method) isha angle")
            }
        }
    }

    /// Umm al-Qura is interval-based, not angle-based: yatsı is exactly 90
    /// minutes after akşam, every day of the year.
    func testUmmAlQuraIshaIsNinetyMinutesAfterMaghrib() throws {
        for (month, dayOfMonth) in [(3, 15), (6, 15), (9, 15), (12, 15)] {
            let d = try day(.ummAlQura, at: makkah,
                            on: date(2026, month, dayOfMonth, timeZone: "Asia/Riyadh"),
                            timeZone: "Asia/Riyadh")
            XCTAssertEqual(minutes(d.times[.isha]!, d.times[.maghrib]!), 90,
                           "Umm al-Qura yatsı must be maghrib + 90 min (2026-\(month)-\(dayOfMonth))")
        }
    }

    // MARK: - 3. Diyanet temkin, measured not assumed

    /// `MethodTemkin.minutes(for: .turkey)` is what the transparency panel
    /// shows the user. Prove the library really applies exactly those numbers
    /// by differencing Diyanet against MWL, which shares both angles (18/17)
    /// and differs only in its method adjustments (dhuhr +1 vs Diyanet's
    /// −7 / +5 / +4 / +7).
    func testDiyanetTemkinIsActuallyApplied() throws {
        let when = date(2026, 3, 15, timeZone: istanbulTZ)
        let diyanet = try day(.diyanet, source: .diyanet, at: istanbul, on: when)
        let mwl = try day(.mwl, source: .standard, at: istanbul, on: when)

        // Diyanet − MWL, given MWL's own +1 minute dhuhr transit correction.
        XCTAssertEqual(minutes(diyanet.times[.sunrise]!, mwl.times[.sunrise]!), -7, "güneş temkin")
        XCTAssertEqual(minutes(diyanet.times[.dhuhr]!, mwl.times[.dhuhr]!), 4, "öğle temkin (5 − MWL's 1)")
        XCTAssertEqual(minutes(diyanet.times[.asr]!, mwl.times[.asr]!), 4, "ikindi temkin")
        XCTAssertEqual(minutes(diyanet.times[.maghrib]!, mwl.times[.maghrib]!), 7, "akşam temkin")
        // Same angles ⇒ imsak and yatsı must be identical; adhan-swift applies
        // no temkin to either for `.turkey`.
        XCTAssertEqual(minutes(diyanet.times[.fajr]!, mwl.times[.fajr]!), 0, "imsak carries no temkin")
        XCTAssertEqual(minutes(diyanet.times[.isha]!, mwl.times[.isha]!), 0, "yatsı carries no temkin")
    }

    /// The panel's copy of the table must equal what the differential test
    /// above just measured.
    func testMethodTemkinTableMatchesTheLibrary() {
        XCTAssertEqual(MethodTemkin.minutes(for: .turkey),
                       [.sunrise: -7, .dhuhr: 5, .asr: 4, .maghrib: 7])
        XCTAssertTrue(MethodTemkin.isTemkin(.turkey))
        // Everyone else's adjustment is a generic transit correction, and must
        // not be presented to the user as a temkin margin.
        for method: Adhan.CalculationMethod in [.muslimWorldLeague, .egyptian, .karachi,
                                                .northAmerica, .ummAlQura] {
            XCTAssertFalse(MethodTemkin.isTemkin(method), "\(method) must not claim temkin")
        }
        XCTAssertEqual(MethodTemkin.minutes(for: .ummAlQura), [:])
        for method: Adhan.CalculationMethod in [.muslimWorldLeague, .egyptian, .karachi, .northAmerica] {
            XCTAssertEqual(MethodTemkin.minutes(for: method), [.dhuhr: 1], "\(method) transit correction")
        }
    }

    /// Diyanet's own method already carries the temkin, so the resolution
    /// attached to the day must say so — this is the claim the UI repeats.
    func testResolutionReportsTemkinTruthfully() throws {
        let when = date(2026, 3, 15, timeZone: istanbulTZ)
        let resolved = try XCTUnwrap(
            PrayerEngine.resolved(for: when, coordinate: istanbul,
                                  configuration: configuration(method: .diyanet, source: .diyanet))
        )
        XCTAssertTrue(resolved.resolution.temkinIsDiyanet)
        XCTAssertEqual(resolved.resolution.temkinMinutes, [.sunrise: -7, .dhuhr: 5, .asr: 4, .maghrib: 7])
        XCTAssertEqual(try XCTUnwrap(resolved.resolution.fajrAngle), 18, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(resolved.resolution.ishaAngle), 17, accuracy: 0.0001)
        XCTAssertEqual(resolved.resolution.adhanMethodID, Adhan.CalculationMethod.turkey.rawValue)

        let isna = try XCTUnwrap(
            PrayerEngine.resolved(for: when, coordinate: chicago,
                                  configuration: configuration(method: .isna, source: .standard,
                                                               timeZone: "America/Chicago"))
        )
        XCTAssertFalse(isna.resolution.temkinIsDiyanet, "ISNA must not claim Diyanet temkin")
        XCTAssertEqual(try XCTUnwrap(isna.resolution.fajrAngle), 15, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(isna.resolution.ishaAngle), 15, accuracy: 0.0001)
    }

    // MARK: - 4. Cross-method relationships

    /// Deeper fajr angle ⇒ earlier imsak. Ordering is a stronger check than any
    /// absolute window: it fails loudly if two presets are swapped.
    func testFajrOrderingFollowsAngleDepth() throws {
        let when = date(2026, 3, 15, timeZone: istanbulTZ)
        let fajr = try CalculationMethod.allCases.reduce(into: [CalculationMethod: Date]()) {
            $0[$1] = try day($1, at: istanbul, on: when).times[.fajr]!
        }

        // 19.5° … 18.5° … 18° … 15°
        XCTAssertLessThan(fajr[.egypt]!, fajr[.ummAlQura]!, "Egypt 19.5° must precede Umm al-Qura 18.5°")
        XCTAssertLessThan(fajr[.ummAlQura]!, fajr[.mwl]!, "Umm al-Qura 18.5° must precede MWL 18°")
        XCTAssertLessThan(fajr[.mwl]!, fajr[.isna]!, "MWL 18° must precede ISNA 15°")
        // The user's own words: "ISNA's fajr is later than MWL's."
        XCTAssertGreaterThan(fajr[.isna]!, fajr[.mwl]!)
        // Same angle ⇒ same instant (Diyanet's temkin does not touch imsak).
        XCTAssertEqual(minutes(fajr[.karachi]!, fajr[.mwl]!), 0, "Karachi and MWL both use 18°")
        XCTAssertEqual(minutes(fajr[.diyanet]!, fajr[.mwl]!), 0, "Diyanet and MWL both use 18°")
        // 15° vs 18° at 41°N should be worth a real chunk of time, not a rounding.
        XCTAssertGreaterThan(minutes(fajr[.isna]!, fajr[.mwl]!), 10)
    }

    /// Deeper isha angle ⇒ later yatsı.
    func testIshaOrderingFollowsAngleDepth() throws {
        let when = date(2026, 3, 15, timeZone: istanbulTZ)
        let isha = try [CalculationMethod.isna, .mwl, .diyanet, .egypt, .karachi]
            .reduce(into: [CalculationMethod: Date]()) {
                $0[$1] = try day($1, at: istanbul, on: when).times[.isha]!
            }
        // 15° … 17° … 17.5° … 18°
        XCTAssertLessThan(isha[.isna]!, isha[.mwl]!, "ISNA 15° must precede MWL 17°")
        XCTAssertLessThan(isha[.mwl]!, isha[.egypt]!, "MWL 17° must precede Egypt 17.5°")
        XCTAssertLessThan(isha[.egypt]!, isha[.karachi]!, "Egypt 17.5° must precede Karachi 18°")
        // Diyanet shares MWL's 17°, and gets no yatsı temkin.
        XCTAssertEqual(minutes(isha[.diyanet]!, isha[.mwl]!), 0)
        XCTAssertGreaterThan(minutes(isha[.mwl]!, isha[.isna]!), 10)
    }

    /// Hanafi asr starts later than Shafi asr, for every method.
    func testHanafiAsrIsAlwaysLaterThanShafiAsr() throws {
        let when = date(2026, 3, 15, timeZone: istanbulTZ)
        for method in CalculationMethod.allCases {
            let shafi = try day(method, madhab: .shafi, at: istanbul, on: when).times[.asr]!
            let hanafi = try day(method, madhab: .hanafi, at: istanbul, on: when).times[.asr]!
            XCTAssertGreaterThan(hanafi, shafi, "\(method): Hanafi ikindi must be later than Shafi")
        }
    }

    /// The madhab must move asr and *nothing* else.
    func testMadhabTouchesOnlyAsr() throws {
        let when = date(2026, 3, 15, timeZone: istanbulTZ)
        let shafi = try day(.diyanet, source: .diyanet, madhab: .shafi, at: istanbul, on: when)
        let hanafi = try day(.diyanet, source: .diyanet, madhab: .hanafi, at: istanbul, on: when)
        for prayer in Prayer.allCases where prayer != .asr {
            XCTAssertEqual(minutes(hanafi.times[prayer]!, shafi.times[prayer]!), 0,
                           "\(prayer) must not depend on the madhab")
        }
    }

    // MARK: - 5. Order and plausibility, every method

    /// Fajr < Sunrise < Dhuhr < Asr < Maghrib < Isha, everywhere, every season.
    func testChronologicalOrderHoldsForEveryMethodCityAndSeason() throws {
        let cities: [(CLLocationCoordinate2D, String)] = [
            (istanbul, istanbulTZ),
            (ankara, istanbulTZ),
            (makkah, "Asia/Riyadh"),
            (cairo, "Africa/Cairo"),
            (karachiCity, "Asia/Karachi"),
            (chicago, "America/Chicago"),
        ]
        for method in CalculationMethod.allCases {
            for (coordinate, tz) in cities {
                for (month, dayOfMonth) in [(1, 15), (3, 21), (6, 21), (9, 23), (12, 21)] {
                    let d = try day(method, at: coordinate,
                                    on: date(2026, month, dayOfMonth, timeZone: tz), timeZone: tz)
                    let ordered = Prayer.allCases.compactMap { d.times[$0] }
                    XCTAssertEqual(ordered.count, 6, "\(method) @ \(tz) 2026-\(month)-\(dayOfMonth)")
                    XCTAssertEqual(ordered, ordered.sorted(),
                                   "\(method) @ \(tz) 2026-\(month)-\(dayOfMonth) is out of order")
                    // No two markers may collapse onto the same minute.
                    XCTAssertEqual(Set(ordered).count, 6,
                                   "\(method) @ \(tz) 2026-\(month)-\(dayOfMonth) has duplicate times")
                }
            }
        }
    }

    /// Independent, published-table sanity anchors. Deliberately generous
    /// windows: the point is to catch an hour-scale error (wrong time zone,
    /// wrong preset), not to re-derive the ephemeris.
    func testKnownCityWindows() throws {
        // Istanbul, equinox, Diyanet: imsak ~05:1x, güneş ~06:4x, öğle ~13:1x,
        // akşam ~19:2x, yatsı ~20:4x (local, UTC+3 year-round).
        let ist = try day(.diyanet, source: .diyanet, madhab: .hanafi, at: istanbul,
                          on: date(2026, 3, 21, timeZone: istanbulTZ))
        assertHour(ist, .fajr, near: 5.2, plusMinus: 0.6, tz: istanbulTZ)
        assertHour(ist, .sunrise, near: 6.7, plusMinus: 0.5, tz: istanbulTZ)
        assertHour(ist, .dhuhr, near: 13.3, plusMinus: 0.5, tz: istanbulTZ)
        assertHour(ist, .maghrib, near: 19.4, plusMinus: 0.5, tz: istanbulTZ)
        assertHour(ist, .isha, near: 20.7, plusMinus: 0.6, tz: istanbulTZ)

        // Makkah, equinox, Umm al-Qura.
        let mkk = try day(.ummAlQura, at: makkah,
                          on: date(2026, 3, 21, timeZone: "Asia/Riyadh"), timeZone: "Asia/Riyadh")
        assertHour(mkk, .sunrise, near: 6.3, plusMinus: 0.5, tz: "Asia/Riyadh")
        assertHour(mkk, .dhuhr, near: 12.4, plusMinus: 0.5, tz: "Asia/Riyadh")
        assertHour(mkk, .maghrib, near: 18.5, plusMinus: 0.5, tz: "Asia/Riyadh")

        // Chicago, equinox, ISNA.
        let chi = try day(.isna, at: chicago,
                          on: date(2026, 3, 21, timeZone: "America/Chicago"), timeZone: "America/Chicago")
        assertHour(chi, .sunrise, near: 6.9, plusMinus: 0.6, tz: "America/Chicago")
        assertHour(chi, .dhuhr, near: 13.0, plusMinus: 0.6, tz: "America/Chicago")
        assertHour(chi, .maghrib, near: 19.1, plusMinus: 0.6, tz: "America/Chicago")
    }

    private func assertHour(_ d: DayPrayerTimes, _ prayer: Prayer,
                            near expected: Double, plusMinus: Double, tz: String,
                            file: StaticString = #filePath, line: UInt = #line) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: tz)!
        let comps = calendar.dateComponents([.hour, .minute], from: d.times[prayer]!)
        let value = Double(comps.hour!) + Double(comps.minute!) / 60
        XCTAssertEqual(value, expected, accuracy: plusMinus,
                       "\(prayer) at \(tz)", file: file, line: line)
    }

    // MARK: - 6. Prayer sources

    /// Only sources whose parameters can be traced to their own publisher may
    /// reach the picker. Fazilet Takvimi is retained as a decodable case (older
    /// installs may have it stored) but is not offered, because it does not
    /// publish the temkin table that is most of what makes its imsak differ.
    func testOnlyVerifiedSourcesAreSelectable() {
        XCTAssertEqual(PrayerSource.selectableCases, [.diyanet, .turkiyeTakvimi, .standard])
        XCTAssertEqual(PrayerSource.allCases, PrayerSource.selectableCases,
                       "allCases is the picker's list and must not leak a withdrawn source")
        XCTAssertTrue(PrayerSource.diyanet.isSelectable)
        XCTAssertTrue(PrayerSource.turkiyeTakvimi.isSelectable)
        XCTAssertTrue(PrayerSource.standard.isSelectable)
        XCTAssertFalse(PrayerSource.fazilet.isSelectable)
        XCTAssertEqual(PrayerSource.withdrawnCases, [.fazilet])
    }

    /// A withdrawn source read off disk must resolve to Diyanet rather than
    /// silently keeping unverified parameters alive.
    func testWithdrawnSourcesFallBackToDiyanet() {
        XCTAssertEqual(PrayerSource.fazilet.resolved, .diyanet)
        XCTAssertEqual(PrayerSource.diyanet.resolved, .diyanet)
        XCTAssertEqual(PrayerSource.turkiyeTakvimi.resolved, .turkiyeTakvimi)
        XCTAssertEqual(PrayerSource.standard.resolved, .standard)
        XCTAssertEqual(PrayerSource.fazilet.fajrAngleOverride, 18, "must not keep the guessed 19°")
        XCTAssertTrue(PrayerSource.fazilet.extraTemkinMinutes.isEmpty)
    }

    /// Every angle and margin, against what the publisher states.
    ///
    /// - Diyanet: 18° / 17°, temkin inside the `.turkey` preset.
    /// - Türkiye Takvimi: 19° / 17° on the empty `.other` preset, plus 10
    ///   minutes of temkin — off the times before noon, on to the times after.
    /// - Standard: nothing of its own.
    func testEverySourceAppliesOnlyPublishedParameters() {
        XCTAssertEqual(PrayerSource.diyanet.fajrAngleOverride, 18)
        XCTAssertEqual(PrayerSource.diyanet.ishaAngleOverride, 17)
        XCTAssertEqual(PrayerSource.diyanet.baseAdhanMethod, .turkey)
        XCTAssertTrue(PrayerSource.diyanet.extraTemkinMinutes.isEmpty,
                      "Diyanet's temkin already lives in the .turkey preset; adding it again would double it")

        XCTAssertEqual(PrayerSource.turkiyeTakvimi.fajrAngleOverride, 19)
        XCTAssertEqual(PrayerSource.turkiyeTakvimi.ishaAngleOverride, 17)
        XCTAssertEqual(PrayerSource.turkiyeTakvimi.baseAdhanMethod, .other,
                       "must sit on an empty preset so Diyanet's temkin cannot leak in")
        XCTAssertEqual(PrayerSource.turkiyeTakvimi.extraTemkinMinutes,
                       [.fajr: -10, .sunrise: -10, .dhuhr: 10, .asr: 10, .maghrib: 10, .isha: 10])

        XCTAssertNil(PrayerSource.standard.fajrAngleOverride)
        XCTAssertNil(PrayerSource.standard.ishaAngleOverride)
        XCTAssertNil(PrayerSource.standard.baseAdhanMethod)
        XCTAssertTrue(PrayerSource.standard.extraTemkinMinutes.isEmpty)
        XCTAssertFalse(PrayerSource.standard.appliesDocumentedTemkin)
    }

    /// Türkiye Takvimi's imsak must land materially earlier than Diyanet's —
    /// a full degree of extra depression *plus* 10 minutes of temkin — and its
    /// afternoon times materially later. Measured, not asserted from the table.
    func testTurkiyeTakvimiDiffersFromDiyanetInTheDirectionItsPublisherDescribes() throws {
        let when = date(2026, 3, 15, timeZone: istanbulTZ)
        let diyanet = try day(.diyanet, source: .diyanet, madhab: .hanafi, at: istanbul, on: when)
        let tt = try day(.diyanet, source: .turkiyeTakvimi, madhab: .hanafi, at: istanbul, on: when)

        // 19° vs 18° is worth roughly 4–6 minutes at 41°N, and the 10-minute
        // temkin comes off on top, so imsak should be ~13–18 minutes earlier.
        let imsakDelta = minutes(tt.times[.fajr]!, diyanet.times[.fajr]!)
        XCTAssertLessThan(imsakDelta, -10, "Türkiye Takvimi imsak must be clearly earlier")
        XCTAssertGreaterThan(imsakDelta, -25, "…but not implausibly so")

        // Güneş: Diyanet already takes 7 minutes off; Türkiye Takvimi takes 10.
        XCTAssertEqual(minutes(tt.times[.sunrise]!, diyanet.times[.sunrise]!), -3)
        // Öğle +10 vs +5, ikindi +10 vs +4, akşam +10 vs +7.
        XCTAssertEqual(minutes(tt.times[.dhuhr]!, diyanet.times[.dhuhr]!), 5)
        XCTAssertEqual(minutes(tt.times[.asr]!, diyanet.times[.asr]!), 6)
        XCTAssertEqual(minutes(tt.times[.maghrib]!, diyanet.times[.maghrib]!), 3)
        // Yatsı: same 17° angle, but Diyanet applies no temkin and TT applies +10.
        XCTAssertEqual(minutes(tt.times[.isha]!, diyanet.times[.isha]!), 10)

        let ordered = Prayer.allCases.compactMap { tt.times[$0] }
        XCTAssertEqual(ordered, ordered.sorted())
    }

    /// Türkiye Takvimi's 10 minutes must be reported as temkin, and must be the
    /// only margin applied — the `.other` base contributes nothing.
    func testTurkiyeTakvimiResolutionReportsItsOwnTemkin() throws {
        let resolved = try XCTUnwrap(
            PrayerEngine.resolved(for: date(2026, 3, 15, timeZone: istanbulTZ),
                                  coordinate: istanbul,
                                  configuration: configuration(method: .diyanet, source: .turkiyeTakvimi))
        )
        XCTAssertEqual(try XCTUnwrap(resolved.resolution.fajrAngle), 19, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(resolved.resolution.ishaAngle), 17, accuracy: 0.0001)
        XCTAssertEqual(resolved.resolution.ishaIntervalMinutes, 0)
        XCTAssertEqual(resolved.resolution.temkinMinutes,
                       [.fajr: -10, .sunrise: -10, .dhuhr: 10, .asr: 10, .maghrib: 10, .isha: 10])
        XCTAssertTrue(resolved.resolution.temkinIsDiyanet,
                      "a published temkin must be labelled temkin, not a transit correction")
        XCTAssertEqual(resolved.resolution.adhanMethodID, Adhan.CalculationMethod.other.rawValue)
    }

    /// Aladhan cannot express Türkiye Takvimi, so it must never be fetched —
    /// a network answer would silently substitute Diyanet's numbers under
    /// another calendar's name.
    func testNetworkMethodMatchesWhateverTheEngineComputed() {
        for method in CalculationMethod.allCases {
            // Diyanet source ⇒ Aladhan method 13, whatever Settings says.
            XCTAssertEqual(configuration(method: method, source: .diyanet).networkMethod, .diyanet)
            // Standard ⇒ the user's own method, untouched.
            XCTAssertEqual(configuration(method: method, source: .standard).networkMethod, method)
            // Türkiye Takvimi ⇒ no network at all.
            XCTAssertNil(configuration(method: method, source: .turkiyeTakvimi).networkMethod)
            // A withdrawn source behaves exactly as Diyanet does.
            XCTAssertEqual(configuration(method: method, source: .fazilet).networkMethod, .diyanet)
        }
    }

    /// Picking the Diyanet source pins the Turkish preset no matter which
    /// method sits in Settings — otherwise a user with "Diyanet" on screen
    /// could be looking at ISNA's numbers.
    func testDiyanetSourceOverridesTheSettingsMethod() throws {
        let when = date(2026, 3, 15, timeZone: istanbulTZ)
        for method in CalculationMethod.allCases {
            let config = configuration(method: method, source: .diyanet)
            XCTAssertEqual(config.effectiveAdhanMethod, .turkey, "\(method) + Diyanet source")
            let p = params(method, source: .diyanet, at: istanbul)
            XCTAssertEqual(p.fajrAngle, 18, accuracy: 0.0001)
            XCTAssertEqual(p.ishaAngle, 17, accuracy: 0.0001)
            XCTAssertEqual(p.ishaInterval, 0, "Umm al-Qura's 90-minute interval must not leak through")

            let d = try day(method, source: .diyanet, at: istanbul, on: when)
            let reference = try day(.diyanet, source: .diyanet, at: istanbul, on: when)
            for prayer in Prayer.allCases {
                XCTAssertEqual(minutes(d.times[prayer]!, reference.times[prayer]!), 0,
                               "\(method) + Diyanet source must equal Diyanet exactly (\(prayer))")
            }
        }
    }

    /// Same for Türkiye Takvimi: the Settings method must not move it.
    func testTurkiyeTakvimiOverridesTheSettingsMethod() throws {
        let when = date(2026, 3, 15, timeZone: istanbulTZ)
        let reference = try day(.diyanet, source: .turkiyeTakvimi, at: istanbul, on: when)
        for method in CalculationMethod.allCases {
            XCTAssertEqual(configuration(method: method, source: .turkiyeTakvimi).effectiveAdhanMethod, .other)
            let d = try day(method, source: .turkiyeTakvimi, at: istanbul, on: when)
            for prayer in Prayer.allCases {
                XCTAssertEqual(minutes(d.times[prayer]!, reference.times[prayer]!), 0,
                               "\(method) + Türkiye Takvimi must equal Türkiye Takvimi exactly (\(prayer))")
            }
        }
    }

    /// `.standard` must be a pass-through: the method the user picked, untouched.
    func testStandardSourceLeavesTheMethodAlone() {
        for method in CalculationMethod.allCases {
            let config = configuration(method: method, source: .standard)
            XCTAssertEqual(config.effectiveAdhanMethod, method.adhanMethod)
        }
    }

    /// Order and plausibility must survive the Türkiye Takvimi margins too,
    /// including the seasons where 19° twilight is at its longest.
    func testTurkiyeTakvimiStaysOrderedAllYear() throws {
        for (month, dayOfMonth) in [(1, 15), (3, 21), (5, 21), (6, 21), (7, 21), (9, 23), (12, 21)] {
            for coordinate in [istanbul, ankara] {
                let d = try day(.diyanet, source: .turkiyeTakvimi, madhab: .hanafi,
                                at: coordinate, on: date(2026, month, dayOfMonth, timeZone: istanbulTZ))
                let ordered = Prayer.allCases.compactMap { d.times[$0] }
                XCTAssertEqual(ordered.count, 6)
                XCTAssertEqual(ordered, ordered.sorted(), "Türkiye Takvimi 2026-\(month)-\(dayOfMonth)")
            }
        }
    }

    // MARK: - 7. User offsets

    /// Corrections are applied last, per prayer, and never reorder the day.
    func testUserOffsetsApplyExactlyAndOnlyWhereAsked() throws {
        let when = date(2026, 3, 15, timeZone: istanbulTZ)
        let base = try day(.diyanet, source: .diyanet, at: istanbul, on: when)
        let shifted = try XCTUnwrap(
            PrayerEngine.times(for: when, coordinate: istanbul,
                               configuration: configuration(method: .diyanet, source: .diyanet,
                                                            offsets: [.fajr: -3, .isha: 4]))
        )
        XCTAssertEqual(minutes(shifted.times[.fajr]!, base.times[.fajr]!), -3)
        XCTAssertEqual(minutes(shifted.times[.isha]!, base.times[.isha]!), 4)
        for prayer in Prayer.allCases where prayer != .fajr && prayer != .isha {
            XCTAssertEqual(minutes(shifted.times[prayer]!, base.times[prayer]!), 0)
        }
        let ordered = Prayer.allCases.compactMap { shifted.times[$0] }
        XCTAssertEqual(ordered, ordered.sorted())
    }

    /// Anything that changes the numbers must change the cache fingerprint,
    /// or a user who switches method keeps seeing yesterday's other method.
    func testFingerprintChangesWithEveryParameterThatMovesATime() {
        let base = configuration(method: .diyanet, source: .diyanet)
        var seen: Set<String> = [base.fingerprint]

        for method in CalculationMethod.allCases {
            seen.insert(configuration(method: method, source: .diyanet).fingerprint)
        }
        seen.insert(configuration(method: .diyanet, madhab: .hanafi, source: .diyanet).fingerprint)
        seen.insert(configuration(method: .diyanet, source: .standard).fingerprint)
        seen.insert(configuration(method: .diyanet, source: .diyanet, offsets: [.fajr: 1]).fingerprint)
        seen.insert(configuration(method: .diyanet, source: .diyanet, timeZone: "Europe/London").fingerprint)

        // 6 methods + madhab + source + offset + time zone, all distinct.
        XCTAssertEqual(seen.count, 6 + 4)
    }
}
