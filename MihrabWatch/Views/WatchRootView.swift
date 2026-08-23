import SwiftUI

/// Four screens, vertically paged — the watchOS 10+ idiom, driven by the Digital
/// Crown as well as by swiping. Times is first because it is the reason the app
/// gets raised in the first place.
struct WatchRootView: View {

    @Environment(WatchAppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            WatchTimesView()
            WatchQiblaView()
            WatchDhikrView()
            WatchPrayerLogView()
        }
        .tabViewStyle(.verticalPage)
        .task { model.onAppear() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                model.refresh()
            case .inactive, .background:
                model.flushDhikr()
            @unknown default:
                break
            }
        }
    }
}
