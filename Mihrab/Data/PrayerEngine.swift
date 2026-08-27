import Adhan
import CoreLocation
import Foundation

// MARK: - Configuration

/// Everything the on-device engine needs, as a plain value.
///
/// Deliberately free of `AppSettings` / `LocationManager` so the engine can be
/// compiled into the test target and exercised without any app singleton.
/// The `AppSettings`-flavoured convenience overloads live in
/// `PrayerEngine+AppSettings.swift`.
public struct PrayerEngineConfiguration: Codable, Sendable, Equatable {
    public var method: CalculationMethod
    public var madhab: Madhab
    public var source: PrayerSource
    /// User's per-prayer correction in minutes, applied last (roadmap #8).
    public var offsets: [Prayer: Int]
    public var timeZoneIdentifier: String

    public init(method: CalculationMethod,
                madhab: Madhab,
                source: PrayerSource,
                offsets: [Prayer: Int] = [:],
                timeZone: TimeZone = .current) {
        self.method = method
        self.madhab = madhab
        self.source = source
        self.offsets = offsets
        timeZoneIdentifier = timeZone.identifier
    }

    public var timeZone: TimeZone { TimeZone(identifier: timeZoneIdentifier) ?? .current }

    /// The adhan-swift preset actually used. A Turkish tradition always sits on
    /// the Diyanet-derived `.turkey` base (that is where the temkin comes from);
    /// `.standard` honours whatever the user chose in Settings.
    public var effectiveAdhanMethod: Adhan.CalculationMethod {
        source.baseAdhanMethod ?? method.adhanMethod
    }

    /// The method id to send to Aladhan, or `nil` when Aladhan cannot reproduce
    /// this source and the network must be skipped.
    ///
    /// Without this the two paths could disagree: a user on the Diyanet source
    /// with, say, ISNA still selected in Settings computed Diyanet times
    /// offline and then had them overwritten by ISNA times from the network,
    /// while the screen kept saying "Diyanet". `CalculationMethod.rawValue` is
    /// the Aladhan method id (13 = Diyanet İşleri Başkanlığı).
    public var networkMethod: CalculationMethod? {
        source.networkMethod(userMethod: method)
    }

    /// The method the transparency panel names. Falls back to the user's own
    /// pick for sources Aladhan cannot express, which is what the engine used.
    public var reportedMethod: CalculationMethod {
        networkMethod ?? method
    }

    /// Stable identity for cache invalidation. Changing anything here must
    /// invalidate stored days.
    public var fingerprint: String {
        let offsetPart = Prayer.allCases
            .map { "\($0.rawValue):\(offsets[$0] ?? 0)" }
            .joined(separator: ",")
        return "\(method.rawValue)|\(madhab.rawValue)|\(source.rawValue)|\(offsetPart)|\(timeZoneIdentifier)"
    }
}

// MARK: - Transparency model

/// "Where did this number come from?" — the data behind the transparency panel
/// (UI is Agent W5's). Attached to every produced day, cached alongside it.
public struct PrayerResolution: Codable, Sendable, Equatable {
    public enum Origin: String, Codable, Sendable {
        /// Computed on this device by adhan-swift. Always available, no network.
        case device
        /// Fetched from the Aladhan API.
        case network
        /// Replayed from the persistent App Group cache.
        case cache
    }

    public var origin: Origin
    public var source: PrayerSource
    /// Mihrab `CalculationMethod.rawValue`.
    public var methodID: Int
    /// Mihrab `Madhab.rawValue`.
    public var madhabID: Int
    /// adhan-swift preset name actually used (`turkey`, `muslimWorldLeague`, …).
    public var adhanMethodID: String
    public var fajrAngle: Double?
    public var ishaAngle: Double?
    public var ishaIntervalMinutes: Int
    /// Minutes the calculation method itself already folded in (Diyanet temkin).
    public var temkinMinutes: [Prayer: Int]
    /// `true` when `temkinMinutes` is a documented temkin margin, not a generic
    /// transit correction.
    public var temkinIsDiyanet: Bool
    /// The user's own ± corrections.
    public var userOffsetMinutes: [Prayer: Int]
    /// adhan-swift `HighLatitudeRule` name, when one was applied.
    public var highLatitudeRule: String?
    public var timeZoneIdentifier: String
    public var updatedAt: Date

