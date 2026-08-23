import WatchKit

/// Wrist feedback, kept in one place so the vocabulary stays consistent.
///
/// `WKInterfaceDevice.play(_:)` is used rather than SwiftUI's
/// `.sensoryFeedback` because these fire from imperative code paths (a Crown
/// detent crossing, a compass entering alignment) rather than from a value
/// change a view can observe — and because the watch taptic vocabulary
/// (`.click`, `.directionUp`, `.success`) has no SwiftUI equivalent.
///
/// Every call is cheap but not free: a haptic on every Crown tick would be a
/// buzzing wrist and a flat battery, so the counter fires one per counted
/// increment, never per rotation delta.
enum WatchHaptics {

    static func tick() {
        WKInterfaceDevice.current().play(.click)
    }

    /// One step closer — used as the compass narrows on the Qibla.
    static func nudge() {
        WKInterfaceDevice.current().play(.directionUp)
    }

    /// Target reached, prayer marked, Qibla found.
    static func success() {
        WKInterfaceDevice.current().play(.success)
    }

    static func failure() {
        WKInterfaceDevice.current().play(.failure)
    }

    static func start() {
        WKInterfaceDevice.current().play(.start)
    }

    static func stop() {
        WKInterfaceDevice.current().play(.stop)
    }
}
