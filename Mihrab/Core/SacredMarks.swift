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

    /// Breathing room above the floating tab bar.
    ///
    /// iOS 26 already reports the tab bar inside the safe area of every tab's
    /// content, so this is a *gutter*, not a clearance — the old 128pt figure
    /// double-counted the bar, parking card edges exactly behind the glass and
    /// reading as a second, ghost bar. Keep it small and let the system inset
    /// plus the soft scroll-edge effect do the real work.
    static let tabClearance: CGFloat = 28
}

extension View {
    /// Brass ornamental caps — tracking 1.5. `.caption2` is 11pt at the default
    /// text size, so this is the same mark it always was, except it now grows
    /// with the reader.
    func ornamentalCaps(_ color: Color = MihrabColor.brass) -> some View {
        font(.caption2.weight(.medium))
            .tracking(1.5)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }

    /// Scroll views hosted in a tab: soft dissolve under both bars.
    ///
    /// The bottom effect only reads correctly when the scroll view actually
    /// owns the bottom edge, so this must sit on the `ScrollView` itself —
    /// never on an inner stack.
    func mihrabTabScroll() -> some View {
        scrollEdgeEffectStyle(.soft, for: .top)
            .scrollEdgeEffectStyle(.soft, for: .bottom)
    }

    /// Bottom inset for content that lives above the floating tab bar.
    ///
    /// `safeAreaPadding` *extends* the safe area instead of hard-padding the
    /// content, so it composes with the tab bar inset the system already
    /// supplies and with `.tabBarMinimizeBehavior(.onScrollDown)`: the last
    /// card ends a gutter above the bar, yet still dissolves under it while
    /// the scroll is in flight. Prefer this over `mihrabTabGutter()`.
    func mihrabTabSafeContent(_ extra: CGFloat = MihrabSpace.tabClearance) -> some View {
        safeAreaPadding(.bottom, extra)
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
