import Foundation
import SwiftUI

// MARK: - Extension-safe entitlement mirror

/// The Plus entitlement, readable from **any** target — including
/// `MihrabWidgets`, which cannot see `SubscriptionManager` (StoreKit state
/// lives in the app process).
///
/// `SubscriptionManager.mirrorEntitlement()` writes these keys into the App
/// Group on every launch, purchase, restore and trial start.
///
/// ⚠️ **Target membership:** for the widgets extension to read this, the file
/// must be a member of the `MihrabWidgets` target too. Flagged to the main
/// session — this agent does not touch `project.yml`.
public enum PremiumEntitlement {
    public static let appGroupID = "group.com.caferkarakaya.mihrab"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    /// Paid entitlement *or* a running trial, as of the app's last refresh.
    public static var isPremium: Bool {
        defaults.bool(forKey: "mihrab.subscription.isPremium")
    }

    /// When the local trial ends, if one is running.
    public static var trialEndsAt: Date? {
        defaults.object(forKey: "mihrab.subscription.trialEndsAt") as? Date
    }

    public static var isInTrial: Bool {
        guard let end = trialEndsAt else { return false }
        return end > Date()
    }
}
