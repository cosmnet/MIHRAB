# Mihrab — UI brief (implement today)

Islamic prayer companion. **iOS 26**, **Turkish-first**. Palette: abyss `#07120D`, forest `#0D2418`, moss `#143322`, emerald `#1FA96B`, mint `#7FE0B2`, brass `#C9A24B`. Depth = shade + `.regular` material, not glow. No neon. **Never** opaque photo watermarks (`prayer-beads`, `kaaba-glass` as overlays). Arabic is companion type, not a cramped caption. Keep floating tab + `.scrollEdgeEffectStyle(.soft)`.

---

## 1. Home countdown / large timer

Refs: [Oura Home](https://mobbin.com/flows/2476e165-a409-4605-a1ca-7e450fb8e282) · [WHOOP strain](https://mobbin.com/screens/e6e8cbaf-b0b6-49b5-b9f2-d0389bddf623) · [Fitness Summary](https://mobbin.com/screens/2745a5a7-c443-46cf-80bb-a3e7b72ff8f7) · [Fitness “2”](https://mobbin.com/screens/527bed87-fe98-4e4d-b778-b635c9475df5) · [Lumy sunrise](https://mobbin.com/screens/e37f48a3-fb38-43c3-86b4-2ba29608408d) · [Sunlitt widgets](https://mobbin.com/screens/2debe50a-5d81-4bb8-84de-34d4ecdec1bb)

- Hero digits **56–64pt** SF Rounded Bold, **tabular**. Oura/WHOOP/Fitness sit a ~60pt number in a **flat** ring with **~16–24pt** air inside the stroke — not 68–72 jammed in a 190pt ring.
- Label **above** (small, tracked brass / all-caps). Units or “IN” smaller/lighter beside or under the duration (Lumy). Do not let the ring clip glyphs.
- Progress = **solid** emerald/mint stroke (Fitness Move). No outer glow, no photo under the timer. Canvas crescent at 7% opacity is OK; photos are not.
- **Never** `.contentTransition` on `Text(timerInterval:)` — overlapping glyphs. `CountdownText` stays a plain timer.

---

## 2. Horizontal chip / pill strip (no hard clip)

Refs: [Fitness+ chips](https://mobbin.com/screens/a43cc23e-a3f9-452f-a5a5-fa1ba322a6ad) · Moonly Topics (inset pills). **Anti-pattern:** Oura metric row, Sunlitt azimuth, Breathwrk Discover — labels shear at the bezel.

- Content inset **16pt**. Fade mask **24pt** leading + trailing (abyss/forest, not a black overlay). Peek ~12–16pt of the next pill.
- Pills **76×88**, gap **10**. Selected = solid emerald fill + white type; others moss, no neon stroke.
- Fade-to-background via existing `softHorizontalFade` — bump `edgeWidth` **16 → 24**.

```
.padding(.horizontal, 16)
.softHorizontalFade(edgeWidth: 24)
```

---

## 3. Timetable rows — large times that don’t wrap

Refs: [Lumy](https://mobbin.com/screens/e37f48a3-fb38-43c3-86b4-2ba29608408d) · [Sunlitt list](https://mobbin.com/screens/dcbf3787-310d-46c7-810c-376f7fdcbd3d) · [Tide Guide](https://mobbin.com/screens/778f52c1-eab2-4f8c-935a-656a87d5586a)

- One line for the clock. Trailing **fixed ~88pt** column, tabular rounded ~28pt. AM/DST (if any) **stacked beside** digits, never wrapping the time.
- `.lineLimit(1)` + `layoutPriority(1)` + `minimumScaleFactor(0.8)` on the time. Name column flexes; time column does not.
- **Same row height** for current / next / passed (~56–64pt content, ~12pt vertical pad). Current = brass weight/color, not a taller card. Next countdown + Arabic live on **line 2**.
- Thin inset dividers or equal moss cards; no extra emerald “hero” card for the live row.

```
.frame(width: 88, alignment: .trailing)
.lineLimit(1).minimumScaleFactor(0.8).layoutPriority(1)
```

---

## 4. Quote / dictionary / 99 names — big type, not boxes

Refs: [Waking Up Daily Quote](https://mobbin.com/screens/17f552f8-7a09-4137-a21d-463234c96f4b) · [5 Minute Journal](https://mobbin.com/screens/ecc4961e-6952-4c89-96b0-cf4e5f80eaeb)

- Kill 2-col `LazyVGrid` (118pt glass cells, Arabic 18pt). **Wide rows** or full-bleed: number as small brass caption; **Arabic ~28–36pt** Amiri; **Turkish meaning ~20–24pt** semibold; transliteration caption. Vertical pad **16–20pt**.
- Hadith: serif ~20–24pt, open leading, ~24–28pt inset — not a 3-line cramped box (`DailyHadithCard` is 18pt / `lineLimit(3)` today).
- Detail sheet can keep large centered stack; the **list** is a dictionary, not a mosaic.

---

## 5. Full-screen tap counters

Refs: [Breathwrk session](https://mobbin.com/flows/4c4acf6e-f704-4a19-b132-b2b12bb8d4ae) · [(Not Boring) Timer](https://mobbin.com/screens/6291170d-17ce-4ee0-862f-fcd6ea25fb7c) · [Tonal Rest](https://mobbin.com/screens/50541d0f-6dd5-4652-946c-0d3b655e616f) · Fitness “2”

- The **number is the UI** (~72–96pt on Dhikr). Chrome (phrase picker, target) at the edges. Hint caption fades; it never covers the digit.
- **Delete** `Image("prayer-beads")`. Background = aurora / botanical gradient only. Flat ring like Fitness, not a photo.
- Drop `.contentTransition(.numericText())` on the tap count (same overlap as the home timer).

---

## Do today (files)

| Where | Change |
|---|---|
| `HeroCountdownCard` | 56–64pt, ≥16pt pad inside ring; no `contentTransition`; no photo |
| `PrayerStrip` | 16 inset + **24pt** fade |
| `PrayerRow` | 88pt time column; uniform height; extras on line 2 |
| `EsmaGridView` | wide dictionary rows, not 2-col grid |
| `DhikrView` | remove beads; no numeric transition on count |
| `DailyHadithCard` | bigger type / more leading |

Tiny rule: `Text(timerInterval:range, countsDown:true)` — **no** `.contentTransition`.
