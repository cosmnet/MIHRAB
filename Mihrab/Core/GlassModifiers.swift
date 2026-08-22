import SwiftUI
import UIKit

/// Mihrab glass card: Liquid Glass over moss, with the "wet glass edge" stroke.
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 28
    var interactive: Bool = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .background {
                if reduceTransparency {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(MihrabColor.moss)
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(MihrabColor.moss.opacity(0.4))
                        .glassEffect(
                            interactive ? .regular.interactive() : .regular,
                            in: .rect(cornerRadius: cornerRadius)
                        )
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [MihrabColor.mint.opacity(0.6), .clear],
                            startPoint: .top,
                            endPoint: .center
                        ),
                        lineWidth: 1
                    )
                    .allowsHitTesting(false)
            }
    }
}

struct MihrabHairline: View {
    var body: some View {
        Rectangle()
            .fill(MihrabColor.mint.opacity(0.16))
            .frame(height: 1)
            .allowsHitTesting(false)
    }
}

extension View {
    func mihrabCard(cornerRadius: CGFloat = 28, interactive: Bool = false) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, interactive: interactive))
    }

    /// Illustrated fill *inside* a rounded card. No-ops when `UIImage(named:)` is nil.
    func mihrabCardScene(
        _ name: String,
        opacity: Double = 0.42,
        cornerRadius: CGFloat = MihrabSpace.cardRadius
    ) -> some View {
        modifier(CardSceneModifier(name: name, opacity: opacity, cornerRadius: cornerRadius))
    }

    /// Opaque moss card — no liquid glass. Use on list rows so text stays readable.
    func mihrabSolidCard(
        cornerRadius: CGFloat = 22,
        fill: Color = MihrabColor.moss,
        stroke: Color = MihrabColor.mint.opacity(0.28)
    ) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(fill)
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(stroke, lineWidth: 1)
                .allowsHitTesting(false)
        }
    }

    func mihrabHairline() -> some View {
        MihrabHairline()
    }

    func mihrabTabGutter() -> some View {
        padding(.bottom, MihrabSpace.tabClearance)
    }

    /// Soft leading/trailing dissolve so horizontal strips never hard-clip.
    func softHorizontalFade(edgeWidth: CGFloat = 24) -> some View {
        mask {
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [.clear, .black],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: edgeWidth)
                Rectangle().fill(.black)
                LinearGradient(
                    colors: [.black, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: edgeWidth)
            }
        }
    }

    /// Staggered spring entrance per §9 recipe #2.
    func cardEntrance(index: Int, appeared: Bool, reduceMotion: Bool) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 24)
            .scaleEffect(appeared || reduceMotion ? 1 : 0.97)
            .animation(
                reduceMotion
                    ? .easeInOut(duration: 0.2)
                    : MihrabMotion.standardAnimation.delay(Double(index) * 0.04),
                value: appeared
            )
    }
}

/// Catalog drawing under card content, plus a dark green scrim for ≥4.5:1 type.
private struct CardSceneModifier: ViewModifier {
    let name: String
    var opacity: Double
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if UIImage(named: name) != nil {
            content
                .background {
                    GeometryReader { geo in
                        ZStack {
                            Image(name)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .opacity(opacity)
                            LinearGradient(
                                colors: [
                                    MihrabColor.abyss.opacity(0.58),
                                    MihrabColor.forest.opacity(0.78)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            content
        }
    }
}
