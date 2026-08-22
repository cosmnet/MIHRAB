import CoreHaptics
import UIKit

/// Central haptics engine per §2.6. No-ops gracefully when Core Haptics
/// is unavailable, falling back to UIKit feedback generators.
@MainActor
final class HapticsEngine {
    static let shared = HapticsEngine()

    private var engine: CHHapticEngine?
    private var supportsHaptics = false

    private init() {
        prepare()
    }

    func prepare() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        guard supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            engine?.resetHandler = { [weak self] in try? self?.engine?.start() }
        } catch {
            supportsHaptics = false
        }
    }

    func dhikrTap(progress: Double = 0.3) {
        let clamped = min(max(progress, 0), 1)
        let intensity = 0.42 + 0.5 * clamped
        let style: UIImpactFeedbackGenerator.FeedbackStyle = clamped > 0.88 ? .rigid : .soft
        UIImpactFeedbackGenerator(style: style).impactOccurred(intensity: intensity)
    }

    func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func compassTick() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.35)
    }

    /// "Heartbeat triple-pulse" for completing a dhikr set (33/99/100).
    func setComplete() {
        success()
        guard supportsHaptics, let engine else { return }
        let pulses: [CHHapticEvent] = [0, 0.15, 0.3].map { t in
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4),
                ],
                relativeTime: t
            )
        }
        if let pattern = try? CHHapticPattern(events: pulses, parameters: []),
           let player = try? engine.makePlayer(with: pattern) {
            try? player.start(atTime: CHHapticTimeImmediate)
        }
    }

    func qiblaLockOn() {
        success()
        guard supportsHaptics, let engine else { return }
        let events: [CHHapticEvent] = [
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.45),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2),
            ], relativeTime: 0, duration: 0.35),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6),
            ], relativeTime: 0.38),
        ]
        if let pattern = try? CHHapticPattern(events: events, parameters: []),
           let player = try? engine.makePlayer(with: pattern) {
            try? player.start(atTime: CHHapticTimeImmediate)
        }
    }
}
