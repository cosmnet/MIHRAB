import SwiftUI
import WidgetKit

// AlarmKit's `AlarmAttributes<Metadata>` is an `ActivityAttributes`, so the
// alarm's Lock Screen / Dynamic Island presentation has to be declared *here*,
// in the widget extension — not in the app where the alarm is scheduled.
//
// The generic parameter is Agent W2's metadata type, `MihrabAlarmMetadata`.
// Until that type exists and is compiled into this target the whole file would
// fail to build, so it is behind a flag. To turn it on, the main session must:
//
//   1. add `Mihrab/Core/Adhan` (or just W2's metadata file) to the
//      `MihrabWidgets` target `sources` in `project.yml`, and
//   2. add `MIHRAB_ALARMKIT` to `SWIFT_ACTIVE_COMPILATION_CONDITIONS` for both
//      the `Mihrab` and `MihrabWidgets` targets, and
//   3. add `AdhanAlarmLiveActivity()` to `MihrabWidgetsBundle`.
//
// Nothing below touches `metadata`'s fields — W2 owns those and they are not
// invented here.

#if MIHRAB_ALARMKIT
import AlarmKit
import ActivityKit

struct AdhanAlarmLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<MihrabAlarmMetadata>.self) { context in
            AlarmLockScreenView(
                title: context.attributes.presentation.alert.title,
                tint: context.attributes.tintColor,
                mode: context.state.mode
            )
            .activityBackgroundTint(MihrabColor.abyss)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundStyle(context.attributes.tintColor)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.presentation.alert.title)
                        .font(.headline)
                        .lineLimit(2)
                }
            } compactLeading: {
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundStyle(context.attributes.tintColor)
            } compactTrailing: {
                Image(systemName: "moon.stars.fill")
                    .foregroundStyle(MihrabColor.emerald)
            } minimal: {
                Image(systemName: "moon.stars.fill")
                    .foregroundStyle(MihrabColor.emerald)
            }
            .keylineTint(MihrabColor.emerald)
        }
        .supplementalActivityFamilies([.small])
    }
}

/// Presentation-only: AlarmKit draws its own stop/repeat buttons from the
/// `AlarmPresentation` W2 supplies, so this view must never add its own.
struct AlarmLockScreenView: View {
    let title: LocalizedStringResource
    let tint: Color
    let mode: AlarmPresentationState.Mode

    @Environment(\.activityFamily) private var activityFamily

    private var symbol: String {
        switch mode {
        case .countdown: "timer"
        case .paused: "pause.circle.fill"
        case .alert: "speaker.wave.3.fill"
        @unknown default: "moon.stars.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(activityFamily == .small ? .body : .title2)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(activityFamily == .small ? .caption.weight(.semibold) : .headline)
                    .lineLimit(2)
                if activityFamily != .small {
                    Text(L10n.wgtAlarmAdhanTitle)
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textSecondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
        .accessibilityElement(children: .combine)
    }
}
#endif
