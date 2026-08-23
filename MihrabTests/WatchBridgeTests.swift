import CoreLocation
import XCTest

/// Covers the parts of the Apple Watch layer that are pure logic and can be
/// exercised without a watch: the wire format, the watch-side stores, and the
/// on-watch schedule calculation.
///
/// Requires on the `MihrabTests` target (see report):
///   - `Mihrab/Core/Connectivity/WatchBridgePayload.swift`
///   - `MihrabWatch/Shared`
///
/// Deliberately **not** covered here, because no simulator can: `WCSession`
/// activation, transfer delivery, the complication transfer budget, and the
/// compass. Those are listed in the report as things to try on real hardware.
final class WatchSettingsPayloadTests: XCTestCase {

    private func makePayload(method: Int = CalculationMethod.diyanet.rawValue,
                             offsets: [String: Int] = [:]) -> WatchSettingsPayload {
        WatchSettingsPayload(latitude: 41.0082,
                             longitude: 28.9784,
                             cityName: "İstanbul",
                             methodID: method,
                             madhabID: Madhab.hanafi.rawValue,
                             sourceID: PrayerSource.diyanet.rawValue,
                             offsetMinutes: offsets,
                             timeZoneIdentifier: "Europe/Istanbul",
                             languageCode: "tr")
    }

    func testRoundTripsThroughApplicationContext() throws {
        let payload = makePayload(offsets: ["fajr": -2, "isha": 3])
        let context = try payload.contextDictionary()
        let decoded = try XCTUnwrap(WatchSettingsPayload.decode(from: context))

        XCTAssertEqual(decoded.latitude, payload.latitude)
        XCTAssertEqual(decoded.longitude, payload.longitude)
        XCTAssertEqual(decoded.cityName, "İstanbul")
        XCTAssertEqual(decoded.offsetMinutes["fajr"], -2)
        XCTAssertEqual(decoded.offsetMinutes["isha"], 3)
        XCTAssertEqual(decoded.languageCode, "tr")
    }

    /// `applicationContext` must be property-list friendly. `Data` is; a
    /// `Codable` struct is not, and shipping one would fail only at runtime, on
    /// a device, silently.
    func testContextValueIsPropertyListFriendly() throws {
        let context = try makePayload().contextDictionary()
        XCTAssertTrue(context[WatchBridge.Key.settings] is Data)
        XCTAssertTrue(PropertyListSerialization.propertyList(context, isValidFor: .binary))
    }

    /// A payload written by a newer phone build must be refused outright rather
    /// than half-applied against fields this build cannot see.
    func testRejectsFuturePayloadVersion() throws {
        var payload = makePayload()
        payload.version = WatchBridge.protocolVersion + 1
        let context = try payload.contextDictionary()
        XCTAssertNil(WatchSettingsPayload.decode(from: context))
    }

    func testDecodeReturnsNilForForeignContext() {
        XCTAssertNil(WatchSettingsPayload.decode(from: ["something": "else"]))
    }

    /// The fingerprint is what stops `syncSettings()` from spending a transfer
    /// on a payload that differs only by its timestamp.
    func testFingerprintIgnoresTimestampAndLogMirror() {
        var a = makePayload()
        var b = makePayload()
        b.generatedAt = a.generatedAt.addingTimeInterval(9_000)
        b.loggedTodayIDs = ["fajr", "dhuhr"]
        XCTAssertEqual(a.calculationFingerprint, b.calculationFingerprint)

        a.methodID = CalculationMethod.mwl.rawValue
        XCTAssertNotEqual(a.calculationFingerprint, b.calculationFingerprint)
    }

    func testFingerprintTracksOffsets() {
        let a = makePayload(offsets: ["asr": 1])
        let b = makePayload(offsets: ["asr": 2])
        XCTAssertNotEqual(a.calculationFingerprint, b.calculationFingerprint)
    }

    /// Offset ordering must not leak into the fingerprint — dictionaries have no
    /// stable order, and a fingerprint that flapped would re-send forever.
    func testFingerprintIsOrderIndependent() {
        let a = makePayload(offsets: ["asr": 1, "isha": -3, "fajr": 2])
        let b = makePayload(offsets: ["fajr": 2, "asr": 1, "isha": -3])
        XCTAssertEqual(a.calculationFingerprint, b.calculationFingerprint)
    }

