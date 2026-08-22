# MIHRAB — Master Build Document
### One-Shot App Specification · iOS 26 · Liquid Glass · Apple Design Award Target

> **How to use this file:** Feed this entire document to an AI coding agent (or follow it manually) as the single source of truth. It contains the complete product spec, design system, screen-by-screen UI instructions with real-world Mobbin references, API contracts, animation recipes, and acceptance criteria. Build it in one pass, in the milestone order given in §14.

---

## 1. Product Vision

**Name:** Mihrab (working alternative: Sahabe)
**Tagline:** "Your prayer companion, beautifully present."
**Platform:** iOS 26+ (iPhone), iPadOS 26, watchOS 26 companion, widgets everywhere.
**North star:** An Islamic daily-companion app so polished it wins an **Apple Design Award**. Every pixel intentional, every animation physical, every piece of data accurate and sourced.

**Core loop:** Open app → see next prayer countdown at a glance → glance at daily hadith → tap to Qibla when needed → log dhikr → get reminded, gently, all day.

**Pillars:**
1. **Accuracy** — prayer times from verified APIs, correct calculation methods, Diyanet option for Türkiye.
2. **Beauty** — Liquid Glass everywhere, deep botanical green, cinematic motion.
3. **Presence** — widgets, Live Activities, Dynamic Island, Apple Watch, StandBy. The app lives on the user's screen even when closed.
4. **Reverence** — no ads, no clutter, no gamification noise. Calm, respectful, premium.

---

## 2. Design Language — "Emerald Glass"

The visual identity is **Apple's Liquid Glass design language (iOS 26)** fused with a **deep botanical dark green** — think a mosque garden at night: wet leaves, brass lanterns, moonlight on marble. Primary UI inspiration: the **Wise app** (clean, confident green fintech UI) crossed with **Apple Fitness'** dark glow and **Oura's** quiet luxury.

### 2.1 Color System

| Token | Hex | Usage |
|---|---|---|
| `mihrab.abyss` | `#07120D` | App background base (near-black green) |
| `mihrab.forest` | `#0D2418` | Primary surface |
| `mihrab.moss` | `#143322` | Elevated surface / card base under glass |
| `mihrab.emerald` | `#1FA96B` | Primary accent — active prayer, CTAs, progress |
| `mihrab.mint` | `#7FE0B2` | Secondary accent — highlights, countdown digits |
| `mihrab.sprout` | `#B8F5D6` | Tertiary accent — subtle glows |
| `mihrab.brass` | `#C9A24B` | Sacred accent — Kaaba, religious days, hadith ornaments |
| `mihrab.text.primary` | `#F2F7F4` | Primary text |
| `mihrab.text.secondary` | `#9DB8AA` | Secondary text |
| `mihrab.text.tertiary` | `#5F7A6B` | Metadata text |
| `mihrab.danger` | `#E4685C` | Destructive only |
| `mihrab.ramadan.violet` | `#2A2140` | Ramadan theme background shift |
| `mihrab.ramadan.gold` | `#E8C476` | Ramadan theme accent |

- Backgrounds are **never flat**: `mihrab.abyss` base + a slow-moving radial aurora gradient (`mihrab.forest` → transparent, 24s drift) + fine grain/noise overlay (2% opacity) so glass has something to refract.
- During **Ramadan**, the entire app shifts to the violet/gold palette automatically (with manual override in Settings).
- All colors defined as SwiftUI `Color` assets with light-mode variants (light mode = soft parchment `#F6F3EC` base, same emerald accents). Dark is the hero; light must still be flawless.

### 2.2 Liquid Glass Rules (iOS 26)

- **Tab bar:** floating Liquid Glass pill, 16pt horizontal margins, morphs into a compact pill on scroll (standard iOS 26 behavior — do not fight it).
- **Cards:** `.glassEffect(.regular, in: .rect(cornerRadius: 28))` over `mihrab.moss` at 40% opacity. Never put glass on a flat light background — glass needs the aurora behind it.
- **Interactive glass:** buttons and tappable cards use `.glassEffect(.regular.interactive())` so they get the press-down specular shift.
- **Glass containers:** grouped controls (prayer time rows, settings clusters) use `GlassEffectContainer` with `spacing: 12` so adjacent glass elements merge and separate with the iOS 26 morphing animation.
- **Sheets:** prayer detail, hadith share, and mosque detail open as glass sheets with `.presentationBackground(.ultraThinMaterial)` and visible background bleed.
- **Edge lighting:** key surfaces (countdown ring, compass bezel) get a 1pt inner stroke gradient from `mihrab.mint` (top, 60%) to transparent — the "wet glass edge" look.
- **Scroll edge effect:** top of scrolling content uses `.scrollEdgeEffectStyle(.soft, for: .top)` so content dissolves under the glass nav bar.

### 2.3 Typography

| Role | Font | Details |
|---|---|---|
| Display numerals (countdown) | SF Pro Rounded Bold | 64–96pt, monospaced digits, `mihrab.mint` |
| Screen titles | SF Pro Bold | 28–34pt |
| Prayer names | SF Pro Semibold | 20pt |
| Body | SF Pro Regular | 16–17pt, `mihrab.text.secondary` |
| Hadith / verse quotes | **New York** serif | 20–24pt, italic for translation |
| Arabic text | **Amiri Quran** (bundled) | 28–34pt, `mihrab.text.primary`, always right-aligned, line-height 1.9 |
| Ornamental labels | SF Pro Medium, all-caps | 11pt, tracking 1.5, `mihrab.brass` |

