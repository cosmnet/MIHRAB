import Adhan
import Foundation

/// Which published prayer-time tradition the on-device engine should imitate.
///
/// Background — why this exists at all:
/// Saying "we are Diyanet-compatible" is not enough in Turkey. Two separate
/// things move the printed numbers:
///
/// 1. **Temkin** — the calendars do not print the raw astronomical instant.
///    They add a safety margin so that a person who prays exactly on the
///    printed minute is still inside the valid window everywhere in the city.
/// 2. **Which twilight angle counts as fecr-i sâdık** — three calendar
///    traditions coexist in Turkey and disagree about imsak by 15–20 minutes.
///    Until 1983 every Turkish calendar used −19°; Diyanet moved to −18° that
///    year and dropped its imsak/yatsı temkin, which is the whole origin of the
///    split.
///
/// ## What is offered, and why
///
/// A tradition is only offered when **its own publisher states the angles and
/// the temkin**. Attribution by third parties is not enough: showing a
/// worshipper an unverified time under a respected calendar's name is worse
/// than not offering that calendar at all.
///
/// | Source | Imsak | Yatsı | Temkin | First-party evidence |
/// |---|---|---|---|---|
/// | Diyanet | 18° | 17° | güneş −7, öğle +5, ikindi +4, akşam +7 | Aladhan `method=13` returns exactly these; adhan-swift `.turkey` implements them; matches Diyanet's printed Istanbul table to ±1 min |
/// | Türkiye Takvimi | 19° | 17° | 10 min, all times | Publisher's own pages, below |
/// | Fazilet Takvimi | 19° (reported) | 17° (reported) | **not published** | — |
///
/// **Türkiye Takvimi (Hakîkat Kitabevi) — offered.** Its own "Vakit Hesâblama
/// Hey'eti Başkanlığı" publishes the parameters:
/// - imsak: *"güneşin irtifâ'ının, ufkun altında (−19) derece olduğu vakti
///   buluyoruz"*; yatsı: *"Güneşin ufkun altında (−17) derece irtifâ'a indiği
///   vakittir"* —
///   <https://www.turktakvim.com/index.php?link=html%2Fmuhim_tenbih.html>
/// - temkin: 10 minutes on every time, subtracted before noon and added after
///   noon —
///   <https://www.turktakvim.com/pdf/DogruImsakVaktiHakkindaAciklamalar.pdf>
///   and <https://www.turktakvim.com/index.php?link=html%2Fimsak_vakti.html>
///
/// **Fazilet Takvimi — withdrawn.** Their own timekeeper states 19°/17°, but
/// Fazilet applies a *per-city* "sabit temkin" whose minute values they
/// deliberately do not publish, and temkin is a large part of why their printed
/// imsak differs from Diyanet's. The figures circulating for it are blog
/// hearsay. A previous revision of this file shipped a guessed 19° with **no**
/// temkin at all, which reproduced roughly half the real difference and was
/// therefore wrong in a way no user could detect. The case is kept so older
/// installs still decode, but it is withdrawn from the picker and resolves to
/// Diyanet. If Fazilet ever publishes its temkin table, re-enabling is a
/// two-line change plus a citation here.
public enum PrayerSource: String, CaseIterable, Identifiable, Sendable, Codable {
    /// Diyanet İşleri Başkanlığı — imsak 18°, yatsı 17°, Diyanet temkin.
    case diyanet
    /// Fazilet Takvimi. **Withdrawn** — temkin unpublished. See above.
    case fazilet
    /// Türkiye Takvimi (Hakîkat Kitabevi) — imsak 19°, yatsı 17°, 10 min temkin.
    case turkiyeTakvimi
    /// No regional override: use the calculation method the user picked in
    /// Settings exactly as its authority publishes it.
    case standard

    public var id: String { rawValue }

    // MARK: - Availability

    /// `false` for a tradition whose published parameters we could not source.
    /// Such a source must never appear in a picker.
    public var isSelectable: Bool {
        switch self {
        case .diyanet, .turkiyeTakvimi, .standard: true
        case .fazilet: false
        }
    }

