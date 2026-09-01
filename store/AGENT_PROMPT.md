# Revak — devir promptu

Aşağıdaki üç blok birbirinden bağımsız. Ajana hepsini birden verebilirsin ya da
tek tek. Her blok kendi başına anlaşılır; hiçbiri bu sohbetin bilgisine ihtiyaç
duymuyor.

---

## BLOK 1 — App Store Connect'e 19 yeni dili gir

```
Revak adlı iOS uygulamasının App Store Connect kaydını dolduracaksın.
Apple ID: 6805912172 · Bundle ID: com.caferkarakaya.mihrab
Birincil dil Türkçe. Sürüm 1.0, "Prepare for Submission" durumunda.

METİNLERİN KAYNAĞI — hiçbir metni kendin yazma, uydurma, çevirme:

Depo: /Users/cosm/Desktop/MIHRAB
Metinler: /Users/cosm/Desktop/MIHRAB/store/metadata/<locale>.md

Bu makinede ~/Projects/mihrab diye boş bir git klasörü de var; o DEĞİL, orada
hiçbir şey yok. Doğru yol yukarıdaki.

Dosya sistemine erişemiyorsan aynı dosyalar herkese açık depoda duruyor:
  https://raw.githubusercontent.com/cosmnet/MIHRAB/main/store/metadata/<locale>.md
Örnek: .../store/metadata/ur-PK.md · .../store/metadata/zh-Hans.md

Her dosyada
## App Name, ## Subtitle, ## Keywords, ## Promotional Text, ## Description
başlıkları ve her birinin sonunda "← (n/limit)" işareti var. Bu işareti ASC'ye
YAZMA, sadece metnin kendisini kopyala.

ŞU ANDA ASC'DE OLAN 8 DİL (dokunma, hepsi girili ve doğru):
tr, ar, en-US, en-GB, fr-FR, de-DE, id, ms

EKLEYECEĞİN 19 DİL:
es-ES, es-MX, pt-BR, pt-PT, it, nl-NL, ru, uk, sv, el, hr,
ur-PK, bn-BD, hi, ml-IN, ta-IN, th, zh-Hans
(hr dosyası Hırvatça yazılmış; ASC'de "Croatian" olarak gir.)

HER DİL İÇİN ÜÇ YERE GİRİŞ GEREKİYOR:

1) Sürüm sayfası — Distribution ▸ iOS App 1.0
   Sağ üstteki dil açılırını aç, "Not Localized" listesinden dili seç (bu onu
   ekler ve o dile geçer). Sonra doldur:
     · Promotional Text  ← dosyadaki ## Promotional Text
     · Description       ← dosyadaki ## Description (satır sonları korunacak)
     · Keywords          ← dosyadaki ## Keywords (virgülle, boşluk YOK)
     · Support URL       ← https://cosmnet.github.io/MIHRAB/support.html
     · Marketing URL     ← https://cosmnet.github.io/MIHRAB/
     · Copyright         ← 2026 Cafer Karakaya
   Save. Kaydettiğini doğrula: Save düğmesi "Saved" olup grileşmeli.

2) App Information ▸ Localizable Information
   Aynı dile geç, doldur:
     · Name     ← dosyadaki ## App Name
     · Subtitle ← dosyadaki ## Subtitle
   Save.

3) App Privacy ▸ Privacy Policy ▸ Edit
   Diyalogun içindeki dil açılırından o dile geç ve URL'yi gir:
     · Türkçe dışındaki HER dil → https://cosmnet.github.io/MIHRAB/privacy-en.html
   Bütün dilleri diyalogda tek tek gezip doldurduktan sonra bir kez Save.
   (Türkçe zaten privacy.html'e bakıyor, onu değiştirme.)

DİKKAT:
· Karakter limitleri: Name 30, Subtitle 30, Keywords 100, Promotional 170,
  Description 4000. Dosyalardaki metinler limit içinde; ASC yine de sayacı
  gösterir, kırmızıya düşerse metni kısaltma — bana haber ver.
· ASC bazen kaydı sessizce yutuyor. Her Save'den sonra sayfayı yenileyip
  değerin gerçekten durduğunu gözle doğrula.
· "Add for Review" ya da "Submit" düğmesine BASMA. Sadece kaydet.
· Primary Language'i değiştirme, Türkçe kalacak.

BİTİRDİĞİNDE: hangi dilin üç bölümünün de girildiğini tablo hâlinde bildir.
```

---

## BLOK 2 — Ekran görüntüleri

