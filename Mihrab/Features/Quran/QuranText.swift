import Foundation

// MARK: - A rendered ayah

struct Ayah: Identifiable, Hashable, Sendable {
    let ref: AyahRef
    /// Arabic text exactly as Tanzil publishes it, minus only the basmala
    /// prefix on ayah 1 of a sura that opens with one (drawn separately as an
    /// ornament). Never normalised, never re-spelled.
    let text: String
    let sajda: SajdaMark?

    var id: String { ref.id }
}

// MARK: - Store

/// The 1.3 MB Arabic corpus.
///
/// **Why an actor.** 6,236 ayahs is small enough to hold but far too much to
/// decode on the main thread while a tab is animating in. The file is read and
/// decoded exactly once, off the main actor, and the result is 114 strings —
/// one per sura, ayahs joined by `\n`. Splitting a sura into ayahs happens on
/// demand and is cached, so opening al-Fātiḥa costs seven `Substring`s, not
/// six thousand.
///
/// **Licence.** `notice` carries Tanzil's copyright block out of the JSON
/// untouched; `QuranLicenceView` displays it. See `CONTENT_LICENSE.md`.
actor QuranTextStore {
    static let shared = QuranTextStore()

    struct Payload: Decodable, Sendable {
        let id: String
        let script: String
        let version: String
        let source: String
        let sourceURL: String
        let license: String
        let licenseURL: String
        let notice: String
        let ayahCount: Int
        /// 114 entries, ayahs separated by `U+000A`.
        let suras: [String]
        /// Unicode **scalars** to skip at the head of ayah 1 to drop the
        /// opening basmala. 0 for sura 1 and sura 9.
        let basmalaPrefixLengths: [Int]
    }

    enum LoadError: Error, Sendable {
        case missingResource
        case corrupt
    }

    private var payload: Payload?
    private var ayahCache: [Int: [String]] = [:]
    private var loadTask: Task<Payload, Error>?

    private final class BundleMarker {}

    private nonisolated static func locate() -> URL? {
        for bundle in [Bundle.main, Bundle(for: BundleMarker.self)] {
            if let url = bundle.url(forResource: "quran-uthmani", withExtension: "json") {
                return url
            }
        }
        return nil
    }

    /// Decodes once. Concurrent callers await the same task rather than each
    /// parsing their own copy.
    @discardableResult
    func load() async throws -> Payload {
        if let payload { return payload }
        if let loadTask { return try await loadTask.value }

        let task = Task<Payload, Error>.detached(priority: .userInitiated) {
            guard let url = Self.locate() else { throw LoadError.missingResource }
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let decoded = try JSONDecoder().decode(Payload.self, from: data)
            guard decoded.suras.count == 114,
                  decoded.basmalaPrefixLengths.count == 114
            else { throw LoadError.corrupt }
            return decoded
        }
        loadTask = task
        do {
            let decoded = try await task.value
            payload = decoded
            loadTask = nil
            return decoded
        } catch {
            loadTask = nil
            throw error
        }
    }

    /// True once the corpus is resident — lets a view skip its spinner.
    var isLoaded: Bool { payload != nil }

    var notice: String? { payload?.notice }
    var attribution: (source: String, url: String, license: String)? {
        guard let payload else { return nil }
        return (payload.source, payload.sourceURL, payload.license)
    }

    // MARK: Reading

    private func rawAyahs(sura: Int) async throws -> [String] {
        if let cached = ayahCache[sura] { return cached }
        let payload = try await load()
        guard (1...114).contains(sura) else { throw LoadError.corrupt }
        var lines = payload.suras[sura - 1].components(separatedBy: "\n")
        let skip = payload.basmalaPrefixLengths[sura - 1]
        if skip > 0, var first = lines.first {
            let scalars = first.unicodeScalars
            if scalars.count > skip {
                first = String(String.UnicodeScalarView(scalars.dropFirst(skip)))
                lines[0] = first
            }
        }
        ayahCache[sura] = lines
        return lines
    }

    /// Every ayah of one sura, basmala already lifted off ayah 1.
    func ayahs(sura: Int) async throws -> [Ayah] {
        let lines = try await rawAyahs(sura: sura)
        return lines.enumerated().map { offset, text in
            let ref = AyahRef(sura, offset + 1)
            return Ayah(ref: ref, text: text, sajda: QuranCatalog.sajda(at: ref))
        }
    }

    func ayah(_ ref: AyahRef) async throws -> Ayah? {
        let lines = try await rawAyahs(sura: ref.sura)
        guard (1...lines.count).contains(ref.ayah) else { return nil }
        return Ayah(ref: ref, text: lines[ref.ayah - 1], sajda: QuranCatalog.sajda(at: ref))
    }

    /// The basmala as its own string, taken from ayah 1 of al-Fātiḥa so the
    /// ornament is the real text and not something we typed.
    func basmala() async throws -> String {
        let payload = try await load()
        return payload.suras[0].components(separatedBy: "\n").first ?? ""
    }

    /// Backing store for search — the whole corpus, one string per sura, ayahs
    /// still separated by `\n`, and the opening basmala already lifted off
    /// ayah 1 exactly as the reader shows it.
    ///
    /// Indexing the *raw* payload instead would mean a search for "الرحمن"
    /// returned 112 sura openings whose displayed first ayah does not contain
    /// the word — a hit the reader cannot see. The index has to match the page.
    func displaySuraStrings() async throws -> [String] {
        var out: [String] = []
        out.reserveCapacity(114)
        for sura in 1...114 {
            out.append(try await rawAyahs(sura: sura).joined(separator: "\n"))
        }
        return out
    }

    /// Drops the per-sura split cache under memory pressure. The decoded
    /// payload stays; re-splitting is cheap, re-decoding is not.
    func purgeAyahCache() {
        ayahCache.removeAll(keepingCapacity: false)
    }
}
