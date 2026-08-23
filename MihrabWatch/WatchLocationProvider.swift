import CoreLocation
import Foundation
import Observation

/// Location and heading, on the watch.
///
/// Two deliberate honesty rules, because a compass that lies is worse than no
/// compass at all:
///
/// 1. **`CLLocationManager.headingAvailable()` is checked at runtime, never
///    assumed.** Not every Apple Watch has a magnetometer. When there is none,
///    the Qibla screen says so and points the user at the iPhone instead of
///    drawing a needle it cannot justify.
/// 2. **Heading accuracy is surfaced, not hidden.** A negative
///    `headingAccuracy` means the reading is invalid; a large one means it is
///    unreliable. Both are shown rather than smoothed away.
///
/// Updates are started and stopped by the screens that need them. Nothing runs
/// while the app is not in front — the watch battery cannot afford it, and a
/// prayer-time app has no business holding a sensor open in the background.
@Observable
final class WatchLocationProvider: NSObject, @unchecked Sendable {

    static let shared = WatchLocationProvider()

    private(set) var coordinate: CLLocationCoordinate2D?
    private(set) var authorization: CLAuthorizationStatus = .notDetermined

    /// Smoothed heading in degrees, `nil` until a usable reading arrives.
    private(set) var heading: Double?
    /// The raw `headingAccuracy` in degrees. Negative means invalid.
    private(set) var headingAccuracy: Double = -1
    private(set) var isCalibrating = false
    /// `true` when the displayed heading is measured from geographic north.
    /// Magnetic-only readings are off by the local declination and the Qibla
    /// screen says so rather than pretending otherwise.
    private(set) var isTrueNorth = false

    /// Whether this watch has a compass at all.
    let hasCompass = CLLocationManager.headingAvailable()

    private let manager = CLLocationManager()
    private var locationClients = 0
    private var headingClients = 0
    private var smoothed: Double?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.headingFilter = 1
        authorization = manager.authorizationStatus
    }

    func requestAuthorization() {
        guard authorization == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    // MARK: - Reference-counted sensors

    func startLocation() {
        requestAuthorization()
        locationClients += 1
        guard locationClients == 1 else { return }
        manager.startUpdatingLocation()
    }

    func stopLocation() {
        locationClients = max(0, locationClients - 1)
        guard locationClients == 0 else { return }
        manager.stopUpdatingLocation()
    }

    func startHeading() {
        guard hasCompass else { return }
        requestAuthorization()
        headingClients += 1
        guard headingClients == 1 else { return }
        manager.startUpdatingHeading()
    }

    func stopHeading() {
        guard hasCompass else { return }
        headingClients = max(0, headingClients - 1)
        guard headingClients == 0 else { return }
        manager.stopUpdatingHeading()
    }

    /// `true` when a heading exists and is trustworthy enough to point with.
    var hasUsableHeading: Bool {
        heading != nil && headingAccuracy >= 0 && headingAccuracy <= 25
    }

    /// The Qibla bearing from the current coordinate, if there is one.
    func qiblaBearing(fallback: CLLocationCoordinate2D?) -> Double? {
        guard let c = coordinate ?? fallback else { return nil }
        return QiblaMath.bearing(fromLatitude: c.latitude, longitude: c.longitude)
    }
}

extension WatchLocationProvider: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
        let granted = authorization == .authorizedWhenInUse || authorization == .authorizedAlways
        if granted && locationClients > 0 {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        coordinate = last.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        headingAccuracy = newHeading.headingAccuracy
        isCalibrating = newHeading.headingAccuracy < 0

        // True north is what the Qibla bearing is measured against. Magnetic is
        // the fallback and the UI discloses it.
        isTrueNorth = newHeading.trueHeading >= 0
        let raw = isTrueNorth ? newHeading.trueHeading : newHeading.magneticHeading
        guard raw >= 0 else { return }

        // Low-pass filter across the 0°/360° seam, so the needle never snaps
        // the long way round.
        if let previous = smoothed {
            let delta = QiblaMath.shortestDelta(from: previous, to: raw)
            var next = previous + delta * 0.2
            next = next.truncatingRemainder(dividingBy: 360)
            if next < 0 { next += 360 }
            smoothed = next
        } else {
            smoothed = raw
        }
        heading = smoothed
    }

    /// Let the system show its calibration prompt when the reading is invalid;
    /// suppressing it would leave the user with a permanently wrong needle.
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        true
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Nothing to recover: the screens already handle "no coordinate".
    }
}
