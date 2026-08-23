import Foundation
import SwiftUI

/// User preferences, persisted in the App Group so widgets read the same config.
@Observable
final class AppSettings: @unchecked Sendable {
    static let shared = AppSettings()

    private let defaults: UserDefaults
    private let groupDefaults = UserDefaults(suiteName: SharedPrayerCache.appGroupID)

    /// Stored so `@Observable` notifies RootView / onboarding (UserDefaults getters do not).
    var calculationMethod: CalculationMethod {
        didSet { persistMethod() }
    }

    var madhab: Madhab {
        didSet { defaults.set(madhab.rawValue, forKey: Key.madhab) }
    }

    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Key.onboarded) }
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let turkish = Self.prefersTurkishDefaults

        if let raw = defaults.object(forKey: Key.method) as? Int,
           let method = CalculationMethod(rawValue: raw) {
            calculationMethod = method
        } else {
            calculationMethod = turkish ? .diyanet : .mwl
        }

        // `integer(forKey:)` is 0 when unset — that is Shafi, not "no value".
        if defaults.object(forKey: Key.madhab) != nil,
           let value = Madhab(rawValue: defaults.integer(forKey: Key.madhab)) {
            madhab = value
        } else {
            madhab = turkish ? .hanafi : .shafi
        }

        hasCompletedOnboarding = defaults.bool(forKey: Key.onboarded)

        dhikrShaderStyle = ShaderStyle(rawValue: defaults.string(forKey: Key.dhikrShader) ?? "") ?? .silk
        accentTheme = AccentTheme(rawValue: defaults.string(forKey: Key.accentTheme) ?? "") ?? .emerald
        shadersEverywhere = defaults.object(forKey: Key.shadersEverywhere) as? Bool ?? true
        backdropIntensity = BackdropIntensity(rawValue: defaults.string(forKey: Key.backdropIntensity) ?? "") ?? .calm
        cardTextureEnabled = defaults.object(forKey: Key.cardTexture) as? Bool ?? true

        if defaults.object(forKey: Key.method) == nil { persistMethod() }
        if defaults.object(forKey: Key.madhab) == nil {
            defaults.set(madhab.rawValue, forKey: Key.madhab)
        }
    }

    private static var prefersTurkishDefaults: Bool {
        if Locale.autoupdatingCurrent.language.languageCode?.identifier == "tr" { return true }
        if Locale.autoupdatingCurrent.region?.identifier == "TR" { return true }
        if Locale.preferredLanguages.contains(where: { $0.hasPrefix("tr") }) { return true }
        return false
    }

    private func persistMethod() {
        defaults.set(calculationMethod.rawValue, forKey: Key.method)
        groupDefaults?.set(calculationMethod.rawValue, forKey: Key.method)
    }

    // MARK: - Prayer

    var disabledPrayerNotifications: Set<Prayer> {
        get {
            let raw = defaults.stringArray(forKey: Key.disabledNotifications) ?? []
            return Set(raw.compactMap(Prayer.init(rawValue:)))
        }
        set { defaults.set(newValue.map(\.rawValue), forKey: Key.disabledNotifications) }
    }

    func isNotificationEnabled(for prayer: Prayer) -> Bool {
        !disabledPrayerNotifications.contains(prayer)
    }

    func toggleNotification(for prayer: Prayer) {
        var set = disabledPrayerNotifications
        if set.contains(prayer) { set.remove(prayer) } else { set.insert(prayer) }
        disabledPrayerNotifications = set
    }

    // MARK: - Location

    var manualCityName: String? {
        get { defaults.string(forKey: Key.manualCity) }
        set { defaults.set(newValue, forKey: Key.manualCity) }
    }

    var manualLatitude: Double? {
        get { defaults.object(forKey: Key.manualLat) as? Double }
        set { defaults.set(newValue, forKey: Key.manualLat) }
    }

    var manualLongitude: Double? {
        get { defaults.object(forKey: Key.manualLon) as? Double }
        set { defaults.set(newValue, forKey: Key.manualLon) }
    }

    // MARK: - Appearance

    enum ThemeMode: String, CaseIterable, Identifiable {
        case auto, dark, light
        var id: String { rawValue }
    }

    enum AccentTheme: String, CaseIterable, Identifiable {
        case emerald, brass, violet
        var id: String { rawValue }

        var color: Color {
            switch self {
            case .emerald: MihrabColor.emerald
            case .brass: MihrabColor.brass
            case .violet: Color(hex: 0x8F7AE0)
            }
        }

        var secondary: Color {
            switch self {
            case .emerald: MihrabColor.mint
            case .brass: MihrabColor.sprout
            case .violet: Color(hex: 0xC5B8F0)
            }
        }

        var localizedName: String {
            switch self {
            case .emerald: L10n.accentEmerald
            case .brass: L10n.accentBrass
            case .violet: L10n.accentViolet
            }
        }
    }

    var themeMode: ThemeMode {
        get { ThemeMode(rawValue: defaults.string(forKey: Key.theme) ?? "") ?? .auto }
        set { defaults.set(newValue.rawValue, forKey: Key.theme) }
    }

    var ramadanThemeEnabled: Bool {
        get { defaults.object(forKey: Key.ramadanTheme) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.ramadanTheme) }
    }

    var dhikrShaderStyle: ShaderStyle {
        didSet { defaults.set(dhikrShaderStyle.rawValue, forKey: Key.dhikrShader) }
    }

    var accentTheme: AccentTheme {
        didSet { defaults.set(accentTheme.rawValue, forKey: Key.accentTheme) }
    }

    /// Legacy switch: "paint the shader on every screen". Superseded by
    /// `backdropIntensity` + `cardTextureEnabled`, kept so nothing breaks.
    var shadersEverywhere: Bool {
        didSet { defaults.set(shadersEverywhere, forKey: Key.shadersEverywhere) }
    }

    /// How much life the *calm* backdrops are allowed to show. The counter
    /// screen ignores this — it always runs its full-screen motif.
    enum BackdropIntensity: String, CaseIterable, Identifiable {
        case calm, standard, vivid

        var id: String { rawValue }

        var localizedName: String {
            switch self {
            case .calm: L10n.apprIntensityCalm
            case .standard: L10n.apprIntensityStandard
            case .vivid: L10n.apprIntensityVivid
            }
        }

        /// Multiplier on every glow's opacity. Capped downstream at 0.34 so
        /// even `.vivid` cannot produce a pattern that fights type.
        var glowScale: Double {
            switch self {
            case .calm: 1.0
            case .standard: 1.35
            case .vivid: 1.75
            }
        }

        /// How far the washes travel.
        var driftScale: CGFloat {
            switch self {
            case .calm: 0.7
            case .standard: 1.0
            case .vivid: 1.4
            }
        }

        /// Multiplier on the drift period — calm breathes slowest.
        var periodScale: Double {
            switch self {
            case .calm: 1.3
            case .standard: 1.0
            case .vivid: 0.75
            }
        }
    }

    var backdropIntensity: BackdropIntensity {
        didSet { defaults.set(backdropIntensity.rawValue, forKey: Key.backdropIntensity) }
    }

    /// Slow shader texture inside cards (`mihrabShaderPanel`).
    var cardTextureEnabled: Bool {
        didSet { defaults.set(cardTextureEnabled, forKey: Key.cardTexture) }
    }

    /// The counter's full-screen motif. Backed by `dhikrShaderStyle` so the two
    /// can never drift apart.
    var dhikrShaderMotif: ShaderMotif {
        get { dhikrShaderStyle.resolvedMotif }
        set { dhikrShaderStyle = newValue.legacyStyle }
    }

    // MARK: - Dhikr

    var dailyDhikrGoal: Int {
        get { max(defaults.integer(forKey: Key.dhikrGoal), 33) }
        set { defaults.set(newValue, forKey: Key.dhikrGoal) }
    }

    var userName: String {
        get { defaults.string(forKey: Key.userName) ?? "" }
        set { defaults.set(newValue, forKey: Key.userName) }
    }

    private enum Key {
        static let method = "calculationMethod"
        static let madhab = "madhab"
        static let disabledNotifications = "disabledPrayerNotifications"
        static let manualCity = "manualCityName"
        static let manualLat = "manualLatitude"
        static let manualLon = "manualLongitude"
        static let theme = "themeMode"
        static let ramadanTheme = "ramadanThemeEnabled"
        static let dhikrShader = "dhikrShaderStyle"
        static let accentTheme = "accentTheme"
        static let shadersEverywhere = "shadersEverywhere"
        static let backdropIntensity = "backdropIntensity"
        static let cardTexture = "cardTextureEnabled"
        static let dhikrGoal = "dailyDhikrGoal"
        static let onboarded = "hasCompletedOnboarding"
        static let userName = "userName"
    }
}
