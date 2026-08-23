import SwiftUI

// MARK: - Display settings

/// Type size, leading, layout, reading mode and typography theme.
///
/// Everything here except the extra typography themes is free. The gate is the
/// existing `PremiumFeature.themes`, which is what those presets are.
struct QuranDisplaySettingsSheet: View {
    @State private var prefs = QuranReadingPreferences.shared
    @State private var subscriptions = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    sizeRow
                    spacingRow
                    sample
                } header: {
                    Text(L10n.quranTextSize)
                }

                Section {
                    Picker(L10n.quranReadingMode, selection: $prefs.mode) {
                        ForEach(QuranReadingMode.allCases) { mode in
                            Label(mode.localizedName, systemImage: mode.symbolName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker(L10n.quranFlowTitle, selection: $prefs.flow) {
                        ForEach(QuranFlow.allCases) { flow in
                            Label(flow.localizedName, systemImage: flow.symbolName).tag(flow)
                        }
                    }

                    Toggle(L10n.quranKeepAwake, isOn: $prefs.keepAwake)
                }

                Section {
                    ForEach(QuranTypeTheme.allCases) { theme in
                        themeRow(theme)
                    }
                } header: {
                    Text(L10n.quranTypography)
                }

                if TranslationPack.hasAny {
                    Section {
                        Toggle(L10n.quranShowTranslation, isOn: $prefs.showTranslation)
                        if prefs.showTranslation {
                            Picker(L10n.quranTranslation, selection: translationSelection) {
                                ForEach(TranslationPack.installed) { pack in
                                    Text(pack.title).tag(pack.id as String?)
                                }
                            }
                        }
                    } header: {
                        Text(L10n.quranTranslation)
                    }
                } else {
                    Section {
                        NavigationLink {
                            QuranTranslationGapView()
                        } label: {
                            Label(L10n.quranNoTranslationTitle, systemImage: "text.book.closed")
                                .frame(minHeight: MihrabSpace.hit)
                        }
                    } header: {
                        Text(L10n.quranTranslation)
                    }
                }
            }
            .navigationTitle(L10n.quranDisplay)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.done) { dismiss() }
                }
            }
        }
    }

    private var translationSelection: Binding<String?> {
        Binding(get: { prefs.translationPackID }, set: { prefs.translationPackID = $0 })
    }

    private var sizeRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(L10n.quranTextSize)
                Spacer()
                Text("\(Int(prefs.arabicSize))")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(MihrabColor.textSecondary)
            }
            Slider(
                value: $prefs.arabicSize,
                in: QuranReadingPreferences.arabicSizeRange,
                step: 1
            )
            .accessibilityLabel(Text(L10n.quranTextSize))
        }
        .frame(minHeight: MihrabSpace.hit)
    }

    private var spacingRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(L10n.quranLineSpacing)
                Spacer()
                Text("\(Int(prefs.lineSpacing))")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(MihrabColor.textSecondary)
            }
            Slider(
                value: $prefs.lineSpacing,
                in: QuranReadingPreferences.lineSpacingRange,
                step: 1
            )
            .accessibilityLabel(Text(L10n.quranLineSpacing))
        }
        .frame(minHeight: MihrabSpace.hit)
    }

    /// Live sample so the sliders are judged against the real face, not a
    /// number. Uses al-Fātiḥa's first ayah, loaded from the bundle like
    /// everything else — nothing here is typed by hand.
    @State private var sampleText = ""

    private var sample: some View {
        Text(sampleText)
            .font(prefs.arabicFont)
            .lineSpacing(prefs.effectiveLineSpacing)
            .foregroundStyle(prefs.mode.ink)
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .environment(\.layoutDirection, .rightToLeft)
            .padding(.vertical, 10)
            .listRowBackground(prefs.mode.background)
            .task {
                if sampleText.isEmpty {
                    sampleText = (try? await QuranTextStore.shared.basmala()) ?? ""
                }
            }
            .accessibilityHidden(true)
    }

    private func themeRow(_ theme: QuranTypeTheme) -> some View {
        Button {
            guard !theme.isPremium || subscriptions.hasAccess(to: .themes) else { return }
            HapticsEngine.shared.light()
            prefs.theme = theme
        } label: {
            HStack {
                Text(theme.localizedName)
                Spacer()
                if theme.isPremium && !subscriptions.hasAccess(to: .themes) {
                    PremiumLockBadge(compact: true)
                } else if prefs.theme == theme {
                    Image(systemName: "checkmark")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(MihrabColor.emerald)
                }
            }
            .frame(minHeight: MihrabSpace.hit)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .modifier(ThemeLockModifier(locked: theme.isPremium))
    }
}

