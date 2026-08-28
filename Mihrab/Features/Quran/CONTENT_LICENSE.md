# Qur'an content — provenance and licence

Everything the reader ships with is recorded here. **Nothing is bundled unless
its licence demonstrably permits redistribution inside a commercially
distributed app.** Where a licence could not be established, the layer ships
*empty* and the reader says so out loud rather than guessing.

---

## Shipped translation — Turkish

**`quran-trans-turkish-shaban.json`** — Şaban Britiş meali, Rowwad Tercüme
Merkezi denetiminde, [QuranEnc.com](https://quranenc.com) üzerinden, sürüm
**1.1.0**, 6236 ayet.

QuranEnc'in yayımladığı şart: *"Contents of the translations can be downloaded
and re-published"* — dört koşulla:

| Koşul | Revak'da durumu |
|---|---|
| İçerikte değişiklik, ekleme, çıkarma yok | Metin harfi harfine kopyalandı. Tek istisna: dört ayette cümle ortasında duran satır sonu boşluğa çevrildi, çünkü paket formatı ayetleri `U+000A` ile ayırıyor ve o karakter ayet sınırını kaydırırdı. Kelimeye dokunulmadı. |
| Yayıncı ve kaynak (QuranEnc.com) açıkça belirtilir | `attribution` alanında, okuyucunun lisans ekranında ve Ayarlar › Kaynaklar'da |
| Sürüm numarası taşınır | `license` alanında `1.1.0` |
| Uygunsuz reklam gösterilmez | Uygulamada **hiç** reklam yok |

`QuranTests` her surenin ayet sayısını Arapça mushaf verisiyle karşılaştırıyor:
bir ayet kayarsa test kırılır, çünkü yanlış ayetle eşleşmiş bir meal hiç
mealden kötüdür.

**Sürüm güncellemesi:** QuranEnc yeni sürüm yayımlarsa şart gereği güncellenmesi
beklenir. Paketi yeniden üretmek tek komut — `quranenc.com/api/v1/translation/sura/turkish_shaban/{1..114}`
çekilip aynı biçime dönüştürülür.

## 1. Arabic text — BUNDLED ✅

| | |
|---|---|
| File | `Revak/Data/Bundled/quran-uthmani.json` |
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

### How Revak complies

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
| File | `Revak/Data/Bundled/quran-meta.json` |
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

No Turkish translation ships with the app. Every candidate was checked against
one question: *may this text be redistributed inside a commercially distributed
app?* Findings, with sources, checked 27 August 2026:

### 3.1 Diyanet's *Kur'an Yolu Meali* — copyrighted, permission required

- Rights holder: **Diyanet İşleri Başkanlığı**, exercised through the
  **Dini Yayınlar Genel Müdürlüğü / Döner Sermaye Daire Başkanlığı**. The
  official sales site carries the notice
  *"…Dini Yayınlar Genel Müdürlüğü Döner Sermaye Daire Başkanlığı © 2018.
  Her hakkı saklıdır."* — <https://yayinsatis.diyanet.gov.tr/iletisim>
- Catalogue entry (publisher DİB, 2017, ISBN 9789751965370):
  <http://dijital.diyanet.gov.tr/e-kitap/kuran-yolu-meali/komisyon/kuran-kitapligi/429>
- No "kullanım şartları / telif" page was found on `kuran.diyanet.gov.tr`. With
  no published licence the default applies: **all rights reserved.**
  Embedding requires written permission. See §6.

### 3.2 Diyanet *does* run an open-source Qur'an project — but not for the text

- <https://acikkaynakkuran.diyanet.gov.tr/> · <https://github.com/diyanet-bid/Kuran>
- The **repository** is Apache-2.0. That covers the Next.js application code,
  **not the Qur'anic content**. The API's own terms forbid sharing the content,
  audio and datasets with third parties, and forbid bulk transfer or
  republication. The free tier is deliberately partial (first 30 pages
  page-wise, first 9 âyet per sûre, 1st cüz only).
- **Do not read "Apache-2.0" as permission to ship Diyanet's meal.** It is not.
- Contact for wider access: **community@diyanet.gov.tr**.

### 3.3 Tanzil translations — non-commercial only

Tanzil's translations page carries a term the Arabic text does not:

> "The translations provided at this page are for non-commercial purposes
> only. If used otherwise, you need to obtain necessary permission from the
> translator or the publisher."

Revak is a commercially distributed app with a subscription, so this rules out
`tr.diyanet`, `tr.vakfi`, `tr.yazir`, `tr.bulac`, `tr.ates`, `tr.yildirim`,
`tr.golpinarli`, `tr.ozturk` **as sources**, regardless of the underlying work's
own status.

### 3.4 Açık Kuran — CC BY-NC-SA 4.0, also out

<https://github.com/acik-kuran/acikkuran-api> hosts 25 Turkish meals under
**CC BY-NC-SA 4.0**. The NC clause blocks a paid app, and ShareAlike would
force the derivative to be licensed alike. Not usable.

### 3.5 Public-domain candidates — FSEK arithmetic

Turkish copyright (FSEK m.27) runs for the author's life + 70 years, counted
from **1 January of the year following the death** (m.29).

| Translator | Died | Free from | Status Aug 2026 |
|---|---|---|---|
| Elmalılı M. Hamdi Yazır | 27 May 1942 | 1 Jan 2013 | **Public domain** |
| Hasan Basri Çantay | 3 Dec 1964 | 1 Jan 2035 | Protected |
| Ömer Nasuhi Bilmen | 12 Oct 1971 | 1 Jan 2042 | Protected |

**Elmalılı is the only public-domain option — and the trap is real.** Under
FSEK m.6 a *sadeleştirme* (modernisation) is an **işlenme eser** with its own
fresh copyright term running from the *adapter's* death. Nearly every file
labelled "Elmalılı" in circulation is such a derivative, and none of them
documents which edition it is. Shipping one would be shipping someone's
copyrighted derivative under a public-domain label. **Not done.**

Only the **original 1935–1938 *Hak Dini Kur'an Dili*** is free. Two practical
wrinkles: the meal is embedded inside a tefsir, so extracting a verse-by-verse
meal is editorial work; and the Ottoman-inflected Turkish will read as archaic.
A scan of the original is at
<https://archive.org/details/hak-dini-kuran-dili-1-6-elmalili-muhammed-hamdi-yazir-yek-yay>
(note the Cumhurbaşkanlığı YEK *edition* may carry its own editorial rights —
work from the 1935–38 text, not the modern typesetting).

### 3.6 QuranEnc / Rowwad — **the one lead worth chasing first**

<https://quranenc.com/en/browse/turkish_rwwad> (King Fahd Complex / Rowwad
Translation Center, IslamHouse) hosts Turkish translations with keys
`turkish_rwwad`, `turkish_shaban`, `turkish_shahin`, downloadable as
PDF/CSV/XLS/XML and served by an API
(`GET /api/v1/translation/sura/{key}/{sura}`).

