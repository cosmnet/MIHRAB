import XCTest

/// W4's gate tests.
///
/// ⚠️ **Target membership (main session):** `MihrabTests` compiles a hand-picked
/// list of sources in `project.yml`. These tests need the following added to
/// that list — all of them are dependency-light on purpose:
///
/// ```yaml
///   MihrabTests:
///     sources:
///       - path: MihrabTests
///       - path: Mihrab/Core/Shared
///       - path: Mihrab/Data/BundledContent.swift
///       - path: Mihrab/Data/AladhanClient.swift
///       - path: Mihrab/Features/Cities/CityTierPolicy.swift      # new
///       - path: Mihrab/Core/Sync/CloudSyncPreference.swift       # new
///       - path: Mihrab/Core/Sync/KeyValueSync.swift              # new
///       - path: Mihrab/Core/Subscription/SubscriptionManager.swift  # new
///       - path: Mihrab/Core/Subscription/TrialReminder.swift        # new
///       - path: Mihrab/Features/Paywall/L10n+Paywall.swift          # new
/// ```
///
/// `CityStore` itself is *not* in that list: it pulls in `AppSettings`,
/// `LocationManager` and the SwiftUI layer. Its tier rule lives in
/// `CityTierPolicy`, which is what is exercised here.
final class SubscriptionGateTests: XCTestCase {

    // MARK: - Free tier city limit

    func testFreeTierHoldsExactlyOneCity() {
        let policy = CityTierPolicy(isPremium: false)

        // Nothing saved yet: the one slot (the device's own location) is open.
        XCTAssertTrue(policy.canAdd(currentCount: 0))
        XCTAssertEqual(policy.remainingSlots(currentCount: 0), 1)

        // Once the slot is taken, adding must fail — the caller then shows
        // `PaywallView(source: .feature)`.
        XCTAssertFalse(policy.canAdd(currentCount: 1))
        XCTAssertEqual(policy.remainingSlots(currentCount: 1), 0)
        XCTAssertFalse(policy.canAdd(currentCount: 7))
    }

    func testPremiumTierIsUnlimited() {
        let policy = CityTierPolicy(isPremium: true)
        XCTAssertTrue(policy.canAdd(currentCount: 0))
        XCTAssertTrue(policy.canAdd(currentCount: 1))
        XCTAssertTrue(policy.canAdd(currentCount: 250))
        XCTAssertNil(policy.remainingSlots(currentCount: 250))
        XCTAssertFalse(policy.isLocked(index: 99))
        XCTAssertEqual(policy.selectableCount(total: 12), 12)
    }

    /// The important one: when Plus lapses the extra cities must be *locked*,
    /// never removed. `selectableCount` shrinks; the total does not.
    func testDowngradeLocksExtraCitiesWithoutDeletingThem() {
        let total = 5
        let premium = CityTierPolicy(isPremium: true)
        let lapsed = CityTierPolicy(isPremium: false)

        XCTAssertEqual(premium.selectableCount(total: total), 5)
        XCTAssertEqual(lapsed.selectableCount(total: total), 1)

        // The first city stays usable, the rest are dimmed with a Plus badge.
        XCTAssertFalse(lapsed.isLocked(index: 0))
        for index in 1..<total {
            XCTAssertTrue(lapsed.isLocked(index: index), "city \(index) should be locked, not deleted")
        }

        // Re-subscribing brings every one of them straight back.
        for index in 0..<total {
            XCTAssertFalse(premium.isLocked(index: index))
        }
    }

    func testFreeLimitIsNeverZero() {
        // A misconfigured limit must not lock the user out of their own city.
        XCTAssertEqual(CityTierPolicy(freeLimit: 0, isPremium: false).freeLimit, 1)
        XCTAssertEqual(CityTierPolicy(freeLimit: -3, isPremium: false).freeLimit, 1)
    }

    // MARK: - hasAccess(to:)

    @MainActor
    func testHasAccessFollowsEntitlementForEveryFeature() {
        let manager = SubscriptionManager.shared
        let original = SubscriptionManager.debugForcePremium
        defer { SubscriptionManager.debugForcePremium = original }

        SubscriptionManager.debugForcePremium = true
        for feature in PremiumFeature.allCases {
            XCTAssertTrue(manager.hasAccess(to: feature), "\(feature.rawValue) should unlock with Plus")
            XCTAssertFalse(manager.requiresUpgrade(feature))
        }

        // No entitlement and no running trial — this is exactly the state a
        // user lands in when the free week ends.
        SubscriptionManager.debugForcePremium = false
        guard !manager.hasPaidEntitlement, !manager.isInTrial else {
            // A sandbox purchase or a live trial on the test device: the
            // negative half of this assertion cannot be made meaningfully.
            return
        }
        for feature in PremiumFeature.allCases {
            XCTAssertFalse(manager.hasAccess(to: feature), "\(feature.rawValue) should lock without Plus")
            XCTAssertTrue(manager.requiresUpgrade(feature))
        }
    }

