import SwiftUI
import WidgetKit

@main
struct MihrabWidgetsBundle: WidgetBundle {

    /// `WidgetBundleBuilder` only has `buildBlock` overloads up to ten members,
    /// and Mihrab ships more than that — so the bundle is assembled from three
    /// builder properties instead of one flat list.
    @WidgetBundleBuilder
    var body: some Widget {
        homeScreenWidgets
        lockScreenWidgets
        controlsAndActivities
    }

    @WidgetBundleBuilder
    var homeScreenWidgets: some Widget {
        PrayerTimesWidget()
        CityPrayerWidget()
        DhikrCounterWidget()
        RamadanCountdownWidget()
    }

    @WidgetBundleBuilder
    var lockScreenWidgets: some Widget {
        LockScreenCircularWidget()
        LockScreenRectangularWidget()
        LockScreenInlineWidget()
    }

    @WidgetBundleBuilder
    var controlsAndActivities: some Widget {
        // Control Center / Lock Screen / Action Button
        QiblaControl()
        DhikrCountControl()
        NextPrayerControl()

        // Live Activities
        PrayerLiveActivity()

        // AlarmKit's alarm presentation — see AlarmLiveActivity.swift for the
        // two project changes that switch this on once W2's metadata type lands.
        #if MIHRAB_ALARMKIT
        AdhanAlarmLiveActivity()
        #endif
    }
}
