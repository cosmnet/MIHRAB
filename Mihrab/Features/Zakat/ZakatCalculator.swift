import Foundation

// MARK: - Nisab

/// Which threshold the user's liability is measured against.
///
/// **Diyanet's position is gold, for everything.** The Din İşleri Yüksek Kurulu
/// fatwa "Gümüşün zekât nisabı nedir?" holds that because silver has lost so
/// much of its historical value relative to gold, the value of 80,18 g of
/// 24-karat gold should be the measure for silver, cash, trade goods and
/// securities alike:
///
/// > "Gümüşün zekât nisabında da, altın ve ticaret malı durumundaki tüm
/// > mallarda olduğu gibi 24 ayardan 80,18 gram altın değerinin ölçü alınması
/// > uygundur."
///
/// <https://kurul.diyanet.gov.tr/tr/fetva/gumusun-zekat-nisabi-nedir/9c22f45d-4481-4f4b-0859-08dd1c135351>
///
/// So `.gold` is the default and the recommended answer, and the app says whose
/// recommendation it is. `.silver` stays available because the classical
/// 200-dirhem threshold is a recognised opinion others follow — but it is
/// labelled as the classical view, never as Diyanet's.
enum NisabBasis: String, Codable, CaseIterable, Identifiable, Sendable {
    case gold, silver
    var id: String { rawValue }

    /// What Diyanet İşleri Başkanlığı recommends, and therefore the default.
    /// The user told us plainly that they cannot make this call themselves;
    /// the app must not hand it back to them.
    static let recommended: NisabBasis = .gold

    var localizedName: String { self == .gold ? L10n.zakatBasisGold : L10n.zakatBasisSilver }

    /// One line on what picking this changes, and whose position it is.
    var localizedNote: String {
        self == .gold ? L10n.zakatBasisGoldNote : L10n.zakatBasisSilverNote
    }
}

/// 200 dirhem of silver, converted to grams.
///
/// Only one figure is offered: **561 g** (200 × 2,805 g), the conversion that
/// goes with the same classical weights Diyanet's 20 miskal = 80,18 g gold
/// figure comes from. The alternative 595 g reading (200 × 2,975 g) is retained
/// as a decodable case so an install that stored it still loads, but it is not
/// offered: making a user who told us "Din bilmiyorum ki" choose between two
/// dirham weights is exactly the decision this app should not delegate.
///
/// Note that neither figure is an operative Diyanet threshold — see
/// `NisabBasis` — so both are presented as the classical view.
enum SilverNisabStandard: String, Codable, CaseIterable, Identifiable, Sendable {
    case grams595, grams561

    var id: String { rawValue }

    /// The one we offer. Everything else only decodes.
    static let standard: SilverNisabStandard = .grams561

    var isSelectable: Bool { self == Self.standard }

    var grams: Double {
        switch self {
        case .grams595: 595
        case .grams561: 561
        }
    }

    var localizedName: String {
        switch self {
        case .grams595: L10n.zakatSilver595
        case .grams561: L10n.zakatSilver561
        }
    }
}

// MARK: - Inputs

/// Current gram prices. **Entered by the user** — we ship no price feed and no
/// hard-coded value, because there is no free, key-less, reliable source we can
/// stand behind, and a stale gold price silently produces a wrong zakat.
struct MetalPrices: Codable, Equatable, Sendable {
    var goldPerGram: Double = 0
    var silverPerGram: Double = 0
    var updatedAt: Date?

    var isUsable: Bool { goldPerGram > 0 || silverPerGram > 0 }
}

/// Everything counted, and everything taken off.
struct ZakatAssets: Codable, Equatable, Sendable {
    // Counted
    var cash: Double = 0
    var bank: Double = 0
    var goldGrams: Double = 0
    var silverGrams: Double = 0
    var tradeGoods: Double = 0
    var receivables: Double = 0
    var investments: Double = 0
    // Deducted
    var debts: Double = 0
    var essentialNeeds: Double = 0
}

// MARK: - Result

struct ZakatResult: Equatable, Sendable {
    var goldValue: Double
    var silverValue: Double
    var grossAssets: Double
    var deductions: Double
    /// Never negative — a person cannot owe zakat on a shortfall.
    var netWealth: Double
    var nisabValue: Double
    var isLiable: Bool
    var zakatDue: Double
    var basis: NisabBasis
}

// MARK: - Calculator

/// Pure functions, no state, no formatting. Everything the tests care about.
enum ZakatCalculator {
    /// Rubu'l-uşr — one fortieth, 2.5%. Stated as "kırkta bir / %2,5" in the
    /// Din İşleri Yüksek Kurulu fatwas cited below.
    static let rate = 1.0 / 40.0

    /// 20 miskal of 24-karat gold. Din İşleri Yüksek Kurulu, "Altının nisabı ve
    /// birbirinden farklı ayarlardaki altınların zekâtında hangi ölçü esas
    /// alınır?": Diyanet follows the majority view and takes
    /// **80,18 g of 24-karat gold**.
    ///
    /// <https://kurul.diyanet.gov.tr/tr/fetva/altinin-nisabi-ve-birbirinden-farkli-ayarlardaki-altinlarin/0193c42d-a374-7008-53e8-21cae4812f96>
    /// <https://kurul.diyanet.gov.tr/tr/fetva/zekat-nedir/0193c42d-650d-7460-b43b-7ad3a03aead3>
    static let goldNisabGrams = 80.18

