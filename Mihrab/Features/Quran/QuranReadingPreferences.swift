import SwiftUI

// MARK: - Reading mode

/// Day / night / follow-the-app. The reader is the one screen where people sit
/// for twenty minutes, so it gets its own light control instead of inheriting
/// the app's dark Emerald Glass unconditionally: reading long Arabic in white
/// on near-black at 3 a.m. is right, and doing it on a bus at noon is not.
enum QuranReadingMode: String, CaseIterable, Codable, Sendable, Identifiable {
    case night, sepia, day

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .night: L10n.quranModeNight
        case .sepia: L10n.quranModeSepia
        case .day: L10n.quranModeDay
        }
    }

    var symbolName: String {
        switch self {
        case .night: "moon.stars.fill"
        case .sepia: "book.closed.fill"
        case .day: "sun.max.fill"
        }
    }

    var background: Color {
        switch self {
        case .night: MihrabColor.abyss
        case .sepia: MihrabColor.parchment
        case .day: Color.white
        }
    }

    var ink: Color {
        switch self {
        case .night: MihrabColor.textPrimary
        case .sepia: Color(hex: 0x2A2419)
        case .day: Color(hex: 0x14191A)
        }
    }

    var secondaryInk: Color {
        switch self {
        case .night: MihrabColor.textSecondary
        case .sepia: Color(hex: 0x6E6249)
        case .day: Color(hex: 0x5A6563)
        }
    }

    /// Ayah-number medallion and rules.
    var ornament: Color {
        switch self {
        case .night: MihrabColor.brass
        case .sepia: Color(hex: 0x9A7B32)
        case .day: MihrabColor.emerald
        }
    }

    var preferredColorScheme: ColorScheme {
        self == .night ? .dark : .light
    }
}

// MARK: - Flow

/// How ayahs are laid out. Two genuinely different reading postures, not a
/// cosmetic toggle: `verse` is for study and sharing, `flowing` is for
/// recitation, where an ayah break mid-line is what the mushaf actually does.
enum QuranFlow: String, CaseIterable, Codable, Sendable, Identifiable {
    case verse, flowing

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .verse: L10n.quranFlowVerse
        case .flowing: L10n.quranFlowContinuous
        }
    }

    var symbolName: String {
        switch self {
        case .verse: "list.bullet"
        case .flowing: "text.alignright"
        }
    }
}

// MARK: - Typography theme (Plus)

/// Extra Arabic typography presets. Ornament only — the free preset is the
/// well-set default, not a crippled one. Gated with the existing
/// `PremiumFeature.themes`.
enum QuranTypeTheme: String, CaseIterable, Codable, Sendable, Identifiable {
    /// Free. Amiri Quran, generous leading, brass medallions.
    case classic
    /// Tight leading, larger ayah, no medallion fill — a mushaf page feel.
    case mushaf
    /// Wide margins, small caps captions, muted ornaments.
    case scholar

    var id: String { rawValue }

    var isPremium: Bool { self != .classic }

    var localizedName: String {
        switch self {
        case .classic: L10n.quranThemeClassic
        case .mushaf: L10n.quranThemeMushaf
        case .scholar: L10n.quranThemeScholar
        }
    }

    /// Multiplier on the user's chosen Arabic size.
    var arabicScale: CGFloat {
        switch self {
        case .classic: 1.0
        case .mushaf: 1.12
        case .scholar: 0.94
        }
    }

    /// Multiplier on the user's chosen line spacing.
    var leadingScale: CGFloat {
        switch self {
        case .classic: 1.0
        case .mushaf: 0.86
        case .scholar: 1.22
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .classic: 20
        case .mushaf: 16
        case .scholar: 30
        }
    }
}

// MARK: - Preferences

