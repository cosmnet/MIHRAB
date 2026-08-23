import Foundation
import Observation

/// Tiny, dependency-free store for the Esmaül Hüsna surface: which Names the
/// user has opened (learning progress) and which ones they starred.
/// Persisted in `UserDefaults` — the data is small, non-syncing and disposable,
/// so it deliberately stays out of SwiftData.
@MainActor
@Observable
final class EsmaLibrary {
    static let shared = EsmaLibrary()

    private enum Key {
        static let favorites = "mihrab.esma.favorites"
        static let visited = "mihrab.esma.visited"
    }

    private let defaults: UserDefaults

    private(set) var favorites: Set<String>
    private(set) var visited: Set<String>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        favorites = Set(defaults.stringArray(forKey: Key.favorites) ?? [])
        visited = Set(defaults.stringArray(forKey: Key.visited) ?? [])
    }

    // MARK: - Favorites

    func isFavorite(_ name: EsmaName) -> Bool { favorites.contains(name.id) }

    /// Returns the new state so callers can drive the star animation.
    @discardableResult
    func toggleFavorite(_ name: EsmaName) -> Bool {
        let added: Bool
        if favorites.contains(name.id) {
            favorites.remove(name.id)
            added = false
        } else {
            favorites.insert(name.id)
            added = true
        }
        defaults.set(Array(favorites), forKey: Key.favorites)
        return added
    }

    var favoriteNames: [EsmaName] {
        BundledContent.esma.filter { favorites.contains($0.id) }
    }

    // MARK: - Progress

    func hasVisited(_ name: EsmaName) -> Bool { visited.contains(name.id) }

    func markVisited(_ name: EsmaName) {
        guard !visited.contains(name.id) else { return }
        visited.insert(name.id)
        defaults.set(Array(visited), forKey: Key.visited)
    }

    var visitedCount: Int { visited.count }

    var favoriteCount: Int { favorites.count }

    /// 0…1 across the ninety-nine.
    var progress: Double {
        let total = max(BundledContent.esma.count, 1)
        return min(1, Double(visited.count) / Double(total))
    }
}
