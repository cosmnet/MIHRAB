import CoreLocation
import Foundation
import SwiftUI

// MARK: - Model

/// A city the user keeps in their list. Persisted as JSON in the App Group so
/// the widgets extension can read the same list without touching the app.
///
/// The stored shape is deliberately tiny and additive-only: any new field must
/// be optional with a default, otherwise an older build's JSON stops decoding.
struct SavedCity: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double

    /// Human-readable region ("Türkiye", "Almanya"). Optional on purpose.
    var region: String?

    /// IANA zone for the city. Without it every saved city was rendered in the
    /// *device's* zone, so a city in another zone showed every prayer wrong by
    /// the offset between them — hours, not minutes.
    var timeZoneIdentifier: String?

    /// The city's own zone, or the device's when it was never resolved.
    var timeZone: TimeZone {
        timeZoneIdentifier.flatMap(TimeZone.init(identifier:)) ?? .current
    }

    init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double,
        region: String? = nil,
        timeZoneIdentifier: String? = nil
    ) {
        self.timeZoneIdentifier = timeZoneIdentifier
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.region = region
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// The reserved identity of the "current location" entry. It is never
    /// written to disk — it is synthesised from `LocationManager` each launch —
    /// but it is stable so `activeCityID` can point at it.
    static let currentLocationID = UUID(uuidString: "00000000-0000-0000-0000-00000C17FEED")!

    var isCurrentLocation: Bool { id == Self.currentLocationID }

    /// Two cities within ~1 km of each other are the same place for our purposes.
    func isNear(_ other: SavedCity) -> Bool {
        abs(latitude - other.latitude) < 0.01 && abs(longitude - other.longitude) < 0.01
    }
}

enum CityStoreError: LocalizedError, Equatable {
    /// The free tier holds one city — the one you are standing in.
    case limitReached(limit: Int)
    case duplicate(name: String)

    var errorDescription: String? {
        switch self {
        case .limitReached(let limit): L10n.citiesLimitReachedMessage(limit)
        case .duplicate(let name): L10n.citiesDuplicateMessage(name)
        }
    }
}

extension Notification.Name {
    /// Posted (on the main actor) whenever the active city changes, so anything
    /// holding prayer times can refresh.
    ///
    /// **Wiring note for W1 / the main session:** `PrayerTimesRepository` should
    /// observe this and call its own refresh — this file deliberately does not
    /// reach into the repository.
    static let mihrabActiveCityChanged = Notification.Name("mihrab.activeCityChanged")
}

// MARK: - Store

/// The multiple-cities feature, for real.
///
/// * Free tier: one city — wherever the device is. `freeCityLimit == 1`.
/// * Plus: as many as you like, reorderable, one active at a time.
///
/// Activating a city writes the manual-location override in `AppSettings`
/// (which `LocationManager.effectiveCoordinate` already prefers) and posts
/// `.mihrabActiveCityChanged`. That is the whole mechanism — no repository
/// code is touched from here.
@MainActor
@Observable
final class CityStore {
    static let shared = CityStore()

    // MARK: Persistence

    private let defaults: UserDefaults
    private enum Key {
        static let cities = "mihrab.cities.saved"
        static let activeID = "mihrab.cities.activeID"
    }

    /// Cities the user typed in or searched for. The current-location entry is
    /// never in here.
    private(set) var storedCities: [SavedCity] = []

    private(set) var activeCityID: UUID?

    /// Last known device location, mirrored so `cities` can synthesise the
    /// "current location" row without observing `LocationManager` directly.
    private(set) var currentLocation: SavedCity?

    init(defaults: UserDefaults? = nil) {
        self.defaults = defaults
            ?? UserDefaults(suiteName: SharedPrayerCache.appGroupID)
            ?? .standard
        load()
    }

