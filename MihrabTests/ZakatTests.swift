import XCTest

// MARK: - Zakat

final class ZakatCalculatorTests: XCTestCase {

    private func prices(gold: Double = 3_000, silver: Double = 35) -> MetalPrices {
        MetalPrices(goldPerGram: gold, silverPerGram: silver, updatedAt: nil)
    }

    func testRateIsOneFortieth() {
        XCTAssertEqual(ZakatCalculator.rate, 0.025, accuracy: 1e-12)
        XCTAssertEqual(ZakatCalculator.rate, 1.0 / 40.0, accuracy: 1e-12)
    }

    func testGoldNisabValue() {
        let value = ZakatCalculator.nisabValue(basis: .gold, prices: prices())
        // 80.18 g × 3000
        XCTAssertEqual(value ?? 0, 240_540, accuracy: 0.001)
    }

    func testSilverNisabValueFollowsChosenStandard() {
        let a = ZakatCalculator.nisabValue(basis: .silver, prices: prices(), silverStandard: .grams595)
        let b = ZakatCalculator.nisabValue(basis: .silver, prices: prices(), silverStandard: .grams561)
        XCTAssertEqual(a ?? 0, 595 * 35, accuracy: 0.001)
        XCTAssertEqual(b ?? 0, 561 * 35, accuracy: 0.001)
        XCTAssertGreaterThan(a ?? 0, b ?? 0)
    }

    func testSilverThresholdIsLowerThanGoldAtRealisticPrices() {
        // The honest claim made in the UI: the silver threshold makes more
        // people liable. Assert it holds at the prices we test with.
        let gold = ZakatCalculator.nisabValue(basis: .gold, prices: prices()) ?? 0
        let silver = ZakatCalculator.nisabValue(basis: .silver, prices: prices()) ?? 0
        XCTAssertLessThan(silver, gold)
    }

    func testNisabIsNilWithoutAPrice() {
        let empty = MetalPrices()
        XCTAssertNil(ZakatCalculator.nisabValue(basis: .gold, prices: empty))
        XCTAssertNil(ZakatCalculator.nisabValue(basis: .silver, prices: empty))
    }

    func testExactlyAtNisabIsLiable() {
        var assets = ZakatAssets()
        assets.cash = 80.18 * 3_000
        let result = ZakatCalculator.calculate(assets: assets, prices: prices(), basis: .gold)
        XCTAssertTrue(result.isLiable)
        XCTAssertEqual(result.zakatDue, assets.cash / 40, accuracy: 0.001)
    }

    func testJustBelowNisabIsNotLiable() {
        var assets = ZakatAssets()
        assets.cash = 80.18 * 3_000 - 1
        let result = ZakatCalculator.calculate(assets: assets, prices: prices(), basis: .gold)
        XCTAssertFalse(result.isLiable)
        XCTAssertEqual(result.zakatDue, 0)
    }

    func testDebtsAreDeductedBeforeTheThresholdIsChecked() {
        var assets = ZakatAssets()
        assets.cash = 300_000
        assets.debts = 100_000          // net 200_000, below 240_540
        let result = ZakatCalculator.calculate(assets: assets, prices: prices(), basis: .gold)
        XCTAssertEqual(result.netWealth, 200_000, accuracy: 0.001)
        XCTAssertFalse(result.isLiable)
        XCTAssertEqual(result.zakatDue, 0)
    }

    func testEssentialNeedsAlsoDeduct() {
        var assets = ZakatAssets()
        assets.cash = 300_000
        assets.essentialNeeds = 50_000
        assets.debts = 10_000
        let result = ZakatCalculator.calculate(assets: assets, prices: prices(), basis: .gold)
        XCTAssertEqual(result.deductions, 60_000, accuracy: 0.001)
        XCTAssertEqual(result.netWealth, 240_000, accuracy: 0.001)
    }

    func testMetalGramsAreValuedAtTheEnteredPrice() {
        var assets = ZakatAssets()
        assets.goldGrams = 100
        assets.silverGrams = 200
        let result = ZakatCalculator.calculate(assets: assets, prices: prices(), basis: .gold)
        XCTAssertEqual(result.goldValue, 300_000, accuracy: 0.001)
        XCTAssertEqual(result.silverValue, 7_000, accuracy: 0.001)
        XCTAssertEqual(result.grossAssets, 307_000, accuracy: 0.001)
    }

