# Mihrab — Apple Platform Yüzeyleri ve Teknik Olgunluk Araştırması

> Tarih: 2026-08-23 · Kapsam: `Mihrab` (iOS 26, SwiftUI), `MihrabWidgets`, `MihrabTests`
> Yöntem: kaynak kod incelemesi (salt okuma) + Apple platform API araştırması
> Not: Bu belgedeki her "bulgu" satırı kodda **doğrulanmıştır** ve `dosya:satır` ile
> referanslanmıştır. "Öneri" satırları doğrulanmış bulgulara dayanan tekliflerdir.

---

## 0. Yönetici özeti

Mihrab'ın ürün ve tasarım katmanı olgun; **platform katmanı ise spesifikasyonun
epey gerisinde.** `MIHRAB.md:252-268` bir "widget + Live Activity + Control Center
+ App Intents + Apple Watch" yüzey matrisi vaat ediyor; kodda bunun yalnızca ilk
%30'u var. Bundan daha önemlisi: **mevcut yüzeyleri besleyen veri hattında,
uygulamanın en temel vaadini (namaz vakti bildirimi) sessizce bozan bir tarih
hatası var.**

Öncelik sırası:

| # | Konu | Efor | Etki |
|---|---|---|---|
| 1 | Aladhan tarih çözümleme hatası — tüm günler bugüne çöküyor | S | **Kritik** |
| 2 | Bildirimler yalnızca bugün için planlanıyor + arka plan yenileme yok | M | **Kritik** |
| 3 | `WidgetCenter.reloadAllTimelines()` hiç çağrılmıyor | S | Yüksek |
| 4 | CloudKit senkronu yok ama paywall'da satılıyor | M | Yüksek (App Review) |
| 5 | `PrivacyInfo.xcprivacy` yok | S | Yüksek (App Review) |
| 6 | App Intents / Siri / Control Center yüzeyi sıfır | M | Yüksek |
| 7 | Test hedefi mimarî olarak kritik kodu test edemiyor | M | Yüksek |
| 8 | Yerelleştirme 2.337 satır hardcoded Swift'e kilitli | L | Orta-Yüksek |

---

## 1. Widget'lar

### 1.1 Mevcut durum (doğrulanmış)

`MihrabWidgets/MihrabWidgetsBundle.swift:6-12` — bundle'da 5 giriş var:

| Widget | Aile | Konfigürasyon | Dosya |
|---|---|---|---|
| `PrayerTimesWidget` | `.systemSmall`, `.systemMedium` | `StaticConfiguration` | `PrayerTimesWidget.swift:40-49` |
| `LockScreenCircularWidget` | `.accessoryCircular` | `StaticConfiguration` | `LockScreenWidgets.swift:4-24` |
| `LockScreenRectangularWidget` | `.accessoryRectangular` | `StaticConfiguration` | `LockScreenWidgets.swift:27-64` |
| `LockScreenInlineWidget` | `.accessoryInline` | `StaticConfiguration` | `LockScreenWidgets.swift:67-80` |
| `PrayerLiveActivity` | — | `ActivityConfiguration` | `PrayerLiveActivity.swift` |

### 1.2 Bulgular

**B1.1 — `WidgetCenter.reloadAllTimelines()` kodun hiçbir yerinde çağrılmıyor.**
`grep -rn "WidgetCenter"` → 0 sonuç.
`PrayerTimesRepository.publishSnapshot()` (`PrayerTimesRepository.swift:107-119`)
App Group dosyasına yazıyor ama WidgetKit'e haber vermiyor. Sonuç: kullanıcı
şehir/yöntem/mezhep değiştirdiğinde widget bir sonraki kendi timeline yenilemesine
kadar (en fazla 1 saat, `PrayerTimesWidget.swift:33-35`) **eski şehrin vakitlerini
gösteriyor.**
→ **Öneri:** `publishSnapshot()` sonuna `WidgetCenter.shared.reloadAllTimelines()`.
Ayrıca `AppSettings` içindeki `calculationMethod`/`madhab` `didSet`'lerine de.
**Efor: S · Etki: Yüksek**

**B1.2 — Widget galerisi metinleri sabit İngilizce.**
`PrayerTimesWidget.swift:46-47` (`"Prayer Times"`, `"Next prayer countdown…"`),
`:87` (`"Open Mihrab"`), `LockScreenWidgets.swift:21-22, 55, 61-63, 72, 77-78`.
Türk ve Arap kullanıcı, widget ekleme galerisinde İngilizce metin görüyor.
Sebep yapısal: `project.yml:69-70` widget hedefine yalnızca `MihrabWidgets` +
`Mihrab/Core/Shared` veriyor; `L10n.swift` orada olduğu için `prayer.localizedName`
çalışıyor ama widget'ın kendi başlıkları hiç `L10n`'e uğramamış.
→ **Öneri:** `configurationDisplayName`/`description` için `L10n` kullan; galeri
metinleri `LocalizedStringResource` ile de verilebilir. **Efor: S · Etki: Orta**

**B1.3 — `containerBackground` sabit renk.**
`PrayerTimesWidget.swift:44` → `.containerBackground(MihrabColor.abyss, for: .widget)`.
iOS 18+ ana ekran widget'ları kullanıcı tarafından **tint'lenebiliyor**
(`.widgetRenderingMode == .accented`) ve iOS 26 Liquid Glass görünümünde widget
arka planı sistem tarafından yeniden boyanıyor. Sabit `abyss` rengi bu modlarda
okunaksız/renksiz kutu üretir. `grep "widgetRenderingMode"` → 0 sonuç.
→ **Öneri:** `@Environment(\.widgetRenderingMode)` ile `.accented` modda
`containerBackground(.fill.tertiary, for: .widget)` + `.widgetAccentable()`
işaretlemesi. **Efor: S · Etki: Orta**

**B1.4 — Widget'lar konfigüre edilemiyor.**
Hepsi `StaticConfiguration`. Kullanıcı ne şehir ne de hangi vakit gösterileceğini
seçebiliyor. Oysa `SubscriptionManager.swift:73` `multipleCities`'i premium olarak
satıyor.
→ **Öneri:** `AppIntentConfiguration` + `WidgetConfigurationIntent`'e geçir;
`CityEntity: AppEntity` + `EntityQuery` ile şehir seçimi. Bu aynı zamanda App
Intents altyapısını (bkz. §3) bedavaya getirir. **Efor: M · Etki: Yüksek**

### 1.3 Eksik widget yüzeyleri (öneriler)

| Yüzey | API | Fikir | Efor | Etki |
|---|---|---|---|---|
| `.systemLarge` | WidgetKit | Günün tam vakit tablosu + güneş yayı + hicri tarih | S | Orta |
| `.systemExtraLarge` (iPad) | WidgetKit | Aylık takvim şeridi | S | Düşük |
| **Control Center / Kilit ekranı / Action Button** | `ControlWidget` (iOS 18+) | **"Kıbleyi aç"** (`ControlWidgetButton` → `OpenQiblaIntent`), **"Zikre başla"** (`OpenDhikrIntent`), **"Zikir +1"** (`ControlWidgetButton` → `IncrementDhikrIntent`, uygulamayı açmadan), **"Bildirimleri sustur"** (`ControlWidgetToggle`) | M | **Yüksek** |
| **İnteraktif widget** | `Button(intent:)` iOS 17+ | Ana ekran zikirmatik: widget üzerinde +1, sayaç App Group'ta artar, `reloadAllTimelines` ile anında güncellenir. Bu, `MIHRAB.md:266`'daki "Log 33 Subhanallah" vaadinin en doğal karşılığı | M | **Yüksek** |
| **Namaz kıldım işaretle** | `Button(intent:)` | Medium widget'ta bugünkü vakit satırına dokunup kılındı işaretlemek (`PrayerLogStore` zaten var: `Mihrab/Features/Today/PrayerLogStore.swift`) | M | Yüksek |
| **StandBy** | `.systemSmall` otomatik | Zaten `.systemSmall` desteklendiği için StandBy'da görünür; ancak StandBy gece kırmızı modunda `MihrabColor.mint` okunmuyor. `@Environment(\.widgetRenderingMode)` ile `.vibrant` durumunu ele al | S | Orta |
| **Smart Stack alaka düzeyi** | `RelevantContext` / `TimelineEntryRelevance` | Vakte 20 dk kala widget'ı yığında öne çıkar; Cuma sabahı Cuma kartını öne çıkar | M | Orta |
| **Apple Watch komplikasyonları** | `.accessoryCorner`, `.accessoryCircular`, `.accessoryRectangular`, `.accessoryInline` | Bkz. §4 | — | — |

