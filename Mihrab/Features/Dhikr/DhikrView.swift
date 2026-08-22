import SwiftData
import SwiftUI

struct DhikrOption: Identifiable, Hashable {
    let id: String
    let arabic: String
    let transliteration: String

    var localizedName: String { L10n.dhikrPhrase(id) }

    static let defaults: [DhikrOption] = [
        .init(id: "subhanallah", arabic: "سُبْحَانَ اللَّه", transliteration: "Subhanallah"),
        .init(id: "alhamdulillah", arabic: "الْحَمْدُ لِلَّه", transliteration: "Alhamdulillah"),
        .init(id: "allahu-akbar", arabic: "اللَّهُ أَكْبَر", transliteration: "Allahu Akbar"),
        .init(id: "la-ilaha", arabic: "لَا إِلَهَ إِلَّا اللَّه", transliteration: "La ilaha illallah"),
        .init(id: "salawat", arabic: "اللَّهُمَّ صَلِّ عَلَى مُحَمَّد", transliteration: "Salawat"),
        .init(id: "astaghfirullah", arabic: "أَسْتَغْفِرُ اللَّه", transliteration: "Astaghfirullah"),
    ]
}

struct DhikrView: View {
    @Environment(Theme.self) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selected: DhikrOption = DhikrOption.defaults[0]
    @State private var target = 33
    @State private var count = 0
    @State private var completedSets = 0
    @State private var orbScale: CGFloat = 1
    @State private var rippleBorn: Date?
    @State private var showStats = false
    @State private var showAchievements = false
    @State private var keepAwake = false
    @State private var session: DhikrSession?
    @State private var celebrating = false
    @State private var hintVisible = true
    @State private var sparkBorn: Date?
    @State private var unlockToast: DhikrAchievementSnapshot?

    private let targets = [33, 99, 100, 500, 0]
    private let orbSide: CGFloat = 256
    private let chipHeight: CGFloat = 56
    private let toolbarSide: CGFloat = 44

    var body: some View {
        NavigationStack {
            ZStack {
                shaderBackdrop

                VStack(spacing: 0) {
                    dhikrSelector
                        .padding(.top, 8)

                    Spacer(minLength: 0)

                    orb

                    Spacer(minLength: 0)

                    targetPicker
                    statsStrip
                }
                .padding(.bottom, MihrabSpace.tabClearance)
                .contentShape(Rectangle())
                .onTapGesture { tap() }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 48).onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        cyclePhrase(forward: value.translation.width < 0)
                    }
                )
                .onLongPressGesture(minimumDuration: 0.7) {
                    HapticsEngine.shared.warning()
                    withAnimation(reduceMotion ? nil : MihrabMotion.snappyAnimation) {
                        count = 0
                    }
                    persist()
                }

