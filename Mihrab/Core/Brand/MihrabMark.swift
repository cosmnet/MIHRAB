import SwiftUI

// MARK: - Geometry

/// The one piece of geometry the whole brand is built on: a two-centred
/// pointed *mihrab* niche.
///
/// Drawn in a canonical 100 × 128 design space and mapped onto whatever rect
/// it is handed, so the proportions never drift between the splash, the
/// welcome screen, the paywall and the app icon.
///
/// The path is authored as **one continuous stroke** — up the left jamb, over
/// the crown, down the right jamb — which is what makes `.trim(from:to:)`
/// read as a single line drawing itself.
struct MihrabArch: Shape {
    /// 0 = the outer arch. Larger values step the arch inwards, giving the
    /// concentric "echo" that reads as depth in a real niche.
    var inset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let scale = CGSize(width: rect.width / 100, height: rect.height / 128)
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * scale.width, y: rect.minY + y * scale.height)
        }

        // Canonical outer arch, then pushed inwards by `inset` design units.
        // The crown drops faster than the jambs move in — that keeps the
        // inner arches concentric rather than merely narrower.
        let left = 10 + inset
        let right = 90 - inset
        let apexY = 6 + inset * 1.70
        let springY = 66 + inset * 0.35
        let baseY: CGFloat = 120

        let mid = (left + right) / 2
        let span = right - left
        let rise = springY - apexY

        // An *ogee*: convex where it leaves the jamb, concave as it climbs,
        // meeting in a point. The inflection is where the curve changes
        // hands. A single arc would give a Roman semicircle — and a
        // semicircle is exactly what read as a stray capital "C" before.
        let inflectionX = span * 0.13
        let inflectionY = apexY + rise * 0.50

        var path = Path()
        path.move(to: point(left, baseY))
        path.addLine(to: point(left, springY))
        // Left limb: convex out of the jamb …
        path.addCurve(
            to: point(left + inflectionX, inflectionY),
            control1: point(left - span * 0.045, springY - rise * 0.26),
            control2: point(left + inflectionX - span * 0.075, inflectionY + rise * 0.16)
        )
        // … then concave into the pointed crown.
        path.addCurve(
            to: point(mid, apexY),
            control1: point(left + inflectionX + span * 0.09, inflectionY - rise * 0.20),
            control2: point(mid - span * 0.155, apexY + rise * 0.20)
        )
        // Right limb, mirrored.
        path.addCurve(
            to: point(right - inflectionX, inflectionY),
            control1: point(mid + span * 0.155, apexY + rise * 0.20),
            control2: point(right - inflectionX - span * 0.09, inflectionY - rise * 0.20)
        )
        path.addCurve(
            to: point(right, springY),
            control1: point(right - inflectionX + span * 0.075, inflectionY + rise * 0.16),
            control2: point(right + span * 0.045, springY - rise * 0.26)
        )
        path.addLine(to: point(right, baseY))
        return path
    }
}

// MARK: - Mark

/// The Mihrab brand mark.
///
/// A pointed prayer niche, an echo of itself inset within, a lamp of light
/// hanging in the recess and a plinth line under both. Vector rather than a
/// bitmap so it is crisp at 16 pt and at 1024 pt, follows the theme colour,
/// scales with Dynamic Type wherever it is placed next to text, and adds
/// nothing to the app's download size.
///
/// Replaces the old arch-plus-crescent lockup, whose crescent read as a
/// stray capital "C" at hero sizes.
struct MihrabMark: View {
    /// Height in points; the width follows the 100:128 canon.
    var height: CGFloat = 128
    /// 0…1 — lets the splash draw the outline on. 1 is the finished mark.
    var drawProgress: CGFloat = 1
    /// Fades the lamp and plinth in behind the outline.
    var detailOpacity: Double = 1
    var tint: Color = MihrabColor.brass

    private var width: CGFloat { height * 100 / 128 }
    /// One design unit, so every weight below is proportional.
    private var unit: CGFloat { height / 128 }

