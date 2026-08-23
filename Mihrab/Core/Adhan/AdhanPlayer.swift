import AVFoundation
import Foundation

// MARK: - File store

/// Where sound files live.
///
/// Two locations, on purpose:
///
/// * **App Group container** (`AdhanSounds/`) is the canonical copy. It survives
///   app updates, is visible to the widgets extension, and is what `AVAudioPlayer`
///   and (in future) an AlarmKit custom sound read from.
/// * **`~/Library/Sounds/`** is the *only* place `UNNotificationSound(named:)`
///   looks besides the main bundle. It is not an app group, so imported and
///   generated sounds must be mirrored there or notifications fall back to the
///   default tone. We keep the mirror in sync from the canonical copy.
enum AdhanFileStore {
    /// Files shipped inside the app bundle, in `Resources/Audio`.
    /// Discovery is by extension, so dropping a new file into the folder is
    /// enough — no code change (see `Resources/Audio/README.md`).
    static let bundledExtensions = ["caf", "m4a", "wav", "aiff", "aif", "mp3"]

    /// Extensions we accept from the Files importer.
    static let importableTypes = bundledExtensions

    static var groupDirectory: URL? {
        guard let container = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: SharedPrayerCache.appGroupID)
        else { return nil }
        let url = container.appendingPathComponent("AdhanSounds", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// `~/Library/Sounds` — created on demand; iOS does not ship it.
    static var librarySoundsDirectory: URL? {
        guard let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
        else { return nil }
        let url = library.appendingPathComponent("Sounds", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Resolves a stored `fileName` to something playable, preferring the
    /// canonical app-group copy and falling back to the app bundle.
    static func playableURL(forFileName fileName: String) -> URL? {
        if let group = groupDirectory?.appendingPathComponent(fileName),
           FileManager.default.fileExists(atPath: group.path) {
            return group
        }
        let name = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        if !ext.isEmpty,
           let bundled = Bundle.main.url(forResource: name, withExtension: ext) {
            return bundled
        }
        for candidate in bundledExtensions {
            if let bundled = Bundle.main.url(forResource: name, withExtension: candidate) {
                return bundled
            }
        }
        return nil
    }

    /// Copies a file into the app group and mirrors it into `Library/Sounds`.
    /// Returns the final file name (with extension) to store in `AdhanSound`.
    @discardableResult
    static func install(from source: URL, preferredName: String) throws -> String {
        guard let groupDirectory else { throw AdhanImportError.storageUnavailable }
        let ext = source.pathExtension.isEmpty ? "caf" : source.pathExtension.lowercased()
        let fileName = "\(preferredName).\(ext)"
        let destination = groupDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: destination.path) {
            try? FileManager.default.removeItem(at: destination)
        }
        do {
            try FileManager.default.copyItem(at: source, to: destination)
        } catch {
            throw AdhanImportError.copyFailed
        }
        mirrorIntoLibrarySounds(fileName: fileName)
        return fileName
    }

    /// Keeps `Library/Sounds` in step with the canonical copy. Best-effort:
    /// a failure here only downgrades the notification tone, it never blocks.
    static func mirrorIntoLibrarySounds(fileName: String) {
        guard let source = groupDirectory?.appendingPathComponent(fileName),
              let target = librarySoundsDirectory?.appendingPathComponent(fileName),
              FileManager.default.fileExists(atPath: source.path)
        else { return }
        if FileManager.default.fileExists(atPath: target.path) {
            // Only re-copy when the source changed, to avoid needless churn.
            let sourceDate = (try? source.resourceValues(forKeys: [.contentModificationDateKey]))?
                .contentModificationDate
            let targetDate = (try? target.resourceValues(forKeys: [.contentModificationDateKey]))?
                .contentModificationDate
            if let sourceDate, let targetDate, targetDate >= sourceDate { return }
            try? FileManager.default.removeItem(at: target)
        }
        try? FileManager.default.copyItem(at: source, to: target)
    }

    static func remove(fileName: String) {
        if let group = groupDirectory?.appendingPathComponent(fileName) {
            try? FileManager.default.removeItem(at: group)
        }
        if let library = librarySoundsDirectory?.appendingPathComponent(fileName) {
            try? FileManager.default.removeItem(at: library)
        }
    }

    /// Every file currently sitting in the app group's sound folder.
    static func groupFileNames() -> [String] {
        guard let groupDirectory,
              let names = try? FileManager.default.contentsOfDirectory(atPath: groupDirectory.path)
        else { return [] }
        return names
            .filter { bundledExtensions.contains(($0 as NSString).pathExtension.lowercased()) }
            .sorted()
    }

    /// Every audio file bundled under `Resources/Audio`. Because the folder is
    /// added to the target as a resource *folder*, files land flat in the bundle
    /// (or under `Audio/` if it is a blue folder reference) — both are checked.
    static func bundledFileNames() -> [String] {
        var found: Set<String> = []
        for ext in bundledExtensions {
            for url in Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? [] {
                found.insert(url.lastPathComponent)
            }
            for url in Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "Audio") ?? [] {
                found.insert(url.lastPathComponent)
            }
        }
        return found.sorted()
    }

    /// Duration in seconds, or nil when the file is not decodable audio.
    static func duration(of url: URL) -> TimeInterval? {
        guard let file = try? AVAudioFile(forReading: url) else { return nil }
        let rate = file.processingFormat.sampleRate
        guard rate > 0 else { return nil }
        return Double(file.length) / rate
    }
}

enum AdhanImportError: LocalizedError {
    case storageUnavailable
    case copyFailed
    case notAudio
    case empty

