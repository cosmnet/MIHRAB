# Mihrab — App Store vitrin paketi (ortak brief)

Üç ajan paralel çalışıyor. Bu dosya ortak gerçekleri taşır.

## Uygulama nedir

Mihrab: iOS 26 için İslami günlük yaşam uygulaması. Namaz vakitleri (cihaz üstü
hesaplama, internetsiz çalışır), kıble pusulası + AR, Kur'an okuyucu (tam Arapça
metin + Türkçe meal, çevrimdışı), zikirmatik (gerçek tespih fiziğiyle), Esmaül
Hüsna, kaza namazı takibi, zekât hesaplayıcı, dinî takvim, hatim takibi,
widget'lar, Live Activity, Apple Watch uygulaması.

**Ayırt edici üç şey:**
1. **Reklam yok, veri toplama yok.** Kod tabanında tek bir analitik/reklam SDK'sı
   yok. Rakiplerin en büyük şikâyeti bu (pazar lideri Ezan Vakti Pro'nun
   Şikayetvar marka puanı 0/100 ve şikayetler ibadet uygulamasındaki kumar ve
   müstehcen reklamlar üzerine).
2. **AlarmKit ile gerçek ezan.** iOS 26'nın alarm API'si sayesinde ezan Sessiz
   modda ve Odak açıkken de, tam uzunlukta çalıyor. Rakiplerde ezan ya hiç
   çalmıyor ya 30 saniyede kesiliyor.
3. **İnternetsiz çalışır.** Vakitler cihazda hesaplanıyor; Kur'an ve meal pakete
   gömülü.

**Ücretsiz kalanlar:** namaz vakitleri, kıble, ezan bildirimleri, Kur'an ve meal,
99 isim, zikirmatik, kaza takibi, zekât, takvim, hatim. **Mihrab Plus** yalnızca
güzelleştirici katman: zengin widget'lar, temalar, özel ezan sesi, sınırsız zikir
geçmişi, Esma koleksiyonları, çoklu şehir, iCloud senkronu, AR kıble.

## Dil gerçeği — buna uy

Uygulama arayüzü **yalnızca üç dilde** var: **Türkçe, İngilizce, Arapça**.
Endonezce, Fransızca, Malayca, Urduca ve Almanca kullanıcılar uygulamayı
**İngilizce** görür. Mağaza metni ve ekran görüntüsü başlıkları o dillerde
olabilir (Apple bunu destekler ve yaygındır) ama **uygulamanın o dilde olduğunu
ima eden bir cümle kurulmayacak.** "Endonezce destekli" gibi bir iddia
Guideline 2.3.1 ihlalidir.

## Hedef diller ve mağazalar

| Kod | Dil | Mağaza | Arayüz dili |
|---|---|---|---|
| tr | Türkçe | TR | **Türkçe** |
| en-US | İngilizce | US + global | **İngilizce** |
| ar | Arapça | SA, EG, AE | **Arapça** |
| id | Endonezce | ID | İngilizce |
| fr-FR | Fransızca | FR | İngilizce |
| ms | Malayca | MY | İngilizce |
| en-GB | İngilizce (PK/UK) | GB, PK | İngilizce |
| de-DE | Almanca | DE (TR diasporası) | İngilizce |

## Anahtar kelime verisi

`/Users/cosm/.cursor/projects/Users-cosm-Projects-apple-ads-popularity/canvases/namaz-kible-keywordler.canvas.tsx`
— Apple Ads search-term-popularity, 9–15 Ağustos 2026 haftası, dil başına
gerçek popülerlik puanlı ilk 10 terim. **Bu dosyayı oku ve esas al.**

## Metin kalitesi — en önemli kural

Metinler **yapay zekâ çıktısı gibi okunmayacak.** Somut olarak:
- Üç maddeli paralel yapı, "…ile … ve …" üçlemesi, "sadece bir X değil, aynı
  zamanda bir Y" kalıbı, "deneyimini keşfedin", "yolculuğunuza başlayın" gibi
  pazarlama klişeleri **yasak**.
- Emoji ve süs karakteri kullanma. Ünlem işaretini israf etme.
- Her dilde **o dili konuşan biri gibi** yaz — Türkçeden çeviri kokmasın.
  Endonezce metin Endonezyalı bir müslümanın kullandığı kelimelerle yazılsın
  (sholat, kiblat, adzan), Malayca Malezyalının (solat, kiblat, azan).
- Kısa cümle. Sıfat yığma. Vaat etme, ne olduğunu söyle.
- Dinî konuda abartılı fazilet iddiası veya rivayet uydurma **kesinlikle yok**.

## Karakter sınırları (App Store Connect)

| Alan | Sınır | Not |
|---|---|---|
| App Name | 30 | Türkçe'de `ı ş ğ ü ö ç` çift bayt, karakter olarak sayılır |
| Subtitle | 30 | |
| Keywords | 100 | Virgülden sonra **boşluk yok**; başlıkta/alt başlıkta geçen kelimeyi tekrar yazma |
| Promotional Text | 170 | Sürüm göndermeden değiştirilebilir |
| Description | 4000 | İlk 2-3 satır kritik, gerisi "daha fazla"nın arkasında |
