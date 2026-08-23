import BackgroundTasks
import Foundation
import WidgetKit

/// Keeps prayer times, the App Group snapshot and the widget timelines warm
/// while the app is not running.
///
/// Two identifiers, both already declared in `Info.plist` under
/// `BGTaskSchedulerPermittedIdentifiers`:
///   - `…refresh` (app refresh) — short, frequent, best-effort top-up.
///   - `…maintenance` (processing) — longer, once a day, rebuilds the month.
///
/// Registration **must** happen before the app finishes launching, so
/// `registerHandlers()` is called from `MihrabApp.init()`.
enum BackgroundRefresh {
    static let refreshTaskID = "com.caferkarakaya.mihrab.refresh"
    static let maintenanceTaskID = "com.caferkarakaya.mihrab.maintenance"

    /// Roughly hourly; iOS decides the real cadence from usage patterns.
    private static let refreshInterval: TimeInterval = 60 * 60
    /// Once a day is enough — a month of times does not change under us.
    private static let maintenanceInterval: TimeInterval = 24 * 60 * 60

    private static let lastMaintenanceKey = "background.lastMaintenance"

    /// Single line to add to `MihrabApp.init()`:
    /// `BackgroundRefresh.registerHandlers()`
    ///
    /// Registering twice for the same identifier traps, so this is idempotent.
    static func registerHandlers() {
        guard !hasRegistered else { return }
        hasRegistered = true

        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshTaskID, using: nil) { task in
            handleRefresh(task)
        }
        BGTaskScheduler.shared.register(forTaskWithIdentifier: maintenanceTaskID, using: nil) { task in
            handleMaintenance(task)
        }
    }

    private nonisolated(unsafe) static var hasRegistered = false

    /// Call when the app goes to the background (and after each task runs).
    static func scheduleAll() {
        schedule(refreshTaskID, earliestAfter: refreshInterval, processing: false)
        schedule(maintenanceTaskID, earliestAfter: maintenanceInterval, processing: true)
    }

    static func cancelAll() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }

    // MARK: - Handlers

    private static func handleRefresh(_ bgTask: BGTask) {
        // BGTask is not Sendable, but `setTaskCompleted` is safe from any
        // thread and both closures below run serially against this one task.
        nonisolated(unsafe) let task = bgTask
        // Always queue the successor first: an early return must not end the chain.
        schedule(refreshTaskID, earliestAfter: refreshInterval, processing: false)

        let work = Task { @MainActor in
            await PrayerTimesRepository.shared.refreshIfNeeded()
            WidgetCenter.shared.reloadAllTimelines()
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = {
            work.cancel()
            task.setTaskCompleted(success: false)
        }
    }

    private static func handleMaintenance(_ bgTask: BGTask) {
        // BGTask is not Sendable, but `setTaskCompleted` is safe from any
        // thread and both closures below run serially against this one task.
        nonisolated(unsafe) let task = bgTask
        schedule(maintenanceTaskID, earliestAfter: maintenanceInterval, processing: true)

        let work = Task { @MainActor in
            // Once a day: full refresh (engine window + network month) and a
            // fresh snapshot for the widgets.
            await PrayerTimesRepository.shared.refresh()
            UserDefaults.standard.set(Date(), forKey: lastMaintenanceKey)
            WidgetCenter.shared.reloadAllTimelines()
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = {
            work.cancel()
            task.setTaskCompleted(success: false)
        }
    }

    /// `true` when maintenance has not run in over a day — the app can then do
    /// it in the foreground instead of waiting for iOS to grant a slot.
    static var maintenanceIsOverdue: Bool {
        guard let last = UserDefaults.standard.object(forKey: lastMaintenanceKey) as? Date else { return true }
        return Date().timeIntervalSince(last) > maintenanceInterval
    }

    // MARK: - Scheduling

    private static func schedule(_ identifier: String,
                                 earliestAfter interval: TimeInterval,
                                 processing: Bool) {
        let request: BGTaskRequest
        if processing {
            let processingRequest = BGProcessingTaskRequest(identifier: identifier)
            // Prayer times are pure arithmetic plus one small JSON request:
            // no need to demand power, and network is nice-to-have only.
            processingRequest.requiresNetworkConnectivity = true
            processingRequest.requiresExternalPower = false
            request = processingRequest
        } else {
            request = BGAppRefreshTaskRequest(identifier: identifier)
        }
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Simulator and "too many pending requests" both land here.
            // Non-fatal: the foreground refresh path still keeps data current.
        }
    }
}
