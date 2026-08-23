import AppIntents
import SwiftUI

/// Marks one of the five fard prayers as prayed for today.
///
/// App-target only: the streak lives in `PrayerLogStore` (standard
/// `UserDefaults`), which the widget extension cannot see. Running this from a
/// widget would silently write into the extension's own defaults, so the intent
/// simply does not exist there.
struct MarkPrayerPrayedIntent: AppIntent {

    static var title: LocalizedStringResource { "Mark Prayer as Prayed" }

    static var description: IntentDescription {
        IntentDescription("Marks one of the five daily prayers as prayed for today.")
    }

    static let supportedModes: IntentModes = .background

    static let isDiscoverable = true

    @Parameter(title: "Prayer")
    var prayer: PrayerEntity

    init() {}

    init(prayer: Prayer) {
        self.prayer = PrayerEntity(prayer: prayer)
    }

    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        guard let prayer = prayer.prayer, prayer.isNotifiable else {
            throw MihrabIntentError.missingPrayer
        }

        let store = PrayerLogStore.shared
        let total = PrayerLogStore.fardPrayers.count

        // `toggle` is the only writer the store exposes and it flips both ways —
        // guard so "mark as prayed" is idempotent and can never un-mark.
        if store.isLogged(prayer) {
            let done = store.completedCount()
            return .result(
                value: done,
                dialog: IntentDialog(.mihrab(L10n.intMarkPrayedAlready(prayer: prayer.localizedNamazName)))
            )
        }

        store.toggle(prayer)
        let done = store.completedCount()
        return .result(
            value: done,
            dialog: IntentDialog(.mihrab(L10n.intMarkPrayedAnswer(
                prayer: prayer.localizedNamazName,
                done: done,
                total: total
            )))
        )
    }
}