    func testZeroEverythingIsZero() {
        let result = ZakatCalculator.calculate(assets: ZakatAssets(), prices: prices(), basis: .gold)
        XCTAssertEqual(result.grossAssets, 0)
        XCTAssertEqual(result.netWealth, 0)
        XCTAssertFalse(result.isLiable)
        XCTAssertEqual(result.zakatDue, 0)
    }

    func testDebtsLargerThanAssetsClampToZeroRatherThanGoingNegative() {
        var assets = ZakatAssets()
        assets.cash = 1_000
        assets.debts = 50_000
        let result = ZakatCalculator.calculate(assets: assets, prices: prices(), basis: .gold)
        XCTAssertEqual(result.netWealth, 0)
        XCTAssertEqual(result.zakatDue, 0)
        XCTAssertFalse(result.isLiable)
    }

    func testNegativeInputsAreTreatedAsZero() {
        var assets = ZakatAssets()
        assets.cash = -5_000
        assets.goldGrams = -10
        assets.debts = -100
        let result = ZakatCalculator.calculate(assets: assets, prices: prices(), basis: .gold)
        XCTAssertEqual(result.grossAssets, 0)
        XCTAssertEqual(result.deductions, 0)
        XCTAssertEqual(result.netWealth, 0)
    }

    func testNobodyIsLiableWhenTheThresholdIsUnknown() {
        var assets = ZakatAssets()
        assets.cash = 10_000_000
        let result = ZakatCalculator.calculate(assets: assets, prices: MetalPrices(), basis: .gold)
        XCTAssertEqual(result.nisabValue, 0)
        XCTAssertFalse(result.isLiable, "An unknown nisab must never make someone liable")
        XCTAssertEqual(result.zakatDue, 0)
    }

    // MARK: Fitre

    func testFitreMultiplies() {
        let result = FitreCalculator.calculate(perPerson: 120, people: 4)
        XCTAssertEqual(result.total, 480, accuracy: 0.001)
    }

    func testFitreClampsNegatives() {
        let result = FitreCalculator.calculate(perPerson: -50, people: -3)
        XCTAssertEqual(result.total, 0)
        XCTAssertEqual(result.people, 0)
    }

    // MARK: Hawl

    func testZakatAnniversaryIsALunarYearNotAGregorianOne() {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let next = ZakatYear.nextAnniversary(after: start)
        XCTAssertNotNil(next)
        let days = calendar.dateComponents([.day], from: start, to: next!).day ?? 0
        // A lunar year is 354 or 355 days — never 365.
        XCTAssertTrue((353...356).contains(days), "Expected a lunar year, got \(days) days")
    }
}

// MARK: - Religious calendar

final class IslamicObservanceTests: XCTestCase {

    private let calendar = Calendar.current

    func testHijriRoundTrip() {
        guard let date = IslamicCalendar.gregorianDay(hijriYear: 1447, month: 9, day: 1) else {
            return XCTFail("Umm al-Qura conversion failed")
        }
        let parts = IslamicCalendar.hijriComponents(for: date)
        XCTAssertEqual(parts?.year, 1447)
        XCTAssertEqual(parts?.month, 9)
        XCTAssertEqual(parts?.day, 1)
    }

    /// The core rule: a night observance begins the *evening before* the
    /// Gregorian day its Hijri date maps to.
    func testNightObservanceStartsOnThePreviousGregorianEvening() {
        let observances = IslamicCalendar.observances(hijriYear: 1447)
        guard let barat = observances.first(where: { $0.key == "barat" }) else {
            return XCTFail("Berat missing from 1447")
        }
        XCTAssertTrue(barat.isNightObservance)
        let delta = calendar.dateComponents(
            [.day],
            from: barat.nightGregorianDay,
            to: barat.gregorianDay
        ).day
        XCTAssertEqual(delta, 1, "The night must sit exactly one day before the Hijri day")
        XCTAssertEqual(barat.reminderGregorianDay, barat.nightGregorianDay)
    }

    func testDaytimeObservanceIsNotShifted() {
        let observances = IslamicCalendar.observances(hijriYear: 1447)
        guard let eid = observances.first(where: { $0.key == "eidFitr" }) else {
            return XCTFail("Eid missing from 1447")
        }
        XCTAssertFalse(eid.isNightObservance)
        XCTAssertEqual(eid.reminderGregorianDay, eid.gregorianDay)
    }

