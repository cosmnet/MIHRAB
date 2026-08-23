import SwiftUI

/// One themed collection, opened from the home strip. Reuses the browser so
/// the list/grid preference and the star behaviour stay identical everywhere.
struct EsmaCollectionSheet: View {
    let collection: EsmaCollection

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var selection: EsmaSelection?

    var body: some View {
        NavigationStack {
            ZStack {
                MihrabBackdrop(surface: .sheet)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerCard

                        EsmaBrowserView(
                            query: $query,
                            restrictedTo: collection.numbers,
                            showsSearch: false
                        ) { index in
                            selection = EsmaSelection(id: index)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .scrollEdgeEffectStyle(.soft, for: .top)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.done) { dismiss() }
                }
            }
            .sheet(item: $selection) { item in
                EsmaDetailSheet(startIndex: item.id)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: collection.symbol)
                    .font(.title2)
                    .foregroundStyle(collection.tint)
                    .symbolRenderingMode(.hierarchical)
                Text(L10n.esmaCollectionCount(collection.numbers.count))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MihrabColor.textSecondary)
                Spacer()
            }

            Text(collection.localizedTitle)
                .font(.title2.weight(.semibold))
                .foregroundStyle(MihrabColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(collection.localizedNote)
                .mihrabQuote(17, relativeTo: .callout, italic: true)
                .foregroundStyle(MihrabColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mihrabShaderPanel(collection.motif, cornerRadius: 28, opacity: 0.42)
    }
}
