import AVFoundation
import AudioToolbox
import CoreHaptics
import QuartzCore
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

        guard engine != nil else {
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

    // MARK: - Tasbih strand

    /// The moment the thumb lands on the strand: barely there, but it tells you
    /// the beads have taken the gesture.
    static func strandGrip() {
        guard hapticsOn else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.35)
    }

    /// Minimum spacing between two bead ticks. Below roughly 20 ms the Taptic
    /// Engine cannot separate two transients and a fast run turns to mush, so a
    /// frame that crosses several beads gets *one* firmer tick rather than four
    /// that smear into a buzz.
    private static let beadTickFloor: TimeInterval = 0.022
    private static var lastBeadTick: TimeInterval = 0

    /// One piece of the strand going under the thumb.
    ///
    /// - Parameters:
    ///   - beads: countable beads that crossed in this frame.
    ///   - passedDurak: a separator disc crossed — a third of the round.
    ///   - passedImame: the terminal bead crossed — a whole round.
    ///   - speed: 0…1 how fast the strand is running. Faster runs tick lighter
    ///     and sharper, the way real beads do when they are flying.
    static func strandPass(beads: Int, passedDurak: Bool, passedImame: Bool, speed: Double) {
        let now = CACurrentMediaTime()
        let landmark = passedImame || passedDurak
        // A landmark always speaks; a plain bead waits its turn.
        guard landmark || now - lastBeadTick >= beadTickFloor else { return }
        lastBeadTick = now

        let material = DhikrStore.shared.tasbihMaterial
        if DhikrStore.shared.beadSoundEnabled {
            TasbihClickSynth.shared.click(
                material: material,
                gain: landmark ? 1.0 : Float(0.55 + 0.25 * (1 - speed)),
                pitchRatio: passedImame ? 0.72 : (passedDurak ? 0.85 : 1.0)
            )
        }

        guard hapticsOn else { return }

        if landmark {
            // Fuller: a short body under the click, so a durak or the imame is
            // unmistakably *not* another bead.
            let events = [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: passedImame ? 1.0 : 0.85),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.45)
                ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticContinuous, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: passedImame ? 0.55 : 0.38),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.20)
                ], relativeTime: 0.012, duration: passedImame ? 0.13 : 0.08)
            ]
            if engine != nil {
                play(events)
            } else {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 0.9)
            }
            return
        }

        // Dry and single. Several beads in one frame make it firmer, never
        // repeated — that is what "a handful just went by" feels like.
        let crowd = min(Double(max(beads, 1) - 1) / 3.0, 1)
        let intensity = Float(min(0.42 + 0.30 * crowd + 0.14 * speed, 1.0))
        let sharpness = Float(min(0.62 + 0.30 * speed, 1.0))
        if engine != nil {
            play([
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ], relativeTime: 0)
            ])
        } else {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: CGFloat(intensity))
        }
    }

    /// One bead rolling past the finger — the plain, un-throttled version, kept
    /// for callers outside the strand.
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

// MARK: - Bead click

/// The sound of a bead going by, synthesised from scratch.
///
/// The recipe is the same struck-body model `AdhanToneFactory` uses for the
/// generated adhan tones — a handful of decaying partials over a very short
/// noise transient — only three orders of magnitude shorter. Nothing is
/// sampled, recorded or licensed; the whole click is arithmetic, so it costs a
/// few kilobytes of buffer and no rights at all.
///
/// **Silent-switch behaviour, chosen deliberately:** the session is `.ambient`
/// with `.mixWithOthers`, the opposite of the adhan's `.playback`. A bead click
/// is decoration. It must never talk over someone's Qur'an recitation and it
/// must go quiet when the phone is switched to silent.
@MainActor
final class TasbihClickSynth {
    static let shared = TasbihClickSynth()

    private let engine = AVAudioEngine()
    /// Four voices in rotation so a fast run overlaps instead of cutting itself
    /// off — one node can only queue buffers, never layer them.
    private var players: [AVAudioPlayerNode] = []
    private var nextVoice = 0
    private var buffers: [TasbihMaterial: AVAudioPCMBuffer] = [:]
    private var running = false

    private static let sampleRate = 44_100.0
    private static let duration = 0.09

    private init() {}

    /// Builds the buffers and starts the engine. Idempotent, and cheap enough
    /// to call whenever the strand appears.
    func prepare() {
        guard !running else { return }
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Self.sampleRate,
            channels: 1,
            interleaved: false
        ) else { return }