    var errorDescription: String? {
        switch self {
        case .storageUnavailable, .copyFailed: L10n.adhImportFailedCopy
        case .notAudio: L10n.adhImportFailedFormat
        case .empty: L10n.adhImportEmpty
        }
    }
}

// MARK: - Tone synthesis

/// Royalty-free tones generated on device on first launch.
///
/// These are *not* an adhan and never pretend to be one — synthesising a human
/// call to prayer would be both dishonest and disrespectful. They are struck
/// metal timbres (bell / gong / chime): real, usable alternatives for anyone
/// who has no licensed recording to hand.
///
/// Output is 16-bit linear PCM in a CAF container at 44.1 kHz — the intersection
/// of what `UNNotificationSound` accepts and what AVAudioPlayer likes. Each is
/// kept under 30 s so it also survives the notification-sound limit intact.
enum AdhanToneSynthesizer {
    struct Recipe: Sendable {
        let id: String
        let fileBaseName: String
        /// Struck partials: (frequency ratio, amplitude, decay time constant).
        let partials: [Partial]
        /// Strike offsets in seconds.
        let strikes: [Double]
        let baseFrequency: Double
        let duration: Double

        struct Partial: Sendable {
            let ratio: Double
            let gain: Double
            let decay: Double
        }
    }

    /// Inharmonic ratios are the ones that make struck metal sound like metal
    /// rather than like a sine beep.
    static let recipes: [Recipe] = [
        Recipe(
            id: AdhanSound.toneBrassBellID,
            fileBaseName: "mihrab-tone-brass-bell",
            partials: [
                .init(ratio: 0.5, gain: 0.32, decay: 3.4),
                .init(ratio: 1.0, gain: 1.00, decay: 2.8),
                .init(ratio: 2.02, gain: 0.42, decay: 1.9),
                .init(ratio: 2.76, gain: 0.28, decay: 1.3),
                .init(ratio: 5.42, gain: 0.12, decay: 0.7),
            ],
            strikes: [0, 3.6, 7.2],
            baseFrequency: 392,
            duration: 11.5
        ),
        Recipe(
            id: AdhanSound.toneGongID,
            fileBaseName: "mihrab-tone-gong",
            partials: [
                .init(ratio: 0.5, gain: 0.50, decay: 6.0),
                .init(ratio: 1.0, gain: 0.90, decay: 5.2),
                .init(ratio: 1.48, gain: 0.36, decay: 3.4),
                .init(ratio: 2.34, gain: 0.22, decay: 2.1),
                .init(ratio: 3.91, gain: 0.10, decay: 1.1),
            ],
            strikes: [0, 5.5],
            baseFrequency: 146.8,
            duration: 12.0
        ),
        Recipe(
            id: AdhanSound.toneDawnChimeID,
            fileBaseName: "mihrab-tone-dawn-chime",
            partials: [
                .init(ratio: 1.0, gain: 0.85, decay: 2.2),
                .init(ratio: 2.0, gain: 0.30, decay: 1.4),
                .init(ratio: 3.0, gain: 0.14, decay: 0.9),
                .init(ratio: 4.16, gain: 0.07, decay: 0.5),
            ],
            // A gentle rising third-fifth-octave figure, then a settling repeat.
            strikes: [0, 0.55, 1.15, 4.2, 4.75, 5.35],
            baseFrequency: 523.25,
            duration: 9.5
        ),
    ]

