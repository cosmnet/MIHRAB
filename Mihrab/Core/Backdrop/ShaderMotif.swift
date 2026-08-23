import SwiftUI

/// The six Metal motifs in `MihrabShaders.metal`, as a first-class value.
///
/// `ShaderStyle` (the legacy type) is `ShaderMotif` plus a `.none` case; the two
/// bridge losslessly, so old call sites keep working while new code speaks in
/// motifs.
enum ShaderMotif: String, CaseIterable, Identifiable {
    case silk, caustics, aurora, lantern, ripple, kufic

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .silk: L10n.shaderSilk
        case .caustics: L10n.shaderCaustics
        case .aurora: L10n.shaderAurora
        case .lantern: L10n.apprMotifLantern
        case .ripple: L10n.apprMotifRipple
        case .kufic: L10n.apprMotifKufic
        }
    }

    /// SF Symbol used on compact chips where a live preview is too small to read.
    var symbolName: String {
        switch self {
        case .silk: "wind"
        case .caustics: "sparkles"
        case .aurora: "aqi.medium"
        case .lantern: "lightbulb.max"
        case .ripple: "drop.circle"
        case .kufic: "square.grid.3x3"
        }
    }

    /// Gradient the shader is composited over. Each motif wants a slightly
    /// different bed — caustics likes a deeper floor, lantern a warmer one.
    var bedColors: [Color] {
        switch self {
        case .silk:
            [MihrabColor.forest, MihrabColor.moss.opacity(0.55), MihrabColor.abyss]
        case .caustics:
            [MihrabColor.forest, MihrabColor.emerald.opacity(0.28), MihrabColor.abyss]
        case .aurora:
            [MihrabColor.abyss, MihrabColor.forest, MihrabColor.abyss]
        case .lantern:
            [MihrabColor.forest.opacity(0.9), MihrabColor.abyss]
        case .ripple:
            [MihrabColor.abyss, MihrabColor.moss.opacity(0.5)]
        case .kufic:
            [MihrabColor.forest, MihrabColor.abyss]
        }
    }

    var bedStart: UnitPoint {
        switch self {
        case .aurora, .lantern: .top
        case .ripple: .bottom
        default: .topLeading
        }
    }

    var bedEnd: UnitPoint {
        switch self {
        case .aurora, .lantern: .bottom
        case .ripple: .top
        default: .bottomTrailing
        }
    }

    /// Seconds per conceptual cycle — used to pace the animation clock so each
    /// motif drifts at its own natural tempo instead of a shared metronome.
    var timeScale: Double {
        switch self {
        case .silk: 1.0
        case .caustics: 0.9
        case .aurora: 1.05
        case .lantern: 1.25
        case .ripple: 0.7
        case .kufic: 1.6
        }
    }

    func shader(time: Float, halfWidth: Float, halfHeight: Float) -> Shader {
        let t = Shader.Argument.float(time)
        let size = Shader.Argument.float2(halfWidth, halfHeight)
        switch self {
        case .silk: return ShaderLibrary.emeraldSilk(t, size)
        case .caustics: return ShaderLibrary.mosqueCaustics(t, size)
        case .aurora: return ShaderLibrary.auroraVeil(t, size)
        case .lantern: return ShaderLibrary.lanternGlow(t, size)
        case .ripple: return ShaderLibrary.stillRipple(t, size)
        case .kufic: return ShaderLibrary.kuficLattice(t, size)
        }
    }

    // MARK: - Legacy bridge

    var legacyStyle: ShaderStyle {
        switch self {
        case .silk: .silk
        case .caustics: .caustics
        case .aurora: .aurora
        case .lantern: .lantern
        case .ripple: .ripple
        case .kufic: .kufic
        }
    }
}

/// Draws one motif into whatever space it is given. This is the single place
/// that owns the animation clock, so frame-rate policy lives in exactly one file.
struct ShaderMotifCanvas: View {
    var motif: ShaderMotif
    /// Frames per second for the driving `TimelineView`.
    var fps: Double = 24
    /// Colours the shader is drawn over; `nil` uses the motif's own bed.
    var bed: [Color]? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / max(fps, 1), paused: reduceMotion)) { context in
                let seconds = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
                let time = reduceMotion ? 0 : Float(seconds * motif.timeScale)
                LinearGradient(
                    colors: bed ?? motif.bedColors,
                    startPoint: motif.bedStart,
                    endPoint: motif.bedEnd
                )
                .colorEffect(
                    motif.shader(
                        time: time,
                        halfWidth: Float(max(geo.size.width, 8) / 2),
                        halfHeight: Float(max(geo.size.height, 8) / 2)
                    )
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
