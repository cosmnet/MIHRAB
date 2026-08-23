import Foundation
import SwiftData

// MARK: - CloudKit schema rules (read before touching a model below)
//
// These models back an **iCloud-synced** store (`Persistence.container`), so the
// SwiftData ↔︎ CloudKit rules apply. Break one and sync does not fail loudly —
// it silently never starts:
//
//   1. `@Attribute(.unique)` / `#Unique` are forbidden.
//   2. Every relationship must be **optional** and must have an **inverse**.
//   3. The `.deny` delete rule is unsupported.
//   4. Every property must be optional *or* carry a default value.
//   5. `@Attribute(.allowsCloudEncryption)` is the only CloudKit-specific
//      attribute in play; we do not use it (nothing here is sensitive).
//
// ✅ Verified for the three models below: none declares `.unique`, none has a
// relationship at all (so rules 2 and 3 are vacuously satisfied), and every
// stored property has a default value. No changes were needed to make them
// CloudKit-compatible — this comment records the audit.
//
// ⚠️ **Once the CloudKit schema is deployed to Production it can only be
// changed additively.** New optional/defaulted properties and new record types
// are fine; renaming a property, changing its type, making it required, or
// deleting it is NOT. Plan migrations as "add new, backfill, stop reading old".

/// Crash-safe dhikr persistence (§4.8). Synced via CloudKit when the user has
/// Mihrab Plus and has turned iCloud sync on.
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

// MARK: - Container

enum Persistence {
    /// Must match the `com.apple.developer.icloud-container-identifiers`
    /// entitlement. Changing it orphans every synced record.
    static let cloudKitContainerID = "iCloud.com.caferkarakaya.mihrab"

    static let schema = Schema([DhikrSession.self, FavoriteHadith.self, KhatamProgress.self])

    /// Resolved once, at launch. Toggling sync in Settings therefore takes
    /// effect on the next launch — `SyncSettingsSection` says so out loud
    /// rather than pretending the switch is instant.
    nonisolated(unsafe) static private(set) var isUsingCloudKit = false

    static let container: ModelContainer = {
        let wantsCloud = CloudSyncPreference.isEnabled && CloudSyncPreference.isEntitled

        if wantsCloud {
            let cloud = ModelConfiguration(
                schema: schema,
                // `private` is a Swift keyword — the backticks are required.
                cloudKitDatabase: .`private`(cloudKitContainerID)
            )
            if let container = try? ModelContainer(for: schema, configurations: [cloud]) {
                isUsingCloudKit = true
                return container
            }
            // Falling through is deliberate: a missing iCloud account or a
            // container mismatch must never cost the user their local data.
        }

        // Local-only store. Turning sync *off* uses `.none`, which keeps the
        // very same on-disk file — nothing is deleted, sync just stops.
        let local = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        if let container = try? ModelContainer(for: schema, configurations: [local]) {
            return container
        }

        let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [memory])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    #if DEBUG
    /// Development-only schema priming.
    ///
    /// CloudKit only learns about a record type once a record of that type has
    /// been pushed from a **development** container. Running this once against
    /// a signed-in dev build creates every record type, after which you can hit
    /// "Deploy Schema Changes" in the CloudKit console.
    ///
    /// ⚠️ Never call this from a Release build, and never against Production:
    /// **a deployed schema can only be extended, never rewritten.**
    @MainActor
    static func primeCloudKitSchemaForDevelopment() throws {
        guard isUsingCloudKit else { return }
        let context = ModelContext(container)
        let probe = DhikrSession(dhikrID: "schema-probe", arabic: "", transliteration: "", target: 1)
        let hadith = FavoriteHadith(hadithID: "schema-probe")
        let khatam = KhatamProgress()
        context.insert(probe)
        context.insert(hadith)
        context.insert(khatam)
        try context.save()
        // Leave them in place long enough to be pushed, then clean up by hand
        // from the console — deleting immediately can race the export.
    }
    #endif
}
