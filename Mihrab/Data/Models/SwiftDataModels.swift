import Foundation
import SwiftData

/// Crash-safe dhikr persistence (§4.8). Synced via CloudKit when available.
@Model
final class DhikrSession {
    var id: UUID = UUID()
    var dhikrID: String = ""
    var arabic: String = ""
    var transliteration: String = ""
    var count: Int = 0
    var target: Int = 33
    var completedSets: Int = 0
    var date: Date = Date()

    init(dhikrID: String, arabic: String, transliteration: String, target: Int) {
        self.dhikrID = dhikrID
        self.arabic = arabic
        self.transliteration = transliteration
        self.target = target
    }

    /// Completed sets plus leftover taps. Not persisted — derived for stats and rewards.
    var recited: Int { completedSets * max(target, 1) + count }
}

@Model
final class FavoriteHadith {
    var hadithID: String = ""
    var savedAt: Date = Date()

    init(hadithID: String) {
        self.hadithID = hadithID
    }
}

@Model
final class KhatamProgress {
    var completedJuz: Int = 0
    var updatedAt: Date = Date()

    init() {}
}

enum Persistence {
    static let container: ModelContainer = {
        let schema = Schema([DhikrSession.self, FavoriteHadith.self, KhatamProgress.self])
        if let container = try? ModelContainer(for: schema) {
            return container
        }
        let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [memory])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