        if players.isEmpty {
            for _ in 0..<4 {
                let player = AVAudioPlayerNode()
                engine.attach(player)
                engine.connect(player, to: engine.mainMixerNode, format: format)
                players.append(player)
            }
        }
        if buffers.isEmpty {
            for material in TasbihMaterial.allCases {
                buffers[material] = Self.render(material, format: format)
            }
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])
            try engine.start()
            players.forEach { $0.play() }
            running = true
        } catch {
            running = false
        }
    }

    /// Releases the audio session again — the strand is not on screen, so
    /// nothing should be holding the route open.
    func shutdown() {
        guard running else { return }
        players.forEach { $0.stop() }
        engine.stop()
        running = false
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    /// - Parameters:
    ///   - gain: 0…1 loudness for this click.
    ///   - pitchRatio: below 1 for the heavier pieces — the durak and the imame
    ///     are bigger, so they ring lower.
    func click(material: TasbihMaterial, gain: Float, pitchRatio: Double) {
        prepare()
        guard running, !players.isEmpty else { return }

        // The pitch shift is baked per request rather than run through a unit:
        // playing the buffer at a scaled sample rate is a resample, which is
        // exactly what a smaller or larger piece of the same material does.
        guard let source = buffers[material] else { return }
        let buffer = pitchRatio == 1.0 ? source : Self.resampled(source, ratio: pitchRatio)

        let player = players[nextVoice]
        nextVoice = (nextVoice + 1) % players.count
        player.volume = min(max(gain, 0), 1) * 0.7
        player.scheduleBuffer(buffer, at: nil, options: [.interrupts], completionHandler: nil)
    }

    // MARK: Synthesis

    private static func render(_ material: TasbihMaterial, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frames = Int(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames)),
              let channel = buffer.floatChannelData?[0]
        else { return nil }
        buffer.frameLength = AVAudioFrameCount(frames)

        let f0 = material.clickFrequency
        let decay = material.clickDecay
        // Inharmonic partials: a bead is a sphere with a hole through it, not a
        // string, so the overtones do not line up on whole multiples.
        let partials: [(ratio: Double, gain: Double, decay: Double)] = [
            (1.00, 1.00, decay),
            (1.83, 0.45, decay * 0.62),
            (2.71, 0.24, decay * 0.40),
            (4.19, 0.11, decay * 0.24),
        ]
        // Deterministic pseudo-noise for the transient — no RNG, so every
        // render of the app produces exactly the same click.
        func noise(_ index: Int) -> Double {
            let x = sin(Double(index) * 12.9898 + 78.233) * 43_758.5453
            return (x - x.rounded(.down)) * 2 - 1
        }

        for index in 0..<frames {
            let t = Double(index) / sampleRate
            // 1.2 ms attack: fast enough to read as a click, slow enough not to
            // put a DC step into the speaker.
            let attack = min(1.0, t / 0.0012)
            var value = 0.0
            for partial in partials {
                let envelope = exp(-t / partial.decay)
                guard envelope > 0.0005 else { continue }
                value += envelope * partial.gain * sin(2 * .pi * f0 * partial.ratio * t)
            }
            // The scrape of the cord: a 4 ms noise burst under the tone.
            value += noise(index) * exp(-t / 0.004) * 0.22
            // Fade the tail so the buffer never ends on a step.
            let tail = duration - t
            let close = tail < 0.006 ? max(0, tail / 0.006) : 1
            channel[index] = Float(max(-1, min(1, value * attack * close * 0.34)))
        }
        return buffer
    }

    /// Linear resample — good enough for a 90 ms click, and it keeps the whole
    /// thing free of AVAudioUnit setup.
    private static func resampled(_ source: AVAudioPCMBuffer, ratio: Double) -> AVAudioPCMBuffer {
        let sourceFrames = Int(source.frameLength)
        let targetFrames = max(Int(Double(sourceFrames) / max(ratio, 0.1)), 1)
        guard let out = AVAudioPCMBuffer(
            pcmFormat: source.format,
            frameCapacity: AVAudioFrameCount(targetFrames)
        ),
            let src = source.floatChannelData?[0],
            let dst = out.floatChannelData?[0]
        else { return source }
        out.frameLength = AVAudioFrameCount(targetFrames)

        for index in 0..<targetFrames {
            let position = Double(index) * ratio
            let low = Int(position)
            guard low < sourceFrames - 1 else {
                dst[index] = 0
                continue
            }
            let fraction = Float(position - Double(low))
            dst[index] = src[low] * (1 - fraction) + src[low + 1] * fraction
        }
        return out
    }
}
