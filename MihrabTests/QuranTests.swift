import XCTest

// MARK: - Metadata

final class QuranCatalogTests: XCTestCase {

    func testCatalogShape() {
        XCTAssertEqual(QuranCatalog.suras.count, 114)
        XCTAssertEqual(QuranCatalog.suras.reduce(0) { $0 + $1.ayahCount }, 6236)
        XCTAssertEqual(QuranCatalog.juz.count, 30)
        XCTAssertEqual(QuranCatalog.hizb.count, 60)
        XCTAssertEqual(QuranCatalog.quarters.count, 240)
        XCTAssertEqual(QuranCatalog.pages.count, 604)
        XCTAssertEqual(QuranCatalog.sajdas.count, 15)
    }

    func testKnownSuraFacts() {
        let fatiha = QuranCatalog.sura(1)
        XCTAssertEqual(fatiha?.ayahCount, 7)
        XCTAssertEqual(fatiha?.revelation, .meccan)
        // Al-Fātiḥa's basmala *is* ayah 1, so it must not be drawn separately.
        XCTAssertEqual(fatiha?.hasSeparateBasmala, false)

        let baqara = QuranCatalog.sura(2)
        XCTAssertEqual(baqara?.ayahCount, 286)
        XCTAssertEqual(baqara?.revelation, .medinan)
        XCTAssertEqual(baqara?.turkishName, "Bakara")

        // At-Tawba is the one sura with no basmala at all.
        XCTAssertEqual(QuranCatalog.sura(9)?.hasSeparateBasmala, false)
        XCTAssertEqual(QuranCatalog.sura(114)?.ayahCount, 6)
        XCTAssertNil(QuranCatalog.sura(0))
        XCTAssertNil(QuranCatalog.sura(115))
    }

    func testEveryTurkishNameIsPresentAndDistinct() {
        let names = QuranCatalog.suras.map(\.turkishName)
        XCTAssertEqual(names.count, 114)
        XCTAssertFalse(names.contains { $0.isEmpty })
        XCTAssertEqual(Set(names).count, 114)
    }

    func testAbsoluteIndexRoundTrips() {
        for ref in [AyahRef(1, 1), AyahRef(2, 255), AyahRef(18, 10), AyahRef(114, 6)] {
            let index = QuranCatalog.absoluteIndex(of: ref)
            XCTAssertNotNil(index)
            XCTAssertEqual(QuranCatalog.ref(atAbsoluteIndex: index!), ref)
        }
        XCTAssertEqual(QuranCatalog.absoluteIndex(of: AyahRef(1, 1)), 1)
        XCTAssertEqual(QuranCatalog.absoluteIndex(of: AyahRef(2, 1)), 8)
        XCTAssertEqual(QuranCatalog.absoluteIndex(of: AyahRef(114, 6)), 6236)
        XCTAssertNil(QuranCatalog.absoluteIndex(of: AyahRef(2, 287)))
        XCTAssertNil(QuranCatalog.ref(atAbsoluteIndex: 6237))
    }

    func testEveryAyahHasAnIndexExactlyOnce() {
        var seen = Set<Int>()
        for sura in QuranCatalog.suras {
            for ayah in 1...sura.ayahCount {
                guard let index = QuranCatalog.absoluteIndex(of: AyahRef(sura.number, ayah)) else {
                    return XCTFail("no index for \(sura.number):\(ayah)")
                }
                XCTAssertTrue(seen.insert(index).inserted, "duplicate index \(index)")
            }
        }
        XCTAssertEqual(seen.count, 6236)
    }

