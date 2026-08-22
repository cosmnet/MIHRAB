import SwiftUI
import WidgetKit

@main
struct MihrabWidgetsBundle: WidgetBundle {
    var body: some Widget {
        PrayerTimesWidget()
        LockScreenCircularWidget()
        LockScreenRectangularWidget()
        LockScreenInlineWidget()
        PrayerLiveActivity()
    }
}
