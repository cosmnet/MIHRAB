import SwiftUI

/// Zikirmatik on the wrist — the feature that most wants to be here rather than
/// on a phone: eyes closed, hand down, one bead per Crown detent.
///
/// Two inputs, both counting up:
///
/// * **The Digital Crown.** `.digitalCrownRotation` needs `.focusable()` to
///   receive anything at all. `isHapticFeedbackEnabled: true` gives the Crown
///   its own detent tick, which is exactly one tap per bead — adding a second
///   haptic on top would double-buzz every count.
/// * **Tapping the face**, for anyone who finds the Crown fiddly.
///
/// Turning the Crown backwards does not subtract. A dhikr said is said; the
/// counter is not an editor. Only `Reset` clears the session, and it never
/// touches the day's total, which has already been handed to the phone.
struct WatchDhikrView: View {

    @Environment(WatchAppModel.self) private var model

    @State private var item: WatchDhikrItem = WatchDhikrCatalog.default
    @State private var sessionCount = 0
    @State private var crown: Double = 0
    @State private var reachedTarget = false
    @State private var showingPicker = false

    var body: some View {
        NavigationStack {
            counter
                .navigationTitle(L10n.wDhikr)
                .containerBackground(WatchPalette.dhikrGradient, for: .navigation)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingPicker = true
                        } label: {
                            Image(systemName: "list.bullet")
                        }
                        .accessibilityLabel(L10n.wDhikrPhrase)
                    }
                }
                .sheet(isPresented: $showingPicker) {
                    phrasePicker
                }
        }
        .onAppear {
            item = WatchDhikrCatalog.item(id: WatchSharedState.dhikrPhraseID) ?? WatchDhikrCatalog.default
        }
        .onDisappear {
            // One envelope per session rather than one per bead: 100 salawat
            // must not become 100 WatchConnectivity transfers.
            model.flushDhikr()
        }
    }

    // MARK: - Counter

    private var counter: some View {
        VStack(spacing: 4) {
            Text(item.arabic)
                .font(.headline)
                .foregroundStyle(MihrabColor.sprout)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            ZStack {
                Circle()
                    .stroke(MihrabColor.moss, lineWidth: 5)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(reachedTarget ? MihrabColor.brass : MihrabColor.emerald,
                            style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(MihrabMotion.snappyAnimation, value: sessionCount)

                VStack(spacing: 0) {
                    Text("\(sessionCount)")
                        .font(.largeTitle.weight(.bold).monospacedDigit())
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text(L10n.wDhikrProgress(sessionCount, item.target))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(MihrabColor.textTertiary)
                }
            }
            .frame(width: 96, height: 96)
            .contentShape(.circle)
            .onTapGesture { count(1) }

            Text(reachedTarget ? L10n.wDhikrDone : L10n.wDhikrTodayTotal(model.dhikrTotal))
                .font(.caption2)
                .foregroundStyle(reachedTarget ? MihrabColor.brass : MihrabColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Button(L10n.wDhikrReset) {
                sessionCount = 0
                crown = 0
                reachedTarget = false
                WatchHaptics.stop()
            }
            .font(.caption2)
            .buttonStyle(.bordered)
            .tint(MihrabColor.moss)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // `.focusable()` is not optional decoration: without it the Crown sends
        // nothing to this view at all.
        .focusable()
        .digitalCrownRotation($crown,
                              from: 0,
                              through: 100_000,
                              by: 1,
                              sensitivity: .medium,
                              isContinuous: false,
                              isHapticFeedbackEnabled: true)
        .onChange(of: crown) { oldValue, newValue in
            let steps = Int(newValue.rounded(.down)) - Int(oldValue.rounded(.down))
            guard steps > 0 else { return }
            count(steps, playHaptic: false)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.transliteration)
        .accessibilityValue(L10n.wDhikrProgress(sessionCount, item.target))
        .accessibilityHint(L10n.wDhikrCrownHint)
        .accessibilityAdjustableAction { direction in
            if direction == .increment { count(1) }
        }
    }

    private var progress: Double {
        guard item.target > 0 else { return 0 }
        return min(1, Double(sessionCount) / Double(item.target))
    }

    private func count(_ amount: Int, playHaptic: Bool = true) {
        guard amount > 0 else { return }
        sessionCount += amount
        model.addDhikr(amount, phraseID: item.id)

        if sessionCount >= item.target && !reachedTarget {
            reachedTarget = true
            WatchHaptics.success()
        } else if playHaptic {
            WatchHaptics.tick()
        }
    }

    // MARK: - Phrase picker

    private var phrasePicker: some View {
        NavigationStack {
            List(WatchDhikrCatalog.all) { entry in
                Button {
                    select(entry)
                } label: {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(entry.arabic)
                            .font(.body)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text("\(entry.transliteration) · \(entry.target)")
                            .font(.caption2)
                            .foregroundStyle(MihrabColor.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
            }
            .navigationTitle(L10n.wDhikrPhrase)
        }
    }

    private func select(_ entry: WatchDhikrItem) {
        // Switching phrase closes the previous session's books: its beads are
        // already in the day's total and on their way to the phone.
        model.flushDhikr()
        item = entry
        WatchSharedState.dhikrPhraseID = entry.id
        sessionCount = 0
        crown = 0
        reachedTarget = false
        showingPicker = false
        WatchHaptics.start()
    }
}
