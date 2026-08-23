import CoreLocation
import Foundation

/// The two legitimate Asr rules, side by side, with **real** times.
///
/// Why this exists — the contradiction wave 1 verified:
///
/// Diyanet publishes Asr with the *majority* (Shafi/Maliki/Hanbali) rule —
/// the shadow of an object equals its own length plus its noon shadow.
/// Mihrab, however, defaults a Turkish device to `Madhab.hanafi` (twice the
/// object's length), because that is what most people in Turkey follow in
/// practice. Both are correct positions; but the combination means that a user
/// who picks "Diyanet" and never touches the madhab picker sees an Asr that is
/// **not** the one printed on the Diyanet calendar. For İstanbul on
/// 12 April 2026 the two rules are ~58 minutes apart (16:51 vs 17:49).
///
/// Silently choosing one is exactly where the "prayer times are wrong" reviews
/// come from. So we ask — once, during onboarding — and we ask it with the
/// user's own two candidate times on screen rather than with an abstract
/// description of shadow ratios.
///
/// Nothing here is invented: both times come from `PrayerEngine` with the
/// user's own method, source, offsets and time zone. Only the madhab differs.
struct AsrMadhabPreview: Equatable, Sendable {

    /// Asr under the Shafi/majority rule — the one Diyanet prints.
    let shafi: Date?
    /// Asr under the Hanafi rule — later.
    let hanafi: Date?
    /// Whole minutes between the two, when both could be computed.
    let differenceMinutes: Int?
    /// `true` when the coordinate is a stand-in (no location yet) and the UI
    /// must label the times as an example rather than as "your" times.
    let isReferenceLocation: Bool
    /// Name to show when `isReferenceLocation` is `true`.
    let referenceName: String?

    var hasTimes: Bool { shafi != nil && hanafi != nil }

    /// A stand-in used only when the user has neither granted location nor
    /// picked a city yet. Shown *labelled* as İstanbul, never as "your city".
    static let referenceCoordinate = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
    static let referenceCityName = "İstanbul"

    /// Computes both Asr times for `date` at `coordinate`.
    ///
    /// - Parameter coordinate: the user's real coordinate. Pass `nil` when it
    ///   is not known yet and the reference city will be used instead.
    static func make(
        date: Date = Date(),
        coordinate: CLLocationCoordinate2D?,
        method: CalculationMethod,
        source: PrayerSource,
        offsets: [Prayer: Int] = [:],
        timeZone: TimeZone = .current
    ) -> AsrMadhabPreview {
        let isReference = coordinate == nil
        let point = coordinate ?? referenceCoordinate

        func asr(_ madhab: Madhab) -> Date? {
            let configuration = PrayerEngineConfiguration(
                method: method,
                madhab: madhab,
                source: source,
                offsets: offsets,
                timeZone: timeZone
            )
            return PrayerEngine.times(for: date, coordinate: point, configuration: configuration)?
                .time(for: .asr)
        }

        let shafiTime = asr(.shafi)
        let hanafiTime = asr(.hanafi)

        var delta: Int?
        if let shafiTime, let hanafiTime {
            // Rounded to the minute the user actually sees, so the label can
            // never disagree with the two times printed next to it.
            let a = Int((shafiTime.timeIntervalSince1970 / 60).rounded())
            let b = Int((hanafiTime.timeIntervalSince1970 / 60).rounded())
            delta = abs(b - a)
        }

        return AsrMadhabPreview(
            shafi: shafiTime,
            hanafi: hanafiTime,
            differenceMinutes: delta,
            isReferenceLocation: isReference,
            referenceName: isReference ? referenceCityName : nil
        )
    }

    func time(for madhab: Madhab) -> Date? {
        madhab == .hanafi ? hanafi : shafi
    }
}
