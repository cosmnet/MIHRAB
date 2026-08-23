import Foundation

/// Identity of a cached set of days. If any field changes, every stored day is
/// stale — a Diyanet İstanbul table says nothing about Hanafi Berlin.
public struct PrayerCacheSignature: Codable, Sendable, Equatable {
    /// Rounded to 2 decimals (~1.1 km): walking around town must not throw the
    /// whole month away, moving cities must.
    public let latitude: Double
    public let longitude: Double
    /// `PrayerEngineConfiguration.fingerprint` — method, madhab, source,
    /// user offsets, time zone.
    public let configurationFingerprint: String

    public init(latitude: Double, longitude: Double, configurationFingerprint: String) {
        self.latitude = (latitude * 100).rounded() / 100
        self.longitude = (longitude * 100).rounded() / 100
        self.configurationFingerprint = configurationFingerprint
    }
}

/// On-disk envelope. `version` exists so a future schema change can discard
/// old files instead of decoding garbage.
public struct PrayerCacheFile: Codable, Sendable {
    public static let currentVersion = 1

    public var version: Int
    public var updatedAt: Date
    public var signature: PrayerCacheSignature
    /// Ascending by date.
    public var records: [ResolvedPrayerDay]

    public init(version: Int = PrayerCacheFile.currentVersion,
                updatedAt: Date = Date(),
                signature: PrayerCacheSignature,
                records: [ResolvedPrayerDay]) {
        self.version = version
        self.updatedAt = updatedAt
        self.signature = signature
        self.records = records
    }
}

/// Durable prayer-time cache in the App Group container.
///
/// The old repository kept a `[String: DayPrayerTimes]` dictionary in memory,
/// which evaporated on every cold launch — first launch in airplane mode meant
/// no prayer times at all. This survives relaunch, reboot, and app updates.
public final class PrayerCacheStore: @unchecked Sendable {
    public static let shared = PrayerCacheStore()

    /// Days kept behind today (history for "did I pray?" style views).
    public static let retainedPastDays = 30
    /// Minimum forward coverage the store guarantees when asked to top up.
    public static let minimumForwardDays = 60

    private let fileURL: URL?
    private let lock = NSLock()
    private var memo: PrayerCacheFile?

    public init(directory: URL? = nil, fileName: String = "prayer_cache_v1.json") {
        let container = directory
            ?? FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedPrayerCache.appGroupID)
        fileURL = container?.appendingPathComponent(fileName)
    }

    // MARK: - Reading

    public func load() -> PrayerCacheFile? {
        lock.lock()
        defer { lock.unlock() }
        if let memo { return memo }
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        do {
            let file = try JSONDecoder.prayerDecoder.decode(PrayerCacheFile.self, from: data)
            guard file.version == PrayerCacheFile.currentVersion else {
                // Schema moved on. Discard rather than reinterpret.
                removeFileLocked()
                return nil
            }
            memo = file
            return file
        } catch {
            // A truncated or corrupted file is worse than no file: reset safely.
            removeFileLocked()
            return nil
        }
    }

    /// Records valid for `signature`, ascending. Empty when the signature moved
    /// (different city, method, madhab, source, offsets or time zone).
    public func records(matching signature: PrayerCacheSignature) -> [ResolvedPrayerDay] {
        guard let file = load(), file.signature == signature else { return [] }
        return file.records
    }

    public func record(for date: Date,
                       signature: PrayerCacheSignature,
                       calendar: Calendar = .current) -> ResolvedPrayerDay? {
        records(matching: signature).first { calendar.isDate($0.day.date, inSameDayAs: date) }
    }

    /// `true` when the cache already covers `date ... date + days` for this
    /// signature. The network check hangs off this: no coverage gap, no request.
    public func covers(from date: Date,
                       days: Int,
                       signature: PrayerCacheSignature,
                       calendar: Calendar = .current) -> Bool {
        let stored = records(matching: signature)
        guard !stored.isEmpty else { return false }
        let start = calendar.startOfDay(for: date)
        for offset in 0...max(0, days) {
            guard let target = calendar.date(byAdding: .day, value: offset, to: start),
                  stored.contains(where: { calendar.isDate($0.day.date, inSameDayAs: target) })
            else { return false }
        }
        return true
    }

    public var lastUpdated: Date? { load()?.updatedAt }

    // MARK: - Writing

    /// Merges `records` into the store. Same-day entries are replaced, so a
    /// later network answer overwrites the earlier on-device estimate.
    /// A signature change wipes the file first.
    @discardableResult
    public func merge(_ incoming: [ResolvedPrayerDay],
                      signature: PrayerCacheSignature,
                      now: Date = Date(),
                      calendar: Calendar = .current) -> PrayerCacheFile? {
        guard !incoming.isEmpty else { return load() }

        lock.lock()
        defer { lock.unlock() }

        var existing: [ResolvedPrayerDay] = []
        if let current = memo ?? decodeLocked(), current.signature == signature {
            existing = current.records
        }

        var byDay: [Date: ResolvedPrayerDay] = [:]
        for record in existing {
            byDay[calendar.startOfDay(for: record.day.date)] = record
        }
        for record in incoming {
            byDay[calendar.startOfDay(for: record.day.date)] = record
        }

        let cutoff = calendar.date(byAdding: .day, value: -Self.retainedPastDays,
                                   to: calendar.startOfDay(for: now)) ?? .distantPast
        let pruned = byDay.values
            .filter { $0.day.date >= cutoff }
            .sorted { $0.day.date < $1.day.date }

        let file = PrayerCacheFile(updatedAt: now, signature: signature, records: pruned)
        writeLocked(file)
        return file
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        removeFileLocked()
    }

    // MARK: - Private

    private func decodeLocked() -> PrayerCacheFile? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        guard let file = try? JSONDecoder.prayerDecoder.decode(PrayerCacheFile.self, from: data),
              file.version == PrayerCacheFile.currentVersion else {
            removeFileLocked()
            return nil
        }
        return file
    }

    private func writeLocked(_ file: PrayerCacheFile) {
        memo = file
        guard let fileURL, let data = try? JSONEncoder.prayerEncoder.encode(file) else { return }
        do {
            // Atomic: a background task killed mid-write must never leave a
            // half-file where the prayer times used to be.
            try data.write(to: fileURL, options: [.atomic])
            // Background refresh can fire while the device is locked.
            try? FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: fileURL.path
            )
        } catch {
            // Nothing sensible to do — the in-memory copy still serves this run.
        }
    }

    private func removeFileLocked() {
        memo = nil
        guard let fileURL else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }
}