```
Revak adlı iOS 26 uygulaması için App Store ekran görüntüleri üreteceksin.
Depo: /Users/cosm/Desktop/MIHRAB · Şema: Mihrab · Ürün: Revak.app

ÖNEMLİ: Uygulamanın adı Revak. Çektiğin karede eski "Mihrab" adını ya da eski
tek kemerli yeşil-pirinç logoyu görürsen kare bayattır — uygulamayı yeniden
derleyip tekrar çek. Yeni amblem turkuaz-turuncu sekiz köşeli bir rozet,
içinde hilal ve yıldız.

1) Simülatörde iPhone 17 Pro Max (1290×2796) ile derle ve çalıştır.
2) Şu altı ekranı sırayla yakala. Her karede vakit verisi gerçek olmalı,
   boş/iskelet hâlde yakalama:
     a. Bugün — sonraki vakit, geri sayım halkası, günün hadisi
     b. Kilit ekranı — Live Activity ve widget görünürken
     c. Kıble pusulası — kilitlenmiş (hizalanmış) durumda
     d. Şeffaflık paneli — bir vakte dokununca açılan "bu vakit nereden geliyor"
     e. Zikirmatik — sayaç ve 99 isim
     f. Kaza / zekât / dinî takvim
3) Durum çubuğu temiz olacak: saat 9:41, tam pil, tam sinyal. Sol üstte
   "◀ başka uygulama" geri dönüş etiketi GÖRÜNMEYECEK — görünürse simülatörü
   yeniden başlat ve uygulamayı doğrudan aç.
4) Hesaplama yöntemi Diyanet olacak (MWL değil). Ayarlar ▸ Namaz vakitleri'nden
   doğrula.
5) Çerçeveleme: /Scripts/screenshots/ altında compose.swift, theme.json ve
   build.sh var. Alt yazılar /store/metadata/<locale>.md dosyalarındaki
   "## Ekran görüntüsü başlıkları" bölümünden otomatik okunuyor — kendin yazma.
   build.sh'ı çalıştırıp tam 1290×2796 çıktı üret.
6) Önce tr, en-US ve ar için üret; sonra aynı ham karelerden diğer 24 dilin
   alt yazılarıyla türet.

Çıktıları /store/screenshots/<locale>/ altına 01..06 sırasıyla koy.
```

---

## BLOK 3 — Kalan uygulama içi çeviriler

```
Revak'ın arayüzü şu an İngilizce, Türkçe, Arapça ve Endonezce konuşuyor.
Yeni dil eklemek tek dosyalık bir iş; altyapı hazır. Ekleyeceğin diller
(nüfusa göre sıralı): ms, ur, bn, hi, fr, de, ru, es, nl, it, ml.

NASIL ÇALIŞIYOR
· Arayüz metinleri kodda L10n.string(en:tr:ar:) çağrılarında duruyor —
  1300 çağrı, 21 dosya. Bu çağrılara DOKUNMA.
· en/tr/ar dışındaki her dil Mihrab/Core/Shared/Localization/L10nCatalog.swift
  üzerinden okunuyor ve anahtar İngilizce metnin kendisi.
· Örnek tablo: Mihrab/Core/Shared/Localization/L10nTableID.swift — sekmeyle
  ayrılmış tek bir çok satırlı metin bloğu, satır başına "İngilizce⇥çeviri".

BİR DİL EKLEMEK
1) L10n.swift'te Language enum'una case ekle (ör. case malay = "ms") ve
   localeIdentifier switch'ine karşılığını yaz (ör. "ms_MY").
2) L10nCatalog.swift'teki rawTable switch'ine satır ekle.
3) L10nTableXX.swift dosyasını üret. Anahtarların kaynağı: aşağıdaki komut
   İngilizce dizelerin tamamını sırayla döker.
   ELLE "İngilizce⇥çeviri" satırı YAZMA — tek harflik kayma aramayı sessizce
   boşa düşürür. Anahtarı komuttan al, yanına çeviriyi ekle.
4) Sağdan sola yazılan bir dil eklersen (ur) L10n.isRightToLeft'e ekle.
5) Şu dört çoğul iskeletini de tabloya ekle (bunlar çağrı yerlerinden
   çıkarılamıyor, çünkü sayı çalışma anında metne giriyor):
     %d prayers left today / %d day streak / %d missed prayers / %d days fasted

ANAHTARLARI DÖKME KOMUTU (depo kökü: /Users/cosm/Desktop/MIHRAB):
  python3 - <<'EOF'
  import re, glob, collections, os
  pat = re.compile(r'string\(\s*en:\s*"((?:[^"\\]|\\.)*)"\s*,\s*tr:', re.S)
  seen = collections.OrderedDict()
  for p in sorted(glob.glob('**/*.swift', recursive=True)):
      s = open(p, encoding='utf-8').read()
      for m in pat.finditer(s):
          k = m.group(1)
          if '\\(' not in k: seen.setdefault(k, p)
  for k in seen: print(k)
  EOF

ÜSLUP
Bu bir ibadet uygulaması. Dinî terimleri o dilin Müslüman topluluğunun
gerçekten kullandığı biçimde yaz — Endonezce tabloda "sholat", "kiblat",
"dzikir", "qadha" tercih edildi; makine çevirisinin "doa"ya kaçtığı yerlerde
"dzikir" doğru olandır. Vakit adlarını yerelleştir (Fajr→Subuh, Dhuhr→Zuhur).
Marka adı her dilde "Revak" kalır, Arapçada "رواق".

DOĞRULAMA
  xcodegen generate
  xcodebuild -project Mihrab.xcodeproj -scheme Mihrab \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
317 test geçmeli. Sonra simülatörü o dile alıp Bugün, Vakitler, Kıble,
Zikirmatik, Ayarlar ve paywall ekranlarını gözle kontrol et: taşan buton
etiketi ya da İngilizce kalmış cümle arıyorsun.
```
