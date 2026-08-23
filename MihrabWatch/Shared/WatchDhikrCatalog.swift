import Foundation

/// The six classics, on the wrist.
///
/// Deliberately a small local copy rather than a link to the phone's
/// `DhikrCatalog`: that type lives in `Mihrab/Features/Dhikr/DhikrLibrary.swift`
/// alongside SwiftData, achievements and sheet presentation, none of which
/// belongs in a watch binary. **The ids are byte-identical to the phone's**, so
/// a count made here lands on the right phrase when it reaches the phone. If
/// the phone ever renames one, this list must follow.
struct WatchDhikrItem: Identifiable, Hashable, Sendable {
    let id: String
    let arabic: String
    let transliteration: String
    let target: Int
}

enum WatchDhikrCatalog {
    static let subhanallah = WatchDhikrItem(
        id: "subhanallah", arabic: "سُبْحَانَ اللَّه",
        transliteration: "Subhanallah", target: 33)
    static let alhamdulillah = WatchDhikrItem(
        id: "alhamdulillah", arabic: "الْحَمْدُ لِلَّه",
        transliteration: "Alhamdulillah", target: 33)
    static let allahuAkbar = WatchDhikrItem(
        id: "allahu-akbar", arabic: "اللَّهُ أَكْبَر",
        transliteration: "Allahu Akbar", target: 34)
    static let tawhid = WatchDhikrItem(
        id: "la-ilaha", arabic: "لَا إِلَهَ إِلَّا اللَّه",
        transliteration: "La ilaha illallah", target: 33)
    static let salawat = WatchDhikrItem(
        id: "salawat", arabic: "اللَّهُمَّ صَلِّ عَلَى مُحَمَّد",
        transliteration: "Salawat", target: 100)
    static let istighfar = WatchDhikrItem(
        id: "astaghfirullah", arabic: "أَسْتَغْفِرُ اللَّه",
        transliteration: "Astaghfirullah", target: 100)

    static let all: [WatchDhikrItem] = [
        subhanallah, alhamdulillah, allahuAkbar, tawhid, salawat, istighfar,
    ]

    static let `default` = subhanallah

    static func item(id: String) -> WatchDhikrItem? {
        all.first { $0.id == id }
    }
}
