import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Mihrab app icon. Opaque (App Store rejects alpha in the 1024 marketing
// icon), and built from the *same* canonical 100 × 128 arch as
// `MihrabArch` in Mihrab/Core/Brand/MihrabMark.swift, so the icon, the
// splash, the welcome screen and the paywall are one drawing at four sizes.

let size = 1024
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
)!

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [
        CGFloat((hex >> 16) & 0xFF) / 255,
        CGFloat((hex >> 8) & 0xFF) / 255,
        CGFloat(hex & 0xFF) / 255, alpha,
    ])!
}

// Ground: forest at the crown falling to abyss at the floor. Fully opaque —
// no alpha anywhere in this image.
let full = CGRect(x: 0, y: 0, width: size, height: size)
ctx.setFillColor(color(0x07120D))
ctx.fill(full)
let sky = CGGradient(colorsSpace: cs, colors: [color(0x14351F), color(0x07120D)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(sky, start: CGPoint(x: 512, y: 1024), end: CGPoint(x: 512, y: 120), options: [])

// A soft emerald pool behind the niche, so the mark is not floating on flat black.
ctx.saveGState()
let pool = CGGradient(colorsSpace: cs, colors: [color(0x1E5C3A, 1), color(0x07120D, 0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(
    pool, startCenter: CGPoint(x: 512, y: 560), startRadius: 20,
    endCenter: CGPoint(x: 512, y: 560), endRadius: 430, options: []
)
ctx.restoreGState()

// The mark occupies a 100 × 128 box, centred, at 62% of the canvas height —
// generous margin so nothing clips under the iOS corner mask.
let markH: CGFloat = 640
let markW = markH * 100 / 128
let box = CGRect(x: (CGFloat(size) - markW) / 2, y: (CGFloat(size) - markH) / 2, width: markW, height: markH)
let unit = markH / 128

func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
    // Canonical space is y-down; CoreGraphics is y-up.
    CGPoint(x: box.minX + x * box.width / 100, y: box.maxY - y * box.height / 128)
}

func arch(_ inset: CGFloat) -> CGPath {
    let left = 10 + inset, right = 90 - inset
    let apexY = 6 + inset * 1.70
    let springY = 66 + inset * 0.35
    let baseY: CGFloat = 120
    let mid = (left + right) / 2, span = right - left, rise = springY - apexY
    let ix = span * 0.13, iy = apexY + rise * 0.50
    let p = CGMutablePath()
    p.move(to: P(left, baseY))
    p.addLine(to: P(left, springY))
    p.addCurve(to: P(left + ix, iy),
               control1: P(left - span * 0.045, springY - rise * 0.26),
               control2: P(left + ix - span * 0.075, iy + rise * 0.16))
    p.addCurve(to: P(mid, apexY),
               control1: P(left + ix + span * 0.09, iy - rise * 0.20),
               control2: P(mid - span * 0.155, apexY + rise * 0.20))
    p.addCurve(to: P(right - ix, iy),
               control1: P(mid + span * 0.155, apexY + rise * 0.20),
               control2: P(right - ix - span * 0.09, iy - rise * 0.20))
    p.addCurve(to: P(right, springY),
               control1: P(right - ix + span * 0.075, iy + rise * 0.16),
               control2: P(right + span * 0.045, springY - rise * 0.26))
    p.addLine(to: P(right, baseY))
    return p
}

ctx.setLineCap(.round)
ctx.setLineJoin(.round)
ctx.setStrokeColor(color(0xC9A24B))
ctx.setLineWidth(3.2 * unit)
ctx.addPath(arch(0))
ctx.strokePath()

ctx.setStrokeColor(color(0xC9A24B, 0.62))
ctx.setLineWidth(2.0 * unit)
ctx.addPath(arch(17))
ctx.strokePath()

// Lamp: solid disc, halo ring, sill.
let lamp = P(50, 64)
ctx.setFillColor(color(0xC9A24B))
ctx.fillEllipse(in: CGRect(x: lamp.x - 5.5 * unit, y: lamp.y - 5.5 * unit, width: 11 * unit, height: 11 * unit))
ctx.setStrokeColor(color(0xC9A24B, 0.55))
ctx.setLineWidth(1.3 * unit)
ctx.strokeEllipse(in: CGRect(x: lamp.x - 9.5 * unit, y: lamp.y - 9.5 * unit, width: 19 * unit, height: 19 * unit))
ctx.setStrokeColor(color(0xC9A24B, 0.85))
ctx.setLineWidth(1.9 * unit)
ctx.move(to: P(36, 81)); ctx.addLine(to: P(64, 81)); ctx.strokePath()

// Plinth.
ctx.setStrokeColor(color(0xC9A24B))
ctx.setLineWidth(2.8 * unit)
ctx.move(to: P(3, 120)); ctx.addLine(to: P(97, 120)); ctx.strokePath()

guard let image = ctx.makeImage() else { fatalError("no image") }
let url = URL(fileURLWithPath: CommandLine.arguments[1])
let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("wrote \(url.path)")
