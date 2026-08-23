import CoreLocation
import SwiftUI

/// "Where did this number come from?" — the whole answer, on one sheet.
///
/// In Turkey "the times are wrong" is the single most common complaint about
/// prayer apps, and it is almost never a bug: it is a temkin or twilight-angle
/// difference between calendar traditions. Anger comes from the silence, not
/// from the minutes. So this sheet says, plainly:
///
///   * which tradition and calculation method produced the number,
///   * which twilight angles were used,
///   * how much temkin the method already folded in,
///   * what the user's own ± correction added,
///   * whether it was computed here or fetched, and how fresh that is,
///   * and — when the two disagree — what this device would have computed.
///
/// Every field is read from `PrayerResolution` (Agent W1's model). Nothing on
/// this sheet is asserted that was not actually applied.
struct PrayerDetailSheet: View {
    let prayer: Prayer
    let day: DayPrayerTimes
    let resolution: PrayerResolution?

    @Environment(\.dismiss) private var dismiss
    @Environment(Theme.self) private var theme

    /// Live so the stepper redraws; the store is the single writer.
    private var preferences: PrayerSourcePreferences { .shared }

    @State private var offset: Int = 0
    @State private var showWhyDifferent = false

    /// Fires when the user changes anything that moves the times, so the caller
    /// can re-resolve the day and reschedule notifications.
    var onChange: () -> Void = {}