/// Everything the reader remembers about *how* you read. Lives in
/// `UserDefaults` (not SwiftData) because it is a handful of scalars that the
/// view reads on every frame.
@MainActor
@Observable
final class QuranReadingPreferences {
    static let shared = QuranReadingPreferences()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let arabicSize = "mihrab.quran.arabicSize"
        static let lineSpacing = "mihrab.quran.lineSpacing"
        static let mode = "mihrab.quran.mode"
        static let flow = "mihrab.quran.flow"
        static let theme = "mihrab.quran.theme"
        static let showTranslation = "mihrab.quran.showTranslation"
        static let translationPack = "mihrab.quran.translationPack"
        static let keepAwake = "mihrab.quran.keepAwake"
    }

    /// Base point size for the Arabic. `MihrabFont.arabic(_:)` is
    /// `relativeTo: .title`, so this scales with Dynamic Type on top.
    static let arabicSizeRange: ClosedRange<Double> = 20...52
    static let lineSpacingRange: ClosedRange<Double> = 4...28

    var arabicSize: Double {
        didSet {
            let clamped = min(max(arabicSize, Self.arabicSizeRange.lowerBound),
                              Self.arabicSizeRange.upperBound)
            if clamped != arabicSize { arabicSize = clamped; return }
            defaults.set(arabicSize, forKey: Key.arabicSize)
        }
    }

    var lineSpacing: Double {
        didSet {
            let clamped = min(max(lineSpacing, Self.lineSpacingRange.lowerBound),
                              Self.lineSpacingRange.upperBound)
            if clamped != lineSpacing { lineSpacing = clamped; return }
            defaults.set(lineSpacing, forKey: Key.lineSpacing)
        }
    }

    var mode: QuranReadingMode {
        didSet { defaults.set(mode.rawValue, forKey: Key.mode) }
    }

    var flow: QuranFlow {
        didSet { defaults.set(flow.rawValue, forKey: Key.flow) }
    }

    var theme: QuranTypeTheme {
        didSet { defaults.set(theme.rawValue, forKey: Key.theme) }
    }

    var showTranslation: Bool {
        didSet { defaults.set(showTranslation, forKey: Key.showTranslation) }
    }

    var translationPackID: String? {
        didSet { defaults.set(translationPackID, forKey: Key.translationPack) }
    }

    /// Keep the screen on while reading. Off by default — battery is not ours
    /// to spend without being asked.
    var keepAwake: Bool {
        didSet { defaults.set(keepAwake, forKey: Key.keepAwake) }
    }

    private init() {
        let storedSize = defaults.double(forKey: Key.arabicSize)
        arabicSize = storedSize > 0 ? storedSize : 30
        let storedSpacing = defaults.double(forKey: Key.lineSpacing)
        lineSpacing = storedSpacing > 0 ? storedSpacing : 14
        mode = QuranReadingMode(rawValue: defaults.string(forKey: Key.mode) ?? "") ?? .night
        flow = QuranFlow(rawValue: defaults.string(forKey: Key.flow) ?? "") ?? .verse
        theme = QuranTypeTheme(rawValue: defaults.string(forKey: Key.theme) ?? "") ?? .classic
        showTranslation = defaults.object(forKey: Key.showTranslation) as? Bool ?? true
        translationPackID = defaults.string(forKey: Key.translationPack)
            ?? TranslationPack.preferred.first?.id
        keepAwake = defaults.bool(forKey: Key.keepAwake)

        // A lapsed subscription must not leave the reader in a locked theme.
        if theme.isPremium, !PremiumEntitlement.isPremium { theme = .classic }
    }

    /// Effective Arabic font, theme multiplier applied.
    var arabicFont: Font {
        MihrabFont.arabic(arabicSize * theme.arabicScale)
    }

    var effectiveLineSpacing: CGFloat {
        lineSpacing * theme.leadingScale
    }

    /// `nil` when nothing is installed — which is the state we ship in.
    var activeTranslationPack: TranslationPack? {
        guard showTranslation, let translationPackID else { return nil }
        return TranslationPack.installed.first { $0.id == translationPackID }
    }
}
