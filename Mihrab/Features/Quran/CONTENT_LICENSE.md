# Qur'an content — provenance and licence

Everything the reader ships with is recorded here. **Nothing is bundled unless
its licence demonstrably permits redistribution inside a commercially
distributed app.** Where a licence could not be established, the layer ships
*empty* and the reader says so out loud rather than guessing.

---

## 1. Arabic text — BUNDLED ✅

| | |
|---|---|
| File | `Mihrab/Data/Bundled/quran-uthmani.json` |
| Work | Tanzil Qur'an Text (Uthmani, Version 1.1) |
| Copyright | Copyright © 2007–2026 Tanzil Project |
| Licence | **Creative Commons Attribution 3.0** |
| Source | <https://tanzil.net> — <https://tanzil.net/download/> |
| Retrieved | 23 August 2026 |

### Terms, verbatim

> - Permission is granted to copy and distribute verbatim copies of this text,
>   but CHANGING IT IS NOT ALLOWED.
> - This Quran text can be used in any website or application, provided that
>   its source (Tanzil Project) is clearly indicated, and a link is made to
>   tanzil.net to enable users to keep track of changes.
> - This copyright notice shall be included in all verbatim copies of the text,
>   and shall be reproduced appropriately in all files derived from or
>   containing substantial portion of this text.

### How Mihrab complies

1. **Verbatim.** The 6,236 ayahs were transferred character-for-character from
   Tanzil's `txt-2` distribution. Only the *container* changed (one line per
   ayah → one JSON string per sura, ayahs still separated by `U+000A`).
   No normalisation, no diacritic stripping, no orthographic "fixes" — the
   two shadda'd basmala variants in Sūrat at-Tīn (95) and al-Qadr (97) are
   preserved exactly as Tanzil has them.
   `QuranTests.testTextIsVerbatim` asserts the ayah count, the per-sura counts
   and that the copyright notice survives in the bundle.
2. **Notice carried.** Tanzil's full copyright block lives inside the JSON under
   `"notice"` and is displayed to the user in
   `QuranLicenceView` (reachable from the reader's "…" menu and from the
   Settings section). It is never stripped at build time.
3. **Attribution + link.** "Tanzil Project · tanzil.net" is shown with a live
   link. Commercial use is permitted by CC BY 3.0 §3 and is not restricted by
   Tanzil's terms, which restrict *modification*, not *sale*.
4. **Searching does not modify the text.** The normaliser in `QuranSearch`
   builds a throwaway index in memory; the stored ayah string is always the
   Tanzil one.

**Owner's standing obligation:** Tanzil issues corrections. Subscribe to
<https://tanzil.net/updates/> and re-run `Scripts/` (see below) when a new
text version lands; bump `"version"` in the JSON when you do.

---

## 2. Sura / juz / hizb / page / sajda metadata — BUNDLED ✅

