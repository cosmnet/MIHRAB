import Foundation
import StoreKit
import SwiftUI

// MARK: - Product catalog

/// The three Mihrab Plus SKUs. Identifiers must match App Store Connect
/// (and `Mihrab/Resources/Mihrab.storekit` for local testing).
enum MihrabProduct: String, CaseIterable, Identifiable, Sendable {
    case monthly = "com.caferkarakaya.mihrab.plus.monthly"
    case yearly = "com.caferkarakaya.mihrab.plus.yearly"
    case lifetime = "com.caferkarakaya.mihrab.plus.lifetime"

    var id: String { rawValue }

    /// Display order in the paywall — yearly first, it is the recommended plan.
    static var displayOrder: [MihrabProduct] { [.yearly, .monthly, .lifetime] }

    var isSubscription: Bool { self != .lifetime }

    /// Fallback price used when StoreKit cannot reach the store (offline, or
    /// products not yet approved in App Store Connect). Values mirror PRICING.md.
    /// The paywall must never show "₺--"; an honest indicative price is better.
    var fallbackPriceTRY: String {
        switch self {
        case .monthly: "₺129,99"
        case .yearly: "₺649,99"
        case .lifetime: "₺1.299,99"
        }
    }

    var fallbackPriceUSD: String {
        switch self {
        case .monthly: "$4.99"
        case .yearly: "$24.99"
        case .lifetime: "$59.99"
        }
    }

    /// Raw decimal used for the "per month" derivation and the savings badge.
    var fallbackAmountTRY: Decimal {
        switch self {
        case .monthly: 129.99
        case .yearly: 649.99
        case .lifetime: 1299.99
        }
    }

    var fallbackAmountUSD: Decimal {
        switch self {
        case .monthly: 4.99
        case .yearly: 24.99
        case .lifetime: 59.99
        }
    }
}

// MARK: - Premium feature gate

/// Everything that is *required to practise* — prayer times, qibla, adhan
/// notifications, the daily verse — stays free, forever. Premium is the
/// "beautifying" layer only.
enum PremiumFeature: String, CaseIterable, Sendable {
    case advancedWidgets
    case themes
    case customAdhan
    case dhikrUnlimitedGoals
    case dhikrFullHistory
    case esmaCollections
    case tafakkurContent
    case ramadanPlanner
    case qiblaAR
    case multipleCities
    case iCloudBackup
    case shareCards

    /// Features that are *never* gated live outside this enum — this list is
    /// deliberately empty of anything worship-critical.
    var localizedTitle: String {
        switch self {
        case .advancedWidgets: L10n.premiumFeatureWidgets
        case .themes: L10n.premiumFeatureThemes
        case .customAdhan: L10n.premiumFeatureAdhan
        case .dhikrUnlimitedGoals: L10n.premiumFeatureDhikrGoals
        case .dhikrFullHistory: L10n.premiumFeatureDhikrHistory
        case .esmaCollections: L10n.premiumFeatureEsma
        case .tafakkurContent: L10n.premiumFeatureTafakkur
        case .ramadanPlanner: L10n.premiumFeatureRamadan
        case .qiblaAR: L10n.premiumFeatureQiblaAR
        case .multipleCities: L10n.premiumFeatureCities
        case .iCloudBackup: L10n.premiumFeatureBackup
        case .shareCards: L10n.premiumFeatureShare
        }
    }
}

// MARK: - Paywall entry points

enum PaywallSource: String, Sendable {
    case onboarding
    case settings
    case feature
}

// MARK: - Purchase outcome

enum PurchaseOutcome: Equatable, Sendable {
    case success
    case pending
    case cancelled
    case failed(String)
}

// MARK: - Manager

/// StoreKit 2 entitlement + local 7-day trial bookkeeping.
///
/// Design notes:
/// * Never crashes or blocks the UI when products are unavailable. The paywall
///   falls back to indicative prices and purchases are simply disabled.
/// * Trial state lives in the App Group so widgets can read it too.
/// * A monotonic "high water mark" date defeats naive clock rollback.
@MainActor
@Observable
final class SubscriptionManager {
    static let shared = SubscriptionManager()

