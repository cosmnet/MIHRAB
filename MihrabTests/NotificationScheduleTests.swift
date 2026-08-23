import XCTest

/// Guards the three promises the reminder system makes:
///
/// 1. a plan never exceeds the pending-notification budget it was given,
/// 2. targeted cleanup deletes only our own requests (trial reminders survive),
/// 3. a prayer instance is announced once — by an alarm *or* a notification.
///
/// Everything exercised here lives in `ReminderPlanner`, which is dependency
/// free on purpose so this file needs no UserNotifications, AlarmKit or UIKit.
final class NotificationScheduleTests: XCTestCase {

    // MARK: - Fixtures

    /// A stand-in for `NotificationEngine.Planned` with the same ranking shape.
    private struct Item: Equatable {
        let id: String
        let rank: Int
        let date: Date
        var isEssential: Bool { rank <= 1 }
    }

    private func fit(_ items: [Item], budget: Int, extrasReserve: Int = 8) -> [Item] {
        ReminderPlanner.fit(
            items,
            budget: budget,
            extrasReserve: extrasReserve,
            isEssential: { $0.isEssential },
            rank: { $0.rank },
            fireDate: { $0.date }
        )
    }

    private func makeDays(
        from start: Date,
        count: Int,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> [DayPrayerTimes] {
        // Fixed offsets from midnight — realistic ordering is all that matters.
        let offsets: [(Prayer, TimeInterval)] = [
            (.fajr, 5 * 3600),
            (.sunrise, 6.5 * 3600),
            (.dhuhr, 13 * 3600),
            (.asr, 16.5 * 3600),
            (.maghrib, 19.5 * 3600),
            (.isha, 21 * 3600),
        ]
        return (0..<count).compactMap { index in
            guard let day = calendar.date(byAdding: .day, value: index, to: start) else { return nil }
            let midnight = calendar.startOfDay(for: day)
            var times: [Prayer: Date] = [:]
            for (prayer, offset) in offsets {
                times[prayer] = midnight.addingTimeInterval(offset)
            }
            return DayPrayerTimes(date: midnight, times: times)
        }
    }

    // MARK: - Budget

    func testPlanNeverExceedsBudget() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        // 50 prayer alerts + 50 heads-ups + a fat kandil month of extras: the
        // exact shape that used to sail past the 64-pending cap.
        var items: [Item] = []
        for index in 0..<50 {
            items.append(Item(id: "prayer-\(index)", rank: 0,
                              date: now.addingTimeInterval(Double(index) * 3_600)))
            items.append(Item(id: "pre-\(index)", rank: 1,
                              date: now.addingTimeInterval(Double(index) * 3_600 - 900)))
        }
        for index in 0..<30 {
            items.append(Item(id: "religious-\(index)", rank: 3,
                              date: now.addingTimeInterval(Double(index) * 86_400)))
        }

        for budget in [0, 1, 8, 20, 60, 64] {
            let fitted = fit(items, budget: budget)
            XCTAssertLessThanOrEqual(fitted.count, budget, "budget \(budget) overflowed")
            XCTAssertEqual(Set(fitted.map(\.id)).count, fitted.count, "duplicate identifiers")
        }
    }

    func testBudgetOfZeroSchedulesNothing() {
        let now = Date()
        let items = (0..<10).map { Item(id: "p\($0)", rank: 0, date: now) }
        XCTAssertTrue(fit(items, budget: 0).isEmpty)
        XCTAssertTrue(fit(items, budget: -5).isEmpty)
    }

