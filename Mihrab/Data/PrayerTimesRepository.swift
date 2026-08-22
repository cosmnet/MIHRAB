import CoreLocation
import Foundation

/// Resolves prayer times: fresh cache → network → stale cache (stale-while-error).
/// Publishes results to the App Group cache for widgets.
@Observable
final class PrayerTimesRepository: @unchecked Sendable {
    static let shared = PrayerTimesRepository()

    private let api: APIClient
    private var memoryCache: [String: DayPrayerTimes] = [:]

    private(set) var today: DayPrayerTimes?
    private(set) var tomorrow: DayPrayerTimes?
    private(set) var isLoading = false
    private(set) var lastError: Error?

    init(api: APIClient = AladhanClient()) {
        self.api = api
    }

    private func cacheKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian)
        let settings = AppSettings.shared
        let coordinate = LocationManager.shared.effectiveCoordinate
        let locationKey = coordinate.map { String(format: "%.2f,%.2f", $0.latitude, $0.longitude) } ?? "none"
        return "\(f.string(from: date))-\(settings.calculationMethod.rawValue)-\(settings.madhab.rawValue)-\(locationKey)"
    }

    /// Refresh today's and tomorrow's times for the effective location.
    @MainActor
    func refresh() async {
        let settings = AppSettings.shared
        guard let coordinate = LocationManager.shared.effectiveCoordinate else { return }
        isLoading = true
        defer { isLoading = false }

        let now = Date()
        let calendar = Calendar.current
        let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now

        do {
            async let todayTimes = day(for: now, coordinate: coordinate, settings: settings)
            async let tomorrowTimes = day(for: tomorrowDate, coordinate: coordinate, settings: settings)
            let (t, tm) = try await (todayTimes, tomorrowTimes)
            today = t
            tomorrow = tm
            lastError = nil
            await prefetchMonth(containing: now, coordinate: coordinate, settings: settings)
            publishSnapshot()
        } catch {
            lastError = error
            // Stale-while-error: fall back to whatever we have cached.
            if today == nil, let snapshot = SharedPrayerCache.load() {
                today = snapshot.day(containing: now)
                tomorrow = snapshot.day(containing: tomorrowDate)
            }
        }
    }

    func day(for date: Date) async -> DayPrayerTimes? {
        let settings = AppSettings.shared
        guard let coordinate = LocationManager.shared.effectiveCoordinate else { return nil }
        return try? await day(for: date, coordinate: coordinate, settings: settings)
    }

    func month(containing date: Date) async -> [DayPrayerTimes] {
        let settings = AppSettings.shared
        guard let coordinate = LocationManager.shared.effectiveCoordinate else { return [] }
        let comps = Calendar.current.dateComponents([.year, .month], from: date)
        return (try? await api.calendar(
            year: comps.year ?? 2026, month: comps.month ?? 1,
            latitude: coordinate.latitude, longitude: coordinate.longitude,
            method: settings.calculationMethod, madhab: settings.madhab
        )) ?? []
    }

    private func day(for date: Date, coordinate: CLLocationCoordinate2D,
                     settings: AppSettings) async throws -> DayPrayerTimes {
        let key = cacheKey(for: date)
        if let cached = memoryCache[key],
           Calendar.current.isDate(cached.date, inSameDayAs: date) {
            return cached
        }
        let fetched = try await api.timings(
            date: date, latitude: coordinate.latitude, longitude: coordinate.longitude,
            method: settings.calculationMethod, madhab: settings.madhab
        )
        memoryCache[key] = fetched
        return fetched
    }

    private func prefetchMonth(containing date: Date, coordinate: CLLocationCoordinate2D,
                               settings: AppSettings) async {
        let comps = Calendar.current.dateComponents([.year, .month], from: date)
        if let days = try? await api.calendar(
            year: comps.year ?? 2026, month: comps.month ?? 1,
            latitude: coordinate.latitude, longitude: coordinate.longitude,
            method: settings.calculationMethod, madhab: settings.madhab
        ) {
            for day in days { memoryCache[cacheKey(for: day.date)] = day }
        }
    }

    private func publishSnapshot() {
        let coordinate = LocationManager.shared.effectiveCoordinate
        let days = memoryCache.values.sorted { $0.date < $1.date }
        guard !days.isEmpty else { return }
        let snapshot = SharedPrayerSnapshot(
            latitude: coordinate?.latitude ?? 0,
            longitude: coordinate?.longitude ?? 0,
            cityName: LocationManager.shared.effectiveCityName,
            methodID: AppSettings.shared.calculationMethod.rawValue,
            days: days
        )
        SharedPrayerCache.save(snapshot)
    }
}
