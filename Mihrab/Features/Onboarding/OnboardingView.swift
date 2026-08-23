import CoreLocation
import SwiftUI
import UserNotifications

/// Seven-step first run: welcome → name → location → method → notifications →
/// feature tour → Mihrab Plus. Every step is skippable, every step is reversible,
/// and Reduce Motion collapses the spring page slide into a plain cross-fade.
struct OnboardingView: View {
    enum Step: Int, CaseIterable, Identifiable {
        case welcome, name, location, method, notifications, tour, plus
        var id: Int { rawValue }
    }

    @Environment(AppSettings.self) private var settings
    @Environment(LocationManager.self) private var locationManager
    @Environment(PrayerTimesRepository.self) private var repository
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var step: Step = .welcome
    @State private var movingBack = false
    @State private var name = ""
    @State private var notificationsGranted: Bool?
    @State private var showCityPicker = false
    @State private var showPaywall = false
    @FocusState private var nameFocused: Bool

    private var stepCount: Int { Step.allCases.count }

    var body: some View {
        ZStack {
            MihrabBackdrop(surface: .sheet)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                pages
                footer
            }
        }
        .onAppear { name = settings.userName }
        .sheet(isPresented: $showCityPicker) {
            ManualCityPicker { city in
                apply(city)
            }
        }
        .fullScreenCover(isPresented: $showPaywall, onDismiss: { finish() }) {
            PaywallView(source: .onboarding)
        }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack(spacing: 14) {
            Button {
                back()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(MihrabColor.textSecondary)
                    .frame(width: MihrabSpace.hit, height: MihrabSpace.hit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(step == .welcome ? 0 : 1)
            .disabled(step == .welcome)
            .accessibilityLabel(L10n.obBack)

            HStack(spacing: 5) {
                ForEach(Step.allCases) { entry in
                    Capsule()
                        .fill(entry.rawValue <= step.rawValue ? MihrabColor.brass : MihrabColor.textTertiary.opacity(0.32))
                        .frame(height: 3)
                }
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : MihrabMotion.standardAnimation, value: step)
            .accessibilityElement()
            .accessibilityLabel(String(format: L10n.obStepFormat, step.rawValue + 1, stepCount))

            Button(L10n.skip) { finish() }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MihrabColor.textSecondary)
                .frame(minWidth: MihrabSpace.hit, minHeight: MihrabSpace.hit)
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .opacity(step == .welcome ? 0 : 1)
                .disabled(step == .welcome)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
    }

    private var pages: some View {
        ZStack {
            switch step {
            case .welcome: welcomePage.transition(pageTransition)
            case .name: namePage.transition(pageTransition)
            case .location: locationPage.transition(pageTransition)
            case .method: methodPage.transition(pageTransition)
            case .notifications: notificationsPage.transition(pageTransition)
            case .tour: tourPage.transition(pageTransition)
            case .plus: plusPage.transition(pageTransition)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private var pageTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        let insertion: Edge = movingBack ? .leading : .trailing
        let removal: Edge = movingBack ? .trailing : .leading
        return .asymmetric(
            insertion: .move(edge: insertion).combined(with: .opacity),
            removal: .move(edge: removal).combined(with: .opacity)
        )
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Button {
                primaryAction()
            } label: {
                Text(primaryTitle)
                    .font(.headline)
                    .foregroundStyle(MihrabColor.abyss)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 54)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                colors: [MihrabColor.mint, MihrabColor.emerald],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .contentTransition(.opacity)

            if let secondary = secondaryTitle {
                Button(secondary) { secondaryAction() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MihrabColor.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: MihrabSpace.hit)
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .animation(reduceMotion ? nil : MihrabMotion.snappyAnimation, value: step)
    }

    // MARK: - Actions

    private var primaryTitle: String {
        switch step {
        case .welcome: L10n.obWelcomeCTA
        case .name: name.trimmingCharacters(in: .whitespaces).isEmpty ? L10n.obNameSkip : L10n.obNext
        case .location: locationAuthorized ? L10n.obNext : L10n.obAllowLocationNow
        case .method: L10n.obNext
        case .notifications: notificationsGranted == nil ? L10n.enableNotifications : L10n.obNext
        case .tour: L10n.obNext
        case .plus: L10n.obPlusSeeOptions
        }
    }

    private var secondaryTitle: String? {
        switch step {
        case .location: L10n.obChooseCity
        case .plus: L10n.obPlusLater
        default: nil
        }
    }

    private func primaryAction() {
        switch step {
        case .welcome:
            advance()
        case .name:
            settings.userName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            nameFocused = false
            advance()
        case .location:
            if !locationAuthorized {
                locationManager.requestAuthorization()
                locationManager.startUpdating()
            }
            advance()
        case .method:
            advance()
        case .notifications:
            if notificationsGranted == nil {
                Task {
                    let granted = await NotificationEngine.shared.requestAuthorization()
                    withAnimation(reduceMotion ? nil : MihrabMotion.standardAnimation) {
                        notificationsGranted = granted
                    }
                    if granted { HapticsEngine.shared.success() } else { HapticsEngine.shared.warning() }
                }
            } else {
                advance()
            }
        case .tour:
            advance()
        case .plus:
            HapticsEngine.shared.light()
            showPaywall = true
        }
    }

    private func secondaryAction() {
        switch step {
        case .location:
            HapticsEngine.shared.light()
            showCityPicker = true
        case .plus:
            finish()
        default:
            break
        }
    }

    private var locationAuthorized: Bool {
        locationManager.authorizationStatus == .authorizedWhenInUse
            || locationManager.authorizationStatus == .authorizedAlways
            || settings.manualCityName != nil
    }

    private func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else {
            finish()
            return
        }
        HapticsEngine.shared.light()
        movingBack = false
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : MihrabMotion.standardAnimation) {
            step = next
        }
    }

    private func back() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        HapticsEngine.shared.light()
        movingBack = true
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : MihrabMotion.standardAnimation) {
            step = previous
        }
    }

