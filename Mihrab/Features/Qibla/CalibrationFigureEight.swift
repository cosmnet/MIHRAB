import CoreLocation
import SwiftUI

/// The honest banner shown whenever `QiblaAccuracy` says the heading cannot be
/// trusted: what is wrong, how bad it is, and an animated figure eight showing
/// exactly what to do about it.
///
/// It is deliberately loud. A quiet warning under an authoritative needle is
/// the same as no warning.
struct QiblaCalibrationBanner: View {
    let accuracy: QiblaAccuracy

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: accuracy.confidence == .invalid
                      ? "exclamationmark.triangle.fill"
                      : "dot.radiowaves.left.and.right")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(MihrabColor.brass)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(accuracy.confidence == .invalid
                         ? L10n.qblUnreliableTitle
                         : L10n.qblInterferenceTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MihrabColor.textPrimary)

                    Text(L10n.qblUnreliableBody)
                        .font(.footnote)
                        .foregroundStyle(MihrabColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(marginText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(MihrabColor.textSecondary)
                }
                Spacer(minLength: 0)
            }

            HStack(alignment: .center, spacing: 14) {
                FigureEightAnimation(reduceMotion: reduceMotion)
                    .frame(width: 96, height: 60)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.qblCalibrateHowTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MihrabColor.textPrimary)
                    Text(L10n.qblCalibrateHowBody)
                        .font(.footnote)
                        .foregroundStyle(MihrabColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius,
                         stroke: MihrabColor.brass.opacity(0.5))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text([accuracy.confidence == .invalid ? L10n.qblUnreliableTitle
                                                                 : L10n.qblInterferenceTitle,
                                  L10n.qblUnreliableBody,
                                  marginText,
                                  L10n.qblCalibrateHowBody].joined(separator: ", ")))
    }

    private var marginText: String {
        guard let reported = accuracy.reportedError else { return L10n.qblErrorUnknown }
        return L10n.qblErrorMargin(Int(reported.rounded()))
    }
}

/// A dot tracing a lemniscate — the gesture Apple's own calibration sheet asks
/// for, shown inline so the user does not have to guess what "figure eight"
/// means. Freezes into a static path under Reduce Motion.
struct FigureEightAnimation: View {
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                lemniscate(in: size)
                    .stroke(MihrabColor.mint.opacity(0.35),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4]))

                if reduceMotion {
                    Circle()
                        .fill(MihrabColor.brass)
                        .frame(width: 9, height: 9)
                        .position(point(at: 0.12, in: size))
                } else {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                        let t = context.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: 2.4) / 2.4
                        Circle()
                            .fill(MihrabColor.brass)
                            .frame(width: 9, height: 9)
                            .shadow(color: MihrabColor.brass.opacity(0.6), radius: 5)
                            .position(point(at: t, in: size))
                    }
                }
            }
        }
    }

    /// Lemniscate of Gerono — a clean figure eight with no self-intersection
    /// artefacts at the crossing.
    private func point(at t: Double, in size: CGSize) -> CGPoint {
        let angle = t * 2 * .pi
        let halfWidth = (size.width - 14) / 2
        let halfHeight = (size.height - 14) / 2
        return CGPoint(x: size.width / 2 + halfWidth * sin(angle),
                       y: size.height / 2 + halfHeight * sin(angle) * cos(angle))
    }

    private func lemniscate(in size: CGSize) -> Path {
        var path = Path()
        let steps = 120
        for step in 0...steps {
            let position = point(at: Double(step) / Double(steps), in: size)
            if step == 0 { path.move(to: position) } else { path.addLine(to: position) }
        }
        return path
    }
}

/// The compact strip that always sits under the dial: which north we are
/// measuring from, and how tight the reading is. Present in every state, so a
/// good reading is visibly good rather than merely un-warned.
struct QiblaAccuracyStrip: View {
    let accuracy: QiblaAccuracy

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.caption)
                .foregroundStyle(tint)
                .accessibilityHidden(true)

            Text(referenceLabel)
                .font(.footnote.weight(.medium))
                .foregroundStyle(MihrabColor.textSecondary)

            Text(verbatim: "·")
                .font(.footnote)
                .foregroundStyle(MihrabColor.textSecondary)
                .accessibilityHidden(true)

            Text(marginLabel)
                .font(.footnote)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .frame(minHeight: 36)
        .background(Capsule().fill(MihrabColor.moss.opacity(0.85)))
        .overlay { Capsule().strokeBorder(tint.opacity(0.35), lineWidth: 1) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(referenceLabel), \(marginLabel)"))
    }

    private var referenceLabel: String {
        switch accuracy.reference {
        case .trueNorth: L10n.qblTrueNorth
        case .magnetic: L10n.qblMagneticNorth
        case .none: L10n.holdFlat
        }
    }

    private var marginLabel: String {
        // Explicit returns throughout: one branch needs a `guard`, so this
        // cannot be an implicit-return switch expression.
        switch accuracy.confidence {
        case .unavailable: return L10n.qblErrorUnknown
        case .invalid: return L10n.qblErrorUnknown
        case .coarse, .good:
            guard let reported = accuracy.reportedError else { return L10n.qblErrorUnknown }
            if accuracy.confidence == .good, reported <= QiblaAccuracy.goodThreshold {
                return L10n.qblPrecise
            }
            return L10n.qblErrorMargin(Int(reported.rounded()))
        }
    }

    private var symbol: String {
        switch accuracy.confidence {
        case .good: accuracy.reference == .trueNorth ? "checkmark.seal.fill" : "exclamationmark.circle"
        case .coarse: "exclamationmark.triangle"
        case .invalid, .unavailable: "questionmark.circle"
        }
    }

    private var tint: Color {
        switch accuracy.confidence {
        case .good: accuracy.reference == .trueNorth ? MihrabColor.mint : MihrabColor.brass
        case .coarse, .invalid: MihrabColor.brass
        case .unavailable: MihrabColor.textSecondary
        }
    }
}
