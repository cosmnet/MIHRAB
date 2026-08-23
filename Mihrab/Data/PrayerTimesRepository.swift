import CoreLocation
import Foundation
import WidgetKit

/// Single source of truth for prayer times.
///
/// Resolution order — the app must **never** be without times:
///   1. **Persistent cache** (App Group, survives relaunch) — instant.
///   2. **On-device engine** (adhan-swift) — instant, works in airplane mode,
///      at 10 000 m, and during an API outage. This is what makes the core
///      feature unconditional.
///   3. **Network** (Aladhan) — optional polish. When it answers, its more
///      "official" values overwrite the computed ones and are written to disk.
///
/// Step 2 always runs, so a network failure downgrades precision, never
/// availability. `isUsingOfflineEngine` reports which of the two the user is
/// currently looking at.
@Observable
final class PrayerTimesRepository: @unchecked Sendable {
    static let shared = PrayerTimesRepository()

    private let api: APIClient
    private let cache: PrayerCacheStore

    private(set) var today: DayPrayerTimes?
    private(set) var tomorrow: DayPrayerTimes?
    private(set) var isLoading = false
    private(set) var lastError: Error?

    /// `true` when the displayed times were computed on this device rather than
    /// fetched. Not an error state — show it as a quiet caption, not a warning.
    private(set) var isUsingOfflineEngine = false

    /// Last time the network actually answered. `nil` = never (or cleared).
    private(set) var lastSuccessfulRefresh: Date?

    /// `true` when the engine cannot produce a schedule for this location
    /// (polar day / polar night). The honest empty state, not a crash.
    private(set) var engineUnavailable = false

    /// Provenance for the transparency panel (Agent W5's UI).
    private(set) var todayResolution: PrayerResolution?

    /// Days currently resolved, keyed by start-of-day. Backed by disk.
    private var resolvedDays: [Date: ResolvedPrayerDay] = [:]
    private var activeSignature: PrayerCacheSignature?

    /// How far ahead the on-device engine fills. Comfortably over the 60-day
    /// retention floor and enough for the month grid plus notifications.
    private static let engineHorizonDays = 75
    /// Don't hit the network more often than this when nothing changed.
    private static let networkCooldown: TimeInterval = 6 * 60 * 60
    /// Forward coverage that must exist before we consider skipping the network.
    private static let requiredCoverageDays = 7

    private enum DefaultsKey {
        static let lastNetworkRefresh = "prayer.lastNetworkRefresh"
    }

    init(api: APIClient = AladhanClient(), cache: PrayerCacheStore = .shared) {
        self.api = api
        self.cache = cache
        lastSuccessfulRefresh = UserDefaults.standard
            .object(forKey: DefaultsKey.lastNetworkRefresh) as? Date
    }

    // MARK: - Configuration

    private var currentConfiguration: PrayerEngineConfiguration {
        .current()
    }

    private func makeSignature(for coordinate: CLLocationCoordinate2D,
                               configuration: PrayerEngineConfiguration) -> PrayerCacheSignature {
        PrayerCacheSignature(latitude: coordinate.latitude,
                             longitude: coordinate.longitude,
                             configurationFingerprint: configuration.fingerprint)
    }

    // MARK: - Refresh

