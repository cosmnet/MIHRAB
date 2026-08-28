# Revak — brand mark

*Revak* (Arabic **رواق**) is not a single arch. It is the run of arches on
columns that wraps a mosque courtyard — column, arch, column, arch — the
arcade of the Selimiye and the Süleymaniye. The mark had to be the **rhythm**,
not one opening.

## The chosen concept

**Three-bay arcade with a crowned central portal.**

Five directions were explored (renders in `concepts/`, generated with Wiro
`gpt-image-1-5`):

| | concept | verdict |
|---|---|---|
| A | three repeating arches on columns, single-line | right meaning, but equal arches read as a **comb** below ~40 px |
| B | twelve arches arranged radially into a ring | pretty, but reads as a generic flower — nothing says *arcade* |
| C | one tall ogee arch filled with an eight-fold girih lattice | strongest silhouette and unmistakably religious, but it is *one* arch, not a revak |
| D | arch whose negative space forms a crescent | failed — the crescent never resolved, and a crescent is a tired cue |
| E | sixteen intersecting arches forming a rosette medallion | beautiful at hero size, complete mush at icon size |

The mark is **A's meaning carried on C's silhouette**. Three bays give the
arcade its rhythm; the centre bay is both wider and far taller than its
neighbours, so as the mark shrinks the side bays fall away and it degrades into
a single crowned portal instead of into a comb. Inside the portal sits a
recessed **mihrab niche** — the app's first name, kept where a real one stands —
and an eight-fold rosette lamp hangs in it. An **alem** (finial) crowns the
centre; capitals sit on every column; one floor line closes the base.

Two decisions did most of the work:

- **Proportion, not curvature.** The first attempts were tall and narrow and
  read Gothic. Widening the design space to 160 × 128, lowering the arches and
  adding capitals is what makes it read Ottoman. The ogee constants never
  needed to change.
- **No six-fold symmetry anywhere.** Every ornament is eight-fold and built
  from outward-bulging arcs only. There is no polygon, no triangle and no pair
  of overlapping shapes in the mark, so no hexagram reading can emerge at any
  contrast or size.

## Canon

One design space — **160 wide × 128 tall** — shared by every rendering:

| | |
|---|---|
| columns | x = 8, 56, 104, 152 (three bays, centre 48 wide) |
| springline / floor | y = 62 / y = 122 |
| apex, side bays / centre | y = 36 / y = 12 |
| mihrab niche | x 64–96, springs at y 66, apex y 34 |
| lamp | centre (80, 80), petals swing between r 8 and r 13.5 |
| arch primitive | two-centred ogee, inflection at 13 % of span and 50 % of rise |

The arcade is authored as **one continuous stroke with no pen lifts** — up the
outer left column, over three bays, down the outer right column. That is what
lets the splash's `.trim(from:to:)` read as a single line drawing itself.

## Colours

| token | hex | use |
|---|---|---|
| brass | `#C9A24B` | the mark itself |
| emerald | `#1FA96B` | accent; the halo behind the mark |
| forest | `#14351F` | icon ground, top |
| abyss | `#07120D` | icon ground, floor; app background |

## Files

| file | what |
|---|---|
| `revak-mark.svg` | single colour, `currentColor` — inherits the surrounding text colour |
| `revak-mark-color.svg` | brass, with the opacity hierarchy baked in |
| `revak-icon-512.png` | reference render of the app icon |
| `concepts/*.png` | the five explored directions |

Both SVGs use `viewBox="0 0 512 512"` and hold the 160 × 128 canon inside one
`<g transform="translate(32 76.8) scale(2.8)">`, so the path data stays in
readable design units and can be edited by hand.

## Sizes

| size | use | note |
|---|---|---|
| 1024 px | App Store icon | `swift Scripts/generate_icon.swift <out.png> 1024` — opaque, no alpha |
| 150–172 pt | splash, welcome, paywall | `MihrabMark(height:)`, vector, takes the theme tint |
| 40–90 pt | list rows, share sheets | still fully legible; the lamp reduces to a warm dot |
| ≤ 24 pt | tab bars | the silhouette survives but the strokes go sub-pixel — use a **filled** treatment or the centre portal alone, not the full arcade |

**The mark is landscape**: width = 1.25 × height. Any container that pins its
width must allow for that.
