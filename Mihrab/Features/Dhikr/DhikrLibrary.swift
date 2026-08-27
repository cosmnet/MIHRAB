import Foundation
import Observation
import SwiftUI

/// One countable phrase. Built-in entries carry a stable id whose copy lives in
/// `L10n+Dhikr`; user-made entries carry their own title, so the model is
/// `Codable` end-to-end and the same row view renders both.
struct DhikrItem: Identifiable, Hashable, Codable {
    var id: String
    var arabic: String
    var transliteration: String
    /// 0 means "free count" — no ring, no set completion.
    var target: Int
    /// Only set for user-made dhikr.
    var customTitle: String?

    var isCustom: Bool { customTitle != nil }

    var localizedName: String {
        if let customTitle, !customTitle.isEmpty { return customTitle }
        return L10n.dhkPhraseName(id)
    }

    var meaning: String { isCustom ? "" : L10n.dhkPhraseMeaning(id) }

    /// What the dial shows big. Falls back to the Latin name when the user did
    /// not supply Arabic.
    var displayScript: String { arabic.isEmpty ? localizedName : arabic }

    init(id: String, arabic: String, transliteration: String, target: Int, customTitle: String? = nil) {
        self.id = id
        self.arabic = arabic
        self.transliteration = transliteration
        self.target = target
        self.customTitle = customTitle
    }
}

/// An ordered set of phrases the counter walks through on its own — the
/// after-prayer tasbihat being the one every Turkish user already knows by heart.
struct DhikrRoutine: Identifiable, Hashable {
    var id: String
    var steps: [DhikrItem]

    var localizedTitle: String { L10n.dhkRoutineTitle(id) }
    var localizedSubtitle: String { L10n.dhkRoutineSubtitle(id) }
    var totalCount: Int { steps.reduce(0) { $0 + max($1.target, 1) } }
}

// MARK: - Catalogue

enum DhikrCatalog {

    static let subhanallah = DhikrItem(id: "subhanallah", arabic: "سُبْحَانَ اللَّه", transliteration: "Subhanallah", target: 33)
    static let alhamdulillah = DhikrItem(id: "alhamdulillah", arabic: "الْحَمْدُ لِلَّه", transliteration: "Alhamdulillah", target: 33)
    static let allahuAkbar = DhikrItem(id: "allahu-akbar", arabic: "اللَّهُ أَكْبَر", transliteration: "Allahu Akbar", target: 34)
    static let tawhid = DhikrItem(id: "la-ilaha", arabic: "لَا إِلَهَ إِلَّا اللَّه", transliteration: "La ilaha illallah", target: 33)
    static let salawat = DhikrItem(id: "salawat", arabic: "اللَّهُمَّ صَلِّ عَلَى مُحَمَّد", transliteration: "Salawat", target: 100)
    static let istighfar = DhikrItem(id: "astaghfirullah", arabic: "أَسْتَغْفِرُ اللَّه", transliteration: "Astaghfirullah", target: 100)

    /// The phrase strip on the counter — six classics, in the order they are recited.
    static let core: [DhikrItem] = [
        subhanallah,
        alhamdulillah,
        allahuAkbar,
        tawhid,
        salawat,
        istighfar
    ]

