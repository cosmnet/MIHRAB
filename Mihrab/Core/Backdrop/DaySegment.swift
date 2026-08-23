import SwiftUI

/// Where in the day's arc we currently stand.
///
/// The backdrop uses this to drift its palette from cold dawn blue through
/// brass sunrise, bright emerald noon, gold afternoon, deep orange dusk and
/// violet night. It is a *tonal* journey on top of Emerald Glass — never a
/// theme swap. Every veil below sits at ≤ 0.22 opacity over the emerald floor.
enum DaySegment: String, CaseIterable, Sendable {
    case fajr, sunrise, morning, dhuhr, asr, maghrib, isha, night
}

// MARK: - Resolution

extension DaySegment {
    /// How long after sunrise the "first light" tone lingers.
    private static let sunriseWindow: TimeInterval = 50 * 60
    /// How long after Isha we still read as evening rather than deep night.
    private static let ishaWindow: TimeInterval = 2 * 60 * 60

    /// The segment `now` falls into, or `nil` when we have no schedule yet.
    ///
    /// Honest by design: with no times on hand we return `nil` and the backdrop
    /// stays on its neutral emerald recipe rather than guessing from the clock.
    static func resolve(now: Date = Date(),
                        today: DayPrayerTimes?,
                        tomorrow: DayPrayerTimes? = nil) -> DaySegment? {
        guard let today else { return nil }

        let fajr = today.time(for: .fajr)
        let sunrise = today.time(for: .sunrise)
        let dhuhr = today.time(for: .dhuhr)
        let asr = today.time(for: .asr)
        let maghrib = today.time(for: .maghrib)
        let isha = today.time(for: .isha)

        if let fajr, now < fajr { return .night }
        if let fajr, let sunrise, now >= fajr, now < sunrise { return .fajr }
        if let sunrise, now >= sunrise, now < sunrise.addingTimeInterval(sunriseWindow) { return .sunrise }
        if let sunrise, let dhuhr, now >= sunrise, now < dhuhr { return .morning }
        if let dhuhr, let asr, now >= dhuhr, now < asr { return .dhuhr }
        if let asr, let maghrib, now >= asr, now < maghrib { return .asr }
        if let maghrib, let isha, now >= maghrib, now < isha { return .maghrib }
        if let isha, now >= isha, now < isha.addingTimeInterval(ishaWindow) { return .isha }
        if let isha, now >= isha { return .night }

        // Sparse schedule (polar edge cases, partial cache): don't invent one.
        return nil
    }

    var localizedName: String {
        switch self {
        case .fajr: L10n.segFajr
        case .sunrise: L10n.segSunrise
        case .morning: L10n.segMorning
        case .dhuhr: L10n.segDhuhr
        case .asr: L10n.segAsr
        case .maghrib: L10n.segMaghrib
        case .isha: L10n.segIsha
        case .night: L10n.segNight
        }
    }
}

// MARK: - Palette

/// The tonal veil a segment lays over the emerald backdrop.
struct DaySegmentPalette {
    /// Warm/cool light coming from the sky.
    var sky: Color
    /// The deeper tone that settles into the lower half of the screen.
    var ground: Color
    /// Where the day's light source sits, in unit space.
    var lightCenter: UnitPoint
    /// Overall strength — multiplied into every layer. Kept low on purpose.
    var strength: Double
}

extension DaySegment {
    /// Colours are picked to read as *time of day* while staying in the
    /// green-leaning family Mihrab paints everywhere else. None of them is
    /// bright enough to lift the contrast floor under body copy.
    var palette: DaySegmentPalette {
        switch self {
        case .fajr:
            // Cold blue-violet, light still under the horizon.
            DaySegmentPalette(sky: Color(hex: 0x3B4A8C), ground: Color(hex: 0x121B36),
                              lightCenter: UnitPoint(x: 0.80, y: 0.92), strength: 0.80)
        case .sunrise:
            // Warm brass climbing in from the east.
            DaySegmentPalette(sky: Color(hex: 0x8A6224), ground: Color(hex: 0x2E2412),
                              lightCenter: UnitPoint(x: 0.86, y: 0.72), strength: 0.92)
        case .morning:
            // Clear, light emerald — the most "Mihrab" of the eight.
            DaySegmentPalette(sky: Color(hex: 0x2A8F63), ground: Color(hex: 0x10382A),
                              lightCenter: UnitPoint(x: 0.68, y: 0.36), strength: 0.78)
        case .dhuhr:
            // Brightest point of the day, light directly overhead.
            DaySegmentPalette(sky: Color(hex: 0x35B683), ground: Color(hex: 0x15503A),
                              lightCenter: UnitPoint(x: 0.50, y: 0.10), strength: 1.00)
        case .asr:
            // Gold, the light lengthening again.
            DaySegmentPalette(sky: Color(hex: 0xB08034), ground: Color(hex: 0x3A2C15),
                              lightCenter: UnitPoint(x: 0.24, y: 0.34), strength: 0.90)
        case .maghrib:
            // Deep orange-red at the western edge.
            DaySegmentPalette(sky: Color(hex: 0xA24528), ground: Color(hex: 0x35160F),
                              lightCenter: UnitPoint(x: 0.14, y: 0.74), strength: 0.95)
        case .isha:
            // Violet over navy, the last of the glow gone.
            DaySegmentPalette(sky: Color(hex: 0x3A2F6E), ground: Color(hex: 0x141232),
                              lightCenter: UnitPoint(x: 0.30, y: 0.94), strength: 0.72)
        case .night:
            // Abyss. Almost nothing added — the floor speaks for itself.
            DaySegmentPalette(sky: Color(hex: 0x14243A), ground: Color(hex: 0x050B0A),
                              lightCenter: UnitPoint(x: 0.52, y: 0.98), strength: 0.46)
        }
    }

    /// Peak opacity of the sky wash. The ground wash uses a little less.
    static let veilCeiling: Double = 0.22
}

// MARK: - Colour blending

extension Color {
    /// Linear blend towards `other`. Used for the Reduce Transparency fill,
    /// where a single flat colour has to carry the whole segment.
    func mihrabBlended(with other: Color, amount: Double) -> Color {
        let t = min(max(amount, 0), 1)
        let a = UIColor(self)
        let b = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        guard a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1),
              b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else { return self }
        return Color(
            .sRGB,
            red: Double(r1 + (r2 - r1) * CGFloat(t)),
            green: Double(g1 + (g2 - g1) * CGFloat(t)),
            blue: Double(b1 + (b2 - b1) * CGFloat(t)),
            opacity: Double(a1 + (a2 - a1) * CGFloat(t))
        )
    }
}

// MARK: - Power state

/// Single place that answers "should this screen animate at all?".
///
/// Agent W4 is adding an `isLowPowerMode` flag to `LocationManager`; until that
/// lands this reads the system directly, which is the same source of truth.
enum MihrabPower {
    static var isLowPowerMode: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }
}
