import Foundation
import Observation
import WatchConnectivity
import WidgetKit

/// The watch half of the link.
///
/// Receives settings over `applicationContext` and pushes wrist-made events
/// back with `transferUserInfo`. Note what it does **not** do: it never blocks
/// the UI on reachability, and nothing on screen waits for the phone. If the
/// phone is out of range the watch still calculates, still counts, still logs —
/// the outbox simply drains later.
@Observable
final class WatchConnectivityClient: NSObject, @unchecked Sendable {

    static let shared = WatchConnectivityClient()

    /// Last settings received (or replayed from the watch's own storage on a
    /// cold launch with no phone in range).
    private(set) var settings: WatchSettingsPayload?
    private(set) var isReachable = false
    private(set) var hasEverReceivedSettings = false
    private(set) var pendingEventCount = 0

    /// Prayer-log changes made on the wrist that have not reached the phone.
    /// Kept in memory *and* mirrored in the shared container, so a flush that
    /// fails is retried rather than lost.
    private var pendingLogEvents: [WatchBridgeEvent] = []
    private let lock = NSLock()

    private var session: WCSession? { WCSession.isSupported() ? .default : nil }
    private var didActivate = false

    private override init() {
        super.init()
        settings = WatchSharedState.loadSettings()
        hasEverReceivedSettings = settings != nil
    }

    // MARK: - Lifecycle

    func activate() {
        guard let session else { return }
        guard !didActivate else {
            flush()
            return
        }
        didActivate = true
        session.delegate = self
        session.activate()
    }

    // MARK: - Outbound

    /// Queues a dhikr delta. The tally itself already lives in the watch's
    /// shared container, so this only concerns getting it to the phone.
    func enqueueDhikr() {
        flush()
    }

    func enqueuePrayerLog(_ prayer: Prayer, logged: Bool, on date: Date = Date()) {
        let event = WatchBridgeEvent.prayerLog(prayerID: prayer.rawValue,
                                               dayKey: WatchBridge.dayKey(for: date),
                                               logged: logged)
        lock.lock()
        // Same prayer, same day: keep only the latest state. The phone applies
        // absolute state, so an intermediate toggle carries no information.
        pendingLogEvents.removeAll {
            if case let .prayerLog(id, day, _) = $0,
               case let .prayerLog(newID, newDay, _) = event {
                return id == newID && day == newDay
            }
            return false
        }
        pendingLogEvents.append(event)
        lock.unlock()
        flush()
    }

    /// Hands everything queued to WatchConnectivity in one envelope.
    ///
    /// `transferUserInfo` is the only transport here that survives the phone
    /// being unreachable — it queues on disk and delivers when the pair meets
    /// again. `sendMessage` would simply fail, and the count would be gone.
    func flush() {
        guard let session, session.activationState == .activated else { return }

        let dhikr = WatchSharedState.drainDhikrOutbox()

        lock.lock()
        let logEvents = pendingLogEvents
        pendingLogEvents.removeAll()
        lock.unlock()

        var events: [WatchBridgeEvent] = []
        if dhikr > 0 {
            events.append(.dhikrTicks(phraseID: WatchSharedState.dhikrPhraseID, amount: dhikr))
        }
        events.append(contentsOf: logEvents)
        guard !events.isEmpty else {
            updatePendingCount()
            return
        }

        let envelope = WatchBridgeEnvelope(events: events)
        guard let userInfo = try? envelope.userInfo() else {
            // Encoding cannot realistically fail, but if it did, putting the
            // counts back is the difference between a delay and a loss.
            WatchSharedState.returnToDhikrOutbox(dhikr)
            lock.lock(); pendingLogEvents.append(contentsOf: logEvents); lock.unlock()
            updatePendingCount()
            return
        }
        session.transferUserInfo(userInfo)
        updatePendingCount()
    }

    private func updatePendingCount() {
        let queued = session?.outstandingUserInfoTransfers.count ?? 0
        Task { @MainActor in self.pendingEventCount = queued }
    }

    // MARK: - Inbound

    private func adopt(_ payload: WatchSettingsPayload, reloadComplications: Bool) {
        WatchSharedState.save(payload)
        WatchSharedState.mergePhoneLog(ids: payload.loggedTodayIDs, dayKey: payload.loggedDayKey)
        Task { @MainActor in
            self.settings = payload
            self.hasEverReceivedSettings = true
        }
        if reloadComplications {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityClient: WCSessionDelegate {

    /// The only method watchOS requires. `sessionDidBecomeInactive` and
    /// `sessionDidDeactivate` are iOS-only — a watch has exactly one phone.
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        guard activationState == .activated else { return }
        // The phone may have pushed a context while this app was not running.
        if let payload = WatchSettingsPayload.decode(from: session.receivedApplicationContext) {
            adopt(payload, reloadComplications: true)
        }
        // Read the Bool here: WCSession is not Sendable, so capturing the
        // session itself in the main-actor task is a cross-isolation send.
        let reachable = session.isReachable
        Task { @MainActor in self.isReachable = reachable }
        flush()
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let payload = WatchSettingsPayload.decode(from: applicationContext) else { return }
        adopt(payload, reloadComplications: true)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        // Arrives as `transferCurrentComplicationUserInfo` from the phone: same
        // settings shape, plus a marker asking for a prompt timeline reload.
        guard let payload = WatchSettingsPayload.decode(from: userInfo) else { return }
        adopt(payload, reloadComplications: true)
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in self.isReachable = reachable }
        if reachable { flush() }
    }

    func sessionCompanionAppInstalledDidChange(_ session: WCSession) {
        flush()
    }
}
