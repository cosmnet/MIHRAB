import Adhan
import Foundation

/// Which published Turkish prayer-time tradition (or plain astronomical
/// standard) the on-device engine should imitate.
///
/// Background — why this exists at all:
/// Saying "we are Diyanet-compatible" is not enough in Turkey. Two separate
/// things move the printed numbers:
///
/// 1. **Temkin** — Diyanet does not print the raw astronomical instant. It adds
///    a safety margin so that a person who prays exactly on the printed minute
///    is still inside the valid window everywhere in the city. adhan-swift's
///    `.turkey` method already carries these as method adjustments (see
///    `temkinMinutes` below; values read from adhan-swift 1.5.0
///    `Sources/Models/CalculationMethod.swift`, case `.turkey`).
/// 2. **Which twilight angle counts as fecr-i sâdık** — since the early 1980s
///    three calendar traditions coexist in Turkey (Diyanet, Fazilet Takvimi,
///    Türkiye Takvimi) and they disagree about imsak by roughly 15–20 minutes.
///
/// This enum models (2). It deliberately does **not** invent numbers it cannot
/// source: see the `⚠️ VERIFY` comments below.
public enum PrayerSource: String, CaseIterable, Identifiable, Sendable, Codable {
    /// Diyanet İşleri Başkanlığı — fajr 18°, isha 17°, with temkin.
    case diyanet
    /// Fazilet Takvimi — earlier imsak than Diyanet.
    case fazilet
    /// Türkiye Takvimi (Hakîkat Kitabevi) — earlier imsak than Diyanet.
    case turkiyeTakvimi
    /// No regional override: use the calculation method the user picked in
    /// Settings exactly as its authority publishes it.
    case standard

    public var id: String { rawValue }

    public var localizedName: String {
        switch self {
        case .diyanet: L10n.sourceDiyanet
        case .fazilet: L10n.sourceFazilet
        case .turkiyeTakvimi: L10n.sourceTurkiyeTakvimi
        case .standard: L10n.sourceStandard
        }
    }

    /// Honest, non-promotional description of what changes when this is picked.
    public var localizedExplanation: String {
        switch self {
        case .diyanet: L10n.sourceDiyanetDetail
        case .fazilet: L10n.sourceFaziletDetail
        case .turkiyeTakvimi: L10n.sourceTurkiyeTakvimiDetail
        case .standard: L10n.sourceStandardDetail
        }
    }

    /// `true` when this source is only meaningful inside Turkey.
    public var isTurkishTradition: Bool { self != .standard }

    // MARK: - Angle overrides

    /// Fajr (imsak) twilight angle this tradition uses, or `nil` to keep the
    /// angle that comes with the selected calculation method.
    ///
    /// - Diyanet: 18° — published by Diyanet and matched by adhan-swift `.turkey`.
    /// - Fazilet / Türkiye Takvimi: 19° — both traditions place fecr-i sâdık at
    ///   a deeper sun depression than Diyanet, which is the main reason their
    ///   imsak lands earlier. **⚠️ VERIFY:** 19° is the value most commonly
    ///   attributed to these calendars; it has not been checked against an
    ///   official printed table by this implementation. At Istanbul's latitude
    ///   it moves imsak roughly 8–12 minutes earlier — the traditions
    ///   themselves are usually quoted as 15–20 minutes earlier, so part of the
    ///   remaining gap is a temkin difference we do **not** model, because we
    ///   could not source a number for it. See `extraTemkinMinutes`.
    public var fajrAngleOverride: Double? {
        switch self {
        case .diyanet: 18.0
        case .fazilet: 19.0          // ⚠️ VERIFY (see doc comment)
        case .turkiyeTakvimi: 19.0   // ⚠️ VERIFY (see doc comment)
        case .standard: nil
        }
    }

    /// Isha twilight angle override, or `nil` to keep the method's own.
    ///
    /// Diyanet uses 17°. Fazilet and Türkiye Takvimi are also reported to use a
    /// deeper angle for işâ-i sânî, but we could not source a defensible
    /// number, so they are left on the method value rather than guessed.
    public var ishaAngleOverride: Double? {
        switch self {
        case .diyanet: 17.0
        case .fazilet: nil           // ⚠️ VERIFY — left unmodified on purpose
        case .turkiyeTakvimi: nil    // ⚠️ VERIFY — left unmodified on purpose
        case .standard: nil
        }
    }

    /// Additional per-prayer temkin, on top of what the calculation method
    /// already applies. Zero everywhere: no source we could verify gives a
    /// concrete extra temkin table for Fazilet / Türkiye Takvimi, and inventing
    /// one in a worship app is not acceptable.
    public var extraTemkinMinutes: [Prayer: Int] { [:] }

    /// Whether this source forces the Turkish (Diyanet-derived) base method
    /// regardless of the method picked in Settings.
    public var forcesTurkishBaseMethod: Bool { isTurkishTradition }
}

// MARK: - Method bridging

public extension CalculationMethod {
    /// Mihrab's method → the adhan-swift preset that implements it.
    /// `Adhan.` qualification is required: adhan-swift ships types with the
    /// exact same names as Mihrab's own (`CalculationMethod`, `Madhab`, `Prayer`).
    var adhanMethod: Adhan.CalculationMethod {
        switch self {
        case .diyanet: .turkey
        case .ummAlQura: .ummAlQura
        case .isna: .northAmerica
        case .mwl: .muslimWorldLeague
        case .egypt: .egyptian
        case .karachi: .karachi
        }
    }
}

public extension Madhab {
    var adhanMadhab: Adhan.Madhab {
        self == .hanafi ? .hanafi : .shafi
    }
}

/// The per-prayer minute adjustments each adhan-swift preset bakes in.
///
/// These are *not* guessed: they are transcribed from adhan-swift 1.5.0
/// `Sources/Models/CalculationMethod.swift`. We need our own copy because
/// `CalculationParameters.methodAdjustments` is `internal` to the Adhan module
/// and therefore unreadable from here — but the transparency panel has to be
/// able to tell the user "your Diyanet öğle already contains +5 minutes of
/// temkin".
///
/// For `.turkey` these are exactly the Diyanet temkin values: sunrise −7,
/// dhuhr +5, asr +4, maghrib +7 minutes. Note that adhan-swift applies **no**
/// temkin to imsak or yatsı for `.turkey`; Diyanet's own tables are generally
/// understood to carry a margin there too, but we do not add one because we
/// could not source the figure. (Flagged in the agent report.)
public enum MethodTemkin {
    public static func minutes(for method: Adhan.CalculationMethod) -> [Prayer: Int] {
        switch method {
        case .turkey:
            [.sunrise: -7, .dhuhr: 5, .asr: 4, .maghrib: 7]
        case .dubai:
            [.sunrise: -3, .dhuhr: 3, .asr: 3, .maghrib: 3]
        case .moonsightingCommittee:
            [.dhuhr: 5, .maghrib: 3]
        case .muslimWorldLeague, .egyptian, .karachi, .northAmerica, .singapore:
            [.dhuhr: 1]
        case .ummAlQura, .kuwait, .qatar, .tehran, .other:
            [:]
        @unknown default:
            [:]
        }
    }

    /// `true` when the method's built-in adjustments are a documented temkin
    /// margin (Diyanet) rather than a generic transit correction.
    public static func isTemkin(_ method: Adhan.CalculationMethod) -> Bool {
        method == .turkey
    }
}
