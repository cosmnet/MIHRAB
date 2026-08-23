# MIHRAB — Dalga 1 (Yol haritası 🔴 "Hemen" bloğu + seçili 🟠)

Aynı anda çalışan 7 ajanın ortak sözleşmesi. **Kendi bölümünü oku, kurallara harfiyen uy.**
Bağlam için oku: `ROADMAP.md`, `RESEARCH_MARKET.md`, `RESEARCH_PLATFORM.md`, `RESEARCH_UI.md`.

## Genel kurallar (HERKES)

1. **Sadece sana verilen dosyaları düzenle.** Yeni dosyaları kendi klasörüne aç.
2. **`xcodebuild` / `xcodegen` / `simctl` ÇALIŞTIRMA.** Derleme ve simülatör doğrulaması ana oturumun işi. `swiftc -parse` ile sözdizimi kontrolü yapabilirsin.
3. **`project.yml`, `Mihrab/Info.plist`, `*.entitlements`, `*.xcprivacy`, `Mihrab.xcodeproj/` DOSYALARINA DOKUNMA.** Altyapı kuruldu (aşağıda). Ek bir şey gerekiyorsa raporunda belirt, ana oturum uygular.
4. **`Mihrab/Core/Shared/L10n.swift`'e DOKUNMA.** Kendi klasörüne `L10n+<Alan>.swift` aç, `extension L10n { ... }` yaz, adları benzersiz ön ekle. Her metin **en/tr/ar**.
5. **`Mihrab/Features/Settings/SettingsView.swift`'e DOKUNMA.** Ayar arayüzü gerekiyorsa kendi dosyanda `struct <Alan>SettingsSection: View { init() }` olarak yaz (Form içine gömülecek `Section`'lar döndürsün) ve raporunda belirt — ana oturum gömecek.
6. **Test:** kendi test dosyanı aç (`MihrabTests/<Alan>Tests.swift`). `MihrabTests/MihrabTests.swift`'e DOKUNMA. Test hedefine yeni kaynak eklenmesi gerekiyorsa raporunda söyle.
7. iOS 26, SwiftUI, Swift 6 (`SWIFT_STRICT_CONCURRENCY: minimal`), `@Observable`, Liquid Glass. Mevcut token'lara (`MihrabColor`, `MihrabFont`, `MihrabMotion`, `MihrabSpace`, `mihrabCard()`, `MihrabBackdrop(surface:)`, `mihrabShaderPanel(_:)`) uy.
8. **Erişilebilirlik:** Reduce Motion / Reduce Transparency dallanması, kontrast ≥ 4.5:1, dokunma hedefi ≥ 44pt, VoiceOver etiketleri. **Yeni yazdığın metinlerde `.font(.system(size:))` yerine Dynamic Type ölçekli font kullan** (`ScaledMetric` veya `.font(.body)` ailesi) — mevcut kodda 57 sabit punto var, çoğaltma.
9. **API uydurma.** Kullandığın her tip ya mevcut olacak ya senin yazdığın. Emin değilsen `grep` ile doğrula.
10. **Dürüstlük kuralı:** Yapamadığın veya lisans/içerik gerektiren bir şey varsa **uydurma, sahte veri koyma** — raporunda açıkça yaz. Uygulama bir ibadet uygulaması; dinî içerikte kaynak belirtilmeden rivayet/meal üretme.

## Kurulmuş altyapı (hazır, kullanabilirsin)

- **`import Adhan`** — batoulapps/adhan-swift 1.5.0, SPM ile bağlı ve derleniyor. Tamamen offline.
  - `CalculationMethod`: `.turkey` (fajr 18°, isha 17°, adjustments: sunrise −7, dhuhr +5, asr +4, maghrib +7), `.muslimWorldLeague`, `.egyptian`, `.karachi`, `.ummAlQura`, `.dubai`, `.moonsightingCommittee`, `.northAmerica`, `.kuwait`, `.qatar`, `.singapore`, `.tehran`, `.other`
  - `Madhab.shafi/.hanafi`, `HighLatitudeRule.recommended(for:)`, `Rounding`, `Shafaq`
  - `CalculationParameters` alanları: `fajrAngle`, `maghribAngle`, `ishaAngle`, `ishaInterval`, `madhab`, `highLatitudeRule`, `adjustments: PrayerAdjustments`, `methodAdjustments`, `rounding`, `shafaq`
  - `PrayerTimes(coordinates:date:calculationParameters:)` **failable** — `date` Gregoryen `DateComponents` olmalı
  - `SunnahTimes(from:)` → `middleOfTheNight`, `lastThirdOfTheNight`; `Qibla(coordinates:).direction`
  - ⚠️ Adhan'ın `Prayer`/`CalculationMethod`/`Madhab` tipleri Mihrab'ın kendi tipleriyle **aynı isimde**. `Adhan.Prayer` gibi nitelendir, karıştırma.
