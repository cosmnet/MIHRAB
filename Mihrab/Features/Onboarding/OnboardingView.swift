import CoreLocation
import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var page = 0

    private let pageCount = 5

    var body: some View {
        @Bindable var settings = settings
        ZStack {
            AuroraBackground()

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        ForEach(0..<pageCount, id: \.self) { index in
                            Capsule()
                                .fill(index <= page ? MihrabColor.brass : MihrabColor.textTertiary.opacity(0.35))
                                .frame(height: 3)
                        }
                    }

                    if page >= 1 {
                        Button(L10n.skip) { finish() }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MihrabColor.textPrimary)
                            .frame(minHeight: MihrabSpace.hit)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                TabView(selection: $page) {
                    welcomePage.tag(0)
                    locationPage.tag(1)
                    methodPage.tag(2)
                    notificationsPage.tag(3)
                    widgetTeaserPage.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? .none : MihrabMotion.standardAnimation, value: page)

                OnboardingCTA(title: ctaTitle) { ctaAction() }
                    .contentShape(Rectangle())
                    .zIndex(20)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
        }
    }

    private var ctaTitle: String {
        switch page {
        case 0: L10n.begin
        case 1: L10n.enableLocation
        case 2: L10n.continue
        case 3: L10n.enableNotifications
        default: L10n.enterMihrab
        }
    }

    private func ctaAction() {
        switch page {
        case 0:
            advance()
        case 1:
            locationManager.requestAuthorization()
            locationManager.startUpdating()
            advance()
        case 2:
            advance()
        case 3:
            Task {
                await NotificationEngine.shared.requestAuthorization()
                advance()
            }
        default:
            finish()
        }
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: 28) {
            Spacer()
            MihrabArchMark()
                .frame(height: 188)
            Text("Mihrab")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(MihrabColor.textPrimary)
            Text("بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيم")
                .font(MihrabFont.arabic(24))
                .foregroundStyle(MihrabColor.brass)
            Text(L10n.tagline)
                .font(MihrabFont.quoteItalic(20))
                .foregroundStyle(MihrabColor.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(24)
    }

    private var locationPage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "location.fill")
                .font(.system(size: 56))
                .foregroundStyle(MihrabColor.emerald)
                .symbolRenderingMode(.hierarchical)
            Text(L10n.locationTitle)
                .font(.title2.bold())
                .foregroundStyle(MihrabColor.textPrimary)
            Text(L10n.locationBody)
                .font(.body)
                .foregroundStyle(MihrabColor.textSecondary)
                .multilineTextAlignment(.center)

            if !locationManager.effectiveCityName.isEmpty {
                Label(locationManager.effectiveCityName, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(MihrabColor.mint)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .frame(minHeight: MihrabSpace.hit)
                    .background(Capsule().fill(MihrabColor.moss))
                    .overlay {
                        Capsule().strokeBorder(MihrabColor.mint.opacity(0.28), lineWidth: 1)
                    }
            } else {
                Text(L10n.locating)
                    .font(.subheadline)
                    .foregroundStyle(MihrabColor.textTertiary)
            }
            Spacer()
        }
        .padding(24)
    }

    private var methodPage: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "function")
                    .font(.system(size: 48))
                    .foregroundStyle(MihrabColor.emerald)
                    .padding(.top, 12)
                Text(L10n.calculationMethod)
                    .font(.title2.bold())
                    .foregroundStyle(MihrabColor.textPrimary)

                VStack(spacing: 8) {
                    ForEach(CalculationMethod.allCases) { method in
                        let selected = settings.calculationMethod == method
                        Button {
                            settings.calculationMethod = method
                        } label: {
                            HStack {
                                Text(method.localizedName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(MihrabColor.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                                if selected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(MihrabColor.mint)
                                }
                            }
                            .padding(.horizontal, 16).padding(.vertical, 12)
                            .frame(minHeight: MihrabSpace.hit)
                            .mihrabSolidCard(
                                cornerRadius: 16,
                                fill: selected ? MihrabColor.emerald.opacity(0.4) : MihrabColor.moss,
                                stroke: selected ? MihrabColor.mint : MihrabColor.mint.opacity(0.22)
                            )
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                    }
                }

                Picker(L10n.madhab, selection: Binding(
                    get: { settings.madhab },
                    set: { settings.madhab = $0 }
                )) {
                    ForEach(Madhab.allCases) { Text($0.localizedName).tag($0) }
                }
                .pickerStyle(.segmented)
                .colorScheme(.dark)
                .padding(.top, 4)
            }
            .padding(24)
        }
        .scrollIndicators(.hidden)
    }

    private var notificationsPage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 48))
                .foregroundStyle(MihrabColor.brass)
            Text(L10n.neverMiss)
                .font(.title2.bold())
                .foregroundStyle(MihrabColor.textPrimary)

            VStack(spacing: 8) {
                ForEach(Prayer.allCases.filter(\.isNotifiable)) { prayer in
                    Toggle(isOn: Binding(
                        get: { settings.isNotificationEnabled(for: prayer) },
                        set: { _ in settings.toggleNotification(for: prayer) }
                    )) {
                        Text(prayer.localizedName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MihrabColor.textPrimary)
                    }
                    .tint(MihrabColor.brass)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .frame(minHeight: MihrabSpace.hit)
                    .mihrabSolidCard(cornerRadius: 16)
                }
            }

            Spacer()
        }
        .padding(24)
    }

    private var widgetTeaserPage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "widget.small.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(MihrabColor.mint)
            Text(L10n.alwaysWithYou)
                .font(.title2.bold())
                .foregroundStyle(MihrabColor.textPrimary)
            Text(L10n.widgetBody)
                .font(.body)
                .foregroundStyle(MihrabColor.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(24)
    }

    // MARK: - Navigation

    private func advance() {
        HapticsEngine.shared.light()
        withAnimation(reduceMotion ? .none : MihrabMotion.snappyAnimation) {
            page = min(page + 1, pageCount - 1)
        }
    }

    private func finish() {
        HapticsEngine.shared.success()
        settings.hasCompletedOnboarding = true
    }
}

private struct OnboardingCTA: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(Capsule().fill(MihrabColor.emerald))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .zIndex(20)
    }
}