Its terms are reported to be permissive — redistribute freely provided the text
is **not modified**, the publisher and QuranEnc.com are credited, the version
number is cited, the edition is kept up to date, and it is not placed next to
inappropriate advertising. **⚠️ We could not open the terms page ourselves**
(`/en/policy` 404s and the policy text is not in the page we fetched), so this
is a lead, not a finding. **Before shipping it, retrieve the Terms and Policies
page and paste its wording into this file.** If it says what it is reported to
say, this is the fastest legal route to a Turkish meal in the app.

**Until any of this resolves,** `TranslationPack.installed` is empty and the
reader shows `L10n.quranNoTranslationTitle` — an honest "no translation bundled
yet" panel with the Arabic still fully readable. **The app must never synthesise
a translation. Generated ayah text is forbidden.**

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

---

## 6. Meal edinme yol haritası — what the owner actually has to do

Ordered by expected time-to-yes. Do 6.1 and 6.2 in parallel; they cost one
email each.

### 6.1 Verify QuranEnc's terms (½ hour, no permission needed if they check out)

1. Open <https://quranenc.com/> → "Terms and Policies" and save the page.
2. Paste the redistribution clause verbatim into §3.6 above.
3. If it permits unmodified redistribution with attribution: download
   `turkish_rwwad` (CSV or XML), convert with the pack format in §7, ship it.
   Record the **version number** — the terms require citing it and keeping the
   text current.

This is the only route that needs nobody's reply.

### 6.2 Ask Diyanet — two addresses, two different asks

**(a) The open-source Qur'an team — community@diyanet.gov.tr.** Faster, and
staffed by people who already work with developers. Ask for API terms that
permit embedding the meal in a distributed app.

**(b) The rights holder — diniyayinlar@diyanet.gov.tr.** The formal licence
request for *Kur'an Yolu Meali*.

- Dini Yayınlar Genel Müdürlüğü, Üniversiteler Mah. Dumlupınar Bul. No:147/A,
  06800 Çankaya/Ankara · 0 312 294 41 06 ·
  <https://diniyayinlar.diyanet.gov.tr/>
