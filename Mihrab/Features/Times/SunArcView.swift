import SwiftUI

/// Weather-style sun path: gradient arc, prayer markers, live sun. Drag to scrub.
struct SunArcView: View {
    let times: DayPrayerTimes?
    let date: Date

    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var scrubbedFraction: Double?
    @State private var introProgress: Double = 0

    var body: some View {
        Group {
            if reduceMotion {
                card(now: Date(), pulse: 1)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: scrubbedFraction != nil)) { context in
                    let pulse = 1 + 0.07 * sin(context.date.timeIntervalSinceReferenceDate * .pi / 1.55)
                    card(now: context.date, pulse: pulse)
                }
            }
        }
        .onAppear(perform: playIntro)
        .sensoryFeedback(.selection, trigger: scrubToken)
    }

    private func card(now: Date, pulse: Double) -> some View {
        let fraction = displayedFraction(at: now)
        let prayer = fraction.flatMap(owningPrayer(at:))
        let scrubbing = scrubbedFraction != nil

        return VStack(alignment: .leading, spacing: 6) {
            Text(L10n.sunPath)
                .ornamentalCaps()

            plot(fraction: fraction, owning: prayer, pulse: pulse, scrubbing: scrubbing)
                .frame(height: 104)
                .accessibilityHidden(true)

            caption(prayer: prayer)
                .frame(maxWidth: .infinity, minHeight: 40)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RadialGradient(
                colors: [
                    MihrabColor.brass.opacity(0.12),
                    MihrabColor.emerald.opacity(0.07),
                    .clear
                ],
                center: UnitPoint(x: 0.5, y: 0.42),
                startRadius: 6,
                endRadius: 170
            )
            .allowsHitTesting(false)
        }
        .mihrabCard(cornerRadius: 22)
        .accessibilityElement(children: .combine)
        .accessibilityValue(captionValue(prayer))
    }

    // MARK: - Plot

    private func plot(fraction: Double?, owning: Prayer?, pulse: Double, scrubbing: Bool) -> some View {
        GeometryReader { geo in
            let rect = CGRect(
                x: 26,
                y: 16,
                width: geo.size.width - 52,
                height: geo.size.height - 36
            )
            let sun = fraction.map { point(on: rect, at: $0) }

            ZStack {
                skyFill(in: rect, canvas: geo.size, sun: sun)
                horizon(in: rect)
                dimArc(in: rect)
                if let fraction {
                    litArc(in: rect, fraction: fraction)
                }
                ticks(in: rect)
                markers(in: rect, owning: owning, sunFraction: fraction)
                if scrubbing, let sun {
                    dropLine(from: sun, to: rect.maxY)
                }
                if let sun {
                    sunDisc(at: sun, pulse: pulse, scrubbing: scrubbing)
                }
            }
            .contentShape(Rectangle())
            .gesture(scrubGesture(in: rect))
        }
    }

    private func skyFill(in rect: CGRect, canvas: CGSize, sun: CGPoint?) -> some View {
        let fill = closedArc(in: rect)
        return ZStack {
            fill.fill(
                LinearGradient(
                    colors: [
                        MihrabColor.brass.opacity(0.14),
                        MihrabColor.emerald.opacity(0.10),
                        MihrabColor.mint.opacity(0.03)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            if let sun {
                fill.fill(
                    RadialGradient(
                        colors: [
                            MihrabColor.brass.opacity(0.28),
                            MihrabColor.mint.opacity(0.08),
                            .clear
                        ],
                        center: UnitPoint(
                            x: sun.x / max(canvas.width, 1),
                            y: sun.y / max(canvas.height, 1)
                        ),
                        startRadius: 0,
                        endRadius: 88
                    )
                )
            }
        }
        .allowsHitTesting(false)
    }

    private func horizon(in rect: CGRect) -> some View {
        Path { path in
            path.move(to: CGPoint(x: rect.minX - 8, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX + 8, y: rect.maxY))
        }
        .stroke(MihrabColor.textTertiary.opacity(0.38), lineWidth: 1)
        .allowsHitTesting(false)
    }

    private func dimArc(in rect: CGRect) -> some View {
        arcPath(in: rect)
            .stroke(
                MihrabColor.brass.opacity(0.22),
                style: StrokeStyle(lineWidth: 1.6, lineCap: .round)
            )
            .allowsHitTesting(false)
    }

    private func litArc(in rect: CGRect, fraction: Double) -> some View {
        let path = arcPath(in: rect)
        let gradient = LinearGradient(
            stops: [
                .init(color: MihrabColor.brass, location: 0),
                .init(color: MihrabColor.emerald, location: 0.48),
                .init(color: MihrabColor.mint, location: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        return ZStack {
            path
                .trim(from: 0, to: fraction)
                .stroke(MihrabColor.brass.opacity(0.32), style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .blur(radius: 7)
            path
                .trim(from: 0, to: fraction)
                .stroke(gradient, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        }
        .allowsHitTesting(false)
    }

    private func ticks(in rect: CGRect) -> some View {
        ForEach(Prayer.allCases) { prayer in
            if let t = fraction(for: prayer) {
                let x = point(on: rect, at: t).x
                Path { path in
                    path.move(to: CGPoint(x: x, y: rect.maxY - 3.5))
                    path.addLine(to: CGPoint(x: x, y: rect.maxY + 3.5))
                }
                .stroke(MihrabColor.textTertiary.opacity(0.5), lineWidth: 0.8)
            }
        }
        .allowsHitTesting(false)
    }

    private func markers(in rect: CGRect, owning: Prayer?, sunFraction: Double?) -> some View {
        ForEach(Prayer.allCases) { prayer in
            if let t = fraction(for: prayer) {
                let covered = sunFraction.map { abs($0 - t) < 0.04 } ?? false
                let p = point(on: rect, at: t)
                let active = prayer == owning
                let nudge = labelNudge(at: t)

                if !covered {
                    Circle()
                        .fill(active ? MihrabColor.mint : MihrabColor.brass.opacity(0.75))
                        .frame(width: active ? 6 : 4, height: active ? 6 : 4)
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    (active ? MihrabColor.sprout : MihrabColor.brass).opacity(active ? 0.7 : 0.25),
                                    lineWidth: 0.5
                                )
                        }
                        .shadow(color: active ? MihrabColor.mint.opacity(0.45) : .clear, radius: 4)
                        .position(p)
                }

                Text(prayer.localizedName)
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundStyle(active ? MihrabColor.mint : MihrabColor.textSecondary)
                    .opacity(covered && active ? 0.35 : 1)
                    .lineLimit(1)
                    .fixedSize()
                    .position(x: p.x + nudge.width, y: p.y + nudge.height)
            }
        }
        .allowsHitTesting(false)
    }

    private func dropLine(from sun: CGPoint, to horizonY: CGFloat) -> some View {
        Path { path in
            path.move(to: sun)
            path.addLine(to: CGPoint(x: sun.x, y: horizonY))
        }
        .stroke(
            MihrabColor.mint.opacity(0.28),
            style: StrokeStyle(lineWidth: 0.8, dash: [3, 3])
        )
        .allowsHitTesting(false)
    }

    private func sunDisc(at point: CGPoint, pulse: Double, scrubbing: Bool) -> some View {
        let core: CGFloat = scrubbing ? 16 : 14
        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            MihrabColor.brass.opacity(0.55 * pulse),
                            MihrabColor.mint.opacity(0.16 * pulse),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 34
                    )
                )
                .frame(width: 68, height: 68)

            Circle()
                .fill(MihrabColor.sprout.opacity(0.28 * pulse))
                .frame(width: 26, height: 26)
                .blur(radius: 4)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: 0xFFF6D8), MihrabColor.brass],
                        center: .center,
                        startRadius: 1,
                        endRadius: core / 2
                    )
                )
                .frame(width: core, height: core)
                .shadow(color: MihrabColor.brass.opacity(0.65), radius: 8)
        }
        .position(point)
        .allowsHitTesting(false)
    }

    private func scrubGesture(in rect: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                introProgress = 1
                let raw = (value.location.x - rect.minX) / max(rect.width, 1)
                scrubbedFraction = snap(min(max(raw, 0), 1))
            }
            .onEnded { _ in
                withAnimation(reduceMotion ? nil : MihrabMotion.gentleAnimation) {
                    scrubbedFraction = nil
                }
            }
    }

    // MARK: - Caption

    @ViewBuilder
    private func caption(prayer: Prayer?) -> some View {
        if let prayer {
            VStack(spacing: 2) {
                Text(prayer.localizedName)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(MihrabColor.textPrimary)
                    .contentTransition(.opacity)
                Text(timeString(for: prayer))
                    .font(MihrabFont.timeDisplay(20))
                    .foregroundStyle(theme.isRamadanMode ? MihrabColor.ramadanGold : MihrabColor.brass)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity)
            .animation(reduceMotion ? nil : MihrabMotion.snappyAnimation, value: prayer)
        }
    }

    // MARK: - Geometry

    private func startPoint(in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX, y: rect.maxY)
    }

    private func endPoint(in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.maxX, y: rect.maxY)
    }

    private func controlPoint(in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.midX, y: rect.minY)
    }

    private func arcPath(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: startPoint(in: rect))
        path.addQuadCurve(to: endPoint(in: rect), control: controlPoint(in: rect))
        return path
    }

    private func closedArc(in rect: CGRect) -> Path {
        var path = arcPath(in: rect)
        path.closeSubpath()
        return path
    }

    private func point(on rect: CGRect, at t: Double) -> CGPoint {
        let p0 = startPoint(in: rect)
        let p1 = controlPoint(in: rect)
        let p2 = endPoint(in: rect)
        let u = 1 - t
        return CGPoint(
            x: u * u * p0.x + 2 * u * t * p1.x + t * t * p2.x,
            y: u * u * p0.y + 2 * u * t * p1.y + t * t * p2.y
        )
    }

    private func labelNudge(at t: Double) -> CGSize {
        switch t {
        case ..<0.10: CGSize(width: 16, height: 11)
        case ..<0.28: CGSize(width: 0, height: 12)
        case ..<0.55: CGSize(width: 0, height: 14)
        case ..<0.75: CGSize(width: 0, height: 12)
        case ..<0.91: CGSize(width: 4, height: -11)
        default: CGSize(width: -16, height: 11)
        }
    }

    // MARK: - Time

    private func displayedFraction(at now: Date) -> Double? {
        if let scrubbedFraction { return scrubbedFraction }
        guard let live = nowFraction(at: now) else { return nil }
        return live * introProgress
    }

    private func nowFraction(at now: Date) -> Double? {
        guard Calendar.current.isDateInToday(date), let times,
              let fajr = times.time(for: .fajr), let isha = times.time(for: .isha) else { return nil }
        let span = isha.timeIntervalSince(fajr)
        guard span > 0 else { return nil }
        return min(max(now.timeIntervalSince(fajr) / span, 0), 1)
    }

    private func fraction(for prayer: Prayer) -> Double? {
        guard let times, let fajr = times.time(for: .fajr),
              let isha = times.time(for: .isha), let t = times.time(for: prayer) else { return nil }
        let span = isha.timeIntervalSince(fajr)
        guard span > 0 else { return nil }
        return min(max(t.timeIntervalSince(fajr) / span, 0), 1)
    }

    private func owningPrayer(at fraction: Double) -> Prayer? {
        guard let times, let fajr = times.time(for: .fajr),
              let isha = times.time(for: .isha) else { return nil }
        let span = isha.timeIntervalSince(fajr)
        guard span > 0 else { return nil }
        let instant = fajr.addingTimeInterval(span * fraction)
        return times.previousPrayer(before: instant)?.prayer ?? .fajr
    }

    private func snap(_ fraction: Double) -> Double {
        var best: (distance: Double, value: Double)?
        for prayer in Prayer.allCases {
            guard let t = self.fraction(for: prayer) else { continue }
            let d = abs(t - fraction)
            if d < 0.03, best == nil || d < best!.distance {
                best = (d, t)
            }
        }
        return best?.value ?? fraction
    }

    private func timeString(for prayer: Prayer) -> String {
        times?.time(for: prayer)?.formatted(date: .omitted, time: .shortened) ?? ""
    }

    private func captionValue(_ prayer: Prayer?) -> String {
        guard let prayer else { return "" }
        return "\(prayer.localizedName) \(timeString(for: prayer))"
    }

    private var scrubToken: String {
        guard scrubbedFraction != nil, let f = scrubbedFraction,
              let prayer = owningPrayer(at: f) else { return "" }
        return prayer.id
    }

    private func playIntro() {
        if reduceMotion {
            introProgress = 1
            return
        }
        introProgress = 0
        withAnimation(.easeInOut(duration: 1.35)) {
            introProgress = 1
        }
    }
}
