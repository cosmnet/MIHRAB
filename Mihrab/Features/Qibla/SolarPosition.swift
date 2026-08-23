import CoreLocation
import Foundation

/// Where the sun is, computed on device.
///
/// Why this file exists: a magnetometer can be wrong and never say so. The sun
/// cannot. If we can tell the user "right now the sun sits 23° to the left of
/// the Qibla", they can check the compass against the sky with no sensor at
/// all — and that is the single cheapest defence against the "app pointed me
/// the wrong way" review that sinks every competitor.
///
/// Algorithm: the NOAA Solar Calculator equations (Astronomical Almanac,
/// low-precision form). Accuracy is about ±0.01° in declination and better
/// than ±0.1° in azimuth for the years this app will run — far tighter than
/// any phone compass, which is the point.
///
/// Everything here is pure: no singletons, no `AppSettings`, no SwiftUI, so it
/// compiles into the test target as-is.
public struct SolarPosition: Sendable, Equatable {
    /// Degrees clockwise from **true** north, in [0, 360).
    public let azimuth: Double
    /// Geometric altitude above the horizon in degrees. Negative = below.
    /// No refraction correction — we never use this for sunrise/sunset (that
    /// is adhan-swift's job), only for "is there a usable shadow right now".
    public let altitude: Double
    /// Solar declination in degrees.
    public let declination: Double
    /// Equation of time in minutes.
    public let equationOfTimeMinutes: Double

    /// Direction a vertical object's shadow points, in degrees from true north.
    public var shadowAzimuth: Double { SolarMath.wrap360(azimuth + 180) }
}

public enum SolarMath {

    // MARK: - Primitives

    @inline(__always) static func rad(_ degrees: Double) -> Double { degrees * .pi / 180 }
    @inline(__always) static func deg(_ radians: Double) -> Double { radians * 180 / .pi }

    /// Wrap to [0, 360).
    public static func wrap360(_ value: Double) -> Double {
        let r = value.truncatingRemainder(dividingBy: 360)
        return r < 0 ? r + 360 : r
    }

    /// Julian Day including fractional time, from a `Date` (UTC based).
    public static func julianDay(_ date: Date) -> Double {
        date.timeIntervalSince1970 / 86_400 + 2_440_587.5
    }

    static func date(fromJulianDay jd: Double) -> Date {
        Date(timeIntervalSince1970: (jd - 2_440_587.5) * 86_400)
    }

    /// Julian centuries since J2000.0.
    static func julianCentury(_ jd: Double) -> Double { (jd - 2_451_545.0) / 36_525 }

    // MARK: - Sun

    /// Declination (degrees) and equation of time (minutes) for an instant.
    /// Both depend only on the date, not on the observer.
    public static func solarParameters(at date: Date) -> (declination: Double, equationOfTime: Double) {
        let t = julianCentury(julianDay(date))

        let meanLongitude = wrap360(280.46646 + t * (36_000.76983 + t * 0.000_303_2))
        let meanAnomaly = 357.52911 + t * (35_999.05029 - 0.000_153_7 * t)
        let eccentricity = 0.016_708_634 - t * (0.000_042_037 + 0.000_000_126_7 * t)

        let centre = sin(rad(meanAnomaly)) * (1.914602 - t * (0.004817 + 0.000014 * t))
            + sin(rad(2 * meanAnomaly)) * (0.019993 - 0.000101 * t)
            + sin(rad(3 * meanAnomaly)) * 0.000289

        let trueLongitude = meanLongitude + centre
        let omega = 125.04 - 1_934.136 * t
        let apparentLongitude = trueLongitude - 0.00569 - 0.00478 * sin(rad(omega))

        let meanObliquity = 23 + (26 + ((21.448 - t * (46.815 + t * (0.00059 - t * 0.001813)))) / 60) / 60
        let obliquity = meanObliquity + 0.00256 * cos(rad(omega))

        let declination = deg(asin(sin(rad(obliquity)) * sin(rad(apparentLongitude))))

        let varY = pow(tan(rad(obliquity / 2)), 2)
        let equationOfTime = 4 * deg(
            varY * sin(2 * rad(meanLongitude))
                - 2 * eccentricity * sin(rad(meanAnomaly))
                + 4 * eccentricity * varY * sin(rad(meanAnomaly)) * cos(2 * rad(meanLongitude))
                - 0.5 * varY * varY * sin(4 * rad(meanLongitude))
                - 1.25 * eccentricity * eccentricity * sin(2 * rad(meanAnomaly))
        )

        return (declination, equationOfTime)
    }

