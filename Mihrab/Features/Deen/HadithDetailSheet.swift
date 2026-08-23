import SwiftData
import SwiftUI

struct HadithDetailSheet: View {
    let hadith: Hadith

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [FavoriteHadith]
    @State private var shareImage: UIImage?

    private var isFavorite: Bool {
        favorites.contains { $0.hadithID == hadith.id }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        ornamentalDivider

                        Text(hadith.arabic)
                            .font(MihrabFont.arabic(28))
                            .foregroundStyle(MihrabColor.textPrimary)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .lineSpacing(14)
                            .environment(\.layoutDirection, .rightToLeft)

                        Text(hadith.localizedTranslation)
                            .mihrabQuote(20, italic: true)
                            .foregroundStyle(MihrabColor.textPrimary)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if Locale.mihrabIsTurkish {
                            Text(hadith.en)
                                .mihrabQuote(17, relativeTo: .callout)
                                .foregroundStyle(MihrabColor.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(hadith.tr)
                                .mihrabQuote(17, relativeTo: .callout)
                                .foregroundStyle(MihrabColor.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        ornamentalDivider

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(hadith.narrator)
                                    .font(.subheadline.weight(.semibold))
                                Text(hadith.source)
                                    .font(.caption)
                                    .foregroundStyle(MihrabColor.textSecondary)
                            }
                            Spacer()
                            Text(hadith.grade)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(hadith.grade == "Sahih" ? MihrabColor.emerald : MihrabColor.mint)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Capsule().fill(MihrabColor.moss))
                                .overlay {
                                    Capsule().strokeBorder(MihrabColor.mint.opacity(0.28), lineWidth: 1)
                                }
                        }
                    }
                    .padding(24)
                }
                .scrollEdgeEffectStyle(.soft, for: .top)
            }
            .navigationTitle(L10n.dailyHadith)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { toggleFavorite() } label: {
                        Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(MihrabColor.brass)
                    }
                    .accessibilityLabel(Text(
                        isFavorite ? L10n.esmaRemoveFavorite : L10n.esmaAddFavorite
                    ))
                    .accessibilityAddTraits(isFavorite ? [.isSelected, .isButton] : .isButton)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    ShareLink(item: ShareImage(image: renderedShareImage()),
                              preview: SharePreview(L10n.shareHadith, image: Image(uiImage: renderedShareImage()))) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel(Text(L10n.shareHadith))
                    Button(L10n.done) { dismiss() }
                }
            }
        }
        .presentationBackground(.ultraThinMaterial)
    }

    private var ornamentalDivider: some View {
        HStack(spacing: 12) {
            Capsule().fill(MihrabColor.brass.opacity(0.5)).frame(height: 1)
            Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundStyle(MihrabColor.brass)
            Capsule().fill(MihrabColor.brass.opacity(0.5)).frame(height: 1)
        }
    }

    private func toggleFavorite() {
        HapticsEngine.shared.light()
        if let existing = favorites.first(where: { $0.hadithID == hadith.id }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(FavoriteHadith(hadithID: hadith.id))
        }
        try? modelContext.save()
    }

    /// 1080×1350 share card rendered off-screen (§9 #13).
    @MainActor
    /// Rendered off-screen by `ImageRenderer`. Fixed point sizes and the dimmer
    /// tertiary tone are correct here: there is no Dynamic Type inside a
    /// renderer, and the card composes at one exact pixel size.
    private func renderedShareImage() -> UIImage {
        let renderer = ImageRenderer(content:
            ZStack {
                MihrabColor.abyss
                RadialGradient(colors: [MihrabColor.forest.opacity(0.8), .clear],
                               center: .top, startRadius: 40, endRadius: 500)
                VStack(spacing: 28) {
                    Text("MIHRAB")
                        .font(MihrabFont.ornamental)
                        .tracking(4)
                        .foregroundStyle(MihrabColor.brass)
                    Text(hadith.arabic)
                        .font(MihrabFont.arabic(30))
                        .foregroundStyle(MihrabColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(12)
                    Text(hadith.localizedTranslation)
                        .font(MihrabFont.quoteItalic(22))
                        .foregroundStyle(MihrabColor.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("\(hadith.narrator) · \(hadith.source)")
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textTertiary)
                }
                .padding(48)
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(MihrabColor.brass.opacity(0.6), lineWidth: 2)
                        .padding(20)
                }
            }
            .frame(width: 540, height: 675)
        )
        renderer.scale = 2
        return renderer.uiImage ?? UIImage()
    }
}