                if celebrating {
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showStats = true } label: {
                        toolbarGlyph("chart.bar.fill")
                    }
                    .tint(theme.accent)
                    .accessibilityLabel(Text(L10n.dhikrStats))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAchievements = true } label: {
                        toolbarGlyph("seal.fill")
                    }
                    .tint(MihrabColor.brass)
                    .accessibilityLabel(Text(L10n.achievements))
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        keepAwake.toggle()
                        UIApplication.shared.isIdleTimerDisabled = keepAwake
                    } label: {
                        toolbarGlyph(keepAwake ? "sun.max.fill" : "moon.zzz")
                    }
                    .tint(keepAwake ? MihrabColor.brass : MihrabColor.textTertiary)
                    .accessibilityLabel(Text(L10n.keepAwake))
                }
            }
            .sheet(isPresented: $showStats) { DhikrStatsView() }
            .sheet(isPresented: $showAchievements) { DhikrAchievementSheet() }
            .task(id: celebrating) {
                guard celebrating else { return }
                try? await Task.sleep(for: .milliseconds(900))
                withAnimation(reduceMotion ? nil : MihrabMotion.snappyAnimation) {
                    count = 0
                    celebrating = false
                }
                persist()
            }
            .task(id: unlockToast?.id) {
                guard unlockToast != nil else { return }
                try? await Task.sleep(for: .milliseconds(2200))
                withAnimation(reduceMotion ? nil : MihrabMotion.snappyAnimation) {
                    unlockToast = nil
                }
            }
            .task(id: rippleBorn) {
                guard rippleBorn != nil else { return }
                try? await Task.sleep(for: .milliseconds(480))
                rippleBorn = nil
            }
        }
        .onAppear {
            loadOrCreateSession()
            inscribeExistingAchievements()
            Task {
                try? await Task.sleep(for: .seconds(3.5))
                withAnimation { hintVisible = false }
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            celebrating = false
            rippleBorn = nil
        }
    }

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(count) / Double(target), 1)
    }

    private var sessionTotal: Int {
        completedSets * max(target, 1) + count
    }

    private var shaderBackdrop: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 12.0, paused: reduceMotion)) { context in
            let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            DhikrShaderField(
                time: t,
                flash: brassFlash(at: context.date),
                ramadan: theme.isRamadanMode
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var orb: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: reduceMotion || !celebrating)) { context in
            let flash = brassFlash(at: context.date)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                MihrabColor.abyss.opacity(0.10),
                                MihrabColor.abyss.opacity(0.42)
                            ],
                            center: .center,
                            startRadius: 24,
                            endRadius: orbSide / 2
                        )
                    )

                Circle()
                    .strokeBorder(MihrabColor.mint.opacity(0.22), lineWidth: 1)

                if let rippleBorn, !reduceMotion {
                    DhikrInnerRipple(born: rippleBorn, side: orbSide)
                }

                orbCopy(flash: flash)
            }
            .frame(width: orbSide, height: orbSide)
            .clipShape(Circle())
            .scaleEffect(orbScale)
        }
        .frame(width: orbSide, height: orbSide)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .bottom) {
            if hintVisible && count == 0 {
                Text(L10n.swipePhrase)
                    .font(.caption2)
                    .foregroundStyle(MihrabColor.textTertiary)
                    .padding(.bottom, 4)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(L10n.dhikrA11y(count, target))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(L10n.dhikrA11yHint(selected.localizedName))
    }

    private func brassFlash(at now: Date) -> Double {
        guard celebrating, let sparkBorn else { return 0 }
        let elapsed = now.timeIntervalSince(sparkBorn)
        guard elapsed >= 0, elapsed < 0.3 else { return 0 }
        return 1 - elapsed / 0.3
    }

    private func orbCopy(flash: Double) -> some View {
        VStack(spacing: 6) {
            Text(primaryPhrase)
                .font(L10n.isArabic ? MihrabFont.arabic(26) : .title3.weight(.semibold))
                .foregroundStyle(MihrabColor.textPrimary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.55)
                .lineLimit(2)
                .padding(.horizontal, 18)

            if !L10n.isArabic {
                Text(selected.arabic)
                    .font(MihrabFont.arabic(18))
                    .foregroundStyle(MihrabColor.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 16)
            }

            Text("\(count)")
                .font(MihrabFont.countdown(88))
                .foregroundStyle(
                    LinearGradient(
                        colors: flash > 0.15
                            ? [MihrabColor.brass, MihrabColor.ramadanGold]
                            : [MihrabColor.sprout, MihrabColor.mint],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: (flash > 0.15 ? MihrabColor.brass : MihrabColor.mint).opacity(0.55), radius: 16)
                .contentTransition(.numericText())
                .animation(reduceMotion ? nil : MihrabMotion.snappyAnimation, value: count)

            if target > 0 {
                Text(L10n.ofTargetSet(count, target, completedSets + 1))
                    .font(.caption)
                    .foregroundStyle(MihrabColor.textSecondary)
            }
        }
        .frame(width: orbSide, height: orbSide)
    }

    private var primaryPhrase: String {
        L10n.isArabic ? selected.arabic : selected.localizedName
    }

    private var celebrationOverlay: some View {
        Text(L10n.setComplete)
            .font(.headline)
            .foregroundStyle(MihrabColor.brass)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(color: MihrabColor.brass.opacity(0.55), radius: 16)
            .transition(.opacity.combined(with: .scale(scale: 0.92)))
            .allowsHitTesting(false)
    }

    private func toolbarGlyph(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .frame(width: toolbarSide, height: toolbarSide)
            .contentShape(Rectangle())
    }

    private func tap() {
        guard !celebrating else { return }
        count += 1
        HapticsEngine.shared.dhikrTap(progress: progress)
        playTapMotion()

        if target > 0 && count >= target {
            completeSet()
        }
        persist()
    }

    private func playTapMotion() {
        guard !reduceMotion else { return }
        var snap = Transaction()
        snap.disablesAnimations = true
        withTransaction(snap) { orbScale = 0.94 }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
            orbScale = 1
        }
        rippleBorn = Date()
    }

    private func completeSet() {
        HapticsEngine.shared.setComplete()
        completedSets += 1
        sparkBorn = Date()
        withAnimation(reduceMotion ? nil : MihrabMotion.snappyAnimation) {
            celebrating = true
        }
        persist()
    }

    private func cyclePhrase(forward: Bool) {
        HapticsEngine.shared.light()
        guard let index = DhikrOption.defaults.firstIndex(of: selected) else { return }
        let next = (index + (forward ? 1 : DhikrOption.defaults.count - 1)) % DhikrOption.defaults.count
        selected = DhikrOption.defaults[next]
        count = 0
        completedSets = 0
        loadOrCreateSession()
    }

    private var dhikrSelector: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(DhikrOption.defaults) { option in
                        dhikrChip(option)
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: chipHeight)
                .animation(nil, value: selected)
            }
            .frame(height: chipHeight)
            .fixedSize(horizontal: false, vertical: true)
            .softHorizontalFade(edgeWidth: 24)
            .onChange(of: selected) { _, newValue in
                proxy.scrollTo(newValue.id, anchor: .center)
            }
        }
        .frame(height: chipHeight)
    }

    private func dhikrChip(_ option: DhikrOption) -> some View {
        let on = selected == option
        return Button {
            selected = option
            count = 0
            completedSets = 0
            loadOrCreateSession()
        } label: {
            VStack(spacing: 3) {
                Text(L10n.isArabic ? option.arabic : option.localizedName)
                    .font(L10n.isArabic ? MihrabFont.arabic(15) : .subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if !L10n.isArabic {
                    Text(option.arabic)
                        .font(MihrabFont.arabic(13))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .opacity(0.8)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: chipHeight)
            .foregroundStyle(on ? Color.white : MihrabColor.textSecondary)
            .background(Capsule().fill(on ? theme.accent : MihrabColor.moss))
            .overlay {
                Capsule()
                    .strokeBorder(MihrabColor.mint.opacity(on ? 0.40 : 0.12), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .id(option.id)
    }

    private var targetPicker: some View {
        HStack(spacing: 8) {
            ForEach(targets, id: \.self) { value in
                targetChip(value)
            }
        }
        .frame(height: 36)
        .padding(.vertical, 8)
        .animation(nil, value: target)
    }

    private func targetChip(_ value: Int) -> some View {
        let on = target == value
        return Button {
            HapticsEngine.shared.light()
            target = value
            count = 0
            completedSets = 0
            persist()
        } label: {
            Text(value == 0 ? "∞" : "\(value)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .frame(minWidth: 44)
                .frame(height: 36)
                .foregroundStyle(on ? Color.white : MihrabColor.textSecondary)
                .background(Capsule().fill(on ? theme.accent : MihrabColor.moss))
        }
        .buttonStyle(.plain)
    }

    private var statsStrip: some View {
        Button { showStats = true } label: {
            HStack(spacing: 28) {
                StatPill(value: "\(completedSets)", label: L10n.setLabel(completedSets))
                StatPill(value: "\(sessionTotal)", label: L10n.thisSession)
            }
            .padding(.top, 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(L10n.dhikrStats))
    }

    private func persist() {
        guard let session else { return }
        session.count = count
        session.completedSets = completedSets
        session.target = target
        try? modelContext.save()
        noteAchievements()
    }

    private func fetchSessions() -> [DhikrSession] {
        (try? modelContext.fetch(FetchDescriptor<DhikrSession>())) ?? []
    }

    private func inscribeExistingAchievements() {
        DhikrAchievements.inscribeExisting(from: fetchSessions())
    }

    private func noteAchievements() {
        let fresh = DhikrAchievements.reveal(from: fetchSessions(), celebrate: true)
        guard let newest = fresh.last else { return }
        if !celebrating {
            HapticsEngine.shared.success()
        }
        guard !showAchievements else { return }
        withAnimation(reduceMotion ? nil : MihrabMotion.snappyAnimation) {
            unlockToast = newest
        }
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
            target = existing.target
        } else {
            let new = DhikrSession(dhikrID: selected.id, arabic: selected.arabic,
                                   transliteration: selected.transliteration, target: target)
            modelContext.insert(new)
            try? modelContext.save()
            session = new
        }
    }
}

private struct DhikrShaderField: View {
    let time: TimeInterval
    let flash: Double
    let ramadan: Bool

    var body: some View {
        ZStack {
            (ramadan ? MihrabColor.ramadanViolet.opacity(0.55) : MihrabColor.abyss)

            Image("dhikr-bg")
                .resizable()
                .scaledToFill()
                .opacity(0.35)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .accessibilityHidden(true)

            MeshGradient(
                width: 3,
                height: 3,
                points: meshPoints,
                colors: meshColors
            )
            .opacity(0.84)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.20),
                            MihrabColor.mint.opacity(0.12),
                            .clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 200
                    )
                )
                .frame(width: 380, height: 240)
                .offset(
                    x: 96 * cos(time * 2 * .pi / 20),
                    y: -36 + 72 * sin(time * 2 * .pi / 26)
                )
                .blendMode(.plusLighter)

            DhikrGrain()
        }
    }

    private var meshPoints: [SIMD2<Float>] {
        let cx = Float(0.50 + 0.18 * cos(time * 2 * .pi / 22))
        let cy = Float(0.48 + 0.16 * sin(time * 2 * .pi / 28))
        let top = Float(0.50 + 0.12 * sin(time * 2 * .pi / 26))
        let lead = Float(0.50 + 0.10 * cos(time * 2 * .pi / 24))
        let trail = Float(0.50 + 0.10 * sin(time * 2 * .pi / 30))
        let bottom = Float(0.50 + 0.11 * cos(time * 2 * .pi / 32))
        return [
            SIMD2(0, 0), SIMD2(top, 0), SIMD2(1, 0),
            SIMD2(0, lead), SIMD2(cx, cy), SIMD2(1, trail),
            SIMD2(0, 1), SIMD2(bottom, 1), SIMD2(1, 1)
        ]
    }

    private var meshColors: [Color] {
        let f = flash
        let gold = ramadan ? MihrabColor.ramadanGold : MihrabColor.brass
        return [
            MihrabColor.forest.mix(with: gold, by: f * 0.4),
            MihrabColor.emerald.mix(with: gold, by: f * 0.5),
            MihrabColor.moss.mix(with: gold, by: f * 0.3),
            MihrabColor.moss.mix(with: gold, by: f * 0.35),
            MihrabColor.mint.mix(with: gold, by: f),
            MihrabColor.emerald.mix(with: gold, by: f * 0.55),
            MihrabColor.forest.mix(with: gold, by: f * 0.25),
            MihrabColor.moss.mix(with: gold, by: f * 0.3),
            MihrabColor.sprout.mix(with: gold, by: f * 0.7)
        ]
    }
}

private struct DhikrGrain: View {
    var body: some View {
        Canvas { canvas, size in
            var rng = DhikrSeededGenerator(seed: 42)
            let dotCount = Int(size.width * size.height / 1000)
            for _ in 0..<dotCount {
                let x = CGFloat.random(in: 0...size.width, using: &rng)
                let y = CGFloat.random(in: 0...size.height, using: &rng)
                let shade = Double.random(in: 0...1, using: &rng)
                canvas.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1.2, height: 1.2)),
                    with: .color(.white.opacity(0.022 + 0.028 * shade))
                )
            }
        }
        .allowsHitTesting(false)
    }
}

private struct DhikrSeededGenerator: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

private struct DhikrInnerRipple: View {
    let born: Date
    let side: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let elapsed = context.date.timeIntervalSince(born)
            let duration = 0.46
            let u = min(max(elapsed / duration, 0), 1)
            Circle()
                .stroke(MihrabColor.mint.opacity(0.50 * (1 - u)), lineWidth: 2.8 * (1 - u) + 0.6)
                .padding(28)
                .scaleEffect(0.42 + 0.58 * u)
        }
        .frame(width: side, height: side)
        .clipShape(Circle())
        .allowsHitTesting(false)
    }
}

private struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(MihrabColor.mint)
                .shadow(color: MihrabColor.mint.opacity(0.35), radius: 6)
            Text(label)
                .font(.caption)
                .foregroundStyle(MihrabColor.textTertiary)
        }
    }
}