    /// Locking a surface must never be a data operation. The gate is a pure
    /// read — calling it repeatedly changes nothing the user owns.
    @MainActor
    func testGateIsReadOnly() {
        let manager = SubscriptionManager.shared
        let original = SubscriptionManager.debugForcePremium
        defer { SubscriptionManager.debugForcePremium = original }

        let trialStartBefore = manager.trialStartedAt
        let hadEntitlement = manager.hasPaidEntitlement

        SubscriptionManager.debugForcePremium = false
        for feature in PremiumFeature.allCases { _ = manager.hasAccess(to: feature) }

        XCTAssertEqual(manager.trialStartedAt, trialStartBefore)
        XCTAssertEqual(manager.hasPaidEntitlement, hadEntitlement)
    }

    // MARK: - Gate audit (Guideline 2.3.1)

    /// Every advertised feature must name the place it is enforced. A case with
    /// no declared site is a feature the paywall sells but the binary ignores.
    func testEveryPremiumFeatureDeclaresAnEnforcementSite() {
        for feature in PremiumFeature.allCases {
            let site = feature.enforcement.siteDescription
            XCTAssertFalse(
                site.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                "\(feature.rawValue) declares no enforcement site"
            )
            XCTAssertFalse(
                feature.localizedTitle.isEmpty,
                "\(feature.rawValue) has no localized title"
            )
        }
    }

    /// The two features W4 built in this wave are enforced in shipped code.
    func testW4FeaturesAreLive() {
        XCTAssertTrue(PremiumFeature.multipleCities.enforcement.isLive)
        XCTAssertTrue(PremiumFeature.iCloudBackup.enforcement.isLive)
    }

    func testFeatureIdentifiersAreUnique() {
        let ids = PremiumFeature.allCases.map(\.rawValue)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    // MARK: - Key-value backup layer

    func testKeyValueSnapshotRoundTrips() throws {
        let snapshot = KeyValueSync.Snapshot(
            prayerLog: ["prayerLog.2026-08-23": ["fajr", "dhuhr"]],
            fastedDays: ["2026-03-01"],
            esmaFavorites: ["ar-rahman"],
            esmaVisited: ["ar-rahman", "al-malik"],
            dhikrCustom: Data("custom".utf8).base64EncodedString(),
            dhikrFlags: ["mihrab.dhikr.haptics": true],
            dhikrLastPhrase: "subhanallah"
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        let decoded = try KeyValueSync.decode(data)

        XCTAssertEqual(decoded.prayerLog, snapshot.prayerLog)
        XCTAssertEqual(decoded.fastedDays, snapshot.fastedDays)
        XCTAssertEqual(decoded.esmaFavorites, snapshot.esmaFavorites)
        XCTAssertEqual(decoded.dhikrCustom, snapshot.dhikrCustom)
        XCTAssertEqual(decoded.dhikrFlags, snapshot.dhikrFlags)
        XCTAssertEqual(decoded.dhikrLastPhrase, snapshot.dhikrLastPhrase)
    }

    /// An additive merge must never *un*-mark a prayer or a fasted day.
    func testAdditiveImportOnlyEverAdds() {
        let defaults = UserDefaults.standard
        let logKey = "prayerLog.2026-08-22"
        let fastKey = "ramadanFastedDays"
        let originalLog = defaults.stringArray(forKey: logKey)
        let originalFast = defaults.stringArray(forKey: fastKey)
        defer {
            defaults.set(originalLog, forKey: logKey)
            defaults.set(originalFast, forKey: fastKey)
        }

        defaults.set(["fajr"], forKey: logKey)
        defaults.set(["2026-03-02"], forKey: fastKey)

        let incoming = KeyValueSync.Snapshot(
            prayerLog: [logKey: ["isha"]],
            fastedDays: ["2026-03-03"]
        )
        KeyValueSync.importSnapshot(incoming, strategy: .unionAdditive)

        XCTAssertEqual(Set(defaults.stringArray(forKey: logKey) ?? []), ["fajr", "isha"])
        XCTAssertEqual(Set(defaults.stringArray(forKey: fastKey) ?? []), ["2026-03-02", "2026-03-03"])
    }

    /// Sync being off (or Plus having lapsed) must stop the *transfer* — it must
    /// never wipe the cloud copy or the local one.
    func testPushIsANoOpWhenSyncIsOffAndDeletesNothing() {
        let originalEnabled = CloudSyncPreference.isEnabled
        defer { CloudSyncPreference.isEnabled = originalEnabled }

        let defaults = UserDefaults.standard
        let logKey = "prayerLog.2026-08-21"
        let original = defaults.stringArray(forKey: logKey)
        defer { defaults.set(original, forKey: logKey) }
        defaults.set(["asr"], forKey: logKey)

        CloudSyncPreference.isEnabled = false
        XCTAssertFalse(KeyValueSync.push())
        XCTAssertFalse(KeyValueSync.pull())

        // The local record is untouched.
        XCTAssertEqual(defaults.stringArray(forKey: logKey), ["asr"])
    }
}