    var body: some View {
        ZStack {
            // Outer niche — the load-bearing line of the whole identity.
            MihrabArch()
                .trim(from: 0, to: drawProgress)
                .stroke(
                    LinearGradient(
                        colors: [tint, tint.opacity(0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 2.1 * unit, lineCap: .round, lineJoin: .round)
                )

            // Inner echo. Same curve, stepped in — depth, not decoration.
            MihrabArch(inset: 17)
                .trim(from: 0, to: drawProgress)
                .stroke(tint.opacity(0.5), style: StrokeStyle(lineWidth: 1.3 * unit, lineCap: .round))

            lamp
            plinth
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }

    /// A single point of light in the recess, over the sill it rests on.
    /// Solid, centred, circular — it cannot be misread as a letterform the
    /// way a crescent could. The canonical centre of the design space is
    /// (50, 64), which is also the centre of the frame, so the lamp needs no
    /// offset at all.
    private var lamp: some View {
        ZStack {
            Circle()
                .fill(tint)
                .frame(width: 11 * unit, height: 11 * unit)
                .overlay {
                    Circle()
                        .strokeBorder(tint.opacity(0.45), lineWidth: 1.1 * unit)
                        .padding(-4 * unit)
                }

            // Sill at canonical y = 81, i.e. 17 units below centre.
            Capsule()
                .fill(tint.opacity(0.8))
                .frame(width: 28 * unit, height: 1.6 * unit)
                .offset(y: 17 * unit)
        }
        .opacity(detailOpacity)
    }

    /// The floor the niche stands on — closes the silhouette so the two
    /// jambs do not trail off the bottom of the frame. Canonical y = 120.
    private var plinth: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [tint.opacity(0), tint, tint.opacity(0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 96 * unit, height: 1.8 * unit)
            .offset(y: 56 * unit)
            .opacity(detailOpacity)
    }
}

// MARK: - Rosette

/// The ornament that sits behind Arabic calligraphy.
///
/// **Radial symmetry only, and never six-fold.** The previous ornament was a
/// *rub el hizb* — two squares at 45° — which at low contrast behind a name
/// read to users as a hexagram. Nothing here is built from triangles or from
/// overlapping polygons: it is a ring of `lobes` identical scallops around
/// concentric circles, with a short tick between each pair. At the default
/// sixteen lobes there is no six-fold reading available at all.
struct MihrabRosette: View {
    var side: CGFloat = 240
    /// Must stay away from 6 and 12-as-two-hexagons readings; 8, 12 and 16 are
    /// the safe Islamic counts and 16 is the default.
    var lobes: Int = 16
    var lineWidth: CGFloat = 1
    var opacity: Double = 0.22
    var tint: Color = MihrabColor.brass

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let outer = side / 2
            let strong = GraphicsContext.Shading.color(tint.opacity(opacity))
            let soft = GraphicsContext.Shading.color(tint.opacity(opacity * 0.6))

            context.stroke(circle(center, outer), with: strong, lineWidth: lineWidth)
            context.stroke(circle(center, outer * 0.80), with: soft, lineWidth: lineWidth)
            context.stroke(circle(center, outer * 0.34), with: soft, lineWidth: lineWidth)

            let count = max(6, lobes)
            let step = 2 * .pi / Double(count)
            // Scalloped petal ring: each lobe is one arc bulging outwards
            // between two spokes. Curves only — no straight-edged polygon can
            // form, so no star-of-David reading can emerge.
            var petals = Path()
            for index in 0..<count {
                let start = Double(index) * step - .pi / 2
                let end = start + step
                let a = polar(center, outer * 0.80, start)
                let b = polar(center, outer * 0.80, end)
                // Just inside the outer ring, so the scallops tuck under it
                // rather than poke through.
                let bulge = polar(center, outer * 0.965, start + step / 2)
                petals.move(to: a)
                petals.addQuadCurve(to: b, control: bulge)
            }
            context.stroke(petals, with: strong, lineWidth: lineWidth)

            // Ticks sit on the spokes *between* petals, halving any chance of
            // the eye grouping lobes into a coarser symmetry.
            var ticks = Path()
            for index in 0..<count {
                let angle = Double(index) * step - .pi / 2
                ticks.move(to: polar(center, outer * 0.34, angle))
                ticks.addLine(to: polar(center, outer * 0.47, angle))
            }
            context.stroke(ticks, with: soft, lineWidth: lineWidth)
        }
        .frame(width: side, height: side)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func polar(_ center: CGPoint, _ radius: CGFloat, _ angle: Double) -> CGPoint {
        CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
    }

    private func circle(_ center: CGPoint, _ radius: CGFloat) -> Path {
        Path(ellipseIn: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
    }
}

// MARK: - Illustration plate

/// Frame for the generated onboarding artwork.
///
/// The illustrations are decorative: they carry no information the copy does
/// not already carry. So they are hidden from VoiceOver, Reduce Transparency
/// drops the halo behind them rather than dimming the art, and — the part
/// that matters most for the older users this app is built for — at
/// accessibility text sizes they **disappear entirely** and give their
/// vertical space back to the words. Decoration should never be the reason a
/// button falls below the fold.
struct MihrabIllustration: View {
    let asset: String
    var height: CGFloat = 180

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Grows a little with text size, then gives up rather than crowd it out.
    private var resolvedHeight: CGFloat {
        dynamicTypeSize >= .xxLarge ? height * 0.78 : height
    }

    var body: some View {
        if !dynamicTypeSize.isAccessibilitySize {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: resolvedHeight)
                .background {
                    if !reduceTransparency {
                        RadialGradient(
                            colors: [MihrabColor.emerald.opacity(0.30), .clear],
                            center: .center,
                            startRadius: 6,
                            endRadius: resolvedHeight * 0.8
                        )
                    }
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    ZStack {
        MihrabColor.abyss.ignoresSafeArea()
        VStack(spacing: 40) {
            MihrabMark(height: 160)
            MihrabRosette(side: 180, opacity: 0.5)
        }
    }
}
