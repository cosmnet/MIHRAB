import SwiftUI
import UIKit

/// Mihrab glass card: Liquid Glass over moss, with the "wet glass edge" stroke.
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 28
    var interactive: Bool = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    func body(content: Content) -> some View {
        content
            .background {
                if reduceTransparency {
                    shape.fill(MihrabColor.moss)
                } else {
                    shape
                        // Inner shadow gives the glass a lip: light catches the
                        // top edge, the floor recedes. Cheap depth, no blur pass.
                        .fill(
                            MihrabColor.moss.opacity(0.42)
                                .shadow(.inner(color: MihrabColor.abyss.opacity(0.55), radius: 8, y: 4))
                        )
                        .glassEffect(
                            interactive ? .regular.interactive() : .regular,
                            in: .rect(cornerRadius: cornerRadius)
                        )
                }
            }
            .overlay {
                // Two-stop rim: a bright crown at 12 o'clock fading out by the
                // middle, then a faint emerald return along the bottom so the
                // card reads as a solid object rather than a cut-out.
                shape
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: MihrabColor.mint.opacity(0.55), location: 0),
                                .init(color: MihrabColor.mint.opacity(0.14), location: 0.35),
                                .init(color: .clear, location: 0.72),
                                .init(color: MihrabColor.emerald.opacity(0.18), location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .allowsHitTesting(false)
            }
            .shadow(color: MihrabColor.abyss.opacity(reduceTransparency ? 0 : 0.35), radius: 14, y: 6)
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
            ZStack {
                // Opaque floor — this is the row's contrast guarantee.
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fill)

                // Top-lit sheen, then a deepening floor. Both stay under 6%
                // so the fill colour still measures as the text background.
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.055),
                                .clear,
                                MihrabColor.abyss.opacity(0.22)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .compositingGroup()
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [stroke, stroke.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
                .allowsHitTesting(false)
        }
    }

    /// A card whose interior carries a shader motif. Equivalent to
    /// `mihrabShaderPanel` with the app's standard card radius — use it when a
    /// screen wants its own visual signature without a full-screen shader.
    func mihrabTexturedCard(
        _ motif: ShaderMotif,
        cornerRadius: CGFloat = MihrabSpace.cardRadius,
        opacity: Double = 0.5
    ) -> some View {
        mihrabShaderPanel(motif, cornerRadius: cornerRadius, opacity: opacity)
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

/// Springy press-down for cards & big targets. Reduce Motion -> simple dim.
struct PressableCardStyle: ButtonStyle {
    var reduceMotion: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(
                reduceMotion ? .easeInOut(duration: 0.12) : MihrabMotion.snappyAnimation,
                value: configuration.isPressed
            )
    }
}

extension View {
    func pressable(_ reduceMotion: Bool = false) -> some View {
        buttonStyle(PressableCardStyle(reduceMotion: reduceMotion))
    }
}
