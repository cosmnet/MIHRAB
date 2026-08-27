import XCTest

// MARK: - Turkish meal (translation) install contract

/// The Turkish meal cannot ship until someone grants a licence
/// (see `Mihrab/Features/Quran/CONTENT_LICENSE.md` §3 and §6). What *can* be
/// guaranteed today is that the day the permission letter comes back, the
/// install is a single file drop and nothing else — no id list to remember, no
/// code change, and no way to accidentally ship a pack that silently misaligns
/// with the Arabic.
final class QuranTranslationInstallTests: XCTestCase {

    /// The filename the licensor's file has to use. Pinned because
    /// `CONTENT_LICENSE.md` tells the owner this exact name.
    func testPackFilenameContract() {
        XCTAssertEqual(TranslationPack.filePrefix, "quran-trans-")
    }

    /// The Turkish meal now ships. QuranEnc's terms allow redistribution on
    /// four conditions — no modification, credit the publisher and QuranEnc,
    /// carry the version, no unsuitable advertising — and Mihrab meets all
    /// four (it has no advertising at all). The assertions below are those
    /// conditions expressed as code.
    func testTurkishTranslationShipsAndCarriesItsLicence() throws {
        XCTAssertFalse(TranslationStore.discoveredURLs().isEmpty)
        let pack = try XCTUnwrap(TranslationPack.installed.first { $0.id == "turkish-shaban" },
                                 "the Turkish pack must install from the bundle alone")
        XCTAssertEqual(pack.languageCode, "tr")
        XCTAssertTrue(pack.attribution.contains("QuranEnc.com"), "source must be credited")
        XCTAssertTrue(pack.license.contains("1.1.0"), "the version must travel with the text")
        XCTAssertTrue(TranslationPack.hasAny)
    }

    /// Dropping one well-formed file is enough: it parses, validates and
    /// produces a complete descriptor with the licence line intact.
    func testOneValidFileIsEnoughToInstallAPack() throws {
        let url = try write(try packJSON())
        let pack = try XCTUnwrap(TranslationStore.descriptor(at: url),
                                 "A complete, well-formed pack must install from the file alone")
        XCTAssertEqual(pack.id, "test-meal")
        XCTAssertEqual(pack.title, "Test Meali")
        XCTAssertEqual(pack.attribution, "Test Yayınları")
        XCTAssertEqual(pack.license, "Licensed for redistribution in Mihrab")
        XCTAssertEqual(pack.languageCode, "tr")
    }

    /// A short file must be refused, not shown. One missing ayah shifts every
    /// later translation by one — the reader would confidently pair the wrong
    /// meal with the wrong ayah, which is worse than showing no meal at all.
    func testShortSuraIsRefused() throws {
        var suras = fullSuras()
        suras[1] = suras[1].components(separatedBy: "\n").dropLast().joined(separator: "\n")
        let url = try write(try packJSON(suras: suras))
        XCTAssertNil(TranslationStore.descriptor(at: url), "A sura with a missing ayah must not install")
    }

    func testLongSuraIsRefused() throws {
        var suras = fullSuras()
        suras[0] += "\nextra line"
        let url = try write(try packJSON(suras: suras))
        XCTAssertNil(TranslationStore.descriptor(at: url))
    }

    func testMissingSuraIsRefused() throws {
        let url = try write(try packJSON(suras: Array(fullSuras().dropLast())))
        XCTAssertNil(TranslationStore.descriptor(at: url))
    }

    func testUnidentifiedPackIsRefused() throws {
        let url = try write(try packJSON(id: ""))
        XCTAssertNil(TranslationStore.descriptor(at: url))
    }

    func testMalformedFileIsRefusedRatherThanCrashing() throws {
        let url = try write("{ this is not json")
        XCTAssertNil(TranslationStore.descriptor(at: url))
    }

    func testMissingFileIsRefusedRatherThanCrashing() {
        let url = URL(fileURLWithPath: "/nonexistent/quran-trans-nope.json")
        XCTAssertNil(TranslationStore.descriptor(at: url))
    }

    // MARK: Fixtures

    /// 114 suras, each with exactly the ayah count the mushaf metadata gives,
    /// ayahs separated by `U+000A` — the same container the Arabic uses.
    private func fullSuras() -> [String] {
        (1...114).map { sura in
            let count = QuranCatalog.sura(sura)?.ayahCount ?? 0
            return (1...max(count, 1)).map { "\(sura):\($0)" }.joined(separator: "\n")
        }
    }

    private func packJSON(id: String = "test-meal", suras: [String]? = nil) throws -> String {
        let payload: [String: Any] = [
            "id": id,
            "title": "Test Meali",
            "attribution": "Test Yayınları",
            "license": "Licensed for redistribution in Mihrab",
            "language": "tr",
            "suras": suras ?? fullSuras(),
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        return String(decoding: data, as: UTF8.self)
    }

    private func write(_ json: String) throws -> URL {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("\(TranslationPack.filePrefix)test-meal.json")
        try json.write(to: url, atomically: true, encoding: .utf8)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return url
    }
}

// MARK: - Zakat: the figures Diyanet publishes

/// The user asked not to be made to decide these ("Din bilmiyorum ki").
/// So the numbers must come from a citable authority, and the app must default
/// to what that authority recommends. Sources are recorded in
/// `ZakatCalculator`'s doc comments; this file pins the values.
final class ZakatNisabSourceTests: XCTestCase {

