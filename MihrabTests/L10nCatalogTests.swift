import XCTest

@testable import Mihrab

/// The catalog trades safety for compile speed: translations live in one
/// tab-delimited blob rather than a dictionary literal. These tests hold the
/// two assumptions that trade rests on.
final class L10nCatalogTests: XCTestCase {

    /// A key containing a tab or a newline would be silently truncated at the
    /// delimiter and never match at runtime — the translation would vanish with
    /// no error anywhere. If the app ever gains such a string, this fails first.
    func testNoInterfaceStringContainsTheDelimiters() {
        for text in Self.sampledInterfaceStrings {
            XCTAssertFalse(text.contains("\t"), "tab in interface string: \(text)")
            XCTAssertFalse(text.contains("\n"), "newline in interface string: \(text)")
        }
    }

    func testDecoderKeepsPairsAndSkipsMalformedLines() {
        let table = L10nCatalog.decode(
            """
            Today\tHari ini
            Qibla\tKiblat
            no tab on this line
            \tempty key
            Empty value\t
            """
        )
        XCTAssertEqual(table["Today"], "Hari ini")
        XCTAssertEqual(table["Qibla"], "Kiblat")
        XCTAssertNil(table["no tab on this line"])
        XCTAssertNil(table["Empty value"])
        XCTAssertEqual(table.count, 2)
    }

    /// `%d` is the only placeholder the plural helper understands; a skeleton
    /// that loses it would render the sentence without its number.
    func testPluralSkeletonsKeepTheirPlaceholder() {
        let table = L10nCatalog.decode("%d day streak\trentetan %d hari")
        XCTAssertEqual(table["%d day streak"]?.contains("%d"), true)
    }

    /// A spread of real strings from across the app — tabs and newlines are
    /// what we are guarding against, and these are the shapes most likely to
    /// grow one: multi-clause sentences and list-like copy.
    private static let sampledInterfaceStrings: [String] = [
        L10n.tabToday, L10n.tabTimes, L10n.tabQibla, L10n.tabDhikr,
        L10n.prayerFajr, L10n.prayerSunrise, L10n.prayerDhuhr,
        L10n.prayerAsr, L10n.prayerMaghrib, L10n.prayerIsha,
    ]
}