    func testDivisionLookups() {
        XCTAssertEqual(QuranCatalog.juz[1].start, AyahRef(2, 142))
        XCTAssertEqual(QuranCatalog.juz[29].start, AyahRef(78, 1))
        XCTAssertEqual(QuranCatalog.juz[0].end, QuranCatalog.previousAyah(before: AyahRef(2, 142)))
        XCTAssertEqual(QuranCatalog.juz[29].end, AyahRef(114, 6))

        XCTAssertEqual(QuranCatalog.juzNumber(containing: AyahRef(1, 1)), 1)
        XCTAssertEqual(QuranCatalog.juzNumber(containing: AyahRef(2, 255)), 3)
        XCTAssertEqual(QuranCatalog.juzNumber(containing: AyahRef(114, 6)), 30)

        XCTAssertEqual(QuranCatalog.page(containing: AyahRef(1, 1)), 1)
        XCTAssertEqual(QuranCatalog.page(containing: AyahRef(2, 1)), 2)
        XCTAssertEqual(QuranCatalog.page(containing: AyahRef(2, 255)), 42)
        XCTAssertEqual(QuranCatalog.page(containing: AyahRef(114, 6)), 604)

        XCTAssertEqual(QuranCatalog.hizbNumber(containing: AyahRef(1, 1)), 1)
        XCTAssertEqual(QuranCatalog.hizbNumber(containing: AyahRef(114, 6)), 60)
    }

    func testDivisionsTileTheMushafWithoutGaps() {
        for (a, b) in zip(QuranCatalog.juz, QuranCatalog.juz.dropFirst()) {
            XCTAssertEqual(QuranCatalog.nextAyah(after: a.end), b.start)
        }
        for (a, b) in zip(QuranCatalog.pages, QuranCatalog.pages.dropFirst()) {
            XCTAssertEqual(QuranCatalog.nextAyah(after: a.end), b.start)
        }
    }

    func testSajdaMarks() {
        XCTAssertNotNil(QuranCatalog.sajda(at: AyahRef(32, 15)))
        XCTAssertEqual(QuranCatalog.sajda(at: AyahRef(32, 15))?.isObligatory, true)
        XCTAssertNotNil(QuranCatalog.sajda(at: AyahRef(96, 19)))
        XCTAssertNil(QuranCatalog.sajda(at: AyahRef(2, 255)))
    }

    func testWalkingAcrossSuraBoundaries() {
        XCTAssertEqual(QuranCatalog.nextAyah(after: AyahRef(1, 7)), AyahRef(2, 1))
        XCTAssertEqual(QuranCatalog.previousAyah(before: AyahRef(2, 1)), AyahRef(1, 7))
        XCTAssertNil(QuranCatalog.previousAyah(before: AyahRef(1, 1)))
        XCTAssertNil(QuranCatalog.nextAyah(after: AyahRef(114, 6)))
    }

    func testCitationParsing() {
        XCTAssertEqual(AyahRef(citation: "2:255"), AyahRef(2, 255))
        XCTAssertEqual(AyahRef(2, 255).citation, "2:255")
        XCTAssertNil(AyahRef(citation: "115:1"))
        XCTAssertNil(AyahRef(citation: "2"))
        XCTAssertNil(AyahRef(citation: "abc"))

        XCTAssertEqual(QuranSearchEngine.citation(in: "2:255"), AyahRef(2, 255))
        XCTAssertEqual(QuranSearchEngine.citation(in: "18 10"), AyahRef(18, 10))
        // Out-of-range ayah clamps into the sura rather than failing silently.
        XCTAssertEqual(QuranSearchEngine.citation(in: "1:99"), AyahRef(1, 7))
        XCTAssertNil(QuranSearchEngine.citation(in: "salam"))
    }
}

// MARK: - Text integrity
//
// The Tanzil licence permits verbatim copies and forbids changing the text.
// These tests are the mechanical half of that promise.

final class QuranTextTests: XCTestCase {

    func testCorpusLoadsWithTheExpectedShape() async throws {
        let payload = try await QuranTextStore.shared.load()
        XCTAssertEqual(payload.suras.count, 114)
        XCTAssertEqual(payload.ayahCount, 6236)
        XCTAssertEqual(payload.basmalaPrefixLengths.count, 114)
        XCTAssertEqual(payload.script, "uthmani")
    }

