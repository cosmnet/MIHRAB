import SwiftUI

/// Legacy texture selector. Kept because it is persisted in `UserDefaults` and
/// referenced across the app; it is now simply `ShaderMotif` plus a `.none`
/// case. New code should prefer `ShaderMotif`.
enum ShaderStyle: String, CaseIterable, Identifiable {
    case none, silk, caustics, aurora, lantern, ripple, kufic

    var id: String { rawValue }

    var localizedName: String {
        motif?.localizedName ?? L10n.shaderNone
    }

    /// `nil` only for `.none`.
    var motif: ShaderMotif? {
        switch self {
        case .none: nil
        case .silk: .silk
        case .caustics: .caustics
        case .aurora: .aurora
        case .lantern: .lantern
        case .ripple: .ripple
        case .kufic: .kufic
        }
    }

    /// Motif to draw when something must be drawn.
    var resolvedMotif: ShaderMotif { motif ?? .silk }
}

/// Full-screen Metal texture. Reserved for the counter — everywhere else uses
/// `CalmBackdrop`, because a moving full-bleed shader behind prayer times was
/// simply unreadable.
struct ShaderBackdrop: View {
    var style: ShaderStyle
    var ramadanMode: Bool = false

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        if style == .none || reduceTransparency {
            CalmBackdrop(surface: .dhikr, ramadanMode: ramadanMode)
        } else {
            ZStack {
                ShaderMotifCanvas(motif: style.resolvedMotif, fps: 30)

                if ramadanMode {
                    // Keep the violet/gold identity even under the shader.
                    LinearGradient(
                        colors: [
                            MihrabColor.ramadanViolet.opacity(0.55),
                            MihrabColor.ramadanGold.opacity(0.10),
                            MihrabColor.ramadanViolet.opacity(0.62)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .blendMode(.softLight)

                    MihrabColor.ramadanViolet.opacity(0.28)
                }

                // Edge falloff so headline type at the top never fights a crest.
                LinearGradient(
                    colors: [
                        MihrabColor.abyss.opacity(0.42),
                        .clear,
                        MihrabColor.abyss.opacity(0.34)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// Shader wash for chips and dials. Falls back to moss when the texture is off.
struct ShaderControlFill: View {
    var style: ShaderStyle
    var opacity: Double = 0.7

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        Group {
            if style == .none || reduceTransparency {
                MihrabColor.moss
            } else {
                ShaderMotifCanvas(motif: style.resolvedMotif, fps: 20)
                    .opacity(opacity)
            }
        }
        .allowsHitTesting(false)
    }
}

/// App-wide backdrop.
///
/// `.dhikr` gets the full-screen shader; every other surface gets the calm
/// wash. The no-argument initialiser keeps every existing call site compiling
/// and lands them on the quietest variant.
struct MihrabBackdrop: View {
    private let surface: BackdropSurface
    private let ramadanMode: Bool

    @Environment(AppSettings.self) private var settings: AppSettings?

    init(ramadanMode: Bool = false) {
        self.surface = .sheet
        self.ramadanMode = ramadanMode
    }

    init(surface: BackdropSurface, ramadanMode: Bool = false) {
        self.surface = surface
        self.ramadanMode = ramadanMode
    }

    var body: some View {
        if surface.isImmersive {
            ShaderBackdrop(
                style: settings?.dhikrShaderStyle ?? .silk,
                ramadanMode: ramadanMode
            )
        } else {
            CalmBackdrop(
                surface: surface,
                ramadanMode: ramadanMode,
                intensity: settings?.backdropIntensity ?? .calm
            )
        }
    }
}