### 2.4 Iconography & Illustration

- SF Symbols 7 everywhere, `hierarchical` rendering with emerald tint. Custom symbols only for: Kaaba, mihrab arch, prayer beads, crescent-with-star (drawn as SF Symbols-compatible custom symbols).
- Empty states and onboarding use **soft 3D-style illustrations**: glass crescent, glass prayer beads, glass Kaaba — rendered as layered blurs + gradients in SwiftUI (no asset bloat) or bundled Lottie files.
- App icon: deep forest green, glass mihrab arch with a brass crescent inside, subtle inner glow. Deliver all sizes + dark/tinted variants.

### 2.5 Motion Principles

- **Physics, not curves.** Default spring: `.spring(response: 0.45, dampingFraction: 0.82)`. Snappy spring for taps: `.spring(response: 0.28, dampingFraction: 0.7)`.
- **Nothing linear.** No `easeInOut` anywhere except opacity crossfades.
- **Stagger:** list appearances stagger 40ms per row, scale 0.96→1 + opacity 0→1 + 12pt rise.
- **Ambient life:** aurora gradient drifts; countdown ring breathes (scale 1.0→1.015, 4s); glass highlights shift with device motion via `motionEffect` (CoreMotion attitude, ±6pt parallax).
- **Reduce Motion:** all ambient motion and parallax disabled, replaced with crossfades. Non-negotiable.

### 2.6 Haptics (Core Haptics)

| Moment | Haptic |
|---|---|
| Dhikr tap | `.impact(style: .soft, intensity: 0.6)` |
| Dhikr set complete (33/99/100) | `.notification(.success)` + custom CHHapticPattern "heartbeat triple-pulse" |
| Qibla aligned | continuous gentle tick while rotating + `.notification(.success)` lock-on |
| Prayer time arrives | `.notification(.warning)` with adhan |
| Compass degree crossing | transient tick every 5° (throttled) |
| Sheet open/close | `.impact(style: .light)` |

---

## 3. App Architecture

**Five tabs** (floating glass tab bar, center tab is visually elevated):

1. **Today** (house.fill) — dashboard
2. **Times** (clock.fill) — full prayer schedule
3. **Qibla** (location.north.circle.fill) — compass + AR — *center tab, raised glass orb with Kaaba glyph*
4. **Deen** (book.fill) — hadith, Esmaül Hüsna, religious days
5. **Dhikr** (circle.grid.3x3.fill) — Zikirmatik

Secondary destinations pushed or sheeted: Mosque Map (from Today), Ramadan Hub (seasonal, replaces a Today slot + appears in Times), Settings (gear in Today nav bar), Prayer Detail, Notifications settings.

---

## 4. Screen-by-Screen Specification

### 4.1 Launch & Onboarding