    /// Full topocentric-enough solar position for an observer.
    public static func position(at date: Date, coordinate: CLLocationCoordinate2D) -> SolarPosition {
        let (declination, equationOfTime) = solarParameters(at: date)

        // Minutes elapsed since UTC midnight, straight out of the Julian day.
        let jd = julianDay(date)
        let dayFraction = (jd + 0.5) - floor(jd + 0.5)
        let utcMinutes = dayFraction * 1_440

        var trueSolarTime = (utcMinutes + equationOfTime + 4 * coordinate.longitude)
            .truncatingRemainder(dividingBy: 1_440)
        if trueSolarTime < 0 { trueSolarTime += 1_440 }

        var hourAngle = trueSolarTime / 4 - 180
        if hourAngle < -180 { hourAngle += 360 }

        let latRad = rad(coordinate.latitude)
        let decRad = rad(declination)
        let haRad = rad(hourAngle)

        let cosZenith = min(max(sin(latRad) * sin(decRad) + cos(latRad) * cos(decRad) * cos(haRad), -1), 1)
        let zenith = acos(cosZenith)
        let altitude = 90 - deg(zenith)

        // NOAA azimuth: undefined exactly at the poles and at the zenith, so we
        // fall back to the hour angle rather than returning NaN.
        let azimuth: Double
        let denominator = cos(latRad) * sin(zenith)
        if abs(denominator) < 1e-9 {
            azimuth = hourAngle > 0 ? 0 : 180
        } else {
            let cosAz = min(max((sin(latRad) * cosZenith - sin(decRad)) / denominator, -1), 1)
            let base = deg(acos(cosAz))
            azimuth = hourAngle > 0 ? wrap360(base + 180) : wrap360(540 - base)
        }

        return SolarPosition(azimuth: azimuth,
                             altitude: altitude,
                             declination: declination,
                             equationOfTimeMinutes: equationOfTime)
    }

    // MARK: - Transit

    /// The instant the sun crosses the meridian of `longitude` on the UTC day
    /// containing `date`. Two fixed-point iterations is plenty: the equation of
    /// time moves by well under a second across the correction.
    public static func solarTransit(onUTCDayOf date: Date, longitude: Double) -> Date {
        let jd = julianDay(date)
        let midnightJD = floor(jd + 0.5) - 0.5
        var instant = self.date(fromJulianDay: midnightJD + 0.5)
        for _ in 0..<3 {
            let equationOfTime = solarParameters(at: instant).equationOfTime
            let utcHours = 12 - longitude / 15 - equationOfTime / 60
            instant = self.date(fromJulianDay: midnightJD + utcHours / 24)
        }
        return instant
    }

    /// Local solar transit (true noon / *istiva*) for the calendar day that
    /// `date` falls on in `calendar`'s time zone.
    public static func localSolarNoon(on date: Date,
                                      coordinate: CLLocationCoordinate2D,
                                      calendar: Calendar) -> Date {
        // Anchor on local midday so the UTC day we solve on is the right one
        // even for longitudes near the date line.
        let localNoon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
        return solarTransit(onUTCDayOf: localNoon, longitude: coordinate.longitude)
    }

    // MARK: - Altitude crossings

    /// The instant on this local day when the sun's altitude passes
    /// `altitude`, either climbing (`rising: true`) or falling.
    ///
    /// Solved by bisection against the true altitude curve rather than by a
    /// closed form, so it stays correct at every latitude the app supports and
    /// simply returns `nil` where the crossing does not happen at all.
    public static func time(atAltitude altitude: Double,
                            rising: Bool,
                            on date: Date,
                            coordinate: CLLocationCoordinate2D,
                            calendar: Calendar) -> Date? {
        let noon = localSolarNoon(on: date, coordinate: coordinate, calendar: calendar)
        let noonAltitude = position(at: noon, coordinate: coordinate).altitude
        guard noonAltitude > altitude else { return nil }   // sun never gets that high today

        var low = rising ? noon.addingTimeInterval(-12 * 3_600) : noon
        var high = rising ? noon : noon.addingTimeInterval(12 * 3_600)

        // f is negative below the target, positive above it, on the half-day
        // that contains the crossing.
        func f(_ t: Date) -> Double { position(at: t, coordinate: coordinate).altitude - altitude }
        guard f(low) * f(high) <= 0 else { return nil }      // polar day: never crosses

        for _ in 0..<40 {
            let mid = Date(timeIntervalSince1970: (low.timeIntervalSince1970 + high.timeIntervalSince1970) / 2)
            if f(low) * f(mid) <= 0 { high = mid } else { low = mid }
        }
        return Date(timeIntervalSince1970: (low.timeIntervalSince1970 + high.timeIntervalSince1970) / 2)
    }

    // MARK: - Sun ⇄ Qibla

