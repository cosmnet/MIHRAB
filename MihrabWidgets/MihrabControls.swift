import AppIntents
import SwiftUI
import WidgetKit

/// Control Center / Lock Screen / Action Button tiles.
///
/// There is no `ControlWidgetFamily`: a control is authored once and the
/// templates lay themselves out at every size the system offers, so the only
/// job here is to keep the label short and the symbol legible at 20pt.

// MARK: - Qibla

struct QiblaControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.caferkarakaya.mihrab.control.qibla") {
            ControlWidgetButton(action: OpenMihrabIntent(tab: .qibla)) {
                Label(L10n.wgtControlQiblaName, systemImage: "location.north.circle.fill")
            }
        }
        .displayName("Qibla")
        .description("Opens the Qibla compass.")
    }
}

// MARK: - Dhikr

/// The one control that does real work in place: a tap adds to today's count
/// and never opens the app.
struct DhikrCountControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: ControlCenterRefresh.dhikrControlKind,
            provider: DhikrCountProvider()
        ) { count in
            ControlWidgetButton(action: AddDhikrIntent(amount: 1)) {
                Label("\(count)", systemImage: "circle.grid.3x3.fill")
                Text(L10n.intDhikrTodayCaption)
            }
        }
        .displayName("Count Dhikr")
        .description("One tap adds one to today's dhikr count.")
    }
}

struct DhikrCountProvider: ControlValueProvider {
    let previewValue = 33

    func currentValue() async throws -> Int {
        SharedDhikrCounter.todayCount
    }
}

// MARK: - Next prayer

struct NextPrayerControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: ControlCenterRefresh.nextPrayerControlKind,
            provider: NextPrayerControlProvider()
        ) { value in
            ControlWidgetButton(action: OpenMihrabIntent(tab: .times)) {
                Label(value.title, systemImage: value.symbol)
                Text(value.subtitle)
            }
        }
        .displayName("Next Prayer")
        .description("Shows the next prayer and opens the schedule.")
    }
}

struct NextPrayerControlValue: Equatable, Sendable {
    var title: String
    var subtitle: String
    var symbol: String
}

struct NextPrayerControlProvider: ControlValueProvider {
    var previewValue: NextPrayerControlValue {
        NextPrayerControlValue(
            title: Prayer.asr.localizedNamazName,
            subtitle: "16:42",
            symbol: Prayer.asr.symbolName
        )
    }

    func currentValue() async throws -> NextPrayerControlValue {
        guard let next = MihrabIntentData.nextPrayer() else {
            return NextPrayerControlValue(
                title: "Revak",
                subtitle: L10n.wgtOpenAppHint,
                symbol: "moon.fill"
            )
        }
        return NextPrayerControlValue(
            title: next.prayer.localizedNamazName,
            subtitle: MihrabIntentData.clock(next.date),
            symbol: next.prayer.symbolName
        )
    }
}
