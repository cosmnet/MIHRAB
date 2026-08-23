# Mihrab Plus — Fiyatlandırma Stratejisi

> Son güncelleme: 2026-08 · Sahibi: Agent C · İlgili kod: `Mihrab/Core/Subscription/`, `Mihrab/Features/Paywall/`

---

## 0. Tek cümlelik özet

**İbadetin kendisi ücretsiz, güzelleştiren katman ücretli.** 7 gün ücretsiz deneme →
yıllık plan varsayılan (**₺649,99 / $24,99**, aylığa göre **%58 tasarruf**), aylık
**₺129,99 / $4,99**, ömür boyu **₺1.299,99 / $59,99**.

---

## 1. Neden bu strateji? — Etik çerçeve

Namaz vakti, kıble yönü, ezan bildirimi ve günün ayeti/hadisi **hiçbir koşulda
ücretli olmayacak.** Üç gerekçe:

1. **Dinî/etik.** İbadetin vaktini öğrenmek bir ihtiyaçtır; onu ödeme duvarının
   arkasına koymak doğru değil.
2. **Pazar gerçeği.** Türkiye'de Diyanet'in kendi uygulaması bu işlevleri
   tamamen ücretsiz ve reklamsız veriyor. Bunları ücretlendirmek ticari olarak da
   yaşayamaz.
3. **App Store incelemesi.** Temel işlevi kilitleyip abonelik dayatan uygulamalar
   Guideline 3.1.2 / 4.2 tarafında sürtünme yaşıyor. Net bir ücretsiz katman
   incelemeyi kolaylaştırır.

Ayrıca paywall'da **karanlık desen yok**: kapatma düğmesi ilk kareden itibaren
görünür, geri sayım/sahte kıtlık yok, fiyat ve yenileme koşulu CTA'nın hemen
altında, "Şimdi değil" seçeneği utandırıcı bir dille yazılmadı, denemenin
bitişinden önce hatırlatma bildirimi gönderiliyor.

---

## 2. Pazar karşılaştırması (2025–2026 taraması)

| Uygulama | Aylık | Yıllık | Ömür boyu | Deneme | Ücretsiz / Premium ayrımı |
|---|---|---|---|---|---|
| **Muslim Pro** (Bitsmedia) | $12,99 | $34,99 (eski kademeler $29,99 / $49,99 hâlâ canlı) | Yok (eski "Remove Ads" $14,99 tek seferlik) | **7 gün** | Ücretsiz: vakitler, kıble, Kur'an, ezan. Premium: reklamsızlık, sınırsız kıraat/meal, Qalbox video |
| **Athan** (IslamicFinder) | $1,99 | $11,99 | Yok; "Remove Ads" $3,99 tek seferlik | Doğrulanamadı | Ücretsiz + reklam; premium = reklamsızlık + ek ezan/içerik |
| **Pillars** | $11,99 (TR ₺300,00) | $49,99 (TR ₺999,99) | Yok; Aile $87,90/yıl | Doğrulanamadı | Çekirdek **reklamsız ve ücretsiz**; premium = temalar, Apple Watch, destekçi kozmetikleri |
| **Quran Pro** (Quanticapps) | TR ₺399,99 | TR ₺2.999,99 | **TR ₺4.999,99** | Yıllıkta var | Premium: tam kıraat kütüphanesi, çevrimdışı, reklamsız |
| **Tarteel AI** | TR ₺599,99 | TR ₺7.999,99 | Yok | Var (süresi doğrulanamadı) | Premium: canlı ezber hata tespiti, analitik |
| **Ayah – Quran App** | $1,99 | $12,99 | Yok | — | Çekirdek ücretsiz; abonelik "destekçi" katmanı |
| **Ezan Vakti Pro** (TR) | **₺99,99** | **₺799,99** | Reklam kaldırma **₺79,99** tek seferlik | Doğrulanamadı | Ücretsiz + yoğun reklam; premium = reklamsızlık |
| **"Diyanet Namaz Vakti" (3. taraf)** | Haftalık ₺199,99 | — | **"Pro" ₺249,99 / ₺499,99 tek seferlik** | — | Türkiye'de baskın kalıp: tek seferlik Pro açma |
| **e-Diyanet (resmî)** | — | — | — | — | **Tamamen ücretsiz, reklamsız, IAP yok.** Türkiye'de fiyat tabanı budur |

