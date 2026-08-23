import SwiftUI

// MARK: - Summary card

/// The one-glance hatim card, embedded in the Qur'an library and available to
/// any other surface that wants it.
struct HatimSummaryCard: View {
    @State private var store = HatimStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "book.pages.fill")
                    .font(.footnote)
                    .foregroundStyle(MihrabColor.brass)
                Text(L10n.hatimTitle).ornamentalCaps()
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MihrabColor.textTertiary)
            }

            if let plan = store.primaryPlan {
                let progress = store.progress(for: plan)
                HStack(alignment: .center, spacing: 16) {
                    HatimRing(fraction: progress.fraction)
                        .frame(width: 54, height: 54)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(plan.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MihrabColor.textPrimary)
                            .lineLimit(1)
                        Text(L10n.hatimPagesOf(progress.pagesRead, progress.pagesTotal))
                            .font(.caption)
                            .foregroundStyle(MihrabColor.textSecondary)
                        if progress.isComplete {
                            Text(L10n.hatimComplete)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MihrabColor.mint)
                        } else if let perDay = progress.pagesPerDay {
                            Text("\(L10n.hatimDailyShareLabel): \(L10n.hatimDailyShare(perDay))")
                                .font(.caption)
                                .foregroundStyle(MihrabColor.mint)
                        }
                    }
                    Spacer()
                }
            } else {
                Text(L10n.hatimEmptyBody)
                    .font(.footnote)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mihrabSolidCard(cornerRadius: MihrabSpace.cardRadius)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Ring

struct HatimRing: View {
    let fraction: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(MihrabColor.mint.opacity(0.16), lineWidth: 6)
            Circle()
                .trim(from: 0, to: max(0.001, min(fraction, 1)))
                .stroke(
                    LinearGradient(
                        colors: [MihrabColor.emerald, MihrabColor.mint],
                        startPoint: .top,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : MihrabMotion.gentleAnimation, value: fraction)
            Text("\(Int((fraction * 100).rounded()))")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(MihrabColor.textPrimary)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Main screen

struct HatimView: View {
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var store = HatimStore.shared
    @State private var showNewPlan = false
    @State private var showShared = false
    @State private var restartTarget: String?

    var body: some View {
        ZStack {
            MihrabBackdrop(surface: .deen, ramadanMode: theme.isRamadanMode)

            ScrollView {
                LazyVStack(spacing: 20) {
                    if store.activePlans.isEmpty {
                        MihrabEmptyState(
                            symbol: "book.pages",
                            title: L10n.hatimEmptyTitle,
                            message: L10n.hatimEmptyBody,
                            retry: nil
                        )
                    } else {
                        ForEach(store.activePlans) { plan in
                            HatimPlanCard(plan: plan, onRestart: { restartTarget = plan.id })
                        }
                    }

                    actions

                    if store.completedHatims > 0 {
                        Text(L10n.hatimCompletedCount(store.completedHatims))
                            .font(.footnote)
                            .foregroundStyle(MihrabColor.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .mihrabTabSafeContent()
            }
            .mihrabTabScroll()
        }
        .navigationTitle(L10n.hatimTitle)
        .sheet(isPresented: $showNewPlan) { HatimPlanEditor() }
        .sheet(isPresented: $showShared) { SharedHatimSheet() }
        .confirmationDialog(
            L10n.hatimRestart,
            isPresented: Binding(get: { restartTarget != nil }, set: { if !$0 { restartTarget = nil } }),
            titleVisibility: .visible
        ) {
            Button(L10n.hatimRestart, role: .destructive) {
                if let restartTarget { store.restart(planID: restartTarget) }
                restartTarget = nil
                HapticsEngine.shared.warning()
            }
            Button(L10n.hatimCancel, role: .cancel) { restartTarget = nil }
        } message: {
            Text(L10n.hatimRestartConfirm)
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                HapticsEngine.shared.light()
                showNewPlan = true
            } label: {
                Label(L10n.hatimNew, systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: MihrabSpace.hit)
            }
            .buttonStyle(.borderedProminent)
            .tint(MihrabColor.emerald)

            Button {
                HapticsEngine.shared.light()
                showShared = true
            } label: {
                Label(L10n.hatimShared, systemImage: "person.2.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: MihrabSpace.hit)
            }
            .buttonStyle(.bordered)
            .tint(MihrabColor.mint)

            Text(L10n.hatimFree)
                .font(.caption2)
                .foregroundStyle(MihrabColor.textTertiary)
        }
    }
}

// MARK: - Plan card

struct HatimPlanCard: View {
    let plan: HatimPlan
    var onRestart: () -> Void

    @State private var store = HatimStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: HatimProgress { store.progress(for: plan) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                HatimRing(fraction: progress.fraction)
                    .frame(width: 66, height: 66)

                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.headline)
                        .foregroundStyle(MihrabColor.textPrimary)
                    Text(L10n.hatimPagesOf(progress.pagesRead, progress.pagesTotal))
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textSecondary)
                    Text(L10n.hatimJuzDone(progress.juzRead))
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textTertiary)
                }
                Spacer(minLength: 0)
            }

            if progress.isComplete {
                Label(L10n.hatimComplete, systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MihrabColor.mint)
            } else {
                statLine
                paceLine
            }

            if let group = plan.group {
                groupNote(group)
            }

            HStack(spacing: 12) {
                if let sura = resumeSura {
                    NavigationLink {
                        QuranReaderView(sura: sura.0, focus: sura.1)
                    } label: {
                        Label(L10n.hatimContinueReading, systemImage: "book")
                            .font(.footnote.weight(.semibold))
                            .frame(minHeight: MihrabSpace.hit)
                    }
                }
                Spacer()
                Menu {
                    Button(L10n.hatimRestart, role: .destructive, action: onRestart)
                    Button(L10n.hatimDelete, role: .destructive) {
                        HapticsEngine.shared.warning()
                        store.remove(id: plan.id)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.body)
                        .frame(width: MihrabSpace.hit, height: MihrabSpace.hit)
                }
            }
            .tint(MihrabColor.mint)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mihrabSolidCard(cornerRadius: MihrabSpace.cardRadius)
    }

    /// Where "continue" lands: the ayah after the furthest recorded, or the
    /// scope's first ayah when nothing is read yet.
    private var resumeSura: (SuraInfo, AyahRef)? {
        let next = max(plan.position + 1, plan.scope.start)
        guard let ref = QuranCatalog.ref(atAbsoluteIndex: min(next, plan.scope.end)),
              let sura = QuranCatalog.sura(ref.sura)
        else { return nil }
        return (sura, ref)
    }

    private var statLine: some View {
        HStack(spacing: 18) {
            stat(
                title: L10n.hatimDailyShareLabel,
                value: progress.pagesPerDay.map { L10n.hatimDailyShare($0) } ?? "—"
            )
            stat(
                title: L10n.hatimFinishBy,
                value: progress.daysRemaining > 0
                    ? L10n.hatimDaysLeft(progress.daysRemaining)
                    : L10n.hatimTargetPassed
            )
        }
    }

    private func stat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).ornamentalCaps()
            Text(value)
                .font(.footnote.weight(.medium))
                .foregroundStyle(MihrabColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var paceLine: some View {
        if let projected = progress.projectedFinish {
            let day = projected.formatted(
                Date.FormatStyle(date: .abbreviated, time: .omitted).locale(L10n.appLocale)
            )
            HStack(spacing: 8) {
                Image(systemName: progress.isOnTrack == true ? "checkmark.circle.fill" : "clock.badge.exclamationmark")
                    .font(.caption)
                    .foregroundStyle(progress.isOnTrack == true ? MihrabColor.mint : MihrabColor.brass)
                Text(L10n.hatimProjected(day))
                    .font(.caption)
                    .foregroundStyle(MihrabColor.textSecondary)
            }
        } else {
            // No pace yet — say so rather than extrapolating from nothing.
            Text(L10n.hatimNoPaceYet)
                .font(.caption)
                .foregroundStyle(MihrabColor.textTertiary)
        }
    }

    private func groupNote(_ group: HatimGroup) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.hatimSharedLocalNote).ornamentalCaps()
            Text(group.claimedJuz.map { L10n.hatimJuzLabel($0) }.joined(separator: ", "))
                .font(.caption)
                .foregroundStyle(MihrabColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(MihrabColor.abyss.opacity(0.35))
        )
    }
}