    func testStartUsesRealMaghribWhenGiven() {
        let observances = IslamicCalendar.observances(hijriYear: 1447)
        guard let qadr = observances.first(where: { $0.key == "qadr" }) else {
            return XCTFail("Kadir missing from 1447")
        }
        let maghrib = calendar.date(bySettingHour: 19, minute: 42, second: 0, of: qadr.nightGregorianDay)!
        XCTAssertEqual(qadr.start(maghrib: maghrib), maghrib)

        // Fallback is a *labelled* placeholder on the correct evening, never an
        // invented sunset on the wrong day.
        let fallback = qadr.start(maghrib: nil)
        XCTAssertEqual(calendar.startOfDay(for: fallback), calendar.startOfDay(for: qadr.nightGregorianDay))
    }

    func testActiveOnBothTheNightAndTheDay() {
        let observances = IslamicCalendar.observances(hijriYear: 1447)
        guard let miraj = observances.first(where: { $0.key == "miraj" }) else {
            return XCTFail("Miraç missing from 1447")
        }
        XCTAssertTrue(miraj.isActive(on: miraj.nightGregorianDay))
        XCTAssertTrue(miraj.isActive(on: miraj.gregorianDay))
        let twoDaysBefore = calendar.date(byAdding: .day, value: -2, to: miraj.nightGregorianDay)!
        XCTAssertFalse(miraj.isActive(on: twoDaysBefore))
    }

    /// Regaib is a weekday rule, not a fixed date — this is what the bundled
    /// `religious_days.json` gets wrong by pinning it to 1 Recep.
    func testRegaibFallsOnAFridayInRajab() {
        for year in 1445...1455 {
            guard let regaib = IslamicCalendar.regaibObservance(hijriYear: year) else {
                XCTFail("No Regaib computed for \(year)")
                continue
            }
            XCTAssertEqual(
                Calendar(identifier: .gregorian).component(.weekday, from: regaib.gregorianDay),
                6,
                "Regaib \(year) is not a Friday"
            )
            XCTAssertEqual(IslamicCalendar.hijriComponents(for: regaib.gregorianDay)?.month, 7)
            // It must be the *first* Friday, i.e. within the first seven days.
            XCTAssertLessThanOrEqual(regaib.hijriDay, 7)
        }
    }

    func testUpcomingObservancesStayInsideTheWindowAndAreSorted() {
        let upcoming = IslamicCalendar.upcomingObservances(within: 400)
        XCTAssertFalse(upcoming.isEmpty)
        for observance in upcoming {
            let delta = observance.daysUntil()
            XCTAssertGreaterThanOrEqual(delta, 0)
            XCTAssertLessThanOrEqual(delta, 400)
        }
        XCTAssertEqual(upcoming, upcoming.sorted { $0.reminderGregorianDay < $1.reminderGregorianDay })
    }

    func testNextOccurrencesHasNoDuplicateKeys() {
        let next = IslamicCalendar.nextOccurrences()
        XCTAssertEqual(Set(next.map(\.key)).count, next.count)
    }

    func testThreeMonthsSpanRajabToRamadan() {
        guard let interval = IslamicCalendar.threeMonthsInterval(hijriYear: 1447) else {
            return XCTFail("No three-month interval")
        }
        XCTAssertEqual(IslamicCalendar.hijriComponents(for: interval.start)?.month, 7)
        XCTAssertEqual(IslamicCalendar.hijriComponents(for: interval.end)?.month, 9)
    }

    // MARK: Voluntary fasts

    func testFastingIsForbiddenOnTheBayramDays() {
        XCTAssertTrue(IslamicCalendar.isFastingForbidden(hijriMonth: 10, hijriDay: 1))
        for day in 10...13 {
            XCTAssertTrue(IslamicCalendar.isFastingForbidden(hijriMonth: 12, hijriDay: day))
        }
        XCTAssertFalse(IslamicCalendar.isFastingForbidden(hijriMonth: 12, hijriDay: 9))
        XCTAssertFalse(IslamicCalendar.isFastingForbidden(hijriMonth: 1, hijriDay: 10))
    }

    func testUpcomingVoluntaryFastsExcludeForbiddenDaysAndRamadan() {
        let days = IslamicCalendar.upcomingVoluntaryFasts(limit: 10)
        for day in days {
            XCTAssertFalse(day.isForbidden)
            XCTAssertNotEqual(day.hijriMonth, 9)
            XCTAssertFalse(day.kinds.isEmpty)
        }
    }

