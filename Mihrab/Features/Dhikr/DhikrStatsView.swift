import Charts
import SwiftData
import SwiftUI

/// Where the counting turns into a habit you can see: today, the week, the
/// streak, the phrases you actually reach for, and — for Plus — a month of
/// history.
struct DhikrStatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(Theme.self) private var theme
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var sessions: [DhikrSession] = []
    @State private var showAchievements = false
    @State private var showPaywall = false
    @State private var appeared = false

    private var accent: Color { theme.accent }
    private var isPremium: Bool { SubscriptionManager.shared.hasAccess(to: .dhikrFullHistory) }
    private let calendar = Calendar.current

    // MARK: - Aggregates

    private var totalsByDay: [Date: Int] {
        DhikrSessionMetrics.totalsByDay(sessions, calendar: calendar)
    }

    private var todayTotal: Int {
        totalsByDay[calendar.startOfDay(for: Date())] ?? 0
    }

    private var weekTotal: Int {
        dayTotals(lastDays: 7).reduce(0) { $0 + $1.total }
    }

    private var allTime: Int { DhikrSessionMetrics.allTime(sessions) }

    private var streak: Int {
        DhikrSessionMetrics.streak(sessions, now: .now, calendar: calendar)
    }

    private var bestDay: Int { DhikrSessionMetrics.bestDay(sessions, calendar: calendar) }

    private var dailyAverage: Int {
        let active = totalsByDay.values.filter { $0 > 0 }
        guard !active.isEmpty else { return 0 }
        return active.reduce(0, +) / active.count
    }

    private var inscribedCount: Int {
        DhikrAchievements.snapshots(from: sessions).filter(\.unlocked).count
    }

    private struct DayTotal: Identifiable {
        let id: Date
        let label: String
        let total: Int
    }

    private func dayTotals(lastDays days: Int) -> [DayTotal] {
        let map = totalsByDay
        return (0..<days).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let start = calendar.startOfDay(for: date)
            return DayTotal(
                id: start,
                label: date.formatted(.dateTime.weekday(.narrow).locale(L10n.appLocale)),
                total: map[start] ?? 0
            )
        }
    }

    private struct PhraseTotal: Identifiable {
        let id: String
        let name: String
        let total: Int
    }

    private var phraseTotals: [PhraseTotal] {
        var map: [String: Int] = [:]
        for session in sessions where session.recited > 0 {
            map[session.dhikrID, default: 0] += session.recited
        }
        return map
            .map { PhraseTotal(id: $0.key, name: L10n.dhkPhraseName($0.key), total: $0.value) }
            .sorted { $0.total > $1.total }
            .prefix(5)
            .map { $0 }
    }

    private var hasData: Bool { allTime > 0 }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                MihrabBackdrop(surface: .sheet, ramadanMode: theme.isRamadanMode)

                ScrollView {
                    VStack(spacing: 16) {
                        if hasData {
                            statGrid
                            goalCard.cardEntrance(index: 1, appeared: appeared, reduceMotion: reduceMotion)
                            achievementsRow.cardEntrance(index: 2, appeared: appeared, reduceMotion: reduceMotion)
                            weekChart.cardEntrance(index: 3, appeared: appeared, reduceMotion: reduceMotion)
                            phraseBreakdown.cardEntrance(index: 4, appeared: appeared, reduceMotion: reduceMotion)
                            historyCard.cardEntrance(index: 5, appeared: appeared, reduceMotion: reduceMotion)
                        } else {
                            MihrabEmptyState(
                                symbol: "circle.hexagongrid",
                                title: L10n.dhkNoData,
                                message: L10n.dhkNoDataBody
                            )
                            .padding(.top, 60)
                        }
                    }
                    .padding()
                    .padding(.bottom, 24)
                }
                .scrollEdgeEffectStyle(.soft, for: .top)
            }
            .navigationTitle(L10n.dhikrStats)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.done) { dismiss() }
                        .foregroundStyle(MihrabColor.textPrimary)
                }
            }
            .tint(accent)
        }
        .presentationBackground(.ultraThinMaterial)
        .sheet(isPresented: $showAchievements) { DhikrAchievementSheet() }
        .sheet(isPresented: $showPaywall) { PaywallView(source: .feature) }
        .task {
            load()
            withAnimation { appeared = true }
        }
    }

    // MARK: - Pieces

    private var statGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(title: L10n.today, value: todayTotal, accent: accent)
                    .cardEntrance(index: 0, appeared: appeared, reduceMotion: reduceMotion)
                StatCard(title: L10n.statsWeek, value: weekTotal, accent: accent)
                    .cardEntrance(index: 0, appeared: appeared, reduceMotion: reduceMotion)
            }
            HStack(spacing: 12) {
                StatCard(title: L10n.statsAllTime, value: allTime, accent: accent)
                    .cardEntrance(index: 1, appeared: appeared, reduceMotion: reduceMotion)
                StatCard(title: L10n.statsStreak, value: streak, suffix: L10n.dayUnit,
                         accent: MihrabColor.brass, symbol: "flame.fill")
                    .cardEntrance(index: 1, appeared: appeared, reduceMotion: reduceMotion)
            }
            HStack(spacing: 12) {
                StatCard(title: L10n.dhkBestDay, value: bestDay, accent: accent)
                    .cardEntrance(index: 2, appeared: appeared, reduceMotion: reduceMotion)
                StatCard(title: L10n.dhkAverage, value: dailyAverage, accent: accent)
                    .cardEntrance(index: 2, appeared: appeared, reduceMotion: reduceMotion)
            }
        }
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.dhkGoalToday).ornamentalCaps()
            DhikrGoalBar(
                todayTotal: todayTotal,
                goal: settings.dailyDhikrGoal,
                streak: streak,
                accent: accent
            )
        }
        .padding(18)
        .mihrabCard()
    }

    private var achievementsRow: some View {
        Button { showAchievements = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "seal.fill")
                    .font(.title3)
                    .foregroundStyle(MihrabColor.brass)
                    .symbolRenderingMode(.hierarchical)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.achievements)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MihrabColor.textPrimary)
                    Text(L10n.achievementsInscribed(inscribedCount, DhikrAchievementID.allCases.count))
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MihrabColor.textTertiary)
            }
            .padding(18)
            .mihrabCard(interactive: true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(L10n.achievements))
    }

    private var weekChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.thisWeek).ornamentalCaps()
            Chart {
                ForEach(dayTotals(lastDays: 7)) { bar in
                    BarMark(
                        x: .value("Day", bar.label),
                        y: .value("Count", bar.total)
                    )
                    .foregroundStyle(
                        LinearGradient(colors: [accent, MihrabColor.mint], startPoint: .bottom, endPoint: .top)
                    )
                    .cornerRadius(6)
                }
                RuleMark(y: .value("Goal", settings.dailyDhikrGoal))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(MihrabColor.brass.opacity(0.6))
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel().foregroundStyle(MihrabColor.textTertiary)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel().foregroundStyle(MihrabColor.textSecondary)
                }
            }
            .accessibilityLabel(Text(L10n.thisWeek))
        }
        .padding(20)
        .mihrabCard()
    }

    private var phraseBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.dhkByPhrase).ornamentalCaps()
            let rows = phraseTotals
            let peak = max(rows.first?.total ?? 1, 1)
            ForEach(rows) { row in
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(row.name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MihrabColor.textPrimary)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text("\(row.total)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(MihrabColor.textTertiary)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(MihrabColor.abyss.opacity(0.4))
                            Capsule()
                                .fill(
                                    LinearGradient(colors: [accent, MihrabColor.mint],
                                                   startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(width: max(4, geo.size.width * Double(row.total) / Double(peak)))
                        }
                    }
                    .frame(height: 6)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(20)
        .mihrabCard()
    }

    /// 30-day history — the one stat that is genuinely a "long game" feature,
    /// so it is where Mihrab Plus earns its keep.
    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.dhkHistory30).ornamentalCaps()
                Spacer()
                if !isPremium { PremiumLockBadge(compact: true) }
            }

            if isPremium {
                Chart {
                    ForEach(dayTotals(lastDays: 30)) { bar in
                        AreaMark(
                            x: .value("Day", bar.id),
                            y: .value("Count", bar.total)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accent.opacity(0.55), accent.opacity(0.04)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    ForEach(dayTotals(lastDays: 30)) { bar in
                        LineMark(
                            x: .value("Day", bar.id),
                            y: .value("Count", bar.total)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(MihrabColor.mint)
                    }
                }
                .frame(height: 160)
                .chartYAxis {
                    AxisMarks { _ in AxisValueLabel().foregroundStyle(MihrabColor.textTertiary) }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.narrow))
                            .foregroundStyle(MihrabColor.textSecondary)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.dhkPremiumHistoryTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MihrabColor.textPrimary)
                    lockedPreview
                    Button {
                        showPaywall = true
                    } label: {
                        Text(L10n.dhkUnlock)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: MihrabSpace.hit)
                            .foregroundStyle(MihrabColor.abyss)
                            .background { Capsule().fill(MihrabColor.brass) }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .mihrabCard()
    }

    /// A blurred silhouette of the real chart — shows what is behind the lock
    /// without pretending to be data.
    private var lockedPreview: some View {
        Chart(dayTotals(lastDays: 30)) { bar in
            BarMark(x: .value("Day", bar.id), y: .value("Count", bar.total))
                .foregroundStyle(MihrabColor.mint.opacity(0.5))
        }
        .frame(height: 96)
        .chartYAxis(.hidden)
        .chartXAxis(.hidden)
        .blur(radius: 6)
        .opacity(0.55)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func load() {
        sessions = (try? modelContext.fetch(FetchDescriptor<DhikrSession>())) ?? []
    }
}

private struct StatCard: View {
    let title: String
    let value: Int
    var suffix: String? = nil
    var accent: Color = MihrabColor.mint
    var symbol: String? = nil

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 5) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.caption2)
                        .foregroundStyle(MihrabColor.brass)
                }
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MihrabColor.brass)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(value)")
                    .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let suffix {
                    Text(suffix)
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .mihrabCard(cornerRadius: 22)
        .accessibilityElement(children: .combine)
    }
}
