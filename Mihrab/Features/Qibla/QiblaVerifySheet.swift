import CoreLocation
import SwiftUI

/// Everything the compass screen used to say out loud, moved one tap away.
///
/// The primary screen keeps only what a person needs while they are turning:
/// the dial, one instruction, and — when the sensor is actually in trouble —
/// the warning. The *reasoning* (how the sun check works, when the sun stands
/// over the Kaaba, how to recalibrate, what the bearing is computed from) lives
/// here, behind a single visible entry point.
///
/// Nothing was deleted, and nothing here softens the honesty rule: the
/// calibration banner still appears on the main screen whenever the heading
/// cannot be trusted. Only the talking that happens when everything is fine has
/// been moved.
struct QiblaVerifySheet: View {
    let coordinate: CLLocationCoordinate2D?
    let qiblaBearing: Double
    let distanceKm: Double
    let accuracy: QiblaAccuracy

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ZStack {
                MihrabBackdrop(surface: .qibla)

                ScrollView {
                    VStack(spacing: 16) {
                        bearingCard

                        if let coordinate {
                            SunQiblaCard(coordinate: coordinate, qiblaBearing: qiblaBearing)
                        }

                        calibrationCard

                        Text(L10n.qblAccuracyMethodNote)
                            .font(.footnote)
                            .foregroundStyle(MihrabColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                    .padding(16)
                }
            }
            .navigationTitle(L10n.qblVerifyTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.done) { dismiss() }
                        .font(.body.weight(.semibold))
                }
            }
        }
    }

    /// The two numbers that were tiles on the main screen. They belong to the
    /// "is this right?" question, not to the act of turning.
    private var bearingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.qibHeadingCaps)
                .ornamentalCaps()

            Text(L10n.qiblaDegrees(Int(qiblaBearing.rounded()), L10n.cardinal(for: qiblaBearing)))
                .font(.title3.weight(.semibold))
                .foregroundStyle(MihrabColor.mint)
                .fixedSize(horizontal: false, vertical: true)

            if distanceKm > 0 {
                Text(L10n.kmToMakkah(Int(distanceKm.rounded())))
                    .font(.subheadline)
                    .foregroundStyle(MihrabColor.brass)
            }

            Text(referenceSentence)
                .font(.footnote)
                .foregroundStyle(MihrabColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
        .accessibilityElement(children: .combine)
    }

    /// Which north the needle is measured from, in a sentence rather than a
    /// badge — this sheet has the room the dial did not.
    private var referenceSentence: String {
        switch accuracy.reference {
        case .trueNorth: L10n.qblReferenceTrueSentence
        case .magnetic: L10n.qblMagneticNorthWarning
        case .none: L10n.holdFlat
        }
    }

    private var calibrationCard: some View {
        HStack(alignment: .center, spacing: 14) {
            FigureEightAnimation(reduceMotion: reduceMotion)
                .frame(width: 96, height: 60)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.qblCalibrateHowTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MihrabColor.textPrimary)
                Text(L10n.qblCalibrateHowBody)
                    .font(.footnote)
                    .foregroundStyle(MihrabColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(L10n.qblCalibrateHowTitle), \(L10n.qblCalibrateHowBody)"))
    }
}
