import CoreLocation
import SwiftUI

/// Location + heading provider for prayer times, qibla, and mosques.
///
/// Battery discipline (roadmap #10):
/// * A meaningful `distanceFilter` — prayer times do not change over a few
///   hundred metres, so we only wake for kilometre-scale movement.
/// * `stopUpdating()` exists and is meant to be called when a screen goes away.
/// * Reverse geocoding is throttled *and* cached: `CLGeocoder` is rate-limited
///   by the system and was previously fired on every single fix.
/// * `isLowPowerMode` is published so UI agents can drop animation work.
@Observable
final class LocationManager: NSObject, @unchecked Sendable {
    static let shared = LocationManager()

    /// How accurate a consumer needs the fix to be.
    enum Precision: Sendable {
        /// Prayer times, city name, mosque list. A few kilometres is plenty:
        /// the largest prayer-time delta across 3 km is well under a minute.
        case prayerTimes
        /// Compass / AR qibla. The bearing is sensitive to position, and the
        /// screen is in the user's hand for a short, deliberate burst.
        case qibla

        var desiredAccuracy: CLLocationAccuracy {
            switch self {
            case .prayerTimes: kCLLocationAccuracyKilometer
            case .qibla: kCLLocationAccuracyNearestTenMeters
            }
        }

        /// Metres of movement before Core Location wakes us again.
        var distanceFilter: CLLocationDistance {
            switch self {
            case .prayerTimes: 2_000
            case .qibla: 10
            }
        }
    }

    private(set) var location: CLLocation?
    private(set) var cityName: String = ""
    private(set) var heading: CLHeading?
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    /// Smoothed heading after low-pass filtering (α = 0.15), wrapped to [0, 360).
    private(set) var smoothedHeading: Double = 0

    /// Unwrapped heading for compass rotation so springs never take the long way around 0°.
    private(set) var continuousHeading: Double = 0

    /// True while iOS Low Power Mode is on.
    ///
    /// **For the UI agents:** read `LocationManager.shared.isLowPowerMode` (it is
    /// `@Observable`, so views re-render when it flips) and drop to the cheap
    /// path — no repeating shader animation, no continuous aurora drift. Treat
    /// it exactly like `accessibilityReduceMotion` for cost purposes.
    private(set) var isLowPowerMode: Bool = ProcessInfo.processInfo.isLowPowerModeEnabled

    /// Which consumers currently want updates. Location stops when it empties.
    private(set) var activePrecisions: Set<String> = []

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var headingInitialized = false
    private var isUpdatingLocation = false
    private var currentPrecision: Precision = .prayerTimes

    // Reverse-geocode throttle + cache.
    private var lastGeocodedLocation: CLLocation?
    private var lastGeocodeAt: Date?
    private var isGeocodingNow = false

    /// Do not reverse-geocode more than once a minute, or for movement smaller
    /// than this — the city name simply cannot have changed.
    private static let geocodeMinInterval: TimeInterval = 60
    private static let geocodeMinDistance: CLLocationDistance = 3_000

    override private init() {
        super.init()
        manager.delegate = self
        apply(precision: .prayerTimes)
        manager.headingFilter = 1
        authorizationStatus = manager.authorizationStatus
        observeLowPowerMode()
    }

