import Foundation
import Observation
import UserNotifications

// MARK: - Model

/// One selectable sound. Deliberately tiny and `Codable` so it can travel into
/// the App Group, into alarm metadata and into widget code untouched.
///
/// `fileName` is `nil` for the two synthetic entries (silent, system default);
/// everything else names a file resolvable via `AdhanFileStore.playableURL`.
struct AdhanSound: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var localizedName: String
    var fileName: String?

    init(id: String, localizedName: String, fileName: String?) {
        self.id = id
        self.localizedName = localizedName
        self.fileName = fileName
    }

    // MARK: Well-known identifiers

    static let silentID = "silent"
    static let systemID = "system"
    static let toneBrassBellID = "tone.brassBell"
    static let toneGongID = "tone.gong"
    static let toneDawnChimeID = "tone.dawnChime"

    static let bundledPrefix = "bundled."
    static let importedPrefix = "imported."

    static var silent: AdhanSound {
        AdhanSound(id: silentID, localizedName: L10n.adhSoundSilent, fileName: nil)
    }

    static var system: AdhanSound {
        AdhanSound(id: systemID, localizedName: L10n.adhSoundSystem, fileName: nil)
    }

    /// True when the user asked for vibration only.
    var isSilent: Bool { id == Self.silentID }

    /// User-supplied files can be deleted; built-ins cannot.
    var isRemovable: Bool { id.hasPrefix(Self.importedPrefix) }

    /// The notification sound iOS should use. Files must be reachable from the
    /// main bundle or `~/Library/Sounds` — `AdhanFileStore` mirrors them there.
    /// Silent returns `nil`: the caller then leaves `content.sound` unset, which
    /// gives a vibration-only alert.
    var notificationSound: UNNotificationSound? {
        if isSilent { return nil }
        guard let fileName else { return .default }
        return UNNotificationSound(named: UNNotificationSoundName(rawValue: fileName))
    }
}

// MARK: - Preferences

/// Adhan + reminder preferences.
///
/// Kept out of `AppSettings` on purpose: that type is shared by every agent and
/// this wave adds a dozen keys. Storage is the App Group suite so the widgets
/// extension can read the reminder mode, with `.standard` as the fallback.
@MainActor
@Observable
final class ReminderPreferences {
    static let shared = ReminderPreferences()

    /// Which mechanism owns the *prayer-time* alert. Exactly one of them fires
    /// for a given prayer — see `AlarmScheduler.effectiveMode`.
    enum Mode: String, CaseIterable, Identifiable, Sendable {
        /// AlarmKit: full-length adhan, pierces Silent and Focus.
        case alarm
        /// Classic `UNUserNotificationCenter`, capped at 30 s of sound.
        case notification

        var id: String { rawValue }

        var localizedName: String {
            switch self {
            case .alarm: L10n.ntfModeAlarm
            case .notification: L10n.ntfModeNotification
            }
        }
    }

    private let defaults: UserDefaults

    private init() {
        defaults = UserDefaults(suiteName: SharedPrayerCache.appGroupID) ?? .standard
    }

    /// Test seam.
    init(defaults: UserDefaults) { self.defaults = defaults }

    // MARK: Mode

    var preferredMode: Mode {
        get { Mode(rawValue: defaults.string(forKey: Key.mode) ?? "") ?? .alarm }
        set { defaults.set(newValue.rawValue, forKey: Key.mode) }
    }

    // MARK: Sounds

    var defaultSoundID: String {
        get { defaults.string(forKey: Key.defaultSound) ?? AdhanSound.toneBrassBellID }
        set { defaults.set(newValue, forKey: Key.defaultSound) }
    }

    /// `prayer.rawValue → sound id`. Absent means "use the default".
    var perPrayerSoundIDs: [String: String] {
        get { defaults.dictionary(forKey: Key.perPrayerSound) as? [String: String] ?? [:] }
        set { defaults.set(newValue, forKey: Key.perPrayerSound) }
    }

    var usesSameSoundEverywhere: Bool { perPrayerSoundIDs.isEmpty }

    var previewVolume: Double {
        get { defaults.object(forKey: Key.volume) as? Double ?? 0.8 }
        set { defaults.set(max(0, min(1, newValue)), forKey: Key.volume) }
    }

    /// Sounds the user imported from Files, newest last.
    var importedSounds: [AdhanSound] {
        get {
            guard let data = defaults.data(forKey: Key.imported),
                  let decoded = try? JSONDecoder().decode([AdhanSound].self, from: data)
            else { return [] }
            return decoded
        }
        set {
            defaults.set(try? JSONEncoder().encode(newValue), forKey: Key.imported)
        }
    }

    // MARK: Extras

