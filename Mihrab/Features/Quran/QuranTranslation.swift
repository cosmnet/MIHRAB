import Foundation

// MARK: - Translation packs

/// A meal/translation layer that sits under the Arabic.
///
/// **Nothing ships in this layer today, and that is a licence decision, not an
/// omission.** The Arabic text is Creative Commons; every Turkish and English
/// translation we could find is either explicitly copyrighted (Diyanet's
/// *Kur'an Yolu Meali*), served under a *non-commercial only* term that a
/// subscription app cannot satisfy (everything on tanzil.net/trans), or of a
/// public-domain work whose only available digitisations are copyrighted
/// modernisations (Elmalılı). The full finding — the wording of each term, and
/// the exact letter the owner has to send to unlock the Turkish layer — is in
/// `Mihrab/Features/Quran/CONTENT_LICENSE.md`.
///
/// **Installing a licensed pack is a one-file operation.** Drop a
/// `quran-trans-<id>.json` into `Mihrab/Data/Bundled/` and it appears. There is
/// no id list to remember to update: `TranslationPack.bundled` discovers every
/// `quran-trans-*.json` in the bundle at runtime and validates it before it can
/// be shown. `QuranTranslationInstallTests` pins that contract.
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

    /// Filename stem every pack must use, so discovery can find it.
    static let filePrefix = "quran-trans-"

    /// Ids that get to sort first when several packs are installed. A pack that
    /// is not listed here still shows — it just sorts after, alphabetically.
    /// This is presentation only; it is **not** an allow-list.
    static let preferredOrder: [String] = []

    /// Every valid pack found in the bundle, in display order.
    ///
    /// Discovery, not configuration: adding a licensed file is the whole
    /// install step. A file that fails validation (wrong shape, not 114 suras)
    /// is skipped rather than shown half-broken.
    static var installed: [TranslationPack] {
        TranslationStore.discoveredDescriptors().sorted { lhs, rhs in
            let l = preferredOrder.firstIndex(of: lhs.id) ?? Int.max
            let r = preferredOrder.firstIndex(of: rhs.id) ?? Int.max
            return l == r ? lhs.id < rhs.id : l < r
        }
    }

    /// Ids currently installed. Derived — never hand-maintained.
    static var bundledIDs: [String] { installed.map(\.id) }

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

        /// A pack is only usable if it covers the whole Qur'an with the right
        /// ayah counts. A short or mis-split file would silently misalign the
        /// meal against the Arabic — every ayah after the gap would show the
        /// wrong translation, which is worse than showing none.
        var isComplete: Bool {
            guard !id.isEmpty, suras.count == 114 else { return false }
            return suras.enumerated().allSatisfy { index, sura in
                sura.components(separatedBy: "\n").count == QuranCatalog.sura(index + 1)?.ayahCount
            }
        }

        var descriptor: TranslationPack {
            TranslationPack(id: id, title: title, attribution: attribution,
                            license: license, languageCode: language)
        }
    }

    private var loaded: [String: Payload] = [:]

    private final class BundleMarker {}

    /// Bundles a pack could live in: the app, and the test/framework bundle.
    private nonisolated static var searchBundles: [Bundle] {
        var bundles = [Bundle.main, Bundle(for: BundleMarker.self)]
        if let resource = Bundle.main.resourceURL,
           let bundle = Bundle(url: resource), !bundles.contains(bundle) {
            bundles.append(bundle)
        }
        return bundles
    }

    nonisolated static func url(for id: String) -> URL? {
        for bundle in searchBundles {
            if let url = bundle.url(forResource: "\(TranslationPack.filePrefix)\(id)",
                                    withExtension: "json") {
                return url
            }
        }
        return nil
    }

    /// Every `quran-trans-*.json` present in any search bundle.
    nonisolated static func discoveredURLs() -> [URL] {
        var seen: Set<String> = []
        var result: [URL] = []
        for bundle in searchBundles {
            for url in bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? [] {
                let name = url.deletingPathExtension().lastPathComponent
                guard name.hasPrefix(TranslationPack.filePrefix), seen.insert(name).inserted else { continue }
                result.append(url)
            }
        }
        return result
    }

    /// Descriptors for every discovered file that actually validates.
    nonisolated static func discoveredDescriptors() -> [TranslationPack] {
        discoveredURLs().compactMap { descriptor(at: $0) }
    }

    /// Reads and validates one pack file. `nil` when the file is missing,
    /// malformed, or incomplete — the reader then shows its honest empty state.
    nonisolated static func descriptor(at url: URL) -> TranslationPack? {
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe),
              let payload = try? JSONDecoder().decode(Payload.self, from: data),
              payload.isComplete
        else { return nil }
        return payload.descriptor
    }

    /// Synchronous, non-actor peek by id.
    nonisolated func descriptor(for id: String) -> TranslationPack? {
        guard let url = Self.url(for: id) else { return nil }
        return Self.descriptor(at: url)
    }

    private func payload(_ id: String) async throws -> Payload? {
        if let cached = loaded[id] { return cached }
        guard let url = Self.url(for: id) else { return nil }
        let decoded = try await Task.detached(priority: .userInitiated) {
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            return try JSONDecoder().decode(Payload.self, from: data)
        }.value
        guard decoded.isComplete else { return nil }
        loaded[id] = decoded
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