> **Not (paywall tutarsızlığı):** `PaywallView.swift:138` "gelişmiş widget'lar"ı
> premium olarak satıyor, ama `advancedWidgets` enum case'i (`SubscriptionManager.swift:63`)
> kodda **hiçbir yerde kontrol edilmiyor** (`grep "\.advancedWidgets"` → 0 kullanım).
> Bkz. §9.3.

---

## 2. Live Activity & Dynamic Island

### 2.1 Mevcut durum

`PrayerLiveActivity.swift` — kilit ekranı sunumu + Dynamic Island'ın dört bölgesi
(expanded leading/trailing/bottom, compactLeading/compactTrailing, minimal) doldurulmuş.
`PrayerActivityAttributes` (`Mihrab/Core/Shared/PrayerActivityAttributes.swift`)
üç alan taşıyor: `prayerName`, `prayerArabic`, `prayerTime`.
`project.yml:57-58` `NSSupportsLiveActivities` **ve** `…FrequentUpdates` açık.

### 2.2 Bulgular

**B2.1 — Live Activity hayat döngüsü fiilen çalışmıyor. (Kritik)**
`LiveActivityManager.update(for:tomorrow:)` **tek bir yerden** çağrılıyor:
`RootView.swift:43`, o da `.task` içinde — yani **uygulama açılışında bir kez.**
`grep -rn "LiveActivityManager.shared"` → tek eşleşme.

Sonuçları:
- Kullanıcı uygulamayı vakte 30 dakikadan erken açarsa (`LiveActivityManager.swift:21-22`
  penceresi) Live Activity **hiç başlamaz**. Yani en yaygın senaryoda ürün özelliği yok.
- Bir kez başlarsa, vakit geçtikten sonra `end()` çağıran ikinci bir tetik olmadığı
  için **kilit ekranında asılı kalır** (`staleDate` sadece soluklaştırır, kaldırmaz).
- `.onChange(of: scenePhase)` yok (`grep` → yalnızca `DhikrView.swift:13`).
- `pushType: nil` (`LiveActivityManager.swift:39`) — uzaktan güncelleme yok, dolayısıyla
  `NSSupportsLiveActivitiesFrequentUpdates: YES` bayrağının hiçbir karşılığı yok.

→ **Öneri (S, Kritik):** `MihrabApp` seviyesinde `.onChange(of: scenePhase)` +
uygulama arka plana geçerken `BGAppRefreshTask` içinde `update()` çağrısı; ayrıca
`ActivityContent.staleDate` yerine `alertConfiguration` ve
`activity.end(dismissalPolicy: .after(prayerTime + 15dk))` kullanılmalı.

**B2.3 — `Date()` render anında okunuyor.**
`PrayerLiveActivity.swift:18, 33, 47` → `SafeCountdown.range(from: Date(), to:)`.
Widget extension'ında `Date()` render zamanıdır; `Text(timerInterval:)` zaten kendi
kendine sayar, dolayısıyla bu çalışır — ancak `range` `nil` döndüğü an (vakit geçti)
sayaç **tamamen kaybolur**, "vakit girdi" durumu hiç gösterilmez.
→ **Öneri:** `ContentState`'e `phase: .counting / .entered` ekle; vakit girince
30 dakika boyunca "Akşam vakti girdi" göster, sonra kapat. **Efor: S · Etki: Orta**

### 2.3 Live Activity fikirleri

| Fikir | Ayrıntı | Efor | Etki |
|---|---|---|---|
| **İftar/Sahur geri sayımı (Ramazan)** | Ramazan boyunca gün boyu açık kalan tek bir aktivite: gündüz iftara, gece imsağa sayar. `RamadanHubView.swift` verisi hazır. Dynamic Island minimal'de hilal, compact'ta saat. Ramazan'da ürünün en görünür yüzeyi bu olur. | M | **Yüksek** |
| **Vakit girdi bildirimi** | Vakit girince aktiviteyi 20-30 dk "vakit girdi + kıldım butonu" durumuna geçir (`Button(intent: LogPrayerIntent)` — Live Activity iOS 17+ interaktif). | M | Yüksek |
| **Zikir oturumu** | Uzun zikir (khatm-i tehlil vb.) sırasında Dynamic Island'da ilerleme halkası; `Button(intent: IncrementDhikrIntent)` ile ekran kapalıyken sayma. | M | Orta |
| **Cuma hutbesi hatırlatıcısı** | Cuma sabahı başlayıp Cuma vaktinde biten aktivite. | S | Düşük |
| **Apple Watch'a taşıma** | `ActivityConfiguration` içinde `.supplementalActivityFamilies([.small])` — watchOS 26, iPhone'daki Live Activity'yi Smart Stack'te gösterir. Watch uygulaması yazmadan saatte varlık kazanmanın en ucuz yolu. | S | **Yüksek** |
| **Uzaktan güncelleme** | `pushType: .token` + APNs Live Activity push. Sunucu gerektirir; şu an gereksiz — cihazda `BGAppRefreshTask` yeterli. | L | Düşük |

> **Süre limiti uyarısı:** Bir Live Activity kullanıcı etkileşimi olmadan 8 saat
> sonra güncellenemez, 12 saat sonra sistem tarafından kaldırılır. İftar geri sayımı
> fikri bu yüzden günde iki kez (iftar sonrası / sahur sonrası) yeniden başlatılmalı.

---

## 3. App Intents & Siri

### 3.1 Mevcut durum

**Sıfır.** `grep -rn "AppIntent\|AppShortcut"` → 0 sonuç. `MIHRAB.md:266` ve
`MIHRAB.md:310` (`MihrabIntents` hedefi) planlanmış ama hiç yazılmamış.

Bu, ürünün Apple ekosistemindeki en büyük **kullanılmamış** kaldıracı: App Intents
tek bir tanımla aynı anda Siri, Kısayollar, Spotlight, Action Button, Control Center
ve interaktif widget yüzeylerini besliyor.

### 3.2 Önerilen intent seti

| Intent | Tetik | Kullanım | Efor |
|---|---|---|---|
| `NextPrayerIntent` | "Bir sonraki namaz ne zaman?" | `ReturnsValue<String>` + `SnippetIntent` görsel yanıt (geri sayım kartı) | S |
| `PrayerTimeIntent(prayer:)` | "Akşam ezanı saat kaçta?" | `@Parameter` ile `PrayerEntity: AppEnum` | S |
| `QiblaDirectionIntent` | "Kıble nerede?" | Derece + yön adı döndür, snippet'te pusula | S |
| `IncrementDhikrIntent(amount:)` | "33 Sübhanallah say" | SwiftData'ya yazar, widget'ı yeniler. **Widget + Control Center + Siri aynı intent'i paylaşır** | M |
| `LogPrayerIntent(prayer:)` | "Öğle namazını kıldım olarak işaretle" | `PrayerLogStore` üzerinden | S |
| `OpenQiblaIntent` / `OpenDhikrIntent` | Action Button, Control Center | `OpenIntent` + `@Dependency` ile tab seçimi | S |
| `TodayHadithIntent` | "Bugünün hadisi" | `BundledContent.hadith()` — snippet'te paylaşılabilir kart | S |
| `IftarCountdownIntent` | "İftara ne kadar var?" | Ramazan sezonluk | S |

**Uygulama notları:**
- `AppShortcutsProvider` ile **10 adede kadar** kısayol, kullanıcı kurulum yapmadan
  Siri ve Spotlight'ta görünür. `phrases` içinde `\(.applicationName)` zorunlu —
  Türkçe cümle kalıplarını (`"Mihrab'da kıble"`, `"\(.applicationName) sıradaki vakit"`)
  ayrıca yazmak gerekir.
- **Spotlight:** `AppEntity`'ler `IndexedEntity`'e uydurulunca (Esmaül Hüsna'nın 99
  ismi, adhkar kütüphanesi) sistem araması içinden doğrudan içerik açılabilir.
  99 isim için bu, keşfedilebilirlik açısından çok değerli. **Efor: M · Etki: Yüksek**
- **Apple Intelligence:** `@AssistantIntent` şema alanları çoğunlukla posta/foto/
  tarayıcı gibi hazır alanlar için; ibadet alanı için hazır şema yok. Ancak
  `SnippetIntent` (iOS 26) ile Siri'nin doğrudan uygulama içi görsel kart döndürmesi
  mümkün — "Kıble nerede?" sorusuna küçük bir pusula kartı döndürmek, bu ürün için
  çok yüksek etkili bir demo yüzeyi.