    /// 20 miskal of gold. Diyanet İşleri Başkanlığı publishes this as 80.18 g.
    func testGoldNisabIsDiyanetsFigure() {
        XCTAssertEqual(ZakatCalculator.goldNisabGrams, 80.18, accuracy: 1e-9)
    }

    /// 200 dirhem of silver, on the weight Diyanet uses alongside the 80.18 g
    /// gold figure.
    func testSilverNisabIsDiyanetsFigure() {
        XCTAssertEqual(ZakatCalculator.silverNisabGrams, 561.0, accuracy: 1e-9)
    }

    /// Rubu'l-uşr — one fortieth.
    func testRateIsOneFortieth() {
        XCTAssertEqual(ZakatCalculator.rate, 1.0 / 40.0, accuracy: 1e-12)
    }

    /// Diyanet's own guidance is to take gold as the basis; silver stays
    /// available for those who follow it, but it is not what we put in front of
    /// a user who told us they cannot make this call themselves.
    @MainActor
    func testDefaultBasisIsGold() {
        XCTAssertEqual(ZakatStore.State().basis, .gold)
        XCTAssertEqual(NisabBasis.recommended, .gold)
    }

    /// The silver threshold is the lower of the two at any realistic price
    /// ratio, which is exactly why the choice is not cosmetic.
    func testSilverThresholdIsLower() {
        let prices = MetalPrices(goldPerGram: 4_000, silverPerGram: 45, updatedAt: nil)
        let gold = ZakatCalculator.nisabValue(basis: .gold, prices: prices) ?? 0
        let silver = ZakatCalculator.nisabValue(basis: .silver, prices: prices) ?? 0
        XCTAssertGreaterThan(gold, 0)
        XCTAssertGreaterThan(silver, 0)
        XCTAssertLessThan(silver, gold)
    }

    /// No price feed, no baked-in fitre amount: an out-of-date figure in a
    /// worship app is worse than no figure.
    @MainActor
    func testNoPriceOrFitreAmountIsShipped() {
        XCTAssertEqual(MetalPrices().goldPerGram, 0)
        XCTAssertEqual(MetalPrices().silverPerGram, 0)
        XCTAssertFalse(MetalPrices().isUsable)
        XCTAssertEqual(ZakatStore.State().fitrePerPerson, 0)
        XCTAssertNil(ZakatCalculator.nisabValue(basis: .gold, prices: MetalPrices()))
        XCTAssertNil(ZakatCalculator.nisabValue(basis: .silver, prices: MetalPrices()))
    }

    // MARK: Fitre

    /// The figure Diyanet actually announced: 240 TL for Ramadan 2026→2027.
    /// <https://kurul.diyanet.gov.tr/tr/duyuru/din-isleri-yuksek-kurulu-2026-yili-fitre-miktarini-acikladi/019bb642-4872-7191-841e-408610f76b33>
    func testFitreFigureMatchesTheAnnouncement() {
        XCTAssertEqual(DiyanetFitre.amount, 240, accuracy: 1e-9)
        XCTAssertEqual(DiyanetFitre.currencyCode, "TRY")
        XCTAssertLessThan(DiyanetFitre.announcedOn, DiyanetFitre.validUntil)
    }

    /// The shipped figure expires, and that is handled *in the app*, not by a
    /// failing build: after `validUntil` the suggestion simply stops and the
    /// zakat screen asks for the current amount. This app is meant to keep
    /// working untouched for years, so nothing here may demand maintenance —
    /// what is asserted is the graceful expiry, not the freshness.
    func testExpiredFitreStopsSuggestingInsteadOfGoingStale() {
        let afterExpiry = DiyanetFitre.validUntil.addingTimeInterval(24 * 3600)
        XCTAssertNil(
            DiyanetFitre.suggestion(currencyCode: "TRY", on: afterExpiry),
            "an expired figure must never be suggested — last year's number is worse than none"
        )
        XCTAssertFalse(DiyanetFitre.isCurrent(on: afterExpiry))
    }

    /// It is a lira figure. Reusing "240" as euros or dollars would be nonsense,
    /// so it is offered only in lira, and only while it is current.
    func testFitreIsSuggestedOnlyInLiraAndOnlyWhileCurrent() {
        let whileValid = DiyanetFitre.announcedOn.addingTimeInterval(24 * 3600)
        XCTAssertEqual(DiyanetFitre.suggestion(currencyCode: "TRY", on: whileValid), 240)
        XCTAssertNil(DiyanetFitre.suggestion(currencyCode: "EUR", on: whileValid))
        XCTAssertNil(DiyanetFitre.suggestion(currencyCode: "USD", on: whileValid))

        let afterExpiry = DiyanetFitre.validUntil.addingTimeInterval(24 * 3600)
        XCTAssertNil(DiyanetFitre.suggestion(currencyCode: "TRY", on: afterExpiry),
                     "a superseded figure must never be suggested")
    }

    /// An unknown threshold must never be read as "everyone is liable".
    func testUnknownThresholdMeansNoLiability() {
        let result = ZakatCalculator.calculate(
            assets: ZakatAssets(cash: 1_000_000),
            prices: MetalPrices(),
            basis: .gold
        )
        XCTAssertEqual(result.nisabValue, 0)
        XCTAssertFalse(result.isLiable)
        XCTAssertEqual(result.zakatDue, 0)
    }
}
