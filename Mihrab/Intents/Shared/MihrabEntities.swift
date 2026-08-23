import AppIntents
import CoreSpotlight
import Foundation
import WidgetKit

// MARK: - Prayer

/// A single prayer of the current day, as Shortcuts and Spotlight see it.
///
/// `IndexedEntity` is what puts "İkindi" into Spotlight search results without
/// a second indexing model: the same entity that Shortcuts passes around is the
/// one Spotlight shows.
struct PrayerEntity: AppEntity, IndexedEntity, Identifiable, Sendable {

    /// `Prayer.rawValue` — stable across launches, which is what an entity id must be.
    var id: String
    var time: Date?

    var prayer: Prayer? { Prayer(rawValue: id) }

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Prayer")

    static let defaultQuery = PrayerEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        let name = prayer?.localizedNamazName ?? id
        let subtitle = time.map { MihrabIntentData.clock($0) } ?? "—"
        return DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: name),
            subtitle: LocalizedStringResource(stringLiteral: subtitle),
            image: prayer.map { .init(systemName: $0.symbolName) }
        )
    }

    /// What Spotlight stores. Kept to name + time; no location, no personal data.
    var attributeSet: CSSearchableItemAttributeSet {
        let set = CSSearchableItemAttributeSet(contentType: .content)
        set.title = prayer?.localizedNamazName ?? id
        set.contentDescription = time.map { MihrabIntentData.clock($0) }
        set.keywords = [prayer?.localizedName, prayer?.turkishName, prayer?.arabicName, prayer?.displayName]
            .compactMap { $0 }
        return set
    }

    init(id: String, time: Date? = nil) {
        self.id = id
        self.time = time
    }

    init(prayer: Prayer, time: Date? = nil) {
        self.init(id: prayer.rawValue, time: time)
    }

    /// Today's five fard prayers plus sunrise, times filled in from the cache.
    static func today() -> [PrayerEntity] {
        let day = MihrabIntentData.day()
        return Prayer.allCases.map { PrayerEntity(prayer: $0, time: day?.time(for: $0)) }
    }
}

struct PrayerEntityQuery: EntityQuery, EnumerableEntityQuery {
    func entities(for identifiers: [String]) async throws -> [PrayerEntity] {
        let all = PrayerEntity.today()
        return identifiers.compactMap { id in all.first { $0.id == id } }
    }

    func allEntities() async throws -> [PrayerEntity] {
        PrayerEntity.today()
    }

    func suggestedEntities() async throws -> [PrayerEntity] {
        PrayerEntity.today().filter { Prayer(rawValue: $0.id)?.isNotifiable == true }
    }
}

// MARK: - Screens

/// The screens `OpenMihrabIntent` can land on. Mirrors `AppTab`, but lives here
/// because the widget extension has no access to the app's tab enum.
struct MihrabScreenEntity: AppEntity, Identifiable, Sendable {

    var id: String

    var tab: MihrabDeepLink.Tab? { MihrabDeepLink.Tab(rawValue: id) }

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Mihrab Screen")

    static let defaultQuery = MihrabScreenEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: Self.title(for: id)),
            image: .init(systemName: Self.symbol(for: id))
        )
    }

    static func title(for id: String) -> String {
        switch MihrabDeepLink.Tab(rawValue: id) {
        case .today: L10n.tabToday
        case .times: L10n.tabTimes
        case .qibla: L10n.tabQibla
        case .deen: L10n.tabEsma
        case .dhikr: L10n.tabDhikr
        case nil: id
        }
    }

    static func symbol(for id: String) -> String {
        switch MihrabDeepLink.Tab(rawValue: id) {
        case .today: "house.fill"
        case .times: "clock.fill"
        case .qibla: "location.north.circle.fill"
        case .deen: "book.fill"
        case .dhikr: "circle.grid.3x3.fill"
        case nil: "app.fill"
        }
    }

    static let all: [MihrabScreenEntity] = MihrabDeepLink.Tab.allCases.map { MihrabScreenEntity(id: $0.rawValue) }

    init(id: String) { self.id = id }
    init(_ tab: MihrabDeepLink.Tab) { self.id = tab.rawValue }
}

struct MihrabScreenEntityQuery: EntityQuery, EnumerableEntityQuery {
    func entities(for identifiers: [String]) async throws -> [MihrabScreenEntity] {
        identifiers.compactMap { id in MihrabScreenEntity.all.first { $0.id == id } }
    }

    func allEntities() async throws -> [MihrabScreenEntity] { MihrabScreenEntity.all }

    func suggestedEntities() async throws -> [MihrabScreenEntity] { MihrabScreenEntity.all }
}

// MARK: - Dhikr phrase

/// The phrases `StartDhikrSessionIntent` can start on.
///
/// The app's `DhikrCatalog` is app-target only, so the built-in ids are mirrored
/// here as a flat list; user-made dhikr are picked up from the App Group when
/// the app publishes them (see `SharedDhikrDirectory`).
struct DhikrPhraseEntity: AppEntity, Identifiable, Sendable {

