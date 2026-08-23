import SwiftUI

/// The Esmaül Hüsna tab.
///
/// Opens on one Name to sit with — not on a list. The ninety-nine are still a
/// scroll away, but the first screen is contemplative: today's Name in large
/// calligraphy, a dhikr that starts in one tap, the user's progress across the
/// ninety-nine, and themed collections to wander into. Searching collapses all
/// of that and leaves only results.
struct DeenView: View {
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showHadith = false
    @State private var showDhikr = false
    @State private var esmaQuery = ""
    @State private var selection: EsmaSelection?
    @State private var activeCollection: EsmaCollection?
    @State private var appeared = false

    /// Deterministic per calendar day, so "today's Name" is the same all day.
    private var featuredIndex: Int {
        let total = max(BundledContent.esma.count, 1)
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return abs(day) % total
    }

    private var isSearchingEsma: Bool {
        !esmaQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MihrabBackdrop(surface: .deen, ramadanMode: theme.isRamadanMode)

                ScrollView {
                    VStack(spacing: 28) {
                        if !isSearchingEsma {
                            EsmaHomeView(
                                featuredIndex: featuredIndex,
                                onOpenName: { selection = EsmaSelection(id: $0) },
                                onOpenCollection: { activeCollection = $0 },
                                onOpenDhikr: { showDhikr = true }
                            )
                            .cardEntrance(index: 0, appeared: appeared, reduceMotion: reduceMotion)
                        }

                        EsmaBrowserView(query: $esmaQuery) { index in
                            selection = EsmaSelection(id: index)
                        }
                        .cardEntrance(index: 1, appeared: appeared, reduceMotion: reduceMotion)

                        if !isSearchingEsma {
                            hadithEntry
                            religiousDaysCard
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .mihrabTabGutter()
                }
                .mihrabTabScroll()
                .scrollDismissesKeyboard(.immediately)
                .sheet(item: $selection) { item in
                    EsmaDetailSheet(startIndex: item.id)
                }
            }
            .navigationTitle(L10n.tabEsma)
            .sheet(item: $activeCollection) { collection in
                EsmaCollectionSheet(collection: collection)
            }
            .sheet(isPresented: $showHadith) {
                HadithDetailSheet(hadith: BundledContent.hadith())
            }
            .sheet(isPresented: $showDhikr) {
                DhikrView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            guard !appeared else { return }
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : MihrabMotion.standardAnimation) {
                appeared = true
            }
        }
    }

    // MARK: - Hadith

    private var hadithEntry: some View {
        Button { showHadith = true } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "book.closed.fill")
                        .font(.footnote)
                        .foregroundStyle(MihrabColor.brass)
                    Text(L10n.deenHadithCaps)
                        .ornamentalCaps()
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MihrabColor.textTertiary)
                }

                Text(BundledContent.hadith().localizedTranslation)
                    .font(MihrabFont.quote(20))
                    .foregroundStyle(MihrabColor.textPrimary)
                    .lineSpacing(5)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Capsule()
                        .fill(MihrabColor.brass.opacity(0.5))
                        .frame(width: 26, height: 1)
                    Text(BundledContent.hadith().narrator)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(MihrabColor.textSecondary)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .mihrabShaderPanel(.lantern, cornerRadius: 28, opacity: 0.4)
        }
        .pressable(reduceMotion)
        .accessibilityLabel(Text(L10n.dailyHadith))
    }

    // MARK: - Religious days

    private var religiousDaysCard: some View {
        ReligiousDaysListView()
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .mihrabSolidCard(cornerRadius: 26)
    }
}
