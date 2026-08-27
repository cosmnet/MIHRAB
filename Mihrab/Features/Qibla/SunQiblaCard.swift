import CoreLocation
import SwiftUI

/// The sensor-free Qibla check.
///
/// Everything on this card is derived from `SolarMath` for the user's own
/// coordinate and clock. Nothing is a stored date, and when the sky cannot
/// answer (sun down, sun too low, polar night) the card says so instead of
/// showing an empty degree.
struct SunQiblaCard: View {
    let coordinate: CLLocationCoordinate2D
    let qiblaBearing: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        // One tick a minute is plenty: the sun moves 0.25° in that time.
        TimelineView(.periodic(from: .now, by: 60)) { context in
            content(now: context.date)
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let sun = SolarMath.position(at: now, coordinate: coordinate)

        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.qblSunCheckTitle, systemImage: "sun.max")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MihrabColor.brass)

            Text(L10n.qblSunCheckCaps)
                .ornamentalCaps(MihrabColor.textSecondary)

            if sun.altitude < 0 {
                note(L10n.qblSunBelowHorizon, symbol: "moon.stars")
            } else if sun.altitude < 3 {
                note(L10n.qblSunTooLow, symbol: "sun.horizon")
            } else {
                sunReadout(sun: sun)
            }

            if let moment = upcomingSunOnQibla(now: now) {
                Divider().overlay(MihrabColor.mint.opacity(0.18))
                Text(L10n.qblSunOnQiblaAt(moment))
                    .font(.footnote)
                    .foregroundStyle(MihrabColor.mint)
                    .fixedSize(horizontal: false, vertical: true)
            }

            rashdulSection(now: now)

            DisclosureGroup(isExpanded: $expanded) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.qblSunCheckIntro)
                    Text(L10n.qblShadowHint)
                    Text(L10n.qblRashdulExplain)
                    Text(L10n.qblAccuracyMethodNote)
                }
                .font(.footnote)
                .foregroundStyle(MihrabColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
            } label: {
                Text(L10n.qblHowItWorks)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MihrabColor.textPrimary)
                    .frame(minHeight: 44, alignment: .leading)
            }
            .tint(MihrabColor.mint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
    }

    // MARK: - Live sun ⇄ Qibla

    @ViewBuilder
    private func sunReadout(sun: SolarPosition) -> some View {
        // Positive = the Qibla lies clockwise (to the right) of the sun.
        let delta = SolarMath.sunToQiblaDelta(sunAzimuth: sun.azimuth, qiblaBearing: qiblaBearing)
        let degrees = Int(abs(delta).rounded())

        VStack(alignment: .leading, spacing: 8) {
            SunQiblaDiagram(sunAzimuth: sun.azimuth,
                            qiblaBearing: qiblaBearing,
                            reduceMotion: reduceMotion)
                .frame(height: 92)
                .accessibilityHidden(true)

            Text(headline(delta: delta, degrees: degrees))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(degrees <= 2 ? MihrabColor.mint : MihrabColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if degrees > 2 {
                Text(delta > 0 ? L10n.qblFaceSunTurnRight(degrees) : L10n.qblFaceSunTurnLeft(degrees))
                    .font(.footnote)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(headline(delta: delta, degrees: degrees)))
    }

    private func headline(delta: Double, degrees: Int) -> String {
        if degrees <= 2 { return L10n.qblSunOnQiblaNow }
        // `delta` is measured from the sun to the Qibla. If the Qibla is
        // clockwise of the sun, then from where you stand the sun sits to the
        // *left* of the Qibla.
        return delta > 0 ? L10n.qblSunLeftOfQibla(degrees) : L10n.qblSunRightOfQibla(degrees)
    }

    /// The next moment today when the sun crosses the Qibla bearing.
    private func upcomingSunOnQibla(now: Date) -> Date? {
        SolarMath.sunOnQiblaMoments(on: now,
                                    coordinate: coordinate,
                                    qiblaBearing: qiblaBearing,
                                    calendar: calendar)
            .first { $0 > now.addingTimeInterval(120) }
    }

    // MARK: - Rashdul Qibla

    @ViewBuilder
    private func rashdulSection(now: Date) -> some View {
        if let moment = SolarMath.rashdulQiblaMoments(after: now, limit: 1).first {
            let daysAway = calendar.dateComponents([.day],
                                                   from: calendar.startOfDay(for: now),
                                                   to: calendar.startOfDay(for: moment)).day ?? 0
            let sunThen = SolarMath.position(at: moment, coordinate: coordinate)

            VStack(alignment: .leading, spacing: 6) {
                Divider().overlay(MihrabColor.brass.opacity(0.22))

                Label(L10n.qblRashdulTitle, systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MihrabColor.brass)

                if daysAway <= 1, sunThen.altitude > 3 {
                    Text(daysAway == 0 ? L10n.qblRashdulToday(moment) : L10n.qblRashdulTomorrow(moment))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(MihrabColor.brass)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(L10n.qblRashdulOn(moment))
                        .font(.footnote)
                        .foregroundStyle(MihrabColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if sunThen.altitude <= 3 {
                    Text(L10n.qblRashdulNightNote)
                        .font(.footnote)
                        .foregroundStyle(MihrabColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func note(_ text: String, symbol: String) -> some View {
        Label(text, systemImage: symbol)
            .font(.footnote)
            .foregroundStyle(MihrabColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Diagram

/// A flat, north-up plan view: where the sun is, where the Qibla is, and the
/// shadow line between them. Deliberately not a compass — it does not move with
/// the phone, so it cannot inherit the magnetometer's error.
private struct SunQiblaDiagram: View {
    let sunAzimuth: Double
    let qiblaBearing: Double
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let radius = side / 2 - 10
            let centre = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                Circle()
                    .strokeBorder(MihrabColor.mint.opacity(0.2), lineWidth: 1)
                    .frame(width: side - 20, height: side - 20)

                Text(L10n.compassN)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MihrabColor.textSecondary)
                    .position(x: centre.x, y: centre.y - radius - 2)

                ray(from: centre, radius: radius, bearing: sunAzimuth,
                    color: MihrabColor.brass, symbol: "sun.max.fill")
                ray(from: centre, radius: radius, bearing: qiblaBearing,
                    color: MihrabColor.mint, symbol: "location.north.fill")

                // The shadow, drawn as a dashed stub away from the sun.
                Path { path in
                    path.move(to: centre)
                    path.addLine(to: point(from: centre, radius: radius * 0.7,
                                           bearing: SolarMath.wrap360(sunAzimuth + 180)))
                }
                .stroke(MihrabColor.textTertiary.opacity(0.6),
                        style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
            }
            .animation(reduceMotion ? nil : MihrabMotion.standardAnimation, value: sunAzimuth)
        }
    }

    private func ray(from centre: CGPoint, radius: CGFloat, bearing: Double,
                     color: Color, symbol: String) -> some View {
        let tip = point(from: centre, radius: radius, bearing: bearing)
        return ZStack {
            Path { path in
                path.move(to: centre)
                path.addLine(to: tip)
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))

            Image(systemName: symbol)
                .font(.caption)
                .foregroundStyle(color)
                .position(tip)
        }
    }

    /// Bearing is clockwise from north; screen y grows downwards.
    private func point(from centre: CGPoint, radius: CGFloat, bearing: Double) -> CGPoint {
        let radians = bearing * .pi / 180
        return CGPoint(x: centre.x + radius * sin(radians),
                       y: centre.y - radius * cos(radians))
    }
}
