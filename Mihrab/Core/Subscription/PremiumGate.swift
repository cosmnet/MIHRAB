import SwiftUI

// Split out of PremiumEntitlement.swift: these helpers reference app-only
// types (SubscriptionManager, PaywallView), so the widget extension —
// which needs only the App Group mirror — cannot compile them.

// MARK: - Gate helpers for other agents

/// The two things a premium surface ever needs: "may I?" and "show me the
/// paywall". Other agents should use these rather than reading `isPremium`
/// directly, so `PremiumFeature.enforcement` stays truthful.
@MainActor
enum PremiumGate {
    static func check(_ feature: PremiumFeature) -> Bool {
        SubscriptionManager.shared.hasAccess(to: feature)
    }

    static func isLocked(_ feature: PremiumFeature) -> Bool {
        SubscriptionManager.shared.requiresUpgrade(feature)
    }
}

extension View {
    /// Wraps a premium control: taps go to the paywall while locked, a brass
    /// badge sits in the corner, and the content stays *visible* so people can
    /// see what Plus offers before deciding.
    ///
    /// Usage (one line, at the entry point of the feature):
    /// ```swift
    /// arButton.premiumRequired(.qiblaAR)
    /// ```
    func premiumRequired(_ feature: PremiumFeature, showsBadge: Bool = true) -> some View {
        modifier(PremiumRequiredModifier(feature: feature, showsBadge: showsBadge))
    }
}

private struct PremiumRequiredModifier: ViewModifier {
    let feature: PremiumFeature
    let showsBadge: Bool

    @State private var subscriptions = SubscriptionManager.shared
    @State private var showPaywall = false

    private var locked: Bool { subscriptions.requiresUpgrade(feature) }

    func body(content: Content) -> some View {
        content
            .opacity(locked ? 0.55 : 1)
            .allowsHitTesting(!locked)
            .overlay(alignment: .topTrailing) {
                if locked && showsBadge {
                    PremiumLockBadge(compact: true)
                        .padding(6)
                        .allowsHitTesting(false)
                }
            }
            .overlay {
                if locked {
                    // A transparent tap target on top, so the lock is a route
                    // to the paywall rather than a dead end.
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            HapticsEngine.shared.warning()
                            showPaywall = true
                        }
                        .accessibilityLabel(feature.localizedTitle)
                        .accessibilityHint(L10n.premiumLockedHint)
                        .accessibilityAddTraits(.isButton)
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView(source: .feature) }
    }
}