    /// 0 means "no heads-up".
    var preReminderMinutes: Int {
        get { defaults.object(forKey: Key.preReminder) as? Int ?? 0 }
        set { defaults.set(newValue, forKey: Key.preReminder) }
    }

    var jumuahEnabled: Bool {
        get { defaults.object(forKey: Key.jumuah) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.jumuah) }
    }

    var dailyHadithEnabled: Bool {
        get { defaults.object(forKey: Key.hadith) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.hadith) }
    }

    var religiousDaysEnabled: Bool {
        get { defaults.object(forKey: Key.religious) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.religious) }
    }

    var karahatEnabled: Bool {
        get { defaults.object(forKey: Key.karahat) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Key.karahat) }
    }

    // MARK: Quiet hours

    var quietHoursEnabled: Bool {
        get { defaults.bool(forKey: Key.quiet) }
        set { defaults.set(newValue, forKey: Key.quiet) }
    }

    var quietStartHour: Int {
        get { defaults.object(forKey: Key.quietStart) as? Int ?? 23 }
        set { defaults.set(max(0, min(23, newValue)), forKey: Key.quietStart) }
    }

    var quietEndHour: Int {
        get { defaults.object(forKey: Key.quietEnd) as? Int ?? 7 }
        set { defaults.set(max(0, min(23, newValue)), forKey: Key.quietEnd) }
    }

    /// Quiet hours silence *extras only* — never the call to prayer itself.
    func isQuiet(_ date: Date, calendar: Calendar = .current) -> Bool {
        guard quietHoursEnabled else { return false }
        let hour = calendar.component(.hour, from: date)
        if quietStartHour == quietEndHour { return false }
        if quietStartHour < quietEndHour {
            return hour >= quietStartHour && hour < quietEndHour
        }
        // Wraps midnight.
        return hour >= quietStartHour || hour < quietEndHour
    }

    private enum Key {
        static let mode = "reminder.mode"
        static let defaultSound = "adhan.defaultSoundID"
        static let perPrayerSound = "adhan.perPrayerSoundIDs"
        static let volume = "adhan.previewVolume"
        static let imported = "adhan.importedSounds"
        static let preReminder = "notif.preReminderMinutes"
        static let jumuah = "notif.jumuahEnabled"
        static let hadith = "notif.dailyHadithEnabled"
        static let religious = "notif.religiousDaysEnabled"
        static let karahat = "notif.karahatEnabled"
        static let quiet = "notif.quietHoursEnabled"
        static let quietStart = "notif.quietStartHour"
        static let quietEnd = "notif.quietEndHour"
    }
}

// MARK: - Library

/// The catalogue of selectable sounds and the per-prayer assignment.
///
/// Discovery is entirely data-driven: anything the owner drops into
/// `Mihrab/Resources/Audio/` shows up here on the next launch with no code
/// change (see that folder's README for the naming convention).
@MainActor
@Observable
final class AdhanLibrary {
    static let shared = AdhanLibrary()

    private let preferences: ReminderPreferences

    /// Non-nil while a preview is audible, so rows can show a stop button.
    private(set) var previewingSoundID: String?

    /// Set when an import fails or succeeds with a caveat; the settings section
    /// surfaces it and clears it.
    var lastImportMessage: String?

    private(set) var available: [AdhanSound] = []

    init(preferences: ReminderPreferences = .shared) {
        self.preferences = preferences
        reload()
        AdhanPreviewPlayer.shared.onStop = { [weak self] in
            self?.previewingSoundID = nil
        }
    }

    /// Generates the built-in tones (once) and rebuilds the catalogue.
    /// Safe to call repeatedly; synthesis happens off the main actor.
    func prepare() {
        Task.detached(priority: .utility) {
            AdhanToneSynthesizer.ensureGenerated()
            await MainActor.run { AdhanLibrary.shared.reload() }
        }
    }

    func reload() {
        var sounds: [AdhanSound] = [.silent, .system]

        // 1. Generated, royalty-free tones.
        for recipe in AdhanToneSynthesizer.recipes {
            let fileName = AdhanToneSynthesizer.fileName(for: recipe)
            // Only offer a tone once its file actually exists on disk.
            guard AdhanFileStore.playableURL(forFileName: fileName) != nil else { continue }
            sounds.append(AdhanSound(
                id: recipe.id,
                localizedName: Self.toneName(for: recipe.id),
                fileName: fileName
            ))
        }

        // 2. Anything bundled under Resources/Audio — zero-code discovery.
        for fileName in AdhanFileStore.bundledFileNames() {
            guard !fileName.hasPrefix("mihrab-tone-") else { continue }
            let base = (fileName as NSString).deletingPathExtension
            sounds.append(AdhanSound(
                id: AdhanSound.bundledPrefix + base,
                localizedName: Self.displayName(fromFileBaseName: base),
                fileName: fileName
            ))
        }

        // 3. User imports, minus any whose file has gone missing.
        var imported = preferences.importedSounds
        let onDisk = Set(AdhanFileStore.groupFileNames())
        let survivors = imported.filter { sound in
            guard let fileName = sound.fileName else { return false }
            return onDisk.contains(fileName)
        }
        if survivors.count != imported.count {
            imported = survivors
            preferences.importedSounds = survivors
        }
        sounds.append(contentsOf: survivors)

        available = sounds
    }