| | |
|---|---|
| File | `Mihrab/Data/Bundled/quran-meta.json` |
| Source | Tanzil `quran-data.xml` (<https://tanzil.net/res/text/metadata/quran-data.xml>), `license="cc-by"` |

Contains: 114 suras (ayah count, Arabic name, Turkish name, English name,
transliteration, Meccan/Medinan, revelation order, ruku count), 30 juz starts,
240 hizb-quarters (= 60 hizb), 604 Madani-mushaf page starts, 15 sajda ayahs
flagged obligatory/recommended.

The Turkish sura names were written for this project (Fâtiha, Bakara,
Âl-i İmrân, …). Names of chapters are facts, not authorship — no third-party
text is reproduced.

---

## 3. Turkish meal (translation) — **NOT BUNDLED** ❌

No Turkish translation ships with the app. Reasoning:

- **Diyanet İşleri Başkanlığı meal — copyrighted.** Owned by the Presidency of
  Religious Affairs; no public redistribution licence exists. Not embeddable.
  (Explicitly ruled out by the project brief.)
- **Every Turkish translation Tanzil hosts is off-limits *for us*.** Tanzil's
  translations page carries a term the Arabic text does not:
  > "The translations provided at this page are for non-commercial purposes
  > only. If used otherwise, you need to obtain necessary permission from the
  > translator or the publisher."
  Mihrab is a commercially distributed app with a subscription, so this rules
  out `tr.diyanet`, `tr.vakfi`, `tr.yazir`, `tr.bulac`, `tr.ates`,
  `tr.yildirim`, `tr.golpinarli`, `tr.ozturk` as *sources*, regardless of the
  underlying work's own status.
- **Elmalılı Hamdi Yazır is the one realistic public-domain candidate — but not
  from a source we have.** Elmalılı died 27 May 1942; under Turkish
  FSEK the term is life + 70 years, so *Hak Dini Kur'an Dili* has been in the
  public domain in Türkiye since 1 January 2013. However:
  - the digital copies in circulation are overwhelmingly **sadeleştirilmiş**
    (modernised) editions, and a modernisation is a derivative work with its
    own fresh copyright held by the moderniser/publisher;
  - the files that are labelled "Elmalılı" in open datasets are almost always
    such a modernised edition, and none of them documents which edition it is.

  Shipping one of those would be shipping someone's copyrighted derivative
  under a public-domain label. **Not done.**

### What the owner must do to unlock the Turkish layer

Any one of these, in decreasing order of ease:

1. **Licence a meal directly.** Approach a publisher (Diyanet Yayınları, TDV,
   Işık/Nesil, Kaynak) for a redistribution licence for an app. Budget for a
   flat fee or per-install royalty. This is the normal path and gives the best
   text.
2. **Commission a scan-verified Elmalılı 1935–1938 first edition.** The
   original is genuinely public domain in Türkiye. Digitising the *original*
   (not a modernisation) and keeping the scan provenance on file makes the
   result safely shippable — and, in Ottoman-inflected Turkish, needs a
   readability decision.
3. **Commission a fresh translation.** Highest cost, cleanest rights, and the
   only route that makes the meal an asset rather than a licence liability.

Until then `TranslationPack.installed` is empty and the reader shows
`L10n.quranNoTranslationTitle` — an honest "no translation bundled yet" panel
with the Arabic still fully readable. **The app must never synthesise a
translation. Generated ayah text is forbidden.**

---

## 4. English translation — **NOT BUNDLED** ❌

Investigated and rejected *for now*:

- **Saheeh International** — copyright Al-Muntada al-Islami / Abul-Qasim.
  Widely redistributed in apps without a documented licence. No licence we can
  point at. Not embeddable.
- **Pickthall (1930)** — the author died 1936, so the work is public domain in
  every life + 70 country (since 1 Jan 2007) and in life + 50 countries. Its
  **US** status is the problem: first published in India/UK in 1930, it was
  restored/renewed into a US term that has not clearly expired, and the App
  Store distributes from the US. A US-safe edition would need a specific
  first-publication and renewal check we have not done.
- **Yusuf Ali (1934)** — public domain in Pakistan since 2002 (life + 50, died
  1953) and in the EU/UK, but a US pro-forma copyright is generally asserted
  through **2033**, and the widely circulated "revised" IFTA/Amana editions are
  separately copyrighted derivatives.
- Tanzil's copies of all of the above carry the same **non-commercial-only**
  term quoted in §3, so Tanzil cannot be the source even where the underlying
  work is free.

### What the owner must do

Either (a) have a lawyer confirm the US status of a specific **Pickthall 1930
first edition** and digitise from that edition — it is the most likely to clear
— or (b) licence Saheeh International, or (c) use
[Quran.com's Clear Quran (Talal Itani)](https://quran.com) only after obtaining
written permission. Do not copy from an app or a GitHub dump that does not name
its edition and licence.

---

## 5. Recitation audio — not in scope

Nothing audio ships. Roadmap item "Kur'an dinleyici + kari indirme" needs a
separate rights review; reciter recordings are performances with their own
neighbouring rights on top of any text licence.

---

## Regenerating the bundled data

```sh
# Arabic text (verbatim, Tanzil txt-2 = "text with aya numbers")
curl -L -o quran-uthmani.txt \
  "https://tanzil.net/pub/download/index.php?quranType=uthmani&outType=txt-2&agree=true"

# Metadata
curl -L -o quran-data.xml \
  "https://tanzil.net/res/text/metadata/quran-data.xml"
```

Then convert: one JSON string per sura, ayahs joined with `\n`, Tanzil's
copyright block copied into `"notice"` untouched, and
`"basmalaPrefixLengths"` computed as the number of **Unicode scalars** to skip
at the head of ayah 1 so the basmala can be drawn as an ornament without
mutating the stored text (0 for al-Fātiḥa, where the basmala *is* ayah 1, and 0
for at-Tawba, which has none).