    func testCopyrightNoticeSurvivesInTheBundle() async throws {
        let payload = try await QuranTextStore.shared.load()
        XCTAssertTrue(payload.notice.contains("Tanzil"))
        XCTAssertTrue(payload.notice.contains("CHANGING IT IS NOT ALLOWED"))
        XCTAssertTrue(payload.notice.contains("tanzil.net"))
        XCTAssertEqual(payload.license, "Creative Commons Attribution 3.0")
        XCTAssertEqual(payload.source, "Tanzil Project")
    }

    func testEverySuraHasExactlyTheAyahsMetadataClaims() async throws {
        for sura in QuranCatalog.suras {
            let ayahs = try await QuranTextStore.shared.ayahs(sura: sura.number)
            XCTAssertEqual(
                ayahs.count, sura.ayahCount,
                "sura \(sura.number) has \(ayahs.count) ayahs, metadata says \(sura.ayahCount)"
            )
            XCTAssertFalse(
                ayahs.contains { $0.text.trimmingCharacters(in: .whitespaces).isEmpty },
                "sura \(sura.number) has an empty ayah"
            )
        }
    }

    func testBasmalaIsLiftedOffOpeningAyahsButNeverFromFatihaOrTawba() async throws {
        let basmala = try await QuranTextStore.shared.basmala()
        XCTAssertFalse(basmala.isEmpty)

        // Al-Fātiḥa 1:1 *is* the basmala and must be returned whole.
        let fatiha = try await QuranTextStore.shared.ayahs(sura: 1)
        XCTAssertEqual(fatiha[0].text, basmala)

        // At-Tawba has no basmala; ayah 1 must be untouched.
        let tawba = try await QuranTextStore.shared.ayahs(sura: 9)
        XCTAssertFalse(tawba[0].text.hasPrefix(basmala))

        // Every other sura must have had it removed.
        for number in 2...114 where number != 9 {
            let first = try await QuranTextStore.shared.ayahs(sura: number)[0].text
            XCTAssertFalse(
                ArabicFold.fold(first).hasPrefix(ArabicFold.fold(basmala)),
                "sura \(number) still carries the basmala on ayah 1"
            )
            XCTAssertFalse(first.hasPrefix(" "), "sura \(number) ayah 1 starts with a stray space")
        }
    }

    func testSajdaFlagsReachTheRenderedAyah() async throws {
        let ayah = try await QuranTextStore.shared.ayah(AyahRef(32, 15))
        XCTAssertNotNil(ayah?.sajda)
        let plain = try await QuranTextStore.shared.ayah(AyahRef(32, 14))
        XCTAssertNil(plain?.sajda)
    }

    func testOutOfRangeAyahReturnsNilRatherThanCrashing() async throws {
        let ayah = try await QuranTextStore.shared.ayah(AyahRef(1, 99))
        XCTAssertNil(ayah)
    }
}

// MARK: - Search

final class ArabicFoldTests: XCTestCase {

    func testDiacriticsAreStripped() {
        // Vowelled and bare forms of the same word must fold together.
        XCTAssertEqual(ArabicFold.fold("ٱلرَّحْمَٰنِ"), ArabicFold.fold("الرحمن"))
        XCTAssertEqual(ArabicFold.fold("ٱلْحَمْدُ"), ArabicFold.fold("الحمد"))
    }

    func testAlefAndHamzaVariantsUnify() {
        let bare = ArabicFold.fold("ا")
        for variant in ["آ", "أ", "إ", "ٱ"] {
            XCTAssertEqual(ArabicFold.fold(variant), bare)
        }
        XCTAssertEqual(ArabicFold.fold("ى"), ArabicFold.fold("ي"))
        XCTAssertEqual(ArabicFold.fold("ة"), ArabicFold.fold("ه"))
    }

