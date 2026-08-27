import Foundation

// MARK: - Reference

/// A single ayah address. Ordered, so it can be compared and stored.
struct AyahRef: Codable, Hashable, Sendable, Comparable, Identifiable {
    let sura: Int
    let ayah: Int

    init(_ sura: Int, _ ayah: Int) {
        self.sura = sura
        self.ayah = ayah
    }

    var id: String { "\(sura):\(ayah)" }

    static func < (lhs: AyahRef, rhs: AyahRef) -> Bool {
        lhs.sura == rhs.sura ? lhs.ayah < rhs.ayah : lhs.sura < rhs.sura
    }

    /// `"2:255"` — the universal citation form, and the wire format for
    /// bookmarks, deep links and share text.
    var citation: String { "\(sura):\(ayah)" }

    init?(citation: String) {
        let parts = citation.split(separator: ":")
        guard parts.count == 2,
              let s = Int(parts[0]), let a = Int(parts[1]),
              (1...114).contains(s), a >= 1
        else { return nil }
        self.init(s, a)
    }
}

// MARK: - Sura

struct SuraInfo: Codable, Hashable, Sendable, Identifiable {
    enum Revelation: String, Codable, Sendable {
        case meccan, medinan
    }

    /// 1…114.
    let number: Int
    let ayahCount: Int
    let arabicName: String
    let turkishName: String
    let englishName: String
    let transliteration: String
    let revelation: Revelation
    /// Chronological order of revelation (1…114).
    let revelationOrder: Int
    let rukuCount: Int

    var id: Int { number }

    private enum CodingKeys: String, CodingKey {
        case number = "n"
        case ayahCount = "ayas"
        case arabicName = "ar"
        case turkishName = "tr"
        case englishName = "en"
        case transliteration = "tn"
        case revelation
        case revelationOrder = "order"
        case rukuCount = "rukus"
    }

    /// The name as this user reads it. Arabic UI gets the Arabic name; Turkish
    /// gets the Turkish spelling; English gets the transliteration, because
    /// "Al-Baqara" is how an English reader finds a sura, not "The Cow".
    var localizedName: String {
        switch L10n.language {
        case .arabic: arabicName
        case .turkish: turkishName
        case .english: transliteration
        }
    }

    /// Secondary line under the name — the meaning, never a repeat.
    var localizedMeaning: String {
        L10n.language == .english ? englishName : arabicName
    }

    var firstAyah: AyahRef { AyahRef(number, 1) }

    /// Al-Fātiḥa carries the basmala as ayah 1; at-Tawba has none. Every other
    /// sura is opened by a basmala that is *not* counted as an ayah.
    var hasSeparateBasmala: Bool { number != 1 && number != 9 }
}

// MARK: - Divisions

/// A juz, hizb or hizb-quarter — anything that is "a span starting here".
struct QuranDivision: Hashable, Sendable, Identifiable {
    let index: Int
    let start: AyahRef
    /// Inclusive last ayah of the division.
    let end: AyahRef

    var id: Int { index }
}

/// One page of the 604-page Madani mushaf.
struct MushafPage: Hashable, Sendable, Identifiable {
    let number: Int
    let start: AyahRef
    let end: AyahRef

    var id: Int { number }
}

struct SajdaMark: Hashable, Sendable, Identifiable {
    let ref: AyahRef
    /// Vâcib (obligatory) vs. müstehap (recommended). Schools differ on which
    /// is which; the flag is Tanzil's, reported as-is and labelled as such.
    let isObligatory: Bool

    var id: String { ref.id }
}

// MARK: - Catalogue

/// Every structural fact about the mushaf: chapters, juz, hizb, pages, sajdas.
///
/// Pure metadata, ~30 KB, loaded eagerly — it is what the library screen needs
/// before a single ayah of text is read. The 1.3 MB Arabic text is a separate
/// file behind `QuranTextStore`, and is *not* touched by opening this.
enum QuranCatalog {

    private struct Payload: Decodable {
        struct Ref: Decodable { let s: Int; let a: Int }
        struct Sajda: Decodable { let s: Int; let a: Int; let obligatory: Bool }
        let suras: [SuraInfo]
        let juz: [Ref]
        let quarters: [Ref]
        let pages: [Ref]
        let sajdas: [Sajda]
    }

    private final class BundleMarker {}

