import Foundation

/// Everything the setup wizard asks for. Plain data so the maths can be tested
/// without a store, a view or a date picker.
struct QadaEstimateInput: Equatable, Sendable {
    /// First day of the missed period (usually puberty, or the day the user
    /// stopped praying).
    var start: Date
    /// Last day of the missed period — normally today.
    var end: Date
    /// Share of that period the user *did* pray, 0…1. Most people did not miss
    /// every single prayer, and forcing an all-or-nothing answer produces a
    /// number so large it stops anyone from starting.
    var prayedFraction: Double = 0
    /// Optional, off by default, women only.
    var deductMonthlyDays: Bool = false
    /// Average number of days per month to deduct. Asked as a plain average —
    /// we never store, sync or ask for anything resembling health data.
    var averageMonthlyDays: Int = 7
    /// Hanafi practice counts witr as wajib, so it is made up alongside the
    /// five. Off by default; the user chooses.
    var includeWitr: Bool = false
}

/// The breakdown the wizard shows before anything is written.
struct QadaEstimate: Equatable, Sendable {
    var totalDays: Int
    var deductedDays: Int
    var effectiveDays: Int
    /// Per fard prayer (Fajr, Dhuhr, Asr, Maghrib, Isha) — the same for each.
    var perPrayer: Int
    var witr: Int

    var total: Int { perPrayer * 5 + witr }
}

enum QadaEstimator {
    /// Mean length of a lunar month in days, used only to turn a span into a
    /// count of months for the optional deduction.
    static let averageMonthLength = 29.53059

    static func estimate(_ input: QadaEstimateInput) -> QadaEstimate {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: min(input.start, input.end))
        let end = calendar.startOfDay(for: max(input.start, input.end))
        let rawDays = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        // Inclusive of both ends, and never negative.
        let totalDays = max(0, rawDays)

        var deducted = 0
        if input.deductMonthlyDays, input.averageMonthlyDays > 0, totalDays > 0 {
            let months = Double(totalDays) / averageMonthLength
            deducted = min(totalDays, Int((months * Double(input.averageMonthlyDays)).rounded()))
        }

        let fraction = min(max(input.prayedFraction, 0), 1)
        let afterDeduction = totalDays - deducted
        let effective = max(0, Int((Double(afterDeduction) * (1 - fraction)).rounded()))

        return QadaEstimate(
            totalDays: totalDays,
            deductedDays: deducted,
            effectiveDays: effective,
            perPrayer: effective,
            witr: input.includeWitr ? effective : 0
        )
    }

    /// Convenience for the "how many years?" entry path.
    static func startDate(yearsAgo years: Int, from reference: Date = Date()) -> Date {
        Calendar.current.date(byAdding: .year, value: -max(0, years), to: reference) ?? reference
    }
}
