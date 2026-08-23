import SwiftUI

enum EsmaViewMode: String, CaseIterable, Identifiable {
    case list, grid

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .list: L10n.esmaViewList
        case .grid: L10n.esmaViewGrid
        }
    }

    var symbolName: String {
        switch self {
        case .list: "list.bullet"
        case .grid: "square.grid.2x2"
        }
    }
}

// MARK: - Browser

/// The ninety-nine, browsable. Search, theme chips and a favorites filter sit
/// above a body that flips between a rich list and a two-column calligraphy
/// grid — the two share a `matchedGeometryEffect` namespace so a Name glides
/// from row to tile instead of cross-fading.
struct EsmaBrowserView: View {
    @Binding var query: String
    /// When set, the browser shows only these Names (collection sheet) and
    /// hides the theme chips.
    var restrictedTo: [Int]? = nil
    var showsSearch: Bool = true

    var onSelect: (Int) -> Void

    private var library: EsmaLibrary { EsmaLibrary.shared }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage("mihrab.esma.viewMode") private var storedMode = EsmaViewMode.list.rawValue
    @State private var collectionFilter: String?
    @State private var favoritesOnly = false
    @Namespace private var calligraphy

    private var mode: EsmaViewMode {
        get { EsmaViewMode(rawValue: storedMode) ?? .list }
        nonmutating set { storedMode = newValue.rawValue }
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSearching: Bool { !trimmedQuery.isEmpty }

    private var entries: [EsmaEntry] {
        let all = BundledContent.esma
        var pool: [EsmaEntry] = all.indices.map { EsmaEntry(index: $0, name: all[$0]) }

        if let restrictedTo {
            let allowed = Set(restrictedTo)
            pool = pool.filter { allowed.contains($0.number) }
        } else if let collectionFilter,
                  let collection = EsmaCollections.all.first(where: { $0.id == collectionFilter }) {
            let allowed = Set(collection.numbers)
            pool = pool.filter { allowed.contains($0.number) }
        }

        if favoritesOnly {
            pool = pool.filter { library.isFavorite($0.name) }
        }

        guard isSearching else { return pool }
        return pool.filter { entry in
            entry.name.transliteration.localizedCaseInsensitiveContains(trimmedQuery)
                || entry.name.en.localizedCaseInsensitiveContains(trimmedQuery)
                || entry.name.tr.localizedCaseInsensitiveContains(trimmedQuery)
                || entry.name.arabic.contains(trimmedQuery)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if showsSearch {
                searchField
            }

            if restrictedTo == nil {
                filterChips
            }

            header

            content
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(isSearching || favoritesOnly || collectionFilter != nil
                 ? L10n.esmaResultCount(entries.count)
                 : L10n.esmaNinetyNine)
                .ornamentalCaps()

            Spacer(minLength: 8)

            viewModeToggle
        }
        .padding(.horizontal, 4)
    }

    private var viewModeToggle: some View {
        HStack(spacing: 2) {
            ForEach(EsmaViewMode.allCases) { candidate in
                let isOn = mode == candidate
                Button {
                    guard !isOn else { return }
                    HapticsEngine.shared.light()
                    withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : MihrabMotion.standardAnimation) {
                        mode = candidate
                    }
                } label: {
                    Image(systemName: candidate.symbolName)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(isOn ? MihrabColor.abyss : MihrabColor.textSecondary)
                        .frame(width: 42, height: 30)
                        .background {
                            if isOn {
                                Capsule().fill(MihrabColor.mint)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(candidate.localizedName))
                .accessibilityAddTraits(isOn ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(3)
        .background(Capsule().fill(MihrabColor.abyss.opacity(0.5)))
        .overlay { Capsule().strokeBorder(MihrabColor.mint.opacity(0.22), lineWidth: 1) }
        .accessibilityLabel(Text(L10n.esmaViewModeCaps))
    }

    // MARK: Search & filters

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.semibold))
                .foregroundStyle(MihrabColor.textTertiary)
            TextField(L10n.searchEsma, text: $query)
                .textFieldStyle(.plain)
                .foregroundStyle(MihrabColor.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if isSearching {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(MihrabColor.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(L10n.clear))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: MihrabSpace.hit)
        .background(Capsule().fill(MihrabColor.moss))
        .overlay {
            Capsule().strokeBorder(MihrabColor.mint.opacity(0.28), lineWidth: 1)
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(
                    title: L10n.esmaFilterAll,
                    symbol: "circle.grid.3x3.fill",
                    tint: MihrabColor.mint,
                    isOn: collectionFilter == nil && !favoritesOnly
                ) {
                    collectionFilter = nil
                    favoritesOnly = false
                }

                chip(
                    title: L10n.esmaFilterFavorites,
                    symbol: favoritesOnly ? "star.fill" : "star",
                    tint: MihrabColor.brass,
                    isOn: favoritesOnly
                ) {
                    favoritesOnly.toggle()
                }

                ForEach(EsmaCollections.all) { collection in
                    chip(
                        title: collection.localizedTitle,
                        symbol: collection.symbol,
                        tint: collection.tint,
                        isOn: collectionFilter == collection.id
                    ) {
                        collectionFilter = collectionFilter == collection.id ? nil : collection.id
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .scrollClipDisabled()
    }

    private func chip(
        title: String,
        symbol: String,
        tint: Color,
        isOn: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticsEngine.shared.light()
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : MihrabMotion.snappyAnimation) {
                action()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.caption2.weight(.semibold))
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isOn ? MihrabColor.abyss : MihrabColor.textSecondary)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background {
                Capsule().fill(isOn ? tint : MihrabColor.moss)
            }
            .overlay {
                Capsule().strokeBorder(
                    isOn ? .clear : MihrabColor.mint.opacity(0.22),
                    lineWidth: 1
                )
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        let items = entries
        if items.isEmpty {
            MihrabEmptyState(
                symbol: favoritesOnly ? "star" : "magnifyingglass",
                title: favoritesOnly ? L10n.esmaNoFavorites : L10n.esmaNoResults,
                message: favoritesOnly ? L10n.esmaNoFavoritesBody : L10n.esmaNoResultsBody
            )
            .padding(.top, 12)
            .transition(.opacity)
        } else if mode == .grid {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(items) { entry in
                    EsmaGridCell(entry: entry, namespace: calligraphy) { onSelect(entry.index) }
                }
            }
        } else {
            LazyVStack(spacing: 10) {
                ForEach(items) { entry in
                    EsmaListRow(entry: entry, namespace: calligraphy) { onSelect(entry.index) }
                }
            }
        }
    }
}

// MARK: - Entry

struct EsmaEntry: Identifiable, Hashable {
    /// 0-based position in `BundledContent.esma`.
    let index: Int
    let name: EsmaName

    var id: String { name.id }
    /// 1-based, the number shown to the user.
    var number: Int { index + 1 }
    var collection: EsmaCollection { EsmaCollections.primaryCollection(for: number) }
}

// MARK: - List row

struct EsmaListRow: View {
    let entry: EsmaEntry
    var namespace: Namespace.ID
    var action: () -> Void

    private var library: EsmaLibrary { EsmaLibrary.shared }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 14) {
                // Thin tint rail: the row's collection, readable without text.
                Capsule()
                    .fill(entry.collection.tint.opacity(0.75))
                    .frame(width: 3)
                    .frame(maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(String(format: "%02d", entry.number))
                            .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(MihrabColor.brass)
                        if library.hasVisited(entry.name) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                                .foregroundStyle(MihrabColor.emerald.opacity(0.8))
                        }
                    }

                    Text(entry.name.localizedMeaning)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(MihrabColor.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(entry.name.transliteration)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(MihrabColor.textTertiary)
                }

                Spacer(minLength: 8)

                Text(entry.name.arabic)
                    .font(MihrabFont.arabic(32))
                    .foregroundStyle(MihrabColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .environment(\.layoutDirection, .rightToLeft)
                    .matchedGeometryEffect(id: entry.id, in: namespace)

                EsmaStarButton(name: entry.name)
            }
            .padding(.vertical, 14)
            .padding(.trailing, 12)
            .frame(minHeight: 76)
            .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
            .contentShape(RoundedRectangle(cornerRadius: MihrabSpace.rowRadius, style: .continuous))
        }
        .pressable(reduceMotion)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(entry.number). \(entry.name.transliteration), \(entry.name.localizedMeaning)"))
    }
}

// MARK: - Grid cell

struct EsmaGridCell: View {
    let entry: EsmaEntry
    var namespace: Namespace.ID
    var action: () -> Void

