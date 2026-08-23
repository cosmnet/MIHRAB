import AppIntents
import SwiftUI

// MARK: - Count

/// Adds to today's dhikr count from Siri, a Shortcut, the Action Button, a
/// Control Center button, or a tap inside the widget.
///
/// Deliberately an `AppIntent` and not a `SetValueIntent`: the user is adding
/// to a tally, not setting it, and "say 33" must never silently overwrite the
/// 200 already counted today.
struct AddDhikrIntent: AppIntent {

    static var title: LocalizedStringResource { "Count Dhikr" }

    static var description: IntentDescription {
        IntentDescription("Adds to today's dhikr count without opening the app.")
    }

    /// Pure background work — counting must never steal the screen.
    static let supportedModes: IntentModes = .background

    static let isDiscoverable = true

    @Parameter(title: "How many", default: 1, inclusiveRange: (1, 1000))
    var amount: Int

    init() {}

    init(amount: Int) {
        self.amount = amount
    }

    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        let total = SharedDhikrCounter.add(amount)
        return .result(
            value: total,
            dialog: IntentDialog(.mihrab(L10n.intAddDhikrAnswer(added: amount, total: total)))
        )
    }
}

// MARK: - Start a session

/// Opens the counter already loaded with a chosen phrase.
///
/// The phrase is parked in the App Group and the app picks it up on the next
/// foreground pass — an `OpenIntent` alone cannot carry state across processes.
struct StartDhikrSessionIntent: AppIntent {

    static var title: LocalizedStringResource { "Start Dhikr Session" }

    static var description: IntentDescription {
        IntentDescription("Opens the counter on a chosen phrase.")
    }

    static let openAppWhenRun = true

    static let isDiscoverable = true

    @Parameter(title: "Dhikr")
    var phrase: DhikrPhraseEntity

    @Parameter(title: "Target count")
    var target: Int?

    init() {}

    init(phrase: DhikrPhraseEntity, target: Int? = nil) {
        self.phrase = phrase
        self.target = target
    }

    func perform() async throws -> some IntentResult {
        MihrabDeepLink.requestDhikrSession(phraseID: phrase.id, target: target ?? phrase.target)
        SharedDhikrCounter.phraseID = phrase.id
        return .result()
    }
}

// MARK: - Open the app

/// The one intent that just moves the user somewhere in Mihrab.
///
/// `OpenIntent` gives Shortcuts and Spotlight the right affordance ("Open …")
/// instead of a generic run-this-action row.
struct OpenMihrabIntent: AppIntent, OpenIntent {

    static var title: LocalizedStringResource { "Open Mihrab" }

    static var description: IntentDescription {
        IntentDescription("Opens Mihrab on a chosen screen.")
    }

    static let openAppWhenRun = true

    static let isDiscoverable = true

    @Parameter(title: "Screen")
    var target: MihrabScreenEntity

    init() {}

    init(tab: MihrabDeepLink.Tab) {
        self.target = MihrabScreenEntity(tab)
    }

    func perform() async throws -> some IntentResult {
        if let tab = target.tab { MihrabDeepLink.requestTab(tab) }
        return .result()
    }
}
