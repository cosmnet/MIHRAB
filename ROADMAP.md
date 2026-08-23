# Mihrab — Birleşik Yol Haritası

> 23 Ağustos 2026. Üç paralel araştırmanın sentezi. Detaylar için:
> [`RESEARCH_MARKET.md`](RESEARCH_MARKET.md) · [`RESEARCH_UI.md`](RESEARCH_UI.md) · [`RESEARCH_PLATFORM.md`](RESEARCH_PLATFORM.md) · [`PRICING.md`](PRICING.md)

## Stratejik tez

Türkiye'de **marka güveninin sahibi, yazılım kalitesinin sahibi değil.** Diyanet'in kendi uygulaması 3.37★, pazar lideri Ezan Vakti Pro'nun Şikayetvar marka puanı 0/100 — şikayetler ibadet uygulamasının içindeki kumar ve müstehcen reklamlar üzerine. Bu bir kullanılabilirlik şikâyeti değil, **ahlaki bir ihlal** olarak algılanıyor ve rakipler gelir modelleri reklama bağlı olduğu için bunu yapısal olarak karşılayamıyor.

Mihrab'ın konumu buradan çıkıyor: **reklamsız, veri toplamayan, Diyanet'e gerçekten uyan, güzel.**

Pencere açık ama kapanıyor — Türkiye Referans kategorisinin ~%20'si artık İslami uygulama ve 2026 çıkışlı Türk indie'ler hızla büyüyor (Quran Widgets 6 ayda ~10.500 puan).

**Takvim baskısı:** Ramazan 2027 = 8 Şubat. Üç aylar ~11 Aralık 2026. En değerli kullanıcılar Ramazan'dan iki hafta **önce** ediniliyor. Yani aşağıdaki "Sonra" bloğunun **Aralık 2026'da yayında olması** gerekiyor.

---

## 🔴 Hemen (0–1 ay) — güven temeli

Bunlar olmadan geri kalanı kumdan kale.

| # | İş | Efor | Kaynak | Neden şimdi |
|---|---|---|---|---|
| 1 | **Cihaz üstü vakit hesaplama** (`adhan-swift`, MIT, `.turkey` metodu hazır) + kalıcı disk cache + `BGTaskScheduler` | M | Pazar + Platform | Vakitler şu an *yalnızca* Aladhan API'sinden geliyor. Uçakta, çekmeyen yerde, API kesintisinde uygulamanın çekirdek işlevi susuyor |
| 2 | **AlarmKit ile gerçek, tam uzunlukta ezan** | M | Pazar | Kategorinin en büyük çözülmemiş sorunu: ezan ya hiç çalmıyor ya 30 sn'de kesiliyor. iOS 26 bunu sistem seviyesinde çözüyor ve **şu an pazarda tamamen sahipsiz** |
| 3 | **Ezan sesi kütüphanesi** | M | Pazar | `Resources/Audio/` boş, bildirimler `.default` sesiyle çalıyor. Adı "ezan vakti" olan bir kategoride tanımlayıcı eksik |
| 4 | **App Intents katmanı** → Siri + Kısayollar + Spotlight + Action Button + Control Center + interaktif widget | S–M | Platform | Kod tabanında **0 `AppIntent`** var. Tek altyapı altı yüzeyi birden açıyor; Apple featuring için en ucuz sinyal. Watch/iPad'den **önce** gelmeli |
| 5 | **`PrivacyInfo.xcprivacy`** (`UserDefaults` → `CA92.1`) | S | Platform | Yok. App Store yüklemesi bunsuz reddediliyor |
| 6 | **Paywall'da satılan ama olmayan özellikleri kapat** — iCloud yedekleme, özel ezan sesi, çoklu şehir | S | Platform | 12 `PremiumFeature` case'inin 11'i kodda hiç kontrol edilmiyor. Guideline 2.3.1 riski |
| 7 | **Kıble: gerçek kuzey + doğruluk kapısı + güneşle doğrulama** | S | Pazar | Sessizce yanlış yön göstermek kabul edilemez; rakipler bundan 1★ alıyor |
| 8 | **Vakit şeffaflık paneli + ±dk düzeltme** | S | Pazar | "Vakitler yanlış" şikâyetini öfkeye dönüşmeden çözer |
| 9 | **Offline dayanıklılık: hatayı ilgili karta hapset** | M | Tasarım | Ağ hatasında tüm Bugün ekranı çöküyor; oysa kıble, zikirmatik, Esma ve önbellekli vakitler offline çalışabilir. + "Son güncelleme" etiketi |
| 10 | **Konum/pil disiplini** — `distanceFilter`, `stopUpdatingLocation()`, Düşük Güç modu kontrolü, bildirim `add()` sonucunu denetle | S | Platform | Her GPS güncellemesi tam aylık API çağrısı tetikliyor. 64 bildirim limiti kandil aylarında tam sınırda |
| 11 | **Live Activity yaşam döngüsü** — `scenePhase` gözlemi | S | Platform | Tek yerden çağrılıyor: vakte 30 dk'dan erken açılırsa hiç başlamıyor, başlarsa hiç kapanmıyor |
| 12 | **"Sıfır reklam, sıfır veri" duruşunun iletişimi** | S | Pazar | Kodda değil mesajda iş. Konumlanmanın tamamı buna dayanıyor |