/// Applies `.premiumRequired(.themes)` only to the locked rows, so the free
/// preset never dims.
private struct ThemeLockModifier: ViewModifier {
    let locked: Bool

    func body(content: Content) -> some View {
        if locked {
            content.premiumRequired(.themes, showsBadge: false)
        } else {
            content
        }
    }
}

// MARK: - Licence

/// Tanzil's copyright block, shown as it is published.
///
/// This screen is a licence obligation, not a nicety: CC BY 3.0 plus Tanzil's
/// own terms require the notice to travel with the text and the source to be
/// clearly indicated with a link. See `CONTENT_LICENSE.md`.
struct QuranLicenceView: View {
    @State private var notice: String?
    @State private var attribution: (source: String, url: String, license: String)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(L10n.quranLicenceIntro)
                        .font(.subheadline)
                        .foregroundStyle(MihrabColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let attribution {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(attribution.source)
                                .font(.headline)
                                .foregroundStyle(MihrabColor.textPrimary)
                            Text(attribution.license)
                                .font(.footnote)
                                .foregroundStyle(MihrabColor.textSecondary)
                            if let url = URL(string: attribution.url) {
                                Link(L10n.quranVisitSource, destination: url)
                                    .font(.footnote.weight(.semibold))
                                    .frame(minHeight: MihrabSpace.hit)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
                    }

                    if let notice {
                        Text(notice)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(MihrabColor.textSecondary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
                    } else {
                        ProgressView().frame(maxWidth: .infinity)
                    }
                }
                .padding(20)
            }
            .background(MihrabBackdrop(ramadanMode: false).ignoresSafeArea())
            .navigationTitle(L10n.quranLicenceTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.done) { dismiss() }
                }
            }
            .task {
                _ = try? await QuranTextStore.shared.load()
                notice = await QuranTextStore.shared.notice
                attribution = await QuranTextStore.shared.attribution
            }
        }
    }
}

// MARK: - Missing translation

/// The honest empty state for the meal layer.
///
/// It explains *why* there is no translation instead of showing a blank row,
/// and it never offers a generated one.
struct QuranTranslationGapView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.quranNoTranslationTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(MihrabColor.textPrimary)

                Text(L10n.quranNoTranslationBody)
                    .font(.subheadline)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.quranNoTranslationDetail)
                        .ornamentalCaps()
                    ForEach(Self.checked, id: \.self) { line in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 4))
                                .foregroundStyle(MihrabColor.brass)
                                .padding(.top, 7)
                            Text(line)
                                .font(.footnote)
                                .foregroundStyle(MihrabColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
            }
            .padding(20)
        }
        .background(MihrabBackdrop(ramadanMode: false).ignoresSafeArea())
        .navigationTitle(L10n.quranTranslation)
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Factual, checkable statements. Deliberately not softened — if any of
    /// this changes, the app's behaviour changes with it.
    private static var checked: [String] {
        L10n.language == .turkish
            ? [
                "Diyanet meali telifli; yeniden dağıtım izni yok.",
                "tanzil.net'teki bütün meallerin şartı \"yalnızca ticari olmayan kullanım\" — abonelikli bir uygulama bunu karşılayamaz.",
                "Elmalılı Hamdi Yazır 1942'de vefat etti, eseri 2013'ten beri Türkiye'de kamu malı; ancak dolaşımdaki dijital kopyalar sadeleştirilmiş, yani ayrı telifli türev eserler.",
                "Pickthall ve Yusuf Ali birçok ülkede kamu malı, ABD'de durumları belirsiz — App Store ABD'den dağıtım yapıyor."
            ]
            : [
                "The Diyanet translation is copyrighted; no redistribution licence exists.",
                "Every translation on tanzil.net is licensed for non-commercial use only, which a subscription app cannot satisfy.",
                "Elmalılı Hamdi Yazır died in 1942 and is public domain in Türkiye since 2013, but the digital copies in circulation are modernised editions — separately copyrighted derivatives.",
                "Pickthall and Yusuf Ali are public domain in many countries; their US status is unresolved, and the App Store distributes from the US."
            ]
    }
}
