import SwiftUI

/// The daily make-up screen: what is left, +1 / −1 per prayer, pace and streak.
struct QadaView: View {
    init() {}

    @Environment(\.dismiss) private var dismiss
    @State private var store = QadaStore.shared
    @State private var showWizard = false
    @State private var showEditor = false
    @State private var milestone: Int?

    var body: some View {
        NavigationStack {
            ZStack {
                MihrabBackdrop(surface: .today)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: MihrabSpace.unit * 2.5) {
                        if store.isSetUp {
                            summaryCard
                            prayerList
                            paceCard
                        } else {
                            MihrabEmptyState(
                                symbol: "hands.and.sparkles",
                                title: L10n.qadaEmptyTitle,
                                message: L10n.qadaEmptyBody,
                                retryTitle: L10n.qadaSetUp,
                                retry: { showWizard = true }
                            )
                        }
                    }
                    .padding(.horizontal, MihrabSpace.unit * 2)
                    .padding(.vertical, MihrabSpace.unit * 2)
                }
                .scrollEdgeEffectStyle(.soft, for: .top)
            }
            .navigationTitle(L10n.qadaTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if store.isSetUp {
                        Button(L10n.qadaEditCounts) { showEditor = true }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.done) { dismiss() }
                }
            }
            .sheet(isPresented: $showWizard) { QadaSetupWizard() }
            .sheet(isPresented: $showEditor) { QadaCountEditor() }
            .sheet(item: Binding(get: { milestone.map(MilestoneBox.init) }, set: { milestone = $0?.percent })) { box in
                QadaMilestoneSheet(percent: box.percent)
            }
        }
    }

    private struct MilestoneBox: Identifiable {
        let percent: Int
        var id: Int { percent }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(MihrabColor.mint.opacity(0.16), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: max(0.001, store.progress))
                    .stroke(
                        LinearGradient(colors: [MihrabColor.emerald, MihrabColor.mint],
                                       startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(store.totalRemaining)")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold).monospacedDigit())
                        .foregroundStyle(MihrabColor.textPrimary)
                    Text(L10n.qadaRemaining)
                        .ornamentalCaps(MihrabColor.textSecondary)
                }
            }
            .frame(width: 168, height: 168)
            .padding(.top, 8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.qadaRemainingCount(store.totalRemaining))
            .accessibilityValue(L10n.qadaProgressPercent(Int(store.progress * 100)))

            Text(L10n.qadaProgressPercent(Int((store.progress * 100).rounded())))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MihrabColor.mint)

            HStack(spacing: 18) {
                Text(L10n.qadaMadeUpToday(store.paidTotal()))
                if store.streak > 0 {
                    Text("·")
                    Text(L10n.qadaStreak(store.streak))
                }
            }
            .font(.caption)
            .foregroundStyle(MihrabColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 16)
        .mihrabSolidCard(cornerRadius: MihrabSpace.cardRadius)
    }

    // MARK: - Per-prayer rows

    private var prayerList: some View {
        VStack(alignment: .leading, spacing: MihrabSpace.unit) {
            Text(L10n.qadaTodayHeader)
                .ornamentalCaps()
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(QadaStore.fardPrayers) { prayer in
                    QadaPrayerRow(
                        title: prayer.localizedNamazName,
                        symbol: prayer.symbolName,
                        remaining: store.remaining(prayer),
                        paidToday: store.paid(prayer),
                        onAdd: { mark { store.markPaid(prayer) } },
                        onUndo: { if store.undoPaid(prayer) { HapticsEngine.shared.light() } }
                    )
                    MihrabHairline()
                }
                if store.tracksWitr {
                    QadaPrayerRow(
                        title: L10n.qadaWitr,
                        symbol: "moon.fill",
                        remaining: store.remainingWitr,
                        paidToday: store.paidWitr(),
                        onAdd: { mark { store.markWitrPaid() } },
                        onUndo: { if store.undoWitrPaid() { HapticsEngine.shared.light() } }
                    )
                }
            }
            .padding(.horizontal, 14)
            .mihrabSolidCard()
        }
    }

    private func mark(_ action: () -> Bool) {
        guard action() else { return }
        HapticsEngine.shared.success()
        if let reached = store.consumeNewMilestone() {
            milestone = reached
            HapticsEngine.shared.setComplete()
        }
    }

    // MARK: - Pace

    private var paceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.qadaStatsTitle)
                .ornamentalCaps()
            if store.isComplete {
                Text(L10n.qadaDoneBody)
                    .font(.subheadline)
                    .foregroundStyle(MihrabColor.textPrimary)
            } else if let date = store.projectedCompletion() {
                Text(L10n.qadaPaceLine(Self.dateFormatter.string(from: date)))
                    .font(.subheadline)
                    .foregroundStyle(MihrabColor.textPrimary)
            } else {
                Text(L10n.qadaPaceUnknown)
                    .font(.subheadline)
                    .foregroundStyle(MihrabColor.textSecondary)
            }
            Text(L10n.qadaAveragePerDay(Self.averageFormatter.string(from: NSNumber(value: store.dailyAverage())) ?? "0"))
                .font(.caption)
                .foregroundStyle(MihrabColor.textTertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mihrabSolidCard()
        .accessibilityElement(children: .combine)
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: L10n.localeIdentifier)
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    static let averageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: L10n.localeIdentifier)
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()
}