    /// Refresh today's and tomorrow's times for the effective location.
    @MainActor
    func refresh() async {
        guard let coordinate = LocationManager.shared.effectiveCoordinate else { return }
        let configuration = currentConfiguration
        let signature = makeSignature(for: coordinate, configuration: configuration)
        isLoading = true
        defer { isLoading = false }

        let now = Date()
        let calendar = PrayerEngine.calendar(for: configuration)

        // A different city / method / madhab / source / offset set means every
        // stored day is meaningless. Drop them before they can be displayed.
        if activeSignature != signature {
            resolvedDays.removeAll()
            activeSignature = signature
        }

        // 1 — Persistent cache. Instant, and correct across cold launches.
        let cached = cache.records(matching: signature)
        if !cached.isEmpty {
            for record in cached {
                var replayed = record
                replayed.resolution.origin = record.resolution.origin == .network ? .network : .cache
                resolvedDays[calendar.startOfDay(for: record.day.date)] = replayed
            }
            publishCurrent(now: now, calendar: calendar)
        }

        // 2 — On-device engine. Runs unconditionally, so from here on the app
        //     has times no matter what the network does.
        let computed = PrayerEngine.resolvedWindow(from: now,
                                                   startingOffset: -1,
                                                   dayCount: Self.engineHorizonDays,
                                                   coordinate: coordinate,
                                                   configuration: configuration)
        if computed.isEmpty {
            // Polar latitude: adhan-swift cannot anchor to a sunrise/sunset.
            engineUnavailable = resolvedDays.isEmpty
        } else {
            engineUnavailable = false
            for record in computed {
                let key = calendar.startOfDay(for: record.day.date)
                // Never downgrade a real network answer to a computed estimate.
                if resolvedDays[key]?.resolution.origin == .network { continue }
                resolvedDays[key] = record
            }
            cache.merge(computed, signature: signature, now: now, calendar: calendar)
            publishCurrent(now: now, calendar: calendar)
        }

        // 3 — Network, only when it can actually add something.
        guard shouldFetchNetwork(signature: signature, configuration: configuration,
                                 now: now, calendar: calendar) else {
            lastError = nil
            publishSnapshot(coordinate: coordinate, configuration: configuration)
            return
        }

        do {
            let comps = calendar.dateComponents([.year, .month], from: now)
            var fetched = try await api.calendar(
                year: comps.year ?? calendar.component(.year, from: now),
                month: comps.month ?? calendar.component(.month, from: now),
                latitude: coordinate.latitude, longitude: coordinate.longitude,
                method: configuration.method, madhab: configuration.madhab
            )
            // Next month too, so a refresh late in the month still covers the
            // notification window.
            if let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: now) {
                let next = calendar.dateComponents([.year, .month], from: nextMonthDate)
                if let days = try? await api.calendar(
                    year: next.year ?? 0, month: next.month ?? 1,
                    latitude: coordinate.latitude, longitude: coordinate.longitude,
                    method: configuration.method, madhab: configuration.madhab
                ) { fetched.append(contentsOf: days) }
            }

            let records = fetched.map { day in
                ResolvedPrayerDay(day: applyingOffsets(to: day, configuration: configuration),
                                  resolution: networkResolution(for: configuration))
            }
            for record in records {
                resolvedDays[calendar.startOfDay(for: record.day.date)] = record
            }
            cache.merge(records, signature: signature, now: now, calendar: calendar)
            lastError = nil
            lastSuccessfulRefresh = now
            UserDefaults.standard.set(now, forKey: DefaultsKey.lastNetworkRefresh)
            publishCurrent(now: now, calendar: calendar)
        } catch {
            // Not fatal any more: step 2 already filled the screen.
            lastError = resolvedDays.isEmpty ? error : nil
        }