- **Action Button:** ayrı iş yok — `AppShortcutsProvider`'daki intent'ler otomatik
  olarak Action Button ve Control Center listesinde belirir.

**Toplam efor: M (yaklaşık 2-3 gün) · Etki: Yüksek.** Bu tek kalem, "widget/Watch"
işlerinden önce yapılmalı çünkü diğer tüm yüzeyler onu yeniden kullanıyor.

---

## 4. Apple Watch uygulaması

### 4.1 Mevcut durum

Watch hedefi **yok**. `project.yml:33-97` üç hedef tanımlıyor: `Mihrab`,
`MihrabWidgets`, `MihrabTests`. `MIHRAB.md:264` ve `:310` `MihrabWatch` hedefi
öngörüyor.

### 4.2 Neden nispeten ucuz

Kritik olan şu: **veri modeli ve iş mantığı zaten paylaşılabilir durumda.**
`Mihrab/Core/Shared/` klasörü (`PrayerModels.swift`, `SharedPrayerCache.swift`,
`L10n.swift`, `CountdownText.swift`, `DesignTokens.swift`, `Locale+Mihrab.swift`)
saf Foundation/SwiftUI ve zaten iki hedefte birden derleniyor (`project.yml:70, 87`).
Bir watchOS hedefine aynı klasörü vermek yeterli.

Tek engel: `SharedPrayerCache` App Group dosyası **iPhone'daki** container'ı okuyor;
Watch ayrı bir cihaz. Veri köprüsü gerekir.

### 4.3 Kapsam ve efor

| Aşama | İçerik | Efor | Etki |
|---|---|---|---|
| **Aşama 0 — bedava varlık** | `ActivityConfiguration`'a `.supplementalActivityFamilies([.small])` ekle → iPhone Live Activity watchOS 26 Smart Stack'te görünür. Watch hedefi gerekmez. | **S** | Yüksek |
| **Aşama 1 — komplikasyonlar** | watchOS WidgetKit hedefi: `.accessoryCircular` (sıradaki vakit), `.accessoryCorner` (geri sayım), `.accessoryRectangular` (vakit + şehir), `.accessoryInline`. Veri: `WatchConnectivity` `transferCurrentComplicationUserInfo` veya doğrudan CloudKit. | **M** | **Yüksek** |
| **Aşama 2 — vakitler uygulaması** | Tek ekran: sıradaki vakit + günün listesi. Always-On Display için düşük fps varyant. | **M** | Yüksek |
| **Aşama 3 — zikirmatik** | `digitalCrownRotation` ile sayma + `WKInterfaceDevice.current().play(.click)` haptik; tam ekran sayaç. Bilekte zikir, ürünün en doğal Watch özelliği. | **M** | **Yüksek** |
| **Aşama 4 — kıble haptik yönlendirme** | Watch'ta `CLLocationManager` heading; hizalandıkça haptik sıklığı artar, ±3°'de `.success`. Ekrana bakmadan kıble bulma — güçlü bir farklılaştırıcı ve erişilebilirlik kazancı. | **M-L** | Yüksek |
| **Aşama 5 — bildirimler** | iPhone bildirimleri Watch'a zaten yansıyor; `UNNotificationContentExtension` ile özel görünüm opsiyonel. | S | Düşük |

**Toplam gerçekçi efor: L (Aşama 0-3 için ~1-1,5 hafta, Aşama 4 dahil ~2 hafta).**

**Senkron kararı:** Watch için `WatchConnectivity` (`transferUserInfo`) en basiti,
ama tek başına yeterli değil — iPhone erişilemezken komplikasyon boş kalır. Doğru
çözüm: (a) Watch'a 7 günlük vakit anlık görüntüsünü `transferUserInfo` ile it,
**veya** (b) §6'daki cihaz-içi Adhan hesabını Watch'ta da çalıştır — o zaman Watch
tamamen bağımsız olur. **(b) şiddetle tavsiye edilir**; §6 zaten yapılması gereken iş.

---

## 5. iPad / Mac / Vision Pro

### 5.1 Mevcut durum (doğrulanmış)

`project.yml:47` → `TARGETED_DEVICE_FAMILY: "1"` — **yalnızca iPhone.**
`project.yml:50` → `UIInterfaceOrientationPortrait` — yalnızca dikey.
Yani iPad'de uyumluluk modunda küçük bir kutu olarak, Apple Silicon Mac'te ise
"iPhone/iPad uygulamaları" listesinde çalışır (geliştirici izin verirse).

### 5.2 Değerlendirme

| Platform | Değer | Gereken düzen işi | Efor | Etki |
|---|---|---|---|---|
| **iPad** | **Yüksek.** Ev/cami ortamında duvara asılı iPad'de vakit ekranı gerçek bir kullanım. Ramazan'da özellikle. | `TARGETED_DEVICE_FAMILY: "1,2"`; `TabView` → `NavigationSplitView` (geniş sınıfta); `TimesView` aylık tablosu iPad'de asıl kazançlı ekran; `.systemExtraLarge` widget; landscape desteği; `MosquesView` harita + liste yan yana. `DhikrView` ve `QiblaCompassView` merkezî sabit genişlikte kalabilir. | **M** | Yüksek |
| **Mac (Catalyst)** | Düşük-orta. Masaüstünde namaz vakti bir menü çubuğu işi, pencere işi değil. | Catalyst yerine **iPad uygulamasını Apple Silicon Mac'te açmaya izin ver** (sıfır iş). Gerçek değer isteniyorsa ayrı, küçük bir **menü çubuğu uygulaması** (`MenuBarExtra`) — sıradaki vakit + geri sayım. | S (izin) / M (MenuBarExtra) | Düşük-Orta |
| **Vision Pro** | Düşük (şimdilik). Kıble AR'ın uzamsal karşılığı ilginç ama pazar küçük ve namaz kılarken headset takmak gerçekçi değil. | — | L | Düşük |

**Karar önerisi:** iPad'i yap (M), Mac'te "iPad uygulaması çalışsın" kutusunu işaretle
(S), Vision Pro'yu ertele. Ayrıca `project.yml:50` dikey kilidi iPhone'da bile
`TimesView` aylık tablosu için yatay moda izin vermeyi engelliyor — orası tek
istisna olarak düşünülebilir.

---

## 6. Veri & senkronizasyon

### 6.1 Bulgu: Aladhan tarih çözümleme hatası — **Kritik**

`Mihrab/Data/AladhanClient.swift:127-151`. Kod şöyle:

```swift
var dayDate = calendar.startOfDay(for: Date())
if let g = date.gregorian?.date {
    …
    if let parsed = dayFormatter.date(from: g) {
        dayDate = calendar.startOfDay(for: parsed)      // ← doğru gün burada
    }
}
for (prayer, key) in map {
    …
    let dayStart = calendar.startOfDay(for: Date())     // ← her zaman BUGÜN
    guard let combined = calendar.date(bySettingHour: …, of: dayStart) else { … }
    result[prayer] = combined
    dayDate = dayStart                                  // ← doğru gün eziliyor
}
```

`dayStart` API'den gelen tarihi değil, **her zaman bugünü** kullanıyor; ve döngünün
son satırı (`:151`) yukarıda doğru hesaplanan `dayDate`'i de eziyor.

**Sonuç zinciri (hepsi doğrulanmış kod yollarıdır):**

1. `AladhanClient.calendar(...)` ile çekilen **tüm ay** — 28-31 gün — aynı tarihe
   (bugün) ve aynı saat damgalarına çöker.
2. `PrayerTimesRepository.prefetchMonth` (`:95-105`) bunları
   `memoryCache[cacheKey(for: day.date)]` altına yazar; `cacheKey` tarihe dayalı
   (`:22-30`) olduğu için **31 gün tek bir anahtara** yazılır → ayın 30 günü kaybolur.
3. `publishSnapshot()` (`:107-119`) tek günlük bir "ay" yayınlar.
4. `NotificationEngine.rescheduleAll()` (`NotificationEngine.swift:24-35`) bu
   snapshot üzerinde döner ve `time > Date()` filtresiyle **yalnızca bugünün kalan
   vakitlerini** planlar → en fazla 5 bildirim. Doküman başlığındaki "10 gün
   ileriye planlama" (`NotificationEngine.swift:4`) fiilen çalışmıyor.
