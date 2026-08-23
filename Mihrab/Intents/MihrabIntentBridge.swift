import AppIntents
import CoreSpotlight
import Foundation
import WidgetKit

/// The app side of the App Intents layer: keeps Spotlight fresh, publishes the
/// lists the widget extension cannot compute for itself, and hands back
/// whatever an intent asked the app to open.
///
/// One call at launch (`refresh()`) and one per foreground
/// (`consumePendingNavigation()` / `consumePendingDhikrSession()`) is the whole
/// contract.
enum MihrabIntentBridge {

    /// Call once per launch, and again after the schedule or city list changes.
    @MainActor
    static func refresh() async {
        publishDhikrDirectory()
        await MihrabAppShortcuts.updateAppShortcutParameters()
        await indexPrayersForSpotlight()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Spotlight

    /// Puts today's prayers into Spotlight so "İkindi" finds Mihrab.
    ///
    /// Re-indexing is cheap and idempotent: the same six stable ids are
    /// overwritten with the current day's times.
    static func indexPrayersForSpotlight() async {
        do {
            let entities = try await PrayerEntity.defaultQuery.allEntities()
            guard !entities.isEmpty else { return }
            try await CSSearchableIndex.default().indexAppEntities(entities)
        } catch {
            // Spotlight is a nicety; never let it break a launch.
        }
    }

    // MARK: - Shared directories

    /// Mirrors the dhikr catalogue (built-ins + user-made) into the App Group so
    /// Siri and the widget can offer the same phrases the app shows.
    @MainActor
    static func publishDhikrDirectory() {
        let items = DhikrStore.shared.allItems
        let entries = items.map {
            SharedDhikrDirectory.Entry(id: $0.id, name: $0.localizedName, target: $0.target)
        }
        SharedDhikrDirectory.publish(entries)
    }

    /// Publishes today's dhikr total so the widget and the Control Center tile
    /// agree with the counter on screen.
    static func publishDhikrTotal(_ total: Int, phraseID: String? = nil) {
        SharedDhikrCounter.publishAppTotal(total, phraseID: phraseID)
    }

    /// Taps made outside the app (widget button, Siri, Control Center) that have
    /// not been folded into the SwiftData session yet. Clears the queue.
    static func drainOutsideTaps() -> Int {
        SharedDhikrCounter.drainPending()
    }

    // MARK: - Navigation hand-off

    /// The tab an intent asked for, if any. Reading it clears it.
    static func consumePendingNavigation() -> AppTab? {
        switch MihrabDeepLink.consumeTab() {
        case .today: .today
        case .times: .times
        case .qibla: .qibla
        case .deen: .deen
        case .dhikr: .dhikr
        case nil: nil
        }
    }

    /// The dhikr phrase (and target) `StartDhikrSessionIntent` asked for.
    /// Reading it clears it.
    @MainActor
    static func consumePendingDhikrSession() -> (item: DhikrItem, target: Int)? {
        guard let request = MihrabDeepLink.consumeDhikrSession() else { return nil }
        guard let item = DhikrStore.shared.item(id: request.phraseID) else { return nil }
        return (item, request.target ?? item.target)
    }

    /// `mihrab://times` and friends, as emitted by `widgetURL(_:)`.
    static func tab(for url: URL) -> AppTab? {
        guard url.scheme == "mihrab" else { return nil }
        let host = url.host() ?? url.path().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return MihrabDeepLink.Tab(rawValue: host).map { tab -> AppTab in
            switch tab {
            case .today: .today
            case .times: .times
            case .qibla: .qibla
            case .deen: .deen
            case .dhikr: .dhikr
            }
        }
    }
}