    public init(origin: Origin,
                source: PrayerSource,
                methodID: Int,
                madhabID: Int,
                adhanMethodID: String,
                fajrAngle: Double?,
                ishaAngle: Double?,
                ishaIntervalMinutes: Int = 0,
                temkinMinutes: [Prayer: Int] = [:],
                temkinIsDiyanet: Bool = false,
                userOffsetMinutes: [Prayer: Int] = [:],
                highLatitudeRule: String? = nil,
                timeZoneIdentifier: String = TimeZone.current.identifier,
                updatedAt: Date = Date()) {
        self.origin = origin
        self.source = source
        self.methodID = methodID
        self.madhabID = madhabID
        self.adhanMethodID = adhanMethodID
        self.fajrAngle = fajrAngle
        self.ishaAngle = ishaAngle
        self.ishaIntervalMinutes = ishaIntervalMinutes
        self.temkinMinutes = temkinMinutes
        self.temkinIsDiyanet = temkinIsDiyanet
        self.userOffsetMinutes = userOffsetMinutes
        self.highLatitudeRule = highLatitudeRule
        self.timeZoneIdentifier = timeZoneIdentifier
        self.updatedAt = updatedAt
    }

    public var methodName: String {
        CalculationMethod(rawValue: methodID)?.localizedName ?? "—"
    }

    public var originLabel: String {
        switch origin {
        case .device: L10n.originDevice
        case .network: L10n.originNetwork
        case .cache: L10n.originCache
        }
    }

    /// One-line headline for the panel: "Diyanet · computed on device".
    public var headline: String {
        "\(source.localizedName) · \(originLabel)"
    }

    /// Human-readable, per-prayer provenance. Every claim here is backed by a
    /// stored field — nothing is asserted that we did not actually apply.
    public func resolutionSummary(for prayer: Prayer) -> String {
        var lines: [String] = [headline]
        lines.append(L10n.resolutionMethod(methodName))

        if let fajrAngle, prayer == .fajr {
            lines.append(L10n.resolutionAngle(L10n.prayerFajr, fajrAngle))
        }
        if let ishaAngle, prayer == .isha, ishaIntervalMinutes == 0 {
            lines.append(L10n.resolutionAngle(L10n.prayerIsha, ishaAngle))
        }
        if prayer == .isha, ishaIntervalMinutes > 0 {
            lines.append(L10n.resolutionIshaInterval(ishaIntervalMinutes))
        }
        if prayer == .asr {
            lines.append(L10n.resolutionMadhab(Madhab(rawValue: madhabID)?.localizedName ?? "—"))
        }
        if let temkin = temkinMinutes[prayer], temkin != 0 {
            lines.append(temkinIsDiyanet ? L10n.resolutionTemkin(temkin)
                                         : L10n.resolutionMethodAdjustment(temkin))
        }
        if let offset = userOffsetMinutes[prayer], offset != 0 {
            lines.append(L10n.resolutionUserOffset(offset))
        }
        if let highLatitudeRule {
            lines.append(L10n.resolutionHighLatitude(highLatitudeRule))
        }
        lines.append(L10n.resolutionUpdatedAt(updatedAt))
        return lines.joined(separator: "\n")
    }
}

/// A day plus its provenance. The cache stores these; `DayPrayerTimes` itself
/// lives in `Core/Shared/PrayerModels.swift` and is not ours to change.
public struct ResolvedPrayerDay: Codable, Sendable, Equatable {
    public var day: DayPrayerTimes
    public var resolution: PrayerResolution

    public init(day: DayPrayerTimes, resolution: PrayerResolution) {
        self.day = day
        self.resolution = resolution
    }

    public static func == (lhs: ResolvedPrayerDay, rhs: ResolvedPrayerDay) -> Bool {
        lhs.day.date == rhs.day.date && lhs.day.times == rhs.day.times
            && lhs.resolution == rhs.resolution
    }
}

// MARK: - Engine

/// Fully offline prayer-time computation. No networking, no singletons, no
/// side effects — safe to call from a background task, a widget, or a test.
public struct PrayerEngine {
    private init() {}

    /// Why a day could not be produced. Polar day/night is a real, honest
    /// answer — not a crash and not a fabricated time.
    public enum Failure: Error, Sendable, Equatable {
        /// adhan-swift could not determine transit/sunrise/sunset. Happens
        /// above the polar circles where the sun does not cross the horizon.
        case undefinedAtThisLatitude
        case invalidDate
    }

    // MARK: Public API (contract)