    static let extended: [DhikrItem] = [
        DhikrItem(id: "subhanallahi-bihamdihi", arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ", transliteration: "Subhanallahi wa bihamdih", target: 100),
        DhikrItem(id: "hasbunallah", arabic: "حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيل", transliteration: "Hasbunallahu wa ni'mal wakil", target: 100),
        DhikrItem(id: "la-hawla", arabic: "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّه", transliteration: "La hawla wa la quwwata illa billah", target: 100)
    ]

    /// Names of Allah that are traditionally taken as a repeated dhikr.
    static let esma: [DhikrItem] = [
        DhikrItem(id: "esma-rahman", arabic: "يَا رَحْمَٰن", transliteration: "Ya Rahman", target: 100),
        DhikrItem(id: "esma-rahim", arabic: "يَا رَحِيم", transliteration: "Ya Rahim", target: 100),
        DhikrItem(id: "esma-latif", arabic: "يَا لَطِيف", transliteration: "Ya Latif", target: 129),
        DhikrItem(id: "esma-fettah", arabic: "يَا فَتَّاح", transliteration: "Ya Fattah", target: 99),
        DhikrItem(id: "esma-shafi", arabic: "يَا شَافِي", transliteration: "Ya Shafi", target: 99),
        DhikrItem(id: "esma-hafiz", arabic: "يَا حَفِيظ", transliteration: "Ya Hafiz", target: 99),
        DhikrItem(id: "esma-vedud", arabic: "يَا وَدُود", transliteration: "Ya Wadud", target: 99),
        DhikrItem(id: "esma-rezzak", arabic: "يَا رَزَّاق", transliteration: "Ya Razzaq", target: 99),
        DhikrItem(id: "esma-sabur", arabic: "يَا صَبُور", transliteration: "Ya Sabur", target: 99)
    ]

    static let routines: [DhikrRoutine] = [
        DhikrRoutine(id: "tesbihat", steps: [
            subhanallah,
            alhamdulillah,
            allahuAkbar,
            DhikrItem(id: "tevhid", arabic: "لَا إِلَهَ إِلَّا اللَّه", transliteration: "La ilaha illallah", target: 1)
        ]),
        DhikrRoutine(id: "sabah", steps: [
            DhikrItem(id: "astaghfirullah", arabic: "أَسْتَغْفِرُ اللَّه", transliteration: "Astaghfirullah", target: 100),
            DhikrItem(id: "subhanallahi-bihamdihi", arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ", transliteration: "Subhanallahi wa bihamdih", target: 100),
            DhikrItem(id: "salawat", arabic: "اللَّهُمَّ صَلِّ عَلَى مُحَمَّد", transliteration: "Salawat", target: 100)
        ]),
        DhikrRoutine(id: "aksam", steps: [
            DhikrItem(id: "la-ilaha", arabic: "لَا إِلَهَ إِلَّا اللَّه", transliteration: "La ilaha illallah", target: 100),
            DhikrItem(id: "hasbunallah", arabic: "حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيل", transliteration: "Hasbunallahu wa ni'mal wakil", target: 70),
            DhikrItem(id: "astaghfirullah", arabic: "أَسْتَغْفِرُ اللَّه", transliteration: "Astaghfirullah", target: 33)
        ]),
        DhikrRoutine(id: "istigfar", steps: [
            DhikrItem(id: "astaghfirullah", arabic: "أَسْتَغْفِرُ اللَّه", transliteration: "Astaghfirullah", target: 100)
        ]),
        DhikrRoutine(id: "salavat", steps: [
            DhikrItem(id: "salawat", arabic: "اللَّهُمَّ صَلِّ عَلَى مُحَمَّد", transliteration: "Salawat", target: 100)
        ])
    ]

    /// Everything the search field in the library can match against.
    static var allBuiltIn: [DhikrItem] { core + extended + esma }
}

// MARK: - Tasbih materials

/// What the strand is *made of*. A real tasbih is chosen as much by the feel and
/// the sound of the material as by the count, so the choice is a stored
/// preference rather than a theme detail: amber is bright and glassy, ebony is
/// dark and dry, olive wood is warm and matte.
///
/// The colours are the material's own, not palette tokens — an amber bead that
/// borrowed the app's green would stop being amber.
enum TasbihMaterial: String, CaseIterable, Codable, Identifiable, Sendable {
    case amber
    case ebony
    case olive

    var id: String { rawValue }

    var localizedName: String { L10n.dhkMaterialName(rawValue) }

    /// Body of the bead where it is in shadow.
    var coreHex: UInt32 {
        switch self {
        case .amber: 0x8A4A0C
        case .ebony: 0x14100E
        case .olive: 0x5A431F
        }
    }

    /// Body of the bead where the light lands.
    var litHex: UInt32 {
        switch self {
        case .amber: 0xF0A93C
        case .ebony: 0x4A423C
        case .olive: 0xC29A54
        }
    }

    /// The specular pin-prick — how wet the surface looks.
    var sheenHex: UInt32 {
        switch self {
        case .amber: 0xFFE7B0
        case .ebony: 0xBFC4C0
        case .olive: 0xF2DCA8
        }
    }

    /// Rim light around the silhouette.
    var rimHex: UInt32 {
        switch self {
        case .amber: 0xFFCE7A
        case .ebony: 0x8C948E
        case .olive: 0xE0C88A
        }
    }

    /// The cord the beads are strung on.
    var cordHex: UInt32 {
        switch self {
        case .amber: 0x6B4A18
        case .ebony: 0x2A2622
        case .olive: 0x4A3A1C
        }
    }

    /// 0…1 — how glossy the highlight reads. Amber is glass, olive is oiled
    /// wood, ebony is polished but dark.
    var gloss: Double {
        switch self {
        case .amber: 0.95
        case .ebony: 0.55
        case .olive: 0.68
        }
    }

    /// Fundamental of the synthesised click, in hertz. Denser, harder material
    /// rings higher; wood is lower and dies faster.
    var clickFrequency: Double {
        switch self {
        case .amber: 1180
        case .ebony: 560
        case .olive: 820
        }
    }

    /// Seconds for the click to fall away.
    var clickDecay: Double {
        switch self {
        case .amber: 0.055
        case .ebony: 0.030
        case .olive: 0.042
        }
    }

    var next: TasbihMaterial {
        let all = Self.allCases
        let index = all.firstIndex(of: self) ?? 0
        return all[(index + 1) % all.count]
    }
}

// MARK: - Store

/// Counter preferences and user-made dhikr. Deliberately `UserDefaults` and not
/// SwiftData: the payload is tiny, non-relational, and must be readable before
/// the model container is touched. `DhikrSession` (SwiftData) stays the single
/// source of truth for *counts*; this store only holds the definitions.
@MainActor
@Observable
final class DhikrStore {
    static let shared = DhikrStore()

    private enum Key {
        static let custom = "mihrab.dhikr.custom"
        static let sound = "mihrab.dhikr.sound"
        static let haptics = "mihrab.dhikr.haptics"
        static let keepAwake = "mihrab.dhikr.keepAwake"
        static let strandDefault = "mihrab.dhikr.strandDefault"
        static let focusDim = "mihrab.dhikr.focusDim"
        static let lastPhrase = "mihrab.dhikr.lastPhrase"
        static let material = "mihrab.dhikr.tasbihMaterial"
        static let beadSound = "mihrab.dhikr.beadSound"
    }

    private let defaults: UserDefaults

    private(set) var customItems: [DhikrItem]

    var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Key.sound) }
    }

    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Key.haptics) }
    }

    /// Whether the counter holds the screen awake while a session is running.
    var keepAwakeWhileCounting: Bool {
        didSet { defaults.set(keepAwakeWhileCounting, forKey: Key.keepAwake) }
    }

    var opensInStrandMode: Bool {
        didSet { defaults.set(opensInStrandMode, forKey: Key.strandDefault) }
    }

    /// Whether focus mode also takes the display brightness down.
    var dimsInFocusMode: Bool {
        didSet { defaults.set(dimsInFocusMode, forKey: Key.focusDim) }
    }

    /// Id of the phrase the counter was last left on, so returning feels continuous.
    var lastPhraseID: String {
        didSet { defaults.set(lastPhraseID, forKey: Key.lastPhrase) }
    }

    /// What the tasbih strand is made of.
    var tasbihMaterial: TasbihMaterial {
        didSet { defaults.set(tasbihMaterial.rawValue, forKey: Key.material) }
    }

    /// The synthesised bead click. Off by default — a counting app that starts
    /// making noise on its own is a counting app people mute and stop using.
    var beadSoundEnabled: Bool {
        didSet { defaults.set(beadSoundEnabled, forKey: Key.beadSound) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        soundEnabled = defaults.object(forKey: Key.sound) as? Bool ?? false
        hapticsEnabled = defaults.object(forKey: Key.haptics) as? Bool ?? true
        keepAwakeWhileCounting = defaults.object(forKey: Key.keepAwake) as? Bool ?? true
        opensInStrandMode = defaults.object(forKey: Key.strandDefault) as? Bool ?? false
        dimsInFocusMode = defaults.object(forKey: Key.focusDim) as? Bool ?? true
        lastPhraseID = defaults.string(forKey: Key.lastPhrase) ?? DhikrCatalog.subhanallah.id
        tasbihMaterial = defaults.string(forKey: Key.material)
            .flatMap(TasbihMaterial.init(rawValue:)) ?? .amber
        beadSoundEnabled = defaults.object(forKey: Key.beadSound) as? Bool ?? false

        if let data = defaults.data(forKey: Key.custom),
           let decoded = try? JSONDecoder().decode([DhikrItem].self, from: data) {
            customItems = decoded
        } else {
            customItems = []
        }
    }

    // MARK: Custom dhikr

    @discardableResult
    func addCustom(title: String, arabic: String, target: Int) -> DhikrItem {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let item = DhikrItem(
            id: "custom-\(UUID().uuidString.prefix(8))",
            arabic: arabic.trimmingCharacters(in: .whitespacesAndNewlines),
            transliteration: trimmed,
            target: max(0, target),
            customTitle: trimmed.isEmpty ? L10n.dhkNewCustom : trimmed
        )
        customItems.append(item)
        persistCustom()
        return item
    }

    func removeCustom(_ item: DhikrItem) {
        customItems.removeAll { $0.id == item.id }
        persistCustom()
    }

    func removeCustom(at offsets: IndexSet) {
        customItems.remove(atOffsets: offsets)
        persistCustom()
    }

    private func persistCustom() {
        guard let data = try? JSONEncoder().encode(customItems) else { return }
        defaults.set(data, forKey: Key.custom)
    }

    // MARK: Lookup

    /// Every phrase the counter can show, built-ins first.
    var allItems: [DhikrItem] { DhikrCatalog.allBuiltIn + customItems }

    func item(id: String) -> DhikrItem? {
        allItems.first { $0.id == id }
    }

    /// The phrase strip: the six classics plus anything the user made.
    var stripItems: [DhikrItem] { DhikrCatalog.core + customItems }
}
