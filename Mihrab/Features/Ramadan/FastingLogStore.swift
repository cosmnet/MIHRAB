import Foundation
import SwiftUI

/// A tick per fasted day, kept in `UserDefaults`.
///
/// Deliberately keyed by the *Gregorian* day the fast was kept: the Hijri day
/// is only ever used to lay the grid out, so a stored value can never drift if
/// the Hijri calculation changes underneath it.
@Observable
final class FastingLogStore: @unchecked Sendable {
    static let shared = FastingLogStore()

    private let defaults: UserDefaults
    private let key = "ramadanFastedDays"

    private(set) var revision = 0

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var stored: Set<String> {
        get { Set(defaults.stringArray(forKey: key) ?? []) }
        set { defaults.set(Array(newValue), forKey: key) }
    }

    func isFasted(_ date: Date) -> Bool {
        _ = revision
        return stored.contains(Self.formatter.string(from: date))
    }

    @discardableResult
    func toggle(_ date: Date) -> Bool {
        let token = Self.formatter.string(from: date)
        var set = stored
        let nowFasted: Bool
        if set.contains(token) {
            set.remove(token)
            nowFasted = false
        } else {
            set.insert(token)
            nowFasted = true
        }
        stored = set
        revision &+= 1
        return nowFasted
    }

    /// How many of the supplied days are marked. Callers pass the current
    /// Ramadan's dates so old years never inflate the number.
    func fastedCount(in dates: [Date]) -> Int {
        _ = revision
        let set = stored
        return dates.filter { set.contains(Self.formatter.string(from: $0)) }.count
    }
}