    func testHasCoordinateIsFalseWhenPhoneHasNoFix() {
        var payload = makePayload()
        payload.latitude = nil
        payload.longitude = nil
        XCTAssertFalse(payload.hasCoordinate)
    }
}

// MARK: - Events

final class WatchBridgeEnvelopeTests: XCTestCase {

    func testEnvelopeRoundTrips() throws {
        let envelope = WatchBridgeEnvelope(events: [
            .dhikrTicks(phraseID: "subhanallah", amount: 33),
            .prayerLog(prayerID: "asr", dayKey: "2026-03-14", logged: true),
        ])
        let userInfo = try envelope.userInfo()
        let decoded = try XCTUnwrap(WatchBridgeEnvelope.decode(from: userInfo))

        XCTAssertEqual(decoded.id, envelope.id)
        XCTAssertEqual(decoded.events, envelope.events)
        XCTAssertTrue(PropertyListSerialization.propertyList(userInfo, isValidFor: .binary))
    }

    /// The whole reason `prayerLog` carries state instead of a toggle: a
    /// duplicate delivery must be a no-op, not a flip.
    func testPrayerLogCarriesAbsoluteState() {
        let event = WatchBridgeEvent.prayerLog(prayerID: "maghrib", dayKey: "2026-03-14", logged: true)
        guard case let .prayerLog(_, _, logged) = event else { return XCTFail("wrong case") }
        XCTAssertTrue(logged)
    }

    func testDayKeyMatchesPrayerLogStoreFormat() {
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 7
        components.hour = 12
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: components)!

        XCTAssertEqual(WatchBridge.dayKey(for: date), "2026-03-07")
        let parsed = WatchBridge.date(fromDayKey: "2026-03-07")
        XCTAssertEqual(calendar.dateComponents([.year, .month, .day], from: parsed!).day, 7)
    }

    func testDayKeyRejectsGarbage() {
        XCTAssertNil(WatchBridge.date(fromDayKey: "not-a-day"))
    }
}

// MARK: - Watch-side store

final class WatchSharedStateTests: XCTestCase {

    override func setUp() {
        super.setUp()
        let defaults = WatchSharedState.defaults
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("mihrab.watch.") {
            defaults.removeObject(forKey: key)
        }
    }

    func testDhikrAccumulatesAndDrainsOnce() {
        XCTAssertEqual(WatchSharedState.addDhikr(1, phraseID: "salawat"), 1)
        XCTAssertEqual(WatchSharedState.addDhikr(32, phraseID: "salawat"), 33)
        XCTAssertEqual(WatchSharedState.dhikrTodayCount, 33)
        XCTAssertEqual(WatchSharedState.dhikrPhraseID, "salawat")

        XCTAssertEqual(WatchSharedState.drainDhikrOutbox(), 33)
        // Draining hands the taps to the phone; it must not clear the day's
        // tally, which is what the complication shows.
        XCTAssertEqual(WatchSharedState.drainDhikrOutbox(), 0)
        XCTAssertEqual(WatchSharedState.dhikrTodayCount, 33)
    }

    /// A failed flush must be recoverable, or a session's beads vanish.
    func testOutboxCanBeReturned() {
        _ = WatchSharedState.addDhikr(10, phraseID: "subhanallah")
        let drained = WatchSharedState.drainDhikrOutbox()
        WatchSharedState.returnToDhikrOutbox(drained)
        XCTAssertEqual(WatchSharedState.drainDhikrOutbox(), 10)
    }

    func testPrayerLogPersistsPerDay() {
        let today = Date()
        let yesterday = today.addingTimeInterval(-86_400)

        WatchSharedState.setLogged([.fajr, .asr], on: today)
        WatchSharedState.setLogged([.isha], on: yesterday)

        XCTAssertEqual(WatchSharedState.loggedPrayers(on: today), [.fajr, .asr])
        XCTAssertEqual(WatchSharedState.loggedPrayers(on: yesterday), [.isha])
    }