    private static let payload: Payload = {
        for bundle in [Bundle.main, Bundle(for: BundleMarker.self)] {
            if let url = bundle.url(forResource: "quran-meta", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let decoded = try? JSONDecoder().decode(Payload.self, from: data) {
                return decoded
            }
        }
        // A packaging fault must not be a launch crash. The library then shows
        // its honest empty state; `QuranTests` is what actually guarantees the
        // file ships.
        assertionFailure("Missing or invalid bundled resource: quran-meta.json")
        return Payload(suras: [], juz: [], quarters: [], pages: [], sajdas: [])
    }()

    // MARK: Suras

    static var suras: [SuraInfo] { payload.suras }

    static let totalAyahs = 6236
    static let totalPages = 604
    static let totalJuz = 30
    static let totalHizb = 60

    static func sura(_ number: Int) -> SuraInfo? {
        guard (1...114).contains(number) else { return nil }
        return payload.suras[number - 1]
    }

    /// Clamps a reference into the mushaf. Returns `nil` only for a sura number
    /// outside 1…114.
    static func normalize(_ ref: AyahRef) -> AyahRef? {
        guard let sura = sura(ref.sura) else { return nil }
        return AyahRef(sura.number, min(max(ref.ayah, 1), sura.ayahCount))
    }

    // MARK: Divisions

    private static func spans(_ starts: [Payload.Ref]) -> [QuranDivision] {
        starts.enumerated().map { offset, ref in
            let start = AyahRef(ref.s, ref.a)
            let end: AyahRef
            if offset + 1 < starts.count {
                let next = starts[offset + 1]
                end = previousAyah(before: AyahRef(next.s, next.a)) ?? start
            } else {
                end = AyahRef(114, 6)
            }
            return QuranDivision(index: offset + 1, start: start, end: end)
        }
    }

    static let juz: [QuranDivision] = spans(payload.juz)

    /// 240 quarters. Hizb *n* is quarters 4n-3 … 4n.
    static let quarters: [QuranDivision] = spans(payload.quarters)

    static let hizb: [QuranDivision] = {
        let q = quarters
        return (0..<60).map { i in
            QuranDivision(index: i + 1, start: q[i * 4].start, end: q[i * 4 + 3].end)
        }
    }()

    static let pages: [MushafPage] = spans(payload.pages).map {
        MushafPage(number: $0.index, start: $0.start, end: $0.end)
    }

    static let sajdas: [SajdaMark] = payload.sajdas.map {
        SajdaMark(ref: AyahRef($0.s, $0.a), isObligatory: $0.obligatory)
    }

    private static let sajdaSet: Set<AyahRef> = Set(sajdas.map(\.ref))

    static func sajda(at ref: AyahRef) -> SajdaMark? {
        guard sajdaSet.contains(ref) else { return nil }
        return sajdas.first { $0.ref == ref }
    }

    // MARK: Walking

    static func previousAyah(before ref: AyahRef) -> AyahRef? {
        if ref.ayah > 1 { return AyahRef(ref.sura, ref.ayah - 1) }
        guard ref.sura > 1, let previous = sura(ref.sura - 1) else { return nil }
        return AyahRef(previous.number, previous.ayahCount)
    }

    static func nextAyah(after ref: AyahRef) -> AyahRef? {
        guard let sura = sura(ref.sura) else { return nil }
        if ref.ayah < sura.ayahCount { return AyahRef(ref.sura, ref.ayah + 1) }
        guard ref.sura < 114 else { return nil }
        return AyahRef(ref.sura + 1, 1)
    }

    // MARK: Absolute position
    //
    // Everything progress-shaped — hatim percentages, "how far through the
    // juz", "which page am I on" — needs one linear coordinate. This is it:
    // the 1-based index of an ayah in the whole mushaf, 1…6236.

    /// Cumulative ayah count *before* each sura. `offsets[0] == 0`.
    private static let offsets: [Int] = {
        var running = 0
        var out: [Int] = []
        out.reserveCapacity(114)
        for sura in payload.suras {
            out.append(running)
            running += sura.ayahCount
        }
        return out
    }()

    static func absoluteIndex(of ref: AyahRef) -> Int? {
        guard let sura = sura(ref.sura), (1...sura.ayahCount).contains(ref.ayah) else { return nil }
        return offsets[ref.sura - 1] + ref.ayah
    }

    static func ref(atAbsoluteIndex index: Int) -> AyahRef? {
        guard (1...totalAyahs).contains(index) else { return nil }
        // Binary search over the offsets.
        var low = 0, high = 113
        while low < high {
            let mid = (low + high + 1) / 2
            if offsets[mid] < index { low = mid } else { high = mid - 1 }
        }
        return AyahRef(low + 1, index - offsets[low])
    }

    /// 1…604. `nil` only for a malformed reference.
    static func page(containing ref: AyahRef) -> Int? {
        guard let target = absoluteIndex(of: ref) else { return nil }
        var low = 0, high = pages.count - 1
        while low < high {
            let mid = (low + high + 1) / 2
            guard let midStart = absoluteIndex(of: pages[mid].start) else { return nil }
            if midStart <= target { low = mid } else { high = mid - 1 }
        }
        return pages[low].number
    }

    /// 1…30.
    static func juzNumber(containing ref: AyahRef) -> Int? {
        guard let target = absoluteIndex(of: ref) else { return nil }
        var low = 0, high = juz.count - 1
        while low < high {
            let mid = (low + high + 1) / 2
            guard let midStart = absoluteIndex(of: juz[mid].start) else { return nil }
            if midStart <= target { low = mid } else { high = mid - 1 }
        }
        return juz[low].index
    }

    /// 1…60.
    static func hizbNumber(containing ref: AyahRef) -> Int? {
        guard let target = absoluteIndex(of: ref) else { return nil }
        var low = 0, high = hizb.count - 1
        while low < high {
            let mid = (low + high + 1) / 2
            guard let midStart = absoluteIndex(of: hizb[mid].start) else { return nil }
            if midStart <= target { low = mid } else { high = mid - 1 }
        }
        return hizb[low].index
    }
}
