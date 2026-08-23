import Foundation

// MARK: - Arabic normalisation

/// Fold Arabic to a searchable skeleton.
///
/// A reader types `الرحمن` on a plain keyboard; the mushaf holds
/// `ٱلرَّحْمَٰنِ` — wasla, shadda, sukun, superscript alef, kasra. Matching
/// those literally finds nothing. So both sides are folded down to bare letters
/// before comparison.
///
/// This never touches stored text. The fold is built into a throwaway index and
/// the ayah that comes back is always Tanzil's, byte for byte — which is what
/// the CC BY "changing it is not allowed" clause requires.
enum ArabicFold {

    /// Harakat, tanwin, shadda, sukun, superscript alef, Qur'anic annotation
    /// marks, tatweel, and the Arabic-script combining block generally.
    private static let strippedScalars: Set<UnicodeScalar> = {
        var set = Set<UnicodeScalar>()
        // Fathatan…sukun + superscript alef and friends.
        for v in 0x064B...0x065F { if let s = UnicodeScalar(v) { set.insert(s) } }
        // Qur'anic annotation signs (sajda mark, small waw/yeh, pause marks).
        for v in 0x06D6...0x06ED { if let s = UnicodeScalar(v) { set.insert(s) } }
        set.insert(UnicodeScalar(0x0640)!)   // tatweel
        set.insert(UnicodeScalar(0x0670)!)   // superscript alef
        set.insert(UnicodeScalar(0x061C)!)   // Arabic letter mark
        set.insert(UnicodeScalar(0x200B)!)   // zero-width space
        set.insert(UnicodeScalar(0x200C)!)
        set.insert(UnicodeScalar(0x200D)!)
        return set
    }()

    /// Letter-shape unification: every alef variant → bare alef, alef maksura →
    /// yeh, teh marbuta → heh, and the hamza carriers collapse too, because
    /// almost nobody types them the way the mushaf spells them.
    private static let letterMap: [UnicodeScalar: UnicodeScalar] = [
        UnicodeScalar(0x0622)!: UnicodeScalar(0x0627)!,   // آ → ا
        UnicodeScalar(0x0623)!: UnicodeScalar(0x0627)!,   // أ → ا
        UnicodeScalar(0x0625)!: UnicodeScalar(0x0627)!,   // إ → ا
        UnicodeScalar(0x0671)!: UnicodeScalar(0x0627)!,   // ٱ → ا
        UnicodeScalar(0x0649)!: UnicodeScalar(0x064A)!,   // ى → ي
        UnicodeScalar(0x0629)!: UnicodeScalar(0x0647)!,   // ة → ه
        UnicodeScalar(0x0624)!: UnicodeScalar(0x0648)!,   // ؤ → و
        UnicodeScalar(0x0626)!: UnicodeScalar(0x064A)!    // ئ → ي
    ]

    /// Fold Arabic. Latin text is lowercased and diacritic-folded so the same
    /// function can index a Turkish or English translation too.
    static func fold(_ input: String) -> String {
        var out = String.UnicodeScalarView()
        out.reserveCapacity(input.unicodeScalars.count)
        var lastWasSpace = true   // also trims a leading space

        for scalar in input.unicodeScalars {
            if strippedScalars.contains(scalar) { continue }
            if CharacterSet.whitespacesAndNewlines.contains(scalar) {
                if !lastWasSpace { out.append(" "); lastWasSpace = true }
                continue
            }
            lastWasSpace = false
            out.append(letterMap[scalar] ?? scalar)
        }

        var folded = String(out)
        if folded.hasSuffix(" ") { folded.removeLast() }

        // Latin side: strip case and accents (İ/ı handled by the Turkish locale).
        if folded.unicodeScalars.contains(where: { $0.value < 0x0590 }) {
            folded = folded.folding(
                options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive],
                locale: L10n.appLocale
            )
        }
        return folded
    }
}

// MARK: - Results

struct QuranSearchResult: Identifiable, Hashable, Sendable {
    let ref: AyahRef
    /// Original, unmodified ayah text.
    let arabic: String
    /// Translation line when a pack is installed, else `nil`.
    let translation: String?
    /// Which layer produced the hit — drives the "found in Arabic / in the
    /// translation" caption so a result never looks arbitrary.
    let matchedTranslation: Bool