// MARK: - Row

private struct QadaPrayerRow: View {
    let title: String
    let symbol: String
    let remaining: Int
    let paidToday: Int
    let onAdd: () -> Void
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(remaining == 0 ? MihrabColor.emerald : MihrabColor.brass)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(MihrabColor.textPrimary)
                Text(L10n.qadaRemainingCount(remaining))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(MihrabColor.textTertiary)
            }

            Spacer(minLength: 8)

            Button(action: onUndo) {
                Image(systemName: "minus")
                    .font(.body.weight(.bold))
                    .frame(width: MihrabSpace.hit, height: MihrabSpace.hit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(paidToday > 0 ? MihrabColor.textSecondary : MihrabColor.textTertiary.opacity(0.5))
            .disabled(paidToday == 0)
            .accessibilityLabel("\(L10n.qadaUndo), \(title)")

            Text("\(paidToday)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(paidToday > 0 ? MihrabColor.mint : MihrabColor.textTertiary)
                .frame(minWidth: 24)

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.body.weight(.bold))
                    .frame(width: MihrabSpace.hit, height: MihrabSpace.hit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(remaining > 0 ? MihrabColor.emerald : MihrabColor.textTertiary.opacity(0.5))
            .disabled(remaining == 0)
            .accessibilityLabel("\(L10n.qadaAdd), \(title)")
        }
        .padding(.vertical, 10)
        .frame(minHeight: MihrabSpace.hit)
    }
}

// MARK: - Milestone

struct QadaMilestoneSheet: View {
    let percent: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            MihrabBackdrop(surface: .sheet)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: percent >= 100 ? "sparkles" : "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(MihrabColor.brass)
                    .scaleEffect(appeared || reduceMotion ? 1 : 0.7)
                    .animation(reduceMotion ? nil : MihrabMotion.gentleAnimation, value: appeared)

                Text(L10n.qadaMilestoneTitle(percent))
                    .font(.title2.bold())
                    .foregroundStyle(MihrabColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text(percent >= 100 ? L10n.qadaDoneBody : L10n.qadaMilestoneBody)
                    .font(.subheadline)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .multilineTextAlignment(.center)

                Button {
                    dismiss()
                } label: {
                    Text(L10n.qadaCelebrateDismiss)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .frame(minHeight: MihrabSpace.hit)
                        .background(Capsule().fill(MihrabColor.emerald))
                }
                .buttonStyle(.plain)
            }
            .padding(32)
        }
        .onAppear { appeared = true }
        .presentationDetents([.medium])
        .presentationBackground(.ultraThinMaterial)
    }
}

// MARK: - Manual editor

struct QadaCountEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = QadaStore.shared

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(QadaStore.fardPrayers) { prayer in
                        Stepper(
                            value: Binding(
                                get: { store.remaining(prayer) },
                                set: { store.setRemaining($0, for: prayer) }
                            ),
                            in: 0...200_000
                        ) {
                            HStack {
                                Text(prayer.localizedNamazName)
                                Spacer()
                                Text("\(store.remaining(prayer))")
                                    .font(.body.monospacedDigit())
                                    .foregroundStyle(MihrabColor.textSecondary)
                            }
                        }
                        .frame(minHeight: MihrabSpace.hit)
                    }
                    if store.tracksWitr {
                        Stepper(
                            value: Binding(
                                get: { store.remainingWitr },
                                set: { store.setRemainingWitr($0) }
                            ),
                            in: 0...200_000
                        ) {
                            HStack {
                                Text(L10n.qadaWitr)
                                Spacer()
                                Text("\(store.remainingWitr)")
                                    .font(.body.monospacedDigit())
                                    .foregroundStyle(MihrabColor.textSecondary)
                            }
                        }
                        .frame(minHeight: MihrabSpace.hit)
                    }
                } header: {
                    Text(L10n.qadaEditCounts)
                } footer: {
                    Text(L10n.qadaEditHint)
                }
            }
            .navigationTitle(L10n.qadaEditCounts)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button(L10n.done) { dismiss() } }
            }
        }
    }
}