> Doğrulanamayanlar: Athan'ın ömür boyu katmanı (App Store listesinde bulunamadı),
> Muslim Pro ve Athan'ın TR fiyat etiketlerinin ad→fiyat eşleşmesi, Pillars ve
> Tarteel deneme süreleri. Bunlar strateji için belirleyici değil.

### Türkiye fiyat gerçeği

- Apple, Türkiye App Store fiyatlarını **17 Kasım 2025**'te güncelledi (kur + vergi);
  dijital satış vergisi **Ocak 2026**'da %7,5 → %5'e indi. Abonelik fiyatları
  otomatik değişmez — geliştirici elle belirler.
- Eski numaralı "Tier" sistemi kalktı; artık ~900 fiyat noktası, taban $0,29.
  ("Türkiye Tier 1 = ₺X" diye dolaşan tablolar güncel değil.)
- Referans nokta: **Apple Music Bireysel TR = ₺59,99/ay**.
- Gözlenen İslami uygulama TR kümeleri: aylık **₺99,99 / ₺199,99 / ₺299,99**,
  yıllık **₺499,99 / ₺799,99 / ₺999,99**, tek seferlik **₺79,99–₺499,99**.
- **Otomatik USD→TRY dönüşümü Türkiye'yi 2–3 kat aşırı fiyatlar.** Muslim Pro'nun
  ₺499,99/ay'ı bunun örneği. Biz TR fiyatlarını **elle** gireceğiz.

### Sektör kıyasları

- Sert paywall + 7 gün deneme: D35 deneme→ödeme medyanı **~%10,7**, düz
  freemium'da **~%2,1**. Deneme eklemek ödemeli dönüşümü **%38–52** artırıyor.
- Kart isteyen (opt-out) deneme, kart istemeyene göre **2,5–3 kat** daha iyi dönüyor.
- Deneme başlangıçlarının **%82'si kurulum günü** oluyor → paywall onboarding'de
  gösterilmeli.
- Yıllık planın tipik fiyatı aylığın **3,8–5,4 katı** (yani %57–68 indirim).
  Muslim Pro 2,7 kat ile agresif uçta.
- Ömür boyu: uygulamaların ~%35'i abonelikle karıştırıyor; bu kategoride
  global olarak seyrek ama **Türkiye'de tek seferlik açma normdur**.

---

## 3. Önerilen paketler

| Plan | Türkiye (TRY) | Global (USD) | Not |
|---|---|---|---|
| **Aylık** | **₺129,99** | **$4,99** | Giriş kapısı; Ezan Vakti Pro'nun (₺99,99) hemen üstü, Muslim Pro'nun çok altı |
| **Yıllık** ⭐ | **₺649,99** (≈ ₺54,17/ay) | **$24,99** (≈ $2,08/ay) | **Varsayılan seçili plan.** Aylığın 5,0 katı → **%58 tasarruf** rozeti |
| **Ömür boyu** | **₺1.299,99** | **$59,99** | Yıllığın ~2 katı (TR) / ~2,4 katı (global) |

Aylık→yıllık oranı (5,0×) kategori medyanının tam ortasında; rozetteki
"%58 tasarruf" ifadesi **gerçek** ve koddan hesaplanıyor
(`SubscriptionManager.yearlySavingsPercent`), sabit yazılmadı.

**Aile paylaşımı** üç ürün için de açık (`familyShareable: true`) — bir ailenin
tek abonelikle yetinmesi, bu kategoride marka açısından doğru olan.

### Ömür boyu seçeneği gerekli mi? — **Evet, ama sessiz bir üçüncü seçenek olarak**