    // MARK: Assignment

    func sound(for prayer: Prayer) -> AdhanSound {
        let id = preferences.perPrayerSoundIDs[prayer.rawValue] ?? preferences.defaultSoundID
        return sound(withID: id) ?? sound(withID: preferences.defaultSoundID) ?? .system
    }

    func sound(withID id: String) -> AdhanSound? {
        available.first { $0.id == id }
    }

    /// `prayer == nil` sets the sound for every prayer and clears the overrides.
    func setSound(_ sound: AdhanSound, for prayer: Prayer?) {
        guard let prayer else {
            preferences.defaultSoundID = sound.id
            preferences.perPrayerSoundIDs = [:]
            return
        }
        var map = preferences.perPrayerSoundIDs
        map[prayer.rawValue] = sound.id
        preferences.perPrayerSoundIDs = map
    }

    /// Drops the per-prayer override, falling back to the shared default.
    func clearOverride(for prayer: Prayer) {
        var map = preferences.perPrayerSoundIDs
        map.removeValue(forKey: prayer.rawValue)
        preferences.perPrayerSoundIDs = map
    }

    var defaultSound: AdhanSound {
        sound(withID: preferences.defaultSoundID) ?? .system
    }

    func hasOverride(for prayer: Prayer) -> Bool {
        preferences.perPrayerSoundIDs[prayer.rawValue] != nil
    }

    // MARK: Preview

    func preview(_ sound: AdhanSound) {
        guard let fileName = sound.fileName else {
            // Silent / system default have nothing to audition.
            stopPreview()
            if !sound.isSilent { HapticsEngine.shared.light() }
            return
        }
        previewingSoundID = sound.id
        AdhanPreviewPlayer.shared.play(fileName: fileName, volume: Float(preferences.previewVolume))
    }

    func stopPreview() {
        AdhanPreviewPlayer.shared.stop()
        previewingSoundID = nil
    }

    // MARK: Import

    /// Copies a user-picked file into the App Group (and `Library/Sounds`),
    /// validating that it is decodable audio first.
    @discardableResult
    func importSound(from url: URL) throws -> AdhanSound {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        guard let duration = AdhanFileStore.duration(of: url) else {
            throw AdhanImportError.notAudio
        }
        guard duration > 0.2 else { throw AdhanImportError.empty }

        let identifier = UUID().uuidString
        let fileName = try AdhanFileStore.install(
            from: url,
            preferredName: "imported-\(identifier)"
        )

        let sound = AdhanSound(
            id: AdhanSound.importedPrefix + identifier,
            localizedName: Self.displayName(fromFileBaseName: url.deletingPathExtension().lastPathComponent),
            fileName: fileName
        )
        preferences.importedSounds.append(sound)
        reload()

        // AlarmKit plays the file whole; a notification's sound stops at 30 s.
        // Say so rather than letting people discover it at Fajr.
        if duration > 30 {
            lastImportMessage = L10n.adhImportedTrimWarning(Int(duration.rounded()))
        }
        return sound
    }

    func remove(_ sound: AdhanSound) {
        guard sound.isRemovable, let fileName = sound.fileName else { return }
        AdhanFileStore.remove(fileName: fileName)
        preferences.importedSounds.removeAll { $0.id == sound.id }

        // Anything pointing at the deleted file falls back to the first tone.
        let fallback = AdhanToneSynthesizer.recipes.first?.id ?? AdhanSound.systemID
        if preferences.defaultSoundID == sound.id { preferences.defaultSoundID = fallback }
        preferences.perPrayerSoundIDs = preferences.perPrayerSoundIDs
            .filter { $0.value != sound.id }
        reload()
    }

    // MARK: Naming

    private static func toneName(for id: String) -> String {
        switch id {
        case AdhanSound.toneBrassBellID: L10n.adhToneBrassBell
        case AdhanSound.toneGongID: L10n.adhToneGong
        case AdhanSound.toneDawnChimeID: L10n.adhToneDawnChime
        default: id
        }
    }

    /// `mishary-fajr` → "Mishary Fajr". Recordings the owner drops in are named
    /// by hand, so the file name *is* the label.
    static func displayName(fromFileBaseName base: String) -> String {
        let cleaned = base
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else { return base }
        return cleaned
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