        publishSnapshot(coordinate: coordinate, configuration: configuration)
    }

    /// Cheap entry point for `.task` / scene activation: skips the whole dance
    /// when nothing has changed and the cache still covers the near future.
    @MainActor
    func refreshIfNeeded() async {
        guard let coordinate = LocationManager.shared.effectiveCoordinate else { return }
        let configuration = currentConfiguration
        let signature = makeSignature(for: coordinate, configuration: configuration)
        let calendar = PrayerEngine.calendar(for: configuration)
        if today != nil,
           activeSignature == signature,
           cache.covers(from: Date(), days: Self.requiredCoverageDays,
                        signature: signature, calendar: calendar) {
            return
        }
        await refresh()
    }

    /// Only go to the network when it can change the answer: the configuration
    /// moved, coverage is missing, or the cooldown expired. Previously every
    /// location update fired a full month request.
    private func shouldFetchNetwork(signature: PrayerCacheSignature,
                                    configuration: PrayerEngineConfiguration,
                                    now: Date,
                                    calendar: Calendar) -> Bool {
        // Aladhan has no parameter for the Fazilet / Türkiye Takvimi imsak
        // angle. Fetching would silently replace the user's chosen tradition
        // with Diyanet's numbers, so those sources stay on-device only.
        switch configuration.source {
        case .fazilet, .turkiyeTakvimi: return false
        case .diyanet, .standard: break
        }
        if activeSignature != signature { return true }
        if !cache.covers(from: now, days: Self.requiredCoverageDays,
                         signature: signature, calendar: calendar) { return true }
        guard let last = lastSuccessfulRefresh else { return true }
        return now.timeIntervalSince(last) > Self.networkCooldown
    }

    // MARK: - Queries

    func day(for date: Date) async -> DayPrayerTimes? {
        resolvedDay(for: date)?.day
    }

    /// Provenance for a given day — the data behind W5's transparency panel.
    func resolution(for date: Date) -> PrayerResolution? {
        resolvedDay(for: date)?.resolution
    }

    /// `resolutionSummary(for:)` convenience: full provenance text for one
    /// prayer on one day.
    func resolutionSummary(for prayer: Prayer, on date: Date = Date()) -> String? {
        resolution(for: date)?.resolutionSummary(for: prayer)
    }

    func resolvedDay(for date: Date) -> ResolvedPrayerDay? {
        let configuration = currentConfiguration
        let calendar = PrayerEngine.calendar(for: configuration)
        let key = calendar.startOfDay(for: date)
        if let hit = resolvedDays[key] { return hit }
        // Never answer "I don't know" while a coordinate exists: compute it.
        guard let coordinate = LocationManager.shared.effectiveCoordinate,
              let computed = PrayerEngine.resolved(for: date,
                                                   coordinate: coordinate,
                                                   configuration: configuration) else { return nil }
        resolvedDays[key] = computed
        return computed
    }

    func month(containing date: Date) async -> [DayPrayerTimes] {
        let configuration = currentConfiguration
        let calendar = PrayerEngine.calendar(for: configuration)
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return [] }
        let dayCount = calendar.range(of: .day, in: .month, for: date)?.count ?? 30

        var result: [DayPrayerTimes] = []
        for offset in 0..<dayCount {
            guard let target = calendar.date(byAdding: .day, value: offset, to: interval.start) else { continue }
            if let known = resolvedDays[calendar.startOfDay(for: target)] {
                result.append(known.day)
            } else if let coordinate = LocationManager.shared.effectiveCoordinate,
                      let computed = PrayerEngine.resolved(for: target,
                                                           coordinate: coordinate,
                                                           configuration: configuration) {
                resolvedDays[calendar.startOfDay(for: target)] = computed
                result.append(computed.day)
            }
        }
        return result
    }

    // MARK: - Publishing

    private func publishCurrent(now: Date, calendar: Calendar) {
        let todayKey = calendar.startOfDay(for: now)
        let tomorrowKey = calendar.date(byAdding: .day, value: 1, to: todayKey) ?? todayKey
        if let record = resolvedDays[todayKey] {
            today = record.day
            todayResolution = record.resolution
            isUsingOfflineEngine = record.resolution.origin != .network
        }
        tomorrow = resolvedDays[tomorrowKey]?.day
    }

    /// Push to the App Group so the widgets can render without networking.
    private func publishSnapshot(coordinate: CLLocationCoordinate2D,
                                 configuration: PrayerEngineConfiguration) {
        let days = resolvedDays.values
            .sorted { $0.day.date < $1.day.date }
            .map(\.day)
        guard !days.isEmpty else { return }
        let snapshot = SharedPrayerSnapshot(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            cityName: LocationManager.shared.effectiveCityName,
            methodID: configuration.method.rawValue,
            days: days,
            sourceID: configuration.source.rawValue,
            isOfflineComputed: isUsingOfflineEngine
        )
        SharedPrayerCache.save(snapshot)
        // Writing the App Group file is not enough — WidgetKit only re-reads on request.
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Helpers

    /// The user's ± corrections must apply to network days too, otherwise the
    /// same prayer moves when connectivity comes back.
    private func applyingOffsets(to day: DayPrayerTimes,
                                 configuration: PrayerEngineConfiguration) -> DayPrayerTimes {
        guard configuration.offsets.contains(where: { $0.value != 0 }) else { return day }
        var times = day.times
        for (prayer, minutes) in configuration.offsets where minutes != 0 {
            if let current = times[prayer] {
                times[prayer] = current.addingTimeInterval(TimeInterval(minutes * 60))
            }
        }
        return DayPrayerTimes(date: day.date, times: times,
                              hijriDate: day.hijriDate, cityName: day.cityName)
    }

    private func networkResolution(for configuration: PrayerEngineConfiguration) -> PrayerResolution {
        PrayerResolution(
            origin: .network,
            source: configuration.source,
            methodID: configuration.method.rawValue,
            madhabID: configuration.madhab.rawValue,
            adhanMethodID: configuration.effectiveAdhanMethod.rawValue,
            // Angles are the API authority's, not ours — do not claim numbers
            // the response never gave us.
            fajrAngle: nil,
            ishaAngle: nil,
            temkinMinutes: MethodTemkin.isTemkin(configuration.effectiveAdhanMethod)
                ? MethodTemkin.minutes(for: .turkey) : [:],
            temkinIsDiyanet: MethodTemkin.isTemkin(configuration.effectiveAdhanMethod),
            userOffsetMinutes: configuration.offsets.filter { $0.value != 0 },
            timeZoneIdentifier: configuration.timeZoneIdentifier,
            updatedAt: Date()
        )
    }
}
