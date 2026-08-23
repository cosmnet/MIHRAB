import SwiftUI

/// Turns "I haven't prayed for years" into a number the user can start on.
///
/// Everything here is an *estimate* and says so. The monthly deduction is
/// opt-in, explained in plain language, and asks for a single average number —
/// no cycle log, no health data, nothing that leaves the device.
struct QadaSetupWizard: View {
    init() {}

    @Environment(\.dismiss) private var dismiss
    @State private var store = QadaStore.shared

    private enum Mode: String, CaseIterable, Identifiable {
        case years, dates
        var id: String { rawValue }
        var title: String { self == .years ? L10n.qadaByYears : L10n.qadaByDates }
    }

    @State private var mode: Mode = .years
    @State private var years = 5
    @State private var start = Calendar.current.date(byAdding: .year, value: -5, to: Date()) ?? Date()
    @State private var end = Date()
    @State private var prayedPercent: Double = 0
    @State private var deductMonthly = false
    @State private var monthlyDays = 7
    @State private var trackWitr = false

    private var input: QadaEstimateInput {
        QadaEstimateInput(
            start: mode == .years ? QadaEstimator.startDate(yearsAgo: years) : start,
            end: mode == .years ? Date() : end,
            prayedFraction: prayedPercent / 100,
            deductMonthlyDays: deductMonthly,
            averageMonthlyDays: monthlyDays,
            includeWitr: trackWitr
        )
    }

    private var estimate: QadaEstimate { QadaEstimator.estimate(input) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(L10n.qadaWizardIntro)
                        .font(.footnote)
                        .foregroundStyle(MihrabColor.textSecondary)
                }

                Section {
                    Picker("", selection: $mode) {
                        ForEach(Mode.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()

                    if mode == .years {
                        Stepper(value: $years, in: 1...80) {
                            HStack {
                                Text(L10n.qadaWizardTitle)
                                Spacer()
                                Text(L10n.qadaYearsValue(years))
                                    .foregroundStyle(MihrabColor.textSecondary)
                            }
                        }
                        .frame(minHeight: MihrabSpace.hit)
                    } else {
                        DatePicker(L10n.qadaFrom, selection: $start, in: ...end, displayedComponents: .date)
                        DatePicker(L10n.qadaTo, selection: $end, in: start...Date(), displayedComponents: .date)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(L10n.qadaPrayedShare)
                                .font(.subheadline)
                            Spacer()
                            Text("%\(Int(prayedPercent))")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(MihrabColor.mint)
                        }
                        Slider(value: $prayedPercent, in: 0...95, step: 5)
                            .accessibilityLabel(L10n.qadaPrayedShare)
                            .accessibilityValue("%\(Int(prayedPercent))")
                    }
                    .padding(.vertical, 4)
                } footer: {
                    Text(L10n.qadaPrayedShareHint)
                }

                Section {
                    Toggle(L10n.qadaMonthlyToggle, isOn: $deductMonthly)
                        .frame(minHeight: MihrabSpace.hit)
                    if deductMonthly {
                        Stepper(value: $monthlyDays, in: 1...15) {
                            HStack {
                                Text(L10n.qadaMonthlyDays)
                                Spacer()
                                Text("\(monthlyDays)")
                                    .foregroundStyle(MihrabColor.textSecondary)
                            }
                        }
                        .frame(minHeight: MihrabSpace.hit)
                    }
                } footer: {
                    Text(L10n.qadaMonthlyExplain)
                }

                Section {
                    Toggle(L10n.qadaWitrToggle, isOn: $trackWitr)
                        .frame(minHeight: MihrabSpace.hit)
                } footer: {
                    Text(L10n.qadaWitrNote)
                }

                Section {
                    row(L10n.qadaTotalDays(estimate.totalDays))
                    if estimate.deductedDays > 0 { row(L10n.qadaDeductedDays(estimate.deductedDays)) }
                    row(L10n.qadaEffectiveDays(estimate.effectiveDays))
                    row(L10n.qadaPerPrayer(estimate.perPrayer))
                    Text(L10n.qadaTotalPrayers(estimate.total))
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(MihrabColor.textPrimary)
                } header: {
                    Text(L10n.qadaBreakdown)
                } footer: {
                    Text(store.isSetUp ? L10n.qadaReplaceWarning : "")
                }
            }
            .navigationTitle(L10n.qadaWizardTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.qadaCancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.qadaSaveEstimate) {
                        store.apply(estimate, trackWitr: trackWitr)
                        HapticsEngine.shared.success()
                        dismiss()
                    }
                    .disabled(estimate.total == 0)
                }
            }
        }
    }

    private func row(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(MihrabColor.textSecondary)
    }
}