    func testWhitespaceIsCollapsedAndTrimmed() {
        XCTAssertEqual(ArabicFold.fold("  الله   اكبر  "), ArabicFold.fold("الله اكبر"))
    }

    func testLatinIsCaseAndAccentInsensitive() {
        XCTAssertEqual(ArabicFold.fold("Rahmân"), ArabicFold.fold("rahman"))
    }

    func testFoldingNeverMutatesTheStoredText() async throws {
        // The point of the fold: it is a throwaway index, not a rewrite.
        let before = try await QuranTextStore.shared.ayah(AyahRef(2, 255))?.text
        _ = ArabicFold.fold(before ?? "")
        let after = try await QuranTextStore.shared.ayah(AyahRef(2, 255))?.text
        XCTAssertEqual(before, after)
    }
}

final class QuranSearchTests: XCTestCase {

    func testUnvowelledQueryFindsVowelledText() async throws {
        // "الرحمن" typed on a plain keyboard must find the mushaf spelling.
        let results = await QuranSearchEngine.shared.search("الرحمن", limit: 20)
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.allSatisfy { $0.matchedTranslation == false })
        // Results carry the original text back, unmodified.
        XCTAssertTrue(results.allSatisfy { !$0.arabic.isEmpty })
    }

    /// `ٱلْحَمْدُ لِلَّهِ` occurs 23 times in the mushaf — a figure that can be
    /// checked against any concordance. If the text, the fold or the index
    /// drifts, this is the test that notices.
    func testKnownOccurrenceCount() async {
        let results = await QuranSearchEngine.shared.search("الحمد لله", limit: 500)
        XCTAssertEqual(results.count, 23)
        XCTAssertEqual(results.first?.ref, AyahRef(1, 2))
    }

    /// Every hit must be visible in the ayah the reader is shown. The index is
    /// built from the *display* text, so a sura's opening basmala can never
    /// produce a result whose ayah does not contain the query.
    func testEveryHitIsVisibleInTheDisplayedAyah() async {
        let needle = ArabicFold.fold("الرحمن")
        let results = await QuranSearchEngine.shared.search("الرحمن", limit: 500)
        XCTAssertFalse(results.isEmpty)
        for hit in results {
            XCTAssertTrue(
                ArabicFold.fold(hit.arabic).contains(needle),
                "\(hit.ref.citation) matched but the displayed ayah does not contain the query"
            )
        }
    }

    func testShortQueriesAreRejectedRatherThanScanningTheCorpus() async {
        let results = await QuranSearchEngine.shared.search("ا")
        XCTAssertTrue(results.isEmpty)
    }
}

// MARK: - Translation layer

final class QuranTranslationTests: XCTestCase {

    /// The licence decision, encoded. If someone lists a pack id without
    /// shipping a correspondingly licensed file, this fails loudly instead of
    /// the reader silently showing blank translation rows.
    func testEveryDeclaredPackHasABundledFile() {
        for id in TranslationPack.bundledIDs {
            XCTAssertNotNil(
                TranslationStore.shared.descriptor(for: id),
                "TranslationPack.bundledIDs lists '\(id)' but quran-trans-\(id).json is not in the bundle"
            )
        }
        XCTAssertEqual(TranslationPack.installed.count, TranslationPack.bundledIDs.count)
    }

    /// Documents the shipped state: a licensed Turkish meal now travels with
    /// the app. Every ayah of it must line up with the Arabic — a translation
    /// off by one verse is worse than none, and the loader is what enforces it.
    func testTurkishMealShipsAndAlignsWithTheArabic() throws {
        XCTAssertTrue(TranslationPack.hasAny)
        XCTAssertTrue(TranslationPack.bundledIDs.contains("turkish-shaban"))
        let pack = try XCTUnwrap(TranslationPack.installed.first { $0.id == "turkish-shaban" })
        _ = pack
    }

