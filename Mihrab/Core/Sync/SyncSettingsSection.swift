import SwiftUI

/// Drop-in `Section` for the Settings `Form`. The main session embeds this.
struct SyncSettingsSection: View {
    init() {}

    @State private var sync = CloudSyncManager.shared
    @State private var subscriptions = SubscriptionManager.shared
    @State private var showPaywall = false
    @State private var isSyncing = false
    @State private var enabled = CloudSyncPreference.isEnabled

    var body: some View {
        Section {
            Toggle(isOn: toggleBinding) {
                HStack(spacing: 8) {
                    Text(L10n.syncToggleTitle)
                    if !subscriptions.hasAccess(to: .iCloudBackup) {
                        PremiumLockBadge(compact: true)
                    }
                }
            }
            .frame(minHeight: MihrabSpace.hit)
            .sheet(isPresented: $showPaywall) { PaywallView(source: .feature) }

            statusRow

            if let last = sync.lastSyncedAt {
                HStack {
                    Text(L10n.syncLastSynced)
                    Spacer()
                    Text(last.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened).locale(L10n.appLocale)))
                        .foregroundStyle(MihrabColor.textSecondary)
                }
                .frame(minHeight: MihrabSpace.hit)
                .accessibilityElement(children: .combine)
            }

            if enabled {
                Button {
                    Task {
                        isSyncing = true
                        await sync.syncNow()
                        isSyncing = false
                        HapticsEngine.shared.light()
                    }
                } label: {
                    HStack {
                        Text(L10n.syncNow)
                        if isSyncing {
                            Spacer()
                            ProgressView().controlSize(.small)
                        }
                    }
                    .frame(minHeight: MihrabSpace.hit)
                }
                .disabled(isSyncing || !subscriptions.hasAccess(to: .iCloudBackup))
            }
        } header: {
            Text(L10n.syncSectionTitle)
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                Text(footerText)
                if sync.needsRelaunch {
                    Text(L10n.syncRelaunchNote)
                        .foregroundStyle(MihrabColor.brass)
                }
            }
            .font(.caption)
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
        .task {
            sync.reconcileEntitlement()
            await sync.refresh()
        }
    }

    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { enabled },
            set: { newValue in
                guard newValue else {
                    enabled = false
                    sync.isEnabled = false
                    return
                }
                guard subscriptions.hasAccess(to: .iCloudBackup) else {
                    HapticsEngine.shared.warning()
                    showPaywall = true
                    return
                }
                enabled = true
                sync.isEnabled = true
            }
        )
    }

    private var statusRow: some View {
        HStack {
            Text(L10n.syncStatusLabel)
            Spacer()
            HStack(spacing: 6) {
                if sync.isChecking { ProgressView().controlSize(.mini) }
                Text(sync.statusText)
                    .foregroundStyle(sync.state.isHealthy ? MihrabColor.mint : MihrabColor.textSecondary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .frame(minHeight: MihrabSpace.hit)
        .accessibilityElement(children: .combine)
    }

    /// Honest explanation of what is and is not synced, and what happens when
    /// Plus lapses.
    private var footerText: String {
        switch sync.state {
        case .noAccount: L10n.syncFooterNoAccount
        case .notEntitled: L10n.syncFooterNotEntitled
        default: L10n.syncFooterGeneral
        }
    }
}