    var id: String
    var name: String
    var target: Int

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Dhikr")

    static let defaultQuery = DhikrPhraseEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: name))
    }
}

/// App Group mirror of the dhikr phrases the counter knows about.
///
/// The app writes it (`publish(_:)`); intents and widgets read it. Falls back to
/// the six classics so a fresh install still has something to offer Siri.
enum SharedDhikrDirectory {

    private static let key = "mihrab.shared.dhikr.directory"

    struct Entry: Codable, Sendable {
        var id: String
        var name: String
        var target: Int
    }

    /// Ids match `DhikrCatalog`; names are only a fallback until the app publishes
    /// the localized ones.
    static let fallback: [Entry] = [
        Entry(id: "subhanallah", name: "Subhanallah", target: 33),
        Entry(id: "alhamdulillah", name: "Alhamdulillah", target: 33),
        Entry(id: "allahu-akbar", name: "Allahu Akbar", target: 34),
        Entry(id: "la-ilaha", name: "La ilaha illallah", target: 33),
        Entry(id: "salawat", name: "Salawat", target: 100),
        Entry(id: "astaghfirullah", name: "Astaghfirullah", target: 100),
    ]

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: SharedPrayerCache.appGroupID) ?? .standard
    }

    static func publish(_ entries: [Entry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: key)
    }

    static var entries: [Entry] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Entry].self, from: data),
              !decoded.isEmpty
        else { return fallback }
        return decoded
    }
}

struct DhikrPhraseEntityQuery: EntityQuery, EnumerableEntityQuery {
    func entities(for identifiers: [String]) async throws -> [DhikrPhraseEntity] {
        let all = try await allEntities()
        return identifiers.compactMap { id in all.first { $0.id == id } }
    }

    func allEntities() async throws -> [DhikrPhraseEntity] {
        SharedDhikrDirectory.entries.map {
            DhikrPhraseEntity(id: $0.id, name: $0.name, target: $0.target)
        }
    }

    func suggestedEntities() async throws -> [DhikrPhraseEntity] {
        try await allEntities()
    }
}

// MARK: - City

/// A city the configurable widget can be pointed at.
///
/// Backed by `SharedCityDirectory`, which is the App Group mirror of Agent W4's
/// `CityStore`. Until W4 publishes into it, the only entry is whatever city the
/// prayer cache was last calculated for — no invented cities.
struct WidgetCityEntity: AppEntity, Identifiable, Sendable {

    /// `SavedCity.id.uuidString`, or `"current"` for the device's own location.
    var id: String
    var name: String
    var latitude: Double
    var longitude: Double

    static let current = WidgetCityEntity(
        id: "current",
        name: L10n.intCurrentLocation,
        latitude: 0,
        longitude: 0
    )

    var isCurrentLocation: Bool { id == "current" }

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "City")

    static let defaultQuery = WidgetCityEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: name))
    }
}

/// App Group mirror of Agent W4's `CityStore`.
///
/// W4 owns `SavedCity`/`CityStore`; this is a decoupled copy so the widget
/// extension does not have to compile the whole Cities feature. W4 (or the main
/// session) calls `publish(_:)` whenever the city list changes.
enum SharedCityDirectory {

    private static let key = "mihrab.shared.cities"

    struct Entry: Codable, Sendable {
        var id: String
        var name: String
        var latitude: Double
        var longitude: Double
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: SharedPrayerCache.appGroupID) ?? .standard
    }

    static func publish(_ entries: [Entry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: key)
        WidgetCenter.shared.reloadTimelines(ofKind: "CityPrayerWidget")
    }

    /// Published cities, or — if nothing has been published yet — the single
    /// city the cached schedule belongs to.
    static var entries: [Entry] {
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Entry].self, from: data),
           !decoded.isEmpty {
            return decoded
        }
        guard let snapshot = SharedPrayerCache.load(), !snapshot.cityName.isEmpty else { return [] }
        return [Entry(
            id: "cache",
            name: snapshot.cityName,
            latitude: snapshot.latitude,
            longitude: snapshot.longitude
        )]
    }
}

struct WidgetCityEntityQuery: EntityQuery, EnumerableEntityQuery {
    func entities(for identifiers: [String]) async throws -> [WidgetCityEntity] {
        let all = try await allEntities()
        return identifiers.compactMap { id in all.first { $0.id == id } }
    }

    func allEntities() async throws -> [WidgetCityEntity] {
        [.current] + SharedCityDirectory.entries.map {
            WidgetCityEntity(id: $0.id, name: $0.name, latitude: $0.latitude, longitude: $0.longitude)
        }
    }

    func suggestedEntities() async throws -> [WidgetCityEntity] {
        try await allEntities()
    }

    func defaultResult() async -> WidgetCityEntity? { .current }
}