**Mobbin references:** [lululemon onboarding flow](https://mobbin.com/flows/68559489-94dd-47cd-b157-c17687bef70f), [Turo onboarding flow](https://mobbin.com/flows/468fe59a-69ba-4e7f-a8fb-8c0ddc48bf71)

- **Launch screen:** black-green, brass crescent draws itself (SVG path animation, 1.2s), "Mihrab" wordmark fades, bismillah calligraphy in Amiri appears last. Total ≤ 2s, skippable on subsequent launches (0.6s version).
- **Onboarding — 5 pages, full-screen glass cards over the aurora background, page dots in brass:**
  1. **Welcome** — glass Kaaba illustration, "Prayer, beautifully present." CTA: "Begin".
  2. **Location** — "For precise prayer times" — `CLLocationManager` WhenInUse request with a live preview card showing detected city + sample times. Fallback: manual city search (search-as-you-type, Aladhan city endpoint).
  3. **Calculation method** — picker: Diyanet (Türkiye), Umm al-Qura, ISNA, MWL, Egypt, Karachi, etc. + madhab (Hanafi/Shafi'i for Asr). Smart default by locale (TR → Diyanet/Hanafi).
  4. **Notifications** — "Never miss a prayer" — per-prayer toggle preview (Fajr…Isha rows with bell icons), adhan sound picker (3 bundled adhans + silent), request `UNUserNotificationCenter` authorization.
  5. **Widget teaser** — looping video/animation of the Home Screen widget + Live Activity. "Add it later in Settings." CTA: "Enter Mihrab" → glass morph transition into Today.
- Progress is a thin brass line under the nav area. Swipe-back allowed. Skip button top-right from page 2 onward.

### 4.2 Today (Home Dashboard)

**Mobbin references:** [Oura dark dashboard](https://mobbin.com/screens/f2dfd1b5-f040-4ff4-a241-abdf48b5f7ae), [WHOOP home](https://mobbin.com/screens/4d288d6d-281a-4980-b16d-87c1da58ea14), [Open home](https://mobbin.com/screens/1e339d42-4e73-4aab-b876-429c65c0a3d7), [Breathwrk home](https://mobbin.com/screens/6e621f11-8e81-4a8a-9379-ed1382943699), [Sunlitt sun-times screen](https://mobbin.com/screens/38d88fa6-3308-475c-aa37-e0db8f9f99da)

Vertical scroll, glass cards over aurora, large-title nav ("Good evening, Ahmed" — time-of-day greeting + first name optional):

1. **Hero countdown card** (top, ~44% of first viewport):
   - Ornamental caps label: "ISHA IN" — giant SF Rounded countdown `02:14:36` ticking every second in `mihrab.mint`.
   - Behind digits: a **breathing progress ring** showing elapsed fraction between previous and next prayer; ring is glass-edged with brass tip marker.
   - Prayer name in Arabic (العشاء) small above, Gregorian + **Hijri date** below ("17 Safar 1448").
   - Subtle Kaaba silhouette watermark bottom-right at 6% opacity.
   - Tap → Times tab. Long-press → quick actions (mute tonight, share times).
2. **Prayer strip** — horizontal scroll of 6 glass pills (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha): name, time, tiny icon (dawn/sun/moon SF Symbols). Passed prayers at 45% opacity; current/next pill has emerald fill + white text + soft glow. Auto-scrolls so next prayer is centered.
3. **Daily Hadith card** — brass "DAILY HADITH" caps label, New York serif quote (truncated 3 lines), narrator line, tap → full hadith sheet (§4.7). Share button (glass circle, square.and.arrow.up).
4. **Quick actions row** — 3 glass circles: **Mosques** (map), **Qibla AR** (camera), **Zikirmatik** (beads). Labels beneath, staggered spring-in on appear.
5. **Ramadan card** *(only during Ramadan ± 3 days)* — violet glass, crescent + lantern illustration, "Iftar 19:42 · 3h 12m left" + "Suhoor ends 04:51", tap → Ramadan Hub (§4.6).
6. **Religious day card** *(when a holy night/day is within 7 days)* — brass-bordered glass: "Laylat al-Mi'raj in 4 days", tap → Religious Days list (§4.9).
7. **Dhikr summary card** — today's count vs daily goal, mini ring, tap → Zikirmatik.

### 4.3 Times (Prayer Schedule)

**Mobbin references:** [Lumy prayer-style list](https://mobbin.com/screens/e37f48a3-fb38-43c3-86b4-2ba29608408d), [Sunlitt schedule](https://mobbin.com/screens/7f631834-4126-4bf3-b8de-10e2228b32f6), [Tide Guide timetable](https://mobbin.com/screens/566be3ca-eaa1-48d4-86bf-01fcea71c35f)

- **Header:** location pill (city + change), Hijri + Gregorian date, calculation-method label (tap → settings).
- **Day pager:** swipe horizontally between days (±30 days), date snaps with haptic. "Today" button returns.
- **Prayer rows** in a `GlassEffectContainer`: each row = prayer name (EN + AR), time in SF Rounded 28pt, bell icon (toggles that prayer's notification inline with a delightful bell-ring rotation animation), and a thin timeline rail on the left connecting rows — a brass dot marks "now" on the rail.
- **Current prayer row** is expanded: shows time remaining, iqama offset if set, and a mini qibla arrow.
- **Sun path footer:** an arc visualization of the day (like Sunlitt) — sun/moon position now, prayer markers on the arc. Dragging along the arc scrubs time and highlights the owning prayer.
- **Monthly view** button → full-month glass table (monospaced times, today highlighted, Ramadan rows tinted violet). Export as image (styled share card) and PDF.
- **Imsak & Iftar** rows appear during Ramadan.

### 4.4 Qibla — Compass

**Mobbin references:** [Lumy compass](https://mobbin.com/screens/55115cb5-0146-4a11-8d40-78b5ad136c02), [Tide Guide compass](https://mobbin.com/screens/792ecf30-b4d5-41fd-80f7-ddd7154392fd)

The app's crown jewel. Full-bleed dark screen:

- **Compass dial:** 360° glass bezel ring, degree ticks every 5° (major ticks brass at cardinal points, N/E/S/W letters in SF Rounded). Dial rotates under a fixed top marker; numbers stay upright (counter-rotated).
- **Kaaba indicator:** a glass Kaaba cube glyph orbits on the dial at the qibla bearing. When within **±3° of qibla**: dial edge ignites with an emerald→mint gradient glow, Kaaba glyph scales 1→1.25 with brass halo, success haptic fires once, and a soft particle burst (12 brass sparks) plays. State text swaps: "Facing the Qibla ✓".
- **Center readout:** current heading in degrees (SF Rounded 48pt), qibla bearing below ("Qibla 152° SE"), distance to Makkah ("2,743 km") with a tiny great-circle arc icon.
- **Calibration:** if accuracy is poor, show Apple's calibration prompt + an inline "move in a figure-8" glass hint card.
- **Level mode:** when device is flat (pitch < 15°), dial becomes a top-down radar view; when raised, crossfade to the raised view. Both share the same bearing math.
- **AR button** — glass pill bottom-center: "View in AR" → §4.5.
- Compass math: `CLLocationManager` heading + qibla bearing from great-circle formula (and cross-check with Aladhan `/qibla/{lat}/{lng}` once online). Smooth heading with a low-pass filter (α=0.15) + shortest-path angular spring so the dial never spins the long way.

### 4.5 Qibla — Augmented Reality

- **ARKit + RealityKit** scene via `ARView` in a SwiftUI wrapper, full screen, glass HUD.
- World-tracking configuration; coaching overlay (Apple's `ARCoachingOverlayView`) styled to match.
- A **brass-edged glass arrow** floats 1.5m ahead pointing at the qibla bearing; a miniature **Kaaba model** (simple black cube entity with gold band — built in Reality Composer or code with `MeshResource` + materials) hovers at the end of the arrow at 3m, gently bobbing (sinusoidal ±4cm, 3s).
- **Distance label** anchored above the Kaaba: "Makkah · 2,743 km" facing the camera (billboard constraint).
- When the camera's forward vector aligns with qibla ±3°: arrow turns emerald, Kaaba emits a soft point light, haptic lock-on, "You're facing the Qibla" glass banner slides down.
- Floor grid: subtle emerald grid shader fading with distance (custom `ShaderGraphMaterial` or simple unlit texture) for spatial grounding.
- Fallback: devices without ARKit or denied camera → graceful glass alert routing back to compass.
- Privacy copy: "Camera is used only to show direction. Nothing is recorded or uploaded."

### 4.6 Ramadan Hub

Seasonal destination (auto-prominent 3 days before Ramadan → end of Eid):

- **Hero:** violet-glass card, animated crescent + stars parallax field, countdown to **Iftar** (Maghrib) or **Suhoor end** (Imsak) — whichever is next — in giant SF Rounded digits, with "May Allah accept your fast" microcopy rotating daily.
- **Dual times card:** Suhoor ends / Iftar times for today, with a 30-day Ramadan timetable (swipe → full month glass table, exportable).
- **Fasting day counter:** "Day 12 of 29" with a crescent-fill progress (crescent fills like a moon phase — custom `Shape` + mask animation).
- **Daily Ramadan duas** card (iftar dua, suhoor intention) in AR + TR/EN.
- **Khatam tracker** (optional): log daily juz reading, progress ring toward 30, streak flame in brass.
- **Eid countdown** after day 20: "Eid al-Fitr in 6 days" with confetti-burst animation on Eid morning + eid greeting card shareable image.
- Theme: whole app shifts to `ramadan.violet/gold` tokens (§2.1) with a 600ms crossfade on first open of the season.

### 4.7 Daily Hadith

**Mobbin references:** [Waking Up quote card](https://mobbin.com/screens/17f552f8-7a09-4137-a21d-463234c96f4b), [5 Minute Journal quote](https://mobbin.com/screens/7fb26723-6a58-4537-b7f4-48f38e398e85), [Open daily card](https://mobbin.com/screens/cff9bea5-009e-49cc-afdb-27c2a2389a23)

- **Card/sheet layout:** ornamental brass divider, Arabic text (Amiri, right-aligned), translation in New York italic, narrator + source + hadith number (e.g., "Bukhari, Īmān 2"), authenticity grade chip (Sahih = emerald glass chip, Hasan = mint, etc.).
- **Daily rotation:** deterministic by date (hash of date → index) so all users see the same hadith; cached 30 days ahead for offline.
- **Browse:** vertical pager of past 30 hadiths, date-labeled.
- **Share sheet:** generates a **beautiful share image** (1080×1350): aurora background, brass frame, Arabic + translation, small Mihrab wordmark. Rendered off-screen with `ImageRenderer`.
- Favorite (bookmark.fill) → stored locally, "Saved" section in Deen tab.

### 4.8 Zikirmatik (Dhikr Counter)

**Mobbin references:** [Breathwrk session screen](https://mobbin.com/screens/22a34ba5-9da8-41c2-800c-d1376abc076d), [(Not Boring) Timer](https://mobbin.com/screens/46b41eb2-d25a-45f4-adaf-3c61d61cc3c9), [Tonal counter](https://mobbin.com/screens/5e9461c9-d902-4e37-ad82-906753bc7583)

- **The tap surface:** entire screen is the button. Center: giant count in SF Rounded 96pt inside a **glass orb** that deforms on tap (scale 0.94, spring back) with an expanding emerald ripple ring (like a drop in water). Haptic per §2.6.
- **Progress ring** around the orb toward the set target (33 / 99 / 100 / 500 / custom / ∞). Ring fills with gradient emerald→mint; on target completion: orb flashes brass, particle celebration (20 sparks), success haptic, count rolls over with an odometer animation, set counter increments ("Set 2 of 3").
- **Dhikr selector:** horizontal glass chips — Subhanallah, Alhamdulillah, Allahu Akbar, La ilaha illallah, Salawat, custom… Each chip shows Arabic + transliteration. Selected chip glows.
- **Stats strip** (bottom, collapsible): today total, week total, all-time, current streak days. Tap → full stats screen with weekly bar chart (Swift Charts, glass bars).
- **Presets:** "After prayer" (33×3), "Morning adhkar", "Evening adhkar" — multi-dhikr sequences that auto-advance with a chime + haptic between items.
- **Always-on option:** keep screen awake toggle; dim-to-10% after 30s idle (not full sleep).
- Counts persist in SwiftData instantly (crash-safe). iCloud sync via CloudKit.

### 4.9 Deen (Knowledge Tab)

Hub with three glass sections:

1. **Daily Hadith** — entry to §4.7 + Saved hadiths.
2. **Esmaül Hüsna (99 Names)** — a 3-column glass grid of the 99 names in Arabic calligraphy (Amiri). Tap a name → detail sheet: large Arabic, transliteration, meaning (TR/EN), a short reflection paragraph, "Recite" button that drops into Zikirmatik pre-loaded with that name and a 100 target. Grid tiles have a slow shimmer sweep on first appear (staggered 15ms).
3. **Religious Days (Dini Günler)** — chronological list of the Hijri year's holy days/nights: Ramadan start, Laylat al-Qadr, Eid al-Fitr, Eid al-Adha, Ashura, Mawlid, Mi'raj, Barat, Raghaib, Hijri New Year… Each row: Hijri + Gregorian date, days-until pill (brass when < 7 days), info dot → short explainer sheet. Data: Aladhan Hijri calendar + bundled curated descriptions (TR/EN).

### 4.10 Mosques Nearby

**Mobbin references:** [Tripadvisor map + list](https://mobbin.com/screens/b6e39606-ab24-499b-9333-314b29f4a8f3), [Starbucks store map](https://mobbin.com/screens/6137bdfc-9652-483d-b11e-15f10d0edcb2)

- **Map:** MapKit, dark style tinted to palette (custom `MapStyle` / standard dark), user location puck in emerald. Mosque pins = custom glass annotation with crescent glyph; selected pin grows with spring and shows brass ring.
- **Bottom sheet** (`.presentationDetents([.height(120), .medium, .large])`, glass): nearest mosques list — name, distance ("650 m"), walking time, open-now indicator if available, directions button (opens Apple Maps with walking route), call button if phone exists.
- Data: **MapKit `MKLocalSearch`** (`pointOfInterestFilter = .init(including: [.placeOfWorship])` + natural-language "mosque"/"camii"/"masjid" queries, deduped). Optional Google Places fallback behind a protocol if configured with an API key.
- List ↔ map sync: tapping a row flies the camera (spring) and selects the pin; dragging the map triggers "Search this area" glass chip.
- "Jumu'ah" badge on Fridays on the sheet header with next Friday prayer time.

### 4.11 Settings

Grouped glass `Form`, iOS 26 style:

- **Prayer:** calculation method, madhab (Asr), high-latitude rule, iqama offsets per prayer, per-prayer notification toggles + adhan sound per prayer.
- **Location:** current city, manual override, "use precise location" toggle.
- **Appearance:** theme (Auto/Dark/Light), Ramadan theme toggle, app icon picker (default/emerald/brass).
- **Notifications:** quiet hours, Jumu'ah reminder, daily hadith time, religious-day alerts (day before + morning of), dhikr daily-goal reminder.
- **Widgets:** setup instructions with live previews.
- **Language:** Türkçe / English / العربية (full RTL support).
- **Data:** iCloud sync toggle, export dhikr history (CSV), reset.
- **About:** version, data sources & credits (Aladhan, hadith sources), privacy policy, "Rate Mihrab".

---

## 5. Widgets & System Surfaces (WidgetKit)

| Surface | Content | Family |
|---|---|---|
| **Lock Screen circular** | Next prayer glyph + countdown ring | accessoryCircular |
| **Lock Screen rectangular** | "Isha 21:43 · in 2h 14m" + mini day strip | accessoryRectangular |
| **Lock Screen inline** | "Isha in 2:14" | accessoryInline |
| **Home small** | Next prayer, countdown, Hijri date, aurora bg | systemSmall |
| **Home medium** | Next prayer + all 5 times row, current highlighted | systemMedium |
| **Home large** | Medium content + daily hadith excerpt | systemLarge |
| **Live Activity / Dynamic Island** | Last 30 min before prayer: countdown in Island (leading: prayer glyph, trailing: mm:ss; expanded: full times + qibla arrow). During Ramadan: iftar countdown. | ActivityKit |
| **StandBy** | Full-screen clock + next prayer + qibla arrow, night-mode dimmed emerald | systemLarge (StandBy) |
| **Apple Watch** | Companion app: next prayer complication-ready, zikirmatik tap counter with haptic crown, qibla compass | watchOS 26 |
| **Control Center** | "Open Qibla" + "Start Dhikr" controls | ControlWidget |
| **Siri / App Intents** | "When is Maghrib?", "What's the qibla direction?", "Log 33 Subhanallah" | AppIntents |

Widgets share the app's design tokens via an App Group; timelines refresh at prayer boundaries + every 15 min; deep links: tap widget → Times tab with that prayer highlighted.

---

## 6. Data & APIs

| Need | Source | Endpoint / Method | Notes |
|---|---|---|---|
| Prayer times | **Aladhan API** | `GET https://api.aladhan.com/v1/timings/{DD-MM-YYYY}?latitude=&longitude=&method=` | Method IDs: 13=Diyanet, 4=Umm al-Qura, 2=ISNA, 3=MWL, 5=Egypt, 1=Karachi. Cache 7 days offline. |
| Prayer times (calendar bulk) | Aladhan | `GET /v1/calendar/{year}/{month}?latitude=&longitude=&method=` | Prefetch current + next month. |
| Diyanet exact (Türkiye) | Diyanet-compatible mirror (e.g. `vakit.vercel.app` / namazvakti API) | `GET /api/times?city=` | Optional toggle "Diyanet exact times" for TR users. |
| Qibla bearing | Local math + Aladhan verify | `GET /v1/qibla/{lat}/{lng}` | Great-circle formula locally; API as sanity check. |
| Hijri calendar / conversion | Aladhan | `GET /v1/gToH/{date}` & `/v1/hToG/{date}` | Cache aggressively. |
| Religious days | Aladhan `holidays` + bundled curated JSON | bundled `religious_days.json` (TR/EN descriptions) | Merge: API dates + curated copy. |
| Hadith | **Bundled dataset** (primary) + Sunnah.com API (optional, key-gated) | local `hadiths.json` — 365 curated hadiths: arabic, tr, en, narrator, source, grade | Zero network dependency for daily card. |
| Esmaül Hüsna | Bundled | `esma.json` — 99 names: arabic, transliteration, tr/en meaning, reflection | — |
| Duas / adhkar | Bundled | `adhkar.json` — morning/evening/after-prayer sets | — |
| Mosques | **MapKit MKLocalSearch** (primary), Google Places (optional) | `MKLocalSearch` with POI filter + keyword | No key needed with MapKit. |
| Geocoding / city search | CoreLocation `CLGeocoder` + Aladhan city endpoint | — | — |
| Adhan audio | Bundled | 3 reciters (Makkah, Madinah, Istanbul style), `.caf`, < 30s notification-critical excerpts + full versions in-app | Notification sounds must be bundled for custom alerts. |

**Networking layer:** `APIClient` protocol + `AladhanClient` concrete, `async/await`, `Codable` DTOs, `URLSession` with `URLCache` (50MB), exponential backoff, and a `PrayerTimesRepository` that resolves: cache (valid) → network → last-known cache (stale-while-error). All times normalized to the device's time zone; DST-safe via `Calendar`/`TimeZone` APIs, never manual offsets.

---

## 7. Backend

The app is **offline-first**; the backend exists for sync, content freshness, and scale.

- **Primary: CloudKit** (zero-ops, Apple-native, ADA-friendly):
  - Private DB: dhikr history, favorites, settings, khatam progress (sync across devices).
  - Public DB (optional): curated content packs (new hadith batches, religious-day copy updates) fetched as records so content can refresh without an app update.
- **Optional service layer (Vapor or Supabase Edge Functions)** — only if adding community features later (congregation iqama times, mosque corrections). Spec'd behind a `RemoteContentService` protocol so it can be no-opped at launch.
- **Push:** local notifications only at launch (scheduled client-side for 10 days ahead, rescheduled on significant time/location/method change). APNs reserved for future content pushes.
- **Analytics:** privacy-respecting, opt-in only (e.g., TelemetryDeck): feature usage counts, no location, no identifiers. A religious app must be beyond reproach on privacy.

---

## 8. Technical Stack & Project Structure

- **SwiftUI** (iOS 26 SDK), **SwiftData** for persistence, **Swift Charts** for stats, **ARKit/RealityKit** for qibla AR, **CoreLocation + CoreMotion** for compass, **WidgetKit + ActivityKit** for surfaces, **UserNotifications** for reminders, **Core Haptics**, **StoreKit 2** (optional tip jar — never paywall worship features), **CloudKit** sync.
- **Architecture:** MV + lightweight coordinators. `@Observable` view models, protocol-based services, dependency injection via environment. No third-party UI frameworks. Zero SPM dependencies preferred (Lottie optional for onboarding illustrations).
- **Targets:** `Mihrab` (app), `MihrabWidgets` (extension), `MihrabWatch` (watch app), `MihrabIntents`, `MihrabCore` (shared SPM package: models, API, design tokens, haptics, formatting).

```
Mihrab/
├── App/                # entry, tab root, deep-link router
├── Core/               # DesignTokens, Haptics, Formatters, Extensions
├── Data/               # DTOs, APIClient, Repositories, SwiftData models, Bundled JSON
├── Features/
│   ├── Onboarding/
│   ├── Today/
│   ├── Times/
│   ├── Qibla/          # CompassView, QiblaARView, HeadingManager
│   ├── Ramadan/
│   ├── Deen/           # Hadith, Esma, ReligiousDays
│   ├── Dhikr/
│   ├── Mosques/
│   └── Settings/
├── Resources/          # Assets, Fonts (Amiri), Audio (adhans), Lottie
└── Tests/              # Unit (qibla math, time math, repository), Snapshot (key screens)
```

**Critical correctness requirements:**
- Qibla bearing: great-circle initial bearing formula, unit-tested against known coordinates (Istanbul ≈ 152°, NYC ≈ 58°, Jakarta ≈ 295°).
- Prayer-time math: trust Aladhan, but verify ordering (Fajr < Sunrise < Dhuhr < Asr < Maghrib < Isha) and handle post-midnight Isha edge cases.
- Countdowns driven by `TimelineView(.periodic(every: 1))` or a single shared `Clock` publisher — never per-view timers.
- All dates via `Calendar(identifier: .islamicUmmAlQura)` for display; Aladhan Hijri fields for authoritative dates.

---

## 9. Animation Cookbook (exact recipes)

| # | Animation | Recipe |
|---|---|---|
| 1 | Countdown tick | `TimelineView` + `.contentTransition(.numericText(countsDown: true))` on digits |
| 2 | Card entrance | opacity 0→1, offset y 24→0, scale 0.97→1, `.spring(0.5, 0.85)`, stagger 40ms |
| 3 | Compass dial | heading → low-pass α=0.15 → `.animation(.spring(0.35, 0.75), value:)` shortest-path degrees |
| 4 | Qibla lock-on | glow via `.shadow(color: .mint, radius: animated 0→24)`, Kaaba scale 1→1.25 spring, 12-particle brass burst (Canvas + timeline), success haptic |
| 5 | Dhikr tap | orb scale 0.94 (response 0.12) → release spring 0.28/0.55; ripple: expanding stroked circle, opacity 0.6→0, 500ms |
| 6 | Set complete | odometer digit roll (`.numericText`), orb brass flash 300ms, 20-spark burst, triple-pulse haptic |
| 7 | Tab switch | iOS 26 glass tab morph (native) + content crossfade 200ms |
| 8 | Sheet present | `.presentationDetents` + glass background + content stagger-in |
| 9 | Ramadan theme shift | 600ms crossfade of all token-driven colors (drive via single `Theme` observable) |
| 10 | Aurora background | two radial gradients, offset animated on 24s/31s loops (out-of-phase), `.drawingGroup()` |
| 11 | Sun arc scrub | drag gesture → angle → interpolate marker positions along arc path (`Path.trim`) |
| 12 | Crescent fill (Ramadan) | `MoonPhaseShape` mask animated with `.spring(0.8, 0.9)` |
| 13 | Hadith share render | `ImageRenderer` of a dedicated `HadithShareCard` view @2x |
| 14 | Bell toggle | bell SF Symbol rotate ±15° twice (keyframe) + clapper swap to `bell.slash` crossfade |
| 15 | Onboarding Kaaba draw | `Path.trimmedPath(from:to:)` 0→1 over 1.2s, `.easeInOut`, then glow fade-in |

Every animation must have a **Reduce Motion** variant (crossfade or instant).

---

## 10. Notifications & Reminders

- **Prayer alerts:** scheduled 10 days ahead (`UNCalendarNotificationTrigger`), per-prayer toggle, options: at time / 5 / 10 / 15 min before; sound = chosen bundled adhan (or `.default`); Fajr gets its own adhan option.
- **Time-sensitive:** prayer alerts request `.timeSensitive` interruption level (justified — core value prop).
- **Daily hadith:** user-picked time (default 09:00), rich notification with quote excerpt.
- **Religious days:** day-before 18:00 + morning-of 09:00.
- **Ramadan:** suhoor-ends-in-30-min alert, iftar-at-maghrib alert, auto-enabled in season.
- **Dhikr goal:** evening nudge if daily goal unmet (opt-in).
- **Jumu'ah:** Friday morning reminder with local Dhuhr time.
- Reschedule triggers: app launch, location change (significant), method/madhab change, time-zone change, toggle change. Cap: iOS 64-pending limit — prioritize prayer alerts.

---

## 11. Localization

- Ship **Türkçe, English, العربية** at launch; strings via String Catalogs; Arabic gets full **RTL layout mirroring** (verify every custom layout, especially compass readouts and the timeline rail).
- Arabic religious text is never translated away — always show Arabic + selected-language translation.
- Date formats: locale-correct Gregorian + Hijri in all three languages.

---

## 12. Accessibility

- Full **Dynamic Type** (countdown scales to AX3, then clamps with layout adaptation).
- **VoiceOver:** every glass card is a single coherent element with a meaningful label ("Isha in 2 hours 14 minutes. Next of 6 daily prayers."); compass announces bearing changes politely (throttled); dhikr count announced on demand, not per tap.
- **Reduce Motion** variants for all §9 animations; **Reduce Transparency** → glass swaps to solid `mihrab.moss`.
- Contrast: all text ≥ 4.5:1 against its effective background (test glass over brightest aurora state).
- Hit targets ≥ 44×44; the dhikr tap surface is the whole screen by design.

---

## 13. Privacy & Permissions

- Location: WhenInUse only; used on-device for times/qibla/mosques; never sent anywhere except anonymous coordinates to Aladhan (documented in privacy label).
- Camera: AR qibla only; nothing recorded.
- Notifications, Motion (compass) — standard prompts with pre-permission glass explainer cards (never show a raw system prompt without context).
- App Tracking Transparency: not needed — no tracking, no ads, ever. Say so proudly in Settings → About.

---

## 14. Build Order (milestones — complete in this sequence)

1. **Foundation:** project + targets + `MihrabCore` package, design tokens, aurora background, glass modifiers, fonts, haptics engine.
2. **Data layer:** Aladhan client, repositories, SwiftData models, bundled JSON (hadiths, esma, adhkar, religious days), qibla math + unit tests.
3. **Times tab** (full pager, rows, notifications toggles, monthly view).
4. **Today tab** (hero countdown, prayer strip, cards).
5. **Qibla compass** → then **AR qibla**.
6. **Zikirmatik** (counter, presets, stats).
7. **Deen tab** (hadith + share renderer, Esmaül Hüsna, religious days).
8. **Mosques** (map + sheet).
9. **Ramadan hub** + seasonal theming.
10. **Notifications engine** (scheduling + rescheduling rules).
11. **Widgets + Live Activity + Dynamic Island + StandBy + Control Center + App Intents**, then **Watch app**.
12. **Onboarding** + Settings + localization pass (TR/EN/AR + RTL).
13. **Polish sprint:** every §9 animation, Reduce Motion/Transparency variants, VoiceOver pass, snapshot tests, performance audit (60fps on iPhone 12), app icon + screenshots.

---

## 15. Acceptance Criteria (Definition of Done)

- [ ] All 5 tabs + 11 surfaces (§5) implemented and functional on iOS 26.
- [ ] Prayer times match Diyanet (TR) / chosen method within 1 minute for 10 sampled cities.
- [ ] Qibla bearing within ±1° of reference for 10 sampled cities; compass lock-on fires at ±3°.
- [ ] AR qibla tracks ≥ 30fps on iPhone 12+; graceful fallback without camera permission.
- [ ] All §9 animations present, spring-based, with Reduce Motion variants; 60fps sustained.
- [ ] Liquid Glass applied per §2.2 — no flat-material cards anywhere.
- [ ] Ramadan theme auto-shifts and all Ramadan features work with mocked dates.
- [ ] Widgets/Live Activity update at prayer boundaries; deep links land correctly.
- [ ] 365 hadiths bundled; share image renders correctly in all 3 languages.
- [ ] Dhikr counts survive force-quit mid-session; CloudKit syncs across two devices.
- [ ] Full TR/EN/AR localization; Arabic UI is fully mirrored RTL.
- [ ] VoiceOver completes: set notification, find qibla, log 33 dhikr — unassisted.
- [ ] Zero third-party trackers; privacy label accurate.
- [ ] App Store screenshots + preview video produced from the real app.

---

## 16. The One-Shot Prompt (condensed, copy-pasteable)

> Build **Mihrab**, a premium Islamic companion app for iOS 26 (SwiftUI + SwiftData), targeting an Apple Design Award. Design language: **Liquid Glass** (iOS 26 glass effects, floating glass tab bar, glass cards over a slowly drifting aurora gradient) on a **deep botanical dark-green palette** (background `#07120D`, surfaces `#0D2418`/`#143322`, emerald accent `#1FA96B`, mint `#7FE0B2`, brass `#C9A24B` for sacred elements), SF Pro Rounded numerals, New York serif for hadith translations, Amiri for Arabic. Five tabs: **Today** (hero next-prayer countdown with breathing glass ring, prayer strip, daily hadith card, quick actions), **Times** (day pager, per-prayer notification bells, sun-arc scrubber, monthly table), **Qibla** (glass compass with orbiting Kaaba glyph, ±3° lock-on glow + haptic + particle burst, plus **ARKit AR mode** with floating brass arrow, bobbing Kaaba model, distance billboard), **Deen** (daily hadith with share-image renderer, Esmaül Hüsna 99-names grid with recite integration, religious days list), **Dhikr** (full-screen tap counter with deforming glass orb, ripple, progress ring, 33/99/100 sets, presets, stats charts). Plus: **nearby mosques** (MapKit POI search, glass bottom sheet, directions), **Ramadan hub** (auto seasonal violet/gold theme, iftar/suhoor countdowns, crescent-fill day counter, khatam tracker, Eid countdown), full **widgets** (Lock Screen, Home, Live Activity + Dynamic Island, StandBy, Control Center, App Intents, Apple Watch companion), **notifications** (per-prayer adhan alerts scheduled 10 days ahead, daily hadith, religious days, Ramadan alerts), **CloudKit sync**, offline-first with bundled JSON (365 hadiths, 99 names, adhkar, religious days) + **Aladhan API** for prayer times/Hijri/qibla (Diyanet method option for Türkiye), TR/EN/AR localization with full RTL, complete accessibility (VoiceOver, Dynamic Type, Reduce Motion variants of every spring animation), and zero tracking. Follow the full spec: milestones in §14 order, animation recipes in §9, acceptance criteria in §15.

---

*References: UI patterns researched via Mobbin — [Oura](https://mobbin.com/screens/f2dfd1b5-f040-4ff4-a241-abdf48b5f7ae) · [WHOOP](https://mobbin.com/screens/4d288d6d-281a-4980-b16d-87c1da58ea14) · [Lumy compass](https://mobbin.com/screens/55115cb5-0146-4a11-8d40-78b5ad136c02) · [Tide Guide compass](https://mobbin.com/screens/792ecf30-b4d5-41fd-80f7-ddd7154392fd) · [Sunlitt](https://mobbin.com/screens/38d88fa6-3308-475c-aa37-e0db8f9f99da) · [Breathwrk counter](https://mobbin.com/screens/22a34ba5-9da8-41c2-800c-d1376abc076d) · [(Not Boring) Timer](https://mobbin.com/screens/46b41eb2-d25a-45f4-adaf-3c61d61cc3c9) · [Tripadvisor map](https://mobbin.com/screens/b6e39606-ab24-499b-9333-314b29f4a8f3) · [Starbucks map](https://mobbin.com/screens/6137bdfc-9652-483d-b11e-15f10d0edcb2) · [Waking Up quote](https://mobbin.com/screens/17f552f8-7a09-4137-a21d-463234c96f4b) · [5 Minute Journal](https://mobbin.com/screens/7fb26723-6a58-4537-b7f4-48f38e398e85) · [lululemon onboarding](https://mobbin.com/flows/68559489-94dd-47cd-b157-c17687bef70f) · [Turo onboarding](https://mobbin.com/flows/468fe59a-69ba-4e7f-a8fb-8c0ddc48bf71)*
