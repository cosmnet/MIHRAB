# Mihrab — v1 Yayın Kontrol Listesi

> Sahibi: Ajan F5 · Son güncelleme: 27 Ağustos 2026 · Hedef: App Store v1.0 (build 1)
> Metadata ve ekran görüntüsü metinleri için [`ASO.md`](ASO.md), fiyatlandırma
> gerekçeleri için [`PRICING.md`](PRICING.md). Burada onlar tekrarlanmaz, referans verilir.

Bu dosya **sırayla** yapılacak işleri sayar. Her madde kodu okuyarak doğrulandı;
doğrulanamayan hiçbir şey "tamam" olarak işaretlenmedi.

---

## ⚖️ Hukukçu notu (siteye değil, buraya)

`docs/privacy.html`, `docs/privacy-en.html` ve `docs/terms.html` **uygulamanın
fiilen ne yaptığını** anlatır; her cümlesi kod okunarak yazıldı ve KVKK/GDPR'ın
beklediği başlıkları (veri sorumlusu, işleme amacı ve hukuki dayanağı, aktarım,
saklama süresi, ilgili kişi hakları) taşır. **Bunlar hukuki tavsiye değildir.**
Yayına almadan önce bir avukata okutun; özellikle şu üç nokta sizin durumunuza
göre değişir:

1. **Veri sorumlusu kimliği.** Sayfalarda `Cafer Karakaya — bağımsız geliştirici`
   ve `mihrab.feedback@icloud.com` yazıyor. Şahıs değil **şirket** olarak
   yayımlıyorsanız ticaret unvanı, MERSİS/vergi no ve tebligata elverişli adres
   eklenmeli; AB'de kullanıcıya satış yapıyorsanız GDPR m.27 temsilcisi gerekip
   gerekmediğini sorun.
2. **VERBİS kaydı.** Türkiye'de yıllık çalışan/ciro eşiklerinin altındaki gerçek
   kişi veri sorumluları genellikle muaf; şirketleşirseniz bu değişebilir.
3. **Aydınlatma metni ayrılığı.** KVKK uygulamasında "gizlilik politikası" ile
   "aydınlatma metni" bazen ayrı belgeler olarak isteniyor. Avukatınız isterse
   `privacy.html`'in 1–5. bölümleri ayrı bir aydınlatma metnine bölünebilir —
   içerik zaten o yapıda yazıldı.

Ayrıca yayına almadan önce **`mihrab.feedback@icloud.com` adresinin gerçekten
sizde olduğunu ve gelen postayı okuduğunuzu doğrulayın.** Bu adres hem uygulamanın
içinde (`SettingsView.swift:434`), hem gizlilik politikasında, hem destek
sayfasında geçiyor; App Store Connect'in "Support URL" ve "Marketing/Privacy
Contact" alanlarına da bu gidecek. Ölü bir destek adresi App Store incelemesinde
takılır.

---

## 1. GitHub Pages — gizlilik politikası URL'sini canlıya al

**Bu, gönderimi engelleyen tek numaralı maddedir.** Guideline 3.1.2 paywall'da
*çalışan* bir gizlilik politikası bağlantısı istiyor; kodda şu an ölü bir
placeholder var.

### 1.1 Yayımlanacak dosyalar (hazır)

`docs/` klasörü, harici kaynak kullanmayan (CDN yok, webfont yok, analitik yok,
çerez yok) statik bir sitedir:

| Dosya | İçerik |
|---|---|
| `docs/index.html` | Giriş sayfası, uygulama özeti, yasal belge bağlantıları |
| `docs/privacy.html` | **Gizlilik Politikası (TR)** — KVKK + GDPR başlıklarıyla |
| `docs/privacy-en.html` | **Privacy Policy (EN)** — aynı içeriğin İngilizcesi |
| `docs/terms.html` | Kullanım Şartları (TR) + English summary + içerik lisansları |
| `docs/support.html` | Destek / SSS — App Store "Support URL" için |
| `docs/style.css` | Tek CSS dosyası, koyu zümrüt kimlik, mobil öncelikli |
| `docs/.nojekyll` | GitHub Pages'in Jekyll işlemesini atlaması için |
| `.github/workflows/pages.yml` | İsteğe bağlı yayın iş akışı — yalnızca Pages kaynağı "GitHub Actions" seçilirse çalışır; beş sayfanın da var ve boş olmadığını doğrulayıp yayına alır |

### 1.2 Adımlar

Bu depoda **henüz bir `git remote` tanımlı değil** (`git remote -v` boş döndü),
bu yüzden nihai URL'yi ancak siz kesinleştirebilirsiniz.

```sh
# 1) GitHub'da bir depo açın (herkese açık olmalı — Pages ücretsiz planda
#    yalnızca public depolarda çalışır).
git remote add origin git@github.com:<KULLANICI>/<DEPO>.git
git push -u origin main

# 2) GitHub → Settings → Pages — iki yoldan biri:
#
#    (a) Source: "Deploy from a branch"  ·  Branch: main  ·  Folder: /docs
#        En basiti. Hiçbir iş akışı gerekmez.
#
#    (b) Source: "GitHub Actions"
#        Depodaki .github/workflows/pages.yml devreye girer; docs/ altındaki
#        her değişiklikte otomatik yayımlar ve beş sayfanın da yerinde
#        olduğunu doğrular.
#
#    Save. İlk yayın 1-2 dakika sürer. İki yol da aynı URL'leri üretir.
```