    private func apply(_ city: OnboardingCity) {
        settings.manualCityName = city.name
        settings.manualLatitude = city.latitude
        settings.manualLongitude = city.longitude
        Task { await repository.refresh() }
    }

    private func finish() {
        HapticsEngine.shared.success()
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { settings.userName = trimmed }
        settings.hasCompletedOnboarding = true
        Task {
            await repository.refresh()
            await NotificationEngine.shared.rescheduleAll()
        }
    }

    // MARK: - 1 · Welcome

    private var welcomePage: some View {
        OnboardingScaffold {
            VStack(spacing: 26) {
                Spacer(minLength: 0)
                MihrabArchMark()
                    .frame(height: 188)
                VStack(spacing: 10) {
                    Text("Mihrab")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(MihrabColor.textPrimary)
                    Text("بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيم")
                        .font(MihrabFont.arabic(22))
                        .foregroundStyle(MihrabColor.brass)
                }
                Text(L10n.obWelcomeBody)
                    .font(MihrabFont.quote(18))
                    .foregroundStyle(MihrabColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - 2 · Name

    private var namePage: some View {
        OnboardingScaffold {
            VStack(spacing: 22) {
                Spacer(minLength: 0)
                OnboardingHeadline(
                    systemImage: "person.crop.circle",
                    tint: MihrabColor.mint,
                    title: L10n.obNameTitle,
                    message: L10n.obNameBody
                )

                TextField(L10n.obNamePlaceholder, text: $name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($nameFocused)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(MihrabColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 56)
                    .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
                    .onSubmit { primaryAction() }

                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                Text(trimmed.isEmpty ? " " : L10n.obNameGreeting(trimmed))
                    .font(MihrabFont.quoteItalic(17))
                    .foregroundStyle(MihrabColor.brass)
                    .animation(reduceMotion ? nil : MihrabMotion.gentleAnimation, value: trimmed)

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - 3 · Location

    private var locationPage: some View {
        OnboardingScaffold {
            VStack(spacing: 20) {
                Spacer(minLength: 0)
                OnboardingHeadline(
                    systemImage: "location.fill",
                    tint: MihrabColor.emerald,
                    title: L10n.obLocationTitle,
                    message: L10n.obLocationBody
                )

                VStack(alignment: .leading, spacing: 12) {
                    OnboardingBullet(text: L10n.obLocationPoint1)
                    OnboardingBullet(text: L10n.obLocationPoint2)
                    OnboardingBullet(text: L10n.obLocationPoint3)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .mihrabSolidCard(cornerRadius: MihrabSpace.cardRadius)

                if !locationManager.effectiveCityName.isEmpty {
                    Label(locationManager.effectiveCityName, systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MihrabColor.mint)
                        .padding(.horizontal, 16)
                        .frame(minHeight: MihrabSpace.hit)
                        .background(Capsule().fill(MihrabColor.moss))
                        .overlay { Capsule().strokeBorder(MihrabColor.mint.opacity(0.28), lineWidth: 1) }
                        .transition(.scale.combined(with: .opacity))
                } else if locationManager.authorizationStatus == .denied
                    || locationManager.authorizationStatus == .restricted {
                    Text(L10n.obLocationDenied)
                        .font(.footnote)
                        .foregroundStyle(MihrabColor.textSecondary)
                        .multilineTextAlignment(.center)
                } else if locationAuthorized {
                    Text(L10n.locating)
                        .font(.footnote)
                        .foregroundStyle(MihrabColor.textTertiary)
                }

                Spacer(minLength: 0)
            }
            .animation(
                reduceMotion ? nil : MihrabMotion.standardAnimation,
                value: locationManager.effectiveCityName
            )
        }
    }

    // MARK: - 4 · Method

    private var methodPage: some View {
        @Bindable var settings = settings
        return OnboardingScaffold {
            VStack(spacing: 18) {
                OnboardingHeadline(
                    systemImage: "sun.horizon.fill",
                    tint: MihrabColor.brass,
                    title: L10n.obMethodTitle,
                    message: L10n.obMethodBody
                )

                VStack(spacing: 8) {
                    ForEach(CalculationMethod.allCases) { method in
                        methodRow(method, selected: settings.calculationMethod == method)
                    }
                }

                VStack(spacing: 8) {
                    Picker(L10n.madhab, selection: $settings.madhab) {
                        ForEach(Madhab.allCases) { Text($0.localizedName).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .colorScheme(.dark)

                    Text(L10n.obMadhabHint)
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textTertiary)
                }
                .padding(.top, 4)
            }
        }
    }

    private func methodRow(_ method: CalculationMethod, selected: Bool) -> some View {
        Button {
            HapticsEngine.shared.light()
            withAnimation(reduceMotion ? nil : MihrabMotion.snappyAnimation) {
                settings.calculationMethod = method
            }
        } label: {
            HStack(spacing: 10) {
                Text(method.localizedName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MihrabColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                if method == recommendedMethod {
                    Text(L10n.obRecommended)
                        .font(.system(size: 10, weight: .bold))
                        .textCase(.uppercase)
                        .foregroundStyle(MihrabColor.abyss)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(MihrabColor.brass))
                }

                Spacer(minLength: 0)

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? MihrabColor.mint : MihrabColor.textTertiary)
                    .symbolEffect(.bounce, value: selected)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: MihrabSpace.hit)
            .mihrabSolidCard(
                cornerRadius: MihrabSpace.rowRadius,
                fill: selected ? MihrabColor.emerald.opacity(0.34) : MihrabColor.moss,
                stroke: selected ? MihrabColor.mint : MihrabColor.mint.opacity(0.2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private var recommendedMethod: CalculationMethod {
        L10n.isTurkish || Locale.autoupdatingCurrent.region?.identifier == "TR" ? .diyanet : .mwl
    }

    // MARK: - 5 · Notifications

    private var notificationsPage: some View {
        OnboardingScaffold {
            VStack(spacing: 18) {
                OnboardingHeadline(
                    systemImage: "bell.badge.fill",
                    tint: MihrabColor.brass,
                    title: L10n.obNotificationsTitle,
                    message: L10n.obNotificationsBody
                )

                VStack(spacing: 8) {
                    ForEach(Prayer.allCases.filter(\.isNotifiable)) { prayer in
                        Toggle(isOn: Binding(
                            get: { settings.isNotificationEnabled(for: prayer) },
                            set: { _ in
                                HapticsEngine.shared.light()
                                settings.toggleNotification(for: prayer)
                            }
                        )) {
                            Text(prayer.localizedName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MihrabColor.textPrimary)
                        }
                        .tint(MihrabColor.emerald)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(minHeight: MihrabSpace.hit)
                        .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
                    }
                }

                if let granted = notificationsGranted {
                    Label(
                        granted ? L10n.obNotificationsGranted : L10n.obNotificationsDenied,
                        systemImage: granted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                    )
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(granted ? MihrabColor.mint : MihrabColor.brass)
                    .multilineTextAlignment(.leading)
                    .transition(.opacity)
                }
            }
        }
    }

    // MARK: - 6 · Feature tour

    private var tourPage: some View {
        OnboardingScaffold {
            VStack(spacing: 16) {
                Text(L10n.obTourTitle)
                    .font(.title2.bold())
                    .foregroundStyle(MihrabColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 4)

                OnboardingFeatureCard(
                    systemImage: "clock.badge.checkmark.fill",
                    tint: MihrabColor.mint,
                    title: L10n.obTourTimesTitle,
                    message: L10n.obTourTimesBody
                )
                OnboardingFeatureCard(
                    systemImage: "location.north.circle.fill",
                    tint: MihrabColor.emerald,
                    title: L10n.obTourQiblaTitle,
                    message: L10n.obTourQiblaBody
                )
                OnboardingFeatureCard(
                    systemImage: "circle.grid.3x3.fill",
                    tint: MihrabColor.brass,
                    title: L10n.obTourDhikrTitle,
                    message: L10n.obTourDhikrBody
                )
            }
        }
    }

    // MARK: - 7 · Mihrab Plus

    private var plusPage: some View {
        OnboardingScaffold {
            VStack(spacing: 20) {
                Spacer(minLength: 0)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [MihrabColor.brass.opacity(0.35), .clear],
                                center: .center,
                                startRadius: 4,
                                endRadius: 90
                            )
                        )
                        .frame(width: 168, height: 168)
                    BrassCrescent(diameter: 78, opacity: 0.95)
                }

                VStack(spacing: 8) {
                    Text(L10n.obPlusTitle)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(MihrabColor.textPrimary)
                    Text(L10n.obPlusBody)
                        .font(.subheadline)
                        .foregroundStyle(MihrabColor.textSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 12) {
                    OnboardingBullet(text: L10n.obPlusPoint1, symbol: "sparkles", tint: MihrabColor.brass)
                    OnboardingBullet(text: L10n.obPlusPoint2, symbol: "book.fill", tint: MihrabColor.brass)
                    OnboardingBullet(text: L10n.obPlusPoint3, symbol: "chart.bar.fill", tint: MihrabColor.brass)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .mihrabSolidCard(cornerRadius: MihrabSpace.cardRadius)

                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Shared page furniture

/// Scrolls only when the content overflows, so short pages stay optically centred.
private struct OnboardingScaffold<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                content
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

private struct OnboardingHeadline: View {
    let systemImage: String
    let tint: Color
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 44))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(MihrabColor.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(MihrabColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct OnboardingBullet: View {
    let text: String
    var symbol: String = "checkmark.circle.fill"
    var tint: Color = MihrabColor.mint

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: symbol)
                .font(.footnote.weight(.bold))
                .foregroundStyle(tint)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(MihrabColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

private struct OnboardingFeatureCard: View {
    let systemImage: String
    let tint: Color
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(MihrabColor.textPrimary)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mihrabSolidCard(cornerRadius: MihrabSpace.cardRadius)
    }
}