5. `PrayerTimesRepository.refresh()` (`:45-49`) `tomorrow`'u da API'den çekiyor ama
   dönen nesnenin tarihleri **bugüne** ait → `nextPrayer(after:tomorrow:)` gece
   yarısından sonra geçmişte bir tarih döndürebilir.
6. `MonthlyTimesView` / `InlineMonthTable` aylık tabloyu bu veriden çiziyor.

**Bu hata, ürünün tek bir kritik vaadini bozuyor:** kullanıcı uygulamayı her gün
açmazsa ertesi gün namaz bildirimi almıyor.

→ **Düzeltme:** `dayStart` yerine `dayDate` kullan, `:151`'deki atamayı sil,
`DayPrayerTimes(date: dayDate, …)` döndür. **Efor: S · Etki: Kritik.**
Ayrıca `DateFormatter`'ların her çağrıda yeniden kurulması (`:29-31, :121-123, :129-132`)
sıcak yolda gereksiz maliyet — `static let` yap.

### 6.2 Bulgu: SwiftData'da CloudKit **yok**, ama satılıyor — **App Review riski**

- `Mihrab/Data/Models/SwiftDataModels.swift:48` → `try? ModelContainer(for: schema)`.
  `ModelConfiguration(… cloudKitDatabase: .automatic)` **yok**.
- `Mihrab/Mihrab.entitlements` → yalnızca `application-groups`. `com.apple.developer.icloud-services`
  / `icloud-container-identifiers` **yok**.
- Buna rağmen:
  - `SwiftDataModels.swift:4` doküman yorumu: "Synced via CloudKit when available."
  - `SubscriptionManager.swift:74` → `case iCloudBackup` premium özelliği.
  - `L10n+Paywall.swift:305` → paywall'da "iCloud yedekleme" olarak listeleniyor.
  - `L10n+Settings.swift:125-127` → Ayarlar'da "yalnızca kendi iCloud'un üzerinden
    eşitlenir" deniyor.

Yani **var olmayan bir özellik ücretli olarak tanıtılıyor.** Bu, App Store Review
Guideline 2.3.1 (accurate metadata) ve 3.1.2 kapsamında reddedilme sebebidir.

→ **İki seçenekten biri, mutlaka:**
  - **(a) Uygula (M):** iCloud entitlement + `ModelConfiguration(cloudKitDatabase: .private("iCloud.com.caferkarakaya.mihrab"))`.
    **Şema uyumluluk şartları:** CloudKit ile SwiftData'da tüm özellikler ya opsiyonel
    ya varsayılan değerli olmalı, `@Attribute(.unique)` kullanılamaz, ilişkiler
    opsiyonel olmalı. Mevcut üç model (`DhikrSession`, `FavoriteHadith`,
    `KhatamProgress`) **zaten bu kurallara uyuyor** — hepsinin varsayılanı var,
    unique yok, ilişki yok. Yani geçiş gerçekten ucuz.
  - **(b) Kaldır (S):** `iCloudBackup`'ı premium listesinden ve paywall metninden çıkar,
    `SwiftDataModels.swift:4` yorumunu düzelt, `L10n+Settings.swift:125-127`'yi
    "cihazda saklanır" olarak değiştir.

**Ek kazanç:** (a) yapılırsa Apple Watch senkronu (§4) ve çoklu cihaz aynı anda
çözülür. **Bu yüzden (a) tavsiye edilir.**

### 6.3 Bulgu: Aladhan API'ye tam bağımlılık, cihaz-içi hesap yok

`PrayerTimesRepository` her vakit için ağa gidiyor. `refresh()` (`:44-60`) hata
durumunda `SharedPrayerCache`'e düşüyor ("stale-while-error"), ama:

- Önbellek §6.1 hatası yüzünden yalnızca **bugünü** içeriyor → yarın uygulama
  vakitsiz açılır.
- `AladhanClient.fetch` (`:69-86`) 3 deneme × 15 sn timeout + 1s/2s bekleme →
  çevrimdışı kullanıcı **en kötü ~50 saniye** boş ekran bekler; `NWPathMonitor`
  veya `waitsForConnectivity` kontrolü yok.
- Aladhan ücretsiz, sözleşmesiz, SLA'sız bir üçüncü taraf servisi. Kesinti = tüm
  kullanıcı tabanı için vakit yok. Bir ibadet uygulaması için kabul edilemez bir
  tek arıza noktası.

→ **Öneri (Yüksek öncelik):** `batoulapps/adhan-swift` (MIT, Swift Package) paketini
ekle ve **birincil hesaplayıcı** yap; Aladhan'ı yalnızca (i) hicri tarih doğrulaması
ve (ii) Diyanet gibi API'ye özgü yöntemler için ikincil kaynak olarak tut.

- Adhan kütüphanesi MWL, Egyptian, Karachi, Umm al-Qura, Dubai, MoonsightingCommittee,
  NorthAmerica (ISNA), Kuwait, Qatar, Singapore, Tehran, Turkey yöntemlerini,
  Shafi/Hanafi madhab'ını, yüksek enlem kurallarını (`HighLatitudeRule`) ve sünnet
  vakitlerini (`SunnahTimes`: gece yarısı, son üçte bir) destekliyor. `Qibla` hesabı da var.
- Mevcut `CalculationMethod` enum'u (`PrayerModels.swift:105+`) Aladhan sayı ID'lerine
  bağlı (`diyanet = 13`); Adhan'a eşleme tablosu gerekir.
- **Uyarı:** Türkiye'de Diyanet vakitleri saf astronomik hesaptan farklıdır (özellikle
  yatsı/imsak, yüksek enlem düzeltmeleri). Adhan'ın `.turkey` yöntemi yaklaşır ama
  birebir tutmaz. Bu yüzden strateji: **Aladhan varsa onu kullan (doğruluk), yoksa
  Adhan ile hesapla (dayanıklılık)** ve kullanıcıya "çevrimdışı hesaplanmış vakit"
  rozetini göster.
- Yan fayda: Watch uygulaması ve widget'lar ağsız çalışır; bildirimler 30 gün ileri
  planlanabilir; test edilebilir saf fonksiyon (bkz. §10).

**Efor: M · Etki: Yüksek**

### 6.4 Diğer

- `SharedPrayerCache` App Group dosyasına `try? data.write(…, .atomic)` ile yazıyor
  (`:38-42`) — `.completeFileProtectionUntilFirstUserAuthentication` belirtilmemiş.
  Cihaz kilitliyken widget okuması dosya koruması nedeniyle başarısız olabilir.
  → `.noFileProtection` veya `…UntilFirstUserAuthentication` ile yaz. **Efor: S · Etki: Orta**
- `publishSnapshot()` `memoryCache.values`'un tamamını yazıyor (`:109`) — çok şehir
  gezildiğinde snapshot şişer ve **karışık koordinatlardan** gelen günleri barındırır.
  Snapshot içindeki `latitude/longitude` tek bir değer olduğu için tutarsızlık oluşur.
  → Snapshot'ı yalnızca güncel koordinatın günleriyle sınırla. **Efor: S · Etki: Orta**

---

## 7. Performans & pil

### 7.1 Bulgu: Konum güncellemeleri sınırsız ve her güncelleme ağ isteği tetikliyor

- `LocationManager.swift:27-28` → `desiredAccuracy = kCLLocationAccuracyHundredMeters`,
  **`distanceFilter` ayarlanmamış** (varsayılan `kCLDistanceFilterNone` = her hareket).
- `LocationManager.swift:36-38` → `startUpdatingLocation()`; kodda **hiçbir yerde
  `stopUpdatingLocation()` yok** (`grep` → 0 sonuç). Uygulama ön planda olduğu sürece
  GPS sürekli çalışıyor.