    func testEveryTranslatedSuraHasTheRightNumberOfAyahs() async throws {
        for sura in 1...114 {
            let expected = try XCTUnwrap(QuranCatalog.sura(sura)?.ayahCount)
            let lines = await TranslationStore.shared.lines(packID: "turkish-shaban", sura: sura)
            XCTAssertEqual(try XCTUnwrap(lines).count, expected,
                           "sura \(sura) has the wrong number of translated ayahs")
        }
    }
}

// MARK: - Hatim

final class HatimMathTests: XCTestCase {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return calendar
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    func testFullMushafScope() {
        let scope = HatimScope.fullMushaf
        XCTAssertEqual(scope.ayahCount, 6236)
        XCTAssertEqual(scope.pageCount, 604)
        XCTAssertTrue(scope.isFullMushaf)
    }

    func testJuzScopesTileTheMushaf() {
        var total = 0
        for number in 1...30 {
            guard let scope = HatimScope.juz(number) else { return XCTFail("no juz \(number)") }
            total += scope.ayahCount
            XCTAssertFalse(scope.isFullMushaf)
        }
        XCTAssertEqual(total, 6236)
        XCTAssertEqual(HatimScope.juz(1)?.start, 1)
        XCTAssertEqual(HatimScope.juz(30)?.end, 6236)
        XCTAssertNil(HatimScope.juz(0))
        XCTAssertNil(HatimScope.juz(31))
    }

    func testDaysBetweenCountsToday() {
        XCTAssertEqual(HatimMath.daysBetween(date(2027, 2, 8), date(2027, 2, 8), calendar: calendar), 1)
        XCTAssertEqual(HatimMath.daysBetween(date(2027, 2, 8), date(2027, 2, 9), calendar: calendar), 2)
        // A target in the past is zero days, never negative.
        XCTAssertEqual(HatimMath.daysBetween(date(2027, 2, 9), date(2027, 2, 8), calendar: calendar), 0)
    }

    func testFreshPlanHasNoProgressAndNoFabricatedPace() {
        let plan = HatimPlan(
            kind: .individual,
            title: "t",
            scope: .fullMushaf,
            startedAt: date(2027, 1, 1),
            targetDate: date(2027, 1, 30)
        )
        let progress = HatimMath.progress(for: plan, now: date(2027, 1, 1), calendar: calendar)
        XCTAssertEqual(progress.ayahsRead, 0)
        XCTAssertEqual(progress.pagesRead, 0)
        XCTAssertEqual(progress.fraction, 0)
        XCTAssertEqual(progress.percent, 0)
        XCTAssertFalse(progress.isComplete)
        // No reading yet means no honest projection.
        XCTAssertNil(progress.observedPagesPerDay)
        XCTAssertNil(progress.projectedFinish)
        XCTAssertNil(progress.isOnTrack)
        // 604 pages over 30 days.
        XCTAssertEqual(progress.pagesPerDay ?? 0, 604.0 / 30.0, accuracy: 0.001)
    }

    func testDailyShareShrinksAsPagesAreRead() {
        var plan = HatimPlan(
            kind: .individual,
            title: "t",
            scope: .fullMushaf,
            startedAt: date(2027, 1, 1),
            targetDate: date(2027, 1, 30)
        )
        let before = HatimMath.progress(for: plan, now: date(2027, 1, 1), calendar: calendar)
        plan.position = QuranCatalog.absoluteIndex(of: AyahRef(2, 142))!   // start of juz 2
        let after = HatimMath.progress(for: plan, now: date(2027, 1, 2), calendar: calendar)
        XCTAssertGreaterThan(after.pagesRead, 0)
        XCTAssertGreaterThan(after.fraction, before.fraction)
        XCTAssertNotNil(after.observedPagesPerDay)
        XCTAssertNotNil(after.projectedFinish)
    }

