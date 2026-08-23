import SwiftUI

/// The rendered ayah card.
///
/// Premium (`PremiumFeature.shareCards`) — the *image* is the ornament. Copying
/// the ayah as plain text, and the system share sheet for that text, stay free
/// and are one tap away in the same menu, so nothing about actually passing on
/// a verse is behind the paywall.
struct QuranVerseShareCard: View {
    let ayah: Ayah
    let sura: SuraInfo
    let translation: String?

    var body: some View {
        VStack(spacing: 22) {
            Text(sura.arabicName)
                .font(MihrabFont.arabic(24))
                .foregroundStyle(MihrabColor.brass)

            Text(ayah.text)
                .font(MihrabFont.arabic(32))
                .lineSpacing(18)
                .foregroundStyle(MihrabColor.textPrimary)
                .multilineTextAlignment(.center)
                .environment(\.layoutDirection, .rightToLeft)
                .fixedSize(horizontal: false, vertical: true)

            if let translation, !translation.isEmpty {
                Text(translation)
                    .font(MihrabFont.quote(17))
                    .lineSpacing(4)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                Capsule().fill(MihrabColor.brass.opacity(0.5)).frame(width: 22, height: 1)
                Text("\(sura.localizedName) \(ayah.ref.citation)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MihrabColor.brass)
                Capsule().fill(MihrabColor.brass.opacity(0.5)).frame(width: 22, height: 1)
            }

            // Licence: the source has to be indicated wherever the text goes,
            // and a share card carries the text out of the app.
            Text("Tanzil Project · tanzil.net · CC BY 3.0")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(MihrabColor.textTertiary)
        }
        .padding(34)
        .frame(width: 400)
        .background {
            LinearGradient(
                colors: [MihrabColor.forest, MihrabColor.abyss],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .overlay {
            Rectangle()
                .strokeBorder(MihrabColor.brass.opacity(0.35), lineWidth: 1)
                .padding(10)
        }
    }
}

// MARK: - Sheet

struct QuranVerseShareSheet: View {
    let ayah: Ayah
    let sura: SuraInfo
    let translation: String?

    @State private var rendered: ShareImage?
    @State private var subscriptions = SubscriptionManager.shared
    @State private var showPaywall = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale

    private var plainText: String {
        var parts = [ayah.text]
        if let translation, !translation.isEmpty { parts.append(translation) }
        parts.append("— \(sura.localizedName) \(ayah.ref.citation)")
        parts.append("Tanzil Project · tanzil.net · CC BY 3.0")
        return parts.joined(separator: "\n\n")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    QuranVerseShareCard(ayah: ayah, sura: sura, translation: translation)
                        .scaleEffect(0.8)
                        .frame(height: cardHeight)
                        .clipped()

                    if subscriptions.hasAccess(to: .shareCards) {
                        if let rendered {
                            ShareLink(item: rendered, preview: SharePreview(
                                "\(sura.localizedName) \(ayah.ref.citation)",
                                image: rendered
                            )) {
                                Label(L10n.quranShareVerse, systemImage: "square.and.arrow.up")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity, minHeight: MihrabSpace.hit)
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            ProgressView().frame(minHeight: MihrabSpace.hit)
                        }
                    } else {
                        Button {
                            HapticsEngine.shared.warning()
                            showPaywall = true
                        } label: {
                            HStack(spacing: 8) {
                                PremiumLockBadge(compact: true)
                                Text(L10n.quranShareVerse)
                                    .font(.subheadline.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity, minHeight: MihrabSpace.hit)
                        }
                        .buttonStyle(.bordered)
                    }

                    // Always free: the words themselves.
                    ShareLink(item: plainText) {
                        Label(L10n.quranCopy, systemImage: "text.quote")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, minHeight: MihrabSpace.hit)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(20)
            }
            .background(MihrabBackdrop(ramadanMode: false).ignoresSafeArea())
            .navigationTitle(L10n.quranShareVerse)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.done) { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView(source: .feature) }
            .task { await render() }
        }
    }

    private var cardHeight: CGFloat {
        translation == nil ? 300 : 380
    }

    @MainActor
    private func render() async {
        guard subscriptions.hasAccess(to: .shareCards), rendered == nil else { return }
        let renderer = ImageRenderer(
            content: QuranVerseShareCard(ayah: ayah, sura: sura, translation: translation)
        )
        renderer.scale = displayScale
        if let image = renderer.uiImage {
            rendered = ShareImage(image: image)
        }
    }
}
