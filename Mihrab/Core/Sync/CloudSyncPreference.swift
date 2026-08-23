import Foundation

// MARK: - Preference (readable before the container is built)

/// The sync switch, stored in the App Group. `Persistence` reads this *before*
/// any object exists, so it lives on its own tiny type rather than on the
/// `@Observable` manager.
enum CloudSyncPreference {
    static let enabledKey = "mihrab.sync.iCloudEnabled"
    static let lastSyncKey = "mihrab.sync.lastSyncedAt"
    /// Mirrored copy of the Plus entitlement, written by `SubscriptionManager`.
    static let entitlementKey = "mihrab.subscription.isPremium"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: SharedPrayerCache.appGroupID) ?? .standard
    }

    static var isEnabled: Bool {
        get { defaults.bool(forKey: enabledKey) }
        set { defaults.set(newValue, forKey: enabledKey) }
    }

    /// Sync is a Plus feature. Reading the mirrored flag (rather than
    /// `SubscriptionManager`) keeps `Persistence` free of a main-actor hop.
    ///
    /// If Plus lapses we stop syncing — **we never delete anything**. The local
    /// store and every record already in iCloud stay exactly where they are.
    static var isEntitled: Bool {
        defaults.bool(forKey: entitlementKey)
    }

    static var lastSyncedAt: Date? {
        get { defaults.object(forKey: lastSyncKey) as? Date }
        set { defaults.set(newValue, forKey: lastSyncKey) }
    }
}
