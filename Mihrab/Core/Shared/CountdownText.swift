import SwiftUI

/// `Text(timerInterval:)` traps if the range is empty or inverted
/// (`lowerBound >= upperBound`). Passed prayers, stale Live Activities, and
/// widget timeline entries all hit that. Never construct the range yourself.
public enum SafeCountdown {
    /// A closed range only when `end` is strictly after `start`.
    public static func range(from start: Date, to end: Date) -> ClosedRange<Date>? {
        guard end.timeIntervalSince(start) > 0.05 else { return nil }
        return start...end
    }
}

public struct CountdownText: View {
    public var start: Date
    public var end: Date
    public var finished: String

    public init(from start: Date = .now, to end: Date, finished: String = "00:00:00") {
        self.start = start
        self.end = end
        self.finished = finished
    }

    public var body: some View {
        if let range = SafeCountdown.range(from: start, to: end) {
            Text(timerInterval: range, countsDown: true)
        } else {
            Text(finished)
        }
    }
}