    var id: String { ref.id }
}

// MARK: - Engine

/// Whole-corpus substring search over the folded skeleton.
///
/// Linear over 6,236 ayahs on a background task. Measured shape: one fold of
/// the corpus (built once, ~6 MB of `String`) then a `range(of:)` per ayah.
/// Fast enough that a debounce, not an index, is the right answer — and it
/// keeps the bundle 6 MB smaller than a prebuilt inverted index would.
actor QuranSearchEngine {
    static let shared = QuranSearchEngine()

    /// Folded corpus, one entry per sura, ayahs still separated by `\n`.
    private var foldedArabic: [[String]]?
    private var foldedTranslation: [String: [[String]]] = [:]

    private func arabicIndex() async throws -> [[String]] {
        if let foldedArabic { return foldedArabic }
        let suras = try await QuranTextStore.shared.displaySuraStrings()
        let built = await Task.detached(priority: .utility) {
            suras.map { sura in
                sura.components(separatedBy: "\n").map(ArabicFold.fold)
            }
        }.value
        foldedArabic = built
        return built
    }

    private func translationIndex(_ packID: String) async -> [[String]]? {
        if let cached = foldedTranslation[packID] { return cached }
        var built: [[String]] = []
        built.reserveCapacity(114)
        for sura in 1...114 {
            guard let lines = await TranslationStore.shared.lines(packID: packID, sura: sura)
            else { return nil }
            built.append(lines.map(ArabicFold.fold))
        }
        foldedTranslation[packID] = built
        return built
    }

    /// Search Arabic, plus the given translation pack when one is installed.
    /// Honours cancellation so a fast typist does not queue up sweeps.
    func search(
        _ query: String,
        translationPackID: String? = nil,
        limit: Int = 200
    ) async -> [QuranSearchResult] {
        let needle = ArabicFold.fold(query)
        guard needle.count >= 2 else { return [] }

        guard let arabic = try? await arabicIndex() else { return [] }

        let translationIdx: [[String]]?
        if let translationPackID {
            translationIdx = await translationIndex(translationPackID)
        } else {
            translationIdx = nil
        }

        var out: [QuranSearchResult] = []
        out.reserveCapacity(min(limit, 64))

        for (suraOffset, ayahs) in arabic.enumerated() {
            if Task.isCancelled { return [] }
            let sura = suraOffset + 1
            var rawLines: [String]?

            for (ayahOffset, folded) in ayahs.enumerated() {
                let inArabic = folded.contains(needle)
                let translationLine = translationIdx.flatMap { idx -> String? in
                    let lines = idx[suraOffset]
                    guard ayahOffset < lines.count else { return nil }
                    return lines[ayahOffset].contains(needle) ? lines[ayahOffset] : nil
                }
                guard inArabic || translationLine != nil else { continue }

                // Only pay for the *original* strings on a hit.
                if rawLines == nil {
                    rawLines = (try? await QuranTextStore.shared.ayahs(sura: sura))?.map(\.text)
                }
                guard let rawLines, ayahOffset < rawLines.count else { continue }

                let ref = AyahRef(sura, ayahOffset + 1)
                var original: String?
                if translationIdx != nil, let translationPackID {
                    original = await TranslationStore.shared.line(packID: translationPackID, ref: ref)
                }

                out.append(
                    QuranSearchResult(
                        ref: ref,
                        arabic: rawLines[ayahOffset],
                        translation: original,
                        matchedTranslation: !inArabic
                    )
                )
                if out.count >= limit { return out }
            }
        }
        return out
    }

    /// Jump-to-citation: `"2:255"`, `"2 255"`, `"18:10-12"` → the first ayah.
    nonisolated static func citation(in query: String) -> AyahRef? {
        let cleaned = query.trimmingCharacters(in: .whitespaces)
        let parts = cleaned.split(whereSeparator: { ":.,-/ ".contains($0) })
        guard parts.count >= 2,
              let sura = Int(parts[0]), let ayah = Int(parts[1])
        else { return nil }
        return QuranCatalog.normalize(AyahRef(sura, ayah))
    }

    func purge() {
        foldedArabic = nil
        foldedTranslation.removeAll(keepingCapacity: false)
    }
}
