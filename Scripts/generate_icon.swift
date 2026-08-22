import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Deep forest green icon with a brass crescent inside a mihrab arch.
let size = 1024
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8,
    bytesPerRow: 0, space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!

func color(_ hex: UInt32) -> CGColor {
    CGColor(
        colorSpace: colorSpace,
        components: [
            CGFloat((hex >> 16) & 0xFF) / 255,
            CGFloat((hex >> 8) & 0xFF) / 255,
            CGFloat(hex & 0xFF) / 255,
            1,
        ]
    )!
}

// Background: abyss → forest vertical gradient
let gradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [color(0x0D2418), color(0x07120D)] as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(
    gradient,
    start: CGPoint(x: size / 2, y: size),
    end: CGPoint(x: size / 2, y: 0),
    options: []
)

// Mihrab arch silhouette (subtle emerald glow)
let arch = CGMutablePath()
let archW: CGFloat = 560
let archH: CGFloat = 760
let archX = (CGFloat(size) - archW) / 2
let archY: CGFloat = 140
arch.move(to: CGPoint(x: archX, y: archY))
arch.addLine(to: CGPoint(x: archX, y: archY + archH * 0.55))
arch.addQuadCurve(
    to: CGPoint(x: archX + archW, y: archY + archH * 0.55),
    control: CGPoint(x: archX + archW / 2, y: archY + archH * 1.25)
)
arch.addLine(to: CGPoint(x: archX + archW, y: archY))
arch.closeSubpath()
ctx.setFillColor(color(0x143322))
ctx.addPath(arch)
ctx.fillPath()
ctx.setStrokeColor(color(0x1FA96B))
ctx.setLineWidth(10)
ctx.addPath(arch)
ctx.strokePath()

// Brass crescent
let crescentCenter = CGPoint(x: CGFloat(size) / 2, y: archY + archH * 0.48)
let outerR: CGFloat = 150
ctx.setFillColor(color(0xC9A24B))
ctx.addArc(center: crescentCenter, radius: outerR, startAngle: 0, endAngle: .pi * 2, clockwise: false)
ctx.fillPath()
ctx.setFillColor(color(0x143322))
ctx.addArc(
    center: CGPoint(x: crescentCenter.x + 55, y: crescentCenter.y + 20),
    radius: outerR * 0.82, startAngle: 0, endAngle: .pi * 2, clockwise: false
)
ctx.fillPath()

// Small brass star
let starCenter = CGPoint(x: crescentCenter.x + 120, y: crescentCenter.y - 40)
let starPath = CGMutablePath()
for i in 0..<10 {
    let angle = CGFloat(i) * .pi / 5 - .pi / 2
    let r: CGFloat = i.isMultiple(of: 2) ? 34 : 14
    let point = CGPoint(x: starCenter.x + r * cos(angle), y: starCenter.y + r * sin(angle))
    if i == 0 { starPath.move(to: point) } else { starPath.addLine(to: point) }
}
starPath.closeSubpath()
ctx.setFillColor(color(0xC9A24B))
ctx.addPath(starPath)
ctx.fillPath()

guard let image = ctx.makeImage() else { fatalError("no image") }
let outURL = URL(fileURLWithPath: CommandLine.arguments[1])
let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("wrote \(outURL.path)")
