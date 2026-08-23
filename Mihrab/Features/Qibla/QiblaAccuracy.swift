import CoreLocation
import Foundation

/// How much the compass reading can be trusted, and against which north.
///
/// The rule this whole type exists to enforce: **never render a confident
/// needle on top of an unreliable sensor.** Competing apps lose their rating to
/// exactly one complaint — "it pointed me the wrong way and never said so".
/// Mihrab would rather show a grey needle and an explanation.
public struct QiblaAccuracy: Sendable, Equatable {

    /// Which north the displayed heading is measured from.
    public enum Reference: String, Sendable, Equatable {
        /// Geographic north. Requires a location fix; this is what the Qibla
        /// bearing is computed against, so it is the only fully correct one.
        case trueNorth
        /// Magnetic north. Off by the local declination — up to ~10° across
        /// Turkey and Europe, far more near the poles. Must be disclosed.
        case magnetic
        /// No usable heading at all.
        case none
    }

    public enum Confidence: Int, Sendable, Equatable, Comparable {
        /// No heading has arrived yet, or the device has no magnetometer.
        case unavailable = 0
        /// CoreLocation reports a negative accuracy: the reading is invalid.
        case invalid = 1
        /// The error bar is wider than `coarseThreshold`. We keep drawing the
        /// dial so the screen is not dead, but every confident affordance
        /// (lock-on, haptic ticks, "you are facing the Qibla") stays off.
        case coarse = 2
        /// Within the tolerance we are willing to call a Qibla direction.
        case good = 3

        public static func < (lhs: Confidence, rhs: Confidence) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// Above this many degrees of reported error we stop claiming a direction.
    /// 20° is roughly the width of two prayer-mat shoulders at arm's length —
    /// past that the needle is decoration, not guidance.
    public static let coarseThreshold: Double = 20
    /// Below this we are happy to light the "locked on" state.
    public static let goodThreshold: Double = 10
    /// Half-width of the lock-on window, in degrees.
    public static let lockTolerance: Double = 3

    public let confidence: Confidence
    public let reference: Reference
    /// CoreLocation's own error estimate in degrees; `nil` when meaningless.
    public let reportedError: Double?

    public init(confidence: Confidence, reference: Reference, reportedError: Double?) {
        self.confidence = confidence
        self.reference = reference
        self.reportedError = reportedError
    }

    /// The one gate every piece of Qibla UI must ask before it is allowed to
    /// assert a direction: lock-on, the "facing the Qibla" banner, the
    /// approach haptics. `false` does not mean "hide the compass" — it means
    /// "stop pretending the number means something".
    public var isTrustworthy: Bool { confidence == .good }

    /// `true` when there is a needle to draw at all, trustworthy or not.
    public var hasHeading: Bool { confidence != .unavailable }

    /// `true` when we are pointing at magnetic north and saying so is required.
    public var isMagneticFallback: Bool { reference == .magnetic }

    /// `true` when the user should be walked through the figure-eight.
    public var needsCalibration: Bool {
        confidence == .invalid || confidence == .coarse
    }

    /// Derive the gate from a raw CoreLocation heading.
    ///
    /// `trueHeading` is only populated once CoreLocation has both a magnetic
    /// reading *and* a location fix to look the declination up against. A
    /// negative `trueHeading` therefore means "true north unknown", and a
    /// negative `headingAccuracy` means "this reading is invalid" — two
    /// different failures that this app deliberately reports differently.
    public static func evaluate(_ heading: CLHeading?) -> QiblaAccuracy {
        guard let heading else {
            return QiblaAccuracy(confidence: .unavailable, reference: .none, reportedError: nil)
        }
        return evaluate(trueHeading: heading.trueHeading,
                        magneticHeading: heading.magneticHeading,
                        headingAccuracy: heading.headingAccuracy)
    }

    /// The gate itself, over plain numbers.
    ///
    /// Split out from the `CLHeading` overload on purpose: `CLHeading` has no
    /// public initialiser, so this is the only form the threshold behaviour can
    /// actually be unit-tested in.
    public static func evaluate(trueHeading: Double,
                                magneticHeading: Double,
                                headingAccuracy: Double) -> QiblaAccuracy {
        let hasTrue = trueHeading >= 0
        let hasMagnetic = magneticHeading >= 0

        guard hasTrue || hasMagnetic else {
            return QiblaAccuracy(confidence: .unavailable, reference: .none, reportedError: nil)
        }
        let reference: Reference = hasTrue ? .trueNorth : .magnetic

        guard headingAccuracy >= 0 else {
            return QiblaAccuracy(confidence: .invalid, reference: reference, reportedError: nil)
        }
        if headingAccuracy > coarseThreshold {
            return QiblaAccuracy(confidence: .coarse, reference: reference, reportedError: headingAccuracy)
        }
        return QiblaAccuracy(confidence: .good, reference: reference, reportedError: headingAccuracy)
    }

    /// The heading we should actually draw, in degrees from **true** north.
    /// Returns `nil` when there is nothing honest to draw.
    ///
    /// When only a magnetic heading exists we still draw it — a compass that
    /// refuses to move is useless — but the caller is obliged to show
    /// `L10n.qblMagneticNorthWarning` alongside it.
    public static func displayHeading(_ heading: CLHeading?) -> Double? {
        guard let heading else { return nil }
        if heading.trueHeading >= 0 { return heading.trueHeading }
        if heading.magneticHeading >= 0 { return heading.magneticHeading }
        return nil
    }
}
