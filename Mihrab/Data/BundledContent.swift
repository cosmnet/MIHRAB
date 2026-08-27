import Foundation

// MARK: - Bundled content models

struct Hadith: Codable, Identifiable, Sendable, Hashable {
    let arabic: String
    let en: String
    let tr: String
    let narrator: String
    let source: String
    let grade: String

    var localizedTranslation: String {
        Locale.mihrabIsTurkish ? tr : en
    }

    var id: String { "\(source)-\(arabic.prefix(20))" }
}

struct EsmaName: Codable, Identifiable, Sendable, Hashable {
    let arabic: String
    let transliteration: String
    let en: String
    let tr: String

    var localizedMeaning: String { Locale.mihrabIsTurkish ? tr : en }

    var id: String { transliteration }
}

struct AdhkarPreset: Codable, Identifiable, Sendable {
    struct Item: Codable, Sendable, Hashable {
        let arabic: String
        let transliteration: String
        let target: Int
    }
    let id: String
    let titleEn: String
    let titleTr: String
    let items: [Item]
}

struct Dua: Codable, Sendable {
    let arabic: String
    let transliteration: String
    let en: String
    let tr: String
}

struct AdhkarContent: Codable, Sendable {
    let presets: [AdhkarPreset]
    let iftarDua: Dua
    let suhoorIntention: Dua
}

struct ReligiousDay: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let hijriMonth: Int
    let hijriDay: Int
    let nameEn: String
    let nameTr: String
    let nameAr: String
    let descEn: String
    let descTr: String

    var localizedName: String {
        if Locale.mihrabIsArabic { return nameAr }
        return Locale.mihrabIsTurkish ? nameTr : nameEn
    }
    var localizedDescription: String { Locale.mihrabIsTurkish ? descTr : descEn }
}

// MARK: - Loader

enum BundledContent {
    static let hadiths: [Hadith] = load("hadiths")
    static let esma: [EsmaName] = load("esma")
    static let religiousDays: [ReligiousDay] = load("religious_days")
    static let adhkar: AdhkarContent = load("adhkar")

    private final class BundleMarker {}

    /// Empty-but-valid stand-in used when a bundled file cannot be read.
    /// Shipping a crash-on-launch for a packaging fault is worse than an empty
    /// list the UI already knows how to render; the unit tests are the real
    /// guard that the resources are present.
    private static func fallback<T: Decodable>() -> T? {
        try? JSONDecoder().decode(T.self, from: Data("[]".utf8))
    }

    private static func load<T: Decodable>(_ name: String) -> T {
        // Bundle.main in the app; class bundle when running inside tests.
        let candidates = [Bundle.main, Bundle(for: BundleMarker.self)]
        for bundle in candidates {
            if let url = bundle.url(forResource: name, withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let decoded = try? JSONDecoder().decode(T.self, from: data) {
                return decoded
            }
        }
        assertionFailure("Missing or invalid bundled resource: \(name).json")
        guard let empty: T = fallback() else {
            fatalError("Missing bundled resource \(name).json and no empty form for \(T.self)")
        }
        return empty
    }
}

// MARK: - Daily rotation (deterministic by date, §4.7)

extension BundledContent {
    /// All users see the same hadith on the same day.
    static func hadith(for date: Date = Date()) -> Hadith {
        let days = Calendar(identifier: .gregorian)
            .dateComponents([.day], from: Date(timeIntervalSince1970: 0), to: date).day ?? 0
        return hadiths[abs(days) % hadiths.count]
    }

    /// Next occurrence of each religious day in the current Hijri year cycle.
    static func upcomingReligiousDays(from hijri: HijriDate) -> [(day: ReligiousDay, daysUntil: Int)] {
        let dayOfYear = hijriDayOfYear(month: hijri.month, day: hijri.day)
        return religiousDays.map { religious in
            var target = hijriDayOfYear(month: religious.hijriMonth, day: religious.hijriDay)
            if target < dayOfYear { target += 354 } // approximate Hijri year length
            return (religious, target - dayOfYear)
        }
        .sorted { $0.daysUntil < $1.daysUntil }
    }

    private static func hijriDayOfYear(month: Int, day: Int) -> Int {
        // Hijri months alternate 30/29 days; close enough for countdown pills.
        (month - 1) * 29 + (month - 1) / 2 + day
    }
}