    /// The phone's marks are merged in, never used to erase a mark the wrist
    /// made while the phone was out of range.
    func testMergePhoneLogIsAdditive() {
        let today = Date()
        WatchSharedState.setLogged([.maghrib], on: today)
        WatchSharedState.mergePhoneLog(ids: ["fajr", "dhuhr"], dayKey: WatchBridge.dayKey(for: today))
        XCTAssertEqual(WatchSharedState.loggedPrayers(on: today), [.maghrib, .fajr, .dhuhr])
    }

    func testMergePhoneLogIgnoresUnparseableDay() {
        let today = Date()
        WatchSharedState.setLogged([.maghrib], on: today)
        WatchSharedState.mergePhoneLog(ids: ["fajr"], dayKey: "nonsense")
        XCTAssertEqual(WatchSharedState.loggedPrayers(on: today), [.maghrib])
    }

    func testSettingsSurviveARelaunch() throws {
        let payload = WatchSettingsPayload(latitude: 39.9334,
                                           longitude: 32.8597,
                                           cityName: "Ankara",
                                           methodID: CalculationMethod.diyanet.rawValue,
                                           madhabID: Madhab.hanafi.rawValue,
                                           sourceID: PrayerSource.diyanet.rawValue,
                                           offsetMinutes: [:],
                                           timeZoneIdentifier: "Europe/Istanbul",
                                           languageCode: "tr")
        WatchSharedState.save(payload)
        let loaded = try XCTUnwrap(WatchSharedState.loadSettings())
        XCTAssertEqual(loaded.cityName, "Ankara")
        XCTAssertEqual(loaded.calculationFingerprint, payload.calculationFingerprint)
    }
}

// MARK: - On-watch calculation

/// The architectural claim under test: **the watch computes its own times.**
/// If these pass, a watch with settings and no phone in range is fully
/// functional.
final class WatchScheduleBuilderTests: XCTestCase {

