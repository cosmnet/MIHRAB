#!/usr/bin/env swift
//
// compose.swift — Mihrab App Store screenshot compositor.
//
// Renders one raw device screenshot into a finished, branded App Store
// screenshot (device frame + gradient/aurora background + localized title)
// using CoreGraphics + CoreText. CoreText is required (not Python/PIL)
// because the Arabic title needs real shaping (letters joined) and
// right-to-left layout, which PIL cannot do.
//
// Usage:
//   swift Scripts/screenshots/compose.swift \
//     --lang tr --index 01 \
//     --raw store/screenshots/raw/tr/01-today.png \
//     --out store/screenshots/out/tr/01.png \
//     [--theme Scripts/screenshots/theme.json] \
//     [--captions Scripts/screenshots/captions.json] \
//     [--metadata-dir store/metadata] \
//     [--caption "Override text, skips file lookup"]
//
// Run from the repository root (relative default paths assume that cwd).
//
// Caption resolution order:
//   1. --caption flag, if given.
//   2. store/metadata/<lang>.md, "Ekran görüntüsü başlıkları" section
//      (or English/Arabic equivalent heading), Nth list item for index N.
//   3. Scripts/screenshots/captions.json[lang][index].
//   4. Scripts/screenshots/captions.json["en"][index].
//   5. The literal index string, as a last-resort visible fallback.

import Foundation
import CoreGraphics
import CoreText
import ImageIO
import CoreFoundation
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

// MARK: - CLI args

struct Args {
    var lang = "en"
    var index = "01"
    var raw = ""
    var out = ""
    var theme = "Scripts/screenshots/theme.json"
    var captions = "Scripts/screenshots/captions.json"
    var metadataDir = "store/metadata"
    var captionOverride: String?
}

func parseArgs() -> Args {
    var a = Args()
    let argv = CommandLine.arguments
    var i = 1
    func next() -> String? {
        i += 1
        return i < argv.count ? argv[i] : nil
    }
    while i < argv.count {
        switch argv[i] {
        case "--lang": a.lang = next() ?? a.lang
        case "--index": a.index = next() ?? a.index
        case "--raw": a.raw = next() ?? a.raw
        case "--out": a.out = next() ?? a.out
        case "--theme": a.theme = next() ?? a.theme
        case "--captions": a.captions = next() ?? a.captions
        case "--metadata-dir": a.metadataDir = next() ?? a.metadataDir
        case "--caption": a.captionOverride = next()
        default: break
        }
        i += 1
    }
    return a
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(("compose.swift: " + message + "\n").data(using: .utf8)!)
    exit(1)
}

let args = parseArgs()
if args.raw.isEmpty || args.out.isEmpty {
    fail("--raw and --out are required")
}

// MARK: - Theme model

struct AuroraPosition: Codable { let xFraction: Double; let yFraction: Double }

struct BackgroundTheme: Codable {
    let gradientTop: String
    let gradientBottom: String
    let auroraColor: String
    let auroraOpacity: Double
    let auroraRadiusFraction: Double
    let auroraPositions: [AuroraPosition]
}

struct TitleTheme: Codable {
    let topFraction: Double
    let bandHeightFraction: Double
    let fontSize: Double
    let fontSizeLong: Double
    let longThreshold: Int
    let lineSpacing: Double
    let color: String
    let horizontalMarginFraction: Double
    let dividerGap: Double
    let dividerWidth: Double
    let dividerThickness: Double
    let dividerColor: String
}

struct ShadowTheme: Codable {
    let color: String
    let opacity: Double
    let blur: Double
    let yOffset: Double
}

struct DeviceTheme: Codable {
    let cornerRadiusFraction: Double
    let borderWidth: Double
    let borderColor: String
    let borderOpacity: Double
    let screenInset: Double
    let widthFraction: Double
    let aspectRatio: Double
    let bottomOverflowFraction: Double
    let topFraction: Double
    let shadow: ShadowTheme
}

struct CanvasTheme: Codable { let width: Int; let height: Int }

struct FontsTheme: Codable {
    let title: String
    let titleWeight: String
    let arabicTitle: String
}

struct Theme: Codable {
    let canvas: CanvasTheme
    let colors: [String: String]
    let background: BackgroundTheme
    let title: TitleTheme
    let device: DeviceTheme
    let fonts: FontsTheme
}

func loadTheme(_ path: String) -> Theme {
    guard let data = FileManager.default.contents(atPath: path) else {
        fail("could not read theme file at \(path)")
    }
    do {
        return try JSONDecoder().decode(Theme.self, from: data)
    } catch {
        fail("theme JSON parse error: \(error)")
    }
}