**Beklenen URL biçimi** (git kullanıcı adı `cosm`, klasör adı `MIHRAB` olduğundan
en olası hâli):

```
https://cosm.github.io/MIHRAB/                 → giriş
https://cosm.github.io/MIHRAB/privacy.html     → Gizlilik Politikası (TR)
https://cosm.github.io/MIHRAB/privacy-en.html  → Privacy Policy (EN)
https://cosm.github.io/MIHRAB/terms.html       → Kullanım Şartları
https://cosm.github.io/MIHRAB/support.html     → Destek
```

- [ ] Depo adını ve GitHub kullanıcı adını **doğrula**; yukarıdaki beş URL'yi
      tarayıcıda tek tek aç ve 200 döndüğünü gör. Depo adı farklıysa (örneğin
      `mihrab`) yol da değişir.
- [ ] Kendi alan adınız varsa: `docs/CNAME` dosyası oluşturup içine tek satır
      alan adı yazın, DNS'te `CNAME` kaydını `<KULLANICI>.github.io`'ya yöneltin.
      O zaman URL `https://mihrab.app/privacy.html` olur ve koda bu girilir.

### 1.3 Koda girilecek satır (dosya F1'in — bu ajan dokunmadı)

**Dosya:** `Mihrab/Features/Paywall/PaywallView.swift`
**Satır 29–33** aşağıdaki blokla değiştirilecek:

```swift
    /// Yayında. GitHub Pages üzerinden servis ediliyor: `docs/privacy.html`.
    /// Guideline 3.1.2 paywall'da *çalışan* bir gizlilik politikası bağlantısı
    /// istiyor; bu bağlantı canlı ve dış kaynak yüklemiyor.
    private static let privacyURL = URL(string: "https://cosm.github.io/MIHRAB/privacy.html")!
    private static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
```

`termsURL` **değişmiyor**: Kullanım Şartları için Apple'ın standart EULA'sı
kullanılıyor (aşağıda §1.4). `docs/terms.html` bu EULA'yı özetleyip Mihrab'a
özgü abonelik ve içerik lisansı maddelerini ekler, ama **hukuken bağlayıcı olan
Apple'ın metnidir** ve paywall doğrudan ona bağlanır — bu Apple'ın onayladığı,
en az sürtünmeli yoldur.

> ⚠️ Bu satırdaki URL'yi §1.2'de **doğruladığınız gerçek URL** ile değiştirin.
> Ölü bağlantı = kesin ret.

### 1.4 EULA kararı

**Seçilen yol: Apple'ın Standart Son Kullanıcı Lisans Sözleşmesi.**

- Gerekçe: Mihrab'ın hesabı, kullanıcı üretimi içeriği, sunucusu ve veri
  toplaması yok. Özel bir EULA'nın çözeceği bir sorun bulunmuyor; özel EULA
  yazmak yalnızca inceleme riskini ve hukuk maliyetini artırır.
- App Store Connect'te **"EULA" alanı boş bırakılacak** — boş bırakmak "Apple'ın
  standart EULA'sı geçerlidir" demektir. Özel metin yapıştırmayın.
- Mihrab'a özgü koşullar (abonelik yenilenmesi, içerik lisansları, dinî içerik
  uyarısı) `docs/terms.html`'de ve uygulama içindeki abonelik metninde yaşıyor;
  bunlar EULA'nın yerine geçmez, onu tamamlar.

### 1.5 Uygulama içindeki ikinci bağlantı (F1/Settings sahibi için)

`Mihrab/Features/Settings/SettingsView.swift:404-407` — Ayarlar → "Veri ve
gizlilik" bölümündeki **"Gizlilik"** düğmesi şu an
`UIApplication.openSettingsURLString` açıyor, yani **iOS Ayarlar'a gidiyor,
gizlilik politikasına değil.** Kullanıcı buradan politikayı okuyamıyor.
Önerilen: bu satır aynı `privacyURL`'e bağlansın, iOS izin ekranı ayrı bir
satır olarak kalsın. (Bu dosya bu ajanın sahibi değil — kod değişikliği
Settings sahibine ait.)

---

## 2. App Store Connect — uygulama kaydı

- [ ] **Bundle ID:** `com.caferkarakaya.mihrab` (Developer portalında Explicit App ID).
      Ek kimlikler aynı önekte kayıtlı olmalı:
      - `com.caferkarakaya.mihrab.widgets`
      - `com.caferkarakaya.mihrab.watchkitapp`
      - `com.caferkarakaya.mihrab.watchkitapp.widget`
- [ ] **App Group:** `group.com.caferkarakaya.mihrab` — dört hedefin de üyesi.
- [ ] **iCloud Container:** `iCloud.com.caferkarakaya.mihrab`.
- [ ] **Ad / alt başlık / anahtar kelimeler:** [`ASO.md` §1](ASO.md) — kopyala-yapıştır hazır.
- [ ] **Kategori:** Birincil **Referans**, ikincil **Yaşam Tarzı**.
      *Not:* kodda `INFOPLIST_KEY_LSApplicationCategoryType` şu an
      `public.app-category.lifestyle` (`project.yml`). Bu alan Mac için anlamlıdır
      ve ASC'deki kategori seçimini ezmez, ama tutarlılık için ASC'de birincil
      **Referans** seçilmesi gerekir; kararı [`ASO.md` §8.1](ASO.md) gerekçelendiriyor.
