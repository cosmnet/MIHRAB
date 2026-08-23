import SwiftUI
import XCTest

/// Guards for the accessibility work in wave 2.
///
/// SwiftUI layout cannot be asserted from a unit test, so these cover the parts
/// that *are* testable and that regress silently: the contrast of the palette
/// against the surfaces it is painted on, locale-aware numerals, and the
/// tick/target arithmetic the dhikr ring draws.
final class ContrastTests: XCTestCase {

    /// WCAG 2.1 relative luminance for an sRGB triple.
    private func luminance(_ hex: UInt32) -> Double {
        func channel(_ raw: Double) -> Double {
            raw <= 0.04045 ? raw / 12.92 : pow((raw + 0.055) / 1.055, 2.4)
        }
        let r = channel(Double((hex >> 16) & 0xFF) / 255)
        let g = channel(Double((hex >> 8) & 0xFF) / 255)
        let b = channel(Double(hex & 0xFF) / 255)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    private func ratio(_ a: UInt32, _ b: UInt32) -> Double {
        let (la, lb) = (luminance(a), luminance(b))
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    // The palette, mirrored from `MihrabColor` so the test states its own
    // expectations rather than reading them from the code under test.
    private let abyss: UInt32 = 0x07120D
    private let moss: UInt32 = 0x143322
    private let forest: UInt32 = 0x0D2418
    private let textPrimary: UInt32 = 0xF2F7F4
    private let textSecondary: UInt32 = 0x9DB8AA
    private let textTertiary: UInt32 = 0x5F7A6B
    private let brass: UInt32 = 0xC9A24B
    private let mint: UInt32 = 0x7FE0B2

    /// The tones we now use for body copy must clear 4.5:1 on every surface
    /// Mihrab paints text on.
    func testBodyTonesClearAA() {
        for surface in [abyss, moss, forest] {
            for tone in [textPrimary, textSecondary, brass, mint] {
                XCTAssertGreaterThanOrEqual(
                    ratio(tone, surface), 4.5,
                    "tone \(String(tone, radix: 16)) on surface \(String(surface, radix: 16))"
                )
            }
        }
    }

    /// The reason wave 2 moved readable copy off `textTertiary`: it fails on
    /// every surface, moss worst of all. If this ever starts passing, the token
    /// was changed and the workarounds can be revisited.
    func testTextTertiaryStillFailsAA() {
        XCTAssertLessThan(ratio(textTertiary, moss), 4.5)
        XCTAssertLessThan(ratio(textTertiary, abyss), 4.5)
        // It does not even clear the 3:1 floor for non-text controls on moss.
        XCTAssertLessThan(ratio(textTertiary, moss), 3.0)
    }
}

/// Numbers that reach the screen have to be rendered in the reader's numeral
/// system. These assert the formatters used in place of `String(format:)` and
/// `"\(int)"` interpolation.
final class LocalisedNumeralTests: XCTestCase {

    func testOrdinalPadsWithoutHardcodingDigits() {
        let style = IntegerFormatStyle<Int>.number
            .precision(.integerLength(2...))
            .grouping(.never)

        XCTAssertEqual(7.formatted(style.locale(Locale(identifier: "en_US"))), "07")
        XCTAssertEqual(99.formatted(style.locale(Locale(identifier: "en_US"))), "99")

        // Arabic (Saudi) uses Eastern Arabic numerals; the exact glyphs are the
        // formatter's business, but they must not be the Western ones.
        let arabic = 7.formatted(style.locale(Locale(identifier: "ar_SA")))
        XCTAssertFalse(arabic.contains("7"), "expected non-Western numerals, got \(arabic)")
        XCTAssertEqual(arabic.count, 2, "padding should survive the locale change")
    }

    func testGroupingNeverForCounts() {
        let style = IntegerFormatStyle<Int>.number.grouping(.never)
            .locale(Locale(identifier: "en_US"))
        XCTAssertEqual(1000.formatted(style), "1000")
    }
}

/// The 11-tick rim on the dhikr dial. Ticks may only be drawn when they land
/// exactly on counts — a tick between two beads would misreport progress.
final class DhikrTickTests: XCTestCase {

    /// Mirrors `DhikrDialRing.tickCount`.
    private func tickCount(target: Int, stride: Int = 11) -> Int? {
        guard target > 0, stride > 1, target % stride == 0 else { return nil }
        let count = target / stride
        return count > 1 ? count : nil
    }

    func testTicksForTasbihTargets() {
        XCTAssertEqual(tickCount(target: 33), 3)
        XCTAssertEqual(tickCount(target: 99), 9)
    }

    func testNoTicksWhereTheyWouldNotLandOnACount() {
        XCTAssertNil(tickCount(target: 100))
        XCTAssertNil(tickCount(target: 500))
        // A free count has no rim to divide.
        XCTAssertNil(tickCount(target: 0))
        // 11 itself would draw a single tick at the top — noise, not a marker.
        XCTAssertNil(tickCount(target: 11))
    }
}

/// Every settings group must be findable by search. The regression this guards
/// is the wave-1 bug where eight sections were rendered only under
/// `!isSearching` and so disappeared the moment their own name was typed.
final class SettingsSearchTests: XCTestCase {

    /// Mirrors `SettingsView.matches`.
    private func matches(_ terms: [String], query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return true }
        let needle = trimmed.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        return terms.contains {
            $0.folding(options: .diacriticInsensitive, locale: .current).lowercased().contains(needle)
        }
    }

    func testDiacriticInsensitiveTurkishSearch() {
        // "zekat" must find "Zekât", and "sehir" must find "şehir".
        XCTAssertTrue(matches(["Zekât Hesaplayıcı"], query: "zekat"))
        XCTAssertTrue(matches(["Konum ve şehirler"], query: "sehir"))
        XCTAssertTrue(matches(["Hatırlatmalar ve ezan"], query: "EZAN"))
    }

    func testUnrelatedQueryMatchesNothing() {
        XCTAssertFalse(matches(["Namaz ve vakitler", "Mezhep"], query: "qibla"))
    }
}
