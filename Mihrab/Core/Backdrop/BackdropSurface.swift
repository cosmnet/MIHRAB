import SwiftUI

/// Which screen a backdrop is painting behind.
///
/// Only `.dhikr` gets the full-screen shader — everywhere else Mihrab paints a
/// calm, near-static wash so type always wins. Each surface tilts its glow
/// colour and placement a little, so the app still feels like it *moves* from
/// room to room without any of them shouting.
enum BackdropSurface: String, CaseIterable, Identifiable {
    case today, times, qibla, deen, dhikr, sheet

    var id: String { rawValue }

    /// `true` when this surface hands the whole screen to the Metal shader.
    var isImmersive: Bool { self == .dhikr }
}

/// One soft radial wash. Opacities live in the 0.06–0.18 band on purpose: the
/// eye reads them as depth, never as pattern.
struct BackdropGlow {
    var color: Color
    /// Centre in unit space of the screen.
    var center: UnitPoint
    /// Radius as a fraction of the *shorter* screen edge.
    var radius: CGFloat
    var opacity: Double
    /// How far (in unit space) the wash wanders over a full cycle.
    var drift: CGSize
    /// Seconds for one there-and-back drift. Long on purpose.
    var period: Double
    /// Horizontal / vertical stretch — used for the "horizon" look.
    var stretch: CGSize = CGSize(width: 1, height: 1)
}

extension BackdropSurface {
    /// Base colour under the glows.
    func baseColor(ramadan: Bool) -> Color {
        ramadan ? MihrabColor.ramadanViolet : MihrabColor.abyss
    }

    /// One or two glows per surface — never more. More layers means more
    /// crossings, and crossings are what make a background feel busy.
    func glows(ramadan: Bool) -> [BackdropGlow] {
        if ramadan { return ramadanGlows }
        switch self {
        case .today:
            // Dawn light from above the fold.
            return [
                BackdropGlow(
                    color: MihrabColor.mint,
                    center: UnitPoint(x: 0.5, y: 0.08),
                    radius: 1.15,
                    opacity: 0.16,
                    drift: CGSize(width: 0.06, height: 0.03),
                    period: 34
                ),
                BackdropGlow(
                    color: MihrabColor.emerald,
                    center: UnitPoint(x: 0.86, y: 0.82),
                    radius: 0.85,
                    opacity: 0.10,
                    drift: CGSize(width: -0.05, height: 0.04),
                    period: 47
                )
            ]

        case .times:
            // A brass horizon line — the day's arc, lying down.
            return [
                BackdropGlow(
                    color: MihrabColor.brass,
                    center: UnitPoint(x: 0.5, y: 0.60),
                    radius: 0.72,
                    opacity: 0.13,
                    drift: CGSize(width: 0.0, height: 0.025),
                    period: 41,
                    stretch: CGSize(width: 2.1, height: 0.42)
                ),
                BackdropGlow(
                    color: MihrabColor.emerald,
                    center: UnitPoint(x: 0.30, y: 0.05),
                    radius: 0.95,
                    opacity: 0.10,
                    drift: CGSize(width: 0.05, height: -0.02),
                    period: 53
                )
            ]

        case .qibla:
            // Focus pulled to the middle, where the needle lives.
            return [
                BackdropGlow(
                    color: MihrabColor.emerald,
                    center: UnitPoint(x: 0.5, y: 0.42),
                    radius: 0.90,
                    opacity: 0.15,
                    drift: CGSize(width: 0.02, height: 0.02),
                    period: 38
                ),
                BackdropGlow(
                    color: MihrabColor.brass,
                    center: UnitPoint(x: 0.5, y: 1.02),
                    radius: 0.80,
                    opacity: 0.08,
                    drift: CGSize(width: 0.03, height: 0.0),
                    period: 59
                )
            ]

        case .deen:
            // Warm brass rising from below, like lamplight in a courtyard.
            return [
                BackdropGlow(
                    color: MihrabColor.brass,
                    center: UnitPoint(x: 0.42, y: 0.98),
                    radius: 1.05,
                    opacity: 0.14,
                    drift: CGSize(width: 0.06, height: -0.03),
                    period: 44
                ),
                BackdropGlow(
                    color: MihrabColor.emerald,
                    center: UnitPoint(x: 0.12, y: 0.12),
                    radius: 0.88,
                    opacity: 0.10,
                    drift: CGSize(width: 0.04, height: 0.03),
                    period: 57
                )
            ]

        case .dhikr:
            // Only used as the calm fallback (Reduce Motion, texture off).
            return [
                BackdropGlow(
                    color: MihrabColor.emerald,
                    center: UnitPoint(x: 0.5, y: 0.46),
                    radius: 1.05,
                    opacity: 0.17,
                    drift: CGSize(width: 0.03, height: 0.03),
                    period: 36
                )
            ]

        case .sheet:
            // The most neutral of all — sheets carry dense text.
            return [
                BackdropGlow(
                    color: MihrabColor.emerald,
                    center: UnitPoint(x: 0.5, y: 0.14),
                    radius: 1.00,
                    opacity: 0.10,
                    drift: CGSize(width: 0.03, height: 0.02),
                    period: 62
                )
            ]
        }
    }

    /// Ramadan keeps its violet/gold identity on every surface, with the
    /// placement nudged by surface so the screens still differ.
    private var ramadanGlows: [BackdropGlow] {
        let anchor: UnitPoint
        switch self {
        case .today: anchor = UnitPoint(x: 0.5, y: 0.10)
        case .times: anchor = UnitPoint(x: 0.5, y: 0.58)
        case .qibla: anchor = UnitPoint(x: 0.5, y: 0.44)
        case .deen: anchor = UnitPoint(x: 0.44, y: 0.94)
        case .dhikr: anchor = UnitPoint(x: 0.5, y: 0.46)
        case .sheet: anchor = UnitPoint(x: 0.5, y: 0.16)
        }
        return [
            BackdropGlow(
                color: MihrabColor.ramadanGold,
                center: anchor,
                radius: 1.05,
                opacity: 0.15,
                drift: CGSize(width: 0.045, height: 0.03),
                period: 42
            ),
            BackdropGlow(
                color: Color(hex: 0x8F7AE0),
                center: UnitPoint(x: 1 - anchor.x, y: 1 - anchor.y * 0.7),
                radius: 0.95,
                opacity: 0.13,
                drift: CGSize(width: -0.04, height: 0.03),
                period: 55
            )
        ]
    }
}
