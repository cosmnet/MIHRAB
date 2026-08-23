# Mihrab — Pazar Araştırması ve Ürün Yol Haritası

> **Araştırma tarihi:** 23 Ağustos 2026
> **Kapsam:** iOS İslami günlük yaşam uygulamaları. Birincil pazar Türkiye, ikincil pazar global.
> **Yöntem:** Apple iTunes Lookup/Search API (tr ve us storefront, canlı çekim), Türkçe App Store yorum akışları, Şikayetvar, Trustpilot, açık kaynak proje issue takipçileri, Diyanet resmî yayınları, Adjust/AppsFlyer/RevenueCat/Sensor Tower sektör raporları.
> **Uyarı:** Rakip pazarlama metinleri kopyalanmamıştır; bulgular özetlenmiş, alıntılar kısa tutulmuş ve kaynak verilmiştir. Bazı sayılarda kaynaklar çelişiyorsa bu açıkça belirtilmiştir.

---

## 0. Yönetici Özeti — 8 Cümlelik Tez

1. Türkiye'de İslami uygulama pazarının lideri **Ezan Vakti Pro** (~490 bin iOS TR puanı, 10M+ Android indirme) ama Şikayetvar'daki marka puanı **0/100** ve son yorumlarının büyük çoğunluğu tek bir şeye dair: **ibadet uygulamasının içindeki kumar, faiz ve müstehcen reklamlar**.
2. Herkesin güvendiği otorite olan **Diyanet'in kendi yazılımı pazarın en kötüsü**: e-Diyanet **3.37★**, Hac ve Umre Rehberi **1.77★**, Diyanet Takvimi mağazadan kalkmış. Yani "Diyanet güveni" ile "iyi yazılım" hiçbir üründe birleşmiyor.
3. Bu boşluk **şu anda doldurulmakta**: 2026'da çıkan Türk indie uygulamaları (irade 10 ayda ~11.900 puan, Quran Widgets 6 ayda ~10.500 puan) hızla büyüyor. Türkiye Referans kategorisinin yaklaşık **%20'si artık İslami uygulama**. Pencere açık ama kapanıyor.
4. **Muslim Pro Türkiye'de yenilmiş durumda** — liderin yalnızca ~%2'si kadar puanı var. Türkiye global bir süper-uygulamanın kazandığı bir pazar değil; Diyanet, kandil, imsakiye ve "reklamsız" diyen uygulamanın kazandığı bir pazar.
5. Mihrab'ın en büyük teknik açığı: namaz vakitleri **yalnızca Aladhan API'sinden** geliyor, cihaz üstü hesaplama ve kalıcı disk kaydı yok. Uçakta, çekmeyen yerde, API kesintisinde uygulama susar.
6. İkinci açık: `Resources/Audio/` klasörü **boş**, bildirimler `.default` sesi kullanıyor. **Ezan sesi yok.**
7. **iOS 26'nın AlarmKit'i kategorinin en büyük çözülmemiş sorununu (ezanın hiç çalmaması ve 30 saniyede kesilmesi) sistem seviyesinde çözüyor** — ve rakiplerin destek sayfaları hâlâ kullanıcıya elle geçici çözüm öneriyor. Bu, şu anda pazardaki en büyük sahipsiz fırsat.
8. Türkiye'de "Diyanet uyumluyum" demek yetmez: Diyanet'in gerçek vakitleri **temkin** payları içerir (doğuş/batış 7 dk, öğle 5 dk, ikindi 4 dk). Genel bir kütüphaneye "18°/17° Türkiye" ayarı verip geçmek, basılı takvimle birkaç dakikalık uyuşmazlık ve "vakitler yanlış" yorumları üretir.

---

## 1. Rakip Analizi

### 1.1 Türkiye — sayılarla

**Tier 1: Yerleşik devler**

| Uygulama | Geliştirici | Puan | iOS TR yorum | Çıkış | Not |
|---|---|---|---|---|---|
| **Ezan Vakti Pro** | (id437447439) | 4.74★ | **~491.000** | 2011 | Play: 10M+ indirme, 1.39M yorum. Şikayetvar marka puanı **0/100** |
| **Namaz Vakti – Ezan Vakitleri** | BEKART TECH | 4.58★ | ~125.600 | 2016 | Alt başlığında yıl boyu "Diyanet Ramazan İmsakiye" tutuyor |
| **Kıble Bulucu, Kıble Pusulası** | BEKART TECH | 4.69★ | ~74.000 | 2017 | **Sadece kıble** — devasa, ayrı bir niyet kümesi |
| **Zikirmatik – Tesbih Et** | CODEIDA | 4.75★ | ~28.100 | 2016 | Zikir kategorisinin lideri |
| **Ramazan İmsakiye Diyanet** | Bağımsız | 4.73★ | ~25.300 | 2016 | **Yalnızca sezonluk** bir uygulama, bu boyutta |
| **Kur'an (Tevafuklu)** | Hayrat Neşriyat | 4.83★ | ~20.100 | 2010 | En yüksek güvenli mushaf |
| **Namaz Hocası** | CODEIDA | 4.78★ | ~19.000 | 2014 | Nasıl kılınır referansı |
| **Muslim Pro** | Bitsmedia | 4.63★ | **~10.300** | 2010 | Referans'ta **#58** — liderin ~%2'si |

> *Not: Ezan Vakti Pro'nun puan sayısı için kaynaklar çelişiyor (bir çekim ~491.000, başka bir çekim çok daha düşük gösterdi). 10M+ Android indirme ve 1.39M Play yorumu ile tutarlı olduğu için yüksek değer esas alınmıştır; yayın öncesi doğrulanması önerilir.*

**Tier 2: Resmî Diyanet uygulamaları — pazarın en büyük açığı**

| Uygulama | Puan | Yorum | Durum |
|---|---|---|---|
| **e-Diyanet** | **3.37★** | ~2.300 | 274 MB. Play'de 1M+ indirme, 1★ oranı ~%15 |
| **Diyanet Hac ve Umre Rehberi** | **1.77★** | 65 | Fiilen çalışmıyor |
| **TDV Kuran** | 2.33★ | 6 | — |
| **Diyanet Takvimi** | — | — | **tr mağazasından kalkmış** |
| Eski "Namaz Vakti" | — | — | Terk edilmiş. Diyanet, yükleniciden imza anahtarlarının hiç teslim alınamadığını ve uygulamanın işletim sistemi güncellemeleriyle çalışamaz hâle geldiğini açıkça duyurmuş |

**Bu tablo Mihrab'ın stratejik tezidir:** Marka güveninin sahibi, yazılım kalitesinin sahibi değil.

**Tier 3: 2026 indie dalgası — Mihrab'ın gerçek rakipleri**

| Referans sırası | Uygulama | Puan / yorum | Çıkış |
|---|---|---|---|
| #2 | Nurlu – Islam Guide | 4.43★ / 2.902 | Mar 2026 |
| #3 | Quran Widgets | 4.52★ / **10.523** | Şub 2026 |
| #7 | Nizam – Quran Widgets & Dhikr | 4.53★ / 3.150 | Nis 2026 |
| #12 | Ruhun Gıdası | 4.70★ / 931 | May 2026 |
| #17 | Rahman: Islam Super App | 4.62★ / 281 | Tem 2026 |
| #20 | Esma: Prayer Times & 99 Names | 4.50★ / 159 | Nis 2026 |
| #25 | Sereni – Quran Companion | 4.55★ / 379 | Mar 2026 |
| Yaşam Tarzı #32 | **irade – Islamic Helper** | 4.62★ / **11.872** | Eki 2025 |
| Yaşam Tarzı #89 | 5te5 (kaza namazı takibi) | 4.87★ / 6.123 | 2022 |

