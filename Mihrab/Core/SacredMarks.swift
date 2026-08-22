import SwiftUI

/// 8pt rhythm + shared radii. Cards 28, rows 20, hits 44.
enum MihrabSpace {
    static let unit: CGFloat = 8
    static let cardRadius: CGFloat = 28
    static let rowRadius: CGFloat = 20
    static let pillRadius: CGFloat = 20
    static let timeColumn: CGFloat = 90
    static let rowHeight: CGFloat = 68
    static let hit: CGFloat = 44
    static let tabClearance: CGFloat = 128
}

extension View {
    /// Brass ornamental caps — 11pt, tracking 1.5.
    func ornamentalCaps(_ color: Color = MihrabColor.brass) -> some View {
        font(.system(size: 11, weight: .medium))
            .tracking(1.5)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }

    func mihrabTabScroll() -> some View {
        scrollEdgeEffectStyle(.soft, for: .top)
            .scrollEdgeEffectStyle(.soft, for: .bottom)
    }
}

/// Transparent catalog ornament. Never a boxed photo — isolated PNG, low opacity.
struct MihrabOrnament: View {
    let name: String
    var opacity: Double = 0.14
    var side: CGFloat? = nil
    var blend: BlendMode = .normal

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: side, height: side)
            .opacity(opacity)
            .blendMode(blend)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// Drawn crescent — never a photo box.
struct BrassCrescent: View {
    var diameter: CGFloat = 72
    var opacity: Double = 0.16

    var body: some View {
        Canvas { context, size in
            let side = min(diameter, min(size.width, size.height))
            let origin = CGPoint(x: (size.width - side) / 2, y: (size.height - side) / 2)
            var moon = Path(ellipseIn: CGRect(origin: origin, size: CGSize(width: side, height: side)))
            moon.addEllipse(in: CGRect(
                x: origin.x + side * 0.32,
                y: origin.y - side * 0.04,
                width: side,
                height: side
            ))
            context.fill(moon, with: .color(MihrabColor.brass.opacity(opacity)), style: FillStyle(eoFill: true))
        }
        .frame(width: diameter, height: diameter)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Welcome / empty-state arch. Stroke only, no bitmap.
struct MihrabArchMark: View {
    var body: some View {
        ZStack {
            MihrabArchShape()
                .stroke(
                    LinearGradient(
                        colors: [MihrabColor.brass, MihrabColor.brass.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
                .frame(width: 120, height: 156)

            BrassCrescent(diameter: 44, opacity: 0.85)
                .offset(y: -10)
        }
        .frame(width: 168, height: 188)
        .accessibilityHidden(true)
    }
}

private struct MihrabArchShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = rect.width * 0.08
        path.move(to: CGPoint(x: rect.minX + inset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.midY + 8))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - inset, y: rect.midY + 8),
            control: CGPoint(x: rect.midX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY))
        return path
    }
}

/// Crescent-fill progress for Ramadan — vector, not `moon-phase.png`.
struct CrescentFillMark: View {
    var progress: Double

    var body: some View {
        ZStack {
            BrassCrescent(diameter: 64, opacity: 0.28)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(MihrabColor.ramadanGold, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 68, height: 68)
        }
        .frame(width: 72, height: 72)
        .accessibilityHidden(true)
    }
}
