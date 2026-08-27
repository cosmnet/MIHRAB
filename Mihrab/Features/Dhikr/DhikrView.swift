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
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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

    // Focus mode: everything but the dial steps out of the way.
    @State private var focusMode = false
    @State private var focusHintVisible = false
    @State private var holdProgress: Double = 0

    private let targets = [33, 99, 100, 500, 0]
    /// The space the layout actually has, so the dial can be as big as the
    /// device allows instead of a number picked for one phone.
    @State private var available: CGSize = .zero

    /// Dial size is deliberately *not* `@ScaledMetric` — it is a touch target
    /// and a canvas, not type, and growing it at AX5 would push the footer off
    /// screen. The number inside it scales instead, capped so it still fits.
    ///
    /// It *is* proportional to the screen. This is the primary action of the
    /// screen, and a screen that will be used by people who want a large,
    /// unmissable target, so it takes the room it can get instead of the flat
    /// 300 it used to take on every device from an SE to a Pro Max. Three
    /// bounds keep it honest: the width, so it never touches the edges; the
    /// height, so the footer can never be pushed off; and a ceiling, because
    /// past a point a bigger circle is just a bigger circle.
    private var dialSide: CGFloat {
        guard available.width > 0, available.height > 0 else { return 300 }
        // The header and footer grow with the text size and the dial has to
        // give that room back, so it claims a smaller share when they are big.
        let share: CGFloat = dynamicTypeSize.isAccessibilitySize ? 0.40 : 0.50
        return min(min(available.width - 36, available.height * share), 372)
    }

    private let chipHeight: CGFloat = 44
    private let toolbarSide: CGFloat = 44
    /// How long the reset press has to be held before it commits.
    private let holdToResetDuration: Double = 0.9

    private var accent: Color { theme.accent }
    private var motif: ShaderMotif { settings.dhikrShaderMotif }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                MihrabBackdrop(surface: .dhikr, ramadanMode: theme.isRamadanMode)

                focusTapLayer

                VStack(spacing: 0) {
                    if !focusMode {
                        header
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Spacer(minLength: 8)

                    counterSurface

                    hintLine

                    Spacer(minLength: 8)

                    if !focusMode {
                        footer
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.bottom, MihrabSpace.tabClearance + 4)
                .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
                    available = size
                }

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
            // The nav bar is chrome too — focus mode is not focus mode with a
            // title and three glyphs still sitting on top.
            .toolbar(focusMode ? .hidden : .visible, for: .navigationBar)
            .statusBarHidden(focusMode)
            .task(id: focusMode) {
                guard focusMode else {
                    focusHintVisible = false
                    return
                }
                withAnimation(reduceMotion ? nil : MihrabMotion.gentleAnimation) {
                    focusHintVisible = true
                }
                try? await Task.sleep(for: .seconds(4))
                guard !Task.isCancelled else { return }
                withAnimation(reduceMotion ? nil : MihrabMotion.gentleAnimation) {
                    focusHintVisible = false
                }
            }
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
            // The click synth holds an audio session, so it is only alive while
            // the strand is actually on screen and the user asked for it.
            .task(id: strandMode && store.beadSoundEnabled) {
                if strandMode && store.beadSoundEnabled {
                    TasbihClickSynth.shared.prepare()
                } else {
                    TasbihClickSynth.shared.shutdown()
                }
            }
        }
        .onAppear(perform: onAppear)
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            TasbihClickSynth.shared.shutdown()
            DhikrScreenDim.restore()
            celebrating = false
            rippleBorn = nil
            milestoneBorn = nil
            holdProgress = 0
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                UIApplication.shared.isIdleTimerDisabled = false
                // Never leave a dimmed screen behind us in the app switcher,
                // and never sit on an audio session in the background.
                TasbihClickSynth.shared.shutdown()
                DhikrScreenDim.restore()
            } else {
                refreshIdleTimer()
                applyScreenDim()
                if strandMode && store.beadSoundEnabled {
                    TasbihClickSynth.shared.prepare()
                }
            }
        }
    }

    // MARK: - Focus mode

    /// The whole backdrop is the focus toggle: one tap anywhere that is not the
    /// dial hides (or restores) the chrome, and in focus mode a downward drag
    /// from anywhere brings it back — the same "swipe down to leave" gesture
    /// full-screen video uses.
    private var focusTapLayer: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture { setFocus(!focusMode) }
            .gesture(
                DragGesture(minimumDistance: 40)
                    .onEnded { value in
                        guard focusMode,
                              value.translation.height > 40,
                              abs(value.translation.height) > abs(value.translation.width)
                        else { return }
                        setFocus(false)
                    }
            )
            .accessibilityHidden(true)
    }

    private func setFocus(_ on: Bool) {
        guard focusMode != on else { return }
        DhikrFeedback.light()
        withAnimation(reduceMotion ? nil : MihrabMotion.gentleAnimation) {
            focusMode = on
        }
        applyScreenDim()
    }

    private func applyScreenDim() {
        if focusMode && store.dimsInFocusMode {
            DhikrScreenDim.dim()
        } else {
            DhikrScreenDim.restore()
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
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(L10n.dhkRoutineStep(routineStep + 1, routine.steps.count))
                    .font(.caption2)
                    .foregroundStyle(MihrabColor.textSecondary)
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 8)
            // Decorative: the step count is already spoken in the label above.
            HStack(spacing: 5) {
                ForEach(Array(routine.steps.enumerated()), id: \.offset) { index, _ in
                    Capsule()
                        .fill(index <= routineStep ? MihrabColor.brass : MihrabColor.textTertiary.opacity(0.4))
                        .frame(width: index == routineStep ? 18 : 8, height: 5)
                }
            }
            .accessibilityHidden(true)
            Button {
                DhikrFeedback.light()
                withAnimation(reduceMotion ? nil : MihrabMotion.gentleAnimation) {
                    self.routine = nil
                    routineStep = 0
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .frame(width: MihrabSpace.hit, height: MihrabSpace.hit)
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
                Group {
                    if L10n.isArabic && !item.arabic.isEmpty {
                        Text(item.arabic).mihrabArabic(15, ceiling: .accessibility2)
                    } else {
                        Text(item.localizedName)
                            .font(.subheadline.weight(.semibold))
                            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    }
                }
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
                    onAdvance: { advance(by: $0, silent: true) }
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
                        // "Next" is a swipe towards the end of the line, which
                        // is left in Turkish/English and right in Arabic.
                        let towardsEnd = layoutDirection == .rightToLeft
                            ? value.translation.width > 0
                            : value.translation.width < 0
                        cyclePhrase(forward: towardsEnd)
                    }
                )
                // Reset costs a deliberate hold, and the ring shows how much of
                // it is left. Released early it unwinds and nothing is lost.
                .onLongPressGesture(
                    minimumDuration: holdToResetDuration,
                    maximumDistance: 30,
                    perform: { resetCount() },
                    onPressingChanged: { pressing in trackResetHold(pressing) }
                )
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
        // The reset gesture is a hold and the focus toggle is a background tap;
        // neither is reachable with VoiceOver on, so both get named actions.
        .accessibilityAction(named: Text(L10n.dhkHoldToReset)) { resetCount() }
        .accessibilityAction(named: Text(focusMode ? L10n.dhkFocusExit : L10n.dhkFocusEnter)) {
            setFocus(!focusMode)
        }
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

            if holdProgress > 0 {
                DhikrHoldRing(progress: holdProgress, side: dialSide)
            }

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
                Group {
                    if selected.arabic.isEmpty {
                        Text(selected.displayScript)
                            .font(.title3.weight(.semibold))
                    } else {
                        Text(selected.displayScript)
                            .mihrabArabic(28)
                    }
                }
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

            Text(count.formatted())
                .mihrabCountdown(92)
                .lineLimit(1)
                .minimumScaleFactor(0.45)
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

            // `formatted()` and not string interpolation: Arabic locales use
            // Eastern Arabic numerals, and hand-built strings would not.
            if target > 0 {
                Text("\(count.formatted()) · \(target.formatted())")
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
            Text(count.formatted())
                .mihrabCountdown(64)
                .lineLimit(1)
                .minimumScaleFactor(0.45)
                .foregroundStyle(
                    LinearGradient(colors: [MihrabColor.sprout, MihrabColor.mint],
                                   startPoint: .top, endPoint: .bottom)
                )
                .contentTransition(.numericText(value: Double(count)))
            Text(target > 0
                 ? "\(count.formatted()) · \(target.formatted())"
                 : L10n.dhkTargetLabel(0))
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
            if focusMode {
                DhikrFocusHint(visible: focusHintVisible)
            } else if hintVisible && count == 0 {
                Text(strandMode ? L10n.dhkStrandHint : L10n.dhkTapHint)
                    .font(.caption2)
                    // textSecondary rather than textTertiary: tertiary is
                    // 2.9:1 on moss / 4.1:1 on abyss, both below 4.5:1.
                    .foregroundStyle(MihrabColor.textSecondary)
                    .transition(.opacity)
            } else if strandMode && count > 0 && count < 6 {
                // The strand had no second line at all; the one thing worth
                // saying here is the gesture nobody would guess.
                Text(L10n.dhkMaterialHint)
                    .font(.caption2)
                    .foregroundStyle(MihrabColor.textSecondary.opacity(0.85))
                    .transition(.opacity)
            } else if count > 0 && !strandMode {
                Text(L10n.dhkHoldToReset)
                    .font(.caption2)
                    .foregroundStyle(MihrabColor.textSecondary.opacity(0.85))
                    .transition(.opacity)
            }
        }
        .frame(minHeight: 16)
        .padding(.top, 14)
        .padding(.horizontal, 24)
        .multilineTextAlignment(.center)
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
                enabled: routine == nil,
                layoutDirection: layoutDirection
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

    /// One button that says where it takes you.
    ///
    /// This used to be a two-chip segmented control, which asks the reader to
    /// work out which half is lit before they can act. A single control naming
    /// its destination — "Switch to tasbih" — needs no such reading, is one
    /// fewer thing standing on the screen, and can be a full 44pt tall instead
    /// of the 34 two chips had to squeeze into.
    private var modeSwitch: some View {
        Button {
            DhikrFeedback.phraseSwap()
            withAnimation(reduceMotion ? nil : MihrabMotion.gentleAnimation) {
                strandMode.toggle()
            }
        } label: {
            Label(
                strandMode ? L10n.dhkModeToCounter : L10n.dhkModeToStrand,
                systemImage: strandMode ? "hand.tap.fill" : "circle.hexagongrid.fill"
            )
            .font(.subheadline.weight(.semibold))
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 18)
            .frame(minHeight: MihrabSpace.hit)
            .foregroundStyle(MihrabColor.textPrimary)
            .background { Capsule().fill(MihrabColor.abyss.opacity(0.55)) }
            .overlay { Capsule().strokeBorder(MihrabColor.mint.opacity(0.3), lineWidth: 1) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(strandMode ? L10n.dhkModeToCounter : L10n.dhkModeToStrand))
        .accessibilityHint(Text(L10n.dhkModeSwitch))
    }

    // MARK: - Toolbar

    /// Two controls, not four.
    ///
    /// Focus mode, statistics and achievements are all *occasional* — none of
    /// them is why anyone opens this screen — so they moved behind one menu.
    /// What is left on the bar is the phrase library and that menu, which is
    /// two large, well-separated targets instead of four small crowded ones.
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
            Menu {
                Button {
                    setFocus(true)
                } label: {
                    Label(L10n.dhkFocusEnter, systemImage: "arrow.down.right.and.arrow.up.left")
                }
                Button {
                    DhikrFeedback.light()
                    showStats = true
                } label: {
                    Label(L10n.dhikrStats, systemImage: "chart.bar.fill")
                }
                Button {
                    DhikrFeedback.light()
                    showAchievements = true
                } label: {
                    Label(L10n.achievements, systemImage: "seal.fill")
                }
            } label: {
                toolbarGlyph("ellipsis.circle")
            }
            .tint(MihrabColor.textSecondary)
            .accessibilityLabel(Text(L10n.dhkMore))
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
            // Already spoken via AccessibilityNotification.Announcement.
            .accessibilityHidden(true)
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

    /// - Parameter steps: how many counts just happened. The strand can hand us
    ///   several in one frame when the beads are flying, and the old one-at-a-
    ///   time path charged a SwiftData save *and* a full session refetch for
    ///   every single one — a fast flick cost five of each. The batch does the
    ///   arithmetic in one go and persists once.
    /// - Parameter silent: the caller already gave its own feedback (the strand
    ///   ticks per bead, on its own budget), so the counter should not tick too.
    private func advance(by steps: Int = 1, silent: Bool = false) {
        guard !celebrating, steps > 0 else { return }
        let before = count
        count += steps
        todayTotal += steps
        MihrabIntentBridge.publishDhikrTotal(todayTotal, phraseID: selected.id)
        if !silent {
            DhikrFeedback.tap(countInSet: count, target: target > 0 ? target : 33)
            playTapMotion()
        }
        refreshIdleTimer()

        // 33 / 66 / 99 inside a longer set get their own golden moment. With a
        // batch, the milestone is whichever multiple of 33 the run crossed —
        // checking `count % 33` alone would miss it when a flick jumps over.
        if target > 33 {
            let crossed = (count / 33) - (before / 33)
            if crossed > 0, count / 33 * 33 != target {
                DhikrFeedback.milestone(index: count / 33)
                milestoneBorn = Date()
            }
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
        // The celebration is a badge and a haptic; neither reaches VoiceOver.
        AccessibilityNotification.Announcement(L10n.setComplete).post()
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

    /// Drives the confirmation ring while the reset press is held.
    private func trackResetHold(_ pressing: Bool) {
        guard count > 0 else {
            holdProgress = 0
            return
        }
        if pressing {
            DhikrFeedback.light()
            // The ring is the contract with the user — it fills in real time
            // even under Reduce Motion, because here motion *is* the message.
            withAnimation(.linear(duration: holdToResetDuration)) { holdProgress = 1 }
        } else {
            withAnimation(reduceMotion ? nil : MihrabMotion.snappyAnimation) { holdProgress = 0 }
        }
    }

    private func resetCount() {
        guard count > 0 else {
            holdProgress = 0
            return
        }
        DhikrFeedback.reset()
        withAnimation(reduceMotion ? nil : MihrabMotion.snappyAnimation) {
            count = 0
            holdProgress = 0
        }
        AccessibilityNotification.Announcement(L10n.dhkResetDone).post()
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

/// Adjustable-trait wrapper for `TargetCycleBar`, lifted out of the body.
private struct TargetCycleAccessibility: ViewModifier {
    let target: Int
    let advance: (Int) -> Void

    func body(content: Content) -> some View {
        content
            .accessibilityElement()
            .accessibilityLabel(Text(L10n.dhkCustomTarget))
            .accessibilityValue(Text(target == 0 ? L10n.dhkTargetLabel(0) : target.formatted()))
            // No `.isAdjustable` trait exists; `accessibilityAdjustableAction`
            // is what makes an element adjustable to VoiceOver.
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: advance(1)
                case .decrement: advance(-1)
                @unknown default: break
                }
            }
    }
}

private struct TargetCycleBar: View {
    let targets: [Int]
    let target: Int
    let accent: Color
    let motif: ShaderMotif
    var enabled: Bool = true
    var layoutDirection: LayoutDirection = .leftToRight
    let onChange: (Int) -> Void

    // Split into three pieces on purpose: as one chain this body exceeded the
    // type checker's time limit.
    var body: some View {
        chipRow
            .padding(5)
            .background { capsuleBackground }
            .overlay { Capsule().strokeBorder(MihrabColor.mint.opacity(0.26), lineWidth: 1) }
            .opacity(enabled ? 1 : 0.4)
            .disabled(!enabled)
            .modifier(TargetCycleAccessibility(target: target, advance: advance))
            .highPriorityGesture(
                DragGesture(minimumDistance: 28).onEnded { value in
                guard enabled,
                      abs(value.translation.width) > abs(value.translation.height) else { return }
                let towardsEnd = layoutDirection == .rightToLeft
                    ? value.translation.width > 0
                    : value.translation.width < 0
                    advance(by: towardsEnd ? 1 : -1)
                }
            )
    }

    private var chipRow: some View {
        HStack(spacing: 0) {
            ForEach(targets, id: \.self) { value in
                Button { onChange(value) } label: {
                    chipLabel(title(for: value), selected: value == target)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var capsuleBackground: some View {
        Capsule()
            .fill(MihrabColor.abyss.opacity(0.40))
            .mihrabShaderPanel(motif, cornerRadius: 25, opacity: 0.28)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func chipLabel(_ title: String, selected: Bool) -> some View {
        let tint: Color = selected ? .white : MihrabColor.textPrimary.opacity(0.85)
        Text(title)
            .font(.subheadline.weight(.semibold).monospacedDigit())
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background { selected ? Capsule().fill(accent.opacity(0.92)) : nil }
    }

    private func title(for value: Int) -> String {
        value == 0 ? "∞" : value.formatted()
    }

    private func advance(by step: Int) {
        let index = targets.firstIndex(of: target) ?? 0
        let next = (index + step + targets.count) % targets.count
        onChange(targets[next])
    }
}