    // MARK: Observable state

    /// Full access — a paid entitlement *or* an active free trial.
    var isPremium: Bool {
        #if DEBUG
        if Self.debugForcePremium { return true }
        #endif
        return hasPaidEntitlement || isInTrial
    }

    /// True only while the local 7-day trial is running.
    var isInTrial: Bool {
        guard !hasPaidEntitlement, let end = trialEndsAt else { return false }
        return effectiveNow < end
    }

    /// 0…7. Rounded up, so the last partial day still reads "1 gün kaldı".
    var trialDaysRemaining: Int {
        guard let end = trialEndsAt else { return 0 }
        let seconds = end.timeIntervalSince(effectiveNow)
        guard seconds > 0 else { return 0 }
        return max(1, Int(ceil(seconds / 86_400)))
    }

    var hasStartedTrial: Bool { trialStartedAt != nil }

    /// True once a trial ran to completion without a purchase.
    var trialHasExpired: Bool { hasStartedTrial && !isInTrial && !hasPaidEntitlement }

    /// Verified non-consumable / auto-renewable entitlement from StoreKit.
    private(set) var hasPaidEntitlement = false

    /// The product the user currently owns, when known.
    private(set) var activeProduct: MihrabProduct?

    /// Loaded StoreKit products, keyed by identifier. Empty is a valid state.
    private(set) var products: [String: Product] = [:]

    private(set) var isLoadingProducts = false
    private(set) var isPurchasing = false
    private(set) var lastError: String?

    /// True when `Product.products(for:)` returned nothing — the paywall then
    /// shows indicative pricing and hides the purchase buttons' spinner state.
    var isStoreUnavailable: Bool { products.isEmpty && !isLoadingProducts }

    // MARK: Trial storage

    private(set) var trialStartedAt: Date?

    private var trialEndsAt: Date? {
        trialStartedAt.map { $0.addingTimeInterval(Self.trialDuration) }
    }

    static let trialDuration: TimeInterval = 7 * 86_400

    // MARK: Persistence

    private let defaults: UserDefaults
    private enum Key {
        static let trialStart = "mihrab.subscription.trialStartedAt"
        static let highWater = "mihrab.subscription.highWaterDate"
        static let trialBurned = "mihrab.subscription.trialBurned"
        static let cachedEntitlement = "mihrab.subscription.cachedEntitlement"
    }

    #if DEBUG
    /// Flip to `true` (or launch with `-MihrabForcePremium YES`) to unlock every
    /// premium surface while developing.
    static var debugForcePremium: Bool = UserDefaults.standard.bool(forKey: "MihrabForcePremium")
    #endif

    private var updatesTask: Task<Void, Never>?

    // MARK: Init

    private init() {
        defaults = UserDefaults(suiteName: SharedPrayerCache.appGroupID) ?? .standard

        if let start = defaults.object(forKey: Key.trialStart) as? Date {
            trialStartedAt = start
        }
        // Optimistic restore of the last verified entitlement so the first frame
        // after launch doesn't flash a paywall for a paying member.
        hasPaidEntitlement = defaults.bool(forKey: Key.cachedEntitlement)
        if defaults.bool(forKey: Key.trialBurned) { trialStartedAt = distantTrialStart }

        startTransactionListener()
    }

    /// A start date far enough in the past that the trial reads as consumed.
    private var distantTrialStart: Date { Date(timeIntervalSince1970: 0) }

    // MARK: - Clock

    /// Monotonic "now": never goes backwards across launches, so setting the
    /// device clock back does not extend a running trial.
    private var effectiveNow: Date {
        let now = Date()
        let stored = defaults.object(forKey: Key.highWater) as? Date
        guard let stored else { return now }
        return max(now, stored)
    }