    func testCompletionIsExactAndStopsProjecting() {
        var plan = HatimPlan(
            kind: .individual,
            title: "t",
            scope: .fullMushaf,
            startedAt: date(2027, 1, 1),
            targetDate: date(2027, 1, 30)
        )
        plan.position = 6236
        let progress = HatimMath.progress(for: plan, now: date(2027, 1, 20), calendar: calendar)
        XCTAssertTrue(progress.isComplete)
        XCTAssertEqual(progress.percent, 100)
        XCTAssertEqual(progress.pagesRead, 604)
        XCTAssertEqual(progress.daysRemaining, 0)
        XCTAssertNil(progress.pagesPerDay)
        XCTAssertNil(progress.projectedFinish)
    }

    func testPaceBehindScheduleIsReportedAsBehind() {
        var plan = HatimPlan(
            kind: .individual,
            title: "t",
            scope: .fullMushaf,
            startedAt: date(2027, 1, 1),
            targetDate: date(2027, 1, 10)
        )
        // One page in five days against a nine-day target.
        plan.position = QuranCatalog.absoluteIndex(of: AyahRef(2, 6))!
        let progress = HatimMath.progress(for: plan, now: date(2027, 1, 5), calendar: calendar)
        XCTAssertEqual(progress.isOnTrack, false)
    }

    func testEndOfRamadanResolvesToRamadan() throws {
        let target = try XCTUnwrap(HatimMath.endOfRamadan(from: Date()))
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.timeZone = .current
        XCTAssertEqual(calendar.component(.month, from: target), 9)
        XCTAssertGreaterThan(target, Date())
    }
}

final class HatimInviteTests: XCTestCase {

    private var sample: HatimInvite {
        HatimInvite(
            groupID: "abc123def456",
            name: "Mahalle hatmi",
            shareCount: 30,
            targetDate: Date(timeIntervalSince1970: 1_800_000_000),
            organiser: nil
        )
    }

    func testCodeRoundTrips() throws {
        let code = try XCTUnwrap(sample.code)
        let decoded = try XCTUnwrap(HatimInvite.parse(code))
        XCTAssertEqual(decoded.groupID, sample.groupID)
        XCTAssertEqual(decoded.name, sample.name)
        XCTAssertEqual(decoded.shareCount, sample.shareCount)
        XCTAssertEqual(
            decoded.targetDate.timeIntervalSince1970,
            sample.targetDate.timeIntervalSince1970,
            accuracy: 1
        )
    }

    func testURLRoundTrips() throws {
        let url = try XCTUnwrap(sample.url)
        XCTAssertEqual(url.scheme, "revak")
        XCTAssertEqual(url.host(), "hatim")
        XCTAssertEqual(HatimInvite.parse(url: url)?.groupID, sample.groupID)
        XCTAssertEqual(HatimInvite.parse(url.absoluteString)?.groupID, sample.groupID)
    }

    func testCodeIsFoundInsideAPastedMessage() throws {
        let url = try XCTUnwrap(sample.url).absoluteString
        let pasted = "Selam! Hatme katılır mısın?\n\(url)\nAllah kabul etsin"
        XCTAssertEqual(HatimInvite.parse(pasted)?.groupID, sample.groupID)
    }

    func testCodeIsURLSafe() throws {
        let code = try XCTUnwrap(sample.code)
        XCTAssertFalse(code.contains("+"))
        XCTAssertFalse(code.contains("/"))
        XCTAssertFalse(code.contains("="))
    }

    func testGarbageIsRejectedRatherThanPartiallyDecoded() {
        XCTAssertNil(HatimInvite.parse(""))
        XCTAssertNil(HatimInvite.parse("hello"))
        XCTAssertNil(HatimInvite.parse("revak://hatim?c=zzzz"))
        XCTAssertNil(HatimInvite.parse("https://example.com/hatim?c=abc"))
    }

    func testInviteMessageCarriesTheLink() throws {
        let text = sample.shareText()
        XCTAssertTrue(text.contains(sample.name))
        XCTAssertTrue(text.contains("revak://hatim?c="))
    }
}
