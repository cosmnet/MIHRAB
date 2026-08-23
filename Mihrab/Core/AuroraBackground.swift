import SwiftUI

/// The signature Mihrab background — abyss base, one or two drifting radial
/// auroras, fine grain so Liquid Glass has something to refract.
///
/// Now a thin wrapper over `CalmBackdrop`, which owns the actual recipe. Kept
/// as its own type because sheets, onboarding and the AR screens all reach for
/// it by name, and `AuroraBackground()` reads better at those call sites than
/// `MihrabBackdrop(surface: .sheet)`.
struct AuroraBackground: View {
    var ramadanMode: Bool = false
    var surface: BackdropSurface = .sheet

    @Environment(AppSettings.self) private var settings: AppSettings?

    var body: some View {
        CalmBackdrop(
            surface: surface,
            ramadanMode: ramadanMode,
            intensity: settings?.backdropIntensity ?? .calm
        )
    }
}