    private func stampClock() {
        let now = Date()
        let stored = defaults.object(forKey: Key.highWater) as? Date
        if stored == nil || now > stored! {
            defaults.set(now, forKey: Key.highWater)
        } else if let stored, stored.timeIntervalSince(now) > 86_400 {
            // Clock moved back more than a day while a trial was running:
            // treat the trial as finished rather than silently extending it.
            if hasStartedTrial && !hasPaidEntitlement {
                defaults.set(true, forKey: Key.trialBurned)
            }
        }
    }

    // MARK: - Public API

    /// Loads products and re-verifies entitlements. Safe to call repeatedly.
    func refresh() async {
        stampClock()
        await loadProducts()
        await verifyEntitlements()
    }

    /// Starts the local 7-day trial. Idempotent — a second call is ignored.
    func startFreeTrial() {
        guard !hasStartedTrial else { return }
        let now = Date()
        trialStartedAt = now
        defaults.set(now, forKey: Key.trialStart)
        defaults.set(now, forKey: Key.highWater)
        defaults.set(false, forKey: Key.trialBurned)
        TrialReminder.scheduleTrialReminders(trialStart: now, duration: Self.trialDuration)
    }

    /// App Store "Restore Purchases".
    func restore() async {
        lastError = nil
        do {
            try await AppStore.sync()
        } catch {
            // A cancelled sign-in sheet throws too; not worth alarming the user.
            lastError = nil
        }
        await verifyEntitlements()
        if !hasPaidEntitlement {
            lastError = L10n.paywallRestoreNothing
        }
    }

