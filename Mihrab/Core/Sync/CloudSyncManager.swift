import CloudKit
import Foundation
import SwiftUI

// MARK: - State

enum CloudSyncState: Equatable, Sendable {
    /// The user has not turned sync on.
    case off
    /// On, entitled, account available — SwiftData is mirroring in the background.
    case active
    /// On, but Plus has lapsed. Data is intact; mirroring is paused.
    case notEntitled
    /// No iCloud account signed in on the device.
    case noAccount
    /// Parental controls / MDM.
    case restricted
    /// Anything else CloudKit told us.
    case failed(String)
    /// We have not asked yet.
    case unknown

    var isHealthy: Bool { self == .active }
}

// MARK: - Manager

/// Honest status reporting for iCloud sync.
///
/// SwiftData's CloudKit mirroring is automatic and has no public "sync now"
/// API — so "Sync now" here does the two things that *are* real: it re-checks
/// the account status, and it pushes/pulls the `NSUbiquitousKeyValueStore`
/// backup layer (`KeyValueSync`). We say exactly that in the UI rather than
/// showing a fake spinner.
@MainActor
@Observable
final class CloudSyncManager {
    static let shared = CloudSyncManager()

    private(set) var state: CloudSyncState = .unknown
    private(set) var lastSyncedAt: Date? = CloudSyncPreference.lastSyncedAt
    private(set) var isChecking = false

    /// The user-facing switch. Flipping it stores the preference; the container
    /// itself is rebuilt at next launch (SwiftData resolves its configuration
    /// once, at `Persistence.container` initialisation).
    var isEnabled: Bool {
        get { CloudSyncPreference.isEnabled }
        set {
            CloudSyncPreference.isEnabled = newValue
            Task { await refresh() }
        }
    }

    /// True when the stored preference and the live container disagree — i.e.
    /// the user just flipped the switch and a relaunch is pending.
    var needsRelaunch: Bool {
        let wants = CloudSyncPreference.isEnabled && CloudSyncPreference.isEntitled
        return wants != Persistence.isUsingCloudKit
    }

    var isUsingCloudKitNow: Bool { Persistence.isUsingCloudKit }

    private init() {}

    // MARK: Status

    func refresh() async {
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }

        guard CloudSyncPreference.isEnabled else {
            state = .off
            return
        }
        guard SubscriptionManager.shared.hasAccess(to: .iCloudBackup) else {
            state = .notEntitled
            return
        }
        state = await accountState()
    }

    private func accountState() async -> CloudSyncState {
        let container = CKContainer(identifier: Persistence.cloudKitContainerID)
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available: return .active
            case .noAccount: return .noAccount
            case .restricted: return .restricted
            case .couldNotDetermine: return .failed(L10n.syncErrorUnknown)
            case .temporarilyUnavailable: return .failed(L10n.syncErrorTemporary)
            @unknown default: return .failed(L10n.syncErrorUnknown)
            }
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    // MARK: Manual sync

    /// Re-checks the account and flushes the key-value backup layer.
    @discardableResult
    func syncNow() async -> CloudSyncState {
        await refresh()
        guard state == .active else { return state }
        KeyValueSync.push()
        KeyValueSync.pull(strategy: .newerWins)
        let now = Date()
        lastSyncedAt = now
        CloudSyncPreference.lastSyncedAt = now
        return state
    }

    /// Call once at launch (after `SubscriptionManager.refresh()`), so a lapsed
    /// subscription is reflected without the user opening Settings.
    func reconcileEntitlement() {
        CloudSyncPreference.defaults.set(
            SubscriptionManager.shared.isPremium,
            forKey: CloudSyncPreference.entitlementKey
        )
        Task { await refresh() }
    }

    // MARK: Copy

    var statusText: String {
        switch state {
        case .off: L10n.syncStatusOff
        case .active: L10n.syncStatusActive
        case .notEntitled: L10n.syncStatusNotEntitled
        case .noAccount: L10n.syncStatusNoAccount
        case .restricted: L10n.syncStatusRestricted
        case .failed(let message): message
        case .unknown: L10n.syncStatusChecking
        }
    }
}