- [ ] **Yaş sınırı: 4+.** Ankette tüm kategoriler "Yok". Doğrulandı: uygulamada
      kullanıcı üretimi içerik, sohbet, reklam, kumar, denetlenmemiş web görünümü yok.
- [ ] **Support URL:** `https://cosm.github.io/MIHRAB/support.html`
- [ ] **Privacy Policy URL:** `https://cosm.github.io/MIHRAB/privacy.html`
- [ ] **Marketing URL** (isteğe bağlı): `https://cosm.github.io/MIHRAB/`
- [ ] **Telif hakkı satırı:** `2026 Cafer Karakaya` (ASC'nin istediği biçim).
- [ ] **İnceleme notu:** AR kıble ve alarm izinlerinin ne için istendiğini bir
      paragrafla yazın; ayrıca "uygulama hesapsız çalışır, demo hesabı gerekmez"
      notunu ekleyin.

---

## 3. Gizlilik beyanı (App Privacy "Nutrition Labels")

`Mihrab/Resources/PrivacyInfo.xcprivacy` ve `MihrabWidgets/PrivacyInfo.xcprivacy`
okundu. **Birebir eşleşmesi gereken beyan:**

| ASC sorusu | Cevap | Kod dayanağı |
|---|---|---|
| Do you or your third-party partners collect data from this app? | **No, we do not collect data** | `NSPrivacyCollectedDataTypes` = boş dizi; kod tabanında analitik/reklam/attribution/crash SDK'sı yok. Tek üçüncü taraf paket `adhan-swift` (MIT), ağ açmıyor. |
| Does this app use data for tracking? | **No** | `NSPrivacyTracking = false`, `NSPrivacyTrackingDomains` = boş. `ATTrackingManager` çağrısı yok, IDFA yok. |

> **Bu "veri toplamıyoruz" cevabı savunulabilir mi?** Evet — Apple'ın tanımında
> "collect", verinin **cihazdan ayrılıp geliştiricinin erişebildiği bir yere**
> gitmesidir. Mihrab'da: konum yalnızca anonim bir vakit sorgusuyla üçüncü taraf
> Aladhan'a gidiyor ve geliştiriciye ulaşmıyor; iCloud verisi kullanıcının kendi
> özel veri tabanında ve geliştirici erişemiyor; StoreKit verisini Apple işliyor.
> Yine de bu üç akış `docs/privacy.html` §3.2, §3.6, §3.7'de açıkça yazılı —
> beyan ile politika birbiriyle çelişmiyor.

**Required Reason API beyanları (manifestte hazır, ASC'de ayrıca soru yok):**

| API kategorisi | Sebep kodu | Neden |
|---|---|---|
| `NSPrivacyAccessedAPICategoryUserDefaults` | `CA92.1`, `1C8F.1` | App Group üzerinden uygulama + uzantı paylaşımı; kendi ayarları |
| `NSPrivacyAccessedAPICategoryFileTimestamp` | `C617.1` | Kendi container'ındaki önbellek dosyalarının tazeliği |

- [x] ✅ **Yapıldı.** `MihrabWatch/PrivacyInfo.xcprivacy` ve
      `MihrabWatchWidgets/PrivacyInfo.xcprivacy` eklendi ve `project.yml`'de her
      iki hedefin `resources:` listesine girdi.

---

## 4. Yetenekler (Capabilities)

`Mihrab/Mihrab.entitlements`, `Mihrab/Info.plist`, uzantı entitlement'ları ve
`project.yml` okunarak çıkarıldı. Developer portalında App ID üzerinde
**açılması gereken** yetenekler:

| Yetenek | Nerede tanımlı | Hedefler |
|---|---|---|
| **App Groups** — `group.com.caferkarakaya.mihrab` | dört `.entitlements` dosyasının hepsi | Mihrab, MihrabWidgets, MihrabWatch, MihrabWatchWidgets |
| **iCloud → CloudKit** — `iCloud.com.caferkarakaya.mihrab` | `Mihrab.entitlements` | Mihrab |
| **iCloud → Key-value storage** — `$(TeamIdentifierPrefix)$(CFBundleIdentifier)` | `Mihrab.entitlements` | Mihrab |
| **Push Notifications** | `UIBackgroundModes → remote-notification` (Info.plist) | Mihrab — **yalnızca CloudKit'in sessiz uyandırması için**; push sunucusu yok |
| **Background Modes** — `fetch`, `processing`, `remote-notification` | `Mihrab/Info.plist` | Mihrab |
| **BGTaskScheduler kimlikleri** — `…mihrab.refresh`, `…mihrab.maintenance` | `Mihrab/Info.plist` | Mihrab |
| **AlarmKit** | `NSAlarmKitUsageDescription` (Info.plist) + `MIHRAB_ALARMKIT` derleme koşulu | Mihrab, MihrabWidgets |
| **Live Activities** | `NSSupportsLiveActivities`, `…FrequentUpdates` (`project.yml`) | Mihrab |
| **URL şeması** — `mihrab://` | `Mihrab/Info.plist` | Mihrab |
| **Özel yazı tipi** — `AmiriQuran-Regular.ttf` | `UIAppFonts` | Mihrab |

**İzin metinleri** (`Mihrab/Resources/InfoPlist.xcstrings` — en/tr/ar üçü de çevrili):

- `NSLocationWhenInUseUsageDescription` ✅
- `NSCameraUsageDescription` ✅ (AR kıble)
- `NSAlarmKitUsageDescription` ✅ — `InfoPlist.xcstrings`'e tr/ar çevirisiyle
  taşındı ve `project.yml`'deki İngilizce sabit kaldırıldı, ikisi çelişemesin.
- Watch tarafı: `MihrabWatch/Info.plist` içinde
  `NSLocationWhenInUseUsageDescription` var, ama **düz metin ve yalnızca
  İngilizce**; watch hedefinde `InfoPlist.xcstrings` yok.

- [ ] Xcode → Signing & Capabilities'te dört hedefin de yeteneklerini gör; hiçbiri
      kırmızı olmasın.
- [ ] Provisioning profilleri **App Group + iCloud + Push** içerecek şekilde
      yeniden üretilsin (Xcode "Automatically manage signing" bunu kendi yapar,
      ama manuel profil kullanıyorsanız elle yenileyin).

---

## 5. Ürünler, deneme ve fiyatlar

Kodda tanımlı üç kimlik (`Mihrab/Core/Subscription/SubscriptionManager.swift:9-13`)
ASC'de **birebir** aynı yazılmalı:

| Ürün | Kimlik | Tür | TR | USD |
|---|---|---|---|---|
| Aylık | `com.caferkarakaya.mihrab.plus.monthly` | Otomatik yenilenen, 1 ay | ₺129,99 | $4,99 |
| Yıllık ⭐ | `com.caferkarakaya.mihrab.plus.yearly` | Otomatik yenilenen, 1 yıl | ₺649,99 | $24,99 |
| Ömür boyu | `com.caferkarakaya.mihrab.plus.lifetime` | Non-consumable | ₺1.299,99 | $59,99 |

- [ ] **Abonelik grubu adı: `Mihrab Plus`** — aylık ve yıllık **aynı grupta**
      olmalı, yoksa yükseltme/düşürme çalışmaz.
- [ ] **7 günlük ücretsiz giriş teklifi** aylık *ve* yıllık planda, "yalnızca yeni
      aboneler" olarak tanımlansın. Kod mağazada gerçek bir giriş teklifi görürse
      Apple akışını kullanır; görmezse kartsız yerel denemeye düşer
      (`TrialReminder`, App Group `UserDefaults`). Teklif tanımlıysa dönüşüm
      belirgin biçimde daha iyi — gerekçe [`PRICING.md`](PRICING.md).
- [ ] **TR fiyatları elle girilsin.** Otomatik USD→TRY dönüşümü Türkiye'yi 2–3 kat
      aşırı fiyatlıyor.
- [ ] **Üç üründe de Aile Paylaşımı açık** (`Mihrab.storekit` içinde
      `familyShareable: true` — koddaki niyetle uyumlu olmalı).
- [ ] Her üç ürünün de **ekran görüntüsü + inceleme notu** alanı doldurulmalı,
      yoksa IAP incelemesi "Missing Metadata"da takılır.
- [ ] Fiyatlar canlıya alındıktan sonra `MihrabProduct.fallbackPriceTRY/USD`
      değerleriyle karşılaştır. Bu değerler yalnızca StoreKit'e ulaşılamadığında
      gösterilen dürüst tahmindir; gerçek fiyatla ayrışırsa güncellenmeli
      (`SubscriptionManager.swift:26-56`).

### ✅ Guideline 2.3.1 — çözüldü

Paywall artık yalnızca binary'de gerçekten kilitli olanı satıyor.

- **Kaldırılan iki iddia:** `ramadanPlanner` (uygulamada Ramazan planlayıcı diye
  bir özellik yok) ve `tafakkurContent` (tefekkür metinleri Esma deneyiminin
  ücretsiz parçası). İkisi de `PremiumFeature`'dan çıkarıldı.
- **Kalan on özelliğin hepsi `.live`:** `multipleCities`, `iCloudBackup`,
  `customAdhan`, `qiblaAR`, `themes`, `dhikrUnlimitedGoals`, `dhikrFullHistory`,
  `esmaCollections`, `advancedWidgets` (şehir seçilebilen widget), `shareCards`
  (işlenmiş görsel; düz metin paylaşımı her yerde ücretsiz).
- `MihrabTests/SubscriptionGateTests.swift` tabloyu test ediyor; bir kapı
  sessizce çürürse test kırılır.

---

## 6. CloudKit

- [ ] **Konteyner:** `iCloud.com.caferkarakaya.mihrab`, private database.
- [ ] Şema **Development**'ta oluşturulsun: `SwiftDataModels.swift:115-123`
      içindeki `#if DEBUG` şema priming yordamı bir kez çalıştırılır (CloudKit
      bir kayıt tipini ancak development konteynerine bir kayıt gönderildikten
      sonra öğrenir).
- [ ] CloudKit Console → **Deploy Schema to Production**.
- [ ] 🔒 **Bir daha geri alınamaz.** Şema Production'a alındıktan sonra
      **yalnızca eklemeli** değiştirilebilir: alan silinemez, yeniden
      adlandırılamaz, tipi değiştirilemez. Üç model (`DhikrSession`,
      `FavoriteHadith`, `KhatamProgress`) ve alan adları Ramazan trafiği gelmeden
      **önce** doğru olmalı. `SwiftDataModels.swift:22`'deki uyarı da bunu söylüyor.
- [ ] Tüm SwiftData alanlarının **varsayılan değeri olduğunu** doğrula (CloudKit
      zorunlu alan kabul etmez) — kodda öyle görünüyor, gönderimden önce bir kez
      daha bak.
- [ ] Senkronizasyonun **varsayılan kapalı** olduğunu doğrula
      (`CloudSyncPreference.isEnabled` → `defaults.bool()` = `false`) ve Plus
      gerektirdiğini teyit et. Gizlilik politikası bunu böyle taahhüt ediyor.

---

## 7. Apple Watch

- [ ] **Bundle id zinciri** — birebir uyum şart, yoksa yükleme
      "BundleID is not valid" ile düşer:
      - iPhone: `com.caferkarakaya.mihrab`
      - Watch app: `com.caferkarakaya.mihrab.watchkitapp`
      - Watch widget: `com.caferkarakaya.mihrab.watchkitapp.widget`
      - `MihrabWatch/Info.plist` → `WKCompanionAppBundleIdentifier` =
        `com.caferkarakaya.mihrab` ✅ (doğrulandı)
- [ ] **Tek gönderim.** Watch uygulaması iPhone binary'sine gömülü gider
      (`project.yml` → `MihrabWatch` bir `embed: true` bağımlılığı). ASC'de ayrı
      bir uygulama kaydı **açılmaz**.
- [ ] **Ayrı ekran görüntüsü seti** gerekir: ASC → App Store → Apple Watch.
      En az bir boyut (45 mm veya 49 mm) zorunlu.
- [ ] `MihrabWatch/Info.plist` içinde `CFBundleShortVersionString` ve
      `CFBundleVersion` `$(MARKETING_VERSION)` / `$(CURRENT_PROJECT_VERSION)`
      değişkenlerinden geliyor ✅ — iPhone ile otomatik senkron.
- [ ] ⚠️ **Watch gerçek cihazda hiç denenmedi** (§9). Simülatörde geçen bir watch
      hedefi, gerçek saatte komplikasyon bütçesi ve WatchConnectivity davranışı
      yüzünden farklı davranabilir. En az bir gerçek Apple Watch'ta:
      uygulamayı aç, komplikasyonu ekle, telefonu uçak moduna al, vakitlerin hâlâ
      hesaplandığını gör.

---

## 8. Ekran görüntüleri, metadata ve içerik lisansları

### 8.1 Metadata

Tüm başlık/alt başlık/anahtar kelime/açıklama metinleri ve ekran görüntüsü
kurgusu **[`ASO.md`](ASO.md)**'de kopyala-yapıştır hazır. Burada tekrarlanmıyor.
Özet gereksinim: 6.9" ve 6.5" zorunlu boyutlar, **tr ve en ayrı ayrı**, 6 kare;
ayrıca Apple Watch için ayrı set (§7).

### 8.2 İçerik lisansları

| İçerik | Lisans | Atıf uygulamada nerede görünüyor | Durum |
|---|---|---|---|
| Kur'an Arapça metni (Tanzil, Uthmani v1.1) | CC BY 3.0 | `QuranVerseShareCard.swift:47,85` (paylaşım kartı), `QuranSettingsSection.swift:71` ("Tanzil · CC BY 3.0"), `L10n+Quran.swift:208-214` (canlı `tanzil.net` bağlantısı) | ✅ Atıf var, lisans belgesi `Mihrab/Features/Quran/CONTENT_LICENSE.md`'de |
| adhan-swift | MIT | — | ⚠️ **Uygulama içinde hiçbir yerde görünmüyor.** MIT lisansı telif bildiriminin dağıtımla birlikte verilmesini şart koşar. Ayarlar → Hakkında altına bir "Açık kaynak lisansları" satırı eklenmeli. |
| Amiri Quran yazı tipi | SIL OFL 1.1 | `L10n+Settings.swift:262-263` — "Amiri Quran (SIL Open Font License)" metni var | ⚠️ **Lisans dosyası eksik.** `Mihrab/Resources/Fonts/` içinde yalnızca `AmiriQuran-Regular.ttf` var; `OFL.txt` yok. OFL, yazı tipinin lisans metniyle birlikte dağıtılmasını **şart koşar**. Amiri projesinin `OFL.txt` dosyası bu klasöre eklenmeli. |
| Hadis / Esmaül Hüsna / adhkar / dinî günler derlemeleri | Uygulama içinde her kayıtta kaynak gösteriliyor | Kayıt bazında | ✅ |
| **Meal (Kur'an çevirisi)** | — | — | ❌ **Yok, bilinçli olarak.** Bkz. §9. |
| **Ezan kaydı** | — | — | ❌ **Yok, bilinçli olarak.** Bkz. §9. |

- [ ] `Mihrab/Resources/Fonts/OFL.txt` ekle (Amiri projesinin lisans metni).
- [ ] Ayarlar → Hakkında'ya "Açık kaynak lisansları" ekranı ekle; en az adhan-swift
      (MIT) ve Amiri (OFL) telif bildirimleri görünsün. *(Kod işi — Settings sahibi.)*

---

## 9. Bilinen boşluklar — inceleme notuna ve mağaza metnine yansıtılmalı

Bunlar hata değil, **bilinçli tercih ya da açık eksik**. Mağaza metninde
saklanmamalı; sürpriz olarak keşfedilen eksik 1★ getirir, önceden söylenen
eksik güven getirir.

1. **Gerçek ezan kaydı yok.** `Mihrab/Resources/Audio/` bilerek boş: telifi
   belirsiz bir muezzin kaydı dağıtılamaz. Uygulama cihazda üretilen telifsiz
   tonlar sunuyor ve kullanıcının kendi kaydını Dosyalar'dan içe aktarmasına izin
   veriyor. → Mağaza açıklamasında **"kendi ezan sesini ekle"** olarak konumlandır,
   "ezan sesi var" deme. Ayrıntı: `Mihrab/Resources/Audio/README.md`.
2. **Kur'an meali yok.** Arapça metin CC BY 3.0 ile eksiksiz var; incelenen her
   Türkçe/İngilizce meal ya telifli ya da yalnızca ticari olmayan kullanıma açık.
   → Uygulama bunu zaten dürüstçe söylüyor (`L10n+Quran.swift:189-190`). Mağaza
   metninde "meal" kelimesini vaat olarak kullanma.
3. **Apple Watch gerçek cihazda denenmedi.** §7.
4. **Fazilet Takvimi seçeneği geri çekildi.** `Mihrab/Data/PrayerSource.swift` —
   temkin değerleri yayımlanmış bir kaynakla doğrulanamadığı için
   `isSelectable = false`; seçicide hiç görünmüyor, kayıtlı değer Diyanet'e
   düşüyor. Doğru karar. → Mağaza metninde **"Fazilet Takvimi desteği" diye bir
   vaat yer almasın.** Türkiye Takvimi ve Diyanet destekleniyor.
5. ✅ **Çoklu şehirde saat dilimi — düzeltildi.** `SavedCity` artık
   `timeZoneIdentifier` taşıyor (arama sonucunda `CLPlacemark.timeZone`'dan,
   hazır şehirlerde elle), `AppSettings.manualTimeZoneIdentifier` üzerinden
   `LocationManager.effectiveTimeZone` olarak yayılıyor ve `PrayerEngine`
   varsayılan olarak onu alıyor.
6. ✅ **Paywall kapıları — çözüldü.** §5.
7. ✅ **AlarmKit izin metni — üç dilde.** §4.

---

## 10. Sürüm, build ve TestFlight

Mevcut durum (doğrulandı):

| Alan | Değer | Nerede |
|---|---|---|
| `MARKETING_VERSION` | `1.0` | `project.yml` → `settings.base` |
| `CURRENT_PROJECT_VERSION` | `1` | `project.yml` → `settings.base` |
| `CFBundleShortVersionString` | `$(MARKETING_VERSION)` | `Mihrab/Info.plist` |
| `CFBundleVersion` | `$(CURRENT_PROJECT_VERSION)` | `Mihrab/Info.plist` |

- [x] ✅ **Düzeltildi.** `Mihrab/Info.plist` artık `$(MARKETING_VERSION)` ve
      `$(CURRENT_PROJECT_VERSION)` değişkenlerini kullanıyor; sürüm ve build
      yalnızca `project.yml` → `settings.base` içinden, tek yerden artırılır.

### Adımlar

```sh
xcodegen generate                      # project.yml değiştiyse
# Xcode 26 · Product → Destination → Any iOS Device (arm64)
# Product → Archive
# Organizer → Distribute App → App Store Connect → Upload
```

- [ ] Archive **Release** konfigürasyonuyla alınsın (`DEBUG` derleme koşulu
      tanımsız kalsın; aksi hâlde `debugForcePremium` yolu binary'ye girer — §11).
- [ ] Yükleme sonrası ASC'de "Export Compliance": uygulama yalnızca standart
      HTTPS/TLS kullanıyor → **"Yalnızca standart şifreleme"** yanıtı.
      (`ITSAppUsesNonExemptEncryption` anahtarını Info.plist'e `false` olarak
      eklemek, her yüklemede bu soruyu sormasını engeller.)
- [ ] **TestFlight iç test:** en az bir gerçek iPhone + bir gerçek Apple Watch.
      Test senaryosu:
      1. Temiz kurulum → onboarding → konum izni → vakitler geliyor mu?
      2. Uçak modu → uygulamayı öldür → aç → vakitler **hâlâ** var mı?
         ("Çevrimdışı motor" etiketi görünmeli.)
      3. Bir vakit için ezan alarmı kur → telefonu sessize al → alarm çalıyor mu?
      4. Widget ekle, Live Activity'yi vakte 30 dk kala gör.
      5. Paywall aç → **gizlilik bağlantısına dokun** → sayfa açılıyor mu? (§1)
      6. Satın al (Sandbox) → geri yükle → başka cihazda geri yükle.
      7. iCloud senkronizasyonunu aç → ikinci cihazda zikir sayısı geliyor mu?
      8. Saat: komplikasyon ekle, telefonu kapat, vakit hâlâ doğru mu?
- [ ] **TestFlight dış test** (isteğe bağlı ama önerilir): 20-30 kişilik Türk
      kullanıcı grubu, en az bir hafta. Asıl aranan geri bildirim: **vakitler
      caminin ilanıyla uyuşuyor mu?**
- [ ] Gönderim: **manuel yayın** seç. Onaylandıktan sonra ne zaman çıkacağına
      sen karar ver ([`ROADMAP.md`](ROADMAP.md): hedef pencere ~11 Aralık 2026,
      üç ayların başı).

---

## 11. Yayın öncesi temizlik

Depo taranarak çıkarıldı. **Kod değiştirilmedi**, dosya:satır ile raporlanıyor.

### 11.1 Engelleyici

| # | Yer | Bulgu |
|---|---|---|
| 1 | `Mihrab/Features/Paywall/PaywallView.swift:29-32` | `privacyURL = "https://mihrab.app/privacy"` — **alan adı yayında değil.** Guideline 3.1.2 → kesin ret. Kodda `⚠️ Placeholder` yorumu da bunu söylüyor. Düzeltme satırı §1.3'te. |
| 2 | `Mihrab/Core/Subscription/SubscriptionManager.swift:124-190` | 12 `PremiumFeature` case'inden **10'u `.awaitingWiring`** — paywall satıyor, kod kilitlemiyor. Guideline 2.3.1 riski. Ayrıntı §5. |
| 3 | `MihrabWatch/`, `MihrabWatchWidgets/` | **`PrivacyInfo.xcprivacy` yok.** İki hedef de `UserDefaults` kullanıyor. iPhone/widget manifestleri var, watch'ta hiç yok. |

### 11.2 Yüksek

| # | Yer | Bulgu |
|---|---|---|
| 4 | `Mihrab/Data/PrayerEngine+AppSettings.swift:10-22` | **Çoklu şehirde saat dilimi hatası.** `PrayerEngineConfiguration.current()` saat dilimini her zaman **cihazın** diliminden alıyor; ne `SavedCity` ne `LocationManager` bir dilim taşıyor. Başka bir dilimdeki şehir elle seçildiğinde astronomi doğru, ama **her vakit cihazın saatiyle** gösteriliyor — saat ölçeğinde, kullanıcının fark etmesi imkânsız bir hata. Ve `multipleCities` **kilitli, yani parayla satılan** iki özellikten biri. Kodda çözüm de yazılı: `SavedCity`'ye `timeZoneIdentifier` ekle, `LocationManager.effectiveTimeZone` olarak yüzeye çıkar, buraya geçir. |
| 5 | `Mihrab/Data/PrayerSource.swift` | Fazilet Takvimi `isSelectable = false` ile **seçiciden çıkarıldı** ✅ (temkin değerleri doğrulanamadı; doğru karar). Aksiyon: mağaza metninde ve ekran görüntülerinde Fazilet **vaat edilmemeli**; kayıtlı değeri olan kullanıcı sessizce Diyanet'e düşüyor. |
| 6 | `Mihrab/Features/Settings/SettingsView.swift:400-408` | "Gizlilik" düğmesi gizlilik politikasını değil **iOS Ayarlar'ı** açıyor (`UIApplication.openSettingsURLString`). Kullanıcı uygulama içinden politikayı okuyamıyor. |
| 7 | `Mihrab/Resources/Fonts/` | **`OFL.txt` yok** — yalnızca `AmiriQuran-Regular.ttf` var. SIL Open Font License, yazı tipinin lisans metniyle birlikte dağıtılmasını şart koşar. Lisans ihlali. |
| 8 | Uygulama genelinde | **adhan-swift (MIT) telif bildirimi hiçbir yerde görünmüyor.** MIT, bildirimin dağıtımla birlikte verilmesini şart koşar. Ayarlar'a "Açık kaynak lisansları" ekranı gerekiyor. |
| 9 | `Mihrab/Info.plist` (`CFBundleShortVersionString`, `CFBundleVersion`) | Sürüm ve build **sabit yazılmış**, `project.yml`'deki değişkenleri kullanmıyor. Watch hedefi doğru yapıyor. Her yüklemede iki yeri elle güncellemek gerekiyor → unutulunca yükleme reddedilir. |
| 10 | `Mihrab/Info.plist` → `NSAlarmKitUsageDescription` | **Yalnızca İngilizce**, `InfoPlist.xcstrings`'e taşınmamış. Türk kullanıcı alarm izin diyaloğunu İngilizce görecek — konum ve kamera metinleri üç dilde çevrili, bu değil. |

### 11.3 Orta

| # | Yer | Bulgu |
|---|---|---|
| 11 | `Mihrab/Core/Subscription/SubscriptionManager.swift:244-246, 308-312` | `debugForcePremium` — `#if DEBUG` içinde ✅ **doğru korunmuş**, ama `UserDefaults` anahtarı `MihrabForcePremium` üzerinden okunuyor. Release archive'ında `DEBUG` tanımsız olduğu için binary'ye girmez; **yine de arşivin Release konfigürasyonuyla alındığını doğrula** (`project.yml` `DEBUG`'ı yalnızca Debug config'inde tanımlıyor ✅). |
| 12 | `NotificationEngine.swift:230-232,237-239`, `AlarmScheduler.swift:346-348` | Üç `print(` çağrısının **üçü de `#if DEBUG` içinde** ✅. Yayında gürültü yok. Bilgi amaçlı listelendi. |
| 13 | `Mihrab/Core/LocationManager.swift:208` | `locationManager(_:didFailWithError:)` **tamamen boş** — hata yutuluyor. Yorum gerekçelendiriyor ("önbellek geçerli kalır"), ama izin reddi ve `kCLErrorDenied` de buradan geçiyor ve kullanıcıya hiçbir şey söylenmiyor. En azından yetki hatası ayırt edilmeli. |
| 14 | `Mihrab/Data/AladhanClient.swift:76-83` | `fetch` üç denemede de başarısız olursa hata fırlatılıyor ✅, ama `catch` bloğu **her hatayı** eşit görüyor: 404 ile bağlantı kopması aynı şekilde 2-4-8 sn beklemeyle yeniden deneniyor. Kalıcı hatalarda gereksiz gecikme. |
| 15 | `Mihrab/Data/PrayerCacheStore.swift:189-192` | `catch` bloğu boş, yorumla gerekçelendirilmiş ("bellekteki kopya bu oturumu kurtarır"). Kabul edilebilir ama disk yazması **kalıcı** olarak başarısızsa kullanıcı hiç öğrenmiyor. |
| 16 | `Mihrab/Features/Quran/QuranMetadata.swift:150`, `Mihrab/Data/BundledContent.swift:93` | Gömülü JSON okunamazsa `fatalError` → **uygulama çöker.** Kaynak dosya build phase'den düşerse (widget/watch hedeflerinde bu kolayca olur) kullanıcı çökme yaşar. Dürüst bir boş durum tercih edilmeli. |
| 17 | `Mihrab/Data/Models/SwiftDataModels.swift:110-111` | `ModelContainer` kurulamazsa `fatalError`. CloudKit hesabı sorunlu bir cihazda **açılışta çökme** riski. En azından `.none` yapılandırmasına düşülmeli. |
| 18 | `Mihrab/Features/Settings/SettingsView.swift:434` | Geri bildirim adresi `mihrab.feedback@icloud.com` — bu adresin **gerçekten sizde olduğu doğrulanmalı.** Aynı adres artık gizlilik politikasında, destek sayfasında ve ASC'nin destek alanında da geçiyor. |
| 19 | Uygulama genelinde | **Aladhan ağ isteğini kapatan bir kullanıcı ayarı yok.** Cihaz üstü motor her koşulda çalışıyor, yani teknik olarak ağ tamamen isteğe bağlı olabilirdi. Gizlilik duruşunu ("sıfır veri") en sert biçimde savunacak ayar bu: *"Yalnızca cihazda hesapla"* anahtarı. v1'de şart değil, ama politikada bunun yerine "şehri elle seç" yolu anlatılmak zorunda kalındı. |
| 20 | `MihrabWidgets/DhikrCounterWidget.swift:94`, `MihrabWidgets/PrayerLiveActivity.swift:44` | `URL(string: "mihrab://dhikr")!` — zorunlu açma. Sabit ve geçerli oldukları için pratikte güvenli; yine de widget sürecinde çökme, kullanıcının ana ekranında boş kutu demektir. |

### 11.4 Bilgi (aksiyon gerektirmiyor)

- Kalan `⚠️` işaretleri (`SwiftDataModels.swift:22,123`,
  `PremiumEntitlement.swift:13`, `TrialReminder.swift:7`) **bilinçli
  uyarılardır** — kalması gereken notlar, yarım kalmış işler değil. Tek
  istisna `PaywallView.swift:29` (§11.1 madde 1) ve
  `PrayerEngine+AppSettings.swift:10` (§11.2 madde 4): bu ikisi gerçek iş.
- **Bu tur içinde başka ajanlar tarafından çözülenler** (doğrulandı, aksiyon
  gerekmiyor): `PrayerSource` içindeki dört `⚠️ VERIFY` işareti kalktı —
  Türkiye Takvimi parametreleri kaynaklandı, Fazilet geri çekildi;
  `ZakatCalculator` nisap değeri artık gerçek bir Diyanet fetvasına
  (`kurul.diyanet.gov.tr`) bağlı ve altın esası varsayılan.
- Widget/complication kodundaki `placeholder(in:)` fonksiyonları WidgetKit'in
  zorunlu API'si, yer tutucu metin değil.
- `TODO` / `FIXME` / `HACK` / `XXX` işareti **hiç yok**. Kod tabanı bu açıdan temiz.
- Üçüncü taraf SDK **yok**: analitik, reklam, attribution, çökme raporlama
  kütüphanesi hiç bulunmuyor. Tek dış paket `adhan-swift` (MIT), ağ açmıyor.
  `NSPrivacyTracking = false` beyanı **doğrulandı**.
- Ağ trafiği yalnızca `https://api.aladhan.com/v1` — depoda başka hiçbir
  uygulama içi uzak uç nokta yok.
