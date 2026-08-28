# Revak

Your prayer companion, beautifully present. iOS 26 · watchOS 26 · SwiftUI · Liquid Glass.

No ads. No analytics. No account. No third-party SDK except the MIT-licensed
arithmetic library that computes the prayer times — and that one opens no
sockets. Everything required to practise is free, permanently.

- **Privacy policy** — [`docs/privacy.html`](docs/privacy.html) ·
  [English](docs/privacy-en.html)
- **Release checklist** — [`RELEASE.md`](RELEASE.md)
- **Store metadata & ASO** — [`ASO.md`](ASO.md) · **Pricing** — [`PRICING.md`](PRICING.md)
- **Roadmap** — [`ROADMAP.md`](ROADMAP.md)

## Build & run

The Xcode project is **generated**, not committed as source of truth. Edit
`project.yml`, never the `.xcodeproj`.

```bash
brew install xcodegen        # once
xcodegen generate            # after adding, moving or removing any file
open Mihrab.xcodeproj
```

Requires **Xcode 26** (iOS 26 / watchOS 26 SDKs — AlarmKit, Liquid Glass and
`scrollEdgeEffectStyle` are all iOS 26 APIs). The single package dependency,
[`adhan-swift`](https://github.com/batoulapps/adhan-swift), resolves on first
open.

From the command line:

```bash
xcodebuild -project Mihrab.xcodeproj -scheme Revak \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Signing: pick your team in Xcode for device runs. Four targets need
capabilities — App Groups, iCloud/CloudKit, Push (for CloudKit's silent wake)
and Background Modes. [`RELEASE.md` §4](RELEASE.md) lists exactly which, and
where each is declared.

## Tests

```bash
xcodebuild -project Mihrab.xcodeproj -scheme Revak \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

15 suites in `MihrabTests/`, all pure-logic and simulator-only — no network, no
fixtures downloaded at run time. The ones worth knowing about:

| Suite | Guards |
|---|---|
| `PrayerEngineTests` · `PrayerAccuracyTests` | The offline engine against known values, and prayer ordering |
| `QiblaAccuracyTests` | Great-circle bearing against 10 cities (Istanbul ≈ 152°, NYC ≈ 58°, Jakarta ≈ 295°) |
| `SubscriptionGateTests` | That every `PremiumFeature` names the call site enforcing it — a paywall must not sell what the binary does not gate |
| `NotificationScheduleTests` | The 64-notification budget, especially in kandil-dense months |
| `WatchBridgeTests` | The phone↔watch payload shape and its version guard |
| `AccessibilityTests` | Dynamic Type and Reduce Motion branches |
| `ContentSourceTests` · `QuranTests` | That bundled religious content matches its declared source |

`swiftc -parse` on a single file is a fast syntax check; it is not a substitute
for the suite.

## Architecture

### Targets

| Target | Platform | What it is |
|---|---|---|
| `Revak` | iOS 26 | The app |
| `MihrabWidgets` | iOS 26 | Home/Lock Screen widgets, Live Activity, Controls |
| `MihrabWatch` | watchOS 26 | Standalone watch app, embedded in the iPhone binary |
| `MihrabWatchWidgets` | watchOS 26 | Complications |
| `MihrabTests` | iOS 26 | Unit tests |

Shared code is not a framework — `project.yml` lists the same source paths in
several targets. `Revak/Core/Shared/` is the deliberate common floor: pure
Foundation and SwiftUI, no UIKit, no WatchKit, nothing platform-specific, so it
compiles into all five.

### The offline prayer-time engine

The core feature is unconditional. Times resolve in this order, and step 2
always runs:

1. **Persistent cache** — App Group container, survives relaunch, instant.
2. **On-device engine** — `adhan-swift`, works in airplane mode, at 10 000 m,
   during an API outage.
3. **Network** — Aladhan, optional polish. When it answers, its values overwrite
   the computed ones and are written to disk.

So a network failure downgrades precision, never availability.
`PrayerTimesRepository.isUsingOfflineEngine` reports which of the two you are
looking at, and the UI says so quietly rather than raising an error.

On top of the calculation method sits `PrayerSource` — the Turkish calendar
traditions as angle and minute overrides, plus a per-prayer ± minute correction
the user controls. The transparency panel names which source produced the number
on screen.

`PrayerSource` also demonstrates the house rule about not inventing values:
Diyanet (with its *temkin*) and Türkiye Takvimi ship because their published
parameters could be sourced. **Fazilet Takvimi is `isSelectable = false`** — its
temkin is unpublished, so rather than guessing an angle the case stays decodable
for old stored values and resolves to Diyanet, and `allCases` is overridden so no
picker anywhere can offer it. That override is deliberate; do not "fix" it.

### The App Group

`group.com.caferkarakaya.mihrab` is the seam between the app and its extensions
on one device: the prayer cache, the generated adhan tones, the sync switch and
a mirror of the Plus entitlement all live there, because a widget extension
cannot import `SubscriptionManager`.

### The watch bridge

**App Group containers are not shared between an iPhone and its paired Watch** —
same identifier, two separate containers on two separate devices. The link is
`WatchConnectivity`, and it carries **settings, not results**: coordinate,
method, madhab, source, per-prayer offsets, time zone. The watch runs the same
`PrayerEngine` and computes its own times. Consequences: the watch works with
the phone off, and the complication never goes blank waiting for a transfer.
`WatchBridgePayload.swift` is compiled into both sides and versioned.

### iCloud

Two layers, both optional and both off by default:
`NSUbiquitousKeyValueStore` for the small `UserDefaults`-backed stores (packed
into one JSON blob, because the store caps at 1 MB / 1024 keys), and SwiftData +
CloudKit private database for the three `@Model` types. It is the user's own
private database; the developer cannot read it.

> ⚠️ Once the CloudKit schema is deployed to Production it can only be changed
> **additively** — no field can be removed, renamed or retyped. See
> [`RELEASE.md` §6](RELEASE.md).

## Folder map

```
Revak/
  App/            MihrabApp, RootView — the two files nobody edits casually
  Core/
    Shared/       DesignTokens, PrayerModels, L10n, SharedPrayerCache
                  — pure, compiled into every target
    Adhan/        AlarmKit scheduler, sound library, reminder planner
    Backdrop/     The time-of-day scene: shaders, veils, day segments
    Brand/        The Revak mark
    Connectivity/ WatchBridgePayload + PhoneWatchBridge
    Shaders/      MihrabShaders.metal
    Subscription/ SubscriptionManager, PremiumGate, entitlement mirror
    Sync/         CloudSyncManager, KeyValueSync
    LocationManager, NotificationEngine, BackgroundRefresh, Haptics…
  Data/
    PrayerEngine, PrayerSource, PrayerTimesRepository, PrayerCacheStore
    AladhanClient          the one and only remote endpoint
    Bundled/               hadiths, esma, adhkar, religious days, Qur'an text
    Models/                SwiftData models + the CloudKit container
  Features/       Today · Times · Qibla · Deen · Dhikr · Quran · Hatim
                  Ramadan · Calendar · Qada · Zakat · Cities · Mosques
                  Onboarding · Paywall · Settings
  Intents/        App Intents, shortcuts, Spotlight, the intent bridge
  Resources/      Localizable/InfoPlist string catalogs, fonts, generated art,
                  PrivacyInfo.xcprivacy, Revak.storekit
MihrabWidgets/    Home, Lock Screen, Live Activity, Controls
MihrabWatch/      Watch app — Views/ and Shared/
MihrabWatchWidgets/ Complications
MihrabTests/      One suite per area
docs/             The published site: privacy, terms, support
Scripts/          generate_localizable.py, generate_icon.swift
```

## Content & licences

Revak does not ship text, audio or type it has no right to — and it never
invents a religious value it cannot source.

| Content | Source | Licence |
|---|---|---|
| Qur'an, Arabic (Uthmani v1.1) | [Tanzil Project](https://tanzil.net) | **CC BY 3.0** — verbatim, attributed in-app with a live link. See [`Revak/Features/Quran/CONTENT_LICENSE.md`](Revak/Features/Quran/CONTENT_LICENSE.md) |
| Prayer-time calculation | [adhan-swift](https://github.com/batoulapps/adhan-swift) | MIT |
| Prayer-time reconciliation | [Aladhan](https://aladhan.com) | Public API |
| Arabic type | Amiri Quran | SIL Open Font License 1.1 |
| Hadith, Esma, adhkar, religious days | Cited per record in-app | Shown with its source |

Two deliberate absences:

- **No Qur'an translation.** Every Turkish and English translation reviewed is
  either copyrighted or licensed for non-commercial use only. The app says so
  plainly rather than shipping one it has no right to.
- **No adhan recording.** `Revak/Resources/Audio/` ships empty on purpose.
  Instead the app generates royalty-free tones on device and lets anyone import
  their own file — see [`Revak/Resources/Audio/README.md`](Revak/Resources/Audio/README.md)
  for the format notes and the licensing checklist.

## Contributing

House rules, in the order they get violated:

1. **Never edit `Mihrab.xcodeproj`.** Edit `project.yml`, run `xcodegen generate`.
2. **Every new user-facing string goes in an `L10n+<Area>.swift` file in its own
   feature folder, with `en` / `tr` / `ar`.** Never a bare literal in a view.
3. **No fixed `.font(.system(size:))`.** Use a semantic font or the
   `mihrabCountdown` / `mihrabTime` / `mihrabQuote` modifiers, which run the size
   through `ScaledMetric`. Dynamic Type is not optional here.
4. **Any `formatted` call that produces a month or day name takes
   `.locale(L10n.appLocale)`** — otherwise a Turkish user gets English months.
5. **Every animation branches on Reduce Motion**, and the expensive ones also
   check `LocationManager.shared.isLowPowerMode`.
6. **Tests go in `MihrabTests/<Area>Tests.swift`.**
7. **Do not invent.** No religious or numeric value you cannot source, no
   copyrighted content, no API that does not exist. If a value is uncertain,
   mark it `⚠️ VERIFY` with the reason — several such markers are live in the
   codebase and tracked in [`RELEASE.md` §9](RELEASE.md).
8. **The paywall may not sell what the binary does not gate.** Add a
   `PremiumFeature` case only together with its enforcement site;
   `SubscriptionGateTests` checks this.

Honesty is a feature: an uncalibrated compass says so, a computed time says it
was computed, a missing translation says why it is missing. Please keep it that
way.