- **Lehine:** Türkiye'de kullanıcılar tek seferlik "Pro açma"ya alışkın; yinelenen
  ödemeye direnç yüksek ve enflasyon nedeniyle abonelik psikolojik olarak riskli
  görülüyor. Rakip Ezan Vakti Pro'nun en çok satan ürünü tek seferlik açma.
  Ayrıca ARPU'yu erken yükseltir ve "destekçi" duygusu yaratır.
- **Aleyhine:** Uzun vadede LTV'yi kırpar, sunucu maliyeti olan özellikleri
  (iCloud yedekleme, çoklu şehir) süresiz taahhüt eder.
- **Karar:** Kalsın, ama **paywall'da üçüncü ve en alttaki kart** olsun, rozet
  taşımasın, varsayılan seçili olmasın. Deneme akışının hedefi yıllık plandır.
  Fiyatı yıllığın ~2 katında tutmak, yıllığın hâlâ "akıllı seçim" gibi
  görünmesini sağlar.

### Deneme mekaniği

İki yol da destekleniyor:

1. **App Store girişli deneme (tercih edilen).** App Store Connect'te aylık ve
   yıllık ürüne `P1W` ücretsiz giriş teklifi tanımlanır. Kullanıcı Apple'ın
   akışından geçer, iptali Ayarlar'dan yapabilir. Dönüşüm en yüksek burada.
2. **Yerel deneme (kartsız).** Ürünler henüz ASC'de tanımlı değilken ya da
   kullanıcı giriş teklifini daha önce kullanmışken, uygulama 7 günlük yerel
   denemeyi verir (`startFreeTrial()`, App Group `UserDefaults`). Kart istenmez,
   hiçbir ücret çıkmaz.

Kod, mağazada gerçek bir giriş teklifi görürse **1. yolu** kullanır; görmezse
2. yola düşer (`PaywallView.storeOffersTrial` / `localTrialAvailable`).

Saat manipülasyonuna karşı: kalıcı bir "en yüksek görülen tarih" damgası
tutuluyor; cihaz saati bir günden fazla geri alınırsa deneme *tüketilmiş* sayılır
(uzatılmaz). Agresif bir DRM değil, makul bir fren.

---

## 4. Ücretsiz vs. Premium

### Her zaman ücretsiz (asla kilitlenmeyecek)

- Namaz vakitleri (günlük + aylık liste, tüm hesaplama yöntemleri, mezhep seçimi)
- Kıble pusulası (klasik pusula)
- Ezan / vakit bildirimleri, Cuma ve dinî gün hatırlatmaları
- Günün hadisi ve ayeti
- Esmaül Hüsna'nın 99 isminin tamamı (Arapça, okunuş, temel anlam)
- Zikirmatik (temel sayaç ve hazır 33/99/100 hedefleri)
- Ramazan imsakiyesi ve iftar/sahur geri sayımı
- Temel widget'lar ve Live Activity (sıradaki vakit)
- Yakındaki camiler
- **Reklam yok — hiçbir katmanda.** Reklamsızlık satılan bir özellik değil,
  uygulamanın baştan verdiği söz.

### Mihrab Plus (`PremiumFeature` enum'u ile birebir)

| Özellik | `PremiumFeature` | Gerekçe |
|---|---|---|
| Gelişmiş widget'lar (tüm boyut/stil, çoklu yapılandırma) | `.advancedWidgets` | Süsleyici |
| Temalar & aksan paletleri | `.themes` | Süsleyici |
| Özel ezan / müezzin sesleri (varsayılan ses ücretsiz) | `.customAdhan` | Süsleyici |
| Sınırsız özel zikir hedefleri | `.dhikrUnlimitedGoals` | Temel sayaç ücretsiz |
| Tam zikir geçmişi & istatistik (ücretsizde son 7 gün) | `.dhikrFullHistory` | Veri katmanı |
| Esma koleksiyonları (derlenmiş setler) | `.esmaCollections` | 99 ismin kendisi ücretsiz |
| Tefekkür metinleri / uzun içerik | `.tafakkurContent` | Üretilen içerik |
| Ramazan planlayıcı (hedefler, hatim takibi, 30 günlük plan) | `.ramadanPlanner` | İmsakiye ücretsiz |
| AR kıble (kamera üzerinden) | `.qiblaAR` | Pusula ücretsiz |
| Çoklu şehir / kayıtlı konumlar | `.multipleCities` | Tek konum ücretsiz |
| iCloud yedekleme & cihazlar arası eşitleme | `.iCloudBackup` | Sürekli maliyet |
| Paylaşım kartları (özel tasarımlar) | `.shareCards` | Süsleyici |

