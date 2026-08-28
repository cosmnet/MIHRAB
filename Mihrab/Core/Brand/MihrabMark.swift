import SwiftUI

// MARK: - Geometry primitive

/// Appends a two-centred pointed (*ogee*) arch to `path`, springing from
/// `(left, springY)` to `(right, springY)` with its point at `apexY`.
///
/// Convex where it leaves the jamb, concave as it climbs, meeting in a point.
/// A single arc would give a Roman semicircle — and a semicircle is exactly
/// what read as a stray capital "C" in the first mark.
///
/// `flare` pushes the springing outwards for a lone arch. In an arcade it is
/// zero, so the curve leaves the capital vertically and runs on into the
/// column below without a kink.
///
/// This is the one piece of geometry the whole brand is built on. The mark,
/// the paywall's flanking niches and `Scripts/generate_icon.swift` all call
/// the same numbers, so nothing drifts between 20 pt and 1024 px.
private func appendOgee(
    to path: inout Path,
    left: CGFloat,
    right: CGFloat,
    springY: CGFloat,
    apexY: CGFloat,
    flare: CGFloat,
    _ point: (CGFloat, CGFloat) -> CGPoint
) {
    let span = right - left
    let rise = springY - apexY
    let mid = (left + right) / 2
    // The inflection is where the curve changes hands.
    let ix = span * 0.13
    let iy = apexY + rise * 0.50

    path.addCurve(
        to: point(left + ix, iy),
        control1: point(left - span * flare, springY - rise * 0.26),
        control2: point(left + ix - span * 0.075, iy + rise * 0.16)
    )
    path.addCurve(
        to: point(mid, apexY),
        control1: point(left + ix + span * 0.09, iy - rise * 0.20),
        control2: point(mid - span * 0.155, apexY + rise * 0.20)
    )
    path.addCurve(
        to: point(right - ix, iy),
        control1: point(mid + span * 0.155, apexY + rise * 0.20),
        control2: point(right - ix - span * 0.09, iy - rise * 0.20)
    )
    path.addCurve(
        to: point(right, springY),
        control1: point(right - ix + span * 0.075, iy + rise * 0.16),
        control2: point(right + span * flare, springY - rise * 0.26)
    )
}

/// A single pointed niche, drawn in a canonical 100 × 128 design space and
/// mapped onto whatever rect it is handed.
///
/// Kept as its own shape because the paywall uses bare arches, faint and
/// un-animated, as depth flanking the mark.
///
/// The path is authored as **one continuous stroke** — up the left jamb, over
/// the crown, down the right jamb — which is what makes `.trim(from:to:)`
/// read as a single line drawing itself.
struct MihrabArch: Shape {
    /// 0 = the outer arch. Larger values step the arch inwards, giving the
    /// concentric "echo" that reads as depth in a real niche.
    var inset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width / 100, y: rect.minY + y * rect.height / 128)
        }

        // The crown drops faster than the jambs move in — that keeps the
        // inner arches concentric rather than merely narrower.
        let left = 10 + inset
        let right = 90 - inset
        let apexY = 6 + inset * 1.70
        let springY = 66 + inset * 0.35
        let baseY: CGFloat = 120

        var path = Path()
        path.move(to: point(left, baseY))
        path.addLine(to: point(left, springY))
        appendOgee(to: &path, left: left, right: right, springY: springY, apexY: apexY, flare: 0.045, point)
        path.addLine(to: point(right, baseY))
        return path
    }
}

// MARK: - Revak canon

/// The arcade's design space: **160 wide × 128 tall**, four columns, three
/// bays. The centre bay is both wider and much taller than its neighbours, so
/// as the mark shrinks the side bays fall away and the silhouette degrades
/// gracefully into a single crowned portal rather than into a comb of equal
/// teeth.
///
/// The proportion is the whole trick. An arcade drawn tall and narrow reads
/// Gothic; drawn wide and low, with capitals on the columns and a finial over
/// the centre, it reads as the courtyard of an Ottoman mosque.
private enum Revak {
    static let width: CGFloat = 160
    static let height: CGFloat = 128
    static let columns: [CGFloat] = [8, 56, 104, 152]
    static let spring: CGFloat = 62
    static let base: CGFloat = 122
    static let apexSide: CGFloat = 36
    static let apexMid: CGFloat = 12
    /// Half-width of a capital.
    static let capital: CGFloat = 7
    static let mid: CGFloat = 80

