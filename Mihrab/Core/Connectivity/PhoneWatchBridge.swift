#if os(iOS)
import Foundation
import Observation
import WatchConnectivity
import WidgetKit

/// The iPhone half of the Mihrab ↔ Apple Watch link.
///
/// Two directions, two very different transports, chosen for the reason each
/// one exists:
///
/// * **Settings, phone → watch: `updateApplicationContext(_:)`.** There is only
///   ever one current answer to "what should the watch calculate with", so the
///   coalescing transport is right. Cheap, replaces the previous payload, and
///   the watch reads it on next launch even if it was asleep for the transfer.
/// * **Events, watch → phone: `transferUserInfo(_:)`.** Dhikr counts and prayer
///   marks are a *sequence*; losing the middle of it loses data. This is the
///   only queued, ordered, guaranteed-delivery transport.
/// * **Complication refresh: `transferCurrentComplicationUserInfo(_:)`.** iOS
///   side only, and rationed — roughly 50 a day. Every call is gated on
///   `isComplicationEnabled` and `remainingComplicationUserInfoTransfers`,
///   because once the budget is gone the call silently degrades to a normal
///   `transferUserInfo` and the complication stops updating promptly for the
///   rest of the day.
///
/// `sessionDidBecomeInactive(_:)` and `sessionDidDeactivate(_:)` are not
/// optional decoration: without re-activating in `sessionDidDeactivate`, the
/// session stays bound to the old watch and support for a second paired watch
/// is quietly lost.
@Observable
final class PhoneWatchBridge: NSObject, @unchecked Sendable {

    static let shared = PhoneWatchBridge()

    // MARK: Observable state (Settings can show this; nothing else depends on it)

    private(set) var isSupported = WCSession.isSupported()
    private(set) var isPaired = false
    private(set) var isWatchAppInstalled = false
    private(set) var isComplicationEnabled = false
    private(set) var remainingComplicationTransfers = 0
    private(set) var lastContextSentAt: Date?
    private(set) var lastEventReceivedAt: Date?
    private(set) var lastError: String?

    /// `true` once `activate()` has been called, so repeat calls are free.
    private var didActivate = false

    /// Fingerprint of the last context actually handed to WatchConnectivity.
    /// Re-sending an identical context is a no-op on the framework's side, but
    /// building the payload is not, and `syncSettings()` is called from several
    /// places on every settings change.
    private var lastSentFingerprint: String?

    private let lock = NSLock()

    private var session: WCSession? { WCSession.isSupported() ? .default : nil }

    private override init() { super.init() }

    // MARK: - Lifecycle

    /// Safe to call on every launch and every foreground.
    func activate() {
        guard let session else {
            isSupported = false
            return
        }
        guard !didActivate else {
            refreshState(session)
            return
        }
        didActivate = true
        session.delegate = self
        session.activate()
    }

    // MARK: - Phone → watch

    /// Publishes the current calculation settings.
    ///
    /// - Parameter force: send even when nothing changed. Used after the watch
    ///   app is installed or the pairing changes, where the framework's own
    ///   deduplication would otherwise hold back the first payload.
    func syncSettings(force: Bool = false) {
        guard let session, session.activationState == .activated else { return }
        guard session.isPaired, session.isWatchAppInstalled else { return }

        let payload = makePayload()

        lock.lock()
        let unchanged = !force && lastSentFingerprint == payload.calculationFingerprint
        lock.unlock()
        if unchanged { return }

        do {
            try session.updateApplicationContext(payload.contextDictionary())
            lock.lock()
            lastSentFingerprint = payload.calculationFingerprint
            lock.unlock()
            lastContextSentAt = Date()
            lastError = nil
        } catch {
            // A failed context is not a user-visible failure: the watch still
            // has the previous settings and still computes correct times with
            // them. Record it and move on.
            lastError = error.localizedDescription
        }
    }

    /// Asks the complication to redraw now, if and only if the budget allows.
    ///
    /// Call it when something the complication *shows* changed — the settings
    /// that move the times, or the city. Not on every prayer boundary: the
    /// watch computes its own timeline and already knows when the next one is.
    func nudgeComplication() {
        guard let session, session.activationState == .activated else { return }
        guard session.isPaired, session.isWatchAppInstalled else { return }
        guard session.isComplicationEnabled else { return }
        // Leave headroom rather than spending the last transfers: the budget is
        // per day and the remaining ones are worth more later than now.
        guard session.remainingComplicationUserInfoTransfers > 5 else {
            remainingComplicationTransfers = session.remainingComplicationUserInfoTransfers
            return
        }

        let payload = makePayload()
        guard var info = try? payload.contextDictionary() else { return }
        info[WatchBridge.Key.complicationNudge] = true
        session.transferCurrentComplicationUserInfo(info)
        remainingComplicationTransfers = session.remainingComplicationUserInfoTransfers
    }