    func testWhiteDaysAreTheThirteenthToFifteenth() {
        let start = IslamicCalendar.gregorianDay(hijriYear: 1447, month: 2, day: 1)!
        let end = IslamicCalendar.gregorianDay(hijriYear: 1447, month: 2, day: 28)!
        let days = IslamicCalendar.voluntaryFastDays(from: start, through: end)
            .filter { $0.kinds.contains(.whiteDays) }
        XCTAssertEqual(Set(days.map(\.hijriDay)), [13, 14, 15])
    }

    func testArafahIsTheNinthOfDhulHijjah() {
        let start = IslamicCalendar.gregorianDay(hijriYear: 1447, month: 12, day: 1)!
        let end = IslamicCalendar.gregorianDay(hijriYear: 1447, month: 12, day: 14)!
        let days = IslamicCalendar.voluntaryFastDays(from: start, through: end)
        let arafah = days.first { $0.kinds.contains(.arafah) }
        XCTAssertEqual(arafah?.hijriDay, 9)
    }
}

// MARK: - Qada estimator

final class QadaEstimatorTests: XCTestCase {

    private let calendar = Calendar.current

    private func input(years: Int) -> QadaEstimateInput {
        let end = Date()
        return QadaEstimateInput(start: QadaEstimator.startDate(yearsAgo: years, from: end), end: end)
    }

    func testFiveYearsIsAboutFiveTimesThreeSixtyFive() {
        let estimate = QadaEstimator.estimate(input(years: 5))
        XCTAssertEqual(Double(estimate.totalDays), 5 * 365.25, accuracy: 3)
        XCTAssertEqual(estimate.perPrayer, estimate.effectiveDays)
        XCTAssertEqual(estimate.total, estimate.perPrayer * 5)
    }

    func testPrayedFractionReducesTheEstimate() {
        var value = input(years: 10)
        value.prayedFraction = 0.5
        let estimate = QadaEstimator.estimate(value)
        let full = QadaEstimator.estimate(input(years: 10))
        XCTAssertEqual(Double(estimate.effectiveDays), Double(full.effectiveDays) / 2, accuracy: 2)
    }

    func testPrayedFractionOfOneLeavesNothing() {
        var value = input(years: 10)
        value.prayedFraction = 1
        XCTAssertEqual(QadaEstimator.estimate(value).total, 0)
    }

    func testFractionIsClampedToZeroAndOne() {
        var high = input(years: 3)
        high.prayedFraction = 5
        XCTAssertEqual(QadaEstimator.estimate(high).total, 0)

        var low = input(years: 3)
        low.prayedFraction = -2
        XCTAssertEqual(QadaEstimator.estimate(low).effectiveDays, QadaEstimator.estimate(input(years: 3)).effectiveDays)
    }

    func testMonthlyDeductionRemovesRoughlySevenDaysPerLunarMonth() {
        var value = input(years: 1)
        value.deductMonthlyDays = true
        value.averageMonthlyDays = 7
        let estimate = QadaEstimator.estimate(value)
        // ~12.37 lunar months in a solar year × 7 days.
        XCTAssertEqual(Double(estimate.deductedDays), 86, accuracy: 3)
        XCTAssertEqual(estimate.effectiveDays, estimate.totalDays - estimate.deductedDays)
    }

    func testMonthlyDeductionNeverExceedsTheRange() {
        var value = QadaEstimateInput(start: Date(), end: Date())
        value.deductMonthlyDays = true
        value.averageMonthlyDays = 15
        let estimate = QadaEstimator.estimate(value)
        XCTAssertEqual(estimate.totalDays, 0)
        XCTAssertEqual(estimate.deductedDays, 0)
        XCTAssertEqual(estimate.total, 0)
    }

    func testReversedDatesAreToleratedRatherThanGoingNegative() {
        let now = Date()
        let earlier = calendar.date(byAdding: .day, value: -100, to: now)!
        let reversed = QadaEstimateInput(start: now, end: earlier)
        let estimate = QadaEstimator.estimate(reversed)
        XCTAssertEqual(estimate.totalDays, 100)
        XCTAssertGreaterThanOrEqual(estimate.total, 0)
    }

    func testWitrIsOnlyCountedWhenAskedFor() {
        var value = input(years: 2)
        XCTAssertEqual(QadaEstimator.estimate(value).witr, 0)
        value.includeWitr = true
        let estimate = QadaEstimator.estimate(value)
        XCTAssertEqual(estimate.witr, estimate.effectiveDays)
        XCTAssertEqual(estimate.total, estimate.perPrayer * 5 + estimate.witr)
    }
}

