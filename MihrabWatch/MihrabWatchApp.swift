import SwiftUI
import WatchKit

/// watchOS 7+ single-target architecture: one `App`, one `WindowGroup`, and
/// `@WKApplicationDelegateAdaptor` for the few lifecycle hooks SwiftUI does not
/// expose. The old `WKExtensionDelegate` / separate WatchKit extension pair is
/// deprecated and is not used anywhere here.
@main
struct MihrabWatchApp: App {

    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var delegate

    @State private var model = WatchAppModel.shared

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(model)
        }
    }
}

/// Lifecycle only. Note what is deliberately absent: no
/// `WKExtendedRuntimeSession`.
///
/// An extended runtime session keeps the app alive with the screen off and is
/// meant for workouts, mindfulness and physical therapy. A prayer-time app has
/// no reason to hold one: the reminder at prayer time is a *local notification*
/// scheduled ahead of time (and the iPhone's notifications already mirror to the
/// wrist), and the complication is a WidgetKit timeline the system refreshes on
/// its own. Both work with the app fully suspended. Taking a runtime session
/// here would drain the battery, and Apple would rightly reject it.
final class WatchAppDelegate: NSObject, WKApplicationDelegate {

    func applicationDidFinishLaunching() {
        // Activating early means a settings context pushed while the app was
        // not running is picked up on the first frame instead of after it.
        WatchConnectivityClient.shared.activate()
    }

    func applicationDidBecomeActive() {
        WatchConnectivityClient.shared.activate()
        Task { @MainActor in
            WatchAppModel.shared.refresh()
        }
    }

    func applicationWillResignActive() {
        // Last chance to hand counted dhikr to the phone before suspension.
        WatchConnectivityClient.shared.flush()
    }

    /// Background refresh, scheduled by the system. Nothing to fetch — the watch
    /// computes its own times — so this only drains the outbox and returns.
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            if task is WKApplicationRefreshBackgroundTask {
                WatchConnectivityClient.shared.flush()
            }
            task.setTaskCompletedWithSnapshot(false)
        }
    }
}