    /// 200 dirhem of silver — the classical threshold, not Diyanet's operative
    /// one (see `NisabBasis`). Kept as a named constant so the number has one
    /// home and the tests can pin it.
    static let silverNisabGrams = SilverNisabStandard.standard.grams

    /// Value of the threshold in the user's currency, or `nil` when the price
    /// needed for the chosen basis has not been entered.
    static func nisabValue(
        basis: NisabBasis,
        prices: MetalPrices,
        silverStandard: SilverNisabStandard = .standard
    ) -> Double? {
        switch basis {
        case .gold:
            guard prices.goldPerGram > 0 else { return nil }
            return goldNisabGrams * prices.goldPerGram
        case .silver:
            guard prices.silverPerGram > 0 else { return nil }
            return silverStandard.grams * prices.silverPerGram
        }
    }

    static func calculate(
        assets: ZakatAssets,
        prices: MetalPrices,
        basis: NisabBasis,
        silverStandard: SilverNisabStandard = .standard
    ) -> ZakatResult {
        let goldValue = max(0, assets.goldGrams) * max(0, prices.goldPerGram)
        let silverValue = max(0, assets.silverGrams) * max(0, prices.silverPerGram)

        let gross = max(0, assets.cash)
            + max(0, assets.bank)
            + goldValue
            + silverValue
            + max(0, assets.tradeGoods)
            + max(0, assets.receivables)
            + max(0, assets.investments)

        let deductions = max(0, assets.debts) + max(0, assets.essentialNeeds)
        let net = max(0, gross - deductions)

        let nisab = nisabValue(basis: basis, prices: prices, silverStandard: silverStandard) ?? 0
        // A nisab of zero means "we don't know the threshold", not "everyone is
        // liable" — so liability requires a positive, known threshold.
        let liable = nisab > 0 && net >= nisab

        return ZakatResult(
            goldValue: goldValue,
            silverValue: silverValue,
            grossAssets: gross,
            deductions: deductions,
            netWealth: net,
            nisabValue: nisab,
            isLiable: liable,
            zakatDue: liable ? net * rate : 0,
            basis: basis
        )
    }
}

// MARK: - Fitre

/// The figure Diyanet actually announced, and how long it is good for.
///
/// Fitre is a fixed amount per household member, not a percentage. In Türkiye
/// the minimum is set each year by the Din İşleri Yüksek Kurulu. There is no
/// API, no feed and no stable URL for it — every year's announcement is a fresh
/// `duyuru` page — so it cannot be fetched. But making a user who told us
/// "Din bilmiyorum ki" go and find it themselves is not an answer either.
///
/// The compromise: ship the announced figure with its announcement date, offer
/// it as a one-tap suggestion, and **stop offering it the moment it can no
/// longer be trusted**. After `validUntil` the app says nothing and asks the
/// user to check the current figure, rather than quietly suggesting a stale one.
///
/// - Amount: **240 TL**, announced 13 January 2026 (decided 7 January 2026),
///   valid from the start of Ramadan 1447 to the start of Ramadan 1448. The
///   same figure is the daily oruç fidyesi. It is a floor, not a cap.
/// - <https://kurul.diyanet.gov.tr/tr/duyuru/din-isleri-yuksek-kurulu-2026-yili-fitre-miktarini-acikladi/019bb642-4872-7191-841e-408610f76b33>
///
/// **Maintenance:** when the Kurul announces the next figure (usually in
/// January), update all four constants together. `ZakatTests` fails the build
/// once `validUntil` is in the past, so this cannot rot silently.
enum DiyanetFitre {
    static let amount: Double = 240
    static let currencyCode = "TRY"

    /// The day the Din İşleri Yüksek Kurulu announced it.
    static let announcedOn = DateComponents(calendar: Calendar(identifier: .gregorian),
                                            timeZone: TimeZone(identifier: "Europe/Istanbul"),
                                            year: 2026, month: 1, day: 13).date!

    /// Start of Ramadan 1448 — the point the figure is superseded.
    static let validUntil = DateComponents(calendar: Calendar(identifier: .gregorian),
                                           timeZone: TimeZone(identifier: "Europe/Istanbul"),
                                           year: 2027, month: 2, day: 18).date!

    static func isCurrent(on date: Date = Date()) -> Bool { date < validUntil }

    /// The amount to suggest, or `nil` when we have nothing trustworthy to say.
    /// Only offered in Turkish lira: the figure is a lira amount, and silently
    /// reusing "240" as euros or dollars would be nonsense.
    static func suggestion(currencyCode code: String, on date: Date = Date()) -> Double? {
        guard code == currencyCode, isCurrent(on: date) else { return nil }
        return amount
    }
}

struct FitreResult: Equatable, Sendable {
    var perPerson: Double
    var people: Int
    var total: Double
}

enum FitreCalculator {
    static func calculate(perPerson: Double, people: Int) -> FitreResult {
        let amount = max(0, perPerson)
        let count = max(0, people)
        return FitreResult(perPerson: amount, people: count, total: amount * Double(count))
    }
}

// MARK: - Havelan-ı havl

enum ZakatYear {
    /// One lunar year on from `date`, using the Umm al-Qura calendar.
    ///
    /// Zakat falls due when a full **lunar** year has passed over wealth that
    /// stayed above nisab. Adding 365 Gregorian days would drift the date about
    /// eleven days later every year.
    static func nextAnniversary(after date: Date) -> Date? {
        IslamicCalendar.hijri.date(byAdding: .year, value: 1, to: date)
    }

    static func daysUntilAnniversary(start: Date, now: Date = Date()) -> Int? {
        guard let next = nextAnniversary(after: start) else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: next)
        ).day
    }
}
