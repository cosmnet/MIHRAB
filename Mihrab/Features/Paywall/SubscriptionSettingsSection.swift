import StoreKit
import SwiftUI

/// Drop-in `Section` for the Settings `Form`. Shows the honest current state,
/// a route to the paywall, and the two links Apple requires (manage + restore).
struct SubscriptionSettingsSection: View {
    init() {}

    @State private var subscriptions = SubscriptionManager.shared
    @State private var showPaywall = false
    @State private var showManageSubscriptions = false
    @State private var isRestoring = false
    @State private var restoreMessage: String?

    var body: some View {
        Section(L10n.subsSectionTitle) {
            statusRow

            if subscriptions.hasPaidEntitlement {
                Text(L10n.subsThanks)
                    .font(.footnote)
                    .foregroundStyle(MihrabColor.textSecondary)
            } else {
                Button(upgradeTitle) {
                    HapticsEngine.shared.light()
                    showPaywall = true
                }
            }

            Button(L10n.subsManage) {
                showManageSubscriptions = true
            }

            Button {
                Task {
                    isRestoring = true
                    restoreMessage = nil
                    await subscriptions.restore()
                    isRestoring = false
                    if subscriptions.hasPaidEntitlement {
                        HapticsEngine.shared.success()
                    } else {
                        restoreMessage = subscriptions.lastError ?? L10n.paywallRestoreNothing
                    }
                }
            } label: {
                HStack {
                    Text(L10n.subsRestore)
                    if isRestoring {
                        Spacer()
                        ProgressView().controlSize(.small)
                    }
                }
            }
            .disabled(isRestoring)

            if let restoreMessage {
                Text(restoreMessage)
                    .font(.caption)
                    .foregroundStyle(MihrabColor.textSecondary)
            }
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }

    private var upgradeTitle: String {
        subscriptions.hasStartedTrial ? L10n.subsUpgrade : L10n.subsStartTrial
    }

    private var statusRow: some View {
        HStack {
            Text(L10n.subsStatusLabel)
            Spacer()
            HStack(spacing: 6) {
                if subscriptions.isPremium {
                    Image(systemName: "seal.fill")
                        .font(.caption2)
                        .foregroundStyle(MihrabColor.brass)
                }
                Text(statusText)
                    .foregroundStyle(
                        subscriptions.isPremium ? MihrabColor.mint : MihrabColor.textSecondary
                    )
            }
        }
        .accessibilityElement(children: .combine)
        // Presentation lives on a concrete row: `.sheet` attached to a `Section`
        // is dropped by `Form`, so the paywall never appeared.
        .sheet(isPresented: $showPaywall) {
            PaywallView(source: .settings)
        }
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
        .task { await subscriptions.refresh() }
    }

    private var statusText: String {
        if subscriptions.hasPaidEntitlement { return L10n.subsStatusMember }
        if subscriptions.isInTrial { return L10n.subsStatusTrial(subscriptions.trialDaysRemaining) }
        if subscriptions.trialHasExpired { return L10n.subsStatusTrialEnded }
        return L10n.subsStatusFree
    }
}

/// Small brass lock shown beside a premium-only control.
struct PremiumLockBadge: View {
    let compact: Bool

    init(compact: Bool = false) {
        self.compact = compact
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.system(size: compact ? 8 : 10, weight: .bold))
            if !compact {
                Text(L10n.premiumLockBadgeLabel)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.5)
            }
        }
        .foregroundStyle(MihrabColor.abyss)
        .padding(.horizontal, compact ? 5 : 8)
        .padding(.vertical, compact ? 4 : 3)
        .background {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [MihrabColor.ramadanGold, MihrabColor.brass],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .accessibilityLabel(L10n.premiumLockBadgeLabel)
        .accessibilityHint(L10n.premiumLockedHint)
    }
}