    private func load() {
        if let data = self.defaults.data(forKey: Key.cities),
           let decoded = try? JSONDecoder().decode([SavedCity].self, from: data) {
            storedCities = decoded
        }
        if let raw = self.defaults.string(forKey: Key.activeID) {
            activeCityID = UUID(uuidString: raw)
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(storedCities) {
            defaults.set(data, forKey: Key.cities)
        }
        defaults.set(activeCityID?.uuidString, forKey: Key.activeID)
    }

    // MARK: Contract surface

    /// Current location first (when known), then the saved list in user order.
    var cities: [SavedCity] {
        if let currentLocation { return [currentLocation] + storedCities }
        return storedCities
    }

    var activeCity: SavedCity? {
        guard let activeCityID else { return cities.first }
        return cities.first { $0.id == activeCityID } ?? cities.first
    }

    /// One city on the free tier — the place you are actually in.
    var freeCityLimit: Int { 1 }

    var isPremium: Bool { SubscriptionManager.shared.hasAccess(to: .multipleCities) }

    /// The rule itself lives in a dependency-free value type so it can be
    /// tested without StoreKit, Core Location or `AppSettings`.
    var policy: CityTierPolicy { CityTierPolicy(freeLimit: freeCityLimit, isPremium: isPremium) }

    /// How many more the user may add before hitting the paywall. `nil` = unlimited.
    var remainingSlots: Int? { policy.remainingSlots(currentCount: cities.count) }

    func canAddMore() -> Bool { policy.canAdd(currentCount: cities.count) }

    /// Adds a city. Throws `CityStoreError.limitReached` on the free tier once
    /// the single slot is taken — the caller then presents
    /// `PaywallView(source: .feature)`.
    func add(_ city: SavedCity) throws {
        if let clash = cities.first(where: { $0.isNear(city) }) {
            throw CityStoreError.duplicate(name: clash.name)
        }
        guard canAddMore() else {
            throw CityStoreError.limitReached(limit: freeCityLimit)
        }
        storedCities.append(city)
        persist()
    }

    func remove(_ city: SavedCity) {
        guard !city.isCurrentLocation else { return }   // you cannot delete where you are
        storedCities.removeAll { $0.id == city.id }
        if activeCityID == city.id {
            activate(cities.first ?? city)
            return
        }
        persist()
    }

    func remove(atOffsets offsets: IndexSet) {
        // `cities` may lead with the synthetic current-location row; map back.
        let doomed = offsets.compactMap { index -> SavedCity? in
            guard cities.indices.contains(index) else { return nil }
            let city = cities[index]
            return city.isCurrentLocation ? nil : city
        }
        doomed.forEach(remove)
    }

    /// Reorder within the saved list. The current-location row is pinned first.
    func move(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        let lead = currentLocation == nil ? 0 : 1
        let from = IndexSet(offsets.compactMap { $0 >= lead ? $0 - lead : nil })
        guard !from.isEmpty else { return }
        let to = max(0, destination - lead)
        storedCities.move(fromOffsets: from, toOffset: min(to, storedCities.count))
        persist()
    }

    /// Makes `city` the one every prayer-time surface uses.
    func activate(_ city: SavedCity) {
        activeCityID = city.id
        persist()
        applyOverride(for: city)
        NotificationCenter.default.post(
            name: .mihrabActiveCityChanged,
            object: nil,
            userInfo: ["cityID": city.id.uuidString, "cityName": city.name]
        )
    }

    /// Current location clears the manual override; a saved city sets it.
    private func applyOverride(for city: SavedCity) {
        let settings = AppSettings.shared
        if city.isCurrentLocation {
            settings.manualCityName = nil
            settings.manualLatitude = nil
            settings.manualLongitude = nil
            settings.manualTimeZoneIdentifier = nil
        } else {
            settings.manualCityName = city.name
            settings.manualLatitude = city.latitude
            settings.manualLongitude = city.longitude
            settings.manualTimeZoneIdentifier = city.timeZoneIdentifier
        }
    }

    // MARK: Device location bridge

    /// Called by `CityListView` (and anyone else holding a fresh fix) so the
    /// list can show a live "current location" row.
    func updateCurrentLocation(name: String, coordinate: CLLocationCoordinate2D) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        currentLocation = SavedCity(
            id: SavedCity.currentLocationID,
            name: trimmed.isEmpty ? L10n.citiesCurrentLocation : trimmed,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            region: L10n.citiesCurrentLocation
        )
    }

    /// Pulls whatever `LocationManager` currently has. Safe to call repeatedly.
    func syncCurrentLocationFromDevice() {
        guard let coordinate = LocationManager.shared.location?.coordinate else { return }
        updateCurrentLocation(name: LocationManager.shared.cityName, coordinate: coordinate)
    }

    // MARK: Graceful downgrade

    /// When Plus lapses we **never delete** the extra cities — they simply stop
    /// being selectable, and come back the moment the user resubscribes. If the
    /// active city is one of the locked ones, fall back to the first slot.
    func enforceTierOnLaunch() {
        guard !isPremium else { return }
        guard let active = activeCity else { return }
        let allowed = Array(cities.prefix(policy.selectableCount(total: cities.count)))
        if !allowed.contains(where: { $0.id == active.id }), let fallback = allowed.first {
            activate(fallback)
        }
    }

    /// Cities beyond the free limit — shown dimmed with a Plus badge rather
    /// than hidden, so nobody thinks their data is gone.
    func isLocked(_ city: SavedCity) -> Bool {
        guard let index = cities.firstIndex(where: { $0.id == city.id }) else { return false }
        return policy.isLocked(index: index)
    }
}
