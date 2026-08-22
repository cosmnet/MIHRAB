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

    var themeMode: ThemeMode {
        get { ThemeMode(rawValue: defaults.string(forKey: Key.theme) ?? "") ?? .auto }
        set { defaults.set(newValue.rawValue, forKey: Key.theme) }
    }

    var ramadanThemeEnabled: Bool {
        get { defaults.object(forKey: Key.ramadanTheme) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.ramadanTheme) }
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
        static let dhikrGoal = "dailyDhikrGoal"
        static let onboarded = "hasCompletedOnboarding"
        static let userName = "userName"
    }
}