- `LocationManager.swift:80` → her konum güncellemesinde `reverseGeocode` (CLGeocoder
  Apple tarafından hız-sınırlıdır; `isGeocoding` guard'ı sadece eşzamanlılığı önler).
- `RootView.swift:45-50` → `.onChange(of: locationManager.location)` her güncellemede
  `repository.refresh()` çağırıyor.
- `PrayerTimesRepository.refresh()` → `prefetchMonth` (`:51`) her seferinde
  `api.calendar(...)` yani **tam aylık API çağrısı** yapıyor; `memoryCache` kontrolü
  yok, yalnızca `URLCache` yardımcı olur.

**Net etki:** Yürüyen bir kullanıcıda saniyede birkaç konum → onlarca reverse-geocode
+ onlarca aylık API çağrısı. Pil ve ağ açısından ciddi.

→ **Öneri:** `distanceFilter = 3000` (3 km — vakitler için fazlasıyla yeterli);
ekran arkaya gidince `stopUpdatingLocation()`; `refresh()`'i son çalışmadan bu yana
en az X dakika/Y kilometre geçtiyse çalıştıran bir throttle; `prefetchMonth`'u
günde bir kez. **Efor: S · Etki: Yüksek**

### 7.2 Bulgu: Arka plan yenileme **hiç yok**

`grep -rn "BGTaskScheduler\|BackgroundTasks"` → 0 sonuç. `project.yml` içinde
`UIBackgroundModes` yok. Yani:
- Bildirim kuyruğu yalnızca uygulama açıldığında yenileniyor.
- Widget verisi yalnızca uygulama açıldığında tazeleniyor.
- Live Activity yalnızca uygulama açıldığında yönetiliyor (§2.1).

→ **Öneri:** `BGAppRefreshTaskRequest` (günde 1-2 kez) kaydet: vakitleri tazele →
snapshot yaz → `WidgetCenter.reloadAllTimelines()` → `NotificationEngine.rescheduleAll()`
→ `LiveActivityManager.update()`. **Efor: M · Etki: Yüksek**

### 7.3 Bulgu: Bildirim 64 limiti — kısmen doğru yönetiliyor, ama riskli

`NotificationEngine.rescheduleAll()`:
- `:21` → `removeAllPendingNotificationRequests()` ile temizliyor (doğru yaklaşım).
- `:29` → `guard scheduled < 50` ile namaz bildirimlerini 50'de kesiyor (bilinçli
  ve doğru bir tasarım).

**Ancak:**

1. **50 sabit bir üst sınır değil, toplamın parçası.** Üstüne eklenenler:
   `daily-hadith` (`:77`, `repeats: true` → 1 slot), `jumuah` (`:110`, `repeats: true` → 1 slot),
   ve **religious-day'ler: 30 gün içindeki her dinî gün için 2 bildirim** (`:84-97`).
   `BundledContent.religiousDays` ≥ 10 kayıt içeriyor (`MihrabTests.swift:119`).
   Ramazan/Recep gibi kandil kümelenmesi olan aylarda 30 günlük pencereye 4-6 dinî
   gün düşebilir → 8-12 slot. Toplam: 50 + 1 + 1 + 12 = **64'ün tam sınırında.**
   Sınır aşılınca iOS **sessizce reddeder** ve `center.add(request)` completion
   handler'ı hiç kontrol edilmiyor (`:64, :77, :95, :110` — hepsi sonucu yok sayıyor).
2. **`TrialReminder` bildirimleri her açılışta siliniyor.** (Aşağıda B7.4.)
3. **Doğrulama yok:** `getPendingNotificationRequests` hiç çağrılmıyor; kaç bildirimin
   gerçekten kuyruğa girdiği bilinmiyor.

→ **Öneri:** Bütçeyi merkezîleştir — `let budget = 60` üzerinden namaz (40) + dinî
gün (12) + sabit (2) olarak böl; `add(_:withCompletionHandler:)` hatalarını logla;
sonda `getPendingNotificationRequests().count` ile doğrula. §6.1 düzeltildikten sonra
bu limit **gerçekten** baskı yapmaya başlayacak (şu an hata yüzünden sadece ~5 bildirim
planlanıyor, yani limit hiç test edilmedi). **Efor: S · Etki: Yüksek**

### 7.4 Bulgu: Deneme süresi hatırlatıcıları her açılışta siliniyor — **doğrulanmış**

`TrialReminder.swift:7-11` kendi doküman yorumunda uyarıyor:
> "`NotificationEngine.rescheduleAll()` calls `removeAllPendingNotificationRequests()`,
> which also clears these. Call `TrialReminder.ensureScheduled()` after any reschedule…"

`grep -rn "ensureScheduled"` → **yalnızca tanımı** (`TrialReminder.swift:52`).
**Hiçbir yerden çağrılmıyor.**

Akış: kullanıcı denemeyi başlatır (`SubscriptionManager.swift:263` hatırlatıcıları
kurar) → uygulamayı bir sonraki açışında `RootView.swift:42` `rescheduleAll()`
çalışır → `NotificationEngine.swift:21` hepsini siler → **deneme bitiş uyarısı asla
gitmez.**

Bu, `PRICING.md`'de açıkça verilen etik sözü ("denemenin bitişinden önce hatırlatma
bildirimi gönderiliyor") ihlal ediyor.

→ **Düzeltme:** `rescheduleAll()` sonuna `TrialReminder.ensureScheduled(trialStart:
SubscriptionManager.shared.trialStartedAt)`. Daha sağlamı: `removeAllPendingNotificationRequests()`
yerine yalnızca `mihrab-` öneki taşıyan kimlikleri hedefli silen bir yardımcı.
**Efor: S · Etki: Yüksek**

### 7.5 Shader / animasyon maliyeti

- `ShaderMotif.swift:116` → varsayılan `fps: 24`; `:124` `TimelineView(.animation(
  minimumInterval: 1/fps, paused: reduceMotion))`.
- `ShaderPanel.swift:34, 107` → panel önizlemelerinde 12 / 20 / 10 fps (iyi ayarlanmış).
- `AppearanceSettingsSection` ayarlar ekranında **aynı anda birden çok** canlı
  shader önizlemesi gösteriyor (`ShaderPanel.swift:107` `isSelected ? 20 : 10`) —
  seçili olmayanlar da çalışıyor.
- `reduceTransparency` 13 yerde dikkate alınmış (iyi).
- **`ProcessInfo.processInfo.isLowPowerModeEnabled` hiç kontrol edilmiyor**
  (`grep` → 0 sonuç). Düşük Güç Modu'nda shader'lar tam hızda dönmeye devam ediyor.
- `repeatForever` animasyonları 4 yerde var; `PaywallView.swift:59-61` 14 saniyelik
  sonsuz hale animasyonu — paywall açık kaldıkça çalışır.

→ **Öneri:** Global `MihrabMotion.isEnergySaving` (lowPowerMode || reduceMotion ||
thermalState ≥ .serious) ve tüm `TimelineView`/`repeatForever` çağrılarını buna bağla;
görünür olmayan shader panellerini `.onDisappear`'da durdur.
**Efor: S · Etki: Orta**

---

## 8. Erişilebilirlik & yerelleştirme

### 8.1 VoiceOver — beklenenden iyi

Sayılar (doğrulanmış): `accessibilityLabel` 50, `accessibilityElement` 33,
`accessibilityHidden` 26, `accessibilityAddTraits` 18, `accessibilityHint` 13,
`accessibilityValue` 5.

Öne çıkanlar:
- Kıble pusulası birleşik bir öğe + özet etiketi taşıyor (`QiblaCompassView.swift:181-182, 267-270`).
- Zikirmatik `accessibilityAdjustableAction` ile Digital-Crown benzeri artır/azalt
  destekliyor (`DhikrCounterViews.swift:207`, `DhikrView.swift:853`).
- Dekoratif katmanlar düzgünce `accessibilityHidden(true)` (26 yer).

**Eksik:** `AccessibilityNotification.Announcement` hiç kullanılmıyor — vakit
girdiğinde veya zikir seti tamamlandığında VoiceOver kullanıcısına sesli duyuru yok.
→ **Efor: S · Etki: Orta**

### 8.2 Bulgu: Dynamic Type fiilen desteklenmiyor

- `.font(.system(size: …))` — **57 kullanım** yalnızca `Mihrab/` altında.
- `@ScaledMetric` — **0 kullanım.**
- `dynamicTypeSize` modifier'ı — **0 kullanım.**

Sabit punto, iOS'un metin ölçekleme ayarını yok sayar. Erişilebilirlik boyutlarında
(AX1-AX5) hem metin büyümez hem de büyürse sabit `frame` değerleri (`MihrabSpace.hit`
vb.) taşma yapar. Bu, Apple Design Award hedefi için ciddi bir engel — ADA
değerlendirmesinde erişilebilirlik zorunlu kriterdir.

→ **Öneri:** Semantik stiller (`.title2`, `.headline`) + gerektiğinde
`.font(.system(size: 28, …))` yerine `@ScaledMetric(relativeTo: .largeTitle)`;
büyük geri sayım rakamları için `.dynamicTypeSize(...DynamicTypeSize.accessibility2)`
üst sınırı. **Efor: M · Etki: Yüksek**