    // The mihrab niche recessed into the back wall of the central bay.
    static let nicheLeft: CGFloat = 64
    static let nicheRight: CGFloat = 96
    static let nicheSpring: CGFloat = 66
    static let nicheApex: CGFloat = 34

    /// Centre of the hanging lamp, and the two radii its petals swing between.
    static let lamp = CGPoint(x: 80, y: 80)
    static let lampInner: CGFloat = 8
    static let lampOuter: CGFloat = 13.5

    static func mapper(_ rect: CGRect) -> (CGFloat, CGFloat) -> CGPoint {
        { x, y in
            CGPoint(x: rect.minX + x * rect.width / width, y: rect.minY + y * rect.height / height)
        }
    }
}

/// The load-bearing line of the identity: a *revak*, the run of arches on
/// columns that wraps a mosque courtyard.
///
/// Authored as **one continuous stroke** with no pen lifts — up the outer left
/// column, over three ogee bays, down the outer right column — so the splash's
/// `.trim(from:to:)` reads as a single line drawing the arcade bay by bay.
private struct RevakArcade: Shape {
    func path(in rect: CGRect) -> Path {
        let p = Revak.mapper(rect)
        let c = Revak.columns
        var path = Path()
        path.move(to: p(c[0], Revak.base))
        path.addLine(to: p(c[0], Revak.spring))
        appendOgee(to: &path, left: c[0], right: c[1], springY: Revak.spring, apexY: Revak.apexSide, flare: 0, p)
        appendOgee(to: &path, left: c[1], right: c[2], springY: Revak.spring, apexY: Revak.apexMid, flare: 0, p)
        appendOgee(to: &path, left: c[2], right: c[3], springY: Revak.spring, apexY: Revak.apexSide, flare: 0, p)
        path.addLine(to: p(c[3], Revak.base))
        return path
    }
}

/// The prayer niche inside the central bay — the *mihrab* the app was first
/// named for, now standing where a real one stands: under the middle arch of
/// the arcade. Also one continuous stroke, so it trims alongside the arcade.
private struct RevakNiche: Shape {
    func path(in rect: CGRect) -> Path {
        let p = Revak.mapper(rect)
        var path = Path()
        path.move(to: p(Revak.nicheLeft, Revak.base))
        path.addLine(to: p(Revak.nicheLeft, Revak.nicheSpring))
        appendOgee(
            to: &path, left: Revak.nicheLeft, right: Revak.nicheRight,
            springY: Revak.nicheSpring, apexY: Revak.nicheApex, flare: 0, p
        )
        path.addLine(to: p(Revak.nicheRight, Revak.base))
        return path
    }
}

/// The masonry: capitals across every column, the two interior shafts, the
/// floor they all stand on, and the finial (*alem*) crowning the centre.
///
/// Separate from the arcade line so the splash can settle it in behind the
/// drawn outline rather than trying to trim four disjoint runs.
private struct RevakStone: Shape {
    func path(in rect: CGRect) -> Path {
        let p = Revak.mapper(rect)
        var path = Path()

        for x in [Revak.columns[1], Revak.columns[2]] {
            path.move(to: p(x, Revak.spring))
            path.addLine(to: p(x, Revak.base))
        }
        for x in Revak.columns {
            path.move(to: p(x - Revak.capital, Revak.spring))
            path.addLine(to: p(x + Revak.capital, Revak.spring))
        }
        path.move(to: p(2, Revak.base))
        path.addLine(to: p(Revak.width - 2, Revak.base))

        path.move(to: p(Revak.mid, Revak.apexMid - 1))
        path.addLine(to: p(Revak.mid, 5))
        return path
    }
}

/// The lamp hanging in the niche: eight scalloped petals around a disc.
///
/// **Radial symmetry only, and never six-fold.** Every petal is one
/// outward-bulging arc, so no straight-edged star can emerge from it at any
/// contrast — nothing here is built from triangles or overlapping polygons. At
/// small sizes the whole ornament collapses into a single warm point of light,
/// which is exactly what it should do.
private struct RevakLamp: Shape {
    var petals: Int = 8

    func path(in rect: CGRect) -> Path {
        let p = Revak.mapper(rect)
        let count = max(6, petals)
        let step = 2 * CGFloat.pi / CGFloat(count)

        func polar(_ radius: CGFloat, _ angle: CGFloat) -> CGPoint {
            p(Revak.lamp.x + cos(angle) * radius, Revak.lamp.y + sin(angle) * radius)
        }

        var path = Path()
        for index in 0..<count {
            let start = CGFloat(index) * step - .pi / 2
            path.move(to: polar(Revak.lampInner, start))
            path.addQuadCurve(
                to: polar(Revak.lampInner, start + step),
                control: polar(Revak.lampOuter, start + step / 2)
            )
        }
        return path
    }
}

