import CoreLocation
import SwiftUI

/// Location + heading provider for prayer times, qibla, and mosques.
@Observable
final class LocationManager: NSObject, @unchecked Sendable {
    static let shared = LocationManager()

    private(set) var location: CLLocation?
    private(set) var cityName: String = ""
    private(set) var heading: CLHeading?
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    /// Smoothed heading after low-pass filtering (α = 0.15), wrapped to [0, 360).
    private(set) var smoothedHeading: Double = 0

    /// Unwrapped heading for compass rotation so springs never take the long way around 0°.
    private(set) var continuousHeading: Double = 0

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var headingInitialized = false

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.headingFilter = 1
        authorizationStatus = manager.authorizationStatus
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func startHeading() {
        guard CLLocationManager.headingAvailable() else { return }
        manager.startUpdatingHeading()
    }

    func stopHeading() {
        manager.stopUpdatingHeading()
    }

    /// Effective coordinate: manual override wins (Settings → Location).
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
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        location = latest
        Task { await reverseGeocode(latest) }
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

    private func reverseGeocode(_ location: CLLocation) async {
        guard !geocoder.isGeocoding else { return }
        if let placemark = try? await geocoder.reverseGeocodeLocation(location).first {
            cityName = placemark.locality ?? placemark.administrativeArea ?? ""
        }
    }
}
