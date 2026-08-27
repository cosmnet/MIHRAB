import SwiftUI

/// The zakat worksheet: prices, threshold, items, result, fitre.
struct ZakatView: View {
    init() {}

    @Environment(\.dismiss) private var dismiss
    @State private var store = ZakatStore.shared
    @State private var showFitre = false

    private var result: ZakatResult { store.result }

    var body: some View {
        NavigationStack {
            Form {
                pricesSection
                nisabSection
                assetsSection
                deductionsSection
                resultSection
                zakatYearSection
                fitreSection
                disclaimerSection
            }
            .navigationTitle(L10n.zakatTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button(L10n.done) { dismiss() } }
            }
        }
    }

    // MARK: - Prices

    private var pricesSection: some View {
        Section {
            amountRow(L10n.zakatGoldPrice, value: Binding(
                get: { store.prices.goldPerGram },
                set: { store.prices.goldPerGram = max(0, $0) }
            ))
            amountRow(L10n.zakatSilverPrice, value: Binding(
                get: { store.prices.silverPerGram },
                set: { store.prices.silverPerGram = max(0, $0) }
            ))
            Button {
                store.stampPrices()
                HapticsEngine.shared.light()
            } label: {
                Text(L10n.zakatStampPrices)
                    .frame(minHeight: MihrabSpace.hit)
            }
            .disabled(!store.prices.isUsable)

            if let updated = store.pricesUpdatedAt {
                Text(L10n.zakatPricesUpdated(Self.dateFormatter.string(from: updated)))
                    .font(.caption)
                    .foregroundStyle(MihrabColor.textTertiary)
            }
            if store.pricesLookStale {
                Label(L10n.zakatPricesStale, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(MihrabColor.brass)
            }
        } header: {
            Text(L10n.zakatPricesHeader)
        } footer: {
            Text(L10n.zakatPricesNote)
        }
    }

    // MARK: - Nisab

    private var nisabSection: some View {
        Section {
            Picker(L10n.zakatNisabHeader, selection: Binding(
                get: { store.basis },
                set: { store.basis = $0 }
            )) {
                ForEach(NisabBasis.allCases) { Text($0.localizedName).tag($0) }
            }
            .pickerStyle(.segmented)

            // Whose position the current choice is, in one sentence. The user
            // said they cannot decide this themselves, so the app decides and
            // then explains — it does not hand the question back.
            Text(store.basis.localizedNote)
                .font(.caption)
                .foregroundStyle(MihrabColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let nisab = store.nisabValue, nisab > 0 {
                Text(L10n.zakatNisabValue(store.format(nisab)))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MihrabColor.mint)
            } else {
                Text(L10n.zakatPricesMissing)
                    .font(.caption)
                    .foregroundStyle(MihrabColor.textSecondary)
            }

            // Name the authority behind the 80,18 g figure.
            Label(L10n.zakatSourceDiyanet, systemImage: "building.columns")
                .font(.caption)
                .foregroundStyle(MihrabColor.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        } header: {
            Text(L10n.zakatNisabHeader)
        } footer: {
            Text(L10n.zakatBasisExplain)
        }
    }

    // MARK: - Items

    private var assetsSection: some View {
        Section {
            amountRow(L10n.zakatCash, value: assetBinding(\.cash))
            amountRow(L10n.zakatBank, value: assetBinding(\.bank))
            amountRow(L10n.zakatGoldGrams, value: assetBinding(\.goldGrams))
            amountRow(L10n.zakatSilverGrams, value: assetBinding(\.silverGrams))
            amountRow(L10n.zakatTradeGoods, value: assetBinding(\.tradeGoods))
            amountRow(L10n.zakatReceivables, value: assetBinding(\.receivables))
            amountRow(L10n.zakatInvestments, value: assetBinding(\.investments))
        } header: {
            Text(L10n.zakatAssetsHeader)
        }
    }

    private var deductionsSection: some View {
        Section {
            amountRow(L10n.zakatDebts, value: assetBinding(\.debts))
            amountRow(L10n.zakatEssentials, value: assetBinding(\.essentialNeeds))
        } header: {
            Text(L10n.zakatDeductionsHeader)
        } footer: {
            Text(L10n.zakatEssentialsNote)
        }
    }

    // MARK: - Result

    private var resultSection: some View {
        Section {
            line(L10n.zakatGross(store.format(result.grossAssets)))
            line(L10n.zakatDeductionsLine(store.format(result.deductions)))
            line(L10n.zakatNet(store.format(result.netWealth)))

            if store.nisabValue == nil {
                Text(L10n.zakatNoPrices)
                    .font(.subheadline)
                    .foregroundStyle(MihrabColor.textSecondary)
            } else if result.isLiable {
                Text(L10n.zakatDue(store.format(result.zakatDue)))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(MihrabColor.textPrimary)
                Text(L10n.zakatRateLine)
                    .font(.caption)
                    .foregroundStyle(MihrabColor.textTertiary)
            } else {
                Text(L10n.zakatBelowNisab)
                    .font(.subheadline)
                    .foregroundStyle(MihrabColor.mint)
            }

            ShareLink(
                item: ShareImage(image: shareCardImage()),
                preview: SharePreview(L10n.zakatShareTitle, image: Image(uiImage: shareCardImage()))
            ) {
                Label(L10n.zakatShare, systemImage: "square.and.arrow.up")
                    .frame(minHeight: MihrabSpace.hit)
            }
        } header: {
            Text(L10n.zakatResultHeader)
        }
    }

    // MARK: - Zakat year

    private var zakatYearSection: some View {
        Section {
            if let next = store.nextZakatAnniversary {
                Text(L10n.zakatAnniversary(Self.dateFormatter.string(from: next)))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MihrabColor.textPrimary)
                if let days = store.daysUntilAnniversary, days >= 0 {
                    Text(L10n.zakatAnniversaryDays(days))
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textTertiary)
                }
                Button(role: .destructive) {
                    store.clearZakatYear()
                } label: {
                    Text(L10n.zakatClearYear).frame(minHeight: MihrabSpace.hit)
                }
            } else {
                Button {
                    store.startZakatYearToday()
                    HapticsEngine.shared.success()
                } label: {
                    Text(L10n.zakatStartYear).frame(minHeight: MihrabSpace.hit)
                }
            }
        } header: {
            Text(L10n.zakatYearHeader)
        } footer: {
            Text(L10n.zakatHawlExplain)
        }
    }

    // MARK: - Fitre

    private var fitreSection: some View {
        Section {
            amountRow(L10n.fitrePerPerson, value: Binding(
                get: { store.fitrePerPerson },
                set: { store.fitrePerPerson = max(0, $0) }
            ))

            // One tap instead of "go and look it up". Only offered while the
            // announced figure is still the current one — after that the app
            // says nothing rather than suggesting a stale amount.
            if let suggested = store.suggestedFitre {
                Button {
                    store.applySuggestedFitre()
                    HapticsEngine.shared.light()
                } label: {
                    Text(L10n.fitreDiyanetAmount(store.format(suggested)))
                        .frame(minHeight: MihrabSpace.hit)
                }
                Text(L10n.fitreDiyanetNote(Self.dateFormatter.string(from: DiyanetFitre.announcedOn)))
                    .font(.caption)
                    .foregroundStyle(MihrabColor.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if store.fitreFigureIsStale {
                Label(L10n.fitreFigureOutdated, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(MihrabColor.brass)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Stepper(value: Binding(get: { store.fitrePeople }, set: { store.fitrePeople = $0 }), in: 0...50) {
                HStack {
                    Text(L10n.fitrePeople)
                    Spacer()
                    Text("\(store.fitrePeople)")
                        .foregroundStyle(MihrabColor.textSecondary)
                }
            }
            .frame(minHeight: MihrabSpace.hit)
            Text(L10n.fitreTotal(store.format(store.fitre.total)))
                .font(.headline.monospacedDigit())
                .foregroundStyle(MihrabColor.textPrimary)
        } header: {
            Text(L10n.fitreHeader)
        } footer: {
            Text(L10n.fitreNote)
        }
    }

    private var disclaimerSection: some View {
        Section {
            Label(L10n.zakatDisclaimer, systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(MihrabColor.textSecondary)
            Button(role: .destructive) {
                store.resetWorksheet()
                HapticsEngine.shared.warning()
            } label: {
                Text(L10n.zakatReset).frame(minHeight: MihrabSpace.hit)
            }
        }
    }

    // MARK: - Row helpers

    private func assetBinding(_ path: WritableKeyPath<ZakatAssets, Double>) -> Binding<Double> {
        Binding(
            get: { store.assets[keyPath: path] },
            set: { store.assets[keyPath: path] = max(0, $0) }
        )
    }

    private func amountRow(_ title: String, value: Binding<Double>) -> some View {
        HStack {
            Text(title)
                .font(.body)
            Spacer(minLength: 12)
            TextField(title, value: value, format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(maxWidth: 140)
                .accessibilityLabel(title)
        }
        .frame(minHeight: MihrabSpace.hit)
    }

    private func line(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(MihrabColor.textSecondary)
    }

    // MARK: - Share card

    private func shareCardImage() -> UIImage {
        let renderer = ImageRenderer(
            content: ZakatShareCard(
                result: result,
                nisabKnown: store.nisabValue != nil,
                format: { store.format($0) }
            )
        )
        renderer.scale = 3
        return renderer.uiImage ?? UIImage()
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: L10n.localeIdentifier)
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - Share card

/// Shareable summary. The disclaimer is part of the image on purpose — a
/// screenshot of a zakat figure travels further than the screen it came from.
struct ZakatShareCard: View {
    let result: ZakatResult
    let nisabKnown: Bool
    let format: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.zakatShareTitle)
                .ornamentalCaps()

            Text(nisabKnown && result.isLiable ? format(result.zakatDue) : format(0))
                .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(MihrabColor.textPrimary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.zakatGross(format(result.grossAssets)))
                Text(L10n.zakatDeductionsLine(format(result.deductions)))
                Text(L10n.zakatNet(format(result.netWealth)))
                if nisabKnown {
                    Text(L10n.zakatNisabValue(format(result.nisabValue)))
                }
                Text(L10n.zakatRateLine)
            }
            .font(.footnote.monospacedDigit())
            .foregroundStyle(MihrabColor.textSecondary)

            Divider().overlay(MihrabColor.mint.opacity(0.2))

            Text(L10n.zakatDisclaimer)
                .font(.caption2)
                .foregroundStyle(MihrabColor.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(28)
        .frame(width: 480, alignment: .leading)
        .background(MihrabColor.forest)
    }
}