### 8.3 Bulgu: RTL yalnızca metin bloğu düzeyinde

`.environment(\.layoutDirection, .rightToLeft)` **8 yerde** var ve hepsi tek bir
Arapça metin bloğunu sarmalıyor (`EsmaGridView.swift:348, 397`,
`EsmaHomeView.swift:111, 284`, `EsmaDetailSheet.swift:233`, `HadithDetailSheet.swift:30`,
`ReligiousDaysListView.swift:97`, `RamadanHubView.swift:350`).

Uygulama geneli yön, iOS'un bundle yerelleştirmesinden gelir. `project.yml:7-11`
`knownRegions`'da `ar` var ve `Localizable.xcstrings` 219 anahtarın 208'ini Arapçaya
çevirmiş — yani `ar.lproj` üretilir ve cihaz Arapça ise iOS düzeni çevirir.

**Ancak tutarsızlık riski var:** `L10n.language` (`L10n.swift:12-18`) dil seçimini
`Locale.preferredLanguages` üzerinden **kendi başına** yapıyor, iOS'un çözdüğü
bundle yerelleştirmesinden bağımsız. `RootView.swift:36` da `.environment(\.locale, …)`
ayarlıyor — ama `locale` `layoutDirection`'ı **değiştirmez**. Yani kullanıcının
tercih listesinde Arapça ikinci sıradaysa: metin Arapça, düzen LTR olabilir.

→ **Öneri:** `RootView`'a `.environment(\.layoutDirection, L10n.isArabic ? .rightToLeft : .leftToRight)`
ekle; RTL'de simülatörde tam bir geçiş turu yap (özellikle `SunArcView`, `QiblaCompassView`
ve `TimesView` gün sayfalayıcısı — bunlar yön varsayımı taşıyan ekranlar).
Ayrıca Arapça rakam biçimlendirmesi (`٠١٢٣` — Doğu Arapça rakamları) `ar_SA` locale'inde
otomatik gelir; monospaced-digit geri sayımlarda hizalamayı test et.
**Efor: M · Etki: Yüksek (Arapça pazar için zorunlu)**

### 8.4 Bulgu: Yerelleştirme mimarisi ölçeklenmiyor — yeni dil eklemek pahalı

`L10n` bir String Catalog değil, **hardcoded Swift**:

| Dosya | Satır |
|---|---|
| `Mihrab/Core/Shared/L10n.swift` | 548 |
| `Mihrab/Features/Paywall/L10n+Paywall.swift` | 407 |
| `Mihrab/Features/Dhikr/L10n+Dhikr.swift` | 331 |
| `Mihrab/Features/Onboarding/L10n+Onboarding.swift` | 304 |
| `Mihrab/Features/Today/L10n+Home.swift` | 244 |
| `Mihrab/Features/Settings/L10n+Settings.swift` | 220 |
| `Mihrab/Features/Deen/L10n+Deen.swift` | 191 |
| `Mihrab/Core/L10n+Appearance.swift` | 92 |
| **Toplam** | **2.337** |

Her metin `string(en:tr:ar:)` imzasıyla üç parametre alıyor (`L10n.swift:30-36`).
**Dördüncü bir dil eklemek, bu imzayı ve 8 dosyadaki her çağrıyı değiştirmek demek** —
yaklaşık 900+ çağrı noktası. Çeviri bürosuna gönderilebilir bir format da yok.

`L10n.swift:3-4` yorumu neden bu yola gidildiğini açıklıyor:
> "String Catalog interpolation was leaking raw keys (`prayer.schedule.fajr`,
> `hijri.month.3`, `PRAYER.COUNTDOWN.ASR`) onto the UI."

Bu, catalog'un yanlış kullanımından kaynaklanan bir hataydı (muhtemelen `String(localized:)`
yerine ham anahtar kullanımı veya eksik `Bundle` çözümlemesi), catalog'un kendi
kusuru değil. `Localizable.xcstrings` hâlâ 219 anahtar ve üç dille projede duruyor
ama fiilen yalnızca widget hedefine kaynak olarak veriliyor (`project.yml:72`).

→ **Öneri (L, ama stratejik):** `String Catalog`'a dön. Yol:
1. `L10n`'in `string(en:tr:ar:)` gövdesini `String(localized: key, defaultValue: en,
   table: "Localizable", bundle: .main)` ile değiştir — **çağrı noktaları aynı kalır.**
2. Bir script ile mevcut tr/ar değerlerini `.xcstrings`'e aktar.
3. Doğrulandıktan sonra `L10n` sabitlerini kademeli olarak `LocalizedStringResource`'a çevir.

**Dil önceliği (pazar gerekçeli):**

| Dil | Gerekçe | Öncelik |
|---|---|---|
| **Arapça (ar)** | Zaten %95 çevrili (208/219). Körfez + Mısır + Levant; yüksek ARPU (Körfez). RTL işi (§8.3) tamamlanmalı. | **1** |
| **Almanca (de)** | Almanya'da ~3M Türk kökenli + geniş Müslüman nüfus; Almanya App Store ARPU'su Türkiye'nin kat kat üstünde. Mevcut TR içerik pazarlaması doğrudan taşınabilir. | **2** |
| **Endonezce (id)** | Dünyanın en büyük Müslüman nüfusu (~240M); indirme hacmi çok yüksek, ARPU düşük. Ücretsiz katman güçlü olduğu için büyüme kaldıracı. | **3** |
| **Fransızca (fr)** | Fransa/Belçika Mağrip diasporası; iyi ARPU. | **4** |
| **Urduca (ur)** | Pakistan + BK diasporası. RTL altyapısı Arapça ile paylaşılır (bedava gelir). ARPU düşük. | **5** |
| **Malayca (ms)** | Malezya/Brunei — yüksek ARPU, küçük hacim. Endonezce ile büyük ölçüde örtüşür. | 6 |

Her dil için ayrıca `InfoPlist.xcstrings` (`Mihrab/Resources/InfoPlist.xcstrings` —
şu an `ar/en/tr` konum ve kamera izin metinleri **çevrili**, bu iyi) ve App Store
metadata gerekir.

---

## 9. Gizlilik & App Store uyumu

### 9.1 Bulgu: `PrivacyInfo.xcprivacy` **yok** — gerekli

`find . -name "*.xcprivacy"` → **0 sonuç.**

Uygulama, "required reason API" kategorisindeki API'leri kullanıyor:
- **UserDefaults** — `AppSettings.swift:9-10`, `SubscriptionManager`, `SharedPrayerCache`
  App Group defaults. Gerekçe kodu: **`CA92.1`** (uygulamanın kendi/uygulama grubu
  verisine erişim).
- **Dosya zaman damgaları** — `SharedPrayerCache` `Data(contentsOf:)`/`write(to:)`
  doğrudan zaman damgası okumuyor, ancak `URLCache` disk kullanımı için kontrol edilmeli.

Ayrıca `NSPrivacyTracking` (false), `NSPrivacyTrackingDomains` (boş) ve
`NSPrivacyCollectedDataTypes` bildirimi gerekiyor. Uygulama gerçekten hiç veri
toplamıyor (analytics SDK yok — doğrulandı, üçüncü taraf bağımlılık yok) — bu
**büyük bir pazarlama avantajı** ve manifest bunu resmîleştirir.

Konum: `Mihrab/PrivacyInfo.xcprivacy` **ve** `MihrabWidgets/PrivacyInfo.xcprivacy`
(her hedef kendi manifestini taşır).

→ **Efor: S · Etki: Yüksek (App Store gönderimi için pratik olarak zorunlu)**

### 9.2 Konum izni gerekçeleri — durum iyi

`project.yml:51-52` ve `Mihrab/Resources/InfoPlist.xcstrings` (ar/en/tr çevrili):
- `NSLocationWhenInUseUsageDescription`: "…calculate precise prayer times, Qibla
  direction, and nearby mosques." — spesifik ve doğru.
- `NSCameraUsageDescription`: "…only to show Qibla direction in AR. Nothing is
  recorded or uploaded." — iyi.

**Küçük not:** `project.yml` içindeki `INFOPLIST_KEY_…` değerleri ile
`InfoPlist.xcstrings` içindekiler çakışıyor; catalog kazanır ama iki kaynak
bakım riski. Tek kaynağa indir. **Efor: S · Etki: Düşük**

**Eksik:** `NSMotionUsageDescription` yok. `QiblaARView` ARKit kullanıyor
(`QiblaARView.swift:1-3` `import ARKit/AVFoundation/RealityKit`); ARKit world
tracking hareket sensörlerine erişir. Bazı ARKit yapılandırmalarında bu anahtar
istenir. Kontrol et. **Efor: S · Etki: Orta (reddedilme riski)**

### 9.3 Bulgu: Paywall'da satılan özelliklerin çoğu **gate'lenmemiş veya yok** — 2.3.1 riski

`PremiumFeature` enum'unun 12 case'i var (`SubscriptionManager.swift:62-75`).
Her birinin kod tabanındaki gerçek kullanımı (enum tanımı hariç):

| Case | Kullanım | Durum |
|---|---|---|
| `qiblaAR` | 1 | ✅ gate'li |
| `advancedWidgets` | 0 | ❌ |
| `themes` | 0 | ❌ |
| `customAdhan` | 0 | ❌ **ve özellik hiç yok** |
| `dhikrUnlimitedGoals` | 0 | (kısmen `isPremium` ile: `DhikrLibrarySheet.swift:155`) |
| `dhikrFullHistory` | 0 | (kısmen: `DhikrStatsView.swift:290`) |
| `esmaCollections` | 0 | (kısmen: `EsmaHomeView.swift:232`) |
| `tafakkurContent` | 0 | ❌ |
| `ramadanPlanner` | 0 | ❌ |
| `multipleCities` | 0 | ❌ |
| `iCloudBackup` | 0 | ❌ **ve özellik hiç yok** (§6.2) |
| `shareCards` | 0 | ❌ |

**`customAdhan` özellikle sorunlu:** `Mihrab/Resources/Audio/` klasörü **boş**;
`NotificationEngine` her bildirimde `content.sound = .default` kullanıyor
(`:55, :74, :90, :104`). Yani "özel ezan sesi" satılıyor ama tek bir ses dosyası yok.

Paywall'ın gösterdiği 5 fayda (`PaywallView.swift:138-142`): widget'lar, temalar,
zikir, esma, ramazan. Bunlardan **widget'lar, temalar ve ramazan gate'li değil** —
ücretsiz kullanıcı da alıyor.

→ **Öneri:** Ya gate'leri uygula ya paywall metnini gerçeğe indir. Gönderimden önce
`PremiumFeature`'ın her case'i için ya bir kullanım noktası ya da silme kararı olmalı.
**Efor: M · Etki: Yüksek (App Review + kullanıcı güveni)**

### 9.4 Guideline 3.1.2 — paywall denetimi

3.1.2 otomatik yenilenen abonelikler için uygulama **içinde**, satın alma noktasında
şunları ister: (a) abonelik başlığı, (b) süre, (c) her dönem için fiyat, (d) sunulan
içerik/hizmet, (e) çalışan **Kullanım Şartları (EULA)** ve **Gizlilik Politikası**
bağlantıları.

Mevcut paywall değerlendirmesi:

| Gereklilik | Durum | Kanıt |
|---|---|---|
| Başlık | ✅ | `PaywallView.swift:110-121` (`paywallTitle`/`paywallHeadline`) |
| Süre | ✅ | `periodText(for:)` `:209-215` — ay/yıl/tek seferlik |
| Dönem fiyatı | ✅ | `PlanCard(priceText: subscriptions.displayPrice(for:))` `:192`; StoreKit'ten yerelleştirilmiş fiyat |
| Yenileme koşulu metni | ✅ | `footnote` `:320-330` → `paywallTrialFootnote`/`paywallDirectFootnote`, CTA'nın hemen altında `:289` |
| İçerik/hizmet tarifi | ✅ | `benefitList` `:136-144` — **ama §9.3'teki doğruluk sorunu var** |
| Gizlilik Politikası bağlantısı | ⚠️ | `:28` `https://mihrab.app/privacy` — **alan adının canlı olduğu doğrulanamadı.** Ölü bağlantı = kesin ret |
| Kullanım Şartları bağlantısı | ✅ | `:29` Apple standart EULA URL'si — kabul edilir |
| Geri yükleme | ✅ | `:335-347` `AppStore.sync()` üzerinden |
| Dark pattern yok | ✅ | Kapatma butonu ilk kareden görünür `:52, :370-386`; geri sayım yok |

