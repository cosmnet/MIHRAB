import SwiftData
import SwiftUI

/// The Zikirmatik — the one screen in Mihrab that keeps the full-screen Metal
/// motif. Everywhere else the app is calm; here it breathes, because here the
/// user is doing one thing for minutes at a time and the room should move with
/// them.
struct DhikrView: View {
    @Environment(Theme.self) private var theme
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @State private var store = DhikrStore.shared

    // Current phrase & counting state.
    @State private var selected: DhikrItem = DhikrCatalog.subhanallah
    @State private var target = 33
    @State private var count = 0
    @State private var completedSets = 0
    @State private var session: DhikrSession?
    @State private var todayTotal = 0
    @State private var currentStreak = 0

    // Routine ("tesbihat") state.
    @State private var routine: DhikrRoutine?
    @State private var routineStep = 0
    @State private var routineFinished = false

    // Presentation.
    @State private var showStats = false
    @State private var showAchievements = false
    @State private var showLibrary = false
    @State private var strandMode = false

    // Motion.
    @State private var orbScale: CGFloat = 1
    @State private var rippleBorn: Date?
    @State private var milestoneBorn: Date?
    @State private var celebrating = false
    @State private var sparkBorn: Date?
    @State private var hintVisible = true
    @State private var unlockToast: DhikrAchievementSnapshot?
    @State private var phraseDirection = 1

    private let targets = [33, 99, 100, 500, 0]
    private let dialSide: CGFloat = 300
    private let chipHeight: CGFloat = 44
    private let toolbarSide: CGFloat = 44

    private var accent: Color { theme.accent }
    private var motif: ShaderMotif { settings.dhikrShaderMotif }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                MihrabBackdrop(surface: .dhikr, ramadanMode: theme.isRamadanMode)

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                    Spacer(minLength: 8)

                    counterSurface

                    hintLine

                    Spacer(minLength: 8)