    /// What this source actually behaves as. A withdrawn tradition falls back
    /// to Diyanet — the closest authority whose numbers we can stand behind —
    /// rather than continuing to apply an angle nobody could verify.
    public var resolved: PrayerSource {
        isSelectable ? self : .diyanet
    }

    /// **This is the picker's list.** `CaseIterable`'s synthesised `allCases`
    /// is deliberately overridden so that no call site anywhere in the app can
    /// accidentally offer a withdrawn tradition; decoding a stored raw value
    /// still works, which is the only thing the removed cases are for.
    public static var allCases: [PrayerSource] { [.diyanet, .turkiyeTakvimi, .standard] }

    /// Explicit alias for readers who find the `allCases` override surprising.
    public static var selectableCases: [PrayerSource] { allCases }

    /// Cases that still decode but are no longer offered.
    public static var withdrawnCases: [PrayerSource] { [.fazilet] }

    // MARK: - Presentation

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
        case .turkiyeTakvimi: L10n.sourceTurkiyeTakvimiDetail
        case .fazilet: L10n.sourceWithdrawnDetail
        case .standard: L10n.sourceStandardDetail
        }
    }

    /// `true` when this source is only meaningful inside Turkey.
    public var isTurkishTradition: Bool { self != .standard }

    /// Who publishes these times. Named on screen: the numbers are theirs.
    /// `nil` for `.standard`, where the authority is whichever calculation
    /// method the user picked and is already named next to it.
    public var localizedAuthority: String? {
        switch resolved {
        case .diyanet, .fazilet: L10n.sourceAuthorityDiyanet
        case .turkiyeTakvimi: L10n.sourceAuthorityTurkiyeTakvimi
        case .standard: nil
        }
    }

    // MARK: - Engine parameters

    /// The adhan-swift preset this tradition is built on, or `nil` to keep the
    /// method the user picked in Settings.
    ///
    /// Diyanet sits on `.turkey`, which *is* the Diyanet preset — its built-in
    /// method adjustments are Diyanet's temkin. Türkiye Takvimi sits on
    /// `.other` instead: `.other` carries no angles and no adjustments of its
    /// own, so every number below is ours and Diyanet's temkin cannot leak in.
    public var baseAdhanMethod: Adhan.CalculationMethod? {
        switch resolved {
        case .diyanet, .fazilet: .turkey
        case .turkiyeTakvimi: .other
        case .standard: nil
        }
    }

    /// Fajr (imsak) twilight angle this tradition uses, or `nil` to keep the
    /// angle that comes with the selected calculation method.
    public var fajrAngleOverride: Double? {
        switch resolved {
        case .diyanet, .fazilet: 18.0
        case .turkiyeTakvimi: 19.0
        case .standard: nil
        }
    }

    /// Isha twilight angle override, or `nil` to keep the method's own.
    public var ishaAngleOverride: Double? {
        switch resolved {
        case .diyanet, .fazilet: 17.0
        case .turkiyeTakvimi: 17.0
        case .standard: nil
        }
    }

    /// Temkin this tradition applies *on top of* whatever its base preset
    /// already carries.
    ///
    /// Diyanet's margin is already inside `.turkey`, so it adds nothing here.
    /// Türkiye Takvimi sits on the empty `.other` preset, so its whole 10-minute
    /// margin lives here — subtracted from the times before noon (imsak,
    /// güneş) and added to the times after noon (öğle, ikindi, akşam, yatsı),
    /// which is the sign convention its publisher states.
    public var extraTemkinMinutes: [Prayer: Int] {
        switch resolved {
        case .turkiyeTakvimi:
            [.fajr: -10, .sunrise: -10, .dhuhr: 10, .asr: 10, .maghrib: 10, .isha: 10]
        case .diyanet, .fazilet, .standard:
            [:]
        }
    }

    /// `true` when this tradition's minute adjustments are a published temkin
    /// margin rather than a generic transit correction. Drives whether the
    /// transparency panel is allowed to use the word "temkin".
    public var appliesDocumentedTemkin: Bool {
        switch resolved {
        case .diyanet, .fazilet, .turkiyeTakvimi: true
        case .standard: false
        }
    }

    /// Whether this source pins its own base preset regardless of the method
    /// picked in Settings.
    public var forcesTurkishBaseMethod: Bool { baseAdhanMethod != nil }

    /// The Aladhan method that reproduces this source, or `nil` when Aladhan
    /// has no equivalent and the network must be skipped entirely.
    ///
    /// Aladhan's `method=13` returns fajr 18 / isha 17 with the offset table
    /// `sunrise −7, dhuhr +5, asr +4, maghrib +7` — byte for byte the Diyanet
    /// preset this app computes offline, which is why the two paths can be
    /// mixed without the displayed times jumping. Aladhan has **no** Türkiye
    /// Takvimi method; fetching would silently replace that user's chosen
    /// tradition with Diyanet's numbers, so it stays on-device only. That is no
    /// loss: the offline engine needs no network to be exact.
    public func networkMethod(userMethod: CalculationMethod) -> CalculationMethod? {
        switch resolved {
        case .diyanet, .fazilet: .diyanet
        case .turkiyeTakvimi: nil
        case .standard: userMethod
        }
    }
}

