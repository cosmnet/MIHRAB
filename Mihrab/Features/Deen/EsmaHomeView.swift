import SwiftUI

// MARK: - Ornament

/// The ornament behind a Name's calligraphy.
///
/// This used to draw a *rub el hizb* — two squares at 45°. Geometrically that
/// is an eight-pointed Islamic seal, but stroked thinly at 22% opacity behind
/// Arabic script, users read the crossing diagonals as a hexagram. The whole
/// drawing is gone: `MihrabRosette` (see `Core/Brand/MihrabMark.swift`) builds
/// its sixteen-fold ring out of arcs and concentric circles, with no straight
/// edges and no polygon overlay for the eye to complete into a star.
///
/// Kept as a named alias so the Esma surfaces share one ornament and one set
/// of defaults; both call sites here and in `EsmaDetailSheet` go through it.
typealias EsmaRosette = MihrabRosette

// MARK: - Home

/// The first thing the Esmaül Hüsna tab shows: one Name to sit with, a quiet
/// measure of how far the user has come, a dhikr they can start in one tap,
/// and themed collections to wander into. The full ninety-nine live below,
/// in `EsmaBrowserView`.
struct EsmaHomeView: View {
    let featuredIndex: Int
    var onOpenName: (Int) -> Void
    var onOpenCollection: (EsmaCollection) -> Void
    var onOpenDhikr: () -> Void

    private var library: EsmaLibrary { EsmaLibrary.shared }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var featured: EsmaName? {
        BundledContent.esma.indices.contains(featuredIndex)
            ? BundledContent.esma[featuredIndex]
            : BundledContent.esma.first
    }

    private var featuredNumber: Int { featuredIndex + 1 }

    var body: some View {
        VStack(spacing: 22) {
            if let featured {
                heroCard(featured)
                dhikrCard(featured)
            }
            journeyStrip
            collectionStrip
        }
    }

    // MARK: Hero

    private func heroCard(_ name: EsmaName) -> some View {
        Button { onOpenName(featuredIndex) } label: {
            VStack(spacing: 16) {
                Text(L10n.esmaHeroCaps)
                    .ornamentalCaps()

                ZStack {
                    EsmaRosette(side: 236, opacity: reduceMotion ? 0.18 : 0.22)
                        .modifier(BreathingScale(active: !reduceMotion, from: 0.97, to: 1.04, period: 7))

                    Text(name.arabic)
                        // Hero calligraphy inside a fixed 236pt stage.
                        .mihrabArabic(70, ceiling: .accessibility2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [MihrabColor.textPrimary, MihrabColor.sprout],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: MihrabColor.brass.opacity(0.28), radius: 18)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .environment(\.layoutDirection, .rightToLeft)
                        .padding(.horizontal, 12)
                        .modifier(BreathingScale(active: !reduceMotion, from: 0.995, to: 1.02, period: 7))
                }
                .frame(height: 236)

                VStack(spacing: 6) {
                    Text(name.localizedMeaning)
                        .font(.title.weight(.semibold))
                        .foregroundStyle(MihrabColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(name.transliteration)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(MihrabColor.brass)
                }

                HStack(spacing: 10) {
                    Text(L10n.esmaPositionOf99(featuredNumber))
                        .mihrabTime(12, relativeTo: .caption, ceiling: .accessibility2)
                        .foregroundStyle(MihrabColor.textSecondary)
                    Circle()
                        .fill(MihrabColor.brass.opacity(0.6))
                        .frame(width: 3, height: 3)
                    Text(L10n.esmaHeroHint)
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textSecondary)
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 26)
            .frame(maxWidth: .infinity)
            .mihrabShaderPanel(.kufic, cornerRadius: 34, opacity: 0.5)
        }
        .pressable(reduceMotion)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(L10n.esmaHeroCaps): \(name.transliteration), \(name.localizedMeaning)"))
        .accessibilityHint(Text(L10n.esmaHeroHint))
    }

    // MARK: Dhikr suggestion

    private func dhikrCard(_ name: EsmaName) -> some View {
        let count = EsmaCommentary.suggestedCount(for: featuredNumber)
        return Button {
            HapticsEngine.shared.light()
            onOpenDhikr()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .strokeBorder(MihrabColor.brass.opacity(0.45), lineWidth: 1)
                        .frame(width: 44, height: 44)
                    Image(systemName: "circle.hexagonpath.fill")
                        // Inside a fixed 44pt ring.
                        .font(.title3)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        .foregroundStyle(MihrabColor.brass)
                        .symbolRenderingMode(.hierarchical)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(L10n.esmaDhikrCaps)
                        .ornamentalCaps()
                    Text(L10n.esmaDhikrSuggestion(name.transliteration, count))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(MihrabColor.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 6)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(MihrabColor.textSecondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: MihrabSpace.hit)
            .mihrabSolidCard(cornerRadius: 22)
        }
        .pressable(reduceMotion)
        .accessibilityHint(Text(L10n.esmaOpenDhikr))
    }

    // MARK: Journey

    private var journeyStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L10n.esmaJourneyCaps)
                    .ornamentalCaps()
                Spacer()
                Label(L10n.esmaFavoritesCount(library.favoriteCount), systemImage: "star.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MihrabColor.brass)
                    .labelStyle(.titleAndIcon)
            }

