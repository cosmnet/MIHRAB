import Foundation

#if canImport(AlarmKit)
import AlarmKit
#endif

/// Payload carried by every Mihrab alarm.
///
/// **This file is deliberately dependency-light** — Foundation, AlarmKit and
/// `Prayer` from `PrayerModels.swift`, nothing else — so it can be added to the
/// `MihrabWidgets` target on its own. `MihrabWidgets/AlarmLiveActivity.swift`
/// (Agent W3) renders `AlarmAttributes<MihrabAlarmMetadata>` and needs exactly
/// this type and no more of the Adhan module.
///
/// Keep it `Codable`/`Hashable`/`Sendable` and additive — removing a field
/// breaks alarms already sitting in the system.
public struct MihrabAlarmMetadata: Codable, Hashable, Sendable {
    /// `Prayer.rawValue` — decode with `Prayer(rawValue:)`.
    public var prayerID: String
    /// Already localized ("Sabah", "Fajr") — the widget must not re-localize.
    public var prayerDisplayName: String
    /// Arabic name, for the secondary line.
    public var prayerArabicName: String
    /// City this alarm was computed for.
    public var cityName: String
    /// `AdhanSound.id` in force when the alarm was scheduled.
    public var soundID: String
    /// The prayer moment itself.
    public var prayerTime: Date

    public init(
        prayerID: String,
        prayerDisplayName: String,
        prayerArabicName: String,
        cityName: String,
        soundID: String,
        prayerTime: Date
    ) {
        self.prayerID = prayerID
        self.prayerDisplayName = prayerDisplayName
        self.prayerArabicName = prayerArabicName
        self.cityName = cityName
        self.soundID = soundID
        self.prayerTime = prayerTime
    }

    public var prayer: Prayer? { Prayer(rawValue: prayerID) }
}

#if canImport(AlarmKit)
extension MihrabAlarmMetadata: AlarmMetadata {}

/// The concrete `ActivityAttributes` the widgets target renders.
public typealias MihrabAlarmAttributes = AlarmAttributes<MihrabAlarmMetadata>
#endif
