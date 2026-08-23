import CoreLocation
import XCTest

/// On-device prayer engine + persistent cache.
///
/// Nothing here touches the network: the whole point of `PrayerEngine` is that
/// it never needs to.
final class PrayerEngineTests: XCTestCase {

    // MARK: - Fixtures

    private let istanbul = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
    private let makkah = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)
    private let london = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
    private let longyearbyen = CLLocationCoordinate2D(latitude: 78.2232, longitude: 15.6267)

    /// 15 June 2026, a date far from any DST edge in the zones we test.
    private func date(_ year: Int, _ month: Int, _ day: Int, timeZone: String) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZone)!
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private func configuration(method: CalculationMethod = .diyanet,
                               madhab: Madhab = .hanafi,
                               source: PrayerSource = .diyanet,
                               offsets: [Prayer: Int] = [:],
                               timeZone: String = "Europe/Istanbul") -> PrayerEngineConfiguration {
        PrayerEngineConfiguration(method: method,
                                  madhab: madhab,
                                  source: source,
                                  offsets: offsets,
                                  timeZone: TimeZone(identifier: timeZone)!)
    }

    /// Local clock-hour (as a Double, e.g. 5.5 == 05:30) of a prayer.
    private func hour(_ day: DayPrayerTimes, _ prayer: Prayer, timeZone: String) -> Double {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZone)!
        let comps = calendar.dateComponents([.hour, .minute], from: day.times[prayer]!)
        return Double(comps.hour!) + Double(comps.minute!) / 60
    }

    // MARK: - Known cities land in plausible windows

    func testIstanbulMidsummerTimesAreReasonable() throws {
        let config = configuration()
        let day = try XCTUnwrap(PrayerEngine.times(for: date(2026, 6, 15, timeZone: "Europe/Istanbul"),
                                                   coordinate: istanbul,
                                                   configuration: config))
        // Istanbul, mid-June: imsak ~03:15–03:45, sunrise ~05:20–05:45,
        // dhuhr ~13:00–13:20, maghrib ~20:30–20:55.
        XCTAssertEqual(hour(day, .fajr, timeZone: "Europe/Istanbul"), 3.5, accuracy: 0.75)
        XCTAssertEqual(hour(day, .sunrise, timeZone: "Europe/Istanbul"), 5.5, accuracy: 0.5)
        XCTAssertEqual(hour(day, .dhuhr, timeZone: "Europe/Istanbul"), 13.1, accuracy: 0.5)
        XCTAssertEqual(hour(day, .maghrib, timeZone: "Europe/Istanbul"), 20.7, accuracy: 0.5)
    }

    func testMakkahTimesAreReasonable() throws {
        let config = configuration(method: .ummAlQura, madhab: .shafi,
                                   source: .standard, timeZone: "Asia/Riyadh")
        let day = try XCTUnwrap(PrayerEngine.times(for: date(2026, 6, 15, timeZone: "Asia/Riyadh"),
                                                   coordinate: makkah,
                                                   configuration: config))
        XCTAssertEqual(hour(day, .fajr, timeZone: "Asia/Riyadh"), 4.4, accuracy: 0.75)
        XCTAssertEqual(hour(day, .dhuhr, timeZone: "Asia/Riyadh"), 12.4, accuracy: 0.5)
        XCTAssertEqual(hour(day, .maghrib, timeZone: "Asia/Riyadh"), 19.1, accuracy: 0.5)
        // Umm al-Qura uses a fixed 90-minute interval after maghrib.
        let gap = day.times[.isha]!.timeIntervalSince(day.times[.maghrib]!)
        XCTAssertEqual(gap, 90 * 60, accuracy: 120)
    }

    func testLondonWinterOrdersCorrectly() throws {
        let config = configuration(method: .mwl, madhab: .shafi,
                                   source: .standard, timeZone: "Europe/London")
        let day = try XCTUnwrap(PrayerEngine.times(for: date(2026, 12, 21, timeZone: "Europe/London"),
                                                   coordinate: london,
                                                   configuration: config))
        let ordered = Prayer.allCases.compactMap { day.times[$0] }
        XCTAssertEqual(ordered.count, 6)
        XCTAssertEqual(ordered, ordered.sorted(), "Prayer times must be chronological")
        // Shortest day of the year in London: sunrise ~08:00, maghrib ~15:55.
        XCTAssertEqual(hour(day, .sunrise, timeZone: "Europe/London"), 8.05, accuracy: 0.5)
        XCTAssertEqual(hour(day, .maghrib, timeZone: "Europe/London"), 15.9, accuracy: 0.5)
    }

    func testEveryProducedDayIsOrderedAndAnchoredToItsOwnDate() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        let config = configuration()
        let days = PrayerEngine.month(of: date(2026, 3, 10, timeZone: "Europe/Istanbul"),
                                      coordinate: istanbul,
                                      configuration: config)
        for day in days {
            let ordered = Prayer.allCases.compactMap { day.times[$0] }
            XCTAssertEqual(ordered, ordered.sorted())
            for time in ordered {
                XCTAssertTrue(calendar.isDate(time, inSameDayAs: day.date),
                              "Prayer instant escaped its own day")
            }
        }
    }

    // MARK: - Diyanet temkin

    func testDiyanetTemkinIsAppliedRelativeToPlainAstronomicalTimes() throws {
        // Same angles, same coordinates, same day — the only difference is the
        // Turkish method's temkin. adhan-swift's `.turkey` preset applies
        // sunrise −7, dhuhr +5, asr +4, maghrib +7 minutes.
        let when = date(2026, 4, 12, timeZone: "Europe/Istanbul")
        let diyanet = try XCTUnwrap(PrayerEngine.times(for: when, coordinate: istanbul,
                                                       configuration: configuration()))
        // MWL also uses fajr 18° and applies only +1 min to dhuhr, so the
        // sunrise/maghrib deltas isolate the temkin cleanly.
        let plain = try XCTUnwrap(PrayerEngine.times(
            for: when, coordinate: istanbul,
            configuration: configuration(method: .mwl, source: .standard)
        ))

        let sunriseDelta = diyanet.times[.sunrise]!.timeIntervalSince(plain.times[.sunrise]!) / 60
        let maghribDelta = diyanet.times[.maghrib]!.timeIntervalSince(plain.times[.maghrib]!) / 60
        let dhuhrDelta = diyanet.times[.dhuhr]!.timeIntervalSince(plain.times[.dhuhr]!) / 60

        XCTAssertEqual(sunriseDelta, -7, accuracy: 1.1, "Diyanet sunrise temkin is −7 min")
        XCTAssertEqual(maghribDelta, 7, accuracy: 1.1, "Diyanet maghrib temkin is +7 min")
        XCTAssertEqual(dhuhrDelta, 4, accuracy: 1.1, "Diyanet +5 vs MWL +1 = +4 min")
    }

    func testTemkinTableIsExposedForTheTransparencyPanel() {
        let config = configuration()
        let temkin = PrayerEngine.temkin(for: config)
        XCTAssertEqual(temkin[.sunrise], -7)
        XCTAssertEqual(temkin[.dhuhr], 5)
        XCTAssertEqual(temkin[.asr], 4)
        XCTAssertEqual(temkin[.maghrib], 7)
        // No temkin is claimed for imsak/yatsı, because adhan-swift applies none.
        XCTAssertNil(temkin[.fajr])
        XCTAssertNil(temkin[.isha])
    }

    func testFaziletImsakIsEarlierThanDiyanetAndOtherTimesMatch() throws {
        let when = date(2026, 4, 12, timeZone: "Europe/Istanbul")
        let diyanet = try XCTUnwrap(PrayerEngine.times(for: when, coordinate: istanbul,
                                                       configuration: configuration(source: .diyanet)))
        let fazilet = try XCTUnwrap(PrayerEngine.times(for: when, coordinate: istanbul,
                                                       configuration: configuration(source: .fazilet)))
        XCTAssertLessThan(fazilet.times[.fajr]!, diyanet.times[.fajr]!,
                          "A deeper dawn angle must produce an earlier imsak")
        // The tradition only moves imsak in this model — everything else is identical.
        for prayer in [Prayer.sunrise, .dhuhr, .asr, .maghrib] {
            XCTAssertEqual(fazilet.times[prayer]!.timeIntervalSince(diyanet.times[prayer]!), 0,
                           accuracy: 1, "\(prayer.rawValue) must not move with the source")
        }
    }

    // MARK: - Resolution / transparency model

    func testResolutionDescribesWhatWasActuallyApplied() throws {
        let config = configuration(offsets: [.fajr: -3])
        let resolved = try XCTUnwrap(PrayerEngine.resolved(for: date(2026, 4, 12, timeZone: "Europe/Istanbul"),
                                                           coordinate: istanbul,
                                                           configuration: config))
        XCTAssertEqual(resolved.resolution.origin, .device)
        XCTAssertEqual(resolved.resolution.source, .diyanet)
        XCTAssertEqual(resolved.resolution.adhanMethodID, "turkey")
        XCTAssertEqual(resolved.resolution.fajrAngle, 18)
        XCTAssertTrue(resolved.resolution.temkinIsDiyanet)
        XCTAssertEqual(resolved.resolution.userOffsetMinutes[.fajr], -3)
        XCTAssertFalse(resolved.resolution.resolutionSummary(for: .fajr).isEmpty)
    }

    func testUserOffsetsShiftExactlyTheRequestedPrayer() throws {
        let when = date(2026, 4, 12, timeZone: "Europe/Istanbul")
        let base = try XCTUnwrap(PrayerEngine.times(for: when, coordinate: istanbul,
                                                    configuration: configuration()))
        let shifted = try XCTUnwrap(PrayerEngine.times(
            for: when, coordinate: istanbul,
            configuration: configuration(offsets: [.isha: 12])
        ))
        XCTAssertEqual(shifted.times[.isha]!.timeIntervalSince(base.times[.isha]!), 12 * 60, accuracy: 1)
        XCTAssertEqual(shifted.times[.fajr]!, base.times[.fajr]!)
    }

    // MARK: - High latitude

    func testHighLatitudeDoesNotCrashAndEitherAnswersOrDeclines() {
        let config = configuration(method: .mwl, madhab: .shafi,
                                   source: .standard, timeZone: "Europe/Oslo")
        // Polar day (June) and polar night (December) at Svalbard.
        for month in [6, 12] {
            let when = date(2026, month, 21, timeZone: "Europe/Oslo")
            let result = PrayerEngine.times(for: when, coordinate: longyearbyen, configuration: config)
            if let result {
                let ordered = Prayer.allCases.compactMap { result.times[$0] }
                XCTAssertEqual(ordered.count, 6)
            }
            // `nil` is a legitimate, honest answer here — the assertion is that
            // we reached this line at all.
        }
    }

    func testHighLatitudeRuleIsRecordedForNorthernCities() throws {
        let config = configuration(method: .mwl, madhab: .shafi,
                                   source: .standard, timeZone: "Europe/Stockholm")
        let stockholm = CLLocationCoordinate2D(latitude: 59.3293, longitude: 18.0686)
        let resolved = try XCTUnwrap(PrayerEngine.resolved(for: date(2026, 5, 20, timeZone: "Europe/Stockholm"),
                                                           coordinate: stockholm,
                                                           configuration: config))
        // Above 48° adhan-swift recommends the one-seventh rule.
        XCTAssertEqual(resolved.resolution.highLatitudeRule, "seventhOfTheNight")
    }

    // MARK: - Month generation

    func testMonthProducesEveryDayInOrder() {
        let config = configuration()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!

        for (month, expected) in [(2, 28), (4, 30), (7, 31)] {
            let anchor = date(2026, month, 10, timeZone: "Europe/Istanbul")
            let days = PrayerEngine.month(of: anchor, coordinate: istanbul, configuration: config)
            XCTAssertEqual(days.count, expected, "Month \(month) should have \(expected) days")
            XCTAssertEqual(days.map(\.date), days.map(\.date).sorted(), "Days must ascend")
            XCTAssertEqual(Set(days.map { calendar.component(.month, from: $0.date) }).count, 1,
                           "Month must not bleed into a neighbour")
        }
    }

    func testLeapYearFebruaryHas29Days() {
        let days = PrayerEngine.month(of: date(2028, 2, 10, timeZone: "Europe/Istanbul"),
                                      coordinate: istanbul,
                                      configuration: configuration())
        XCTAssertEqual(days.count, 29)
    }

    func testWindowCoversAtLeastSixtyDays() {
        let window = PrayerEngine.resolvedWindow(from: date(2026, 1, 20, timeZone: "Europe/Istanbul"),
                                                 startingOffset: -1,
                                                 dayCount: 75,
                                                 coordinate: istanbul,
                                                 configuration: configuration())
        XCTAssertGreaterThanOrEqual(window.count, 60)
        XCTAssertEqual(window.map(\.day.date), window.map(\.day.date).sorted())
    }

    func testHijriDateIsProducedOffline() throws {
        let resolved = try XCTUnwrap(PrayerEngine.resolved(for: date(2026, 4, 12, timeZone: "Europe/Istanbul"),
                                                           coordinate: istanbul,
                                                           configuration: configuration()))
        let hijri = try XCTUnwrap(resolved.day.hijriDate)
        XCTAssertTrue((1...30).contains(hijri.day))
        XCTAssertTrue((1...12).contains(hijri.month))
        XCTAssertGreaterThan(hijri.year, 1400)
    }

    // MARK: - Cache round-trip

    private func makeStore() throws -> (PrayerCacheStore, URL) {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return (PrayerCacheStore(directory: directory), directory)
    }

    /// Explicit calendar everywhere: the cache keys days by start-of-day, so a
    /// CI machine in another time zone must not shift them.
    private var istanbulCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return calendar
    }

    private func signature(for coordinate: CLLocationCoordinate2D,
                           configuration: PrayerEngineConfiguration) -> PrayerCacheSignature {
        PrayerCacheSignature(latitude: coordinate.latitude,
                             longitude: coordinate.longitude,
                             configurationFingerprint: configuration.fingerprint)
    }

    func testCacheRoundTripsAcrossInstances() throws {
        let (store, directory) = try makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let config = configuration()
        let now = date(2026, 4, 12, timeZone: "Europe/Istanbul")
        let records = PrayerEngine.resolvedWindow(from: now, startingOffset: 0, dayCount: 70,
                                                  coordinate: istanbul, configuration: config)
        let sig = signature(for: istanbul, configuration: config)
        store.merge(records, signature: sig, now: now, calendar: istanbulCalendar)

        // A brand-new store object reading the same directory: this is what a
        // cold launch (or the widget extension) actually does.
        let reopened = PrayerCacheStore(directory: directory)
        let loaded = reopened.records(matching: sig)
        XCTAssertEqual(loaded.count, records.count)
        XCTAssertTrue(reopened.covers(from: now, days: 60, signature: sig, calendar: istanbulCalendar))

        let day = try XCTUnwrap(reopened.record(for: now, signature: sig, calendar: istanbulCalendar))
        XCTAssertEqual(day.day.times[.fajr]!.timeIntervalSince1970,
                       records[0].day.times[.fajr]!.timeIntervalSince1970,
                       accuracy: 1)
        XCTAssertEqual(day.resolution.source, .diyanet)
    }

    func testCoordinateChangeInvalidatesTheCache() throws {
        let (store, directory) = try makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let config = configuration()
        let now = date(2026, 4, 12, timeZone: "Europe/Istanbul")
        let istanbulSig = signature(for: istanbul, configuration: config)
        store.merge(PrayerEngine.resolvedWindow(from: now, startingOffset: 0, dayCount: 10,
                                                coordinate: istanbul, configuration: config),
                    signature: istanbulSig, now: now, calendar: istanbulCalendar)
        XCTAssertFalse(store.records(matching: istanbulSig).isEmpty)

        // Same settings, different city → nothing valid to show.
        let makkahSig = signature(for: makkah, configuration: config)
        XCTAssertTrue(store.records(matching: makkahSig).isEmpty)
        XCTAssertFalse(store.covers(from: now, days: 1, signature: makkahSig, calendar: istanbulCalendar))
    }

    func testSettingsChangeInvalidatesTheCache() throws {
        let (store, directory) = try makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let now = date(2026, 4, 12, timeZone: "Europe/Istanbul")
        let diyanetConfig = configuration()
        let diyanetSig = signature(for: istanbul, configuration: diyanetConfig)
        store.merge(PrayerEngine.resolvedWindow(from: now, startingOffset: 0, dayCount: 5,
                                                coordinate: istanbul, configuration: diyanetConfig),
                    signature: diyanetSig, now: now, calendar: istanbulCalendar)

        for changed in [configuration(madhab: .shafi),
                        configuration(source: .fazilet),
                        configuration(offsets: [.fajr: 2]),
                        configuration(method: .mwl)] {
            let sig = signature(for: istanbul, configuration: changed)
            XCTAssertTrue(store.records(matching: sig).isEmpty,
                          "Fingerprint \(changed.fingerprint) should not read another config's days")
        }
    }

    func testMergeReplacesSameDayAndPrunesOldHistory() throws {
        let (store, directory) = try makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let config = configuration()
        let now = date(2026, 4, 12, timeZone: "Europe/Istanbul")
        let sig = signature(for: istanbul, configuration: config)

        // Days from 200 days ago onwards; retention should discard the ancient ones.
        let old = PrayerEngine.resolvedWindow(from: now, startingOffset: -200, dayCount: 5,
                                              coordinate: istanbul, configuration: config)
        let recent = PrayerEngine.resolvedWindow(from: now, startingOffset: 0, dayCount: 5,
                                                 coordinate: istanbul, configuration: config)
        store.merge(old, signature: sig, now: now, calendar: istanbulCalendar)
        store.merge(recent, signature: sig, now: now, calendar: istanbulCalendar)
        let stored = store.records(matching: sig)
        XCTAssertEqual(stored.count, recent.count, "Days older than the retention window must be pruned")

        // Re-merging the same days must not duplicate them.
        store.merge(recent, signature: sig, now: now, calendar: istanbulCalendar)
        XCTAssertEqual(store.records(matching: sig).count, recent.count)
    }

    func testCorruptCacheFileResetsInsteadOfCrashing() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent("prayer_cache_v1.json")
        try Data("{ not json at all".utf8).write(to: fileURL)

        let store = PrayerCacheStore(directory: directory)
        XCTAssertNil(store.load())
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path),
                       "A corrupt cache must be removed, not re-read forever")

        // And the store must still be usable afterwards.
        let config = configuration()
        let now = date(2026, 4, 12, timeZone: "Europe/Istanbul")
        let sig = signature(for: istanbul, configuration: config)
        store.merge(PrayerEngine.resolvedWindow(from: now, startingOffset: 0, dayCount: 3,
                                                coordinate: istanbul, configuration: config),
                    signature: sig, now: now, calendar: istanbulCalendar)
        XCTAssertEqual(store.records(matching: sig).count, 3)
    }

    func testWrongVersionFileIsDiscarded() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let config = configuration()
        let now = date(2026, 4, 12, timeZone: "Europe/Istanbul")
        let sig = signature(for: istanbul, configuration: config)
        var file = PrayerCacheFile(
            signature: sig,
            records: PrayerEngine.resolvedWindow(from: now, startingOffset: 0, dayCount: 3,
                                                 coordinate: istanbul, configuration: config)
        )
        file.version = PrayerCacheFile.currentVersion + 99
        let data = try JSONEncoder.prayerEncoder.encode(file)
        try data.write(to: directory.appendingPathComponent("prayer_cache_v1.json"))

        XCTAssertNil(PrayerCacheStore(directory: directory).load())
    }

    // MARK: - Fingerprint

    func testFingerprintIsStableAndSensitive() {
        let a = configuration()
        XCTAssertEqual(a.fingerprint, configuration().fingerprint)
        XCTAssertNotEqual(a.fingerprint, configuration(madhab: .shafi).fingerprint)
        XCTAssertNotEqual(a.fingerprint, configuration(source: .turkiyeTakvimi).fingerprint)
        XCTAssertNotEqual(a.fingerprint, configuration(offsets: [.asr: 1]).fingerprint)
        XCTAssertNotEqual(a.fingerprint, configuration(timeZone: "Europe/Berlin").fingerprint)
    }

    func testSignatureRoundsCoordinatesToAboutOneKilometre() {
        let config = configuration()
        let here = PrayerCacheSignature(latitude: 41.0082, longitude: 28.9784,
                                        configurationFingerprint: config.fingerprint)
        let nextStreet = PrayerCacheSignature(latitude: 41.0080, longitude: 28.9781,
                                              configurationFingerprint: config.fingerprint)
        let nextCity = PrayerCacheSignature(latitude: 39.9334, longitude: 32.8597,
                                            configurationFingerprint: config.fingerprint)
        XCTAssertEqual(here, nextStreet, "Walking around town must not throw the cache away")
        XCTAssertNotEqual(here, nextCity, "Moving city must")
    }
}
