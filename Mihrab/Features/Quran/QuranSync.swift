import Foundation

/// iCloud carry-over for the reader and the hatim.
///
/// **Why this is not part of `KeyValueSync`.** `KeyValueSync.Snapshot` is a
/// fixed `Codable` struct in `Mihrab/Core/Sync/KeyValueSync.swift`, which this
/// agent does not own, and it has no field for Qur'an or hatim state. Rather
/// than edit someone else's file, this mirrors its contract exactly:
///
/// - one `NSUbiquitousKeyValueStore` key holding one JSON blob (the store is
///   capped at 1 MB total / 1024 keys, so per-item keys are not an option);
/// - gated on `CloudSyncPreference.isEnabled && .isEntitled`, so a lapsed
///   subscription stops *updating* the cloud copy and never erases it;
/// - union-additive merge — nothing a user recorded on either device is
///   removed by a sync.
///
/// **Follow-up for the owner (one line, no behaviour change):** if
/// `KeyValueSync.Snapshot` later gains `quran` and `hatim` fields, delete this
/// file and route through the shared blob. Until then two keys is correct and
/// still well inside the store's budget — the combined payload is a few KB.
enum QuranSync {

    static let ubiquitousKey = "mihrab.quran.snapshot.v1"
    private static let localStampKey = "mihrab.quran.localStamp"

    private struct Envelope: Codable, Sendable {
        var createdAt: Date
        var quran: QuranBookmarkStore.Snapshot?
        var hatim: HatimStore.Snapshot?
    }

    private static var local: UserDefaults { .standard }
    private static var cloud: NSUbiquitousKeyValueStore { .default }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: Push

    /// Coalesced: the stores call this on every edit, and a burst of taps must
    /// not become a burst of iCloud writes.
    @MainActor private static var pendingPush: Task<Void, Never>?

    @MainActor
    static func push(debounce: Duration = .seconds(2)) {
        guard CloudSyncPreference.isEnabled, CloudSyncPreference.isEntitled else { return }
        pendingPush?.cancel()
        pendingPush = Task {
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
            pushNow()
        }
    }

    @MainActor
    @discardableResult
    static func pushNow() -> Bool {
        guard CloudSyncPreference.isEnabled, CloudSyncPreference.isEntitled else { return false }
        let envelope = Envelope(
            createdAt: Date(),
            quran: QuranBookmarkStore.shared.exportSnapshot(),
            hatim: HatimStore.shared.exportSnapshot()
        )
        guard let data = try? encoder.encode(envelope), data.count < 900_000 else { return false }
        cloud.set(data, forKey: ubiquitousKey)
        local.set(Date(), forKey: localStampKey)
        return cloud.synchronize()
    }

    // MARK: Pull

    @MainActor
    @discardableResult
    static func pull() -> Bool {
        guard CloudSyncPreference.isEnabled, CloudSyncPreference.isEntitled else { return false }
        cloud.synchronize()
        guard let data = cloud.data(forKey: ubiquitousKey),
              let envelope = try? decoder.decode(Envelope.self, from: data)
        else { return false }
        if let quran = envelope.quran { QuranBookmarkStore.shared.merge(quran) }
        if let hatim = envelope.hatim { HatimStore.shared.merge(hatim) }
        return true
    }

    /// Mirrors `KeyValueSync.startObserving`. **Wiring note for the main
    /// session:** call once from `MihrabApp`, next to the existing
    /// `KeyValueSync.startObserving`, and keep the token alive.
    @MainActor
    static func startObserving(onChange: @escaping @MainActor () -> Void) -> NSObjectProtocol {
        cloud.synchronize()
        return NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                _ = pull()
                onChange()
            }
        }
    }
}