**İki kritik çıkarım:**
- **irade 10 ayda sıfırdan ~11.900 puana, Quran Widgets 6 ayda ~10.500 puana çıktı.** İyi tasarlanmış bir yeni oyuncu bu pazarı gerçekten kazanabiliyor.
- Bu kohortun neredeyse tamamı **Türkiye mağazasında İngilizce başlık** kullanıyor (Nurlu – Islam Guide, Elif: Prayer Times & Qur'an, Esma: Prayer Times & 99 Names). Tek binary ile hem TR hem global peşinde koşuyorlar. Mihrab da aynı yapıyı kurabilir.

### 1.2 Global oyuncular

| Uygulama | iOS Puan / Yorum | Yıllık fiyat | En güçlü yanı | En büyük şikayet |
|---|---|---|---|---|
| **Muslim Pro** | 4.7★ / ~598K | $34.99 | Dağıtım, dil genişliği, Qalbox medya ekosistemi | Reklam bombardımanı; **haram reklam kreatifleri**; iptal zorluğu; Trustpilot **1.8/5**; 2020 veri skandalı |
| **Athan (IslamicFinder)** | 4.8★ / ~49K | **$11.99** | Olgun vakit motoru; kategorinin en ucuz premium'u | Ezanı dinlemek için açınca reklam; Android'de ezan çalmaması |
| **Athan Pro (Quanticapps)** | 4.6★ / ~79K | değişken | Live Activity ve widget kalitesi övülüyor | Ömür boyu → aboneliğe geçiş tepkisi |
| **Pillars** | 4.8★ / ~5.5K | $49.99 (+ aile $87.90) | **Sınıfının en iyisi iOS widget'ları**, reklamsız/gizlilik markası | **Widget'ları ödeme duvarına alması** büyük tepki çekti |
| **Tarteel AI** | 4.7★ / ~11K | **$99** | Tek gerçek AI kıraat düzeltme motoru | Fiyat şoku; doğru okumayı hatalı işaretleme |
| **Quran.com** | 4.9★ / ~33K | **Ücretsiz, açık kaynak** | Güvenilirlik; **fiyat tabanını belirliyor** | Sadece Kur'an |
| **Ayah** | 4.8★ / **~109K** | $12.99 | Dikkat dağıtmayan okuma estetiği — **tek kişilik ekip** | Neredeyse yok |
| **Just Pray** | **4.9★ / ~20K** | Free + Pro | **Prayer Circles** (sosyal sorumluluk), Watch, Garden of Deeds | Pazarlanan özelliklerin çoğu premium |
| **Salam App** | 4.9★ / ~119 | **Tamamen ücretsiz, IAP yok** | En derin ücretsiz set; "veri toplamıyor" etiketi | Dağıtımı yok |
| **Sajda** | 4.84★ / 13M indirme | Ücretsiz + Plus | 14 yıldır reklamsız + Mekke canlı yayın | Neredeyse yok |
| **FivePrayer** | 4.9★ | Ücretsiz | **Ezan vaktinde telefonu kilitleme** | Screen Time izni sürtünmesi |
| **Muslim: Prayer Times, Qibla** (TR ekip) | 4.7★ / ~88K | $39.99 + **ömür boyu** | AI İmam, Watch + Mac, ömür boyu seçeneği | Reklam; bölgesel vakit sapmaları |

**Fiyat gerçeği:** Kimsenin kızmadığı yıllık bant **$12–$35**. Pillars ($49.99) ve Tarteel ($99) aktif olarak şikayet üretiyor. Ayah tek kişiyle **109 bin puana** ulaştı — sadece tasarım ve odakla. Bu, iOS 26 tasarım kalitesinin savunulabilir bir avantaj olduğunun kanıtı.

---

## 2. Boşluk Analizi

### 2.1 Mihrab'ın mevcut durumu (kod tabanından doğrulandı)

| Alan | Durum | Kanıt |
|---|---|---|
| Namaz vakitleri | 🔴 **Sadece Aladhan API** | `AladhanClient.swift` + `PrayerTimesRepository.swift`; yalnızca bellek cache + `URLCache`. Cihaz üstü hesaplama ve kalıcı disk kaydı **yok** |
| Ezan sesi | 🔴 **Yok** | `Resources/Audio/` boş; `NotificationEngine.swift` → `content.sound = .default` |
| AlarmKit | 🔴 Yok | iOS 26'nın en büyük fırsatı kullanılmıyor |
| Apple Watch | 🔴 Yok | Hedef yok |
| iPad / Mac / Vision Pro | 🔴 Yok | `TARGETED_DEVICE_FAMILY = 1` |
| App Intents / Siri / Control Center | 🔴 Yok | Projede hiç `AppIntent` yok |
| iCloud senkron | 🟡 Kısmi | `SwiftDataModels.swift` yorumunda CloudKit geçiyor, yapılandırma yok |
| Arka plan yenileme | 🔴 Yok | `BGTask` yok |
| Kur'an okuyucu | 🔴 Yok | Amiri Quran fontu paketlenmiş, içerik yok |
| Kaza namazı / zekât / hatim | 🔴 Yok | — |
| Widget + Live Activity | 🟢 Var | `MihrabWidgets`, `PrayerLiveActivity` |
| Bildirim mimarisi | 🟢 İyi | 64 bekleyen bildirim sınırı gözetilmiş |
| Kıble + AR | 🟢 Var | Doğruluk göstergesi ve sapma düzeltmesi doğrulanmalı |

### 2.2 Kategori genelinde acı noktaları — sıklık sırasına göre

| # | Acı noktası | Kanıt |
|---|---|---|
| 1 | **İbadetin içine sokulan reklam** | Ezan Vakti Pro'nun son 50 yorumunun ~41'i ≤3 yıldız, ~35'i sadece reklam hakkında. Kumar, faizli banka, bikinili kadın reklamları. Zikirmatik yorumlarında "date ve poker uygulaması reklamı". Şikayetvar marka puanı 0/100 |
| 2 | **Gizlilik / konum verisi satışı** | 2020 Muslim Pro → X-Mode → ABD ordusu; 2021 Salaat First → Predicio → ICE/FBI. Comparitech'in 175 Müslüman uygulaması taramasında %96'sı cihaz kimliği, ~%40'ı konum istiyor. Türk basınında geniş yer buldu |
| 3 | **Ezan bildiriminin hiç gelmemesi / birkaç gün sonra susması** | Muslim Pro'nun bu konuda **üç ayrı destek makalesi** var. Kök neden: iOS'un 64 bekleyen bildirim sınırı; vakitler her gün değiştiği için tekrarlayan tetikleyici kullanılamıyor. TR yorumu: *"2 gündür sahura kalkamıyorum"* |
| 4 | **Tam ezanın çalmaması** | iOS bildirim sesi **30 saniye** ile sınırlı; ezan 2–4 dakika. Tüm rakiplerin "çözümü" aynı: bildirime dokunup uygulamayı aç |
| 5 | **Vakitlerin yanlış olması** | Üç ayrı kök neden tek şikayet olarak geliyor: mezhep (ikindi 30–60 dk fark), yaz saati (±1 saat kayma), hesaplama yöntemi/seyahat |
| 6 | **Kıble sapması** | *"1 haftadır ters yöne kılıyormuşum"* — 74 bin puanlı bir kıble uygulamasında. Manyetik/gerçek kuzey karışıklığı, kalibrasyonsuz manyetometre, metal parazit 20–30° sapma yaratıyor |
| 7 | **Abonelik baskısı ve ödeme duvarı ihaneti** | *"Süresiz olarak pro sürümüne yükseltmiştim, şimdi tekrar ücret istiyorsunuz"*. Widget'ların paralı yapılması: *"Uygulamayı saatte görebilmek için Pro almak gerekliymiş, SİLDİM"* |
| 8 | **Senkron yokluğu / veri kaybı** | quran_android deposunun **1. ve 2. en çok oy alan açık talebi** cihazlar arası yer imi ve son okunan konum senkronu |
| 9 | **Widget'ların donması** | WidgetKit yenileme bütçesi, Düşük Güç Modu, arka plan yenileme kapalıyken geçmiş vakti göstermeye devam etmesi |
| 10 | **Apple Watch desteğinin bozuk olması** | *"Son güncellemeyle Apple Watch desteği kalktı"*, *"her gün uygulamayı açmam gerekiyor"* — üstelik ödeme yapmış kullanıcıdan |
| 11 | **Şişkinlik / misyon kayması** | Muslim Pro'nun video akışına girmesi: *"başladığı yerden çok uzaklaşmış"* |
| 12 | **Çevrimdışı çalışmama** | *"Önceden internetsiz kullanılabiliyordu, şimdi internetsiz açmıyor"*; e-Diyanet için *"Neden sadece namaz vakitleri için yüzlerce MB indireyim?"* |
| 13 | **İçerik doğruluğu** | Türk kullanıcı **harekeleri tek tek kontrol ediyor**: *"Vakıa suresinin 30. ve 43. ayetleri yanlış, lam harfleri üstün olmuş"*. Ayrıca mealde **"Tanrı" kelimesi kullanılması** teolojik itiraz görüyor — daima **"Allah"** kullanın |

### 2.3 Hiçbirinde olmayıp talep edilen — sahipsiz fırsatlar

| Fırsat | Neden sahipsiz |
|---|---|
| **AlarmKit ile gerçekten çalan, tam uzunlukta ezan** | iOS 26 ile üçüncü taraf uygulamalara sistem seviyesi alarm açıldı: Sessiz modu ve Odak'ı deler, kilit ekranı/Dynamic Island/Watch sunumu ve tam ekran durdur-ertele verir. Rakiplerin destek sayfaları hâlâ elle geçici çözüm anlatıyor. **Kategorinin en büyük tek açığı** |
| **Takvim kaynağı seçici (Diyanet / Fazilet / Türkiye Takvimi)** | Türkiye'de 15–20 dakikalık farkla üç ayrı takvim geleneği ve her birinin kitlesi var; hiçbir modern uygulama bunu şeffafça sunmuyor |
| **"Bu vakit neden farklı?" açıklayıcısı** | Aktif yöntem, açılar, mezhep, temkin, yaz saati durumu ve rakım tek ekranda + vakit başına ±dakika düzeltme |
| **Güneş gölgesiyle kıble doğrulama** | Manyetometreden tamamen bağımsız, kat kat hassas; büyük rakiplerin hiçbirinde yok |
| **Hediye / sadaka-i cariye aboneliği** | Fazilet Takvimi'nin "Arkadaşım / Ailem / Komşum" paketleri Türkiye'nin en kültürel uyumlu para kazanma modeli — ve kimse kopyalamıyor |
| **Türk ihtiyaçlarının tek üründe birleşmesi** | Kaza namazı, hatim/cüz dağıtımı, zekât, feraiz, namaz öğretici, kandiller — hepsi **ayrı ayrı uygulamalar** olarak yaşıyor |

---

## 3. Özellik Fikirleri

**Efor:** S ≈ 1–5 gün · M ≈ 1–3 hafta · L ≈ 1 ay+

### 3.1 Temel güven ve doğruluk

| # | Özellik | Ne | Çözdüğü ihtiyaç | Efor | Etki | Ücret |
|---|---|---|---|---|---|---|
| 1 | **Cihaz üstü vakit hesaplama** | `adhan-swift` entegre edilir (Meeus astronomik algoritmaları); API tamamen yedeğe düşer. Vakitlerin **artan sırada olduğu doğrulanmalı** — kütüphanede yüksek enlemlerde ikindinin öğleden önce dönebildiği açık bir hata var; sessizce göstermek yerine hata verin | Uçak modu, çekmeyen yer, API kesintisi, seyahat. Acı noktası #12 | M | **Çok yüksek** | Ücretsiz |
| 2 | **Diyanet vakitleri — gerçek temkin ile** | Diyanet 1983'ten beri imsak ve yatsıda **18°** kullanıyor ve **temkin** payları uyguluyor: doğuş/batışta **7 dk**, öğlede **5 dk**, ikindide **4 dk**, imsak ve yatsıda **temkin yok**. Genel kütüphaneye "18/17 Türkiye" verip geçmek basılı takvimle uyuşmaz | Acı noktası #5'in Türkiye'deki tam karşılığı | M | **Çok yüksek** | Ücretsiz |
| 3 | **Takvim kaynağı seçici** | Diyanet (varsayılan) / Fazilet / Türkiye Takvimi (temkinli) + sade bir "1983'te ne değişti" açıklaması. BEKART zaten "isteğe bağlı Fazilet vakitleri" sunuyor — talep kanıtlı | Üç ayrı dinî kitleyi tek üründe barındırır | M | Yüksek | Ücretsiz |
| 4 | **Vakit şeffaflık paneli + ±dk düzeltme** | Aktif yöntem, açılar, mezhep, temkin, yaz saati, rakım; her vakit için manuel kaydırma; "yerel camimle eşitle" | Şikayet öfkeye dönüşmeden çözülür. Yorumlarda birebir isteniyor | S | Yüksek | Ücretsiz |
| 5 | **AlarmKit ile gerçek ezan** | Ezan vakti sistem alarmı olarak kurulur: Sessiz/Odak'ı deler, tam uzunlukta çalar, kilit ekranında ve Watch'ta görünür, durdur/ertele sunar. Bildirim yolu yedek olarak kalır | Acı noktaları #3 ve #4 — kategorinin en büyük ve en sahipsiz sorunu | M | **Çok yüksek** | Ücretsiz |
| 6 | **Ezan sesi kütüphanesi** | Türk makamı, Mekke, Medine; vakit başına ayrı ses; ön dinleme; kerahat vakti uyarısı; **süre sınırı olmayan ön-hatırlatma** (yorumlar 45 dk sınırından şikayetçi) | `Audio/` klasörü boş. Türk kullanıcı için tanımlayıcı eksik | M | **Çok yüksek** | Temel ücretsiz, ek sesler Plus |
| 7 | **Kıble: gerçek kuzey + doğruluk kapısı** | `CLHeading.trueHeading` kullanın (`magneticHeading` değil — iOS sapmayı zaten uyguluyor, üstüne elle eklemek çift düzeltme hatası yaratır). `headingAccuracy` negatifse veya kötüyse **oku göstermeyin**, kalibrasyon isteyin. Büyük daire başlangıç açısı kullanın | Acı noktası #6. 74 bin puanlı rakip bu yüzden 1★ alıyor | S | Yüksek | Ücretsiz |
| 8 | **Güneşle kıble doğrulama** | Bulunduğun konum için güneşin azimutunun kıble azimutuna eşit olduğu anı hesaplar: "Bugün 14:37'de dik bir cismin gölgesi kıble hattını verir." Ayrıca yılda iki kez güneşin Kâbe'nin tam üzerinden geçtiği küresel anlar (yaklaşık 27–28 Mayıs ve 15–16 Temmuz) için geri sayım | Manyetometreden tamamen bağımsız doğrulama. Rakiplerde yok | S | Yüksek | Ücretsiz |
| 9 | **Kalıcı çevrimdışı depo + arka plan yenileme** | 12 aylık vakitler SwiftData'ya yazılır; `BGAppRefreshTask` ile tazelenir; widget zaman çizelgesi **tüm günü önceden hesaplar** ki sıfır yenilemeyle bile doğru kalsın | Acı noktaları #9 ve #12 | S | Yüksek | Ücretsiz |
| 10 | **iCloud senkronizasyonu** | Zikir sayaçları, namaz/oruç/kaza kaydı, favoriler, ayarlar | Acı noktası #8 — açık kaynak Kur'an projelerinin en çok oy alan talebi | M | Yüksek | Plus |
| 11 | **"Sıfır veri" gizlilik duruşu** | App Store'da "Veri Toplanmıyor" etiketi; konum işlemenin tamamen cihazda kalması; reklam SDK'sı yok; ayarlarda düz Türkçe açıklama: *konumunuz cihazınızdan çıkmıyor* | Acı noktası #2. Muslim Pro skandalı sonrası bu **satın alma gerekçesi**, uyum maddesi değil | S | Yüksek | Ücretsiz |

### 3.2 İçerik

| # | Özellik | Ne | Çözdüğü ihtiyaç | Efor | Etki | Ücret |
|---|---|---|---|---|---|---|
| 12 | **Kur'an okuyucu (metin + meal)** | Mushaf görünümü, Diyanet meali, yer imi, son okunan yere dönme. **Kaynağı ekranda belirtin** (hangi mushaf baskısı, hangi meal). Font kararı bilinçli olmalı: QCF sayfa-sadık ama **604 ayrı font dosyası** gerektirir; Unicode Hafs fontu tek dosya ama sayfa düzeni birebir olmaz | En çok istenen tek eksik | **L** | **Çok yüksek** | **Ücretsiz olmalı** — Quran.com fiyat tabanını belirliyor; kutsal metni paralı yapmak en hızlı 1★ üreten hamle |
| 13 | **Kur'an dinleyici** | Çoklu kari, ayet vurgulama, **aralık tekrarı** (ezber için), indirilebilir ses, arka planda oynatma | Ezber ve dinleme | L | Yüksek | Temel ücretsiz; indirme ve ek kariler Plus |
| 14 | **Hatim takibi + Ortak Hatim** | Bireysel plan (Ramazan'da günde 1 cüz) ve **grup hatmi**: davet linkiyle çember, otomatik cüz dağıtımı, ortak ilerleme | "Ortak Hatim" ve "Cüz Takip" Türkiye'de ayrı uygulamalar olarak yaşıyor — talep kanıtlı. Davet linki = büyüme motoru | M | **Çok yüksek** | Bireysel ücretsiz, grup Plus |
| 15 | **Dua kütüphanesi** | Sabah/akşam ezkârı, yemek, yolculuk, uyku, hastalık, istihare; Arapça + okunuş + meal + ses; **kaynak ve sıhhat bilgisi açıkça yazılı** | Mevcut `AdhkarContent` altyapısı hazır. Yorumlarda "uydurma hadis" itirazı var — kaynak göstermek güven kazandırır | M | Yüksek | Ücretsiz |
| 16 | **Namaz öğretici** | Abdest ve namaz adım adım (kadın/erkek ayrı), rekât sayıları, namaz sureleri; Arapça/okunuş/meal + ses, ezber modu | Yeni Müslümanlar, gençler, çocuklar. Türkiye'de "Namaz Hocası" 19 bin puanla ayrı bir uygulama | L | Yüksek | Ücretsiz (edinme kancası) |
| 17 | **Türk dinî takvimi — birinci sınıf özellik** | Kandiller **akşam ezanıyla başladığı için bir önceki akşam bildirimi**; üç aylar; mübarek geceler; bayram namazı vakti; **nafile oruç hatırlatıcıları** (eyyam-ı bîz, Pazartesi–Perşembe) | Yılda ~6 kültürel olarak zorunlu uygulama açma anı. e-Diyanet bu eksikten 2★ alıyor. Yabancı uygulamaların en çok yanlış yaptığı yer akşam kaydırması | M | **Çok yüksek** | Ücretsiz |
| 18 | **Hadis derlemesi genişletme** | Günün hadisi → Riyâzü's-Sâlihîn / Kırk Hadis; konu ve arama | Mevcut özelliğin doğal derinleşmesi | M | Orta | Ücretsiz |

### 3.3 Alışkanlık ve topluluk

| # | Özellik | Ne | Çözdüğü ihtiyaç | Efor | Etki | Ücret |
|---|---|---|---|---|---|---|
| 19 | **Kaza namazı takibi** | Doğum + buluğ tarihinden borç hesabı, **kadınlar için hayız günlerinin otomatik düşülmesi**, günlük kayıt, kalan borç widget'ı | Türkiye'de tek başına bir kategori; ASO'da **"kaza namazı"** teriminde 1. sıradaki uygulamanın 1000'den az puanı var — **bedava trafik**. Duygusal olarak çok bağlayıcı | M | **Çok yüksek** | Ücretsiz + istatistik Plus |
| 20 | **Hayız / duraklama modu** | Namaz istemlerini gizler, seriyi bozmaz, kaza hesabından düşer. Erkek kullanıcıya bu özellikler hiç gösterilmez | Pillars'ın en övülen ayrıntılarından. Doğru yapılmazsa saldırgan hissettiriyor | S | Yüksek | Ücretsiz |
| 21 | **Aile / dost çemberleri** | Davet linkiyle özel çember; kimin kıldığı görünür, nazik hatırlatma. **Varsayılan kapalı, paylaşım opt-in** — "sıfır veri" duruşuyla çelişmemeli | Just Pray'in Prayer Circles'ı ve Everyday Muslim'in grup takibi çalıştığını kanıtladı. Türk aile kültürüne çok uygun | L | Yüksek | Plus |
| 22 | **Teheccüd / kıyâm alarmı** | Gecenin son üçte biri hesaplanır, akıllı uyandırma penceresi. AlarmKit ile gerçek alarm | İleri seviye ibadet eden kullanıcıyı bağlar | S | Orta | Plus |
| 23 | **Cuma ritüeli** | Cuma sabahı hatırlatma, Kehf suresi kartı, salavat sayacı | Haftalık, tahmin edilebilir açılış tetikleyicisi. `scheduleJumuah` altyapısı hazır | S | Orta | Ücretsiz |
| 24 | **Ezan vaktinde odak** | Screen Time API ile dikkat dağıtıcı uygulamaları kısa süre kısıtlar veya "Namaz Odak" modu tetikler. **Tamamen opsiyonel** | FivePrayer'ın tek kancası bu ve 4.9★ aldı. Konuşulur bir özellik | M | Yüksek | Plus |
| 25 | **Apple Health** | Zikir/tefekkür oturumları `HKCategoryType.mindfulSession` olarak, oruç günleri Health'e yazılır | Zikri ölçülebilir bir pratik yapar; Apple'ın editoryal ilgisini çeker. Sahipsiz niş | S | Orta | Ücretsiz |

### 3.4 Apple ekosistemi

| # | Özellik | Ne | Çözdüğü ihtiyaç | Efor | Etki | Ücret |
|---|---|---|---|---|---|---|
| 26 | **Apple Watch + komplikasyonlar** | Sonraki vakit ve geri sayım komplikasyonu, bilekten namaz kaydı, kıble oku (hizalanınca haptik), Digital Crown ile zikir, **sessiz haptik ezan** | Camide sesli bildirim istemeyen için haptik ezan gerçek ihtiyaç. TR yorumlarında rakiplerin Watch desteği bozuk — **neredeyse rakipsiz alan**. Watch'ı **ödeme duvarına koymayın**, bu pazarda tepki çekiyor | **L** | **Çok yüksek** | Temel ücretsiz |
| 27 | **App Intents + Siri + Control Center + Aksiyon Düğmesi** | "Bugün iftar saat kaçta?", "Kıble nerede?", "Namazımı işaretle", "Zikre başla". iOS 26'da **tek bir App Intent** aynı anda Siri, Kısayollar, Control Center kontrolü ve Live Activity butonu olarak çalışıyor | Efor/etki oranı kategorinin en iyisi. Apple featuring için en güçlü sinyallerden | S | Yüksek | Ücretsiz |
| 28 | **StandBy** | Yatay şarjda tam ekran sonraki vakit + geri sayım + hicri tarih; gece kırmızı tonlu; Ramazan'da imsak/iftar geri sayımı | Başucu kullanımı — ibadet uygulaması için doğal yüzey | S | Orta | Ücretsiz |
| 29 | **Live Activity genişletme** | İftar/sahur geri sayımı; iOS 26'da Live Activity içindeki **butonla "kıldım" işaretleme** (intent `LiveActivityIntent` olmalı); vakit geçince otomatik kapanma | Mevcut `PrayerLiveActivity` üstüne düşük maliyetli derinleşme. Ramazan'da çok görünür | S | Yüksek | Ücretsiz |
| 30 | **iPad + Mac** | Cihaz ailesi genişletilir; iPad'de çift sütun Kur'an, Mac'te menü çubuğu vakit göstergesi | Kur'an okuma iPad'de çok daha iyi | M | Orta | Ücretsiz |
| 31 | **Vision Pro** | Sakin bir mekânda Kur'an okuma ve zikir; kıble mekânsal ok olarak | Kullanıcı sayısı düşük ama **Apple featuring ve basın getirisi orantısız yüksek** | L | Düşük (kullanıcı) / Yüksek (görünürlük) | Plus |

### 3.5 Araçlar ve niş

| # | Özellik | Ne | Çözdüğü ihtiyaç | Efor | Etki | Ücret |
|---|---|---|---|---|---|---|
| 32 | **Zekât hesaplayıcı** | Güncel altın/gümüş nisabı, mezhep desteği, kalem kalem giriş, PDF çıktı, "zekât yılı" hatırlatıcısı | TDV'nin ayrı uygulaması var — talep kanıtlı. **Türkiye'de nüfusun %78,6'sı fitre/zekât/sadaka veriyor** — namaz kılandan çok daha geniş kitle | M | Yüksek | Ücretsiz (güven kazandırır) |
| 33 | **Feraiz (miras) hesaplayıcı** | Akrabalık girilir, mezhebe göre paylar ve delilleri | Türkiye'de sadık niş; unutulmaz bir "bunu da yapıyor" etkisi | M | Düşük–Orta | Plus |
| 34 | **Hac & Umre modu** | Menâsik rehberi, tavaf/sa'y sayacı, harem içi harita, bölgesel vakit, telbiye, çevrimdışı paket | Yüksek duygusal değer ve ödeme isteği. **ASO'da "hac umre" teriminde ilk organik sonucun 15 puanı var — pazar tamamen boş** ve Diyanet'in kendi uygulaması 1.77★ | L | Orta–Yüksek | **Plus** |
| 35 | **Çocuk modu** | Basitleştirilmiş arayüz, namaz öğretici, rozet ödülleri, ebeveyn görünümü, PIN korumalı ayarlar | Aile pazarı; Apple'ın aile koleksiyonlarına girme şansı | L | Orta | Plus / Aile |
| 36 | **Cami modülü geliştirmesi** | Cemaat vakitleri (kullanıcı katkılı, düzeltilebilir), cuma hutbe saati, kadınlar bölümü/abdesthane bilgisi. **Cemaat vakti asla kullanıcının kendi hesabını ezmemeli** | Mevcut `MosquesView` üstüne. Uyarı: dizin özellikleri **veri tazeliği yükümlülüğüdür**, özellik değil | M | Orta | Ücretsiz |
| 37 | **Paylaşılabilir tefekkür kartları** | Esmâ, hadis, ayet, dua ve **kandil tebriği** için zarif tasarlanmış görsel kartlar; tek dokunuşla WhatsApp/Instagram | **Sıfır maliyetli organik büyüme motoru.** `ShareImage.swift` hazır. Türkiye'de kandil tebriği paylaşma kültürü olağanüstü güçlü | S | **Yüksek** | Ücretsiz |
| 38 | **Hediye / Sadaka-i Cariye tier'ı** | Aboneliği başkası için satın alma: "Arkadaşım", "Ailem", "Komşum" paketleri. Fazilet Takvimi'nin modeli (₺55 / ₺259 / ₺1.019,99) | **Pazarda bulduğum en kültürel uyumlu para kazanma fikri ve kimse kopyalamıyor.** Satın almayı bir *sevap* eylemine çevirerek "din parayla olmaz" itirazını tamamen etkisizleştiriyor | M | **Yüksek** | Gelir kalemi |

---

## 4. Türkiye'ye Özel Fırsatlar

### 4.1 Diyanet ile uyum — teknik gerçekler
- **Resmî API mevcut:** `awqatsalah.diyanet.gov.tr` (Din İşleri Yüksek Kurulu). JWT ile kimlik doğrulama, **45 dakikalık token ömrü**, **endpoint başına 5 istek** limiti, erişim için form doldurup Diyanet'e posta ile başvuru. GitHub'da .NET referans istemcisi var.
- **Bu bir çalışma zamanı API'si değil, toplu senkron API'sidir.** Doğru mimari: ilçe bazında yıllık tabloları önceden çekip cihazda/kendi arka ucunuzda saklamak. Bu aynı hamlede *"internetsiz açmıyor"* şikayetini de çözer.
- **Temkin gerçeği:** Diyanet 1983'ten beri imsak/yatsıda 18° kullanıyor ve temkin paylarını uyguluyor (doğuş/batış 7 dk, öğle 5 dk, ikindi 4 dk; imsak ve yatsıda temkin yok). Genel kütüphaneye "Türkiye" ayarı verip geçerseniz basılı takvimle dakikalık fark oluşur ve bu "vakitler yanlış" olarak yorumlanır.
- **Marka uyarısı:** "Diyanet" en yüksek güven taşıyan kelime ama devlet kurumu. Rakiplerden biri *"Diyanet'in uygulaması olmadığı hâlde kendini öyle gösteriyor"* diye 1★ aldı. **"Diyanet uyumlu" / "Diyanet takvimine göre" deyin; resmîlik iması vermeyin ve açık bir bağlantısızlık notu koyun.**

### 4.2 Üç takvim geleneği — bir ürün kararı
1983'te temkinin kaldırılması Türkiye'de kalıcı bir ayrışma yarattı; **imsakte 15–20 dakikaya varan farkla üç gelenek** ve her birinin kitlesi var:
- **Diyanet** (devlet, varsayılan, çoğunluk)
- **Fazilet Takvimi** (temkin korunmuş, imsak ~20 dk daha erken)
- **Türkiye Takvimi / İhlas** (1983 öncesi yöntem)

BEKART'ın uygulaması zaten "isteğe bağlı Fazilet vakitleri" sunuyor. **Mihrab bu seçiciyi dürüst bir açıklamayla sunarsa üç kitleyi birden kazanır ve rakiplerinin hiçbirinin yapmadığı bir olgunluk gösterir.**

### 4.3 Mevsimsellik ve gerçek kitle büyüklüğü
- Türkiye'de **nüfusun %62–67'si Ramazan'da tam oruç tutuyor**, ancak **yalnızca %31,2'si düzenli namaz kılıyor** ve **%78,6'sı fitre/zekât/sadaka veriyor**.
- **Sonuç: Ramazan kitleniz namaz kitlenizin yaklaşık iki katı.** İmsakiye/iftar özellikleri huninin ağzıdır; namaz takibi ise elde tutma katmanı. Zekât hesaplayıcı da namazdan geniş bir kitleye dokunuyor.
- Yalnızca sezonluk imsakiye uygulamaları bile 25 bin puana ulaşıyor — talebin büyüklüğünün ölçüsü.
- **Kandiller** yılda ~6 kültürel zorunlu açılma anı yaratıyor ve **akşam ezanıyla başlıyor** (Gregoryen tarihin bir önceki akşamı). Yabancı uygulamalar bu kaydırmayı sürekli yanlış yapıyor.

### 4.4 Ödeme davranışı ve fiyatlandırma
- **Rakiplerin canlı TRY fiyatları:** Fazilet yıllık ₺55 (+ hediye paketleri ₺55 / ₺259 / ₺1.019,99); Quran Widgets yıllık ₺99,99–₺309,99; irade yıllık ₺249,90–₺599,90; Nurlu yıllık ₺399,99–₺999,99. **En pahalı kohortun puanı en düşük** (Nurlu 4.43) — fiyat ve memnuniyet ters orantılı.
- Türk anketlerinde ~**%33 tek seferlik ödemeyi tercih ediyor**, ~%65 aylık aboneliği kabul ediyor. Yani **ömür boyu tier'ı ödemeye istekli kitlenin üçte birini yakalıyor** ve pazarın en yüksek sesli şikayetini (*"süresiz pro almıştım, yine para istiyorsunuz"*) etkisiz kılıyor.
- **Apple otomatik yenileme kuralı kritik:** fiyat artışları belirli bir eşiğin altında kalırsa abonelik sessizce yenilenir; üstüne çıkarsa kullanıcı onayı gerekir ve kohortu kaybedersiniz. TL enflasyonu düşünüldüğünde **yıllık fiyatı ileride yapılacak zamların bu eşiği aşmayacağı şekilde konumlandırın**, ve TR fiyatlarını Apple'ın otomatik döviz çevrimine bırakmayın, elle belirleyin.
- **Operatör faturasına yansıtma (Türk Telekom vb.) Türkiye'de ciddi bir ödeme kanalı** — kartı olmayan, yaşça büyük dindar kitle için ödeyebilir tabanı gözle görülür genişletiyor.
- **Türkiye'de iOS payı ~%24** — küçük ama gelir açısından yüksek gelirli, ödeyebilen kesim. Türkiye bir **hacim pazarı**, ARPU pazarı değil; global (ABD/İngiltere/Almanya/Körfez) gelirin yaşadığı yer.
- **Diaspora açık bir fırsat:** rakipler açıkça "Türkiye'den Almanya'ya, Hollanda'dan ABD'ye" diye pazarlıyor. Türkçe + Diyanet yöntemi, Almanya/Hollanda/Avusturya'da **AB düzeyinde ARPU, Türkiye düzeyinde rekabet** demek.

### 4.5 Konumlanma cümlesi
> **"Sıfır reklam. Hiçbir zaman. Konumunuz cihazınızdan çıkmaz. Vakitler Diyanet takvimine göre."**

Bu, Türkiye'de rakiplerin **yapısal olarak** veremeyeceği bir söz — gelir modelleri reklama bağlı. Ve şikayet dili gösteriyor ki bu bir kullanılabilirlik iddiası değil, **ahlaki bir iddia** olarak algılanıyor.

---

## 5. ASO ve Büyüme

### 5.1 Türkiye anahtar kelime haritası

| Terim | 1. sıradaki uygulama | Zorluk / fırsat |
|---|---|---|
| **namaz vakti / ezan** | Ezan Vakti Pro (~491K) | En yüksek hacim, en yüksek zorluk. Apple ikisini neredeyse eşanlamlı işliyor — tek başlıkla ikisine birden oynayabilirsiniz |
| **kıble** | Kıble Bulucu (~74K) | **Ayrı, büyük, para kazandıran bir niyet.** İlk 12 sonucun 6'sı sadece kıble uygulaması |
| **zikirmatik** | Zikirmatik (~28K) | **Kazanılabilir en iyi ana terim** — ilk 12'nin toplamı ~55K |
| **diyanet** | e-Diyanet (**3.37★**) | **Pazarın en değerli, en düşük kaliteli terimi** |
| **kaza namazı** | 5te5 (<1.000 puan) | **Tamamen açık** |
| **hac umre** | (Diyanet'inki 1.77★) | **Tamamen açık** — ilk organik sonuç 15 puan |
| **esmaül hüsna** | ~2.350 puan | Açık — ve Mihrab'ın zaten en güçlü modülü |
| **ramazan imsakiye** | ~25K | Patlayıcı sezonluk; sıralama **Şaban'dan önce** kazanılmalı |
| **kandil / tesbihat / kerahat vakti** | — | Düşük rekabetli uydu terimler |

Ayrıca: Türkçe mağaza hem `kıble` hem `kible` yazımını indeksliyor — **noktasız-i varyantlarını kapsayın**.

### 5.2 Metadata önerisi

Limitler: **başlık 30, alt başlık 30, anahtar kelime alanı 100** (pratikte **bayt** sınırı — Türkçe `ı ğ ş ç ö ü` ve Arapça harfler 2–3 bayt, dolayısıyla ~60–70 Türkçe karakterlik bütçe düşünün). Başlık/alt başlıktaki kelimeleri anahtar alanına **tekrar yazmayın**; virgülden sonra boşluk koymayın.

**Türkiye (tr — birincil)**
```
Başlık   (28): Mihrab: Namaz Vakti ve Kıble
Alt başlık(30): Ezan, Zikirmatik, İmsakiye
Anahtar      : vakit,imsak,iftar,sahur,dua,tesbih,esmaül,hüsna,kuran,
               ramazan,kandil,hicri,takvim,kaza,pusula,diyanet,hadis
```

**Ramazan varyantı** (Şaban'ın başında değiştir, bayramdan bir hafta sonra geri al)
```
Başlık   (30): Mihrab: İmsakiye 2027 Ezan
Alt başlık(30): Namaz Vakti, İftar, Sahur, Dua
```

**Türkiye storefront — en-GB (ikincil, kullanıcıya görünmez ama indekslenir)**
> Apple her mağazada ikincil dilleri de indeksler. Türkiye mağazasında **Türkçe + İngilizce (UK)** = 160 değil **320 indekslenebilir karakter**. Bu, elinizdeki en büyük bedava kaldıraç.
```
Anahtar      : prayer,times,qibla,compass,muslim,islam,quran,dhikr,tasbih,
               athan,adhan,ramadan,fasting,hijri,salah,tracker
```

**ABD (en-US)**
```
Başlık   (28): Mihrab: Prayer Times & Qibla
Alt başlık(30): Athan, Dhikr, Quran & Ramadan
Anahtar      : adhan,azan,salah,salat,namaz,tasbih,tasbeeh,zikr,dua,99,
               names,allah,asma,husna,iftar,suhoor,tracker,muslim,hijri
```
ABD mağazasında **Arapça bir ikincil dildir** — Arapça İslami terimleri oraya yazarsanız ABD'de o terimlerde sıfır maliyetle sıralanırsınız:
```
Arapça       : مواقيت,الصلاة,أذان,القبلة,بوصلة,أذكار,تسبيح,أسماء,الحسنى,رمضان,إمساكية
```

**Kural:** aynı kelimeyi iki dilde tekrarlamayın; kelime kombinasyonları yalnızca **aynı dil içinde** oluşur.

**Başlık stratejisi notu:** Türkiye'de marka bilinirliği neredeyse yok — çartın tepesindeki uygulamaların adı düpedüz "Namaz Vakti" ve "Ezan Vakti Pro". Bir rakip, ürün içinde kendi markasını korurken **App Store başlığını jenerik terimlere çevirdi**. Marka-önce isimlendirme TR'de ölçülebilir bir dezavantaj; `Mihrab:` öneki kısa tutulup kalan alan jenerik terimlere ayrılmalı.

### 5.3 2026'da değişen ve sömürülmesi gereken kurallar
- **Özel Ürün Sayfaları (CPP) 35'ten 70'e çıktı ve artık anahtar kelime atanabiliyor; arama sonuçlarında organik olarak görünüyorlar.** Bu, CPP'yi bir reklam iniş sayfası olmaktan çıkarıp **ASO varlığına** dönüştürdü. CPP'ler tipik olarak varsayılan sayfaya göre **%18–26 dönüşüm artışı** getiriyor. Üretin: `ramazan-imsakiye`, `kible`, `zikir-tesbih`, `esma-ul-husna`, `kaza-namazi`, `apple-watch` + EN/AR karşılıkları.
- **Bağımsız inceleme gönderimi:** In-App Event'ler ve kritik hata düzeltmeleri artık incelemedeki bir sürümden **ayrı** gönderilebiliyor. Ramazan etkinliğiniz bekleyen bir build'e takılmaz.
- **In-App Events:** 15 onaylı / 10 canlı / her biri 31 güne kadar / başlangıçtan **14 gün önce** yayınlanabilir. Etkinlik adları **aranabilir ve indekslenir** — `Ramazan 2027 İmsakiye` adlı bir etkinlik, ana metadata'nızın taşıyamayacağı sezonluk terimlerde sıralanır. Ayrıca App Store Connect içinden **Apple editoryal değerlendirmesine sunulabilir**.
- **IAP promosyon kodları 26 Mart 2026'da sona eriyor** — teklif kodlarına (offer codes) geçin. Teklif kodları artık tüm IAP türlerini kapsıyor.
- **Creative Assets / Creative Asset Library:** ürün sayfası başlığında ve doğrudan arama sonuçlarında görünen zengin görsel/video; tam uygulama güncellemesi olmadan gönderilebiliyor. Ramazan görsel değişimi için ideal.
- **Liquid Glass:** Apple, tam iOS 26 tasarım sistemi desteğini Eylül 2026 itibarıyla bekliyor. Mihrab zaten iOS 26 SwiftUI — bu bir featuring varlığı.

### 5.4 Ekran görüntüsü stratejisi
1. **İlk kare her şeydir** — aramada yalnızca ilk 1–2 görünür. Buraya "sonraki vakit + geri sayım" ve tek cümlelik ahlaki vaat: **"Sıfır reklam. Diyanet uyumlu."**
2. **Widget + Live Activity kilit ekranında** — rakiplerin en çok övüldüğü ve en çok şikayet edildiği yer.
3. Kıble pusulası + AR + doğruluk göstergesi.
4. Zikirmatik / tesbihat.
5. Esmâ-ül Hüsnâ — görsel olarak en çarpıcı ekranınız.
6. Ramazan hub'ı — **sezonda 1. sıraya alın**.
7. **Türkçe mağazada Türkçe ekran görüntüsü** kullanın.
8. App Preview videosu (15–30 sn), sessiz izlenebilir olmalı: geri sayım → ezan → kıble → zikir.

### 5.5 Ramazan 2027 takvimi

**Tarihler:** Ramazan 2027 **8 Şubat**; 2028 **28 Ocak**; 2029 **16 Ocak**. (Hilal gözlemi yapan ülkelerde ±1 gün kayabilir — kullanıcıya başlangıç günü seçtirin.)

**Sezon Şubat'ta değil, Aralık'ta başlıyor:** Üç aylar Ramazan'dan yaklaşık 60 gün önce Recep ile başlar ve kandiller uygulama açılışlarında sıçrama yaratır.

**Sektör verisi:**
- Ramazan'da İslami uygulamalarda günlük indirmeler **1.6×–2.2×**, en yüksek göreli sıçrama **3.1×**; **zirve Ramazan'ın ilk 1–2 günü**. Oturum süresi 22,5 → 37 dakika.
- **En yüksek yaşam boyu değere sahip kullanıcılar Ramazan başlamadan ~2 hafta önce ediniliyor** (bu kohortlarda D7/D14/D30 elde tutma ~%20 daha yüksek).
- **Utilities kategorisinde indirmeler Ramazan'da +%26, ama zirve bayramdan SONRAKİ iki haftada +%43.** Bayramda bütçeyi kesmeyin.
- Türkiye'de Ramazan dönemi kurulum artışı ~%9 (Suudi Arabistan +%34, Pakistan +%21).

| Zaman | Yapılacak |
|---|---|
| **Kasım 2026** | Apple **featuring adaylığı** gönderilir (Apple en az 3 hafta ister, 3 aya kadar önerir). Influencer anlaşmaları **şimdi** yapılır — Ramazan'da fiyatlar ~%40 artıyor |
| **~11 Aralık 2026** | Üç aylar başlar. Kandil bildirimleri ve ilk metadata değişimi yayında |
| **Ocak 2027** | Miraç ve Berat kandilleri — organik içerik zirveleri, kreatif testi |
| **T−3 hafta (~18 Ocak)** | Ramazan CPP'leri anahtar kelimeleriyle yayında; Creative Assets yüklü; imsakiye özelliği çıkmış |
| **T−2 hafta (25 Oca – 7 Şub)** | **En yüksek değerli edinme penceresi — ücretli harcamanın zirvesi.** In-App Event yayına alınır. Camii/dernek dağıtımı: QR kodlu basılı imsakiye kartları (DİTİB gibi Avrupa Türk cemaat merkezleri dahil) |
| **8 Şub – 8 Mar** | Ramazan. Sahur öncesi ve iftar sonrası bildirim; iftar geri sayımı Live Activity |
| **~5–6 Mart** | **Kadir Gecesi — yılın tek en büyük etkileşim gecesi** |
| **9–11 Mart** | Ramazan Bayramı — ayrı kreatif fazı, **harcamayı kesmeyin** |
| **12–26 Mart** | Bayram sonrası: Utilities kurulumları burada zirve yapıyor. Şevval orucu hatırlatıcısı, kaza takibi, hatim devamı ile elde tutma kampanyası |

### 5.6 Büyüme kanalları
- **Apple Search Ads:** Türkiye'de CPI ≈ **$1,02**, ABD'de ≈ **$4,06** — Türkiye ABD'den ~4 kat ucuz. Yapı: (1) "mihrab" marka savunması (ucuz, zorunlu — rakipler adınıza teklif verir), (2) tam eşleme Türkçe ana terimler, (3) rakip terimleri, (4) keşif. Her biri kendi CPP'sine yönlendirilmeli. **Mart 2026'dan itibaren CPA tavanları kalktı**, otomatik teklif verme hacim istiyor — çok sayıda küçük kampanya yerine tema başına tek kampanya kurun.
- **Apple featuring — en asimetrik hamle.** Apple 2026'da Today sekmesinde bir Ramazan editoryal hub'ı yayınladı ve bu vertikalden uygulamaları isim vererek öne çıkardı. Kriterler: görsel işçilik (en yüksek ağırlık), **yeni Apple çerçevelerinin benimsenmesi** (WidgetKit, Live Activities, Dynamic Island, App Intents, Control Center, watchOS, visionOS), mevsimsel uyum ve geliştirici hikâyesi. Başvuru yalnızca App Store Connect → Featuring Nominations üzerinden.
- **Paylaşılabilir kartlar (#37)** — kandil tebriği paylaşma kültürü Türkiye'de bedava dağıtım motoru.
- **Ortak hatim ve aile çemberleri (#14, #21)** — davet linki doğal K-faktörü. Bunları büyüme özelliği olarak tasarlayın.
- **TikTok/Reels:** en kaydedilebilir varlığınız Live Activity/Dynamic Island geri sayımı. Ayrıca Esmâ estetiği döngüleri, tesbih ASMR sayacı, "iftara kaç dakika" ekran kayıtları.
- **Türk influencer maliyetleri (2026):** YouTube entegrasyonu makro (100K–1M) ortalama ~₺10.000/video; mega (1M+) ₺25.000+. YouTube entegrasyonu bir Instagram Story'nin 5–6 katı. **Ramazan'da fiyatlar ~%40 artıyor → Kasım/Aralık'ta anlaşın.**
- **Uyarı:** kategori liderinin ABD indirmelerinin ~%60'ı ücretli ve iOS kurulumlarının ~%90'ı marka aramasından geliyor. **Globalde jenerik terimlerde organik keşif neredeyse yok.** Türkiye'de marka dışı organik hâlâ mümkün — bu yüzden TR odağı doğru strateji.

### 5.7 Para kazanma önerisi

**Ücretsiz katman cömert olsun:** vakitler, ezan ve bildirim, kıble, zikirmatik, Esmâ, Kur'an metni, kaza takibi, **widget'lar ve Apple Watch**. Widget veya Watch'ı paralı yapmak bu pazarda kanıtlanmış bir itibar mayını.

**Mihrab Plus:** iCloud senkron, gelişmiş istatistik, ek ezan sesleri ve kariler, çevrimdışı Kur'an sesi, aile çemberleri, Hac/Umre modu, temalar, feraiz.

| Pazar | Aylık | Yıllık | Ömür boyu |
|---|---|---|---|
| **Türkiye** | ~₺79,99 | ~₺399,99 (*"ayda ₺33"* çerçevesi) | ~₺1.199,99 |
| **Global** | $4,99 | $24,99 | $69,99 |

- `,99` sonlandırması TR perakendesinde standart.
- **Ömür boyu ≈ yıllığın 3 katı** olsun ki yinelenen geliri yemesin — ama Türkiye'de görünür şekilde öne çıkarın.
- **Ömür boyu alanları asla sonradan aboneliğe çevirmeyin.** Pazar liderinin bu hamlesi kalıcı marka hasarı yarattı.
- **7 gün deneme, yalnızca yıllıkta.** Denemelerin %82'si 0. günde başlıyor, dolayısıyla **paywall onboarding'in sonunda** gösterilmeli.
- **Hediye / Sadaka-i Cariye tier'ı (#38)** ekleyin — kültürel olarak en uyumlu ve kimsenin kopyalamadığı gelir kalemi.
- İptali kolaylaştırın ve ayarlarda görünür yapın; bunu *doğru yapmak* pazarlanabilir bir farktır.
- **TR fiyatlarını aylık gözden geçirin.** Enflasyon ve döviz yeniden fiyatlaması ARPU'yu sessizce eritir.

---

## 6. Önceliklendirme — Yol Haritası

### 🔴 Hemen (0–1 ay) — güven temeli
Bunlar olmadan diğer her şey kumdan kale. Hepsi yüksek etki / düşük–orta efor.

| # | İş | Efor | Neden şimdi |
|---|---|---|---|
| 1 | **Cihaz üstü vakit hesaplama + kalıcı disk cache + arka plan yenileme** (#1, #9) | M | Uygulamanın çekirdek işlevi internete bağımlı. Tek en büyük kırılganlık |
| 2 | **AlarmKit ile gerçek, tam uzunlukta ezan** (#5) | M | Kategorinin en büyük çözülmemiş sorunu ve şu anda **sahipsiz**. Doğrudan pazarlanabilir vaat |
| 3 | **Ezan sesi kütüphanesi** (#6) | M | `Audio/` boş. Türkiye'de tanımlayıcı eksik |
| 4 | **Kıble: gerçek kuzey + doğruluk kapısı** (#7) | S | Sessizce yanlış yön göstermek kabul edilemez; rakipler bundan 1★ alıyor |
| 5 | **Vakit şeffaflık paneli + ±dk düzeltme** (#4) | S | Şikayeti öfkeye dönüşmeden çözer |
| 6 | **App Intents → Siri + Control Center + StandBy + Live Activity butonu** (#27, #28, #29) | S | Dördü tek altyapıdan gelir. Apple featuring için en ucuz sinyal |
| 7 | **Paylaşılabilir kartlar** (#37) | S | `ShareImage.swift` hazır. Bedava büyüme |
| 8 | **"Sıfır veri" duruşu ve iletişimi** (#11) | S | Kodda değil mesajda iş var; konumlanmanın temeli |
| 9 | **Güneşle kıble doğrulama** (#8) | S | Küçük iş, büyük etki, rakiplerde yok |

### 🟠 Sonra (1–3 ay) — farklılaşma ve Ramazan hazırlığı
Hedef: **Aralık 2026'da üç aylar başlamadan** bunların çoğu yayında olmalı.

| # | İş | Efor | Neden |
|---|---|---|---|
| 10 | **Diyanet vakitleri — gerçek temkin ile + takvim kaynağı seçici** (#2, #3) | M | Türkiye'de vakit tartışmasını bitirir ve rakiplerin yapmadığı bir olgunluk gösterir |
| 11 | **Kaza namazı takibi + hayız/duraklama modu** (#19, #20) | M | Türkiye'ye özel, duygusal, çok bağlayıcı; ASO'da terim neredeyse boş |
| 12 | **Kur'an okuyucu (metin + meal)** (#12) | L | "Tek uygulamam" olabilmenin ön şartı. Ücretsiz olmalı |
| 13 | **Türk dinî takvimi — kandiller, üç aylar, nafile oruç** (#17) | M | Yılda 6 doğal geri dönüş tetikleyicisi; akşam kaydırması doğru yapılmalı |
| 14 | **Hatim takibi + Ortak Hatim** (#14) | M | Ramazan'ın en güçlü özelliği + davet linkiyle büyüme motoru |
| 15 | **iCloud senkronizasyonu** (#10) | M | Seri ve kayıt kaybı en hızlı terk sebeplerinden |
| 16 | **Zekât hesaplayıcı** (#32) | M | Nüfusun %78,6'sına dokunur; Ramazan zirvesi; ücretsiz kalsın |
| 17 | **Dua kütüphanesi genişletme, kaynak bilgisiyle** (#15) | M | Mevcut modelin üstüne içerik işi; güven kazandırır |
| 18 | **Hediye / Sadaka-i Cariye tier'ı** (#38) | M | Kültürel olarak en uyumlu gelir kalemi; rakipsiz |
| 19 | **ASO paketi: CPP'ler, In-App Event, ikincil dil doldurma, sezonluk metadata** | S | Kod işi değil, ama Ramazan'ın tek en yüksek getirili hazırlığı |

### 🟡 İleride (3 ay+) — genişleme

| İş | Efor | Not |
|---|---|---|
| **Apple Watch + komplikasyonlar** (#26) | L | Etkisi çok yüksek, alan neredeyse rakipsiz. Ramazan çekirdeğini bozmamak için sonraya — ama Ramazan 2028'in ana kozu bu olmalı. Ödeme duvarına koymayın |
| **Kur'an dinleyici + kari indirme** (#13) | L | Plus'ın en güçlü gerekçelerinden |
| **Namaz öğretici** (#16) | L | Yeni Müslüman ve genç kitlesi; edinme kancası |
| **Aile / dost çemberleri** (#21) | L | Gizlilik tasarımı "sıfır veri" duruşuyla çelişmemeli |
| **Hac & Umre modu** (#34) | L | ASO'da terim tamamen boş, Diyanet'inki 1.77★. Yüksek ödeme isteği |
| **iPad + Mac** (#30) | M | Kur'an okuyucudan sonra anlamlı |
| **Ezan vaktinde odak** (#24) | M | Güçlü ama izin sürtünmesi var; opsiyonel tutulmalı |
| **Teheccüd** (#22), **Cuma ritüeli** (#23), **Apple Health** (#25) | S | Küçük, tatlı eklemeler; boşluklara serpiştirilir |
| **Hadis derlemesi** (#18), **cami modülü** (#36) | M | İçerik ve veri işi |
| **Feraiz** (#33), **çocuk modu** (#35) | M–L | Niş; ana eksen oturduktan sonra |
| **Vision Pro** (#31) | L | Kullanıcı az, featuring/basın getirisi yüksek |

---

## 7. Teknik Notlar — Uygulama Sırasında Dikkat

| Konu | Uyarı |
|---|---|
| **Bildirim sınırı** | iOS'ta bekleyen yerel bildirim üst sınırı **64**. Günde 5–6 uyarı ile ~10–12 günlük ömür demek. Sınırı aşmak **tüm bildirimlerin sessizce ölmesine** yol açabilir. Öne çıkarma stratejisiyle zarifçe azaltın; her öne gelişte, konum değişiminde, saat dilimi değişiminde ve `BGAppRefreshTask` ile yeniden kurun |
| **Yaz saati** | Öğle = 12 + TZ − Boylam/15 − zaman denklemi. Yanlış saat dilimi tüm vakitlerde temiz bir ±1 saat hatası verir — sahada en sık görülen hata ve Ramazan'da iftarı yanlış yapar. Saat dilimini koordinattan türetin, `NSSystemTimeZoneDidChange` ve önemli konum değişiminde yeniden hesaplayın, **mutlak zamanları saat dilimi olmadan saklamayın** |
| **Yüksek enlem** | Üç standart kural (Gecenin Ortası, Yedide Bir, Açı Tabanlı). `adhan-swift`'te yüksek enlemlerde **ikindinin öğleden önce dönebildiği açık bir hata var** — altı vaktin artan sırada olduğunu doğrulayın ve bozuksa anlamsız bir çizelge göstermek yerine hata verin |
| **Kıble yönü** | Büyük daire başlangıç açısı hesaplayın. Kuzey Amerika'da bu **kuzeydoğu** verir ve bazı cemaatlerin tarihsel güneydoğu uygulamasıyla çelişir — canlı bir fıkhi tartışma. Yöntemi uygulama içinde açıklayın |
| **Hicri tarih** | Hesaplanan hicri tarihi asla kesin diye sunmayın. **−2…+2 gün kaydırma** sunun |
| **Yuvarlama** | En yakın dakikaya / yukarı / yok seçenekleri basılı takvimle ±1 dakikalık farklar üretir. Politikayı belgeleyin veya seçtirin |
| **Kur'an tipografisi** | QCF sayfa-sadık ama **sayfa başına bir font, 604 dosya** demek ve satırlar `page_number` + `line_number` ile gruplanmalı (bir satır birden çok ayetten kelime içerebilir). Unicode Hafs tek dosya ama sayfa düzeni birebir olmaz. **Bilinçli seçin ve kullanıcıya söyleyin** |
| **İçerik dili** | Meallerde **"Allah"** kullanın, "Tanrı" değil. Harekeler kullanıcılar tarafından tek tek denetleniyor. Mushaf baskısını, meali ve hadis kaynağını ekranda belirtin |
| **Dizin özellikleri** | Cami ve helal dizinleri bir özellik değil, **veri tazeliği yükümlülüğüdür**. Kullanıcı düzeltmesi olmadan yapmayın |

---

## 8. Kaynaklar

**Türkiye**
[Ezan Vakti Pro — App Store TR](https://apps.apple.com/tr/app/ezan-vakti-pro/id437447439?l=tr) · [Şikayetvar dosyası](https://www.sikayetvar.com/ezan-vakti-pro) · [kumar reklamı şikayeti](https://www.sikayetvar.com/ezan-vakti-pro/ezan-vakti-proda-casino-reklami-gorulmesi-ve-kaldirilmasi-talebi) · [müstehcen reklam şikayeti](https://www.sikayetvar.com/ezan-vakti-pro/dini-icerikte-cinsel-reklamlar-saygisizlik-olusturuyor)
[e-Diyanet](https://apps.apple.com/tr/app/e-diyanet/id6745179920?l=tr) · [Diyanet Mobil Hizmetler](https://mobilhizmetler.diyanet.gov.tr/yazilimlar.html)
[Diyanet AwqatSalah API](https://awqatsalah.diyanet.gov.tr/index.html) · [GitHub referans istemci](https://github.com/DinIsleriYuksekKurulu/AwqatSalah) · [REST spesifikasyonu (PDF)](https://awqatsalah.diyanet.gov.tr/files/56d83ac4-f7f5-4f6e-9b9e-b1ffeebf1b6a.pdf)
[Diyanet temkin açıklaması](https://vakithesaplama.diyanet.gov.tr/temkin.php) · [vakit kıyaslamaları](https://vakithesaplama.diyanet.gov.tr/vakit_kiyaslamalari.php) · [Fazilet Takvimi suâl-cevap](https://fazilettakvimi.com/sual-ve-cevaplar/13/) · [Türkiye Takvimi](https://www.turktakvim.com/index.php?link=html%2Fmuhim_tenbih.html) · [1983 değişikliği — Türkiye Gazetesi](https://www.turkiyegazetesi.com.tr/gundem/namaz-vakitleriyle-34-yil-once-oynandi-523459)
[Ortak Hatim](https://apps.apple.com/us/app/ortak-hatim/id6742418688) · [Cüz Takip](https://apps.apple.com/au/app/c%C3%BCz-takip/id6760223262) · [TDV Zekat](https://apps.apple.com/tr/app/tdv-zekat-hesaplama/id1470427829) · [Feraiz](https://apps.apple.com/tr/app/feraiz-miras-hesaplama/id1577031741) · [Kaza Tracker](https://apps.apple.com/us/app/kaza-tracker-qada-prayers/id6742993708)
Oruç/ibadet oranları: [Ipsos — Marketing Türkiye](https://www.marketingturkiye.com.tr/haberler/ipsos-arastirdi-iste-turkiyede-oruc-tutanlarin-orani/) · [Optimar — Memurlar.net](https://www.memurlar.net/haber/830026/optimar-anketine-gore-oruc-tutanlarin-orani.html)
Muslim Pro veri skandalı TR basını: [Hürriyet](https://www.hurriyet.com.tr/teknoloji/muslim-pro-uygulamasi-abd-ordusuna-verilerini-mi-satiyor-41666208) · [Anadolu Ajansı](https://www.aa.com.tr/tr/dunya/abd-ordusunun-dunya-genelindeki-telefon-uygulamalarindan-veri-topladigi-iddia-edildi/2046040)
Ödeme ortamı: [Business of Apps — Türkiye](https://www.businessofapps.com/data/turkey-app-market/) · [Apple Developer — Türkiye fiyat değişimi](https://developer.apple.com/news/?id=4li349ao) · [Türk Telekom operatör faturasına yansıtma](https://bireysel.turktelekom.com.tr/dijital-servisler/dijital-odeme/app-storeda-mobil-odeme) · [Webtekno — otomatik yenileme kuralı](https://www.webtekno.com/apple-abonelik-fiyati-karari-otomatik-yenileme-h123830.html)

**Global rakipler**
[Muslim Pro](https://apps.apple.com/us/app/muslim-pro-quran-athan/id388389451) · [Trustpilot](https://www.trustpilot.com/review/www.muslimpro.com) · [Athan](https://apps.apple.com/us/app/athan-prayer-times-dua-azkar/id505858403) · [Pillars](https://apps.apple.com/us/app/pillars-prayer-times-qibla/id1559086853) · [Tarteel](https://apps.apple.com/us/app/tarteel-ai-quran-memorization/id1391009396) · [Quran.com](https://apps.apple.com/us/app/quran-by-quran-com-%D9%82%D8%B1%D8%A2%D9%86/id1118663303) · [quran-ios açık kaynak](https://github.com/quran/quran-ios) · [Ayah](https://apps.apple.com/us/app/ayah-quran-app/id706037876) · [Salam App](https://apps.apple.com/us/app/salam-app-muslim-companion/id1629159763) · [Just Pray](https://justprayapp.co/) · [Sajda](https://sajda.com/en) · [Bağımsız karşılaştırma](https://www.fiveprayer.app/blog/best-muslim-apps-2026)
Veri skandalları: [Al Jazeera — Muslim Pro](https://www.aljazeera.com/news/2020/11/17/report-us-military-buying-location-data-on-popular-muslim-apps) · [Vice — Salaat First](https://www.vice.com/en/article/muslim-app-location-data-salaat-first/) · [Comparitech — 175 uygulama taraması](https://www.comparitech.com/blog/vpn-privacy/muslim-prayer-app-study/)

**Teknik**
[adhan-swift](https://github.com/batoulapps/adhan-swift) · [yüksek enlem hatası #102](https://github.com/batoulapps/adhan-swift/issues/102) · [hesaplama yöntemleri](https://github.com/batoulapps/adhan-js/blob/master/METHODS.md) · [Aladhan yöntem listesi](https://api.aladhan.com/v1/methods) · [PrayTimes hesaplama dokümanı](http://praytimes.org/docs/calculation) · [Moonsighting yöntemi](https://www.moonsighting.com/how-we.html)
[iOS 26 AlarmKit — MacRumors](https://www.macrumors.com/2025/06/11/ios-26-third-party-alarm-apps/) · [30 sn ezan sınırı — Muslim Pro destek](https://support.muslimpro.com/hc/en-us/articles/200588785) · [WWDC26 App Intents](https://developer.apple.com/videos/play/wwdc2026/345/) · [WWDC26 Live Activities](https://developer.apple.com/videos/play/wwdc2026/223/)
[Kıble — Abdali, büyük daire tartışması (PDF)](https://geomete.com/abdali/papers/qibla.pdf) · [Gölge ile kıble tespiti](https://en.wikipedia.org/wiki/Qibla_observation_by_shadows) · [Quran Foundation font dokümanı](https://api-docs.quran.foundation/docs/tutorials/fonts/font-rendering/)

**Pazar, ASO, para kazanma**
[Apple Developer — mağaza güncellemeleri (Eki 2025)](https://developer.apple.com/news/?id=gf6mgrs6) · [Featuring adaylığı](https://developer.apple.com/help/app-store-connect/manage-featuring-nominations/nominate-your-app-for-featuring/) · [Apple "The gift of Ramadan"](https://apps.apple.com/us/story/id1849327066)
[AppTweak — Apple Ads benchmark](https://www.apptweak.com/en/aso-blog/apple-ads-benchmarks) · [AppTweak — featuring rehberi](https://www.apptweak.com/en/aso-blog/how-to-get-your-app-featured-on-the-app-store) · [MobileAction — In-App Events](https://www.mobileaction.co/guide/in-app-events-promotional-content-guide/) · [MobileAction — çapraz yerelleştirme](https://www.mobileaction.co/blog/app-store-cross-localization/) · [AppLaunchFlow — anahtar kelime alanı](https://www.applaunchflow.com/blog/app-store-keyword-field-guide-2026)
[Adjust — Ramazan uygulama trendleri 2026 (PDF)](https://investgame.net/wp-content/uploads/2026/01/2026-01-27-ramadan-app-trends-report.pdf) · [AppsFlyer — Ramazan geliri](https://www.appsflyer.com/company/newsroom/pr/ramadan-app-revenue/) · [Data Darbar — İslami uygulama pazarı](https://insights.datadarbar.io/decoding-the-massive-market-for-islamic-apps/) · [Data Darbar — Ramazan sıçraması](https://insights.datadarbar.io/ramzan-rush-how-religious-apps-get-more-popular-during-ramzan/)
[RevenueCat — State of Subscription Apps 2026](https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026) · [Sensor Tower — İslami uygulama ASO](https://sensortower.com/blog/decoding-islamic-app-in-performance-aso-creative)