                    footer
                }
                .padding(.bottom, MihrabSpace.tabClearance + 4)

                if celebrating || routineFinished {
                    celebrationOverlay
                }
            }
            .overlay(alignment: .top) {
                if let unlockToast {
                    DhikrAchievementToast(item: unlockToast)
                        .padding(.top, 6)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .navigationTitle(L10n.zikirmatik)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showStats) { DhikrStatsView() }
            .sheet(isPresented: $showAchievements) { DhikrAchievementSheet() }
            .sheet(isPresented: $showLibrary) {
                DhikrLibrarySheet(
                    onPick: { pick($0, resetCount: true) },
                    onStartRoutine: { start($0) }
                )
            }
            .task(id: celebrating) {
                guard celebrating else { return }
                try? await Task.sleep(for: .milliseconds(routine == nil ? 900 : 700))
                guard !Task.isCancelled else { return }
                finishSetPause()
            }
            .task(id: routineFinished) {
                guard routineFinished else { return }
                try? await Task.sleep(for: .milliseconds(1800))
                guard !Task.isCancelled else { return }
                withAnimation(reduceMotion ? nil : MihrabMotion.gentleAnimation) {
                    routineFinished = false
                    routine = nil
                    routineStep = 0
                }
            }
            .task(id: unlockToast?.id) {
                guard unlockToast != nil else { return }
                try? await Task.sleep(for: .milliseconds(2200))
                withAnimation(reduceMotion ? nil : MihrabMotion.snappyAnimation) { unlockToast = nil }
            }
            .task(id: rippleBorn) {
                guard rippleBorn != nil else { return }
                try? await Task.sleep(for: .milliseconds(500))
                rippleBorn = nil
            }
            .task(id: milestoneBorn) {
                guard milestoneBorn != nil else { return }
                try? await Task.sleep(for: .milliseconds(1000))
                milestoneBorn = nil
            }
        }
        .onAppear(perform: onAppear)
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            celebrating = false
            rippleBorn = nil
            milestoneBorn = nil
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { UIApplication.shared.isIdleTimerDisabled = false }
            else { refreshIdleTimer() }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            DhikrGoalBar(
                todayTotal: todayTotal,
                goal: settings.dailyDhikrGoal,
                streak: currentStreak,
                accent: accent
            )

            if let routine {
                routineBanner(routine)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                phraseStrip
            }
        }
        .animation(reduceMotion ? nil : MihrabMotion.gentleAnimation, value: routine?.id)
    }

    private func routineBanner(_ routine: DhikrRoutine) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(routine.localizedTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MihrabColor.textPrimary)
                    .lineLimit(1)
                Text(L10n.dhkRoutineStep(routineStep + 1, routine.steps.count))
                    .font(.caption2)
                    .foregroundStyle(MihrabColor.textSecondary)
            }
            Spacer(minLength: 8)
            HStack(spacing: 5) {
                ForEach(Array(routine.steps.enumerated()), id: \.offset) { index, _ in
                    Capsule()
                        .fill(index <= routineStep ? MihrabColor.brass : MihrabColor.textTertiary.opacity(0.4))
                        .frame(width: index == routineStep ? 18 : 8, height: 5)
                }
            }
            Button {
                DhikrFeedback.light()
                withAnimation(reduceMotion ? nil : MihrabMotion.gentleAnimation) {
                    self.routine = nil
                    routineStep = 0
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(MihrabColor.textTertiary)
                    .frame(width: MihrabSpace.hit, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(L10n.dhkRoutineStop))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius, fill: MihrabColor.moss.opacity(0.8))
    }

    private var phraseStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(store.stripItems) { item in
                        phraseChip(item)
                    }
                    libraryChip
                }
                .padding(.horizontal, 4)
                .frame(height: chipHeight)
                .animation(nil, value: selected)
            }
            .frame(height: chipHeight)
            .softHorizontalFade(edgeWidth: 20)
            .onChange(of: selected.id) { _, id in
                withAnimation(reduceMotion ? nil : MihrabMotion.gentleAnimation) {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
        .frame(height: chipHeight)
    }

    private func phraseChip(_ item: DhikrItem) -> some View {
        let on = item.id == selected.id
        return Button {
            pick(item, resetCount: true)
        } label: {
            VStack(spacing: 4) {
                Text(L10n.isArabic && !item.arabic.isEmpty ? item.arabic : item.localizedName)
                    .font(L10n.isArabic ? MihrabFont.arabic(15) : .subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Capsule()
                    .fill(MihrabColor.brass)
                    .frame(width: 20, height: 3)
                    .opacity(on ? 1 : 0)
            }
            .padding(.horizontal, 16)
            .frame(height: chipHeight)
            .foregroundStyle(on ? Color.white : MihrabColor.textSecondary)
            .background {
                if on {
                    Capsule().fill(accent.opacity(0.55))
                        .mihrabShaderPanel(motif, cornerRadius: chipHeight / 2, opacity: 0.5)
                }
            }
            .overlay {
                Capsule().strokeBorder(MihrabColor.mint.opacity(on ? 0.40 : 0), lineWidth: 1)
            }
            .clipShape(Capsule())
        }
        .pressable(reduceMotion)
        .id(item.id)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private var libraryChip: some View {
        Button {
            DhikrFeedback.light()
            showLibrary = true
        } label: {
            Label(L10n.dhkLibrary, systemImage: "books.vertical.fill")
                .font(.caption.weight(.semibold))
                .labelStyle(.iconOnly)
                .frame(width: chipHeight, height: chipHeight)
                .foregroundStyle(MihrabColor.brass)
                .background { Circle().fill(MihrabColor.abyss.opacity(0.35)) }
                .overlay { Circle().strokeBorder(MihrabColor.brass.opacity(0.35), lineWidth: 1) }
        }
        .pressable(reduceMotion)
        .accessibilityLabel(Text(L10n.dhkLibrary))
    }

    // MARK: - Counter surface

    @ViewBuilder
    private var counterSurface: some View {
        if strandMode {
            ZStack {
                DhikrStrandView(
                    count: count,
                    target: target,
                    accent: accent,
                    reduceMotion: reduceMotion,
                    onAdvance: { advance() }
                )
                strandReadout
                    .allowsHitTesting(false)
            }
            .frame(width: dialSide, height: dialSide)
            .frame(maxWidth: .infinity)
            .overlay {
                if let milestoneBorn, !reduceMotion {
                    DhikrMilestoneBurst(born: milestoneBorn, side: dialSide)
                }
            }
        } else {
            dial
                .contentShape(Circle())
                .onTapGesture { advance() }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 48).onEnded { value in
                        guard routine == nil,
                              abs(value.translation.width) > abs(value.translation.height) else { return }
                        cyclePhrase(forward: value.translation.width < 0)
                    }
                )
                .onLongPressGesture(minimumDuration: 0.7) { resetCount() }
        }
    }

    private var dial: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: reduceMotion || !celebrating)) { context in
            let flash = reduceMotion ? (celebrating ? 1.0 : 0.0) : brassFlash(at: context.date)
            dialContent(flash: flash)
        }
        .frame(width: dialSide, height: dialSide)
        .frame(maxWidth: .infinity)
        .accessibilityElement()
        .accessibilityLabel(
            L10n.dhikrA11y(count, target)
                + ", \(sessionTotal) \(L10n.thisSession)"
                + ", \(completedSets) \(L10n.setLabel(completedSets))"
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(L10n.dhikrA11yHint(selected.localizedName))
        .accessibilityAction { advance() }
    }

    private func dialContent(flash: Double) -> some View {
        ZStack {
            orbBase

            DhikrDialRing(
                side: dialSide,
                progress: target == 0 ? nil : progress,
                target: target,
                flash: flash,
                accent: accent,
                reduceMotion: reduceMotion
            )

            if let rippleBorn, !reduceMotion {
                DhikrRipple(born: rippleBorn, side: dialSide, color: accent)
            }

            dialCopy(flash: flash)

            if let milestoneBorn, !reduceMotion {
                DhikrMilestoneBurst(born: milestoneBorn, side: dialSide)
            }
        }
        .frame(width: dialSide, height: dialSide)
        .scaleEffect(orbScale)
    }

    private var orbBase: some View {
        ZStack {
            Circle()
                .fill(MihrabColor.moss.opacity(0.35))
                .mihrabShaderPanel(motif, cornerRadius: dialSide / 2, opacity: 0.5)
            RadialGradient(
                colors: [MihrabColor.abyss.opacity(0.06), MihrabColor.abyss.opacity(0.42)],
                center: .center,
                startRadius: 20,
                endRadius: dialSide / 2
            )
        }
        .clipShape(Circle())
        .glassEffect(.regular.interactive(), in: .circle)
        .overlay {
            Circle()
                .strokeBorder(MihrabColor.mint.opacity(0.34), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .frame(width: dialSide, height: dialSide)
    }

    private func dialCopy(flash: Double) -> some View {
        VStack(spacing: 6) {
            Group {
                Text(selected.displayScript)
                    .font(selected.arabic.isEmpty ? .title3.weight(.semibold) : MihrabFont.arabic(28))
                    .foregroundStyle(MihrabColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 26)

                if !L10n.isArabic {
                    Text(selected.localizedName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MihrabColor.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .id(selected.id)
            .transition(phraseTransition)

            Text("\(count)")
                .font(MihrabFont.countdown(92))
                .foregroundStyle(
                    LinearGradient(
                        colors: flash > 0.15
                            ? [MihrabColor.brass, MihrabColor.ramadanGold]
                            : [MihrabColor.sprout, MihrabColor.mint],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .contentTransition(.numericText(value: Double(count)))
                .shadow(color: (flash > 0.15 ? MihrabColor.brass : MihrabColor.mint).opacity(0.28), radius: 6)

            if target > 0 {
                Text("\(count) · \(target)")
                    .ornamentalCaps()
            } else {
                Text(L10n.dhkTargetLabel(0))
                    .ornamentalCaps()
            }
        }
        .frame(width: dialSide, height: dialSide)
    }

    private var strandReadout: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(MihrabFont.countdown(64))
                .foregroundStyle(
                    LinearGradient(colors: [MihrabColor.sprout, MihrabColor.mint],
                                   startPoint: .top, endPoint: .bottom)
                )
                .contentTransition(.numericText(value: Double(count)))
            Text(target > 0 ? "\(count) · \(target)" : L10n.dhkTargetLabel(0))
                .ornamentalCaps()
        }
    }

    private var phraseTransition: AnyTransition {
        let forward = phraseDirection > 0
        return .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.92)),
            removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private var hintLine: some View {
        ZStack {
            if hintVisible && count == 0 {
                Text(strandMode ? L10n.dhkStrandHint : L10n.dhkTapHint)
                    .font(.caption2)
                    .foregroundStyle(MihrabColor.textTertiary)
                    .transition(.opacity)
            } else if count > 0 && !strandMode {
                Text(L10n.dhkHoldToReset)
                    .font(.caption2)
                    .foregroundStyle(MihrabColor.textTertiary.opacity(0.7))
                    .transition(.opacity)
            }
        }
        .frame(height: 16)
        .padding(.top, 14)
        .allowsHitTesting(false)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 12) {
            modeSwitch
            TargetCycleBar(
                targets: targets,
                target: target,
                accent: accent,
                motif: motif,
                enabled: routine == nil
            ) { newValue in
                DhikrFeedback.light()
                withAnimation(reduceMotion ? nil : MihrabMotion.snappyAnimation) {
                    target = newValue
                    count = 0
                    completedSets = 0
                }
                persist()
            }
        }
        .padding(.horizontal, 20)
    }

    private var modeSwitch: some View {
        HStack(spacing: 6) {
            ForEach([false, true], id: \.self) { strand in
                let on = strandMode == strand
                Button {
                    guard strandMode != strand else { return }
                    DhikrFeedback.phraseSwap()
                    withAnimation(reduceMotion ? nil : MihrabMotion.gentleAnimation) {
                        strandMode = strand
                    }
                } label: {
                    Label(
                        strand ? L10n.dhkModeStrand : L10n.dhkModeCounter,
                        systemImage: strand ? "circle.hexagongrid.fill" : "hand.tap.fill"
                    )
                    .font(.caption.weight(.semibold))
                    .labelStyle(.titleAndIcon)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .foregroundStyle(on ? MihrabColor.textPrimary : MihrabColor.textTertiary)
                    .background {
                        if on {
                            Capsule().fill(MihrabColor.abyss.opacity(0.55))
                        }
                    }
                    .overlay {
                        Capsule().strokeBorder(MihrabColor.mint.opacity(on ? 0.3 : 0), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .frame(minHeight: MihrabSpace.hit)
        .accessibilityLabel(Text(L10n.dhkModeSwitch))
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                DhikrFeedback.light()
                showLibrary = true
            } label: {
                toolbarGlyph("books.vertical.fill")
            }
            .tint(MihrabColor.brass)
            .accessibilityLabel(Text(L10n.dhkLibrary))
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { showStats = true } label: {
                toolbarGlyph("chart.bar.fill")
            }
            .tint(accent)
            .accessibilityLabel(Text(L10n.dhikrStats))
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { showAchievements = true } label: {
                toolbarGlyph("seal.fill")
            }
            .tint(MihrabColor.brass)
            .accessibilityLabel(Text(L10n.achievements))
        }
    }

    private func toolbarGlyph(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .frame(width: toolbarSide, height: toolbarSide)
            .contentShape(Rectangle())
    }

    // MARK: - Overlays

    private var celebrationOverlay: some View {
        Text(routineFinished ? L10n.dhkRoutineComplete : L10n.setComplete)
            .font(.headline)
            .foregroundStyle(MihrabColor.brass)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(color: MihrabColor.brass.opacity(0.55), radius: 16)
            .transition(.opacity.combined(with: .scale(scale: 0.92)))
            .allowsHitTesting(false)
    }

    // MARK: - Derived values

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(count) / Double(target), 1)
    }

    private var sessionTotal: Int { completedSets * max(target, 1) + count }

    private func brassFlash(at now: Date) -> Double {
        guard celebrating, let sparkBorn else { return 0 }
        let elapsed = now.timeIntervalSince(sparkBorn)
        guard elapsed >= 0, elapsed < 0.5 else { return 0 }
        return 1 - elapsed / 0.5
    }

    // MARK: - Counting

    private func advance() {
        guard !celebrating else { return }
        count += 1
        todayTotal += 1
        MihrabIntentBridge.publishDhikrTotal(todayTotal, phraseID: selected.id)
        DhikrFeedback.tap(countInSet: count, target: target > 0 ? target : 33)
        playTapMotion()
        refreshIdleTimer()

        // 33 / 66 / 99 inside a longer set get their own golden moment.
        if target > 33, count % 33 == 0, count != target {
            DhikrFeedback.milestone(index: count / 33)
            milestoneBorn = Date()
        }

        if target > 0 && count >= target {
            completeSet()
        }
        persist()
    }

    private func playTapMotion() {
        guard !reduceMotion else { return }
        var snap = Transaction()
        snap.disablesAnimations = true
        withTransaction(snap) { orbScale = 0.945 }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) { orbScale = 1 }
        rippleBorn = Date()
    }

    private func completeSet() {
        DhikrFeedback.setComplete()
        completedSets += 1
        sparkBorn = Date()
        milestoneBorn = Date()
        withAnimation(reduceMotion ? nil : MihrabMotion.snappyAnimation) { celebrating = true }
        persist()
    }

    /// Called once the "set complete" badge has had its moment.
    private func finishSetPause() {
        if let routine {
            let next = routineStep + 1
            if next < routine.steps.count {
                routineStep = next
                DhikrFeedback.phraseSwap()
                phraseDirection = 1
                withAnimation(reduceMotion ? nil : MihrabMotion.gentleAnimation) {
                    celebrating = false
                }
                pick(routine.steps[next], resetCount: true, keepRoutine: true)
                return
            }
            DhikrFeedback.routineComplete()
            withAnimation(reduceMotion ? nil : MihrabMotion.snappyAnimation) {
                celebrating = false
                routineFinished = true
                count = 0
            }
            persist()
            return
        }

        withAnimation(reduceMotion ? nil : MihrabMotion.snappyAnimation) {
            count = 0
            celebrating = false
        }
        persist()
    }

    private func resetCount() {
        guard count > 0 else { return }
        DhikrFeedback.reset()
        withAnimation(reduceMotion ? nil : MihrabMotion.snappyAnimation) { count = 0 }
        persist()
    }

    private func cyclePhrase(forward: Bool) {
        let items = store.stripItems
        guard let index = items.firstIndex(where: { $0.id == selected.id }) else { return }
        let next = (index + (forward ? 1 : items.count - 1)) % items.count
        phraseDirection = forward ? 1 : -1
        pick(items[next], resetCount: true)
    }

    private func pick(_ item: DhikrItem, resetCount: Bool, keepRoutine: Bool = false) {
        if !keepRoutine, routine != nil {
            routine = nil
            routineStep = 0
        }
        if item.id != selected.id {
            DhikrFeedback.phraseSwap()
            if let from = store.stripItems.firstIndex(where: { $0.id == selected.id }),
               let to = store.stripItems.firstIndex(where: { $0.id == item.id }) {
                phraseDirection = to > from ? 1 : -1
            }
        }
        withAnimation(reduceMotion ? nil : MihrabMotion.gentleAnimation) {
            selected = item
            target = item.target
            if resetCount {
                count = 0
                completedSets = 0
            }
        }
        store.lastPhraseID = item.id
        loadOrCreateSession()
    }

    private func start(_ routine: DhikrRoutine) {
        guard let first = routine.steps.first else { return }
        DhikrFeedback.light()
        withAnimation(reduceMotion ? nil : MihrabMotion.gentleAnimation) {
            self.routine = routine
            routineStep = 0
            routineFinished = false
        }
        pick(first, resetCount: true, keepRoutine: true)
    }

    // MARK: - Lifecycle & persistence

    private func onAppear() {
        strandMode = store.opensInStrandMode
        // A Siri phrase, a widget button or a Control Center tap can add counts
        // while this view is not on screen; fold them in before anything reads
        // the totals. The SwiftData store is not in the App Group, so the
        // bridge is the only path back.
        if let pending = MihrabIntentBridge.consumePendingDhikrSession() {
            selected = pending.item
            target = pending.target
        } else if let last = store.item(id: store.lastPhraseID) {
            selected = last
            target = last.target
        }
        loadOrCreateSession()
        let outside = MihrabIntentBridge.drainOutsideTaps()
        if outside > 0 {
            count += outside
            persist()
        }
        recomputeTodayTotal()
        MihrabIntentBridge.publishDhikrTotal(todayTotal, phraseID: selected.id)
        DhikrAchievements.inscribeExisting(from: fetchSessions())
        Task {
            try? await Task.sleep(for: .seconds(3.5))
            withAnimation { hintVisible = false }
        }
    }

    private func refreshIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = store.keepAwakeWhileCounting && count > 0
    }

    private func persist() {
        guard let session else { return }
        session.count = count
        session.completedSets = completedSets
        session.target = target
        try? modelContext.save()
        recomputeTodayTotal()
        noteAchievements()
    }

    private func fetchSessions() -> [DhikrSession] {
        (try? modelContext.fetch(FetchDescriptor<DhikrSession>())) ?? []
    }

    private func recomputeTodayTotal() {
        let sessions = fetchSessions()
        let start = Calendar.current.startOfDay(for: Date())
        todayTotal = sessions.filter { $0.date >= start }.reduce(0) { $0 + $1.recited }
        currentStreak = DhikrSessionMetrics.streak(sessions, now: .now, calendar: .current)
    }

    private func noteAchievements() {
        let fresh = DhikrAchievements.reveal(from: fetchSessions(), celebrate: true)
        guard let newest = fresh.last else { return }
        if !celebrating { DhikrFeedback.light() }
        guard !showAchievements else { return }
        withAnimation(reduceMotion ? nil : MihrabMotion.snappyAnimation) { unlockToast = newest }
    }

    private func loadOrCreateSession() {
        let dhikrID = selected.id
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DhikrSession>(
            predicate: #Predicate { $0.dhikrID == dhikrID && $0.date >= today }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            session = existing
            count = existing.count
            completedSets = existing.completedSets
            if existing.target > 0 { target = existing.target }
        } else {
            let new = DhikrSession(
                dhikrID: selected.id,
                arabic: selected.arabic,
                transliteration: selected.transliteration,
                target: target
            )
            modelContext.insert(new)
            try? modelContext.save()
            session = new
        }
    }
}

// MARK: - Target bar

/// Five targets, one tap or one swipe apart. Disabled while a routine is
/// running — the routine owns the targets then, and silently changing one would
/// break the count the user is keeping in their head.
private struct TargetCycleBar: View {
    let targets: [Int]
    let target: Int
    let accent: Color
    let motif: ShaderMotif
    var enabled: Bool = true
    let onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(targets, id: \.self) { value in
                let on = value == target
                Button {
                    onChange(value)
                } label: {
                    Text(title(for: value))
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(on ? Color.white : MihrabColor.textPrimary.opacity(0.72))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background {
                            if on { Capsule().fill(accent.opacity(0.92)) }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background {
            Capsule()
                .fill(MihrabColor.abyss.opacity(0.40))
                .mihrabShaderPanel(motif, cornerRadius: 25, opacity: 0.28)
                .clipShape(Capsule())
        }
        .overlay {
            Capsule().strokeBorder(MihrabColor.mint.opacity(0.26), lineWidth: 1)
        }
        .opacity(enabled ? 1 : 0.4)
        .disabled(!enabled)
        .highPriorityGesture(
            DragGesture(minimumDistance: 28).onEnded { value in
                guard enabled,
                      abs(value.translation.width) > abs(value.translation.height) else { return }
                advance(by: value.translation.width < 0 ? 1 : -1)
            }
        )
        .accessibilityElement()
        .accessibilityLabel(Text(L10n.dhkCustomTarget))
        .accessibilityValue(Text(title(for: target)))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: advance(by: 1)
            case .decrement: advance(by: -1)
            @unknown default: break
            }
        }
    }

    private func title(for value: Int) -> String {
        value == 0 ? "∞" : "\(value)"
    }

    private func advance(by step: Int) {
        let index = targets.firstIndex(of: target) ?? 0
        let next = (index + step + targets.count) % targets.count
        onChange(targets[next])
    }
}
