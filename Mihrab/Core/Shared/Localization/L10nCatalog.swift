import Foundation

/// Translations for every language beyond the three (`en`, `tr`, `ar`) that are
/// written inline at the call sites.
///
/// **Why a table and not more parameters.** `L10n.string(en:tr:ar:)` is called
/// ~1300 times across the app, the widgets and the watch app. Growing that
/// signature to fifteen languages would mean editing every one of those call
/// sites for every language added, and would make each site unreadable. Here
/// the English text *is* the key, so adding a language is one new file.
///
/// **Why a delimited blob and not a dictionary literal.** A `[String: String]`
/// literal with a thousand entries makes the Swift type checker crawl — minutes
/// per file. A single multi-line string literal compiles instantly and is split
/// once, lazily, on first use.
///
/// **Why not a bundled JSON resource.** Five targets compile this folder; only
/// two of them have a resource bundle worth the plumbing. Source keeps the
/// widgets and the watch app translated for free.
enum L10nCatalog {

    /// The translation for `english`, or `nil` when this language has no entry
    /// for it — the caller then falls back to the English text, which is a
    /// worse experience than a translation but a far better one than a key.
    static func lookup(_ english: String) -> String? {
        table[english]
    }

    private static let table: [String: String] = {
        guard let raw = rawTable(for: L10n.language) else { return [:] }
        return decode(raw)
    }()

    private static func rawTable(for language: L10n.Language) -> String? {
        switch language {
        case .english, .turkish, .arabic: nil
        case .indonesian: L10nTableID.raw
        }
    }

    /// A count-carrying string. Interpolated copy cannot be keyed by its
    /// finished text — "3 prayers left today" is a different string every hour
    /// — so these are keyed by the English *skeleton* with `%d` standing in for
    /// the number.
    ///
    /// Languages that inflect the noun after a numeral are served by giving the
    /// table a form that reads correctly for every count; none of the languages
    /// shipped so far needs more than one.
    static func plural(_ skeleton: String, _ count: Int) -> String? {
        guard let text = table[skeleton] else { return nil }
        return text.replacingOccurrences(of: "%d", with: String(count))
    }

    /// One entry per line, English and translation separated by a tab. No key
    /// in the app contains a tab or a newline, which is what makes this format
    /// safe; `L10nCatalogTests` fails the build if that ever stops being true.
    static func decode(_ raw: String) -> [String: String] {
        var out: [String: String] = [:]
        out.reserveCapacity(1200)
        for line in raw.split(separator: "\n", omittingEmptySubsequences: true) {
            guard let tab = line.firstIndex(of: "\t") else { continue }
            let key = String(line[line.startIndex..<tab])
            let value = String(line[line.index(after: tab)...])
            guard !key.isEmpty, !value.isEmpty else { continue }
            out[key] = value
        }
        return out
    }
}