    private let istanbul = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)

    private func payload(lat: Double? = 41.0082, lon: Double? = 28.9784) -> WatchSettingsPayload {
        WatchSettingsPayload(latitude: lat,
                             longitude: lon,
                             cityName: "İstanbul",
                             methodID: CalculationMethod.diyanet.rawValue,
                             madhabID: Madhab.hanafi.rawValue,
                             sourceID: PrayerSource.diyanet.rawValue,
                             offsetMinutes: [:],
                             timeZoneIdentifier: "Europe/Istanbul",
                             languageCode: "tr")
    }

    func testConfigurationSurvivesTheWire() {
        var p = payload()
        p.offsetMinutes = ["fajr": -3, "isha": 4]
        let configuration = WatchScheduleBuilder.configuration(from: p)

        XCTAssertEqual(configuration.method, .diyanet)
        XCTAssertEqual(configuration.madhab, .hanafi)
        XCTAssertEqual(configuration.source, .diyanet)
        XCTAssertEqual(configuration.offsets[.fajr], -3)
        XCTAssertEqual(configuration.offsets[.isha], 4)
        XCTAssertEqual(configuration.timeZoneIdentifier, "Europe/Istanbul")
    }

    /// An unrecognised raw value must degrade to a sane default, not to a blank
    /// watch. Showing times computed with a slightly different preset beats
    /// showing nothing.
    func testUnknownRawValuesFallBackInsteadOfFailing() {
        var p = payload()
        p.methodID = 9_999
        p.madhabID = 9_999
        p.sourceID = "made-up"
        let configuration = WatchScheduleBuilder.configuration(from: p)
        XCTAssertEqual(configuration.method, .diyanet)
        XCTAssertEqual(configuration.madhab, .hanafi)
        XCTAssertEqual(configuration.source, .standard)
    }

    func testComputesAFullDayWithoutAnyPhoneData() throws {
        let schedule = try XCTUnwrap(
            WatchScheduleBuilder.schedule(for: Date(), payload: payload(), watchFix: nil)
        )
        XCTAssertEqual(schedule.rows.count, Prayer.allCases.count)
        XCTAssertNotNil(schedule.tomorrow)
        XCTAssertFalse(schedule.usesWatchLocation)
        XCTAssertEqual(schedule.cityName, "İstanbul")

        // Chronological, which is what every screen and the timeline assume.
        let dates = schedule.rows.map(\.date)
        XCTAssertEqual(dates, dates.sorted())
    }

    /// Produces the same numbers the phone would for the same inputs — the whole
    /// point of syncing settings rather than results.
    func testMatchesThePhoneEngineExactly() throws {
        let p = payload()
        let date = Date()
        let configuration = WatchScheduleBuilder.configuration(from: p)
        let phone = try XCTUnwrap(PrayerEngine.times(for: date,
                                                     coordinate: istanbul,
                                                     configuration: configuration))
        let watch = try XCTUnwrap(
            WatchScheduleBuilder.schedule(for: date, payload: p, watchFix: nil)
        )
        for prayer in Prayer.allCases {
            XCTAssertEqual(watch.today.times[prayer], phone.times[prayer], "\(prayer)")
        }
    }

    /// The phone's coordinate wins: it carries the manual city choice, which the
    /// watch's GPS knows nothing about.
    func testPhoneCoordinateBeatsWatchFix() throws {
        let watchFix = CLLocationCoordinate2D(latitude: 21.42, longitude: 39.82)
        let resolved = try XCTUnwrap(
            WatchScheduleBuilder.coordinate(payload: payload(), watchFix: watchFix)
        )
        XCTAssertEqual(resolved.0.latitude, 41.0082, accuracy: 0.0001)
        XCTAssertFalse(resolved.1)
    }

    func testFallsBackToWatchFixAndSaysSo() throws {
        let watchFix = CLLocationCoordinate2D(latitude: 39.9334, longitude: 32.8597)
        let schedule = try XCTUnwrap(
            WatchScheduleBuilder.schedule(for: Date(),
                                          payload: payload(lat: nil, lon: nil),
                                          watchFix: watchFix)
        )
        XCTAssertTrue(schedule.usesWatchLocation)
    }

    /// No coordinate anywhere: `nil`, so the UI can say "no location" instead of
    /// inventing one.
    func testReturnsNilWithNoCoordinateAtAll() {
        XCTAssertNil(WatchScheduleBuilder.schedule(for: Date(), payload: nil, watchFix: nil))
        XCTAssertNil(WatchScheduleBuilder.coordinate(payload: payload(lat: nil, lon: nil),
                                                     watchFix: nil))
    }

    /// Polar latitudes have no honest answer in midsummer. `nil` is the answer;
    /// plausible-looking invented times are not.
    func testReturnsNilAboveThePolarCircleInMidsummer() {
        var p = payload(lat: 78.22, lon: 15.65) // Longyearbyen
        p.timeZoneIdentifier = "Europe/Oslo"
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 21
        components.hour = 12
        let date = Calendar(identifier: .gregorian).date(from: components)!

        XCTAssertNil(WatchScheduleBuilder.schedule(for: date, payload: p, watchFix: nil))
    }

    func testNextRollsIntoTomorrowAfterIsha() throws {
        let schedule = try XCTUnwrap(
            WatchScheduleBuilder.schedule(for: Date(), payload: payload(), watchFix: nil)
        )
        let isha = try XCTUnwrap(schedule.today.times[.isha])
        let next = try XCTUnwrap(schedule.next(after: isha.addingTimeInterval(60)))
        XCTAssertEqual(next.prayer, .fajr)
        XCTAssertGreaterThan(next.date, isha)
    }
}

// MARK: - Catalogue parity

final class WatchDhikrCatalogTests: XCTestCase {

    /// The watch keeps its own small copy of the six classics. If an id drifts
    /// from the phone's `DhikrCatalog`, counts made on the wrist land on the
    /// wrong phrase — silently. This pins them.
    func testIdsMatchThePhoneCatalogue() {
        XCTAssertEqual(WatchDhikrCatalog.all.map(\.id),
                       ["subhanallah", "alhamdulillah", "allahu-akbar",
                        "la-ilaha", "salawat", "astaghfirullah"])
    }

    func testTargetsMatchTheTesbihatCount() {
        XCTAssertEqual(WatchDhikrCatalog.subhanallah.target, 33)
        XCTAssertEqual(WatchDhikrCatalog.alhamdulillah.target, 33)
        XCTAssertEqual(WatchDhikrCatalog.allahuAkbar.target, 34)
    }

    func testLookupByID() {
        XCTAssertEqual(WatchDhikrCatalog.item(id: "salawat")?.target, 100)
        XCTAssertNil(WatchDhikrCatalog.item(id: "not-a-phrase"))
    }
}