    /// Everything the watch needs, read straight from the app's own singletons.
    private func makePayload() -> WatchSettingsPayload {
        let settings = AppSettings.shared
        let preferences = PrayerSourcePreferences.shared
        let coordinate = LocationManager.shared.effectiveCoordinate
        let today = Date()
        let logged = PrayerLogStore.shared.logged(on: today).map(\.rawValue).sorted()

        var offsets: [String: Int] = [:]
        for (prayer, minutes) in preferences.offsets where minutes != 0 {
            offsets[prayer.rawValue] = minutes
        }

        return WatchSettingsPayload(
            latitude: coordinate?.latitude,
            longitude: coordinate?.longitude,
            cityName: LocationManager.shared.effectiveCityName,
            methodID: settings.calculationMethod.rawValue,
            madhabID: settings.madhab.rawValue,
            sourceID: preferences.source.rawValue,
            offsetMinutes: offsets,
            timeZoneIdentifier: TimeZone.current.identifier,
            languageCode: L10n.language.rawValue,
            loggedTodayIDs: logged,
            loggedDayKey: WatchBridge.dayKey(for: today)
        )
    }

    // MARK: - Watch → phone

    private func apply(_ envelope: WatchBridgeEnvelope) {
        guard !SeenEnvelopes.insert(envelope.id) else { return }

        var dhikrTouched = false

        for event in envelope.events {
            switch event {
            case let .dhikrTicks(phraseID, amount):
                guard amount > 0 else { continue }
                // Goes through the same App Group tally the widget button and
                // Siri use, so the app folds watch taps into SwiftData on next
                // foreground via `MihrabIntentBridge.drainOutsideTaps()`.
                // No new persistence path, no double counting.
                _ = SharedDhikrCounter.add(amount, phraseID: phraseID)
                dhikrTouched = true

            case let .prayerLog(prayerID, dayKey, logged):
                guard let prayer = Prayer(rawValue: prayerID), prayer.isNotifiable,
                      let date = WatchBridge.date(fromDayKey: dayKey) else { continue }
                Task { @MainActor in
                    let store = PrayerLogStore.shared
                    // The event carries the resulting state, so a replay is a
                    // no-op instead of an unwanted toggle.
                    if store.isLogged(prayer, on: date) != logged {
                        store.toggle(prayer, on: date)
                    }
                }
            }
        }

        lastEventReceivedAt = Date()

        if dhikrTouched {
            SharedDhikrCounter.reloadWidgets()
        }
        Task { @MainActor in
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    // MARK: - State mirror

    private func refreshState(_ session: WCSession) {
        let paired = session.isPaired
        let installed = session.isWatchAppInstalled
        let complication = session.isComplicationEnabled
        let remaining = session.remainingComplicationUserInfoTransfers
        Task { @MainActor in
            self.isPaired = paired
            self.isWatchAppInstalled = installed
            self.isComplicationEnabled = complication
            self.remainingComplicationTransfers = remaining
        }
    }
}

// MARK: - WCSessionDelegate

extension PhoneWatchBridge: WCSessionDelegate {

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error { lastError = error.localizedDescription }
        refreshState(session)
        guard activationState == .activated else { return }
        // First payload after activation: force it, because the framework's
        // deduplication has no record of what this watch already holds.
        syncSettings(force: true)
    }

    /// Required on iOS. Called while the session switches to another watch.
    func sessionDidBecomeInactive(_ session: WCSession) {
        refreshState(session)
    }

    /// Required on iOS. **Must** re-activate, otherwise the session never binds
    /// to the newly-selected watch and multi-watch support is lost.
    func sessionDidDeactivate(_ session: WCSession) {
        lock.lock()
        lastSentFingerprint = nil
        lock.unlock()
        session.activate()
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        refreshState(session)
        // A freshly installed watch app has no context yet.
        syncSettings(force: true)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let envelope = WatchBridgeEnvelope.decode(from: userInfo) else { return }
        apply(envelope)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        // The watch does not push settings; nothing to do. Implemented so a
        // future watch→phone context is not silently dropped.
    }
}

// MARK: - Replay guard

/// A short ring of envelope ids already applied.
///
/// `transferUserInfo` is delivery-guaranteed and ordered, but a queue that
/// survives a phone-app reinstall can hand the same batch over twice. Dhikr
/// deltas are the only genuinely non-idempotent event, and re-adding 33 to the
/// day's tally is exactly the kind of quiet wrongness a tally must never have.
private enum SeenEnvelopes {
    private static let key = "mihrab.watch.seenEnvelopes"
    private static let capacity = 60
    private static let lock = NSLock()

    /// Returns `true` when the id had already been seen.
    static func insert(_ id: UUID) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let defaults = UserDefaults.standard
        var ids = defaults.stringArray(forKey: key) ?? []
        let value = id.uuidString
        if ids.contains(value) { return true }
        ids.append(value)
        if ids.count > capacity { ids.removeFirst(ids.count - capacity) }
        defaults.set(ids, forKey: key)
        return false
    }
}
#endif