    private var library: EsmaLibrary { EsmaLibrary.shared }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack {
                    Text(String(format: "%02d", entry.number))
                        .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(MihrabColor.brass)
                    Spacer()
                    if library.isFavorite(entry.name) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(MihrabColor.brass)
                    }
                }

                Spacer(minLength: 4)

                Text(entry.name.arabic)
                    .font(MihrabFont.arabic(40))
                    .foregroundStyle(MihrabColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .environment(\.layoutDirection, .rightToLeft)
                    .matchedGeometryEffect(id: entry.id, in: namespace)

                Spacer(minLength: 4)

                Text(entry.name.localizedMeaning)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(MihrabColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)

                Text(entry.name.transliteration)
                    .font(.caption2)
                    .foregroundStyle(MihrabColor.textTertiary)
                    .lineLimit(1)
            }
            .padding(14)
            .frame(height: 172)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(MihrabColor.moss)
            }
            .overlay {
                // Thin gold frame — the "illuminated page" cue.
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                MihrabColor.brass.opacity(0.55),
                                entry.collection.tint.opacity(0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .pressable(reduceMotion)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(entry.number). \(entry.name.transliteration), \(entry.name.localizedMeaning)"))
    }
}

// MARK: - Star

/// Favorite toggle with a short spring pop. 44pt target even though the glyph
/// is small.
struct EsmaStarButton: View {
    let name: EsmaName
    var size: CGFloat = 18

    private var library: EsmaLibrary { EsmaLibrary.shared }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pop = false

    private var isFavorite: Bool { library.isFavorite(name) }

    var body: some View {
        Button {
            let added = library.toggleFavorite(name)
            if added {
                HapticsEngine.shared.success()
            } else {
                HapticsEngine.shared.light()
            }
            guard !reduceMotion else { return }
            pop = true
            withAnimation(MihrabMotion.snappyAnimation) { pop = false }
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(isFavorite ? MihrabColor.brass : MihrabColor.textTertiary)
                .symbolEffect(.bounce, value: isFavorite)
                .scaleEffect(pop ? 1.35 : 1)
                .frame(width: MihrabSpace.hit, height: MihrabSpace.hit)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(isFavorite ? L10n.esmaRemoveFavorite : L10n.esmaAddFavorite))
        .accessibilityAddTraits(isFavorite ? [.isSelected, .isButton] : .isButton)
    }
}
