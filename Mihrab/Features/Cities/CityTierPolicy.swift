import Foundation

/// The free/Plus rule for the city list, kept as a dependency-free value type
/// so it can be unit-tested without booting `SubscriptionManager`,
/// `AppSettings` or Core Location.
///
/// The rule itself: the free plan follows **one** city — wherever the device
/// is. Plus removes the limit. Losing Plus never deletes a city; the extras
/// simply stop being selectable until the user subscribes again.
struct CityTierPolicy: Equatable, Sendable {
    let freeLimit: Int
    let isPremium: Bool

    init(freeLimit: Int = 1, isPremium: Bool) {
        self.freeLimit = max(1, freeLimit)
        self.isPremium = isPremium
    }

    func canAdd(currentCount: Int) -> Bool {
        isPremium || currentCount < freeLimit
    }

    /// `nil` when unlimited.
    func remainingSlots(currentCount: Int) -> Int? {
        isPremium ? nil : max(0, freeLimit - currentCount)
    }

    /// A city past the free limit is *locked*, not deleted.
    func isLocked(index: Int) -> Bool {
        guard !isPremium else { return false }
        return index >= freeLimit
    }

    func selectableCount(total: Int) -> Int {
        isPremium ? total : min(total, freeLimit)
    }
}