- **Arka plan görevleri:** `BGTaskSchedulerPermittedIdentifiers` = `com.caferkarakaya.mihrab.refresh`, `com.caferkarakaya.mihrab.maintenance`. `UIBackgroundModes` = fetch, processing, remote-notification.
- **AlarmKit:** `NSAlarmKitUsageDescription` tanımlı.
- **iCloud:** entitlement'ta `iCloud.com.caferkarakaya.mihrab` konteyneri + CloudKit servisi tanımlı.
- **App Group:** `SharedPrayerCache.appGroupID`.
- Gizlilik manifestoları her iki hedefte hazır. **Yeni bir "gerekçeli API" kullanırsan** (ör. disk alanı, aktif klavyeler) raporunda belirt.

## AlarmKit gerçek API'si (SDK'dan çıkarıldı — bunun dışına çıkma)

```swift
@available(iOS 26.0, *)
public class AlarmManager {
    public static let shared: AlarmManager
    public var authorizationState: AuthorizationState          // .notDetermined/.denied/.authorized
    public func requestAuthorization() async throws -> AuthorizationState
    public var authorizationUpdates: some AsyncSequence<AuthorizationState, Never>
    public var alarms: [Alarm] { get throws }
    public var alarmUpdates: some AsyncSequence<[Alarm], Never>
    public func schedule<M: AlarmMetadata>(id: Alarm.ID, configuration: AlarmConfiguration<M>) async throws -> Alarm
    public func cancel(id: Alarm.ID) throws
    public func stop(id: Alarm.ID) throws
    public func countdown(id: Alarm.ID) throws
    public func pause(id: Alarm.ID) throws
    public func resume(id: Alarm.ID) throws
    public enum AlarmError: Error { case maximumLimitReached }

    public struct AlarmConfiguration<Metadata: AlarmMetadata> {
        public init(countdownDuration: Alarm.CountdownDuration? = nil,
                    schedule: Alarm.Schedule? = nil,
                    attributes: AlarmAttributes<Metadata>,
                    stopIntent: (any LiveActivityIntent)? = nil,
                    secondaryIntent: (any LiveActivityIntent)? = nil,
                    sound: AlertConfiguration.AlertSound = .default)
        public static func alarm(schedule:attributes:stopIntent:secondaryIntent:sound:) -> Self
        public static func timer(duration:attributes:stopIntent:secondaryIntent:sound:) -> Self
    }
}

public struct Alarm: Identifiable, Codable, Sendable {
    public typealias ID = UUID
    public var id: UUID
    public var schedule: Schedule?
    public var countdownDuration: CountdownDuration?
    public var state: State                                     // .scheduled/.countdown/.paused/.alerting
    public enum Schedule: Codable, Hashable, Sendable {
        case fixed(Date)
        case relative(Relative)
        public struct Relative: Codable, Hashable, Sendable {
            public struct Time: Codable, Hashable, Sendable { public var hour: Int; public var minute: Int
                                                              public init(hour: Int, minute: Int) }
            public enum Recurrence: Codable, Hashable, Sendable { case weekly([Locale.Weekday]); case never }
            public var time: Time
            public var repeats: Recurrence
            public init(time: Time, repeats: Recurrence = .never)
        }
    }
    public struct CountdownDuration: Codable, Sendable, Equatable {
        public init(preAlert: TimeInterval?, postAlert: TimeInterval?)
    }
}

public protocol AlarmMetadata: Codable, Hashable, Sendable {}   // kendi tipini yaz

public struct AlarmAttributes<Metadata: AlarmMetadata>: ActivityAttributes, Sendable {
    public init(presentation: AlarmPresentation, metadata: Metadata? = nil, tintColor: Color)
}

public struct AlarmPresentation: Codable, Sendable {
    public init(alert: Alert, countdown: Countdown? = nil, paused: Paused? = nil)
    public struct Alert: Codable, Sendable {
        public init(title: LocalizedStringResource, stopButton: AlarmButton,
                    secondaryButton: AlarmButton? = nil,
                    secondaryButtonBehavior: SecondaryButtonBehavior? = nil)
        public enum SecondaryButtonBehavior: Codable, Hashable, Sendable { /* .countdown, .custom */ }
    }
    public struct Countdown: Codable, Sendable { public init(title: LocalizedStringResource, pauseButton: AlarmButton? = nil) }
    public struct Paused: Codable, Sendable { public init(title: LocalizedStringResource, resumeButton: AlarmButton) }
}

public struct AlarmButton: Codable, Sendable {
    public init(text: LocalizedStringResource, textColor: Color, systemImageName: String)
}

public struct AlarmPresentationState: Codable, Hashable, Sendable {
    public init(alarmID: Alarm.ID, mode: Mode)
    public enum Mode: Codable, Hashable, Sendable {
        case countdown(Countdown), paused(Paused), alert(Alert)   // ilişkili değerler mevcut
    }
}
```
Notlar: `AlarmAttributes` bir `ActivityAttributes`'tır — Live Activity görünümü `MihrabWidgets` hedefinde tanımlanır (o hedef **Ajan W3'ün**; ihtiyacın varsa raporunda söyle, uydurma). `sound` parametresi `ActivityKit.AlertConfiguration.AlertSound` tipindedir.

