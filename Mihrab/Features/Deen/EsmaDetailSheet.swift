import SwiftUI
import UIKit

/// Identifiable wrapper so a 0-based Name index can drive `sheet(item:)`.
struct EsmaSelection: Identifiable, Hashable {
    let id: Int
}

// MARK: - Sheet

/// A page per Name. Swiping horizontally walks the ninety-nine without ever
/// going back to the list — the whole catalog becomes one continuous book.
struct EsmaDetailSheet: View {
    let startIndex: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var index: Int
    @State private var showDhikr = false
    /// Rendered lazily and cached — an `ImageRenderer` pass inside `body` would
    /// run on every layout of a 99-page pager.
    @State private var shareImage: UIImage?

    private var library: EsmaLibrary { EsmaLibrary.shared }

    private var names: [EsmaName] { BundledContent.esma }

    private var current: EsmaName? {
        names.indices.contains(index) ? names[index] : names.first
    }

    init(startIndex: Int) {
        self.startIndex = startIndex
        _index = State(initialValue: startIndex)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MihrabBackdrop(surface: .sheet)

                TabView(selection: $index) {
                    ForEach(Array(names.enumerated()), id: \.offset) { offset, name in
                        EsmaDetailPage(index: offset, name: name)
                            .tag(offset)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(String(format: "%02d · 99", index + 1))
                        .font(.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(MihrabColor.textSecondary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    if let current {
                        EsmaStarButton(name: current, size: 17)
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if let shareImage {
                        ShareLink(
                            item: ShareImage(image: shareImage),
                            preview: SharePreview(L10n.esmaShareTitle, image: Image(uiImage: shareImage))
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel(Text(L10n.esmaShareAction))
                    }
                    Button(L10n.done) { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                dhikrCTA
            }
        }
        .onAppear {
            markVisited()
            refreshShareImage()
        }
        .onChange(of: index) { _, _ in
            if !reduceMotion { HapticsEngine.shared.phraseSwap() }
            markVisited()
            refreshShareImage()
        }
        .sheet(isPresented: $showDhikr) {
            DhikrView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
    }

    private func refreshShareImage() {
        guard let current else { return }
        shareImage = EsmaShareCard.render(number: index + 1, name: current)
    }

    private func markVisited() {
        guard let current else { return }
        library.markVisited(current)
    }

    @ViewBuilder
    private var dhikrCTA: some View {
        let count = EsmaCommentary.suggestedCount(for: index + 1)
        VStack(spacing: 8) {
            Button {
                HapticsEngine.shared.light()
                showDhikr = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "circle.hexagonpath.fill")
                    Text(L10n.esmaReciteTimes(count))
                }
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Capsule().fill(MihrabColor.emerald))
                .shadow(color: MihrabColor.emerald.opacity(reduceMotion ? 0 : 0.24), radius: 14, y: 6)
            }
            .pressable(reduceMotion)

            Text(L10n.esmaSwipeHint)
                .font(.caption2)
                .foregroundStyle(MihrabColor.textTertiary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }
}

// MARK: - Page

struct EsmaDetailPage: View {
    let index: Int
    let name: EsmaName

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var number: Int { index + 1 }
    private var collection: EsmaCollection { EsmaCollections.primaryCollection(for: number) }

    /// The meaning in the language the user is *not* reading in.
    private var secondaryMeaning: String {
        L10n.isTurkish ? name.en : (L10n.isArabic ? name.en : name.tr)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                calligraphyPlate

                HStack(spacing: 8) {
                    ForEach(EsmaCollections.collections(for: number)) { item in
                        HStack(spacing: 5) {
                            Image(systemName: item.symbol)
                                .font(.caption2.weight(.semibold))
                            Text(item.localizedTitle)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(item.tint)
                        .padding(.horizontal, 10)
                        .frame(height: 26)
                        .background(Capsule().fill(item.tint.opacity(0.14)))
                    }
                    Spacer(minLength: 0)
                }

                block(L10n.esmaMeaningCaps) {
                    Text(name.localizedMeaning)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(MihrabColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                block(L10n.esmaPronunciationCaps) {
                    Text(name.transliteration)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(MihrabColor.brass)
                }

                block(L10n.esmaOtherLanguageCaps) {
                    Text(secondaryMeaning)
                        .font(MihrabFont.quote(20))
                        .foregroundStyle(MihrabColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                block(L10n.esmaReflectionCaps) {
                    Text(EsmaCommentary.reflection(for: number))
                        .font(MihrabFont.quoteItalic(19))
                        .foregroundStyle(MihrabColor.textPrimary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .mihrabSolidCard(cornerRadius: 22)
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
    }

    private var calligraphyPlate: some View {
        ZStack {
            EsmaRosette(side: 210, opacity: 0.2)

            Text(name.arabic)
                .font(MihrabFont.arabic(62))
                .foregroundStyle(
                    LinearGradient(
                        colors: [MihrabColor.textPrimary, MihrabColor.sprout],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: MihrabColor.brass.opacity(0.26), radius: 16)
                .lineLimit(1)
                .minimumScaleFactor(0.35)
                .environment(\.layoutDirection, .rightToLeft)
                .padding(.horizontal, 16)
                .modifier(BreathingScale(active: !reduceMotion, from: 0.995, to: 1.018, period: 8))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 218)
        .mihrabShaderPanel(collection.motif, cornerRadius: 30, opacity: 0.44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(name.transliteration))
    }

    @ViewBuilder
    private func block<Content: View>(
        _ caps: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(caps)
                .ornamentalCaps()
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Share card

enum EsmaShareCard {
    /// 1080×1350 (@2×) portrait card, rendered off-screen for `ShareLink`.
    @MainActor
    static func render(number: Int, name: EsmaName) -> UIImage {
        let renderer = ImageRenderer(content: card(number: number, name: name))
        renderer.scale = 2
        return renderer.uiImage ?? UIImage()
    }

    @MainActor
    private static func card(number: Int, name: EsmaName) -> some View {
        ZStack {
            MihrabColor.abyss
            RadialGradient(
                colors: [MihrabColor.forest.opacity(0.85), .clear],
                center: .top,
                startRadius: 40,
                endRadius: 520
            )

            VStack(spacing: 26) {
                Text("MIHRAB")
                    .font(MihrabFont.ornamental)
                    .tracking(4)
                    .foregroundStyle(MihrabColor.brass)

                Text(String(format: "%02d · 99", number))
                    .font(.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(MihrabColor.textTertiary)

                Text(name.arabic)
                    .font(MihrabFont.arabic(58))
                    .foregroundStyle(MihrabColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)

                Text(name.localizedMeaning)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(MihrabColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text(name.transliteration)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(MihrabColor.brass)

                Text(EsmaCommentary.reflection(for: number))
                    .font(MihrabFont.quoteItalic(19))
                    .foregroundStyle(MihrabColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(52)
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(MihrabColor.brass.opacity(0.6), lineWidth: 2)
                    .padding(20)
            }
        }
        .frame(width: 540, height: 675)
    }
}