// MARK: - Qada store

@MainActor
final class QadaStoreTests: XCTestCase {

    private func makeStore(_ name: String = UUID().uuidString) -> QadaStore {
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return QadaStore(defaults: defaults)
    }

    func testApplyingAnEstimateSetsEveryFardPrayer() {
        let store = makeStore()
        store.apply(QadaEstimate(totalDays: 100, deductedDays: 0, effectiveDays: 100, perPrayer: 100, witr: 100),
                    trackWitr: false)
        XCTAssertEqual(store.totalRemaining, 500)
        XCTAssertEqual(store.startingTotal, 500)
        XCTAssertEqual(store.remainingWitr, 0, "Witr must be ignored when not tracked")
        XCTAssertTrue(store.isSetUp)
    }

    func testMarkingPaidDecrementsAndLogs() {
        let store = makeStore()
        store.apply(QadaEstimate(totalDays: 10, deductedDays: 0, effectiveDays: 10, perPrayer: 10, witr: 0),
                    trackWitr: false)
        XCTAssertTrue(store.markPaid(.fajr))
        XCTAssertEqual(store.remaining(.fajr), 9)
        XCTAssertEqual(store.paid(.fajr), 1)
        XCTAssertEqual(store.totalRemaining, 49)
        XCTAssertEqual(store.totalPaid, 1)
    }

    func testCannotPayMoreThanIsOwed() {
        let store = makeStore()
        store.apply(QadaEstimate(totalDays: 1, deductedDays: 0, effectiveDays: 1, perPrayer: 1, witr: 0),
                    trackWitr: false)
        XCTAssertTrue(store.markPaid(.asr))
        XCTAssertFalse(store.markPaid(.asr))
        XCTAssertEqual(store.remaining(.asr), 0)
    }

    func testUndoRestoresTheDebt() {
        let store = makeStore()
        store.apply(QadaEstimate(totalDays: 3, deductedDays: 0, effectiveDays: 3, perPrayer: 3, witr: 0),
                    trackWitr: false)
        store.markPaid(.isha)
        XCTAssertTrue(store.undoPaid(.isha))
        XCTAssertEqual(store.remaining(.isha), 3)
        XCTAssertEqual(store.paid(.isha), 0)
        XCTAssertFalse(store.undoPaid(.isha), "Nothing left to undo")
    }

    func testCompletionIsRecordedOnlyWhenEverythingIsDone() {
        let store = makeStore()
        store.apply(QadaEstimate(totalDays: 1, deductedDays: 0, effectiveDays: 1, perPrayer: 1, witr: 0),
                    trackWitr: false)
        for prayer in QadaStore.fardPrayers { store.markPaid(prayer) }
        XCTAssertEqual(store.totalRemaining, 0)
        XCTAssertTrue(store.isComplete)
        XCTAssertNotNil(store.completedAt)
    }

    func testProgressIsZeroWhenNothingWasEverOwed() {
        let store = makeStore()
        XCTAssertEqual(store.progress, 0)
        XCTAssertFalse(store.isComplete)
        XCTAssertNil(store.projectedCompletion())
    }

    func testMilestoneFiresOnce() {
        let store = makeStore()
        store.apply(QadaEstimate(totalDays: 2, deductedDays: 0, effectiveDays: 2, perPrayer: 2, witr: 0),
                    trackWitr: false)   // 10 total
        store.markPaid(.fajr)           // 10%
        XCTAssertEqual(store.consumeNewMilestone(), 10)
        XCTAssertNil(store.consumeNewMilestone())
    }

    func testManualEditsNeverGoNegative() {
        let store = makeStore()
        store.setRemaining(-40, for: .dhuhr)
        XCTAssertEqual(store.remaining(.dhuhr), 0)
    }

    func testResetClearsEverything() {
        let store = makeStore()
        store.apply(QadaEstimate(totalDays: 5, deductedDays: 0, effectiveDays: 5, perPrayer: 5, witr: 0),
                    trackWitr: false)
        store.markPaid(.maghrib)
        store.reset()
        XCTAssertEqual(store.totalRemaining, 0)
        XCTAssertEqual(store.startingTotal, 0)
        XCTAssertFalse(store.isSetUp)
    }
}