## Ortak API sözleşmesi (bağlayıcı imzalar)

**W1 sağlar** (`Mihrab/Data/`):
```swift
enum PrayerSource: String, CaseIterable, Identifiable, Sendable { case diyanet, fazilet, turkiyeTakvimi, standard }
struct PrayerEngine {                                    // cihaz üstü, offline, ağsız
    static func times(for date: Date, coordinate: CLLocationCoordinate2D,
                      settings: AppSettings) -> DayPrayerTimes?
    static func month(of date: Date, coordinate: CLLocationCoordinate2D,
                      settings: AppSettings) -> [DayPrayerTimes]
}
extension PrayerTimesRepository {
    var isUsingOfflineEngine: Bool { get }
    var lastSuccessfulRefresh: Date? { get }
}
struct PrayerSourceSettingsSection: View { init() }
```

**W2 sağlar** (`Mihrab/Core/Adhan/`):
```swift
struct AdhanSound: Identifiable, Codable, Hashable, Sendable { var id: String; var localizedName: String; var fileName: String? }
@MainActor @Observable final class AdhanLibrary {
    static let shared: AdhanLibrary
    var available: [AdhanSound] { get }
    func sound(for prayer: Prayer) -> AdhanSound
    func setSound(_ sound: AdhanSound, for prayer: Prayer?)      // nil = tüm vakitler
    func preview(_ sound: AdhanSound)
    func stopPreview()
    func importSound(from url: URL) throws -> AdhanSound
}
struct AdhanSettingsSection: View { init() }
struct NotificationSettingsSection: View { init() }
```

**W4 sağlar** (`Mihrab/Features/Cities/`, `Mihrab/Core/Subscription/`):
```swift
struct SavedCity: Identifiable, Codable, Hashable, Sendable { var id: UUID; var name: String; var latitude: Double; var longitude: Double }
@MainActor @Observable final class CityStore {
    static let shared: CityStore
    var cities: [SavedCity] { get }
    var activeCity: SavedCity? { get }
    var freeCityLimit: Int { get }                               // premium değilse 1
    func add(_ city: SavedCity) throws                           // limit aşılırsa CityStoreError.limitReached
    func remove(_ city: SavedCity)
    func activate(_ city: SavedCity)
}
struct CityListView: View { init() }
struct CitiesSettingsSection: View { init() }
struct SyncSettingsSection: View { init() }
```
Ayrıca W4, `SubscriptionManager.hasAccess(to:)`'ı **gerçekten** çalışır hale getirir; diğer ajanlar premium kapısı için yalnızca `SubscriptionManager.shared.hasAccess(to: .someFeature)` ve `PremiumLockBadge(compact:)` / `PaywallView(source: .feature)` kullansın.

**W6 sağlar** (`Mihrab/Core/Backdrop/`):
```swift
enum DaySegment: String, CaseIterable, Sendable { case fajr, sunrise, morning, dhuhr, asr, maghrib, isha, night }
extension MihrabBackdrop { init(surface: BackdropSurface, segment: DaySegment?, ramadanMode: Bool) }
```
Mevcut `MihrabBackdrop(surface:ramadanMode:)` ve `MihrabBackdrop(ramadanMode:)` init'leri **kırılmayacak**.

Bu imzalara güvenen ajanlar, dosyalar henüz diskte olmasa bile imzayı kullanabilir.