let theme = loadTheme(args.theme)

func resolveColorHex(_ nameOrHex: String) -> String {
    if nameOrHex.hasPrefix("#") { return nameOrHex }
    return theme.colors[nameOrHex] ?? "#FFFFFF"
}

func cgColor(_ nameOrHex: String, alpha: CGFloat = 1) -> CGColor {
    let hex = resolveColorHex(nameOrHex)
    var s = hex
    if s.hasPrefix("#") { s.removeFirst() }
    guard let v = UInt32(s, radix: 16) else { return CGColor(red: 1, green: 1, blue: 1, alpha: alpha) }
    let r = CGFloat((v >> 16) & 0xFF) / 255
    let g = CGFloat((v >> 8) & 0xFF) / 255
    let b = CGFloat(v & 0xFF) / 255
    return CGColor(red: r, green: g, blue: b, alpha: alpha)
}

// MARK: - Caption resolution

func indexAsInt(_ s: String) -> Int { Int(s) ?? (Int(s.trimmingCharacters(in: .init(charactersIn: "0"))) ?? 0) }

/// Very small, format-tolerant Markdown list scraper. Looks for a heading
/// line containing one of the marker phrases, then reads subsequent lines
/// until the next heading, picking out list-item lines in order.
func captionFromMetadata(lang: String, index: String, metadataDir: String) -> String? {
    let path = metadataDir + "/" + lang + ".md"
    guard let data = FileManager.default.contents(atPath: path),
          let text = String(data: data, encoding: .utf8) else { return nil }

    let markers = [
        "ekran görüntüsü başlıkları",
        "screenshot titles",
        "screenshot captions",
        "عناوين لقطات الشاشة",
        "عناوين الشاشات"
    ]

    let lines = text.components(separatedBy: .newlines)
    var collecting = false
    var items: [String] = []

    for rawLine in lines {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        let lower = line.lowercased()
        if line.hasPrefix("#") {
            if collecting {
                // hit the next heading, stop collecting
                break
            }
            if markers.contains(where: { lower.contains($0) }) {
                collecting = true
            }
            continue
        }
        guard collecting, !line.isEmpty else { continue }

        // Strip common list-item prefixes: "1.", "01.", "1)", "01:", "- ", "* "
        var content = line
        if let dashRange = content.range(of: #"^[-*]\s+"#, options: .regularExpression) {
            content.removeSubrange(dashRange)
        } else if let numRange = content.range(of: #"^\d+[\.\):]\s*"#, options: .regularExpression) {
            content.removeSubrange(numRange)
        } else {
            // not a recognizable list item; ignore stray prose lines
            continue
        }
        content = content.trimmingCharacters(in: .whitespaces)
        if !content.isEmpty { items.append(content) }
    }

    let n = indexAsInt(index)
    guard n >= 1, n <= items.count else { return nil }
    return items[n - 1]
}

func captionFromJSON(lang: String, index: String, path: String) -> String? {
    guard let data = FileManager.default.contents(atPath: path) else { return nil }
    guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
    if let byLang = obj[lang] as? [String: String], let v = byLang[index] { return v }
    if let byEn = obj["en"] as? [String: String], let v = byEn[index] { return v }
    return nil
}

func resolveCaption() -> String {
    if let o = args.captionOverride { return o }
    if let fromMd = captionFromMetadata(lang: args.lang, index: args.index, metadataDir: args.metadataDir) {
        return fromMd
    }
    if let fromJson = captionFromJSON(lang: args.lang, index: args.index, path: args.captions) {
        return fromJson
    }
    return args.index
}

let captionText = resolveCaption()

// MARK: - Canvas setup

let canvasW = theme.canvas.width
let canvasH = theme.canvas.height

guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { fail("no sRGB colorspace") }
guard let ctx = CGContext(
    data: nil,
    width: canvasW,
    height: canvasH,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fail("could not create bitmap context") }

// CoreGraphics origin is bottom-left; keep a helper to flip a "from-top" y.
func fromTop(_ y: Double) -> CGFloat { CGFloat(canvasH) - CGFloat(y) }

// MARK: - Background: vertical gradient + aurora glow

