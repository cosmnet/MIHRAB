import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct PrayerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerActivityAttributes.self) { context in
            PrayerActivityLockScreenView(context: context)
                .activityBackgroundTint(MihrabColor.abyss)
                .activitySystemActionForegroundColor(MihrabColor.mint)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Label(context.state.prayerName, systemImage: "moon.stars.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MihrabColor.mint)
                        Text(context.attributes.cityName)
                            .font(.caption2)
                            .foregroundStyle(MihrabColor.textSecondary)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.prayerTime, format: .dateTime.hour().minute())
                            .font(.title3.bold().monospacedDigit())
                            .foregroundStyle(MihrabColor.mint)
                        Text(context.state.prayerArabic)
                            .font(.caption2)
                            .foregroundStyle(MihrabColor.brass)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // The countdown gets the full width instead of being squeezed
                    // into the trailing slot — it is the only thing the user is
                    // actually looking at.
                    HStack {
                        CountdownText(to: context.state.prayerTime)
                            .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(MihrabColor.textPrimary)
                        Spacer()
                        Link(destination: MihrabDeepLink.url(for: .times) ?? URL(string: "mihrab://times")!) {
                            Label(L10n.tabTimes, systemImage: "clock.fill")
                                .font(.caption2)
                                .labelStyle(.titleAndIcon)
                        }
                        .foregroundStyle(MihrabColor.brass)
                    }
                    .accessibilityElement(children: .combine)
                }
            } compactLeading: {
                Image(systemName: "moon.stars.fill")
                    .foregroundStyle(MihrabColor.emerald)
            } compactTrailing: {
                CountdownText(to: context.state.prayerTime)
                    .font(.caption2.monospacedDigit())
                    .frame(maxWidth: 44)
                    .foregroundStyle(MihrabColor.mint)
            } minimal: {
                Image(systemName: "moon.stars.fill")
                    .foregroundStyle(MihrabColor.emerald)
            }
            .widgetURL(MihrabDeepLink.url(for: .times))
            .keylineTint(MihrabColor.emerald)
        }
        // Costs one line and puts Mihrab in the Apple Watch Smart Stack and in
        // CarPlay without a watchOS target existing at all.
        .supplementalActivityFamilies([.small])
    }
}

/// Lock Screen, StandBy, Smart Stack and CarPlay all render this. The `.small`
/// family is a watch complication-sized strip, so the layout branches instead
/// of shrinking.
struct PrayerActivityLockScreenView: View {
    let context: ActivityViewContext<PrayerActivityAttributes>

    @Environment(\.activityFamily) private var activityFamily
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var body: some View {
        switch activityFamily {
        case .small: smallView
        case .medium: mediumView
        @unknown default: mediumView
        }
    }

    /// Apple Watch Smart Stack / CarPlay: one line of name, one of countdown.
    private var smallView: some View {
        HStack(spacing: 8) {
            Image(systemName: "moon.stars.fill")
                .foregroundStyle(MihrabColor.emerald)
            VStack(alignment: .leading, spacing: 0) {
                Text(context.state.prayerName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                CountdownText(to: context.state.prayerTime)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(MihrabColor.mint)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private var mediumView: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.prayerName)
                    .font(.headline)
                Text(context.state.prayerArabic)
                    .font(.subheadline)
                    .foregroundStyle(MihrabColor.brass)
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption2)
                    Text(context.attributes.cityName)
                        .font(.caption)
                }
                .foregroundStyle(MihrabColor.textSecondary)
                .lineLimit(1)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 2) {
                CountdownText(to: context.state.prayerTime)
                    .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(MihrabColor.mint)
                    // Always-On display: dim the loudest element rather than the text.
                    .opacity(isLuminanceReduced ? 0.75 : 1)
                Text(context.state.prayerTime, format: .dateTime.hour().minute())
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(MihrabColor.textSecondary)
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(context.state.prayerName) \(MihrabIntentData.clock(context.state.prayerTime))")
    }
}
