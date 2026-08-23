import StoreKit
import SwiftUI

/// Mihrab Plus paywall — Emerald Glass, calm, honest.
///
/// Deliberately *not* a dark-pattern paywall: the close button is always
/// visible from the first frame, the free tier is named out loud, the price and
/// renewal terms sit directly under the CTA, and nothing counts down.
struct PaywallView: View {
    let source: PaywallSource

    init(source: PaywallSource = .settings) {
        self.source = source
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL

    @State private var subscriptions = SubscriptionManager.shared
    @State private var selection: MihrabProduct = .yearly
    @State private var appeared = false
    @State private var haloPhase: CGFloat = 0
    @State private var isWorking = false
    @State private var didSucceed = false
    @State private var errorMessage: String?

    /// ⚠️ **Placeholder.** Guideline 3.1.2 requires a *functioning* privacy
    /// policy link on the paywall. The owner must publish the policy and put
    /// the real URL here before submission — this domain is not live yet.
    private static let privacyURL = URL(string: "https://mihrab.app/privacy")!
    private static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    var body: some View {
        ZStack {
            MihrabBackdrop()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: MihrabSpace.unit * 3) {
                    hero
                    statusBanner
                    benefits
                    planCards
                    callToAction
                    subscriptionTerms
                    footer
                }
                .padding(.horizontal, MihrabSpace.unit * 2.5)
                .padding(.top, MihrabSpace.unit * 2)
                .padding(.bottom, MihrabSpace.unit * 5)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)

            if didSucceed { thankYouOverlay }
        }
        .overlay(alignment: .topTrailing) { closeButton }
        .task {
            await subscriptions.refresh()
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : MihrabMotion.standardAnimation) {
                appeared = true
            }
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 14).repeatForever(autoreverses: true)) {
                haloPhase = 1
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: MihrabSpace.unit * 1.5) {
            ZStack {
                // Breathing halo — a lamp behind an arch, not a marketing splash.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                MihrabColor.emerald.opacity(0.45),
                                MihrabColor.emerald.opacity(0.06),
                                .clear,
                            ],
                            center: .center,
                            startRadius: 4,
                            endRadius: 130
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(reduceMotion ? 1 : 0.92 + 0.12 * haloPhase)
                    .blur(radius: 12)

                MihrabArchGlyph()
                    .stroke(
                        LinearGradient(
                            colors: [MihrabColor.brass, MihrabColor.mint.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: 108, height: 132)
                    .opacity(0.9)

                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(MihrabColor.brass)
                    .offset(y: -46)
                    .opacity(reduceMotion ? 0.8 : 0.55 + 0.4 * haloPhase)
            }
            .frame(height: 190)
            .accessibilityHidden(true)

            Text(L10n.paywallTitle)
                .ornamentalCaps()

            Text(L10n.paywallHeadline)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(MihrabColor.textPrimary)
                .multilineTextAlignment(.center)

            Text(L10n.paywallSubtitle)
                .font(.subheadline)
                .foregroundStyle(MihrabColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MihrabSpace.unit)
        }
        .cardEntrance(index: 0, appeared: appeared, reduceMotion: reduceMotion)
    }

    // MARK: - Benefits

    private struct Benefit: Identifiable {
        var id: String { icon }
        let icon: String
        let title: String
        let body: String
    }

    private var benefitList: [Benefit] {
        [
            Benefit(icon: "square.grid.2x2.fill", title: L10n.paywallBenefitWidgetsTitle, body: L10n.paywallBenefitWidgetsBody),
            Benefit(icon: "paintpalette.fill", title: L10n.paywallBenefitThemesTitle, body: L10n.paywallBenefitThemesBody),
            Benefit(icon: "circle.hexagongrid.fill", title: L10n.paywallBenefitDhikrTitle, body: L10n.paywallBenefitDhikrBody),
            Benefit(icon: "book.closed.fill", title: L10n.paywallBenefitEsmaTitle, body: L10n.paywallBenefitEsmaBody),
            Benefit(icon: "moon.stars.fill", title: L10n.paywallBenefitRamadanTitle, body: L10n.paywallBenefitRamadanBody),
            Benefit(icon: "icloud.fill", title: L10n.paywallBenefitCitiesTitle, body: L10n.paywallBenefitCitiesBody),
        ]
    }

    private var benefits: some View {
        VStack(spacing: MihrabSpace.unit * 1.75) {
            // Guideline 3.1.2: say what the subscription actually provides.
            Text(L10n.paywallIncludedHeading)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(MihrabColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Array(benefitList.enumerated()), id: \.element.id) { index, benefit in
                HStack(alignment: .top, spacing: MihrabSpace.unit * 1.75) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(MihrabColor.emerald.opacity(0.18))
                        Image(systemName: benefit.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(MihrabColor.mint)
                    }
                    .frame(width: 38, height: 38)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(benefit.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(MihrabColor.textPrimary)
                        Text(benefit.body)
                            .font(.footnote)
                            .foregroundStyle(MihrabColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .cardEntrance(index: index + 1, appeared: appeared, reduceMotion: reduceMotion)
            }

            // In flow, not an overlay: as an overlay it sat on top of the last row.
            Text(L10n.paywallFreeForeverNote)
                .font(.caption2)
                .foregroundStyle(MihrabColor.brass.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
        }
        .padding(MihrabSpace.unit * 2.25)
        .mihrabCard(cornerRadius: MihrabSpace.cardRadius)
    }

    // MARK: - Plans

    private var planCards: some View {
        VStack(spacing: MihrabSpace.unit * 1.25) {
            ForEach(MihrabProduct.displayOrder) { product in
                PlanCard(
                    product: product,
                    isSelected: selection == product,
                    priceText: subscriptions.displayPrice(for: product),
                    periodText: periodText(for: product),
                    detailText: detailText(for: product),
                    badgeText: badgeText(for: product),
                    reduceMotion: reduceMotion
                ) {
                    guard selection != product else { return }
                    HapticsEngine.shared.light()
                    withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : MihrabMotion.snappyAnimation) {
                        selection = product
                    }
                }
            }
        }
        .cardEntrance(index: 6, appeared: appeared, reduceMotion: reduceMotion)
    }

    private func periodText(for product: MihrabProduct) -> String {
        switch product {
        case .monthly: L10n.paywallPeriodMonth
        case .yearly: L10n.paywallPeriodYear
        case .lifetime: L10n.paywallPeriodOnce
        }
    }

    private func detailText(for product: MihrabProduct) -> String? {
        switch product {
        case .yearly:
            subscriptions.monthlyEquivalentPrice(for: .yearly).map(L10n.paywallMonthlyEquivalent)
        case .lifetime:
            L10n.paywallLifetimeNote
        case .monthly:
            nil
        }
    }

    private func badgeText(for product: MihrabProduct) -> String? {
        guard product == .yearly else { return nil }
        if let percent = subscriptions.yearlySavingsPercent, percent >= 5 {
            return L10n.paywallSaveBadge(percent)
        }
        return L10n.paywallMostPopular
    }

    // MARK: - CTA

    /// StoreKit itself carries a free introductory period for this SKU.
    private var storeOffersTrial: Bool {
        guard let offer = subscriptions.storeIntroOffer(for: selection) else { return false }
        return offer.paymentMode == .freeTrial
    }

    /// No store offer available (products unconfigured, or already used) —
    /// we can still grant the local, card-free week.
    private var localTrialAvailable: Bool {
        selection.isSubscription && !subscriptions.hasStartedTrial && !subscriptions.hasPaidEntitlement
    }

    private var offersTrial: Bool {
        selection.isSubscription && (storeOffersTrial || localTrialAvailable)
    }

    private var ctaTitle: String {
        if selection == .lifetime { return L10n.paywallBuyLifetime }
        return offersTrial ? L10n.paywallStartTrial : L10n.paywallSubscribeNow
    }

    private var callToAction: some View {
        VStack(spacing: MihrabSpace.unit) {
            Button(action: primaryAction) {
                ZStack {
                    if isWorking {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(MihrabColor.abyss)
                    } else {
                        Text(ctaTitle)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                    }
                }
                .frame(maxWidth: .infinity, minHeight: MihrabSpace.hit + 8)
                .foregroundStyle(MihrabColor.abyss)
                .background {
                    RoundedRectangle(cornerRadius: MihrabSpace.pillRadius + 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [MihrabColor.sprout, MihrabColor.mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .pressable(reduceMotion)
            .disabled(isWorking)
            .accessibilityLabel(ctaTitle)

            Text(footnote)
                .font(.caption2)
                .foregroundStyle(MihrabColor.textSecondary)
                .multilineTextAlignment(.center)

            if offersTrial {
                Label(L10n.paywallReminderNote, systemImage: "bell.badge")
                    .font(.caption2)
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(MihrabColor.textTertiary)
                    .multilineTextAlignment(.center)
            }

            if subscriptions.isStoreUnavailable {
                Text(L10n.paywallIndicativePriceNote)
                    .font(.caption2)
                    .foregroundStyle(MihrabColor.textTertiary)
                    .multilineTextAlignment(.center)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(MihrabColor.danger)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
        }
        .cardEntrance(index: 7, appeared: appeared, reduceMotion: reduceMotion)
    }

    private var footnote: String {
        let price = subscriptions.displayPrice(for: selection)
        let period = periodText(for: selection)
        if selection == .lifetime {
            return L10n.paywallDirectFootnote(price, period: period)
        }
        return offersTrial
            ? L10n.paywallTrialFootnote(price, period: period)
            : L10n.paywallDirectFootnote(price, period: period)
    }

    // MARK: - Status banner

    /// Honest current state: days left in the free week, or — once it has run
    /// out — a plain statement that nothing was deleted.
    @ViewBuilder
    private var statusBanner: some View {
        if subscriptions.hasPaidEntitlement {
            banner(icon: "checkmark.seal.fill", title: L10n.paywallAlreadyMember, body: nil)
        } else if subscriptions.isInTrial {
            banner(
                icon: "hourglass",
                title: L10n.paywallTrialDaysLeft(subscriptions.trialDaysRemaining),
                body: nil
            )
        } else if subscriptions.trialHasExpired {
            banner(
                icon: "lock.open.trianglebadge.exclamationmark",
                title: L10n.paywallTrialEndedTitle,
                body: L10n.paywallTrialEndedBody
            )
        }
    }

    private func banner(icon: String, title: String, body: String?) -> some View {
        HStack(alignment: .top, spacing: MihrabSpace.unit * 1.5) {
            Image(systemName: icon)
                .foregroundStyle(MihrabColor.brass)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(MihrabColor.textPrimary)
                if let body {
                    Text(body)
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(MihrabSpace.unit * 1.75)
        .mihrabCard(cornerRadius: MihrabSpace.rowRadius)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Subscription terms (Guideline 3.1.2 / Schedule 2 §3.8(b))

    private var durationText: String {
        switch selection {
        case .yearly: L10n.paywallDurationYear
        case .monthly: L10n.paywallDurationMonth
        case .lifetime: L10n.paywallDurationLifetime
        }
    }

    private var subscriptionTerms: some View {
        VStack(alignment: .leading, spacing: MihrabSpace.unit) {
            Text(L10n.paywallTermsHeading)
                .font(.caption.weight(.semibold))
                .foregroundStyle(MihrabColor.textSecondary)

            // Name · length · price, then the auto-renewal statement.
            Text(termsBody)
                .font(.caption2)
                .foregroundStyle(MihrabColor.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            if offersTrial, selection.isSubscription {
                Text(L10n.paywallTrialTerms(
                    price: subscriptions.displayPrice(for: selection),
                    duration: durationText
                ))
                .font(.caption2)
                .foregroundStyle(MihrabColor.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MihrabSpace.unit * 1.75)
        .mihrabCard(cornerRadius: MihrabSpace.rowRadius)
        .accessibilityElement(children: .combine)
        .cardEntrance(index: 8, appeared: appeared, reduceMotion: reduceMotion)
    }

    private var termsBody: String {
        let name = "\(L10n.paywallTitle) · \(planName(for: selection))"
        let price = subscriptions.displayPrice(for: selection)
        if selection == .lifetime {
            return L10n.paywallLifetimeTerms(name: name, price: price)
        }
        return L10n.paywallSubscriptionTerms(name: name, duration: durationText, price: price)
    }

    private func planName(for product: MihrabProduct) -> String {
        switch product {
        case .monthly: L10n.paywallPlanMonthly
        case .yearly: L10n.paywallPlanYearly
        case .lifetime: L10n.paywallPlanLifetime
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: MihrabSpace.unit * 1.25) {
            Button(L10n.paywallRestore) {
                Task {
                    isWorking = true
                    await subscriptions.restore()
                    isWorking = false
                    if subscriptions.hasPaidEntitlement {
                        HapticsEngine.shared.success()
                        showThankYou()
                    } else {
                        setError(subscriptions.lastError)
                    }
                }
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(MihrabColor.mint)

            HStack(spacing: MihrabSpace.unit * 2) {
                Button(L10n.paywallPrivacy) { openURL(Self.privacyURL) }
                Text("·").foregroundStyle(MihrabColor.textTertiary)
                Button(L10n.paywallTerms) { openURL(Self.termsURL) }
            }
            .font(.caption2)
            .foregroundStyle(MihrabColor.textTertiary)

            if source == .onboarding {
                Button(L10n.paywallNotNow) { dismiss() }
                    .font(.footnote)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .frame(minHeight: MihrabSpace.hit)
            }
        }
        .cardEntrance(index: 9, appeared: appeared, reduceMotion: reduceMotion)
    }

    private var closeButton: some View {
        Button {
            HapticsEngine.shared.light()
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(MihrabColor.textSecondary)
                .frame(width: MihrabSpace.hit, height: MihrabSpace.hit)
                .background {
                    Circle().fill(MihrabColor.moss.opacity(0.85))
                }
        }
        .padding(.trailing, MihrabSpace.unit * 2)
        .padding(.top, MihrabSpace.unit)
        .accessibilityLabel(L10n.paywallClose)
    }

    // MARK: - Thank you

    private var thankYouOverlay: some View {
        ZStack {
            MihrabColor.abyss.opacity(0.86).ignoresSafeArea()
            VStack(spacing: MihrabSpace.unit * 1.5) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 46, weight: .light))
                    .foregroundStyle(MihrabColor.brass)
                Text(L10n.paywallThankYouTitle)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(MihrabColor.textPrimary)
                Text(L10n.paywallThankYouBody)
                    .font(.footnote)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(MihrabSpace.unit * 4)
            .mihrabCard()
            .padding(.horizontal, MihrabSpace.unit * 5)
        }
        .transition(.opacity)
    }

    // MARK: - Actions

    private func primaryAction() {
        errorMessage = nil
        // When the App Store carries the introductory offer, let Apple run the
        // free week — it is the flow people can cancel from Settings.
        if !storeOffersTrial, localTrialAvailable {
            // Local trial: no charge, no card, nothing to undo later.
            subscriptions.startFreeTrial()
            HapticsEngine.shared.success()
            showThankYou()
            return
        }
        Task {
            isWorking = true
            let outcome = await subscriptions.purchase(selection)
            isWorking = false
            switch outcome {
            case .success:
                HapticsEngine.shared.success()
                showThankYou()
            case .cancelled, .pending:
                break
            case .failed(let message):
                HapticsEngine.shared.warning()
                setError(message)
            }
        }
    }

    private func setError(_ message: String?) {
        withAnimation(.easeInOut(duration: 0.2)) { errorMessage = message }
    }

    private func showThankYou() {
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : MihrabMotion.standardAnimation) {
            didSucceed = true
        }
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            dismiss()
        }
    }
}

// MARK: - Plan card

private struct PlanCard: View {
    let product: MihrabProduct
    let isSelected: Bool
    let priceText: String
    let periodText: String
    let detailText: String?
    let badgeText: String?
    let reduceMotion: Bool
    let action: () -> Void

    private var title: String {
        switch product {
        case .monthly: L10n.paywallPlanMonthly
        case .yearly: L10n.paywallPlanYearly
        case .lifetime: L10n.paywallPlanLifetime
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: MihrabSpace.unit * 1.5) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? MihrabColor.mint : MihrabColor.textTertiary.opacity(0.6),
                            lineWidth: isSelected ? 6 : 1.5
                        )
                        .frame(width: 22, height: 22)
                }
                .frame(width: 26, height: 26)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MihrabColor.textPrimary)
                    if let detailText {
                        Text(detailText)
                            .font(.caption2)
                            .foregroundStyle(MihrabColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: MihrabSpace.unit)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(priceText)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(MihrabColor.textPrimary)
                    Text(periodText)
                        .font(.caption2)
                        .foregroundStyle(MihrabColor.textTertiary)
                }
            }
            .padding(.vertical, MihrabSpace.unit * 1.75)
            .padding(.horizontal, MihrabSpace.unit * 2)
            .frame(minHeight: MihrabSpace.hit + 18)
            .background {
                RoundedRectangle(cornerRadius: MihrabSpace.rowRadius, style: .continuous)
                    .fill(isSelected ? MihrabColor.emerald.opacity(0.16) : MihrabColor.moss.opacity(0.55))
            }
            .overlay {
                RoundedRectangle(cornerRadius: MihrabSpace.rowRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? MihrabColor.mint.opacity(0.9) : MihrabColor.mint.opacity(0.18),
                        lineWidth: isSelected ? 1.6 : 1
                    )
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .topTrailing) {
                if let badgeText {
                    Text(badgeText)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(MihrabColor.abyss)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background {
                            Capsule().fill(MihrabColor.brass)
                        }
                        .offset(x: -10, y: -9)
                }
            }
            .scaleEffect(isSelected && !reduceMotion ? 1.015 : 1)
            .animation(
                reduceMotion ? .easeInOut(duration: 0.15) : MihrabMotion.snappyAnimation,
                value: isSelected
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Arch glyph

/// A simple mihrab arch outline, drawn rather than shipped as an asset.
private struct MihrabArchGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let shoulder = height * 0.42

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + shoulder))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control1: CGPoint(x: rect.minX, y: rect.minY + shoulder * 0.34),
            control2: CGPoint(x: rect.midX - width * 0.30, y: rect.minY)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + shoulder),
            control1: CGPoint(x: rect.midX + width * 0.30, y: rect.minY),
            control2: CGPoint(x: rect.maxX, y: rect.minY + shoulder * 0.34)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))

        // Inner arch, offset inwards.
        let inset = width * 0.18
        let inner = rect.insetBy(dx: inset, dy: 0)
        let innerShoulder = shoulder * 0.92
        path.move(to: CGPoint(x: inner.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: inner.minX, y: rect.minY + inset + innerShoulder))
        path.addCurve(
            to: CGPoint(x: inner.midX, y: rect.minY + inset),
            control1: CGPoint(x: inner.minX, y: rect.minY + inset + innerShoulder * 0.34),
            control2: CGPoint(x: inner.midX - inner.width * 0.30, y: rect.minY + inset)
        )
        path.addCurve(
            to: CGPoint(x: inner.maxX, y: rect.minY + inset + innerShoulder),
            control1: CGPoint(x: inner.midX + inner.width * 0.30, y: rect.minY + inset),
            control2: CGPoint(x: inner.maxX, y: rect.minY + inset + innerShoulder * 0.34)
        )
        path.addLine(to: CGPoint(x: inner.maxX, y: rect.maxY))
        return path
    }
}

#Preview {
    PaywallView(source: .settings)
}
