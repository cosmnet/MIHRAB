import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Revak app icon. Opaque (App Store rejects alpha in the 1024 marketing
// icon), and built from the *same* canonical 160 × 128 arcade as `RevakArcade`
// in Mihrab/Core/Brand/MihrabMark.swift, so the icon, the splash, the welcome
// screen and the paywall are one drawing at four sizes.
//
// Usage: swift Scripts/generate_icon.swift <out.png> [size]

let size = CommandLine.arguments.count > 2 ? Int(CommandLine.arguments[2])! : 1024
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
)!
ctx.interpolationQuality = .high
let S = CGFloat(size) / 1024   // everything below is authored at 1024

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [
        CGFloat((hex >> 16) & 0xFF) / 255,
        CGFloat((hex >> 8) & 0xFF) / 255,
        CGFloat(hex & 0xFF) / 255, alpha,
    ])!
}

// MARK: - Ground

// Forest at the crown falling to abyss at the floor. Fully opaque — there is
// no alpha anywhere in this image.
ctx.setFillColor(color(0x07120D))
ctx.fill(CGRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size)))
let sky = CGGradient(colorsSpace: cs, colors: [color(0x14351F), color(0x07120D)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(
    sky, start: CGPoint(x: 512 * S, y: 1024 * S), end: CGPoint(x: 512 * S, y: 120 * S), options: []
)

// A soft emerald pool behind the arcade, so the mark is not floating on flat
// black. startRadius must be 0 — a non-zero inner radius leaves an unpainted
// disc that reads as a hole punched in the icon.
let pool = CGGradient(colorsSpace: cs, colors: [color(0x1E5C3A, 1), color(0x07120D, 0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(
    pool, startCenter: CGPoint(x: 512 * S, y: 545 * S), startRadius: 0,
    endCenter: CGPoint(x: 512 * S, y: 545 * S), endRadius: 450 * S, options: []
)

// MARK: - Revak canon (160 × 128 design units)

let W: CGFloat = 160, H: CGFloat = 128
let MID: CGFloat = 80
let COL: [CGFloat] = [8, 56, 104, 152]     // four columns, three bays
let SPRING: CGFloat = 62, BASE: CGFloat = 122
let APEX_SIDE: CGFloat = 36, APEX_MID: CGFloat = 12
let CAP: CGFloat = 7                        // capital half-width
let NICHE_L: CGFloat = 64, NICHE_R: CGFloat = 96
let NICHE_SPRING: CGFloat = 66, NICHE_APEX: CGFloat = 34
let LAMP = CGPoint(x: 80, y: 80)
let LAMP_IN: CGFloat = 8, LAMP_OUT: CGFloat = 13.5
let gold: UInt32 = 0xC9A24B

// The mark box, centred, at 63% of the canvas — generous margin so nothing
// clips under the iOS corner mask.
let markH: CGFloat = 630 * S
let markW = markH * W / H
let box = CGRect(
    x: (CGFloat(size) - markW) / 2,
    y: (CGFloat(size) - markH) / 2,
    width: markW, height: markH
)
let unit = markH / H

func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
    // Canonical space is y-down; CoreGraphics is y-up.
    CGPoint(x: box.minX + x * box.width / W, y: box.maxY - y * box.height / H)
}

/// Two-centred pointed (ogee) arch — the one primitive the brand is built on.
/// Convex out of the jamb, concave into the point. `flare` is 0 in an arcade
/// so the curve leaves the capital vertically, straight into the column below.
func ogee(_ p: CGMutablePath, _ left: CGFloat, _ right: CGFloat,
          _ springY: CGFloat, _ apexY: CGFloat, _ flare: CGFloat = 0) {
    let span = right - left, rise = springY - apexY, mid = (left + right) / 2
    let ix = span * 0.13, iy = apexY + rise * 0.50   // the inflection
    p.addCurve(to: P(left + ix, iy),
               control1: P(left - span * flare, springY - rise * 0.26),
               control2: P(left + ix - span * 0.075, iy + rise * 0.16))
    p.addCurve(to: P(mid, apexY),
               control1: P(left + ix + span * 0.09, iy - rise * 0.20),
               control2: P(mid - span * 0.155, apexY + rise * 0.20))
    p.addCurve(to: P(right - ix, iy),
               control1: P(mid + span * 0.155, apexY + rise * 0.20),
               control2: P(right - ix - span * 0.09, iy - rise * 0.20))
    p.addCurve(to: P(right, springY),
               control1: P(right - ix + span * 0.075, iy + rise * 0.16),
               control2: P(right + span * flare, springY - rise * 0.26))
}

// MARK: - Arcade

let arcade = CGMutablePath()
arcade.move(to: P(COL[0], BASE))
arcade.addLine(to: P(COL[0], SPRING))
ogee(arcade, COL[0], COL[1], SPRING, APEX_SIDE)
ogee(arcade, COL[1], COL[2], SPRING, APEX_MID)
ogee(arcade, COL[2], COL[3], SPRING, APEX_SIDE)
arcade.addLine(to: P(COL[3], BASE))

ctx.setLineCap(.round)
ctx.setLineJoin(.round)
ctx.setStrokeColor(color(gold))
ctx.setLineWidth(3.4 * unit)
ctx.addPath(arcade)
ctx.strokePath()

// The mihrab niche recessed in the back wall of the central bay.
let niche = CGMutablePath()
niche.move(to: P(NICHE_L, BASE))
niche.addLine(to: P(NICHE_L, NICHE_SPRING))
ogee(niche, NICHE_L, NICHE_R, NICHE_SPRING, NICHE_APEX)
niche.addLine(to: P(NICHE_R, BASE))
ctx.setStrokeColor(color(gold, 0.66))
ctx.setLineWidth(2.0 * unit)
ctx.addPath(niche)
ctx.strokePath()

// Capitals, interior columns and the floor they all stand on.
let stone = CGMutablePath()
for x in [COL[1], COL[2]] {
    stone.move(to: P(x, SPRING))
    stone.addLine(to: P(x, BASE))
}
for x in COL {
    stone.move(to: P(x - CAP, SPRING))
    stone.addLine(to: P(x + CAP, SPRING))
}
stone.move(to: P(2, BASE))
stone.addLine(to: P(W - 2, BASE))
ctx.setStrokeColor(color(gold, 0.9))
ctx.setLineWidth(2.6 * unit)
ctx.addPath(stone)
ctx.strokePath()

// The finial (alem) crowning the central portal.
ctx.setStrokeColor(color(gold))
ctx.setLineWidth(2.6 * unit)
ctx.move(to: P(MID, APEX_MID - 1))
ctx.addLine(to: P(MID, 5))
ctx.strokePath()
let finial = P(MID, 2.6)
ctx.setFillColor(color(gold))
ctx.fillEllipse(in: CGRect(x: finial.x - 2.4 * unit, y: finial.y - 2.4 * unit, width: 4.8 * unit, height: 4.8 * unit))

// Lamp: eight scalloped petals, a halo ring and a solid disc. Curves only —
// nothing here can collapse into a straight-edged star at any contrast.
let petals = CGMutablePath()
let step = 2 * CGFloat.pi / 8
func polar(_ radius: CGFloat, _ angle: CGFloat) -> CGPoint {
    P(LAMP.x + cos(angle) * radius, LAMP.y + sin(angle) * radius)
}
for index in 0..<8 {
    let start = CGFloat(index) * step - .pi / 2
    petals.move(to: polar(LAMP_IN, start))
    petals.addQuadCurve(to: polar(LAMP_IN, start + step), control: polar(LAMP_OUT, start + step / 2))
}
ctx.setStrokeColor(color(gold, 0.92))
ctx.setLineWidth(2.0 * unit)
ctx.addPath(petals)
ctx.strokePath()

let lamp = P(LAMP.x, LAMP.y)
ctx.setStrokeColor(color(gold, 0.55))
ctx.setLineWidth(1.6 * unit)
ctx.strokeEllipse(in: CGRect(
    x: lamp.x - LAMP_IN * unit, y: lamp.y - LAMP_IN * unit,
    width: LAMP_IN * 2 * unit, height: LAMP_IN * 2 * unit
))
ctx.setFillColor(color(gold))
ctx.fillEllipse(in: CGRect(x: lamp.x - 3.2 * unit, y: lamp.y - 3.2 * unit, width: 6.4 * unit, height: 6.4 * unit))

// MARK: - Write

guard let image = ctx.makeImage() else { fatalError("no image") }
let url = URL(fileURLWithPath: CommandLine.arguments[1])
let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("wrote \(url.path) at \(size)×\(size)")