// MARK: - Mark

/// The Revak brand mark.
///
/// *Revak* (رواق) is not one arch — it is the run of arches on columns that
/// wraps a mosque courtyard. So the mark is an arcade: a crowned central portal
/// between two lower bays, a mihrab niche recessed in the portal, an eight-fold
/// rosette lamp hanging in the niche, and the floor they all stand on.
///
/// Vector rather than a bitmap, so it is crisp at 16 pt and at 1024 pt, follows
/// the theme colour, scales with Dynamic Type wherever it sits next to text,
/// and adds nothing to the download.
///
/// **The mark is landscape** — 160 : 128, so `width` is 1.25 × `height`. Any
/// container that pins its width must allow for that.
struct MihrabMark: View {
    /// Height in points; the width follows the 160:128 canon.
    var height: CGFloat = 128
    /// 0…1 — lets the splash draw the outline on. 1 is the finished mark.
    var drawProgress: CGFloat = 1
    /// Fades the masonry, the finial and the lamp in behind the outline.
    var detailOpacity: Double = 1
    var tint: Color = MihrabColor.brass

    private var width: CGFloat { height * Revak.width / Revak.height }
    /// One design unit, so every weight below is proportional.
    private var unit: CGFloat { height / Revak.height }

    var body: some View {
        ZStack {
            // The arcade — the line the whole identity hangs on.
            RevakArcade()
                .trim(from: 0, to: drawProgress)
                .stroke(
                    LinearGradient(
                        colors: [tint, tint.opacity(0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 3.0 * unit, lineCap: .round, lineJoin: .round)
                )

            // Same curve, recessed.
            RevakNiche()
                .trim(from: 0, to: drawProgress)
                .stroke(tint.opacity(0.66), style: StrokeStyle(lineWidth: 1.9 * unit, lineCap: .round, lineJoin: .round))

            stone
            lamp
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }

    private var stone: some View {
        ZStack {
            RevakStone()
                .stroke(tint.opacity(0.9), style: StrokeStyle(lineWidth: 2.4 * unit, lineCap: .round))

            // The bead on top of the finial. Canonical (80, 2.6) in a
            // 160 × 128 space, i.e. 61.4 units above the frame's centre.
            Circle()
                .fill(tint)
                .frame(width: 4.8 * unit, height: 4.8 * unit)
                .offset(y: -61.4 * unit)
        }
        .opacity(detailOpacity)
    }

    private var lamp: some View {
        ZStack {
            RevakLamp()
                .stroke(tint.opacity(0.92), style: StrokeStyle(lineWidth: 1.9 * unit, lineCap: .round, lineJoin: .round))
                .frame(width: width, height: height)

            // The lamp is centred on (80, 80) in a 160 × 128 space; the
            // frame's own centre is (80, 64), so the ring and disc hang 16
            // units low.
            Circle()
                .strokeBorder(tint.opacity(0.55), lineWidth: 1.5 * unit)
                .frame(width: Revak.lampInner * 2 * unit, height: Revak.lampInner * 2 * unit)
                .offset(y: 16 * unit)

            Circle()
                .fill(tint)
                .frame(width: 6.4 * unit, height: 6.4 * unit)
                .offset(y: 16 * unit)
        }
        .opacity(detailOpacity)
    }
}

// MARK: - Rosette

/// The ornament that sits behind Arabic calligraphy.
///
/// **Radial symmetry only, and never six-fold.** The original ornament was a
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
                        // The gradient fills whatever size it is proposed, and a
                        // `.background` proposes the *content's* size. With an
                        // endRadius wider than the artwork the falloff was being
                        // squeezed into that rectangle and ended in a hard edge.
                        // Giving it its own, larger frame lets it fade out.
                        RadialGradient(
                            colors: [MihrabColor.emerald.opacity(0.30), .clear],
                            center: .center,
                            startRadius: 6,
                            endRadius: resolvedHeight * 0.8
                        )
                        .frame(width: resolvedHeight * 1.8, height: resolvedHeight * 1.8)
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
            MihrabMark(height: 44)
            MihrabMark(height: 20)
            MihrabRosette(side: 180, opacity: 0.5)
        }
    }
}