    var body: some View {
        NavigationStack {
            ZStack {
                MihrabBackdrop(surface: .times, ramadanMode: theme.isRamadanMode)

                ScrollView {
                    VStack(spacing: 16) {
                        heroHeader
                        provenanceCard
                        correctionCard
                        sourceCard
                        whyDifferentCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle(prayer.localizedNamazName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.done) { dismiss() }
                }
            }
        }
        .presentationBackground(.ultraThinMaterial)
        .presentationDetents([.large])
        .onAppear { offset = preferences.offset(for: prayer) }
    }

    // MARK: - Header

    private var heroHeader: some View {
        VStack(spacing: 6) {
            Text(prayer.arabicName)
                .font(MihrabFont.arabic(30))
                .foregroundStyle(MihrabColor.brass)

            Text(prayer.localizedName)
                .font(.headline)
                .foregroundStyle(MihrabColor.textPrimary)

            if let time = day.time(for: prayer) {
                Text(time, format: .dateTime.hour().minute())
                    .font(MihrabFont.timeDisplay(44))
                    .foregroundStyle(MihrabColor.textPrimary)
                    .contentTransition(.numericText())
            } else {
                Text("–")
                    .font(MihrabFont.timeDisplay(44))
                    .foregroundStyle(MihrabColor.textTertiary)
            }

            Text(day.date, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.caption)
                .foregroundStyle(MihrabColor.textSecondary)

            if prayer == .dhuhr, Calendar.current.component(.weekday, from: day.date) == 6 {
                Label(L10n.tmxJumuah, systemImage: "star.circle")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(MihrabColor.brass)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .mihrabSolidCard(cornerRadius: MihrabSpace.cardRadius)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Provenance

    @ViewBuilder
    private var provenanceCard: some View {
        section(L10n.tmxWhereFromTitle, caps: L10n.tmxProvenanceCaps) {
            if let resolution {
                VStack(alignment: .leading, spacing: 10) {
                    fact(L10n.tmxSourceTitle, resolution.source.localizedName)
                    fact(L10n.tmxDataCaps, resolution.originLabel)
                    fact(L10n.tmxCalculationCaps, resolution.methodName)

                    if prayer == .asr,
                       let madhab = Madhab(rawValue: resolution.madhabID) {
                        fact(L10n.madhab, madhab.localizedName)
                    }
                    if prayer == .fajr, let angle = resolution.fajrAngle {
                        fact(L10n.tmxTwilightAngle, angleText(angle))
                    }
                    if prayer == .isha {
                        if resolution.ishaIntervalMinutes > 0 {
                            fact(L10n.tmxIshaInterval,
                                 L10n.tmxCorrectionMinutes(resolution.ishaIntervalMinutes))
                        } else if let angle = resolution.ishaAngle {
                            fact(L10n.tmxTwilightAngle, angleText(angle))
                        }
                    }
                    if let rule = resolution.highLatitudeRule {
                        fact(L10n.tmxHighLatitudeRule, rule)
                    }

                    MihrabHairline()

                    Text(L10n.tmxAdjustmentsCaps).ornamentalCaps(MihrabColor.textTertiary)
                    adjustmentLines(resolution)

                    MihrabHairline()

                    Text(L10n.tmxLastUpdated(resolution.updatedAt))
                        .font(.caption2)
                        .foregroundStyle(MihrabColor.textTertiary)
                }
            } else {
                Text(L10n.tmxResolutionUnavailable)
                    .font(.footnote)
                    .foregroundStyle(MihrabColor.textTertiary)
            }
        }
    }

    @ViewBuilder
    private func adjustmentLines(_ resolution: PrayerResolution) -> some View {
        let temkin = resolution.temkinMinutes[prayer] ?? 0
        let userOffset = resolution.userOffsetMinutes[prayer] ?? 0

        if temkin == 0 && userOffset == 0 {
            Text(L10n.tmxNoAdjustments)
                .font(.caption)
                .foregroundStyle(MihrabColor.textSecondary)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                if temkin != 0 {
                    fact(resolution.temkinIsDiyanet ? L10n.tmxTemkin : L10n.tmxMethodAdjustment,
                         L10n.tmxCorrectionMinutes(temkin),
                         tint: MihrabColor.brass)
                }
                if userOffset != 0 {
                    fact(L10n.tmxYourCorrectionCaps,
                         L10n.tmxCorrectionMinutes(userOffset),
                         tint: MihrabColor.mint)
                }
            }
        }
    }

    private func angleText(_ angle: Double) -> String {
        String(format: "%.1f°", angle)
    }

    // MARK: - User correction

    private var correctionCard: some View {
        section(L10n.tmxCorrectionTitle, caps: L10n.tmxYourCorrectionCaps) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    stepperButton(symbol: "minus", label: L10n.tmxDecreaseMinute) {
                        apply(offset - 1)
                    }
                    .disabled(offset <= PrayerSourcePreferences.offsetRange.lowerBound)

                    Text(offset == 0 ? L10n.tmxCorrectionNone : L10n.tmxCorrectionMinutes(offset))
                        .font(.title3.weight(.semibold).monospacedDigit())
                        .foregroundStyle(offset == 0 ? MihrabColor.textSecondary : MihrabColor.mint)
                        .frame(maxWidth: .infinity)
                        .contentTransition(.numericText())

                    stepperButton(symbol: "plus", label: L10n.tmxIncreaseMinute) {
                        apply(offset + 1)
                    }
                    .disabled(offset >= PrayerSourcePreferences.offsetRange.upperBound)
                }

                if offset != 0 {
                    Button(L10n.tmxResetCorrection) { apply(0) }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(theme.accent)
                        .frame(minHeight: MihrabSpace.hit)
                }

                Text(L10n.tmxCorrectionFooter)
                    .font(.caption)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func stepperButton(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(MihrabColor.textPrimary)
                .frame(width: MihrabSpace.hit, height: MihrabSpace.hit)
                .background(Circle().fill(MihrabColor.moss))
                .overlay { Circle().strokeBorder(MihrabColor.mint.opacity(0.3), lineWidth: 1) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }

    private func apply(_ minutes: Int) {
        let clamped = min(max(minutes, PrayerSourcePreferences.offsetRange.lowerBound),
                          PrayerSourcePreferences.offsetRange.upperBound)
        guard clamped != offset else { return }
        withAnimation(MihrabMotion.snappyAnimation) { offset = clamped }
        preferences.setOffset(clamped, for: prayer)
        HapticsEngine.shared.light()
        onChange()
    }

    // MARK: - Source shortcut

    private var sourceCard: some View {
        section(L10n.tmxSourceTitle, caps: L10n.tmxTraditionCaps) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(PrayerSource.allCases) { candidate in
                    let selected = candidate == preferences.source
                    Button {
                        guard !selected else { return }
                        preferences.source = candidate
                        HapticsEngine.shared.light()
                        onChange()
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                                .font(.body)
                                .foregroundStyle(selected ? theme.accent : MihrabColor.textTertiary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(candidate.localizedName)
                                    .font(.subheadline.weight(selected ? .semibold : .regular))
                                    .foregroundStyle(MihrabColor.textPrimary)
                                Text(candidate.localizedExplanation)
                                    .font(.caption)
                                    .foregroundStyle(MihrabColor.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 8)
                        .frame(minHeight: MihrabSpace.hit)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
                }
            }
        }
    }

    // MARK: - Honest explainer

    private var whyDifferentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(MihrabMotion.standardAnimation) { showWhyDifferent.toggle() }
            } label: {
                HStack {
                    Text(L10n.tmxWhyDifferentTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MihrabColor.textPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 8)
                    Image(systemName: showWhyDifferent ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MihrabColor.textSecondary)
                }
                .frame(minHeight: MihrabSpace.hit)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showWhyDifferent {
                Text(L10n.tmxWhyDifferentBody)
                    .font(.footnote)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .offset(y: -6)))
            }
        }
        .padding(16)
        .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
    }

    // MARK: - Building blocks

    private func section<Content: View>(_ title: String,
                                        caps: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(caps).ornamentalCaps()
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MihrabColor.textPrimary)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
    }

    private func fact(_ label: String, _ value: String,
                      tint: Color = MihrabColor.textPrimary) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label)
                .font(.caption)
                .foregroundStyle(MihrabColor.textSecondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.footnote.weight(.medium))
                .foregroundStyle(tint)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }
}