    /// Purchases one of the three SKUs.
    @discardableResult
    func purchase(_ item: MihrabProduct) async -> PurchaseOutcome {
        guard let product = products[item.rawValue] else {
            lastError = L10n.paywallStoreUnavailable
            return .failed(L10n.paywallStoreUnavailable)
        }
        guard !isPurchasing else { return .pending }

        isPurchasing = true
        lastError = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard let transaction = verifiedTransaction(verification) else {
                    lastError = L10n.paywallVerificationFailed
                    return .failed(L10n.paywallVerificationFailed)
                }
                await transaction.finish()
                await verifyEntitlements()
                TrialReminder.cancelTrialReminders()
                return .success
            case .pending:
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                return .cancelled
            }
        } catch {
            let message = (error as? StoreKitError).map(Self.describe) ?? error.localizedDescription
            lastError = message
            return .failed(message)
        }
    }

    /// The gate every premium surface should call.
    func hasAccess(to feature: PremiumFeature) -> Bool {
        _ = feature // Single-tier product: one entitlement unlocks the whole layer.
        return isPremium
    }

    // MARK: - Display helpers

    /// Localized store price when available, otherwise the indicative fallback.
    func displayPrice(for item: MihrabProduct) -> String {
        if let product = products[item.rawValue] { return product.displayPrice }
        return isTurkishStorefront ? item.fallbackPriceTRY : item.fallbackPriceUSD
    }

    /// "≈ ₺62,50 / ay" style helper for the yearly card.
    func monthlyEquivalentPrice(for item: MihrabProduct) -> String? {
        guard item == .yearly else { return nil }
        if let product = products[item.rawValue] {
            let monthly = product.price / 12
            return format(monthly, like: product)
        }
        let amount = item.fallbackAmountTRY / 12
        let usd = item.fallbackAmountUSD / 12
        return isTurkishStorefront
            ? "₺" + Self.plainString(amount, fractionDigits: 2).replacingOccurrences(of: ".", with: ",")
            : "$" + Self.plainString(usd, fractionDigits: 2)
    }

    /// Whole-percent saving of yearly against 12× monthly. `nil` if not derivable.
    var yearlySavingsPercent: Int? {
        let monthly: Decimal
        let yearly: Decimal
        if let m = products[MihrabProduct.monthly.rawValue],
           let y = products[MihrabProduct.yearly.rawValue] {
            monthly = m.price
            yearly = y.price
        } else if isTurkishStorefront {
            monthly = MihrabProduct.monthly.fallbackAmountTRY
            yearly = MihrabProduct.yearly.fallbackAmountTRY
        } else {
            monthly = MihrabProduct.monthly.fallbackAmountUSD
            yearly = MihrabProduct.yearly.fallbackAmountUSD
        }
        let full = monthly * 12
        guard full > 0, yearly < full else { return nil }
        let ratio = (full - yearly) / full
        let percent = (ratio as NSDecimalNumber).doubleValue * 100
        return Int(percent.rounded())
    }

    /// Does StoreKit itself offer an introductory free period for this SKU?
    func storeIntroOffer(for item: MihrabProduct) -> Product.SubscriptionOffer? {
        products[item.rawValue]?.subscription?.introductoryOffer
    }

    /// Only consulted when the store is unreachable. Region alone is too narrow —
    /// a Turkish-language device on another region still reads ₺ as "its" price.
    var isTurkishStorefront: Bool {
        if Locale.current.region?.identifier == "TR" { return true }
        return L10n.isTurkish
    }

    // MARK: - StoreKit plumbing

    private func loadProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let fetched = try await Product.products(for: MihrabProduct.allCases.map(\.rawValue))
            var map: [String: Product] = [:]
            for product in fetched { map[product.id] = product }
            products = map
        } catch {
            // Offline, sandbox hiccup, or products not yet configured in ASC.
            // Keep whatever we already had; the paywall degrades to fallback pricing.
            lastError = nil
        }
    }

    private func verifyEntitlements() async {
        var owned: MihrabProduct?

        for await result in Transaction.currentEntitlements {
            guard let transaction = verifiedTransaction(result) else { continue }
            guard let item = MihrabProduct(rawValue: transaction.productID) else { continue }
            if transaction.revocationDate != nil { continue }
            if let expiry = transaction.expirationDate, expiry <= Date() { continue }
            // Lifetime wins over any subscription.
            if item == .lifetime { owned = .lifetime; break }
            owned = owned ?? item
        }

        activeProduct = owned
        hasPaidEntitlement = owned != nil
        defaults.set(hasPaidEntitlement, forKey: Key.cachedEntitlement)
        if hasPaidEntitlement { TrialReminder.cancelTrialReminders() }
    }

    private func startTransactionListener() {
        updatesTask = Task.detached { [weak self] in
            for await update in Transaction.updates {
                guard case .verified(let transaction) = update else { continue }
                await transaction.finish()
                await self?.verifyEntitlements()
            }
        }
    }

    private func verifiedTransaction(_ result: VerificationResult<StoreKit.Transaction>) -> StoreKit.Transaction? {
        switch result {
        case .verified(let transaction): transaction
        case .unverified: nil
        }
    }

    // MARK: - Formatting

    private func format(_ amount: Decimal, like product: Product) -> String {
        amount.formatted(product.priceFormatStyle)
    }

    private static func plainString(_ value: Decimal, fractionDigits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    private static func describe(_ error: StoreKitError) -> String {
        switch error {
        case .userCancelled: L10n.paywallCancelled
        case .networkError: L10n.paywallNetworkError
        case .systemError, .unknown: L10n.paywallGenericError
        case .notAvailableInStorefront: L10n.paywallStoreUnavailable
        case .notEntitled: L10n.paywallGenericError
        @unknown default: L10n.paywallGenericError
        }
    }
}

// MARK: - Convenience gate

extension View {
    /// Dims + disables a view for non-members, without hiding it — people should
    /// see what the Plus layer offers before deciding.
    func premiumGated(_ feature: PremiumFeature, isPremium: Bool) -> some View {
        opacity(isPremium ? 1 : 0.55)
            .disabled(!isPremium)
            .accessibilityHint(isPremium ? "" : L10n.premiumLockedHint)
    }
}