    private func observeLowPowerMode() {
        NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    // MARK: - Location updates

    private func apply(precision: Precision) {
        currentPrecision = precision
        manager.desiredAccuracy = precision.desiredAccuracy
        manager.distanceFilter = precision.distanceFilter
    }

    /// Starts (or upgrades) location updates.
    ///
    /// Precision is *reference counted* by key: while the qibla screen is on
    /// screen we run at high precision, and dropping back to `.prayerTimes`
    /// happens automatically when it calls `stopUpdating(precision: .qibla)`.
    func startUpdating(precision: Precision = .prayerTimes) {
        activePrecisions.insert(key(for: precision))
        // Highest requested precision wins.
        apply(precision: activePrecisions.contains(key(for: .qibla)) ? .qibla : .prayerTimes)
        guard !isUpdatingLocation else { return }
        manager.startUpdatingLocation()
        isUpdatingLocation = true
    }

    /// Releases one consumer. Updates stop entirely when the last one leaves.
    func stopUpdating(precision: Precision = .prayerTimes) {
        activePrecisions.remove(key(for: precision))
        if activePrecisions.isEmpty {
            manager.stopUpdatingLocation()
            isUpdatingLocation = false
        } else {
            apply(precision: activePrecisions.contains(key(for: .qibla)) ? .qibla : .prayerTimes)
        }
    }

    /// Hard stop — for backgrounding, or a screen that owns nothing else.
    func stopAllUpdates() {
        activePrecisions.removeAll()
        manager.stopUpdatingLocation()
        isUpdatingLocation = false
        stopHeading()
    }

    private func key(for precision: Precision) -> String {
        switch precision {
        case .prayerTimes: "prayerTimes"
        case .qibla: "qibla"
        }
    }

    /// One-shot fix for a background refresh — no continuous stream to forget
    /// to stop.
    func requestOneShotLocation() {
        manager.requestLocation()
    }

    // MARK: - Heading

    func startHeading() {
        guard CLLocationManager.headingAvailable() else { return }
        manager.startUpdatingHeading()
    }

    func stopHeading() {
        manager.stopUpdatingHeading()
    }

    /// Effective coordinate: manual override wins (Settings → Location, and the
    /// active city chosen in `CityStore`).
    var effectiveCoordinate: CLLocationCoordinate2D? {
        let settings = AppSettings.shared
        if let lat = settings.manualLatitude, let lon = settings.manualLongitude {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        return location?.coordinate
    }

    var effectiveCityName: String {
        AppSettings.shared.manualCityName ?? cityName
    }

    /// The zone that belongs to `effectiveCoordinate`. A saved city in another
    /// zone must not be rendered on the device's clock — that is an hour-scale
    /// error the user has no way to spot.
    var effectiveTimeZone: TimeZone {
        let settings = AppSettings.shared
        guard settings.manualLatitude != nil,
              let identifier = settings.manualTimeZoneIdentifier,
              let zone = TimeZone(identifier: identifier)
        else { return .current }
        return zone
    }

    private func wrapDegrees(_ value: Double) -> Double {
        var wrapped = value.truncatingRemainder(dividingBy: 360)
        if wrapped < 0 { wrapped += 360 }
        return wrapped
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            // Only resume if somebody actually asked for updates. Starting here
            // unconditionally was one of the "always on" paths.
            if !activePrecisions.isEmpty && !isUpdatingLocation {
                manager.startUpdatingLocation()
                isUpdatingLocation = true
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        location = latest
        Task { await reverseGeocodeIfNeeded(latest) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // `requestLocation()` requires a delegate method; a failure here is not
        // worth surfacing — the cached fix stays valid.
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading
        let true_ = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        if !headingInitialized {
            smoothedHeading = true_
            continuousHeading = true_
            headingInitialized = true
        } else {
            let delta = QiblaMath.shortestDelta(from: wrapDegrees(continuousHeading), to: true_)
            continuousHeading += 0.18 * delta
            smoothedHeading = wrapDegrees(continuousHeading)
        }
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool { true }

    /// Throttled + cached reverse geocode.
    ///
    /// `CLPlacemark` is **not** `Sendable`: it is consumed inside this function
    /// and only the extracted `String` escapes.
    private func reverseGeocodeIfNeeded(_ location: CLLocation) async {
        guard !isGeocodingNow, !geocoder.isGeocoding else { return }

        // Never twice inside a minute, whatever happens.
        if let lastGeocodeAt, Date().timeIntervalSince(lastGeocodeAt) < Self.geocodeMinInterval {
            return
        }
        // Cache hit: we already have a name and we have not moved far enough
        // for it to have changed.
        if let last = lastGeocodedLocation, !cityName.isEmpty,
           location.distance(from: last) < Self.geocodeMinDistance {
            return
        }

        isGeocodingNow = true
        defer { isGeocodingNow = false }

        lastGeocodeAt = Date()
        guard let placemark = try? await geocoder.reverseGeocodeLocation(location).first else {
            return
        }
        let resolved = placemark.locality ?? placemark.administrativeArea ?? ""
        lastGeocodedLocation = location
        guard !resolved.isEmpty else { return }
        cityName = resolved

        let coordinate = location.coordinate
        await MainActor.run {
            CityStore.shared.updateCurrentLocation(name: resolved, coordinate: coordinate)
        }
    }
}