func drawBackground() {
    let topColor = cgColor(theme.background.gradientTop)
    let bottomColor = cgColor(theme.background.gradientBottom)
    guard let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [topColor, bottomColor] as CFArray,
        locations: [0, 1]
    ) else { return }

    ctx.saveGState()
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: CGFloat(canvasH)),
        end: CGPoint(x: 0, y: 0),
        options: []
    )
    ctx.restoreGState()

    // Aurora: soft radial glow, position cycles per screenshot index so a
    // six-up row of screenshots doesn't look like six copies of one frame.
    let positions = theme.background.auroraPositions
    let n = max(indexAsInt(args.index) - 1, 0)
    let pos = positions.isEmpty ? AuroraPosition(xFraction: 0.5, yFraction: 0.2) : positions[n % positions.count]
    let center = CGPoint(x: CGFloat(pos.xFraction) * CGFloat(canvasW), y: fromTop(pos.yFraction * Double(canvasH)))
    let radius = CGFloat(theme.background.auroraRadiusFraction) * CGFloat(max(canvasW, canvasH))

    let auroraColor = cgColor(theme.background.auroraColor, alpha: CGFloat(theme.background.auroraOpacity))
    let clearColor = cgColor(theme.background.auroraColor, alpha: 0)
    guard let auroraGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [auroraColor, clearColor] as CFArray,
        locations: [0, 1]
    ) else { return }

    ctx.saveGState()
    ctx.drawRadialGradient(
        auroraGradient,
        startCenter: center, startRadius: 0,
        endCenter: center, endRadius: radius,
        options: []
    )
    ctx.restoreGState()
}

// MARK: - Device frame + screenshot

func drawDevice() {
    let d = theme.device
    let deviceW = CGFloat(d.widthFraction) * CGFloat(canvasW)
    let deviceH = deviceW / CGFloat(d.aspectRatio)
    let deviceX = (CGFloat(canvasW) - deviceW) / 2
    let deviceTopY = d.topFraction * Double(canvasH)
    // CG y (bottom-left origin) of the device's *top* edge:
    let deviceOriginY = fromTop(deviceTopY) - deviceH
    let cornerRadius = deviceW * CGFloat(d.cornerRadiusFraction)
    let outerRect = CGRect(x: deviceX, y: deviceOriginY, width: deviceW, height: deviceH)

    // Soft shadow, drawn as a filled shape behind everything else.
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -CGFloat(d.shadow.yOffset)),
        blur: CGFloat(d.shadow.blur),
        color: cgColor(d.shadow.color, alpha: CGFloat(d.shadow.opacity))
    )
    let shadowPath = CGPath(roundedRect: outerRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(shadowPath)
    ctx.setFillColor(cgColor(theme.background.gradientBottom))
    ctx.fillPath()
    ctx.restoreGState()

    // Screenshot content, clipped to the inset rounded rect.
    let inset = CGFloat(d.screenInset) + CGFloat(d.borderWidth)
    let innerRect = outerRect.insetBy(dx: inset, dy: inset)
    let innerRadius = max(cornerRadius - inset, 0)

    ctx.saveGState()
    let innerPath = CGPath(roundedRect: innerRect, cornerWidth: innerRadius, cornerHeight: innerRadius, transform: nil)
    ctx.addPath(innerPath)
    ctx.clip()

    if let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: args.raw) as CFURL, nil),
       let image = CGImageSourceCreateImageAtIndex(src, 0, nil) {
        // Aspect-fill the raw screenshot into innerRect.
        let imgW = CGFloat(image.width)
        let imgH = CGFloat(image.height)
        let scale = max(innerRect.width / imgW, innerRect.height / imgH)
        let drawW = imgW * scale
        let drawH = imgH * scale
        let drawX = innerRect.midX - drawW / 2
        let drawY = innerRect.midY - drawH / 2
        ctx.draw(image, in: CGRect(x: drawX, y: drawY, width: drawW, height: drawH))
    } else {
        FileHandle.standardError.write("compose.swift: warning: could not load raw screenshot at \(args.raw)\n".data(using: .utf8)!)
        ctx.setFillColor(cgColor(theme.background.gradientTop))
        ctx.fill(innerRect)
    }
    ctx.restoreGState()

    // Border, on top, unclipped.
    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: outerRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil))
    ctx.setStrokeColor(cgColor(d.borderColor, alpha: CGFloat(d.borderOpacity)))
    ctx.setLineWidth(CGFloat(d.borderWidth))
    ctx.strokePath()
    ctx.restoreGState()
}

// MARK: - Title (CoreText: shaping + bidi)

func isRTL(_ lang: String) -> Bool { lang == "ar" || lang == "ur" || lang == "fa" || lang == "he" }