    /// Writes any missing tone files. Cheap and idempotent — safe to call on
    /// every launch. Runs off the main actor; each file takes a few ms.
    static func ensureGenerated() {
        for recipe in recipes {
            let fileName = "\(recipe.fileBaseName).caf"
            let exists = AdhanFileStore.groupDirectory
                .map { FileManager.default.fileExists(atPath: $0.appendingPathComponent(fileName).path) }
                ?? false
            if !exists {
                try? render(recipe, fileName: fileName)
            }
            AdhanFileStore.mirrorIntoLibrarySounds(fileName: fileName)
        }
    }

    static func fileName(for recipe: Recipe) -> String { "\(recipe.fileBaseName).caf" }

    private static func render(_ recipe: Recipe, fileName: String) throws {
        guard let directory = AdhanFileStore.groupDirectory else {
            throw AdhanImportError.storageUnavailable
        }
        let url = directory.appendingPathComponent(fileName)
        let sampleRate = 44_100.0

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false,
        ]
        let file = try AVAudioFile(
            forWriting: url,
            settings: settings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )

        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ) else { throw AdhanImportError.copyFailed }

        let chunkFrames: AVAudioFrameCount = 8_192
        let totalFrames = Int(recipe.duration * sampleRate)
        var written = 0

        while written < totalFrames {
            let frames = min(Int(chunkFrames), totalFrames - written)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames)),
                  let channel = buffer.floatChannelData?[0]
            else { throw AdhanImportError.copyFailed }
            buffer.frameLength = AVAudioFrameCount(frames)

            for index in 0..<frames {
                let t = Double(written + index) / sampleRate
                channel[index] = Float(sample(recipe, at: t))
            }
            try file.write(from: buffer)
            written += frames
        }
    }

    /// One sample of the struck-metal model, summed over every strike that has
    /// already happened. Amplitude is kept at 0.82 peak so the 16-bit render
    /// never clips when several strikes overlap.
    private static func sample(_ recipe: Recipe, at time: Double) -> Double {
        var value = 0.0
        for (order, strike) in recipe.strikes.enumerated() where time >= strike {
            let age = time - strike
            // Successive strikes lose a little energy, like a real hand.
            let strikeGain = pow(0.86, Double(order))
            for partial in recipe.partials {
                let envelope = exp(-age / partial.decay)
                guard envelope > 0.0005 else { continue }
                // 4 ms attack removes the click a hard onset would otherwise make.
                let attack = min(1.0, age / 0.004)
                let frequency = recipe.baseFrequency * partial.ratio
                value += attack * envelope * partial.gain * strikeGain
                    * sin(2 * .pi * frequency * age)
            }
        }
        // Global fade-out over the last 350 ms so the file never ends abruptly.
        let tail = recipe.duration - time
        if tail < 0.35 { value *= max(0, tail / 0.35) }
        return max(-1, min(1, value * 0.28)) * 0.82
    }
}

// MARK: - Preview player

/// In-app auditioning of a sound.
///
/// **Silent-switch behaviour, chosen deliberately:** the session uses
/// `.playback`, which *ignores* the ring/silent switch. Someone auditioning an
/// adhan is deciding what they will hear when the phone is on silent at Fajr —
/// a preview that stayed mute would answer the wrong question. The session is
/// deactivated the moment playback ends so nothing else in the system is
/// affected, and `.duckOthers` keeps any music the user had running.
@MainActor
final class AdhanPreviewPlayer: NSObject {
    static let shared = AdhanPreviewPlayer()

    private var player: AVAudioPlayer?
    /// Called on the main actor when playback stops for any reason.
    var onStop: (() -> Void)?

    private(set) var playingFileName: String?

    func play(fileName: String, volume: Float) {
        stop()
        guard let url = AdhanFileStore.playableURL(forFileName: fileName) else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.volume = max(0, min(1, volume))
            player.prepareToPlay()
            player.play()
            self.player = player
            playingFileName = fileName
        } catch {
            deactivateSession()
            playingFileName = nil
        }
    }

    func stop() {
        player?.stop()
        player = nil
        if playingFileName != nil {
            playingFileName = nil
            deactivateSession()
            onStop?()
        }
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}

extension AdhanPreviewPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in AdhanPreviewPlayer.shared.stop() }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in AdhanPreviewPlayer.shared.stop() }
    }
}