**Ek gözlem — "yerel deneme" mekanizması (`:246-252, PaywallView.swift:318-320`):**
StoreKit teklifi yokken uygulama kendi 7 günlük denemesini başlatıyor
(`SubscriptionManager.startFreeTrial()` `:255-264`). Bu, StoreKit dışı bir
hak yönetimidir. Reddedilme sebebi değil (ücretsiz veriliyor, ödeme alınmıyor), ama:
- `UserDefaults`'a yazıldığı için uygulama silinip yeniden kurulunca sıfırlanır
  (sonsuz deneme). Ciddi bir gelir sızıntısı.
- → Deneme durumunu Keychain'e veya (§6.2 yapılırsa) CloudKit KVS'e taşı. **Efor: S · Etki: Orta**

**StoreKit tarafı sağlam:** `Transaction.updates` dinleyicisi var
(`SubscriptionManager.swift:421-422`), `Transaction.currentEntitlements` ile
doğrulama (`:404`), saat geri alma savunması (yorum `:~50`), `Mihrab.storekit`
test konfigürasyonu mevcut (`Mihrab/Resources/Mihrab.storekit`). Bu katman iyi yazılmış.

---

## 10. Test & kalite

### 10.1 Mevcut kapsam

`MihrabTests/MihrabTests.swift` — **126 satır, 3 sınıf, 11 test**, XCTest (Swift
Testing değil):

| Sınıf | Testler |
|---|---|
| `QiblaMathTests` | 10 şehir için referans kerteriz, 0-360 aralığı, Mekke mesafesi, `shortestDelta` |
| `PrayerTimesTests` | `nextPrayer` sıralaması, `SafeCountdown` sınır durumları, boş olmayan yerelleştirilmiş isimler, gece yarısı sonrası devrilme |
| `BundledContentTests` | Hadis/esma/dinî gün veri setleri yükleniyor mu, günün hadisi deterministik mi |

Bu testler iyi yazılmış ve gerçek riskleri (kıble matematiği, geri sayım aralığı)
hedefliyor.

### 10.2 Bulgu: Test hedefi kritik kodu **derleyemiyor bile**

`project.yml:81-97`, `MihrabTests` hedefinin kaynakları:
```yaml
sources:
  - path: MihrabTests
  - path: Mihrab/Core/Shared          # PrayerModels, SharedPrayerCache, L10n, CountdownText…
  - path: Mihrab/Data/BundledContent.swift
```

`dependencies: - target: Mihrab` var, ancak ana hedef `DEFINES_MODULE: YES`
(`project.yml:45`) ile modül tanımlıyor ve test dosyasında **`@testable import Mihrab`
yok** (`MihrabTests.swift:1` → yalnızca `import XCTest`). Yani testler sadece
doğrudan kaynak olarak eklenen dosyalara erişiyor.

**Test edilemeyen (kaynak listesinde olmayan) kritik dosyalar:**

| Dosya | Risk |
|---|---|
| `Mihrab/Data/AladhanClient.swift` | **§6.1'deki kritik hata tam burada.** Bir tek `toDomain()` testi olsaydı yakalanırdı |
| `Mihrab/Data/PrayerTimesRepository.swift` | Önbellek anahtarı, stale-while-error, snapshot yayını |
| `Mihrab/Core/NotificationEngine.swift` | 64 limiti, bütçe dağılımı, kimlik çakışması |
| `Mihrab/Core/LiveActivityManager.swift` | 30 dk penceresi mantığı |
| `Mihrab/Core/Subscription/SubscriptionManager.swift` | Hak yönetimi, deneme saati, geri yükleme |
| `Mihrab/Core/Subscription/TrialReminder.swift` | **§7.4'teki hata tam burada** |
| `Mihrab/Core/LocationManager.swift` | Heading yumuşatma, manuel konum önceliği |

**Bu, raporun en önemli yapısal bulgusu:** iki kritik hatanın (§6.1, §7.4) ikisi de
tam olarak test kapsamı dışında bırakılmış dosyalarda. Sebep-sonuç ilişkisi tesadüf değil.

### 10.3 Öneriler

