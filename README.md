# Mihrab

Your prayer companion, beautifully present. iOS 26 · SwiftUI · Liquid Glass.

## Build & Run

```bash
xcodegen generate          # regenerate the Xcode project after adding files
open Mihrab.xcodeproj      # or build from CLI:
xcodebuild -project Mihrab.xcodeproj -scheme Mihrab \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Run tests:

```bash
xcodebuild -project Mihrab.xcodeproj -scheme Mihrab \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## What's inside

- **Today** — hero next-prayer countdown with breathing glass ring, prayer strip,
  daily hadith card, quick actions, Ramadan + religious-day banners, dhikr summary.
- **Times** — day pager (±30 days), per-prayer notification bells, sun-arc scrubber,
  monthly table with share-image export.
- **Qibla** — glass compass with orbiting Kaaba glyph, ±3° lock-on glow + haptics +
  particle burst, ARKit AR mode with brass arrow and bobbing Kaaba.
- **Deen** — daily hadith (deterministic rotation) with share-image renderer,
  Esmaül Hüsna 99-name grid, religious days list.
- **Dhikr** — full-screen tap counter, deforming glass orb, ripples, 33/99/100/500/∞
  targets, set completion celebration, weekly stats chart, crash-safe SwiftData.
- **Mosques** — MapKit POI search (mosque/camii/masjid, deduped), glass pins,
  walking directions, Jumu'ah badge.
- **Ramadan Hub** — iftar/suhoor countdown, crescent-fill day counter, duas,
  khatam tracker, Eid countdown, violet/gold seasonal theme.
- **Widgets** — Home (small/medium), Lock Screen (circular/rectangular/inline),
  Live Activity + Dynamic Island countdown (last 30 min before prayer).
- **Notifications** — per-prayer alerts scheduled ahead, daily hadith, religious
  days, Jumu'ah reminder. Time-sensitive prayer alerts.
- **Data** — Aladhan API (Diyanet method option for Türkiye), offline-first with
  App Group cache shared to widgets, bundled hadiths/99 names/adhkar/religious days.
- **Correctness** — qibla great-circle math unit-tested against 10 cities
  (Istanbul ≈ 152°, NYC ≈ 58°, Jakarta ≈ 295°…), prayer ordering verified.

## Notes

- Signing: open the project in Xcode and select your team for device runs;
  CloudKit sync and widgets need the App Group + iCloud capabilities active.
- The bundled hadith collection ships with 40 curated sahih hadiths and is
  structured to scale to 365 by appending to `Mihrab/Data/Bundled/hadiths.json`.
- Adhan audio files are not bundled; notifications use the default sound.
  Drop `.caf` files into `Mihrab/Resources/Audio` and set them in
  `NotificationEngine` to enable custom adhan alerts.
