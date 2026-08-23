import Foundation
import Observation

/// Hatim plans and their progress.
///
/// Free, ungated, and offline. Finishing the Qur'an is worship; it does not go
/// behind a paywall.
@MainActor
@Observable
final class HatimStore {
    static let shared = HatimStore()

    private let defaults = UserDefaults.standard
    private enum Key {
        static let plans = "mihrab.hatim.plans"
        static let completed = "mihrab.hatim.completedCount"
    }

    private(set) var plans: [HatimPlan] = []
    /// Hatims finished, ever. Kept even after a plan is deleted.
    private(set) var completedHatims: Int = 0

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {
        if let data = defaults.data(forKey: Key.plans),
           let decoded = try? Self.decoder.decode([HatimPlan].self, from: data) {
            plans = decoded
        }
        completedHatims = defaults.integer(forKey: Key.completed)
    }

    private func persist() {
        if let data = try? Self.encoder.encode(plans) {
            defaults.set(data, forKey: Key.plans)
        }
        defaults.set(completedHatims, forKey: Key.completed)
        QuranSync.push()
    }

    // MARK: Queries

    var activePlans: [HatimPlan] { plans.filter { $0.completedAt == nil } }

    /// The one the reader treats as "the" hatim: the individual plan if there
    /// is one, else the earliest-targeted active plan.
    var primaryPlan: HatimPlan? {
        activePlans.first { $0.kind == .individual }
            ?? activePlans.min { $0.targetDate < $1.targetDate }
    }

    func plan(id: String) -> HatimPlan? { plans.first { $0.id == id } }

    func progress(for plan: HatimPlan, now: Date = Date()) -> HatimProgress {
        HatimMath.progress(for: plan, now: now)
    }

    // MARK: Mutations

    func add(_ plan: HatimPlan) {
        plans.removeAll { $0.id == plan.id }
        plans.append(plan)
        persist()
    }

    func remove(id: String) {
        plans.removeAll { $0.id == id }
        persist()
    }

    func setTarget(_ date: Date, for id: String) {
        guard let index = plans.firstIndex(where: { $0.id == id }) else { return }
        plans[index].targetDate = date
        persist()
    }

    /// Records that the reader has reached `ref`. Monotonic within the plan's
    /// scope: scrolling back to re-read an ayah never undoes progress.
    func advance(planID: String, to ref: AyahRef) {
        guard let index = plans.firstIndex(where: { $0.id == planID }),
              let absolute = QuranCatalog.absoluteIndex(of: ref)
        else { return }
        let plan = plans[index]
        guard plan.scope.contains(absolute), absolute > plan.position else { return }
        plans[index].position = absolute
        finishIfComplete(at: index)
        persist()
    }

    /// Explicit "I finished up to here" — the tap on a juz or page row. Also
    /// monotonic.
    func markCompleted(planID: String, throughAbsolute absolute: Int) {
        guard let index = plans.firstIndex(where: { $0.id == planID }) else { return }
        let plan = plans[index]
        let clamped = min(max(absolute, plan.scope.start - 1), plan.scope.end)
        guard clamped > plan.position else { return }
        plans[index].position = clamped
        finishIfComplete(at: index)
        persist()
    }

    /// The only way progress goes down, and it is deliberate and confirmed in
    /// the UI: starting the plan over.
    func restart(planID: String) {
        guard let index = plans.firstIndex(where: { $0.id == planID }) else { return }
        plans[index].position = plans[index].scope.start - 1
        plans[index].startedAt = Date()
        plans[index].completedAt = nil
        persist()
    }

    private func finishIfComplete(at index: Int) {
        let plan = plans[index]
        guard plan.completedAt == nil, plan.position >= plan.scope.end else { return }
        plans[index].completedAt = Date()
        completedHatims += 1
    }

    /// Every advance a reading session produced, applied in one write.
    func recordReading(ayahs: [AyahRef]) {
        guard let furthest = ayahs.max() else { return }
        for plan in activePlans {
            advance(planID: plan.id, to: furthest)
        }
    }

    // MARK: Shared hatim

    /// Creates the local half of a shared hatim from an invite. The device
    /// tracks only the juz it claims — see `HatimGroup` for why there is no
    /// group-wide view.
    @discardableResult
    func joinShared(_ invite: HatimInvite, claiming juz: [Int]) -> HatimPlan? {
        let wanted = juz.filter { (1...30).contains($0) }.sorted()
        guard let first = wanted.first, let last = wanted.last,
              let firstScope = HatimScope.juz(first),
              let lastScope = HatimScope.juz(last)
        else { return nil }

        let group = HatimGroup(
            id: invite.groupID,
            name: invite.name,
            shareCount: invite.shareCount,
            targetDate: invite.targetDate,
            claimedJuz: wanted,
            organiser: invite.organiser
        )
        let plan = HatimPlan(
            kind: .shared,
            title: invite.name,
            scope: HatimScope(start: firstScope.start, end: lastScope.end),
            targetDate: invite.targetDate,
            group: group
        )
        add(plan)
        return plan
    }

    /// Juz already claimed on *this* device. Other participants' claims are
    /// unknowable without a server, and the UI says so.
    var claimedJuzLocally: Set<Int> {
        Set(activePlans.compactMap { $0.group?.claimedJuz }.flatMap { $0 })
    }

    // MARK: Sync

    struct Snapshot: Codable, Sendable {
        var plans: [HatimPlan]
        var completedHatims: Int
    }

    func exportSnapshot() -> Snapshot {
        Snapshot(plans: plans, completedHatims: completedHatims)
    }

    /// Union-additive: a plan present on either device survives, and where both
    /// have it the *further* position wins. Progress only ever goes forward.
    func merge(_ snapshot: Snapshot) {
        var byID = Dictionary(uniqueKeysWithValues: plans.map { ($0.id, $0) })
        for incoming in snapshot.plans {
            if var existing = byID[incoming.id] {
                existing.position = max(existing.position, incoming.position)
                existing.targetDate = min(existing.targetDate, incoming.targetDate)
                existing.completedAt = existing.completedAt ?? incoming.completedAt
                byID[incoming.id] = existing
            } else {
                byID[incoming.id] = incoming
            }
        }
        plans = byID.values.sorted { $0.startedAt < $1.startedAt }
        completedHatims = max(completedHatims, snapshot.completedHatims)
        if let data = try? Self.encoder.encode(plans) {
            defaults.set(data, forKey: Key.plans)
        }
        defaults.set(completedHatims, forKey: Key.completed)
    }
}
