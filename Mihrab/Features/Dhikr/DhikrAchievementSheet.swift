import SwiftData
import SwiftUI

struct DhikrAchievementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var sessions: [DhikrSession]

    private var items: [DhikrAchievementSnapshot] {
        DhikrAchievements.snapshots(from: sessions)
    }

    private var inscribedCount: Int {
        items.filter(\.unlocked).count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        lexiconHeader
                        lexiconEntries
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
                .scrollEdgeEffectStyle(.soft, for: .top)
            }
            .navigationTitle(L10n.achievements)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.done) { dismiss() }
                }
            }
        }
        .presentationBackground(.ultraThinMaterial)
    }

    private var lexiconHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(MihrabColor.brass.opacity(0.12))
                    .frame(width: 72, height: 72)
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [MihrabColor.brass, MihrabColor.emerald.opacity(0.55)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.2
                    )
                    .frame(width: 72, height: 72)
                Image(systemName: "seal.fill")
                    // Sits inside a fixed 72pt rosette — semantic style, capped.
                    .font(.title.weight(.medium))
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .foregroundStyle(MihrabColor.brass)
                    .symbolRenderingMode(.hierarchical)
            }
            Text(L10n.achievementsLexicon)
                .ornamentalCaps()
            Text(L10n.achievementsInscribed(inscribedCount, items.count))
                .mihrabQuote(17)
                .foregroundStyle(MihrabColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 18)
        .glassEffect(.regular, in: .rect(cornerRadius: MihrabSpace.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: MihrabSpace.cardRadius, style: .continuous)
                .strokeBorder(MihrabColor.brass.opacity(0.28), lineWidth: 1)
        }
    }

    private var lexiconEntries: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Rectangle()
                        .fill(MihrabColor.brass.opacity(item.unlocked ? 0.18 : 0.08))
                        .frame(height: 0.5)
                        .padding(.leading, 76)
                }
                AchievementLemmaRow(item: item)
            }
        }
        .padding(.vertical, 6)
        .mihrabSolidCard(cornerRadius: MihrabSpace.cardRadius)
    }
}

private struct AchievementLemmaRow: View {
    let item: DhikrAchievementSnapshot

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            AchievementSeal(item: item, size: 52)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(item.title)
                        .mihrabQuote(20)
                        // A locked title still has to be readable: textTertiary
                        // is 2.9:1 on moss, so dim textSecondary instead.
                        .foregroundStyle(item.unlocked
                                         ? MihrabColor.textPrimary
                                         : MihrabColor.textSecondary.opacity(0.75))
                    Spacer(minLength: 8)
                    if item.unlocked {
                        Text(L10n.achievementInscribedMark)
                            .font(.caption2.weight(.medium))
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .foregroundStyle(MihrabColor.brass)
                    }
                }

                Text(item.unlocked ? item.detail : item.lemma)
                    .font(.caption)
                    .foregroundStyle(item.unlocked ? MihrabColor.textSecondary : MihrabColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !item.unlocked {
                    ProgressView(value: item.progress)
                        .tint(MihrabColor.brass.opacity(0.45))
                        .padding(.top, 4)
                    Text(L10n.achievementProgress(item.current, item.goal))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(MihrabColor.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        if item.unlocked {
            return "\(item.title). \(item.detail). \(L10n.achievementInscribedMark)"
        }
        return "\(item.title). \(item.lemma). \(L10n.achievementProgress(item.current, item.goal))"
    }
}

struct AchievementSeal: View {
    let item: DhikrAchievementSnapshot
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            Circle()
                .fill(item.unlocked ? MihrabColor.brass.opacity(0.16) : MihrabColor.moss)
            Circle()
                .strokeBorder(
                    item.unlocked
                        ? LinearGradient(
                            colors: [MihrabColor.brass, MihrabColor.emerald.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [MihrabColor.textTertiary.opacity(0.35), MihrabColor.moss],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                    lineWidth: 1.15
                )

            if let symbol = item.symbol {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.36, weight: .medium))
                    .foregroundStyle(item.unlocked ? MihrabColor.brass : MihrabColor.textTertiary)
                    .symbolRenderingMode(.hierarchical)
            } else {
                Text(item.sealText)
                    .font(.system(size: sealFont, weight: .semibold, design: .serif))
                    .foregroundStyle(item.unlocked ? MihrabColor.brass : MihrabColor.textTertiary)
                    .minimumScaleFactor(0.45)
                    .lineLimit(1)
                    .padding(.horizontal, 5)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var sealFont: CGFloat {
        item.sealText.count > 3 ? size * 0.26 : size * 0.34
    }
}

struct DhikrAchievementToast: View {
    let item: DhikrAchievementSnapshot

    var body: some View {
        HStack(spacing: 12) {
            AchievementSeal(item: item, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.achievementUnlocked)
                    .font(.caption2.weight(.medium))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(MihrabColor.brass)
                Text(item.title)
                    .mihrabQuote(17)
                    .foregroundStyle(MihrabColor.textPrimary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(MihrabColor.brass.opacity(0.35), lineWidth: 1)
        }
        .padding(.horizontal, 20)
        .allowsHitTesting(false)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityLabel("\(L10n.achievementUnlocked). \(item.title)")
    }
}
