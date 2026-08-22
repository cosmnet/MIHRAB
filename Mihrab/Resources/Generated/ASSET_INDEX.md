# Mihrab generated assets

**Status:** Wiro GPT Image 1.5 transparent ornaments (10 files, 2026-08-21) plus GPT Image 2 opaque drawing backgrounds (6 files, 2026-08-21).

## Ornaments (`Generated/`)

Wiro GPT Image 1.5 transparent PNGs. All 10 files are RGBA with alpha (`sips -g hasAlpha` = yes).

Folder: `Mihrab/Resources/Generated/` (XcodeGen picks up files under `Mihrab/` automatically). The eight imagesets that already existed also received copies.

| Field | Value |
| --- | --- |
| Model | `openai/gpt-image-1-5` (GPT Image 1.5) |
| Transparency | `background=transparent`, `outputFormat=png`, `size=1:1`, `quality=high`, `samples=1` |
| Result | 10/10 completed with alpha |

| File | Size | Pixels | Color | Transparent | Subject | SwiftUI usage |
| --- | ---: | --- | --- | ---: | --- | --- |
| `kaaba-glass.png` | 1.7 MB | 1024×1024 | RGBA | 59% | Glass Kaaba cube, brass band, 3/4 view | Qibla hero / share card: `Image("kaaba-glass")` |
| `compass-rose.png` | 1.8 MB | 1024×1024 | RGBA | 64% | Brass + glass 8-point rose, no text | Qibla compass overlay |
| `crescent-brass.png` | 1.6 MB | 1024×1024 | RGBA | 81% | Brass crescent + star, isolated | Tab / empty-state ornament |
| `prayer-beads.png` | 1.5 MB | 1024×1024 | RGBA | 85% | Emerald glass tasbih, loose circle | Dhikr screen header |
| `mihrab-arch.png` | 1.6 MB | 1024×1024 | RGBA | 77% | Dark green arch, brass edge light | Today / onboarding frame |
| `lantern.png` | 1.4 MB | 1024×1024 | RGBA | 82% | Brass mosque lantern, emerald glow | Ramadan hub / night mood |
| `particle-spark.png` | 1.4 MB | 1024×1024 | RGBA | 97% | Small brass spark sprite | Particle / celebration overlay |
| `moon-phase.png` | 2.0 MB | 1024×1024 | RGBA | 67% | Crescent-fill moon | Ramadan day counter |
| `qibla-arrow.png` | 1.6 MB | 1024×1024 | RGBA | 81% | Clean brass AR arrow | Qibla AR / compass pointer |
| `esma-ornament.png` | 1.5 MB | 1024×1024 | RGBA | 65% | Subtle geometric tile ornament | Esma / 99 names ornament |

Absolute path: `/Users/cosm/Desktop/MIHRAB/Mihrab/Resources/Generated/`

Copied into existing `Assets.xcassets` imagesets: `kaaba-glass`, `compass-rose`, `crescent-brass`, `prayer-beads`, `mihrab-arch`, `lantern`, `particle-spark`, `moon-phase`.

Also in the catalog: `qibla-arrow`, `esma-ornament`.

## Drawing backgrounds (`Generated/Backgrounds/`)

Wiro GPT Image 2 full-bleed illustrations (not photographs). Opaque RGB PNGs for card/page fills. Catalog names match filenames so `Image("today-hero")` works.

| Field | Value |
| --- | --- |
| Model | `openai/gpt-image-2` (GPT Image 2) |
| Settings | `resolution=2k`, `ratio=3:4`, `quality=high`, `background=opaque`, `outputFormat=png`, `samples=1` |
| Result | 6/6 completed |

| File | Size | Pixels | Color | Subject | SwiftUI usage |
| --- | ---: | --- | --- | --- | --- |
| `today-hero.png` | 5.1 MB | 1536×2048 | RGB | Night garden + mihrab niche drawing | Countdown card: `Image("today-hero")` |
| `today-hadith.png` | 5.6 MB | 1536×2048 | RGB | Quiet paper / garden watercolor wash | Hadith card: `Image("today-hadith")` |
| `times-bg.png` | 5.0 MB | 1536×2048 | RGB | Night sky + faint sun/moon arc drawing | Times page: `Image("times-bg")` |
| `qibla-bg.png` | 5.0 MB | 1536×2048 | RGB | Dark garden + distant Kaaba silhouette | Qibla page: `Image("qibla-bg")` |
| `esma-bg.png` | 5.1 MB | 1536×2048 | RGB | Calm botanical wash | Esma page: `Image("esma-bg")` |
| `dhikr-bg.png` | 5.6 MB | 1536×2048 | RGB | Deep green abstract botanical (no beads) | Dhikr page: `Image("dhikr-bg")` |

Absolute path: `/Users/cosm/Desktop/MIHRAB/Mihrab/Resources/Generated/Backgrounds/`

Copied into new `Assets.xcassets` imagesets: `today-hero`, `today-hadith`, `times-bg`, `qibla-bg`, `esma-bg`, `dhikr-bg`.

## Suggested SwiftUI

```swift
Image("today-hero")
    .resizable()
    .scaledToFill()
    .clipped()
    .accessibilityHidden(true)
```

Ornaments: prefer `.renderingMode(.original)`, sit on `MihrabColor.abyss` / `.forest`, and keep particles (`particle-spark`) small with `.blendMode(.plusLighter)` on dark backgrounds.

Backgrounds: fill cards with `.scaledToFill()`; they are already dark enough for white text.