**Tasarım tarafında aynı dönemde:**
- Bugün ekranını **11 karttan ~6'ya** indir (Calm 3, TIDE 5, Waking Up 4 kart kullanıyor — 11'de hiyerarşi yok)
- Hero geri sayım kartına **tek birincil eylem şeridi** (kart ekranın %35'ini kaplayıp yalnızca bilgi veriyor)
- **Vakte göre kayan arka plan sahnesi**: fecir soğuk mavi → öğle zümrüt → akşam pirinç → yatsı abis. Altyapı (`MihrabBackdrop` + shader) ve veri (countdown zaten vakti biliyor) hazır. *Tasarım ajanının "ADA seviyesindeki tek detay" dediği madde.*
- Kıble kadranının merkezine **derece değil talimat**: "12° sağa dön"
- Onboarding bildirim adımında **gerçek ezan bildirimi önizlemesi** (Strava deseni)

---

## 🟠 Sonra (1–3 ay) — farklılaşma ve Ramazan hazırlığı

| # | İş | Efor | Neden |
|---|---|---|---|
| 13 | **Diyanet vakitleri gerçek *temkin* ile + takvim kaynağı seçici** | M | "Diyanet uyumluyum" demek yetmiyor: doğuş/batış 7 dk, öğle 5 dk, ikindi 4 dk temkin var. Ayrıca 1983'ten beri imsakte 15–20 dk farkla **üç takvim geleneği** (Diyanet / Fazilet / Türkiye Takvimi) — seçici sunan modern uygulama yok |
| 14 | **Kaza namazı takibi** + duraklama modu | M | Türkiye'de tek başına bir kategori, duygusal olarak çok bağlayıcı. ASO'da **"kaza namazı" teriminde 1. sıradaki uygulamanın 1000'den az puanı var** — bedava trafik |
| 15 | **Kur'an okuyucu (metin + meal)** | L | "Tek uygulamam" olabilmenin ön şartı. Ücretsiz olmalı |
| 16 | **Hatim takibi + Ortak Hatim** | M | "Ortak Hatim" ve "Cüz Takip" TR'de ayrı uygulamalar olarak yaşıyor — talep kanıtlı. Davet linki doğal büyüme motoru |
| 17 | **Türk dinî takvimi** — kandiller, üç aylar, nafile oruç | M | Yılda 6 doğal geri dönüş tetikleyicisi (akşam kaydırması doğru yapılmalı) |
| 18 | **SwiftData + CloudKit senkronu** | M | Seri ve kayıt kaybı en hızlı terk sebeplerinden. Üç model zaten CloudKit şema kurallarına uyuyor, geçiş ucuz. *Not: şema yayına alındıktan sonra yalnızca eklemeli değiştirilebilir* |
| 19 | **Zekât hesaplayıcı** | M | Nüfusun %78,6'sına dokunur, Ramazan zirvesi. Ücretsiz kalsın |
| 20 | **Hediye / Sadaka-i Cariye abonelik tier'ı** | M | Fazilet Takvimi'nin "Arkadaşım / Ailem / Komşum" paketleri gibi. Satın almayı bir **sevap eylemine** çevirerek pazarın en yaygın itirazını ("din parayla olmaz") etkisiz kılıyor. Bulunan en kültürel uyumlu gelir modeli, kimse kopyalamıyor |
| 21 | **Dinamik Tip desteği** — 57 sabit `.font(.system(size:))`, 0 `ScaledMetric` | M | Apple Design Award hedefi için engelleyici |
| 22 | **ASO paketi** — CPP'ler, In-App Event, sezonluk metadata, ikincil diller | S | Kod işi değil ama Ramazan'ın en yüksek getirili hazırlığı |
| 23 | **Paywall'ı yatay 3 plan + sticky footer + CTA'da plan adı** | M | Bloom/Hevy deseni; dikey kartlar karşılaştırmayı zorlaştırıyor |
| 24 | **Zikirmatik odak modu** + basılı tutarak sıfırlama + halkada 11'lik tikler | S–M | 871 satırlık ekranda 4 katman chrome var (pushr + Forest deseni) |

---

## 🟡 İleride (3 ay+)

| İş | Efor | Not |
|---|---|---|
| **Apple Watch + komplikasyonlar** | L | Etkisi çok yüksek, alan neredeyse rakipsiz — **Ramazan 2028'in ana kozu**. Hesaplama kodu olduğu gibi taşınır, UI yeniden yazılır. Ödeme duvarına koyma. *Ucuz ara adım:* `supplementalActivityFamilies([.small])` ile watch hedefi olmadan Smart Stack'te görün |
| **Kur'an dinleyici + kari indirme** | L | Plus'ın en güçlü gerekçelerinden |
| **Namaz öğretici** | L | Yeni Müslüman ve genç kitle; edinme kancası |
| **Hac & Umre modu** | L | ASO'da terim tamamen boş, Diyanet'inki 1.77★. Yüksek ödeme isteği |
| **Yeni diller** | M | Öncelik: ar → de (diaspora) → id → fr → ur. *Uyarı: yerelleştirme 8 dosyada 2.337 satır hardcoded Swift; dördüncü dil ~900 çağrı noktası demek — önce String Catalog'a taşımak gerekebilir* |
| **iPad + Mac** | M | Kur'an okuyucudan sonra anlamlı |
| **Aile/dost çemberleri** | L | Gizlilik tasarımı "sıfır veri" duruşuyla çelişmemeli |
| Teheccüd, Cuma ritüeli, Apple Health, cami modülü, feraiz, çocuk modu, Vision Pro | S–L | Boşluklara serpiştirilir |

---

## Korunması gereken güçlü yanlar

Tasarım araştırmasının ayrıca not ettiği, **bozulmaması gereken** kararlar:

- Geri sayımsız, dürüst paywall; ilk kareden görünen kapatma butonu
- Ücretsiz katmanın adıyla anılması ("İbadetin temeli her zaman ücretsiz")
- Her animasyonda Reduce Motion dallanması
- Kalibre olmayan pusulayı dürüstçe söylemek
- "Türetilmiş veri, uydurulmuş değil" ilkesi
