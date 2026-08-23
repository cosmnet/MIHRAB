import Foundation

// MARK: - Translation packs

/// A meal/translation layer that sits under the Arabic.
///
/// **Nothing ships in this layer today, and that is a licence decision, not an
/// omission.** The Arabic text is Creative Commons; every Turkish and English
/// translation we could find is either explicitly copyrighted (Diyanet), served
/// under a *non-commercial only* term that a subscription app cannot satisfy
/// (everything on tanzil.net/trans), or of a public-domain work whose only
/// available digitisations are copyrighted modernisations (Elmalılı). The full
/// finding, with the wording of each term and what the owner has to do to
/// unlock this, is in `Mihrab/Features/Quran/CONTENT_LICENSE.md`.
///
/// The type exists now so that dropping a licensed pack in later is a data
/// change, not a rewrite: add a `quran-trans-<id>.json` to
/// `Mihrab/Data/Bundled/`, list its id in `TranslationPack.bundledIDs`, done.
///
/// Until then `installed` is empty and the reader says so out loud. It must
/// never fill the gap with generated text — a fabricated ayah translation is
/// the single worst thing this app could ship.
struct TranslationPack: Identifiable, Hashable, Sendable {
    let id: String
    /// Display name of the translation ("Elmalılı Hamdi Yazır").
    let title: String
    /// Who to credit, verbatim from the licence.
    let attribution: String
    /// Human-readable licence line ("Public domain (FSEK m.27)").
    let license: String
    let languageCode: String

    /// Bundled pack ids, in display order. **Empty on purpose.**
    /// Adding an id here without adding a correspondingly licensed
    /// `quran-trans-<id>.json` will fail `QuranTests.testTranslationPacksResolve`.
    static let bundledIDs: [String] = []

    /// Packs whose data file is actually present in the bundle.
    static var installed: [TranslationPack] {
        bundledIDs.compactMap { TranslationStore.shared.descriptor(for: $0) }
    }

    static var hasAny: Bool { !installed.isEmpty }

    /// Packs matching the UI language, falling back to whatever is installed.
    static var preferred: [TranslationPack] {
        let code = L10n.language.rawValue
        let matching = installed.filter { $0.languageCode == code }
        return matching.isEmpty ? installed : matching
    }
}

// MARK: - Store

/// Loads translation packs on the same lazy, off-main pattern as the Arabic.
///
/// With no packs bundled every method returns `nil` / empty and no file is ever
/// opened, so this costs nothing today.
actor TranslationStore {
    static let shared = TranslationStore()

    struct Payload: Decodable, Sendable {
        let id: String
        let title: String
        let attribution: String
        let license: String
        let language: String
        /// 114 entries, ayahs separated by `U+000A`, same shape as the Arabic.
        let suras: [String]
    }

    private var loaded: [String: Payload] = [:]
    private var descriptors: [String: TranslationPack] = [:]

    private final class BundleMarker {}

    private nonisolated static func url(for id: String) -> URL? {
        for bundle in [Bundle.main, Bundle(for: BundleMarker.self)] {
            if let url = bundle.url(forResource: "quran-trans-\(id)", withExtension: "json") {
                return url
            }
        }
        return nil
    }

    /// Synchronous, non-actor peek used by `TranslationPack.installed`. Reads
    /// nothing but the bundle's file table when no pack is present.
    nonisolated func descriptor(for id: String) -> TranslationPack? {
        guard let url = Self.url(for: id),
              let data = try? Data(contentsOf: url),
              let payload = try? JSONDecoder().decode(Payload.self, from: data)
        else { return nil }
        return TranslationPack(
            id: payload.id,
            title: payload.title,
            attribution: payload.attribution,
            license: payload.license,
            languageCode: payload.language
        )
    }

    private func payload(_ id: String) async throws -> Payload? {
        if let cached = loaded[id] { return cached }
        guard let url = Self.url(for: id) else { return nil }
        let decoded = try await Task.detached(priority: .userInitiated) {
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            return try JSONDecoder().decode(Payload.self, from: data)
        }.value
        guard decoded.suras.count == 114 else { return nil }
        loaded[id] = decoded
        descriptors[id] = TranslationPack(
            id: decoded.id,
            title: decoded.title,
            attribution: decoded.attribution,
            license: decoded.license,
            languageCode: decoded.language
        )
        return decoded
    }

    /// Translation lines for one sura, index 0 == ayah 1.
    /// `nil` when the pack is not installed — the caller shows the empty state,
    /// it does **not** substitute anything.
    func lines(packID: String, sura: Int) async -> [String]? {
        guard (1...114).contains(sura),
              let payload = try? await payload(packID)
        else { return nil }
        return payload.suras[sura - 1].components(separatedBy: "\n")
    }

    func line(packID: String, ref: AyahRef) async -> String? {
        guard let lines = await lines(packID: packID, sura: ref.sura),
              (1...lines.count).contains(ref.ayah)
        else { return nil }
        return lines[ref.ayah - 1]
    }
}
