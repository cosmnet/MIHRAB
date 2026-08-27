import Foundation
import SwiftUI

/// Persists the zakat worksheet: the figures the user typed, the gram prices
/// they last entered, their nisab choice, and the date their zakat year began.
///
/// Nothing here leaves the device and nothing is fetched. See `MetalPrices` for
/// why there is no price feed.
@MainActor
@Observable
final class ZakatStore {
    static let shared = ZakatStore()

    struct State: Codable, Equatable, Sendable {
        var assets = ZakatAssets()
        var prices = MetalPrices()
        /// Diyanet's recommendation, pre-selected. See `NisabBasis`.
        var basis: NisabBasis = .recommended
        var silverStandard: SilverNisabStandard = .standard
        /// Start of the current zakat year (havelan-ı havl).
        var zakatYearStart: Date?
        var currencyCode: String?
        // Fitre
        var fitrePerPerson: Double = 0
        var fitrePeople: Int = 1
    }

    private let defaults: UserDefaults
    private static let storageKey = "zakat.state.v1"

    private(set) var state: State {
        didSet { persist() }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(State.self, from: data) {
            state = decoded
        } else {
            state = State()
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    // MARK: - Currency

    /// The user's own currency, so the sheet never implies a country.
    var currencyCode: String {
        get { state.currencyCode ?? Locale.current.currency?.identifier ?? "TRY" }
        set { state.currencyCode = newValue }
    }

    func format(_ amount: Double) -> String {
        amount.formatted(.currency(code: currencyCode).locale(Locale(identifier: L10n.localeIdentifier)))
    }

    // MARK: - Bindable slices

    var assets: ZakatAssets {
        get { state.assets }
        set { state.assets = newValue }
    }

    var prices: MetalPrices {
        get { state.prices }
        set { state.prices = newValue }
    }

    var basis: NisabBasis {
        get { state.basis }
        set { state.basis = newValue }
    }

    var silverStandard: SilverNisabStandard {
        get { state.silverStandard }
        set { state.silverStandard = newValue }
    }

    var fitrePerPerson: Double {
        get { state.fitrePerPerson }
        set { state.fitrePerPerson = newValue }
    }

    var fitrePeople: Int {
        get { state.fitrePeople }
        set { state.fitrePeople = max(0, newValue) }
    }

    /// Record that the prices on screen are current.
    func stampPrices() {
        state.prices.updatedAt = Date()
    }

    var pricesUpdatedAt: Date? { state.prices.updatedAt }

    /// True when the entered prices are older than a week — gold moves, and a
    /// stale price quietly produces a wrong zakat.
    var pricesLookStale: Bool {
        guard let updated = state.prices.updatedAt else { return state.prices.isUsable }
        return Date().timeIntervalSince(updated) > 7 * 24 * 3600
    }

    // MARK: - Results

    var result: ZakatResult {
        ZakatCalculator.calculate(
            assets: state.assets,
            prices: state.prices,
            basis: state.basis,
            silverStandard: state.silverStandard
        )
    }

    /// Diyanet's announced fitre amount, when it is still current and the
    /// sheet is in lira. `nil` means we have nothing trustworthy to offer and
    /// the UI must say so rather than suggest a stale figure.
    var suggestedFitre: Double? {
        DiyanetFitre.suggestion(currencyCode: currencyCode)
    }

    /// `true` when the shipped figure has been superseded and the user has to
    /// look up this year's amount themselves.
    var fitreFigureIsStale: Bool {
        currencyCode == DiyanetFitre.currencyCode && !DiyanetFitre.isCurrent()
    }

    func applySuggestedFitre() {
        guard let amount = suggestedFitre else { return }
        state.fitrePerPerson = amount
    }

    var fitre: FitreResult {
        FitreCalculator.calculate(perPerson: state.fitrePerPerson, people: state.fitrePeople)
    }

    /// `nil` when the price for the chosen basis has not been entered.
    var nisabValue: Double? {
        ZakatCalculator.nisabValue(basis: state.basis, prices: state.prices, silverStandard: state.silverStandard)
    }

    // MARK: - Zakat year (havelan-ı havl)

    var zakatYearStart: Date? {
        get { state.zakatYearStart }
        set { state.zakatYearStart = newValue }
    }

    /// **Reading point for the notification engine (W2).** The next date one
    /// lunar year on from the recorded start, or `nil` if the user has not set
    /// a start date.
    var nextZakatAnniversary: Date? {
        guard let start = state.zakatYearStart else { return nil }
        var anniversary = ZakatYear.nextAnniversary(after: start)
        // Roll forward through years the user never cleared.
        while let candidate = anniversary, candidate < Date() {
            anniversary = ZakatYear.nextAnniversary(after: candidate)
        }
        return anniversary
    }

    var daysUntilAnniversary: Int? {
        guard let next = nextZakatAnniversary else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: next)
        ).day
    }

    func startZakatYearToday() {
        state.zakatYearStart = Calendar.current.startOfDay(for: Date())
    }

    func clearZakatYear() {
        state.zakatYearStart = nil
    }

    func resetWorksheet() {
        state.assets = ZakatAssets()
    }
}
