import XCTest

/// Covers the parts of the App Intents layer that are pure logic: the shared
/// counter's midnight roll and drain semantics, the deep-link hand-off, and the
/// next-prayer / iftar selection the intents and widgets both rely on.
///
/// Requires `Mihrab/Intents/Shared` on the `MihrabTests` target (see report).
final class SharedDhikrCounterTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: SharedPrayerCache.appGroupID) ?? .standard
        // `removeObject` leaves values that were registered in another process
        // (the app itself writes this suite) still readable through the cached
        // domain. Wiping the persistent domain is the only reliable reset, and
        // without it a real counting session in the simulator leaks into the
        // assertions here.
        defaults.removePersistentDomain(forName: SharedPrayerCache.appGroupID)
        defaults.synchronize()
    }

    func testAddAccumulates() {
        XCTAssertEqual(SharedDhikrCounter.add(1), 1)
        XCTAssertEqual(SharedDhikrCounter.add(32), 33)
        XCTAssertEqual(SharedDhikrCounter.todayCount, 33)
    }

    /// A non-positive amount must never decrement — "count dhikr" only ever adds.
    func testAddClampsToAtLeastOne() {
        XCTAssertEqual(SharedDhikrCounter.add(0), 1)
        XCTAssertEqual(SharedDhikrCounter.add(-10), 2)
    }

    /// Drain hands the app exactly the taps made outside it, once.
    ///
    /// Asserted as a delta, not an absolute: this suite is the live App Group,
    /// which the app itself writes to. A real counting session in the simulator
    /// used to leak in and fail the absolute form — but what the code actually
    /// promises is "drain returns what was added and leaves the total alone",
    /// and that holds whatever the starting tally is.
    func testDrainPendingIsConsumedOnlyOnce() {
        SharedDhikrCounter.drainPending()          // clear anything ambient
        let before = SharedDhikrCounter.todayCount
        SharedDhikrCounter.add(5)
        XCTAssertEqual(SharedDhikrCounter.drainPending(), 5)
        XCTAssertEqual(SharedDhikrCounter.drainPending(), 0)
        XCTAssertEqual(SharedDhikrCounter.todayCount, before + 5)
    }

    /// A tally written on a previous day resets instead of carrying over.
    func testStaleDayRollsOver() {
        defaults.set("2001-01-01", forKey: "mihrab.shared.dhikr.day")
        defaults.set(999, forKey: "mihrab.shared.dhikr.count")
        XCTAssertEqual(SharedDhikrCounter.todayCount, 0)
    }

    func testPublishAppTotalOverwrites() {
        SharedDhikrCounter.add(3)
        SharedDhikrCounter.publishAppTotal(120, phraseID: "salawat")
        XCTAssertEqual(SharedDhikrCounter.todayCount, 120)
        XCTAssertEqual(SharedDhikrCounter.phraseID, "salawat")
    }
}

final class MihrabDeepLinkTests: XCTestCase {

    func testTabRequestIsConsumedOnce() {
        MihrabDeepLink.requestTab(.qibla)
        XCTAssertEqual(MihrabDeepLink.consumeTab(), .qibla)
        XCTAssertNil(MihrabDeepLink.consumeTab())
    }

    func testDhikrSessionRequestCarriesTargetAndSelectsTab() {
        MihrabDeepLink.requestDhikrSession(phraseID: "salawat", target: 100)
        let request = MihrabDeepLink.consumeDhikrSession()
        XCTAssertEqual(request?.phraseID, "salawat")
        XCTAssertEqual(request?.target, 100)
        XCTAssertEqual(MihrabDeepLink.consumeTab(), .dhikr)
        XCTAssertNil(MihrabDeepLink.consumeDhikrSession())
    }

    func testURLsMatchWidgetDeepLinks() {
        XCTAssertEqual(MihrabDeepLink.url(for: .times)?.absoluteString, "mihrab://times")
        XCTAssertEqual(MihrabDeepLink.url(for: .dhikr)?.absoluteString, "mihrab://dhikr")
    }
}

final class FastEdgeTests: XCTestCase {

    private func snapshot(fajr: Date, maghrib: Date, on day: Date) -> SharedPrayerSnapshot {
        SharedPrayerSnapshot(
            latitude: 41.0082,
            longitude: 28.9784,
            cityName: "İstanbul",
            methodID: 13,
            days: [DayPrayerTimes(date: day, times: [.fajr: fajr, .maghrib: maghrib])]
        )
    }

    /// Before sunset the widget counts to iftar.
    func testBeforeMaghribCountsToIftar() {
        let day = Calendar.current.startOfDay(for: Date())
        let fajr = day.addingTimeInterval(5 * 3600)
        let maghrib = day.addingTimeInterval(19 * 3600)
        let now = day.addingTimeInterval(15 * 3600)

        guard case .iftar(let date)? = FastEdge.next(at: now, snapshot: snapshot(fajr: fajr, maghrib: maghrib, on: day)) else {
            return XCTFail("Expected an iftar countdown before maghrib")
        }
        XCTAssertEqual(date, maghrib)
    }

    /// Before dawn — still the same calendar day — it counts to the end of suhoor.
    func testBeforeFajrCountsToSuhoor() {
        let day = Calendar.current.startOfDay(for: Date())
        let fajr = day.addingTimeInterval(5 * 3600)
        let maghrib = day.addingTimeInterval(19 * 3600)
        let now = day.addingTimeInterval(3 * 3600)

        guard case .suhoor(let date)? = FastEdge.next(at: now, snapshot: snapshot(fajr: fajr, maghrib: maghrib, on: day)) else {
            return XCTFail("Expected a suhoor countdown before fajr")
        }
        XCTAssertEqual(date, fajr)
    }

    /// No cached day means no countdown — never a fabricated one.
    func testNoSnapshotYieldsNothing() {
        XCTAssertNil(FastEdge.next(at: Date(), snapshot: nil))
    }
}
