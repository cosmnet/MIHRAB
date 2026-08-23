import Foundation

// MARK: - Nisab

/// Which threshold the user's liability is measured against.
enum NisabBasis: String, Codable, CaseIterable, Identifiable, Sendable {
    case gold, silver
    var id: String { rawValue }
    var localizedName: String { self == .gold ? L10n.zakatBasisGold : L10n.zakatBasisSilver }
}

/// 200 dirhem of silver, converted to grams. The conversion depends on which
/// dirham weight is used and the published figures genuinely differ, so the
/// user picks rather than us pretending there is one number.
///
/// - `grams595`: 200 × 2.975 g — the figure most Turkish zakat calculators use.
/// - `grams561`: 200 × 2.805 g — the figure Diyanet İşleri Başkanlığı publishes
///   alongside the 80.18 g gold nisab.
///
/// ⚠️ Both need editorial verification against a current Diyanet fatwa before
/// release; do not treat these constants as checked.
enum SilverNisabStandard: String, Codable, CaseIterable, Identifiable, Sendable {
    case grams595, grams561

    var id: String { rawValue }

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
    /// One fortieth — 2.5%.
    static let rate = 1.0 / 40.0

    /// 20 miskal of gold. Diyanet publishes this as **80.18 g**.
    /// ⚠️ Verify against a current Diyanet fatwa before release.
    static let goldNisabGrams = 80.18

    /// Value of the threshold in the user's currency, or `nil` when the price
    /// needed for the chosen basis has not been entered.
    static func nisabValue(
        basis: NisabBasis,
        prices: MetalPrices,
        silverStandard: SilverNisabStandard = .grams595
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
        silverStandard: SilverNisabStandard = .grams595
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

/// Fitre (sadaka-i fıtr) is a fixed amount per household member, not a
/// percentage. In Türkiye the minimum is announced annually by the Diyanet
/// fitre commission, so **the user enters this year's amount** — we ship no
/// figure, because an out-of-date one would be worse than none.
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
