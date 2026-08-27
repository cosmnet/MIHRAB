import CoreLocation
import SwiftUI

struct QiblaCompassView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var showsAREntry: Bool = true

    @State private var showAR = false
    @State private var showVerify = false
    @State private var hasLockedOn = false
    @State private var lastTickDegree = 0
    @State private var burstTrigger = 0

    private var qiblaBearing: Double {
        guard let c = locationManager.effectiveCoordinate else { return 0 }
        return QiblaMath.bearing(fromLatitude: c.latitude, longitude: c.longitude)
    }

    private var distanceKm: Double {
        guard let c = locationManager.effectiveCoordinate else { return 0 }
        return QiblaMath.distanceToMakkah(fromLatitude: c.latitude, longitude: c.longitude)
    }

    private var heading: Double { locationManager.smoothedHeading }
    private var dialHeading: Double { locationManager.continuousHeading }

    private var qiblaDelta: Double {
        QiblaMath.shortestDelta(from: heading, to: qiblaBearing)
    }

    /// The accuracy gate. Everything that *asserts* a direction is behind it.
    private var accuracy: QiblaAccuracy {
        QiblaAccuracy.evaluate(locationManager.heading)
    }

    /// Locked on. Requires a trustworthy sensor — a ±3° claim on top of a ±40°
    /// reading is the exact false confidence this screen must never show.
    private var isAligned: Bool {
        accuracy.isTrustworthy && abs(qiblaDelta) <= QiblaAccuracy.lockTolerance
    }

    /// `true` when the magnetometer is either unusable or badly skewed.
    private var needsCalibration: Bool { accuracy.needsCalibration }

    var body: some View {
        NavigationStack {
            ZStack {
                MihrabBackdrop(surface: .qibla, ramadanMode: theme.isRamadanMode)

                // The dial alone used to fill the screen; the accuracy gate and
                // the solar check add real height, so this scrolls now. Without
                // it the calibration banner — the one thing that must never be
                // missable — would be the first casualty of a small phone.
                ScrollView {
                    VStack(spacing: 16) {
                        Spacer(minLength: 4)

                        if locationManager.effectiveCoordinate == nil {
                            MihrabEmptyState(
                                symbol: "location.slash",
                                title: L10n.locationNeeded,
                                message: L10n.locationNeededBody,
                                retryTitle: L10n.enableLocation
                            ) {
                                locationManager.requestAuthorization()
                                locationManager.startUpdating()
                            }
                            .padding(.horizontal, 24)
                        } else {
                            VStack(spacing: 18) {
                                QiblaCompassDial(
                                    heading: heading,
                                    dialHeading: dialHeading,
                                    qiblaBearing: qiblaBearing,
                                    isAligned: isAligned,
                                    burstTrigger: burstTrigger,
                                    reduceMotion: reduceMotion
                                )
                                // A distrusted needle is drawn, but drained of the
                                // colour that says "this is the answer".
                                .saturation(accuracy.isTrustworthy ? 1 : 0.25)
                                .opacity(accuracy.isTrustworthy ? 1 : 0.6)
                                .frame(width: 300, height: 300)
                                .accessibilityHidden(true)

                                // The one line a person actually needs while
                                // they are turning. Everything else moved.
                                guidance
                            }
                            .padding(20)
                            .mihrabShaderPanel(.kufic, cornerRadius: MihrabSpace.cardRadius, opacity: 0.18)
                            .mihrabCardScene("qibla-bg", opacity: 0.45)
                            .mihrabCard()
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(Text(accessibilitySummary))

                            // Silence when the compass is fine. The strip used
                            // to announce "true north · compass steady" forever,
                            // which is a sentence nobody needs to read twice.
                            if !accuracy.isTrustworthy || accuracy.isMagneticFallback {
                                QiblaAccuracyStrip(accuracy: accuracy)
                            }

                            if accuracy.isMagneticFallback {
                                magneticNorthNotice
                                    .transition(.opacity.combined(with: .offset(y: 8)))
                            }

                            if needsCalibration {
                                QiblaCalibrationBanner(accuracy: accuracy)
                                    .padding(.horizontal, 16)
                                    .transition(.opacity.combined(with: .offset(y: 8)))
                            }

                            verifyEntry
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 16)
                    .animation(reduceMotion ? nil : MihrabMotion.standardAnimation, value: needsCalibration)
                }
                .mihrabTabScroll()
            }
            // The floating tab bar already owns the bottom safe area; the AR
            // entry rides just above it instead of guessing a clearance.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if showsAREntry, locationManager.effectiveCoordinate != nil {
                    Button { showAR = true } label: {
                        Label(L10n.viewInAR, systemImage: "camera.viewfinder")
                            .font(.subheadline.weight(.semibold))
                            .frame(minHeight: MihrabSpace.hit)
                            .padding(.horizontal, 22)
                            .glassEffect(.regular.interactive(), in: .capsule)
                    }
                    .pressable(reduceMotion)
                    .premiumRequired(.qiblaAR)
                    .padding(.bottom, 8)
                }
            }
            .mihrabTabSafeContent(showsAREntry ? MihrabSpace.tabClearance : 16)
            .navigationTitle(L10n.tabQibla)
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showVerify) {
            QiblaVerifySheet(
                coordinate: locationManager.effectiveCoordinate,
                qiblaBearing: qiblaBearing,
                distanceKm: distanceKm,
                accuracy: accuracy
            )
        }
        .fullScreenCover(isPresented: $showAR) {
            QiblaARGate(qiblaBearing: qiblaBearing, distanceKm: distanceKm)
        }
        .onAppear {
            locationManager.startHeading()
            // `trueHeading` is only populated once CoreLocation has a fix to
            // look the magnetic declination up against, so the compass screen
            // must hold a location subscription — otherwise we silently fall
            // back to magnetic north for the whole session.
            locationManager.startUpdating(precision: .qibla)
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestAuthorization()
            }
        }
        .onDisappear {
            locationManager.stopHeading()
            locationManager.stopUpdating(precision: .qibla)
        }
        .onChange(of: isAligned) { _, aligned in
            if aligned && !hasLockedOn {
                hasLockedOn = true
                HapticsEngine.shared.qiblaLockOn()
                burstTrigger += 1
            } else if !aligned {
                hasLockedOn = false
            }
        }
        .onChange(of: heading) { _, newHeading in
            // Only tick while closing in — a click every 5° across a full spin
            // is noise, and it fires constantly when the phone is on a table.
            // No approach ticks on a reading we would not trust to lock on.
            guard accuracy.isTrustworthy, abs(qiblaDelta) < 40 else { return }
            let bucket = Int(newHeading) / 5
            if bucket != lastTickDegree {
                lastTickDegree = bucket
                HapticsEngine.shared.compassTick()
            }
        }
    }

    /// One visible button in place of a permanently open essay. Behind it:
    /// the sun check, Rashdul Qibla, the calibration walkthrough and the method
    /// note that all used to sit on this screen at once.
    private var verifyEntry: some View {
        Button {
            HapticsEngine.shared.light()
            showVerify = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sun.max")
                    .font(.body)
                    .foregroundStyle(MihrabColor.brass)
                Text(L10n.qblVerifyEntry)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(MihrabColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(MihrabColor.textSecondary)
            }
            .padding(.horizontal, 20)
            .frame(minHeight: 52)
            .contentShape(Capsule())
            .background(Capsule().fill(MihrabColor.moss))
            .overlay { Capsule().strokeBorder(MihrabColor.mint.opacity(0.3), lineWidth: 1) }
        }
        .buttonStyle(.plain)
        .pressable(reduceMotion)
        .accessibilityAddTraits(.isButton)
    }

    /// Locked on, told which way to turn, or told honestly that we cannot say.
    ///
    /// This is now the *only* text under the dial, so it is sized to be read
    /// at arm's length rather than squinted at.
    @ViewBuilder
    private var guidance: some View {
        if !accuracy.isTrustworthy, accuracy.hasHeading {
            // The sensor is live but wrong. Saying "turn 14° right" here would
            // be the precise failure mode this screen exists to avoid.
            Label(L10n.qblUnreliableTitle, systemImage: "exclamationmark.triangle.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(MihrabColor.brass)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .frame(minHeight: 52)
                .background(Capsule().fill(MihrabColor.moss))
                .overlay { Capsule().strokeBorder(MihrabColor.brass.opacity(0.5), lineWidth: 1) }
        } else if isAligned {
            Text(L10n.facingQibla)
                .font(.title3.weight(.bold))
                .foregroundStyle(MihrabColor.mint)
                .padding(.horizontal, 24)
                .frame(minHeight: 52)
                .background(Capsule().fill(MihrabColor.moss))
                .overlay {
                    Capsule().strokeBorder(MihrabColor.mint.opacity(0.45), lineWidth: 1)
                }
                .transition(.opacity.combined(with: .scale))
        } else if locationManager.heading == nil {
            Text(L10n.holdFlat)
                .font(.body)
                .foregroundStyle(MihrabColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .frame(minHeight: 52)
        } else {
            let degrees = Int(abs(qiblaDelta).rounded())
            Label {
                Text(qiblaDelta > 0 ? L10n.qibTurnRight(degrees) : L10n.qibTurnLeft(degrees))
                    .contentTransition(.numericText())
            } icon: {
                Image(systemName: qiblaDelta > 0 ? "arrow.turn.up.right" : "arrow.turn.up.left")
            }
            .font(.title3.weight(.semibold))
            .foregroundStyle(MihrabColor.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 20)
            .frame(minHeight: 52)
            .background(Capsule().fill(MihrabColor.moss.opacity(0.9)))
            .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: degrees)
        }
    }

    /// True north needs a location fix. Until one lands we are reading magnetic
    /// north, which is a different direction — never left implicit.
    private var magneticNorthNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "location.magnifyingglass")
                .font(.footnote)
                .foregroundStyle(MihrabColor.brass)
                .accessibilityHidden(true)
            Text(L10n.qblMagneticNorthWarning)
                .font(.footnote)
                .foregroundStyle(MihrabColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14)
        .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius, stroke: MihrabColor.brass.opacity(0.35))
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
    }

    private var accessibilitySummary: String {
        var parts = [L10n.qiblaDegrees(Int(qiblaBearing.rounded()), L10n.cardinal(for: qiblaBearing))]
        if distanceKm > 0 { parts.append(L10n.kmToMakkah(Int(distanceKm.rounded()))) }
        if !accuracy.isTrustworthy {
            // VoiceOver hears the warning first, before any number it might
            // otherwise act on.
            parts.insert(L10n.qblUnreliableTitle, at: 0)
        } else if isAligned {
            parts.append(L10n.facingQibla)
        } else if accuracy.hasHeading {
            let degrees = Int(abs(qiblaDelta).rounded())
            parts.append(qiblaDelta > 0 ? L10n.qibTurnRight(degrees) : L10n.qibTurnLeft(degrees))
        }
        if accuracy.isMagneticFallback { parts.append(L10n.qblMagneticNorth) }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Dial

struct QiblaCompassDial: View {
    let heading: Double
    let dialHeading: Double
    let qiblaBearing: Double
    let isAligned: Bool
    let burstTrigger: Int
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [MihrabColor.brass.opacity(0.9), MihrabColor.mint.opacity(0.28),
                                 MihrabColor.brass.opacity(0.55), MihrabColor.brass.opacity(0.2),
                                 MihrabColor.brass.opacity(0.9)],
                        center: .center
                    ),
                    lineWidth: 8
                )
                .shadow(color: MihrabColor.brass.opacity(isAligned ? 0.45 : 0.14), radius: isAligned ? 16 : 6)

            Circle()
                .fill(MihrabColor.moss.opacity(0.35))
                .padding(12)
                .glassEffect(.regular, in: .circle)
                .overlay {
                    Circle()
                        .strokeBorder(
                            LinearGradient(colors: [MihrabColor.mint.opacity(0.55), .clear],
                                           startPoint: .top, endPoint: .center),
                            lineWidth: 1
                        )
                        .padding(12)
                }

            MihrabOrnament(name: "compass-rose", opacity: isAligned ? 0.28 : 0.16, side: 268)
                .rotationEffect(.degrees(-dialHeading))
                .animation(reduceMotion ? nil : MihrabMotion.compassAnimation, value: dialHeading)

            ForEach([0.70, 0.52], id: \.self) { scale in
                Circle()
                    .stroke(MihrabColor.brass.opacity(0.16), lineWidth: 0.5)
                    .scaleEffect(scale)
            }

            rotatingFurniture
                .rotationEffect(.degrees(-dialHeading))
                .animation(reduceMotion ? nil : MihrabMotion.compassAnimation, value: dialHeading)

            VStack(spacing: 0) {
                Image("qibla-arrow")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .opacity(isAligned ? 1 : 0.85)
                    .accessibilityHidden(true)
                Spacer()
            }
            .padding(.top, 6)

            if isAligned {
                Circle()
                    .strokeBorder(
                        AngularGradient(colors: [MihrabColor.mint, MihrabColor.emerald, MihrabColor.brass, MihrabColor.mint],
                                        center: .center),
                        lineWidth: 3
                    )
                    .shadow(color: MihrabColor.mint.opacity(reduceMotion ? 0.25 : 0.4), radius: reduceMotion ? 6 : 12)
                    .padding(10)
                    .transition(.opacity)
            }

            if !reduceMotion {
                AmbientTickField(aligned: isAligned)
            }

            ParticleBurst(trigger: burstTrigger)
        }
        .animation(reduceMotion ? nil : MihrabMotion.snappyAnimation, value: isAligned)
    }

    private var rotatingFurniture: some View {
        ZStack {
            ForEach(0..<72, id: \.self) { tick in
                let degrees = Double(tick) * 5
                let major = tick % 18 == 0
                let medium = tick % 6 == 0
                Rectangle()
                    .fill(major ? MihrabColor.brass : MihrabColor.textTertiary.opacity(medium ? 0.7 : 0.35))
                    .frame(width: major ? 2 : 1, height: major ? 16 : (medium ? 11 : 6))
                    .offset(y: -118)
                    .rotationEffect(.degrees(degrees))
            }

            ForEach([0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330], id: \.self) { deg in
                Text("\(deg)")
                    .font(.system(size: 9, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(MihrabColor.textSecondary)
                    .offset(y: -96)
                    .rotationEffect(.degrees(Double(deg)))
                    .rotationEffect(.degrees(dialHeading))
            }

            ForEach(
                Array(zip([0.0, 90.0, 180.0, 270.0],
                          [L10n.compassN, L10n.compassE, L10n.compassS, L10n.compassW])),
                id: \.0
            ) { degrees, label in
                Text(label)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(degrees == 0 ? MihrabColor.brass : MihrabColor.textSecondary)
                    .offset(y: -76)
                    .rotationEffect(.degrees(degrees))
                    .rotationEffect(.degrees(dialHeading))
            }

            Image("qibla-arrow")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .offset(y: -118)
                .rotationEffect(.degrees(qiblaBearing))
                .opacity(isAligned ? 1 : 0.88)
                .scaleEffect(isAligned ? 1.18 : 1)
                .accessibilityHidden(true)

            KaabaGlyph(aligned: isAligned)
                .offset(y: -96)
                .rotationEffect(.degrees(qiblaBearing))
        }
    }
}

// MARK: - Components

private struct KaabaGlyph: View {
    let aligned: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if aligned && !reduceMotion {
                Circle()
                    .fill(MihrabColor.brass.opacity(0.35))
                    .frame(width: 40, height: 40)
                    .blur(radius: 6)
            }
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black)
                .frame(width: 22, height: 22)
                .overlay {
                    Rectangle()
                        .fill(MihrabColor.brass)
                        .frame(height: 3.5)
                        .offset(y: -4)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(MihrabColor.brass, lineWidth: 1.2)
                }
            if aligned {
                Circle()
                    .stroke(MihrabColor.mint.opacity(0.85), lineWidth: 1.5)
                    .frame(width: 34, height: 34)
            }
        }
        .scaleEffect(aligned ? 1.22 : 1)
        .shadow(color: aligned ? MihrabColor.brass.opacity(0.85) : MihrabColor.brass.opacity(0.2), radius: aligned ? 12 : 3)
    }
}