Kural: **bir özelliği premium yapmadan önce şunu sor — bu olmadan kişi ibadetini
zamanında ve doğru yapabilir mi? Cevap "hayır" ise ücretsiz kalır.**

---

## 5. Dönüşüm akışı

```
Onboarding (son adım)
   └─ PaywallView(source: .onboarding)      "Şimdi değil" görünür
        ├─ [7 gün ücretsiz dene] ──► yıllık plan seçili, deneme başlar
        │      ├─ 5. gün 11:00 ─► "İki gün kaldı" bildirimi (TrialReminder)
        │      ├─ 7. gün −12sa ─► "Bugün bitiyor" bildirimi
        │      └─ bitiş ─► ücretsiz katman; hiçbir şey kaybolmaz, sadece
        │                  Plus özellikleri PremiumLockBadge ile işaretlenir
        └─ [Şimdi değil] ──► ücretsiz katman

Özellik dokunuşu (kilitli)
   └─ PaywallView(source: .feature)          bağlam: hangi özellik istendiyse

Ayarlar
   └─ SubscriptionSettingsSection             durum + yükselt + yönet + geri yükle
```

Beklenen sonuç (kıyaslara göre, taahhüt değil): onboarding paywall'ı + 7 gün
deneme ile kurulum başına ödemeli dönüşüm **%3–6** bandı; TR'de daha düşük ama
ömür boyu satışları ARPU'yu dengeler.

---

## 6. App Store Connect kurulum notları

1. **Abonelik grubu:** "Mihrab Plus" — aylık ve yıllık aynı grupta, böylece
   kullanıcı planlar arasında yükseltip düşürebilir.
2. **Ürün kimlikleri** (koddaki `MihrabProduct` ile birebir):
   - `com.caferkarakaya.mihrab.plus.monthly` — Otomatik yenilenen, 1 ay
   - `com.caferkarakaya.mihrab.plus.yearly` — Otomatik yenilenen, 1 yıl
   - `com.caferkarakaya.mihrab.plus.lifetime` — Non-consumable
3. Aylık ve yıllığa **1 hafta ücretsiz giriş teklifi** ekle (yeni aboneler).
4. Türkiye fiyatlarını **elle** gir; otomatik dönüşüme bırakma.
5. Üçünde de **Aile Paylaşımı** açık.
6. Gizlilik ve EULA bağlantıları paywall'da mevcut
   (`PaywallView.privacyURL` / `termsURL` — yayından önce gerçek gizlilik
   sayfasıyla değiştirilecek).
7. Yerel test: `Mihrab/Resources/Mihrab.storekit` dosyasını şemada
   *StoreKit Configuration* olarak seç.

---

## 7. İleride gözden geçirilecekler

- TL enflasyonu nedeniyle **TR fiyatları 6 ayda bir** gözden geçirilmeli.
  Mevcut aboneler için fiyat artışında Apple'ın onay akışı gerekiyor — sadece
  yeni abonelere uygulamak daha az sürtünmeli.
- Ramazan öncesi (Şubat) tanıtım teklifi düşünülebilir, **ama** "son X saat"
  tarzı baskı dili kullanılmayacak.
- Aile planı, kullanıcı talebi gelirse ayrı SKU olarak eklenebilir; şimdilik
  Aile Paylaşımı yeterli.
- Öğrenci/düşük gelir indirimi: Apple'ın araçlarıyla zor; alternatif olarak
  "istersen daha sonra" akışının hep açık kalması yeterli görülüyor.
