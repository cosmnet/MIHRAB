import ActivityKit
import SwiftUI
import WidgetKit

struct PrayerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerActivityAttributes.self) { context in
            // Lock Screen / StandBy presentation
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.state.prayerName)
                        .font(.headline)
                    Text(context.state.prayerArabic)
                        .font(.subheadline)
                        .foregroundStyle(MihrabColor.textSecondary)
                }
                Spacer()
                if let range = SafeCountdown.range(from: Date(), to: context.state.prayerTime) {
                    Text(timerInterval: range, countsDown: true)
                        .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(MihrabColor.mint)
                }
            }
            .padding()
            .activityBackgroundTint(MihrabColor.abyss)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.prayerName, systemImage: "moon.fill")
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let range = SafeCountdown.range(from: Date(), to: context.state.prayerTime) {
                        Text(timerInterval: range, countsDown: true)
                            .font(.caption.monospacedDigit())
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.prayerArabic)
                        .font(.caption)
                        .foregroundStyle(MihrabColor.brass)
                }
            } compactLeading: {
                Image(systemName: "moon.fill")
                    .foregroundStyle(MihrabColor.emerald)
            }             compactTrailing: {
                if let range = SafeCountdown.range(from: Date(), to: context.state.prayerTime) {
                    Text(timerInterval: range, countsDown: true)
                        .font(.caption2.monospacedDigit())
                }
            } minimal: {
                Image(systemName: "moon.fill")
                    .foregroundStyle(MihrabColor.emerald)
            }
        }
    }
}