    /// Signed angle from the sun to the Qibla, in (-180, 180].
    /// Negative = the Qibla is to the **left** of the sun as you face the sun.
    public static func sunToQiblaDelta(sunAzimuth: Double, qiblaBearing: Double) -> Double {
        QiblaMath.shortestDelta(from: sunAzimuth, to: qiblaBearing)
    }

    /// The moments today when the sun stands exactly on the Qibla bearing and
    /// is high enough to cast a readable shadow.
    ///
    /// At most two per day (the azimuth curve can cross a given bearing twice
    /// in high summer at high latitudes). Coarse 2-minute sweep, then bisection
    /// — accurate to a couple of seconds, and cheap enough to run in `body`.
    public static func sunOnQiblaMoments(on date: Date,
                                         coordinate: CLLocationCoordinate2D,
                                         qiblaBearing: Double,
                                         calendar: Calendar,
                                         minimumAltitude: Double = 3) -> [Date] {
        let start = calendar.startOfDay(for: date)
        let step: TimeInterval = 120
        let steps = Int((24 * 3_600) / step)

        func delta(_ t: Date) -> Double {
            QiblaMath.shortestDelta(from: position(at: t, coordinate: coordinate).azimuth, to: qiblaBearing)
        }

        var results: [Date] = []
        var previousTime = start
        var previousDelta = delta(start)

        for index in 1...steps {
            let time = start.addingTimeInterval(Double(index) * step)
            let current = delta(time)
            // Ignore the ±180 wrap: a real crossing moves through zero, so the
            // two samples must be small and on opposite sides.
            if previousDelta.sign != current.sign, abs(previousDelta) < 90, abs(current) < 90 {
                var low = previousTime
                var high = time
                for _ in 0..<24 {
                    let mid = Date(timeIntervalSince1970: (low.timeIntervalSince1970 + high.timeIntervalSince1970) / 2)
                    if delta(low).sign == delta(mid).sign { low = mid } else { high = mid }
                }
                let crossing = Date(timeIntervalSince1970: (low.timeIntervalSince1970 + high.timeIntervalSince1970) / 2)
                if position(at: crossing, coordinate: coordinate).altitude >= minimumAltitude {
                    results.append(crossing)
                }
            }
            previousTime = time
            previousDelta = current
        }
        return results
    }

    // MARK: - Rashdul Qibla (Istiwa al-A'zam)

    /// The two instants each year when the sun stands directly over the Kaaba,
    /// so that **every** shadow on the lit half of the earth points away from
    /// the Qibla.
    ///
    /// These are *not* hard-coded dates. We walk forward one day at a time,
    /// take the sun's declination at the Kaaba's own meridian transit, and
    /// return the transit of the day on which that declination crosses the
    /// Kaaba's latitude. In practice this lands in late May and mid July, which
    /// is exactly where the published Rashdul Qibla dates fall — but it is
    /// derived, not memorised, so it stays right in leap years and future
    /// decades.
    ///
    /// Residual error: declination moves ~0.2°/day at those crossings and we
    /// snap to the nearer whole day, so the sub-solar point can sit up to about
    /// 0.1° from the Kaaba. That is a shadow-direction error well under 1° —
    /// smaller than anyone can read off a shadow anyway. Documented rather than
    /// hidden.
    public static func rashdulQiblaMoments(after date: Date,
                                           limit: Int = 2,
                                           searchDays: Int = 400) -> [Date] {
        let kaabaLatitude = QiblaMath.kaabaLatitude
        let kaabaLongitude = QiblaMath.kaabaLongitude

        var results: [Date] = []
        var previousTransit: Date?
        var previousDifference: Double?

        for offset in 0...searchDays {
            let probe = date.addingTimeInterval(Double(offset) * 86_400)
            let transit = solarTransit(onUTCDayOf: probe, longitude: kaabaLongitude)
            let difference = solarParameters(at: transit).declination - kaabaLatitude

            if let previousDifference, let previousTransit, previousDifference.sign != difference.sign {
                let best = abs(previousDifference) <= abs(difference) ? previousTransit : transit
                if best > date {
                    results.append(best)
                    if results.count >= limit { return results }
                }
            }
            previousDifference = difference
            previousTransit = transit
        }
        return results
    }

    /// `true` when `date` is within `tolerance` of a Rashdul Qibla instant.
    public static func isRashdulQibla(_ date: Date, tolerance: TimeInterval = 90) -> Bool {
        guard let next = rashdulQiblaMoments(after: date.addingTimeInterval(-2 * 86_400), limit: 3).first(where: {
            abs($0.timeIntervalSince(date)) < 2 * 86_400
        }) else { return false }
        return abs(next.timeIntervalSince(date)) <= tolerance
    }
}