func drawTitle() {
    let t = theme.title
    let rtl = isRTL(args.lang)

    var alignmentValue = CTTextAlignment.center
    var writingDirectionValue: CTWritingDirection = rtl ? .rightToLeft : .natural
    var lineSpacingValue = CGFloat(t.lineSpacing)

    let paragraph: CTParagraphStyle = withUnsafePointer(to: &alignmentValue) { alignPtr in
        withUnsafePointer(to: &writingDirectionValue) { dirPtr in
            withUnsafePointer(to: &lineSpacingValue) { spacingPtr in
                let settings = [
                    CTParagraphStyleSetting(
                        spec: .alignment,
                        valueSize: MemoryLayout<CTTextAlignment>.size,
                        value: UnsafeRawPointer(alignPtr)
                    ),
                    CTParagraphStyleSetting(
                        spec: .baseWritingDirection,
                        valueSize: MemoryLayout<CTWritingDirection>.size,
                        value: UnsafeRawPointer(dirPtr)
                    ),
                    CTParagraphStyleSetting(
                        spec: .lineSpacingAdjustment,
                        valueSize: MemoryLayout<CGFloat>.size,
                        value: UnsafeRawPointer(spacingPtr)
                    )
                ]
                return CTParagraphStyleCreate(settings, settings.count)
            }
        }
    }

    let useLongSize = captionText.count > t.longThreshold
    let fontSize = CGFloat(useLongSize ? t.fontSizeLong : t.fontSize)

    // Prefer a real bold weight; fall back gracefully if unavailable.
    var font = CTFontCreateWithName((theme.fonts.title as CFString), fontSize, nil)
    let boldTraits: CTFontSymbolicTraits = .traitBold
    if let bolded = CTFontCreateCopyWithSymbolicTraits(font, fontSize, nil, boldTraits, boldTraits) {
        font = bolded
    }

    let attrs: [CFString: Any] = [
        kCTFontAttributeName: font,
        kCTForegroundColorAttributeName: cgColor(t.color),
        kCTParagraphStyleAttributeName: paragraph
    ]

    let attrString = CFAttributedStringCreate(nil, captionText as CFString, attrs as CFDictionary)!
    let framesetter = CTFramesetterCreateWithAttributedString(attrString)

    let margin = CGFloat(t.horizontalMarginFraction) * CGFloat(canvasW)
    let boxWidth = CGFloat(canvasW) - margin * 2
    let boxHeight = CGFloat(t.bandHeightFraction) * CGFloat(canvasH)

    let fitRange = CFRangeMake(0, 0)
    let constraint = CGSize(width: boxWidth, height: .greatestFiniteMagnitude)
    let fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, fitRange, nil, constraint, nil)

    let bandTopY = t.topFraction * Double(canvasH)
    // Vertically center the (possibly one-line) text block inside the band.
    let textTopY = bandTopY + max((boxHeight - fitSize.height) / 2, 0)
    let textOriginY = fromTop(textTopY) - fitSize.height

    let path = CGPath(rect: CGRect(x: margin, y: textOriginY, width: boxWidth, height: fitSize.height), transform: nil)
    let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
    CTFrameDraw(frame, ctx)

    // Thin brass divider, centered, just below the text block.
    let dividerY = textOriginY - CGFloat(t.dividerGap)
    let dividerX = (CGFloat(canvasW) - CGFloat(t.dividerWidth)) / 2
    ctx.saveGState()
    ctx.setFillColor(cgColor(t.dividerColor))
    ctx.fill(CGRect(x: dividerX, y: dividerY, width: CGFloat(t.dividerWidth), height: CGFloat(t.dividerThickness)))
    ctx.restoreGState()
}

// MARK: - Render + write PNG

drawBackground()
drawDevice()
drawTitle()

guard let finalImage = ctx.makeImage() else { fail("could not render final image") }

let outURL = URL(fileURLWithPath: args.out)
try? FileManager.default.createDirectory(at: outURL.deletingLastPathComponent(), withIntermediateDirectories: true)

let pngType: CFString
if #available(macOS 11.0, *) {
    pngType = UTType.png.identifier as CFString
} else {
    pngType = "public.png" as CFString
}

guard let dest = CGImageDestinationCreateWithURL(outURL as CFURL, pngType, 1, nil) else {
    fail("could not create image destination at \(args.out)")
}
CGImageDestinationAddImage(dest, finalImage, nil)
if !CGImageDestinationFinalize(dest) {
    fail("could not write PNG to \(args.out)")
}

print("compose.swift: wrote \(args.out) (\(canvasW)x\(canvasH)) — \"\(captionText)\"")
