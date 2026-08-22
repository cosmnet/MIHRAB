import Charts
import SwiftData
import SwiftUI

struct DhikrStatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var sessions: [DhikrSession] = []
    @State private var showAchievements = false

    private var inscribedCount: Int {
        DhikrAchievements.snapshots(from: sessions).filter(\.unlocked).count
    }

    private var todayTotal: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return sessions.filter { $0.date >= today }
            .reduce(0) { $0 + $1.completedSets * max($1.target, 1) + $1.count }
    }

    private var weekTotal: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessions.filter { $0.date >= weekAgo }
            .reduce(0) { $0 + $1.completedSets * max($1.target, 1) + $1.count }
    }

    private var allTime: Int {
        sessions.reduce(0) { $0 + $1.completedSets * max($1.target, 1) + $1.count }
    }

    private var streak: Int {
        let calendar = Calendar.current
        var days = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        var count = 0
        var cursor = calendar.startOfDay(for: Date())
        while days.contains(cursor) {
            count += 1
            days.remove(cursor)
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        return count
    }

    private var weeklyBars: [(day: String, total: Int)] {
        let calendar = Calendar.current
        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
            let total = sessions.filter { $0.date >= start && $0.date < end }
                .reduce(0) { $0 + $1.completedSets * max($1.target, 1) + $1.count }
            return (date.formatted(.dateTime.weekday(.narrow)), total)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            StatCard(title: L10n.today, value: todayTotal)
                            StatCard(title: L10n.statsWeek, value: weekTotal)
                        }
                        HStack(spacing: 12) {
                            StatCard(title: L10n.statsAllTime, value: allTime)
                            StatCard(title: L10n.statsStreak, value: streak, suffix: L10n.dayUnit)
                        }

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

                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.thisWeek)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MihrabColor.brass)
                            Chart(weeklyBars, id: \.day) { bar in
                                BarMark(x: .value("Day", bar.day), y: .value("Count", bar.total))
                                    .foregroundStyle(
                                        LinearGradient(colors: [MihrabColor.emerald, MihrabColor.mint],
                                                       startPoint: .bottom, endPoint: .top)
                                    )
                                    .cornerRadius(6)
                            }
                            .frame(height: 180)
                            .chartYAxis {
                                AxisMarks { _ in
                                    AxisValueLabel()
                                        .foregroundStyle(MihrabColor.textTertiary)
                                }
                            }
                            .chartXAxis {
                                AxisMarks { _ in
                                    AxisValueLabel()
                                        .foregroundStyle(MihrabColor.textSecondary)
                                }
                            }
                        }
                        .padding(20)
                        .mihrabCard()
                    }
                    .padding()
                }
                .scrollEdgeEffectStyle(.soft, for: .top)
            }
            .navigationTitle(L10n.dhikrStats)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.done) { dismiss() }
                }
            }
        }
        .presentationBackground(.ultraThinMaterial)
        .sheet(isPresented: $showAchievements) { DhikrAchievementSheet() }
        .task { load() }
    }

    private func load() {
        sessions = (try? modelContext.fetch(FetchDescriptor<DhikrSession>())) ?? []
    }
}

private struct StatCard: View {
    let title: String
    let value: Int
    var suffix: String? = nil

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(MihrabColor.brass)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(value)")
                    .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(MihrabColor.mint)
                if let suffix {
                    Text(suffix)
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .mihrabCard(cornerRadius: 22)
    }
}
