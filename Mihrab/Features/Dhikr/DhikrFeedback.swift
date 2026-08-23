import AudioToolbox
import CoreHaptics
import UIKit

/// Counter-specific feedback. `HapticsEngine` owns the shared vocabulary
/// (tap ramp, set completion, phrase swap); this file adds only the two
/// patterns that belong to the Zikirmatik and nowhere else — the milestone
/// chime at 33 / 66 / 99, and the four-beat flourish when a routine ends.
///
/// Every call is a no-op when the user turns vibration off in Settings, so the
/// preference is honoured in one place instead of at every call site.
@MainActor
enum DhikrFeedback {

    private static var engine: CHHapticEngine? = {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return nil }
        let engine = try? CHHapticEngine()
        try? engine?.start()
        engine?.resetHandler = { [weak engine] in try? engine?.start() }
        return engine
    }()

    private static var hapticsOn: Bool { DhikrStore.shared.hapticsEnabled }
    private static var soundOn: Bool { DhikrStore.shared.soundEnabled }

    // MARK: - Taps

    static func tap(countInSet: Int, target: Int) {
        if hapticsOn {
            HapticsEngine.shared.dhikrProgressTap(countInSet: countInSet, target: target)
        }
        if soundOn {
            // A short, dry UI tick — the closest system sound to a bead click.
            AudioServicesPlaySystemSound(1104)
        }
    }

    static func phraseSwap() {
        guard hapticsOn else { return }
        HapticsEngine.shared.phraseSwap()
    }

    static func light() {
        guard hapticsOn else { return }
        HapticsEngine.shared.light()
    }

    static func reset() {
        guard hapticsOn else { return }
        HapticsEngine.shared.warning()
    }

    // MARK: - Milestones

    /// 33 / 66 / 99: two rising transients over a soft swell — felt as a "chime"
    /// rather than a knock, so it reads as reward and not as error.
    static func milestone(index: Int) {
        guard hapticsOn else { return }
        if soundOn { AudioServicesPlaySystemSound(1113) }

        guard let engine else {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.8)
            return
        }
        let lift = Float(min(max(Double(index) / 3.0, 0), 1))
        let events: [CHHapticEvent] = [
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35 + 0.2 * lift),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15)
            ], relativeTime: 0, duration: 0.14),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.72 + 0.2 * lift),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ], relativeTime: 0.10),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.92),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.72)
            ], relativeTime: 0.20)
        ]
        play(events)
    }

    /// Set complete — reuses the shared heartbeat so the app speaks one language.
    static func setComplete() {
        guard hapticsOn else { return }
        HapticsEngine.shared.setComplete()
    }

    /// A routine finishing: four beats that decay, like a strand being laid down.
    static func routineComplete() {
        guard hapticsOn else { return }
        guard let engine else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        }
        _ = engine
        let beats: [(TimeInterval, Float)] = [(0, 1.0), (0.13, 0.82), (0.26, 0.62), (0.44, 0.95)]
        let events = beats.map { time, intensity in
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.38)
            ], relativeTime: time)
        }
        play(events)
        if soundOn { AudioServicesPlaySystemSound(1113) }
    }

    /// One bead rolling past the finger in Tasbih mode — lighter than a tap.
    static func bead() {
        guard hapticsOn else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.45)
        if soundOn { AudioServicesPlaySystemSound(1104) }
    }

    private static func play(_ events: [CHHapticEvent]) {
        guard let engine,
              let pattern = try? CHHapticPattern(events: events, parameters: []),
              let player = try? engine.makePlayer(with: pattern) else { return }
        try? player.start(atTime: CHHapticTimeImmediate)
    }
}