// MARK: - Method bridging

public extension CalculationMethod {
    /// Mihrab's method → the adhan-swift preset that implements it.
    ///
    /// Each pairing was checked against both the authority's published angles
    /// and adhan-swift's own parameters; `PrayerAccuracyTests` asserts every
    /// row and every angle so a future reshuffle cannot go unnoticed.
    ///
    /// | Mihrab | adhan-swift | published fajr / isha |
    /// |---|---|---|
    /// | `.diyanet` (13) | `.turkey` | 18° / 17° + temkin |
    /// | `.ummAlQura` (4) | `.ummAlQura` | 18.5° / maghrib + 90 min |
    /// | `.isna` (2) | `.northAmerica` | 15° / 15° |
    /// | `.mwl` (3) | `.muslimWorldLeague` | 18° / 17° |
    /// | `.egypt` (5) | `.egyptian` | 19.5° / 17.5° |
    /// | `.karachi` (1) | `.karachi` | 18° / 18° |
    ///
    /// The raw values are also the Aladhan API's method ids, which is why
    /// `AladhanClient` can send them straight through.
    ///
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
    /// `Madhab.rawValue` doubles as Aladhan's `school` parameter (0 Shafi, 1 Hanafi).
    var adhanMadhab: Adhan.Madhab {
        self == .hanafi ? .hanafi : .shafi
    }
}

/// The per-prayer minute adjustments each adhan-swift preset bakes in.
///
/// These are *not* guessed: they are transcribed from adhan-swift
/// `Sources/Models/CalculationMethod.swift`, and
/// `PrayerAccuracyTests.testDiyanetTemkinIsActuallyApplied` re-derives the
/// `.turkey` row from the library's own output rather than trusting the
/// transcription. We need our own copy because
/// `CalculationParameters.methodAdjustments` is `internal` to the Adhan module
/// and therefore unreadable from here — but the transparency panel has to be
/// able to tell the user "your Diyanet öğle already contains +5 minutes of
/// temkin".
///
/// For `.turkey` these are exactly the Diyanet temkin values: sunrise −7,
/// dhuhr +5, asr +4, maghrib +7 minutes — and Aladhan's `method=13` returns the
/// identical offset table, which is independent confirmation. adhan-swift
/// applies **no** temkin to imsak or yatsı for `.turkey`, matching Diyanet's
/// practice since 1983.
///
/// `.other` returns an empty table on purpose: it is the blank base Türkiye
/// Takvimi is built on, and that tradition's own 10-minute margin arrives
/// through `PrayerSource.extraTemkinMinutes` instead.
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
