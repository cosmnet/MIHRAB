import SwiftUI

struct DeenView: View {
    @Environment(Theme.self) private var theme
    @State private var showHadith = false
    @State private var featured: EsmaName?
    @State private var esmaQuery = ""

    private var isSearchingEsma: Bool {
        !esmaQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground(ramadanMode: theme.isRamadanMode)
                ScrollView {
                    VStack(spacing: 24) {
                        EsmaGridView(featured: featured, query: $esmaQuery)
                        if !isSearchingEsma {
                            hadithEntry
                            ReligiousDaysListView()
                        }
                    }
                    .padding(.horizontal, 16)
                    .mihrabTabGutter()
                }
                .mihrabTabScroll()
                .scrollDismissesKeyboard(.immediately)
            }
            .navigationTitle(L10n.tabEsma)
            .sheet(isPresented: $showHadith) {
                HadithDetailSheet(hadith: BundledContent.hadith())
            }
        }
        .onAppear {
            let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
            featured = BundledContent.esma[abs(day) % BundledContent.esma.count]
        }
    }

    private var hadithEntry: some View {
        Button { showHadith = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundStyle(MihrabColor.brass)
                    .symbolRenderingMode(.hierarchical)
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.dailyHadith)
                        .ornamentalCaps()
                    Text(BundledContent.hadith().localizedTranslation)
                        .font(MihrabFont.quote(21))
                        .foregroundStyle(MihrabColor.textPrimary)
                        .lineSpacing(5)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(MihrabColor.textTertiary)
            }
            .padding(18)
            .mihrabCardScene("today-hadith", opacity: 0.38)
            .mihrabCard(interactive: true)
        }
        .buttonStyle(.plain)
    }
}
