import SwiftUI

/// A hand-curated grouping of the ninety-nine Names by theme.
/// Numbers are 1-based positions in `BundledContent.esma`; every Name from
/// 1…99 belongs to at least one collection (see `EsmaCollections.coverageIsComplete`).
struct EsmaCollection: Identifiable, Hashable {
    let id: String
    let symbol: String
    let numbers: [Int]
    let tint: Color
    let motif: ShaderMotif
    /// Suggested repetition count for the dhikr CTA of Names in this collection.
    let dhikrCount: Int

    static func == (lhs: EsmaCollection, rhs: EsmaCollection) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var localizedTitle: String {
        switch id {
        case "mercy": L10n.esmaCollectionMercy
        case "majesty": L10n.esmaCollectionMajesty
        case "knowledge": L10n.esmaCollectionKnowledge
        case "provision": L10n.esmaCollectionProvision
        case "justice": L10n.esmaCollectionJustice
        default: L10n.esmaCollectionLife
        }
    }

    var localizedNote: String {
        switch id {
        case "mercy": L10n.esmaCollectionMercyNote
        case "majesty": L10n.esmaCollectionMajestyNote
        case "knowledge": L10n.esmaCollectionKnowledgeNote
        case "provision": L10n.esmaCollectionProvisionNote
        case "justice": L10n.esmaCollectionJusticeNote
        default: L10n.esmaCollectionLifeNote
        }
    }

    /// Names in catalog order, guarded against an unexpected bundle size.
    var names: [EsmaName] {
        let all = BundledContent.esma
        return numbers.compactMap { n in
            let index = n - 1
            return all.indices.contains(index) ? all[index] : nil
        }
    }

    /// The Arabic of the first three Names — used as the card's calligraphic seal.
    var sealArabic: String {
        names.prefix(3).map(\.arabic).joined(separator: "  ")
    }
}

enum EsmaCollections {
    static let all: [EsmaCollection] = [
        EsmaCollection(
            id: "mercy",
            symbol: "heart.circle.fill",
            numbers: [1, 2, 5, 6, 14, 16, 30, 32, 34, 35, 42, 47, 79, 80, 82, 83, 99],
            tint: MihrabColor.mint,
            motif: .silk,
            dhikrCount: 100
        ),
        EsmaCollection(
            id: "majesty",
            symbol: "crown.fill",
            numbers: [3, 8, 9, 10, 15, 33, 36, 37, 41, 48, 53, 54, 65, 69, 70, 78, 84, 85, 88],
            tint: MihrabColor.brass,
            motif: .kufic,
            dhikrCount: 33
        ),
        EsmaCollection(
            id: "knowledge",
            symbol: "eye.circle.fill",
            numbers: [19, 26, 27, 28, 31, 40, 43, 46, 50, 51, 57, 64, 73, 74, 75, 76, 94, 98],
            tint: MihrabColor.sprout,
            motif: .caustics,
            dhikrCount: 99
        ),
        EsmaCollection(
            id: "provision",
            symbol: "leaf.circle.fill",
            numbers: [17, 18, 21, 39, 44, 45, 52, 56, 87, 89, 92],
            tint: MihrabColor.emerald,
            motif: .lantern,
            dhikrCount: 100
        ),
        EsmaCollection(
            id: "justice",
            symbol: "scalemass.fill",
            numbers: [20, 22, 23, 24, 25, 29, 71, 72, 81, 86, 90, 91, 97],
            tint: MihrabColor.brass,
            motif: .ripple,
            dhikrCount: 33
        ),
        EsmaCollection(
            id: "life",
            symbol: "shield.lefthalf.filled",
            numbers: [4, 7, 11, 12, 13, 38, 49, 55, 58, 59, 60, 61, 62, 63, 66, 67, 68, 77, 93, 95, 96],
            tint: MihrabColor.mint,
            motif: .aurora,
            dhikrCount: 99
        ),
    ]

    /// Collections a given 1-based Name number belongs to.
    static func collections(for number: Int) -> [EsmaCollection] {
        all.filter { $0.numbers.contains(number) }
    }

    /// The collection that drives a Name's tint, motif and dhikr count.
    static func primaryCollection(for number: Int) -> EsmaCollection {
        collections(for: number).first ?? all[0]
    }

    /// Debug guard — true when 1…99 are all represented.
    static var coverageIsComplete: Bool {
        let covered = Set(all.flatMap(\.numbers))
        return Set(1...99).isSubset(of: covered)
    }
}