            EsmaProgressBar(progress: library.progress)

            Text(L10n.esmaDiscovered(library.visitedCount))
                .font(.caption)
                .foregroundStyle(MihrabColor.textSecondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mihrabSolidCard(cornerRadius: 22)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(L10n.esmaJourneyCaps). \(L10n.esmaDiscovered(library.visitedCount)). \(L10n.esmaFavoritesCount(library.favoriteCount))"))
    }

    // MARK: Collections

    private var collectionStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(L10n.esmaCollectionsCaps)
                    .ornamentalCaps()
                // Soft signpost only — every collection stays open to everyone.
                if !SubscriptionManager.shared.hasAccess(to: .esmaCollections) {
                    PremiumLockBadge(compact: true)
                }
                Spacer()
            }
            .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(EsmaCollections.all) { collection in
                        EsmaCollectionCard(collection: collection) {
                            onOpenCollection(collection)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
            .scrollClipDisabled()
        }
    }
}

// MARK: - Collection card

struct EsmaCollectionCard: View {
    let collection: EsmaCollection
    var action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: collection.symbol)
                        .font(.title3)
                        .foregroundStyle(collection.tint)
                        .symbolRenderingMode(.hierarchical)
                    Spacer()
                    Text(collection.numbers.count.formatted())
                        .mihrabTime(13, relativeTo: .footnote, ceiling: .accessibility2)
                        .foregroundStyle(MihrabColor.textSecondary)
                }

                Spacer(minLength: 10)

                Text(collection.sealArabic)
                    .font(MihrabFont.arabic(21))
                    .foregroundStyle(MihrabColor.textPrimary.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .environment(\.layoutDirection, .rightToLeft)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Spacer(minLength: 10)

                Text(collection.localizedTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MihrabColor.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(collection.localizedNote)
                    .font(.caption2)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 3)
            }
            .padding(16)
            .frame(width: 208, height: 196, alignment: .topLeading)
            .mihrabShaderPanel(collection.motif, cornerRadius: 26, opacity: 0.42)
        }
        .pressable(reduceMotion)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(collection.localizedTitle), \(L10n.esmaCollectionCount(collection.numbers.count))"))
    }
}

// MARK: - Progress bar

/// Hairline brass progress across the ninety-nine, with 33/66 tick marks so
/// the number means something at a glance.
struct EsmaProgressBar: View {
    var progress: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(MihrabColor.abyss.opacity(0.55))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [MihrabColor.emerald, MihrabColor.brass],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, min(1, progress)) * width)

                ForEach([1.0 / 3.0, 2.0 / 3.0], id: \.self) { tick in
                    Rectangle()
                        .fill(MihrabColor.abyss.opacity(0.7))
                        .frame(width: 1)
                        .offset(x: tick * width)
                }
            }
            .animation(reduceMotion ? nil : MihrabMotion.gentleAnimation, value: progress)
        }
        .frame(height: 6)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }
}

// MARK: - Breathing

/// Slow inhale/exhale scale. Inert under Reduce Motion — the card simply rests.
struct BreathingScale: ViewModifier {
    var active: Bool
    var from: CGFloat = 0.98
    var to: CGFloat = 1.03
    var period: Double = 6

    @State private var expanded = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(active && expanded ? to : from)
            .onAppear {
                guard active else { return }
                withAnimation(.easeInOut(duration: period).repeatForever(autoreverses: true)) {
                    expanded = true
                }
            }
    }
}