    public static func times(for date: Date,
                             coordinate: CLLocationCoordinate2D,
                             configuration: PrayerEngineConfiguration) -> DayPrayerTimes? {
        resolved(for: date, coordinate: coordinate, configuration: configuration)?.day
    }

    public static func month(of date: Date,
                             coordinate: CLLocationCoordinate2D,
                             configuration: PrayerEngineConfiguration) -> [DayPrayerTimes] {
        resolvedMonth(of: date, coordinate: coordinate, configuration: configuration).map(\.day)
    }

    /// Every day in the Gregorian month containing `date`, ascending.
    public static func resolvedMonth(of date: Date,
                                     coordinate: CLLocationCoordinate2D,
                                     configuration: PrayerEngineConfiguration) -> [ResolvedPrayerDay] {
        let calendar = calendar(for: configuration)
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return [] }
        let dayCount = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
        return (0..<dayCount).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: interval.start) else { return nil }
            return resolved(for: day, coordinate: coordinate, configuration: configuration)
        }
    }

    /// A rolling window starting `startingOffset` days from `date`.
    /// Used to keep at least 60 days on disk without month-boundary gaps.
    public static func resolvedWindow(from date: Date,
                                      startingOffset: Int = -1,
                                      dayCount: Int,
                                      coordinate: CLLocationCoordinate2D,
                                      configuration: PrayerEngineConfiguration) -> [ResolvedPrayerDay] {
        let calendar = calendar(for: configuration)
        let start = calendar.startOfDay(for: date)
        return (0..<max(0, dayCount)).compactMap { index in
            guard let day = calendar.date(byAdding: .day, value: startingOffset + index, to: start) else { return nil }
            return resolved(for: day, coordinate: coordinate, configuration: configuration)
        }
    }

    /// The one place that actually calls adhan-swift.
    public static func resolved(for date: Date,
                                coordinate: CLLocationCoordinate2D,
                                configuration: PrayerEngineConfiguration) -> ResolvedPrayerDay? {
        try? resolvedOrThrow(for: date, coordinate: coordinate, configuration: configuration)
    }

    public static func resolvedOrThrow(for date: Date,
                                       coordinate: CLLocationCoordinate2D,
                                       configuration: PrayerEngineConfiguration) throws -> ResolvedPrayerDay {
        let calendar = calendar(for: configuration)
        let dayStart = calendar.startOfDay(for: date)
        var components = calendar.dateComponents([.year, .month, .day], from: dayStart)
        components.calendar = nil
        components.timeZone = nil
        guard components.year != nil, components.month != nil, components.day != nil else {
            throw Failure.invalidDate
        }

        let coordinates = Coordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let params = parameters(for: configuration, coordinates: coordinates)

        // `PrayerTimes.init` is failable: above the polar circles the sun never
        // crosses the horizon and there simply is no sunrise/sunset to anchor
        // to. Return a typed failure so the UI can say so honestly instead of
        // showing invented times or crashing.
        guard let computed = Adhan.PrayerTimes(coordinates: coordinates,
                                               date: components,
                                               calculationParameters: params) else {
            throw Failure.undefinedAtThisLatitude
        }

        var times: [Prayer: Date] = [
            .fajr: computed.fajr,
            .sunrise: computed.sunrise,
            .dhuhr: computed.dhuhr,
            .asr: computed.asr,
            .maghrib: computed.maghrib,
            .isha: computed.isha,
        ]
        // User corrections are applied last, on top of method temkin.
        for prayer in Prayer.allCases {
            guard let minutes = configuration.offsets[prayer], minutes != 0,
                  let current = times[prayer] else { continue }
            times[prayer] = current.addingTimeInterval(TimeInterval(minutes * 60))
        }

        let resolution = PrayerResolution(
            origin: .device,
            source: configuration.source.resolved,
            methodID: configuration.reportedMethod.rawValue,
            madhabID: configuration.madhab.rawValue,
            adhanMethodID: configuration.effectiveAdhanMethod.rawValue,
            fajrAngle: params.fajrAngle,
            ishaAngle: params.ishaInterval > 0 ? nil : params.ishaAngle,
            ishaIntervalMinutes: params.ishaInterval,
            temkinMinutes: temkin(for: configuration),
            temkinIsDiyanet: configuration.source.appliesDocumentedTemkin
                || MethodTemkin.isTemkin(configuration.effectiveAdhanMethod),
            userOffsetMinutes: configuration.offsets.filter { $0.value != 0 },
            // Only worth surfacing where it actually changes anything: below
            // 48° the rule is a no-op safety net, and naming it in the panel
            // would be noise.
            highLatitudeRule: abs(coordinate.latitude) > 48 ? params.highLatitudeRule?.rawValue : nil,
            timeZoneIdentifier: configuration.timeZoneIdentifier,
            updatedAt: Date()
        )

        let day = DayPrayerTimes(date: dayStart,
                                 times: times,
                                 hijriDate: hijriDate(for: dayStart, configuration: configuration))
        return ResolvedPrayerDay(day: day, resolution: resolution)
    }

    /// `true` when this coordinate can produce a full schedule today.
    /// Cheap probe for "should I show the high-latitude explanation?".
    public static func isSupported(coordinate: CLLocationCoordinate2D,
                                   on date: Date = Date(),
                                   configuration: PrayerEngineConfiguration) -> Bool {
        resolved(for: date, coordinate: coordinate, configuration: configuration) != nil
    }

    // MARK: Parameters

    /// Builds adhan-swift parameters. Note that `CalculationParameters`'
    /// initialisers are `internal` to the Adhan module — the only supported
    /// entry point is `CalculationMethod.params`, which we then mutate through
    /// its public vars.
    static func parameters(for configuration: PrayerEngineConfiguration,
                           coordinates: Coordinates) -> CalculationParameters {
        var params = configuration.effectiveAdhanMethod.params
        params.madhab = configuration.madhab.adhanMadhab

        let source = configuration.source.resolved
        if let fajrAngle = source.fajrAngleOverride {
            params.fajrAngle = fajrAngle
        }
        if let ishaAngle = source.ishaAngleOverride, params.ishaInterval == 0 {
            params.ishaAngle = ishaAngle
        }

        // Temkin the tradition applies on top of its base preset's own.
        // Diyanet's already lives inside `.turkey`; Türkiye Takvimi's whole
        // 10-minute margin arrives here. See `PrayerSource.extraTemkinMinutes`.
        // `params.adjustments` is summed with `params.methodAdjustments` by
        // adhan-swift, so this never overwrites a preset's own numbers.
        let extra = source.extraTemkinMinutes
        if !extra.isEmpty {
            params.adjustments = PrayerAdjustments(
                fajr: extra[.fajr] ?? 0,
                sunrise: extra[.sunrise] ?? 0,
                dhuhr: extra[.dhuhr] ?? 0,
                asr: extra[.asr] ?? 0,
                maghrib: extra[.maghrib] ?? 0,
                isha: extra[.isha] ?? 0
            )
        }

        // Above ~48° the twilight can stop happening; without a rule Fajr and
        // Isha drift into absurdity or vanish entirely.
        params.highLatitudeRule = .recommended(for: coordinates)
        return params
    }

    /// Method temkin + tradition temkin, merged, for the transparency panel.
    static func temkin(for configuration: PrayerEngineConfiguration) -> [Prayer: Int] {
        var merged = MethodTemkin.minutes(for: configuration.effectiveAdhanMethod)
        for (prayer, minutes) in configuration.source.resolved.extraTemkinMinutes {
            merged[prayer, default: 0] += minutes
        }
        return merged.filter { $0.value != 0 }
    }

    // MARK: Helpers

    static func calendar(for configuration: PrayerEngineConfiguration) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = configuration.timeZone
        return calendar
    }

    /// Offline Hijri date via `islamicUmmAlQura`, the same civil calendar
    /// Diyanet's printed tables follow. Note this is the *civil* date for the
    /// Gregorian day; it does not roll forward at maghrib.
    static func hijriDate(for date: Date, configuration: PrayerEngineConfiguration) -> HijriDate? {
        var hijri = Calendar(identifier: .islamicUmmAlQura)
        hijri.timeZone = configuration.timeZone
        let comps = hijri.dateComponents([.year, .month, .day], from: date)
        guard let day = comps.day, let month = comps.month, let year = comps.year,
              (1...12).contains(month) else { return nil }
        return HijriDate(day: day,
                         month: month,
                         year: year,
                         monthNameEn: HijriDate.monthNamesEn[month - 1],
                         monthNameAr: Self.hijriMonthNamesAr[month - 1])
    }

    static let hijriMonthNamesAr = [
        "محرم", "صفر", "ربيع الأول", "ربيع الآخر",
        "جمادى الأولى", "جمادى الآخرة", "رجب", "شعبان",
        "رمضان", "شوال", "ذو القعدة", "ذو الحجة",
    ]
}
