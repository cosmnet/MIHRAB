import SwiftUI
import UIKit

// MARK: - Screen dimming

/// Focus mode can take the display down a notch, the way a reading app does.
///
/// The brightness the user had is remembered here and *always* handed back — on
/// leaving focus mode, on leaving the screen, and on the app going to the
/// background. If we ever fail to restore it, the user is left staring at a
/// phone they think is broken, so every exit path funnels through `restore()`.
@MainActor
enum DhikrScreenDim {
    private static var previous: CGFloat?

    static var isDimmed: Bool { previous != nil }

    /// Multiplies the current brightness, never going under `floor` — a screen
    /// dimmed to zero in a dark room is indistinguishable from a dead one.
    static func dim(factor: CGFloat = 0.55, floor: CGFloat = 0.18) {
        guard previous == nil else { return }
        let screen = UIScreen.main
        let current = screen.brightness
        previous = current
        screen.brightness = max(floor, min(current, current * factor))
    }

    static func restore() {
        guard let value = previous else { return }
        previous = nil
        UIScreen.main.brightness = value
    }
}

// MARK: - Hold-to-reset ring

/// The confirmation ring for a press-and-hold reset.
///
/// Losing a 500-count set to a stray tap is the one unrecoverable mistake this
/// screen can make, so resetting costs a deliberate hold and the ring says
/// exactly how much of that hold is left. Released early, it unwinds and
/// nothing happens.
struct DhikrHoldRing: View {
    let progress: Double
    let side: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(MihrabColor.danger.opacity(0.18 * min(progress * 3, 1)), lineWidth: 3)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    MihrabColor.danger.opacity(0.9),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: MihrabColor.danger.opacity(0.45), radius: 5)
        }
        .frame(width: side - 4, height: side - 4)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Focus chrome

/// The single line that stays on screen in focus mode, telling the user how to
/// get the rest of the app back. Fades out after a few seconds so the screen
/// really is just the dial.
struct DhikrFocusHint: View {
    let visible: Bool

    var body: some View {
        Text(L10n.dhkFocusExitHint)
            .font(.caption2)
            // textSecondary, not textTertiary: tertiary measures 2.9:1 on moss
            // and 4.1:1 on abyss, both under the 4.5:1 floor.
            .foregroundStyle(MihrabColor.textSecondary)
            .opacity(visible ? 1 : 0)
            .allowsHitTesting(false)
    }
}