- Escalation if there is no reply in ~30 days: Hukuk Müşavirliği,
  hukuk@diyanet.gov.tr, 0 312 295 78 75; or file the same request through
  CİMER (<https://cimer.gov.tr>), which carries a statutory reply deadline.

#### Draft — to `diniyayinlar@diyanet.gov.tr` (copy `community@diyanet.gov.tr`)

> **Konu:** Kur'an Yolu Meali metninin bir mobil uygulamada kullanımı için
> telif izni talebi
>
> Diyanet İşleri Başkanlığı
> Dini Yayınlar Genel Müdürlüğü'ne
>
> Sayın Yetkili,
>
> iOS için geliştirdiğimiz **Revak** adlı namaz vakti ve Kur'an okuma
> uygulamasında, Başkanlığınızca yayımlanan **Kur'an Yolu Meali** metnini
> kullanabilmek için telif izni talep ediyoruz.
>
> Talebimizin kapsamı:
> - Kullanılacak metin: Kur'an Yolu Meali'nin Türkçe meal metni (tefsir
>   kısmı olmaksızın), 6.236 âyetin tamamı.
> - Kullanım biçimi: Metin, uygulamanın içine gömülü olarak, âyet âyet
>   Arapça metnin altında gösterilecektir. Ayrı bir dosya olarak dışa
>   aktarılamaz, kopyalanarak çoğaltılamaz ve üçüncü kişilere
>   dağıtılamaz.
> - Atıf: Her ekranda ve uygulamanın "Kaynaklar" bölümünde
>   "Kur'an Yolu Meali — Diyanet İşleri Başkanlığı" ibaresi ve
>   kuran.diyanet.gov.tr bağlantısı yer alacaktır.
> - Metne hiçbir müdahale yapılmayacak; sadeleştirme, kısaltma veya
>   düzenleme söz konusu değildir.
> - Dağıtım: Apple App Store. Uygulamanın bazı özellikleri ücretli abonelik
>   kapsamındadır; meal metninin ücretli ya da ücretsiz sunulması
>   konusunda Başkanlığınızın şartlarına uyacağız.
> - Güncelleme: Metinde yapılacak düzeltmeleri bildirmeniz hâlinde en kısa
>   sürede uygulamaya yansıtacağız.
>
> Talebimizin uygun görülmesi hâlinde, imzalanması gereken bir sözleşme,
> ödenmesi gereken bir telif bedeli veya uymamız gereken şartlar varsa
> tarafımıza bildirilmesini rica ederiz. Uygun görülmemesi hâlinde de
> bilgilendirilmemiz bizim için yeterlidir; izinsiz kullanım kesinlikle söz
> konusu değildir.
>
> Saygılarımızla,
> [Ad Soyad] — [Ünvan]
> [E-posta] · [Telefon]
> Uygulama: Revak — [App Store bağlantısı]

Keep the reply — the licence terms it contains have to be transcribed into §3.1
of this file **and** into the pack's own `license` and `attribution` fields
before anything ships.

### 6.3 Commission a scan-verified Elmalılı 1935–38 meal

Only if 6.1 and 6.2 both fail. Genuinely public domain, but needs: sourcing the
original edition (not a modernisation), extracting the meal from inside the
tefsir, and a readability decision about the Ottoman-inflected Turkish. Keep the
scan provenance on file — it is the only proof that what shipped is the free
text and not somebody's copyrighted sadeleştirme.

### 6.4 Commission a fresh translation

Highest cost, cleanest rights, and the only route that makes the meal an asset
rather than a licence liability.

---

## 7. Installing a pack once permission arrives

**It is one file.** Drop `quran-trans-<id>.json` into `Revak/Data/Bundled/`
and it appears in the reader. There is no id list to update: `TranslationPack`
discovers every `quran-trans-*.json` in the bundle at runtime.

```jsonc
{
  "id": "kuranyolu",                       // becomes the filename suffix
  "title": "Kur'an Yolu Meali",            // shown in the reader's picker
  "attribution": "Diyanet İşleri Başkanlığı",  // verbatim from the licence
  "license": "…",                          // the licence line, verbatim
  "language": "tr",                        // must match L10n.language raw value
  "suras": [ "…", "…" ]                    // 114 strings, ayahs joined with \n
}
```

The loader **refuses** a pack whose sura count is not 114 or whose ayah counts
do not match the mushaf metadata, because a one-line gap would pair every later
ayah with the wrong meal — worse than showing none.
`MihrabTests/ContentSourceTests.swift` (`QuranTranslationInstallTests`) pins
all of that, including that nothing is bundled today.
