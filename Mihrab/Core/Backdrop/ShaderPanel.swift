import SwiftUI

/// Puts a shader motif *inside* a card instead of behind the whole screen.
///
/// Three layers, in order: the motif clipped to the card shape, a directional
/// scrim that darkens wherever type sits, and a hairline that catches light on
/// the top edge. The scrim is not optional — it is what buys the ≥4.5:1
/// contrast that lets us use a moving texture behind body copy at all.
struct ShaderPanelModifier: ViewModifier {
    let motif: ShaderMotif
    var cornerRadius: CGFloat = MihrabSpace.cardRadius
    var opacity: Double = 0.55

    @Environment(AppSettings.self) private var settings: AppSettings?
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    private var texturesOn: Bool {
        settings?.cardTextureEnabled ?? true
    }

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Opaque floor first: the motif is translucent, and text
                    // must never sit on whatever happens to be behind the card.
                    shape.fill(MihrabColor.moss)

                    if texturesOn && !reduceTransparency {
                        ShaderMotifCanvas(motif: motif, fps: 12)
                            .opacity(opacity)
                            .blendMode(.plusLighter)

                        // Readability scrim. Heaviest at the bottom, where the
                        // secondary line of a card almost always lives.
                        LinearGradient(
                            colors: [
                                MihrabColor.abyss.opacity(0.34),
                                MihrabColor.abyss.opacity(0.52),
                                MihrabColor.abyss.opacity(0.68)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
                .clipShape(shape)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .overlay {
                shape
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                MihrabColor.mint.opacity(0.34),
                                MihrabColor.mint.opacity(0.08),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .allowsHitTesting(false)
            }
            .clipShape(shape)
    }
}

extension View {
    /// Fills a card's interior with a slow, clipped shader texture plus a
    /// readability scrim. Full-screen shaders are reserved for the counter —
    /// this is how texture reaches the rest of the app.
    func mihrabShaderPanel(
        _ motif: ShaderMotif,
        cornerRadius: CGFloat = MihrabSpace.cardRadius,
        opacity: Double = 0.55
    ) -> some View {
        modifier(ShaderPanelModifier(motif: motif, cornerRadius: cornerRadius, opacity: opacity))
    }
}

/// A small, live motif tile — used by the appearance picker so the user chooses
/// a texture by looking at it, not by reading its name.
struct ShaderMotifPreview: View {
    var motif: ShaderMotif
    var isSelected: Bool = false
    var cornerRadius: CGFloat = 16
    var accent: Color = MihrabColor.emerald

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack {
            if reduceTransparency {
                LinearGradient(
                    colors: motif.bedColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                ShaderMotifCanvas(motif: motif, fps: isSelected ? 20 : 10)
            }

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(MihrabColor.textPrimary, accent)
                    .shadow(color: MihrabColor.abyss.opacity(0.6), radius: 3, y: 1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(6)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    isSelected ? accent : MihrabColor.mint.opacity(0.16),
                    lineWidth: isSelected ? 2 : 1
                )
        }
        .shadow(
            color: isSelected ? accent.opacity(0.35) : .clear,
            radius: 8,
            y: 3
        )
    }
}