private struct AmbientTickField: View {
    let aligned: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { canvas, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 28
                for i in 0..<24 {
                    let angle = Double(i) * (.pi / 12) + t * (aligned ? 0.35 : 0.08)
                    let pulse = 0.25 + 0.55 * abs(sin(t * 1.4 + Double(i)))
                    let point = CGPoint(
                        x: center.x + cos(angle) * radius,
                        y: center.y + sin(angle) * radius
                    )
                    canvas.fill(
                        Path(ellipseIn: CGRect(x: point.x - 1.4, y: point.y - 1.4, width: 2.8, height: 2.8)),
                        with: .color((aligned ? MihrabColor.mint : MihrabColor.brass).opacity(pulse * 0.7))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Brass + mint spark burst keyed to the lock-on trigger, not wall-clock remainder.
struct ParticleBurst: View {
    let trigger: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startedAt: Date?

    var body: some View {
        TimelineView(.animation(paused: reduceMotion || trigger == 0)) { context in
            Canvas { canvas, size in
                guard !reduceMotion, trigger > 0, let startedAt else { return }
                let elapsed = context.date.timeIntervalSince(startedAt)
                guard elapsed < 1.15 else { return }
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let spark = canvas.resolve(Image("particle-spark"))
                canvas.blendMode = .plusLighter
                for i in 0..<18 {
                    let angle = Double(i) * (2 * .pi / 18) + elapsed * 0.8
                    let distance = 28 + elapsed * 150 + Double(i % 4) * 6
                    let point = CGPoint(
                        x: center.x + cos(angle) * distance,
                        y: center.y + sin(angle) * distance
                    )
                    canvas.opacity = max(0, 1 - elapsed / 1.15)
                    let side: CGFloat = i.isMultiple(of: 2) ? 36 : 24
                    canvas.draw(
                        spark,
                        in: CGRect(x: point.x - side / 2, y: point.y - side / 2, width: side, height: side)
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in startedAt = Date() }
    }
}