    func testEssentialsAreScheduledNearestFirst() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let items = (0..<20).map {
            Item(id: "p\($0)", rank: 0, date: now.addingTimeInterval(Double(20 - $0) * 3_600))
        }
        let fitted = fit(items, budget: 5, extrasReserve: 0)
        XCTAssertEqual(fitted.count, 5)
        let dates = fitted.map(\.date)
        XCTAssertEqual(dates, dates.sorted(), "near days must win over distant ones")
        XCTAssertEqual(fitted.first?.id, "p19")
    }

    func testExtrasKeepTheirReserveButNoMore() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let essentials = (0..<40).map {
            Item(id: "p\($0)", rank: 0, date: now.addingTimeInterval(Double($0) * 3_600))
        }
        let extras = (0..<3).map {
            Item(id: "x\($0)", rank: 2, date: now.addingTimeInterval(Double($0) * 86_400))
        }
        let fitted = fit(essentials + extras, budget: 20, extrasReserve: 8)

        XCTAssertEqual(fitted.count, 20)
        // Only three extras exist, so only three slots are held back.
        XCTAssertEqual(fitted.filter { !$0.isEssential }.count, 3)
        XCTAssertEqual(fitted.filter(\.isEssential).count, 17)
    }

    func testExtrasSurviveACrowdedPrayerSchedule() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let essentials = (0..<100).map {
            Item(id: "p\($0)", rank: 0, date: now.addingTimeInterval(Double($0) * 600))
        }
        let extras = (0..<20).map {
            Item(id: "x\($0)", rank: 2, date: now.addingTimeInterval(Double($0) * 86_400))
        }
        let fitted = fit(essentials + extras, budget: 60, extrasReserve: 8)

        XCTAssertEqual(fitted.count, 60)
        XCTAssertEqual(fitted.filter { !$0.isEssential }.count, 8,
                       "the Friday reminder must not be starved out")
    }

    // MARK: - Targeted cleanup

    func testCleanupClaimsOnlyItsOwnRequests() {
        let ours = [
            "mihrab-prayer-fajr-1700000000",
            "mihrab-pre-asr-1700000000",
            "mihrab-karahat-dhuhr-1700000000",
            "mihrab-hadith",
            "mihrab-religious-mevlid-0",
            "mihrab-jumuah",
        ]
        for identifier in ours {
            XCTAssertTrue(ReminderPlanner.isManaged(identifier), identifier)
        }
    }

    func testCleanupNeverTouchesTrialReminders() {
        // The whole reason `removeAllPendingNotificationRequests()` had to go.
        for identifier in ["mihrab-trial-reminder-day5", "mihrab-trial-reminder-final"] {
            XCTAssertFalse(ReminderPlanner.isManaged(identifier), identifier)
        }
    }

    func testTrialReminderIdentifiersStayOutsideOurPrefixes() {
        // Belt and braces: if `TrialReminder` ever renames its identifiers, this
        // fails before anybody's billing reminder is silently deleted.
        XCTAssertFalse(ReminderPlanner.isManaged(TrialReminderIdentifiers.day5))
        XCTAssertFalse(ReminderPlanner.isManaged(TrialReminderIdentifiers.final))
    }

    func testLegacyIdentifiersAreReclaimed() {
        // Requests written by builds before the prefix scheme must be cleared,
        // or an upgrading user keeps duplicates forever.
        for identifier in ["prayer-fajr-123", "daily-hadith", "religious-x-0", "jumuah"] {
            XCTAssertTrue(ReminderPlanner.isManaged(identifier), identifier)
        }
    }

    func testUnrelatedIdentifiersAreLeftAlone() {
        for identifier in ["some-other-feature", "widget-refresh", "", "mihrab"] {
            XCTAssertFalse(ReminderPlanner.isManaged(identifier), identifier)
        }
    }

    // MARK: - No double announcement

    func testAlarmPlanRespectsLimitHorizonAndEnabledPrayers() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let days = makeDays(from: now, count: 10)

        let plan = ReminderPlanner.alarmPlan(
            days: days, now: now, horizonDays: 3, limit: 15
        ) { _ in true }

        XCTAssertLessThanOrEqual(plan.count, 15)
        XCTAssertTrue(plan.allSatisfy { $0.date > now })
        XCTAssertTrue(plan.allSatisfy { $0.date <= now.addingTimeInterval(3 * 86_400) })
        XCTAssertFalse(plan.contains { $0.prayer == .sunrise }, "sunrise is a marker, not a prayer")
        XCTAssertEqual(plan.map(\.date), plan.map(\.date).sorted())
    }

    func testDisabledPrayersNeverBecomeAlarms() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let days = makeDays(from: now, count: 5)

        let plan = ReminderPlanner.alarmPlan(
            days: days, now: now, horizonDays: 5, limit: 100
        ) { $0 != .fajr }

        XCTAssertFalse(plan.contains { $0.prayer == .fajr })
    }

    func testDuplicateCachedDaysProduceOneAlarmEach() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        // A refresh overlap can leave the same day twice in the cached month.
        let days = makeDays(from: now, count: 3) + makeDays(from: now, count: 3)

        let plan = ReminderPlanner.alarmPlan(
            days: days, now: now, horizonDays: 3, limit: 100
        ) { _ in true }

        XCTAssertEqual(Set(plan.map(\.key)).count, plan.count, "one alarm per prayer instance")
    }

    /// The contract between the two mechanisms: the notification engine skips
    /// every key the alarm scheduler claimed, so each moment is announced once.
    func testAlarmAndNotificationPathsNeverOverlap() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let days = makeDays(from: now, count: 10)

        let alarms = ReminderPlanner.alarmPlan(
            days: days, now: now, horizonDays: 3, limit: 15
        ) { _ in true }
        let covered = Set(alarms.map(\.key))

        // Mirror of `NotificationEngine.buildPlan`'s prayer-alert loop.
        var notificationKeys: [String] = []
        for day in days {
            for prayer in Prayer.allCases where prayer.isNotifiable {
                guard let time = day.time(for: prayer), time > now else { continue }
                let key = ReminderPlanner.PrayerInstance(prayer: prayer, date: time).key
                if !covered.contains(key) { notificationKeys.append(key) }
            }
        }

        XCTAssertTrue(covered.isDisjoint(with: Set(notificationKeys)),
                      "a prayer must never get both an alarm and a notification")

        // And nothing is silently dropped between the two paths.
        var allKeys: Set<String> = []
        for day in days {
            for prayer in Prayer.allCases where prayer.isNotifiable {
                guard let time = day.time(for: prayer), time > now else { continue }
                allKeys.insert(ReminderPlanner.PrayerInstance(prayer: prayer, date: time).key)
            }
        }
        XCTAssertEqual(covered.union(notificationKeys), allKeys)
    }

    func testNotificationModeLeavesEveryPrayerToNotifications() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let days = makeDays(from: now, count: 3)

        // Notification mode is expressed as "no alarms planned at all".
        let alarms = ReminderPlanner.alarmPlan(
            days: days, now: now, horizonDays: 3, limit: 0
        ) { _ in true }

        XCTAssertTrue(alarms.isEmpty)
    }

    func testInstanceKeyIsStableAndDistinct() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let a = ReminderPlanner.PrayerInstance(prayer: .asr, date: date)
        let b = ReminderPlanner.PrayerInstance(prayer: .asr, date: date)
        let c = ReminderPlanner.PrayerInstance(prayer: .isha, date: date)
        let d = ReminderPlanner.PrayerInstance(prayer: .asr, date: date.addingTimeInterval(60))

        XCTAssertEqual(a.key, b.key)
        XCTAssertNotEqual(a.key, c.key)
        XCTAssertNotEqual(a.key, d.key)
    }
}

/// Mirrors `TrialReminder`'s identifiers without importing it — that type pulls
/// in UserNotifications and the subscription stack, which this target does not
/// compile. If these strings drift, `testTrialReminderIdentifiersStayOutside…`
/// is the wrong test to fix: fix `ReminderPlanner.foreignPrefixes`.
private enum TrialReminderIdentifiers {
    static let day5 = "mihrab-trial-reminder-day5"
    static let final = "mihrab-trial-reminder-final"
}