| # | Öneri | Efor | Etki |
|---|---|---|---|
| T1 | `project.yml`'a `Mihrab/Data` ve `Mihrab/Core` ekle veya `@testable import Mihrab`'ı çalışır hale getir. **Diğer her test önerisi buna bağlı.** | S | **Yüksek** |
| T2 | `AladhanClient.toDomain()` için altın-dosya testleri: gerçek Aladhan JSON yanıtlarını fixture olarak kaydet; **ayın 15. günü için dönen nesnenin `date` alanının ayın 15'i olduğunu doğrula.** §6.1'i kalıcı olarak kapatır | S | **Yüksek** |
| T3 | `APIClient` protokolü zaten var (`AladhanClient.swift:3-9`) — `MockAPIClient` ile `PrayerTimesRepository` testleri: ağ hatası → stale cache, yöntem değişimi → yeni anahtar, snapshot içeriği | M | Yüksek |
| T4 | `NotificationEngine` bütçe testi: 30 günlük snapshot + 6 dinî gün ver, planlanan istek sayısının 64'ü aşmadığını ve namaz bildirimlerinin önceliklendiğini doğrula (UNUserNotificationCenter'ı protokol arkasına al) | M | Yüksek |
| T5 | `SubscriptionManager` için StoreKit Test (`Mihrab/Resources/Mihrab.storekit` zaten var): satın alma, geri yükleme, deneme bitişi, saat geri alma senaryoları | M | Orta |
| T6 | Yaz saati / zaman dilimi testleri: DST geçiş günü, UTC+14 ve UTC-11 uçları, kutup enlemlerinde (Tromsø, 69°N) vakit hesabı. §6.3'teki Adhan entegrasyonu bunları saf fonksiyon olarak test edilebilir kılar | M | Yüksek |
| T7 | Snapshot testleri (`swift-snapshot-testing` veya Xcode `XCTAttachment`): TR/EN/**AR-RTL** × Dynamic Type XL/AX3 × açık/koyu için ana ekranlar. §8.2/§8.3'ü regresyondan korur | M | Orta |
| T8 | Swift Testing'e geçiş (`@Test`, `#expect`, parametrized `@Test(arguments:)`). `QiblaMathTests`'in 10 şehri parametrized test için ideal | S | Düşük |
| T9 | UI testi hedefi yok. `RootView.swift:16-21` zaten `-tabTimes`/`-tabQibla` gibi launch argument'ları destekliyor — XCUITest altyapısı yarı hazır | M | Orta |
| T10 | `SWIFT_STRICT_CONCURRENCY: minimal` (`project.yml:17`) — `@unchecked Sendable` 4+ yerde (`LocationManager.swift:6`, `PrayerTimesRepository.swift:7`, `LiveActivityManager.swift:6`, `Theme` `MihrabApp.swift:38`) ve `nonisolated(unsafe)` (`LiveActivityManager.swift:11`). Swift 6'da `complete`'e geçmek gerçek veri yarışlarını ortaya çıkarır | L | Orta |

---

## 11. Önerilen yol haritası

### Faz 0 — Gönderim engelleyiciler (1 hafta)
1. §6.1 Aladhan tarih hatası **(S, Kritik)**
2. §7.4 `TrialReminder.ensureScheduled()` çağrısı **(S, Yüksek)**
3. §1.1 `WidgetCenter.reloadAllTimelines()` **(S, Yüksek)**
4. §9.1 `PrivacyInfo.xcprivacy` × 2 hedef **(S, Yüksek)**
5. §9.3 Paywall–gerçeklik uyumu; §6.2'de (a) veya (b) kararı **(M, Yüksek)**
6. §9.4 `mihrab.app/privacy` bağlantısının canlı olduğunu doğrula **(S, Kritik)**
7. §10.3 T1 + T2 — test hedefini aç, `toDomain()` fixture testi **(S, Yüksek)**

### Faz 1 — Platform derinliği (2-3 hafta)
8. §3 App Intents seti + `AppShortcutsProvider` **(M, Yüksek)** ← diğer her şeyi besler
9. §1.3 Control widget'ları (Kıble / Zikir / Zikir+1) **(M, Yüksek)**
10. §2.2 Live Activity yaşam döngüsü + scenePhase + `BGAppRefreshTask` **(M, Yüksek)**
11. §7.1 Konum throttle + `distanceFilter` **(S, Yüksek)**
12. §7.3 Bildirim bütçesi merkezîleştirme + doğrulama **(S, Yüksek)**
13. §6.3 `adhan-swift` ile çevrimdışı hesaplama **(M, Yüksek)**

### Faz 2 — Yeni yüzeyler (3-4 hafta)
14. §4 Watch: Aşama 0 (Live Activity ailesi) → Aşama 1 (komplikasyonlar) → Aşama 3 (zikirmatik)
15. §1.4 `AppIntentConfiguration` + şehir seçimi + `.systemLarge`
16. §2.3 İftar/sahur Live Activity (Ramazan'dan önce yetiştirilmeli)
17. §5 iPad desteği

### Faz 3 — Erişilebilirlik & büyüme (2-3 hafta)
18. §8.2 Dynamic Type geçişi **(M, Yüksek)**
19. §8.3 Tam RTL turu **(M, Yüksek)**
20. §8.4 String Catalog'a dönüş → de, id, fr **(L, Yüksek)**
21. §10.3 T3-T7 test kapsamı

---

## Ek A — Doğrulanmış bulguların dosya:satır dizini

| # | Bulgu | Referans |
|---|---|---|
| 1 | Tüm API günleri bugüne çöküyor | `Mihrab/Data/AladhanClient.swift:127-151` (özellikle `:143`, `:151`) |
| 2 | `WidgetCenter` hiç kullanılmıyor | tüm kod tabanı, 0 eşleşme |
| 3 | Live Activity tek çağrı noktası | `Mihrab/App/RootView.swift:43` |
| 4 | `TrialReminder.ensureScheduled` hiç çağrılmıyor | `Mihrab/Core/Subscription/TrialReminder.swift:52` (tanım), 0 çağrı |
| 5 | Bildirimleri kayıtsızca silme | `Mihrab/Core/NotificationEngine.swift:21` |
| 6 | Bildirim bütçesi 50 + sabit + değişken | `NotificationEngine.swift:29, 77, 84-97, 110` |
| 7 | `add(request)` sonucu hiç kontrol edilmiyor | `NotificationEngine.swift:64, 77, 95, 110` |
| 8 | SwiftData'da CloudKit yok | `Mihrab/Data/Models/SwiftDataModels.swift:48`; `Mihrab/Mihrab.entitlements:5-8` |
| 9 | iCloud yedekleme satılıyor | `SubscriptionManager.swift:74`; `L10n+Paywall.swift:305`; `L10n+Settings.swift:125-127` |
| 10 | `customAdhan` satılıyor, ses dosyası yok | `SubscriptionManager.swift:66`; `Mihrab/Resources/Audio/` boş |
| 11 | 11/12 `PremiumFeature` case'i gate'lenmemiş | `SubscriptionManager.swift:62-75` |
| 12 | `PrivacyInfo.xcprivacy` yok | proje genelinde 0 dosya |
| 13 | App Intents yok | 0 eşleşme |
| 14 | `BGTaskScheduler` yok | 0 eşleşme |
| 15 | `stopUpdatingLocation` / `distanceFilter` yok | `Mihrab/Core/LocationManager.swift:26-46` |
| 16 | Her konum güncellemesi tam `refresh()` tetikliyor | `RootView.swift:45-50` → `PrayerTimesRepository.swift:44-60, 95-105` |
| 17 | `isLowPowerModeEnabled` kontrol edilmiyor | 0 eşleşme |
| 18 | iPhone-only, dikey-only | `project.yml:47, 50` |
| 19 | 57 sabit punto, 0 `ScaledMetric` | `Mihrab/` genelinde |
| 20 | RTL yalnızca 8 metin bloğunda | `EsmaGridView.swift:348, 397` vd. |
| 21 | Yerelleştirme 2.337 satır hardcoded Swift | `L10n.swift:30-36` + 7 uzantı dosyası |
| 22 | Test hedefi kritik dosyaları içermiyor | `project.yml:84-88`; `MihrabTests.swift:1` (`@testable import` yok) |
| 23 | Widget galerisi metinleri İngilizce | `PrayerTimesWidget.swift:46-47, 87`; `LockScreenWidgets.swift:21-22, 55, 61-63, 72, 77-78` |
| 24 | `containerBackground` sabit, tint modları ele alınmamış | `PrayerTimesWidget.swift:44` |
| 25 | Yerel deneme durumu `UserDefaults`'ta (yeniden kurulumla sıfırlanır) | `SubscriptionManager.swift:255-264` |
