# Mihrab — UI/UX Araştırma Raporu

**Tarih:** 23 Ağustos 2026
**Kaynak:** Mobbin (iOS ekran/akış arşivi) + Mihrab mevcut kod tabanı okuması
**Kapsam:** Ana ekran, onboarding, paywall, liste/sözlük, sayaç, pusula, istatistik, ayarlar, boş/yükleniyor/hata durumları, sezonluk tema

> Tüm bağlantılar Mobbin'in kanonik ekran sayfalarına gider; tıklayıp orijinal ekran görüntüsünü ve uygulamanın diğer ekranlarını görebilirsin.

---

## 0. Mihrab'ın mevcut durumu (kod okumasından çıkan not)

Öneriler somut olsun diye önce nerede olduğumuzu sabitleyelim:

| Ekran | Dosya | Mevcut yapı |
|---|---|---|
| Bugün | `Mihrab/Features/Today/TodayView.swift` (983 satır) | Selamlama + konum çipi → `HeroCountdownCard` (216pt `BreathingRing` + saat:dakika) → `DaySummaryRow` (2 kutucuk) → `PrayerStrip` (yatay 6 hap) → `PrayerLogCard` (5 daire + streak) → `quickActions` (2×2 ızgara) → `SunArcView` → `DailyHadithCard` → Ramazan/dini gün/zikir kartları. **11 kart alt alta.** |
| Vakitler | `Times/TimesView.swift` | Gün/Ay mod seçici, gün pager, `MihrabEmptyState` ile 3 farklı boş/hata durumu |
| Kıble | `Qibla/QiblaCompassView.swift` | 300pt kadran + `readout` + kalibrasyon banner'ı + alt safe-area'da AR capsule |
| Esmaül Hüsna | `Deen/EsmaHomeView.swift`, `EsmaGridView.swift` | Hero (rosette + 70pt hat) → dhikr kartı → journey strip → koleksiyon strip; browser'da arama + tema çipleri + favori filtresi + liste/ızgara `matchedGeometryEffect` |
| Zikirmatik | `Dhikr/DhikrView.swift` (871 satır) | `DhikrGoalBar` + rutin banner + 300pt sayaç yüzeyi + hint + footer, Metal shader arka plan |
| Onboarding | `Onboarding/OnboardingView.swift` (688 satır) | 7 adım: welcome → name → location → method → notifications → tour → plus |
| Paywall | `Paywall/PaywallView.swift` (599 satır) | Hero halo → 5 fayda satırı → 3 plan kartı → CTA → footer. Kapatma butonu ilk kareden görünür (dürüst paywall) |
| Ayarlar | `Settings/SettingsView.swift` | Aranabilir `Form`, 9+ bölüm, en üstte abonelik + görünüm |

**Zaten iyi olanlar:** dürüst paywall, `MihrabEmptyState` ortak bileşeni, Reduce Motion her yerde dallanıyor, `TodaySkeleton` gerçek kart yüksekliklerini taklit ediyor, `SafeCountdown` ile geri sayım güvenliği, kalibrasyon uyarısı ("emin değilsek iğneyi göstermiyoruz").

---

## 1. Ana ekran / Bugün ekranı

### Referanslar

**1. [Calm — Home](https://mobbin.com/screens/5236d3fc-154c-4a08-8eb1-8da87069582b)**
Tam ekran manzara fotoğrafı üzerinde tek bir "4 Days" halkası, altında 7 günlük M-T-W-T-F-S-S check dizisi, sonra tek satır cümle ("You're making mindful moves with 4 days of Calm this week"). Kart yığını yok; **bir ölçü, bir hafta şeridi, bir cümle.**
→ *Mihrab'a öğrettiği:* Mihrab'da streak `PrayerLogCard` içine gömülü küçük bir alev ikonu. Calm streak'i **hero'nun altına, ekranın ikinci öğesi** yapmış ve 7 günlük noktalarla görselleştirmiş. Mihrab'ın `PrayerLogCard` streak satırı hero'nun hemen altına 7 günlük mini şerit olarak taşınabilir.

**2. [Ten Percent Happier — Home](https://mobbin.com/screens/383427ac-4b58-4d44-af80-82d2e9dcef66)**
"Good Afternoon" + tek dev renkli kart: süre rozeti (7 MIN) sol üstte, "Today's Session" etiketi, başlık, altında tam genişlik beyaz **Play** kapsülü. Kartın kendisi eylem.
→ *Öğrettiği:* Mihrab'ın hero countdown kartı şu an **sadece bilgi** (tap → Vakitler sekmesi). Kartın içine tam genişlikte tek bir birincil eylem ("Namazı işaretle" / "Bildirimi kur" / "Kıbleyi göster") koymak kartı bilgi levhasından eylem yüzeyine çevirir.

**3. [TIDE — Home](https://mobbin.com/screens/50a3b0f2-b2be-41d3-bf9e-cac733217b14)**
"Good day" + hemen altında S M T W T F S hafta şeridi, sonra **yatay kaydırmalı 3 hızlı eylem çipi** (Focus Timer / Quick Nap / Breathwork), sonra günün alıntısı, sonra kategori çipleri.
→ *Öğrettiği:* Mihrab'ın `quickActions` 2×2 dikey ızgara — 4 satır dikey yer yiyor ve 6. kart sırasında geliyor. TIDE bunları **tek satır yatay çip şeridi** yapıp hero'nun hemen altına almış. Mihrab'ın 2×2 ızgarası tek satır yatay şeride dönüşürse ~60pt kazanılır ve hızlı eylemler scroll gerektirmeden görünür olur.

**4. [Waking Up — Home](https://mobbin.com/screens/e1a8a9dd-ca53-4276-8909-bf56da5e8331)**
"Day 4 of 28" mikro-etiketi kartın üstünde; kart içinde 2 satır (Meditation 4 · 10m 26s ▶ / Begin Again · 3m 32s ▶). Sonra "Up Next" bölümü ilerleme çubuklu.
→ *Öğrettiği:* İçerik kartlarında **"kaldığın yer"** metaforu. Mihrab'ın Esmaül Hüsna kartı "99'un 12'si" gibi bir devam noktası taşıyabilir.

**5. [timespent — Arcs](https://mobbin.com/screens/c49184d7-4dc7-4f49-b7df-cce7563bc829)**
Koyu tema, her "Arc" kartı: başlık + sağda büyük metrik (3 days / 10h 45m) + altında **kart dışına taşan 7 günlük S M T W T F S nokta şeridi tarihlerle**. Aktif olanlar dolu altıgen, olmayanlar boş.
→ *Öğrettiği:* Mihrab'ın `PrayerLogCard`'ındaki 5 daire sadece **bugünü** gösteriyor. timespent gibi altına 7 günlük geçmiş şeridi eklenirse streak "sayı" olmaktan çıkıp **görülebilir bir desen** olur — ve boş günler suçlayıcı değil, sadece boş.

**6. [Life Reset — Home](https://mobbin.com/screens/bb668112-fb6b-45f4-887a-6020a472836e)**
Üstte sabit "Level progress / Lvl 2 / 414 XP" ilerleme bandı, altında **To-dos 3 · Done 1 · Skipped 1** segment filtreleri.
→ *Öğrettiği:* Mihrab'ın günlük özeti ("3 vakit kaldı") pasif bir kutucuk. Segment filtresi haline gelirse (Kalan / Kılınan / Kaza) `PrayerLogCard` ile birleşip iki kart yerine bir kart olur.

### Bu kategorinin özeti
Referansların hiçbirinde **11 kart yok**. Ortalama 4–6 blok var ve bunlardan biri her zaman "bugünün tek eylemi". Mihrab'ın Bugün ekranı bilgi açısından zengin ama **hiyerarşi açısından düz** — her kart aynı `mihrabCard` ağırlığında.

---

## 2. Onboarding

### Referanslar

**1. [Strava — "Don't miss a thing"](https://mobbin.com/screens/c43f3937-d7e3-4af8-9a56-1bb85e63a06d)**
Sistem izin diyaloğundan önce, ekranın ortasında **gerçek bir bildirim kartının önizlemesi** (STRAVA · 10 min ago · "Way to go 👏 Kudos for another activity..."). Altta küçük gri metin: "Make sure you select 'Allow' on the next step". CTA: "Choose permissions".
→ *Öğrettiği:* Mihrab'ın `notificationsPage`'i madde madde anlatıyor. **Gerçek bir ezan bildiriminin sahte önizlemesi** ("Mihrab · şimdi — İkindi vakti girdi · Ankara") madde listesinden çok daha ikna edici. Efor: S.

**2. [Affirm — "Stay in the know"](https://mobbin.com/screens/c797ee4d-1c25-4e77-b592-9f6732e5725a)**
Küçük ikon + başlık + "Choose to allow notifications **on the next screen** to receive:" + 3 chevron'lu madde + "Update your notification preferences any time in **Settings**." İki buton: Continue / Not right now.
→ *Öğrettiği:* "Sonraki ekranda" ifadesi kullanıcıyı sistem diyaloğuna hazırlıyor — reddetme oranını düşüren klasik priming. Mihrab'ın `L10n.enableNotifications` butonu doğrudan sistem prompt'unu açıyor; araya bu cümle girmeli.

**3. [Zocdoc — bildirim izni](https://mobbin.com/screens/624436bd-5176-4fb7-99af-161f59d3ac99)**
Sarı eşkenar dörtgen üzerinde telefon mockup'ı, üstünde gerçek bildirim baloncuğu. Başlık iki satır, gövde tek satır, sonra dev sarı CTA + "Not now".
→ *Öğrettiği:* Görsel bir "kanıt" objesi (telefon + bildirim) marka rengiyle çerçevelenmiş. Mihrab'ın `MihrabArchMark()` sadece welcome sayfasında; her izin sayfasının kendi görsel motifi olabilir (konum → pusula gülü, bildirim → minare/ezan dalgası).

**4. [Tiimo — kişiselleştirme sorusu](https://mobbin.com/screens/e2345aec-25d2-4584-9bcc-266601eaf9de)**
Üstte ince mor ilerleme çubuğu (dolu kısım ~%25), serif başlık "Are you neurodivergent?", açıklama, 3 kapsül seçenek + altında düz metin "I don't know" (baskısız kaçış), en altta sabit siyah Continue.
→ *Öğrettiği:* Mihrab'ın `methodPage`'i `CalculationMethod.allCases` üzerinde ham liste + segmented madhab picker gösteriyor — **teknik bir tercih ekranı**. Tiimo formatına çevrilirse: "Hangi kuruma göre vakit istersin?" + 3-4 kapsül + "Emin değilim → senin için Diyanet'i seçtik" kaçışı. Efor: M.

**5. [Hers — Consultation](https://mobbin.com/screens/c5d35999-99dd-4583-be65-93db284351a7)**
Üstte **segmentli** ilerleme çubuğu (mevcut bölümün içindeki adımlar dolu, sonraki bölümler ayrı küçük segmentler). Kullanıcı "bu bölüm bitiyor, 2 bölüm daha var" diye okuyabiliyor.
→ *Öğrettiği:* Mihrab 7 eşit capsule gösteriyor. Adımları **gruplayıp** (Tanışma · Ayarlar · Bonus) segmentlemek 7 adımı psikolojik olarak 3 adım gibi hissettirir.

**6. [Me+ — kişiselleştirme](https://mobbin.com/screens/21f7cee4-6352-4354-8b70-dd605fb3ee2b)**
Seçilen seçenek mor dolgu + sağda mor onay rozeti; seçilmeyenler açık gri. Her seçeneğin solunda emoji/ikon.
→ *Öğrettiği:* Seçim geri bildirimi **renk + ikon + konum** olarak üç kanaldan geliyor. Mihrab'ın method satırları sadece checkmark ile ayrılıyor.

**7. [Beli — "Stay connected"](https://mobbin.com/screens/441290e3-2ea8-4b7a-8017-40aefe806713)** ve **[Granola](https://mobbin.com/screens/796e5918-9efd-42e4-855c-3cb7b3593ad0)**
İkisi de aynı kalıp: tek ikon/illüstrasyon, serif başlık, 2 satır gövde, koyu dolu CTA, altında **soluk** "Not now". Granola'nınki neredeyse boş — bol beyaz alan, sakin.
→ *Öğrettiği:* Granola'nın sakinliği Mihrab'ın "Emerald Glass / sakin lüks" diline en yakın örnek. Mihrab'ın izin sayfalarındaki 3 madde kartı (`OnboardingBullet` × 3 + `mihrabSolidCard`) kaldırılıp tek cümleye indirilebilir.

---

## 3. Paywall / Abonelik

### Referanslar

**1. [Bloom — plan seçimi](https://mobbin.com/screens/71492042-1dac-41c0-a148-0150c6325c9d)** ⭐ en yakın referans
Yukarıda deneme zaman çizelgesi (Day 7 · "Your free trial ends and you will be charged. Cancel anytime before." + "Forget to cancel? No problem. Get a full refund"), altında **sosyal kanıt yığını** (Loved by 2 million users / App of the Day / 4.8★ 21,000+ reviews / #1 App for...), en altta **sabitlenmiş (sticky) 3 sütunlu plan seçici**: MONTHLY $9.99 · YEARLY $59.99 (Most Popular rozeti, teal dolgu) · LIFETIME $99.99. Her sütunda ikinci satır olarak **haftalık birim fiyat** ($2.49/week · $1.15/week · Billed once).
→ *Öğrettiği:* Üç şey Mihrab'da yok: (a) planlar **yan yana 3 sütun** — dikey 3 kart yerine tek bakışta karşılaştırma; (b) **haftalık birim fiyat** — yıllık planın ucuzluğunu "%X tasarruf"tan daha somut anlatır; (c) plan seçici **sticky footer** — kullanıcı faydaları okurken fiyat hep görünür.

**2. [Hevy — PRO](https://mobbin.com/screens/19fce77b-a3e7-428c-857c-79aa00fbe716)**
Üstte 6 fayda ✓ listesi (tek satır, ikonsuz), altında 3 sütun MONTHLY/YEARLY/LIFETIME, YEARLY üzerinde mavi "SAVE 33%" **kartın üstüne oturan** rozet, tam genişlik CTA "**Subscribe to Yearly plan**" (seçili planın adı butonda), altında "Not now" + "Cancel your subscription at any time." + ★★★★★ + "What our users are saying".
→ *Öğrettiği:* CTA metninde plan adının geçmesi ("Yıllık plana geç") belirsizliği sıfırlıyor. Mihrab'ın `ctaTitle`'ı jenerik ("Denemeyi başlat"). Efor: S.

**3. [Babbel](https://mobbin.com/screens/be51c800-b274-43d6-afd5-28e434cda0cf)**
Her plan kartında **üstü çizili eski fiyat** turuncu ile ($239.92 → $115.98) ve "SAVE 52%" siyah rozet. CTA'nın hemen üstünde tek satır: "Free for 7 days, then $59.98 every 3 months".
→ *Öğrettiği:* Üstü çizili fiyat = tasarruf rozetinin görsel karşılığı. Mihrab yıllık planda sadece `paywallSaveBadge(percent)` gösteriyor; "12 × aylık fiyat" üstü çizili yazılırsa rozet kanıtlanmış olur.

**4. [Mimo — deneme zaman çizelgesi](https://mobbin.com/screens/e257555e-bd98-4163-b095-198a8c58473b)**
Dikey mor gradient çizgi üzerinde 3 nokta: **Today** (kilit açık ikonu) → **In 12 days** (zil) → **In 14 days** (yıldız). Altında tek satır fiyat ve CTA "Start my 14-day free trial" + "No charges yet. Cancel anytime on the App Store."
→ *Öğrettiği:* Mihrab'ın `paywallReminderNote` bir `Label(systemImage:"bell.badge")` — tek satır. **3 noktalı dikey zaman çizelgesi** aynı bilgiyi anlatır ama endişeyi ölçülebilir şekilde düşürür. Emerald Glass'ta pirinç (brass) çizgi + zümrüt noktalar olarak çizilebilir. Efor: M.

**5. [Vocabulary](https://mobbin.com/screens/32238af5-552f-4ac3-bede-16981f4c23d3)**
Zaman çizelgesinin ilk maddesi **üstü çizili** ("~~Install the app~~ — Set it up to match your goals") — kullanıcı zaten bir adım ilerlemiş hissediyor. Ayrıca CTA'nın üstünde **"Reminder before trial ends" toggle'ı** — deneme bitmeden hatırlatma kullanıcının kendi kontrolünde.
→ *Öğrettiği:* Bu toggle Mihrab'ın "dürüst paywall" duruşuyla mükemmel örtüşüyor ve zaten `NotificationEngine` var. Efor: S.

**6. [Peanut](https://mobbin.com/screens/fea3b0ed-9377-41d6-8282-8146146daefc)** — *karşı örnek*
Geri sayımlı "39% off ends in 47:27:13" + üstü çizili $132→$80. Baskı yaratıyor.
→ *Öğrettiği:* Mihrab'ın kod yorumunda açıkça "nothing counts down" yazıyor. Bu duruş **korunmalı**; Bloom/Mimo'nun sosyal kanıt + zaman çizelgesi yaklaşımı baskı yaratmadan aynı dönüşümü sağlıyor.

**7. [timespent — Boundless](https://mobbin.com/screens/c9098dc0-df20-49c8-9ff0-3720857cee3a)**
Geliştiricinin kendi avatarı + el yazısı tonunda birinci tekil mektup ("hi, me again. 👋 as i start my solo dev journey full-time..."). Planlar sade satırlar halinde, ücretsiz katman açıkça korunuyor ("everyone gets 5 of each for free").
→ *Öğrettiği:* Mihrab'ın `paywallFreeForeverNote`'u caption2 boyutunda dipnot. Bir **"Mihrab'ın kalbi hep ücretsiz kalacak"** bloğu — vakitler, kıble, zikirmatik asla kilitlenmez — paywall'ın ortasına konursa markanın güveni artar.

---

## 4. Liste / sözlük ekranları (99 İsim)

### Referanslar

**1. [DailyArt — Masterpieces](https://mobbin.com/screens/e32a1a29-45de-46d6-96bb-4b79f663ca4f)** ⭐
Serif başlık, sağ üstte **iki durumlu ızgara/liste toggle'ı** (aktif olan kırmızı dolu). Liste satırları: solda küçük kare görsel, sağda serif eser adı + sanatçı + yıl. Alt tab bar'da ayrı "Favourites" sekmesi.
→ *Öğrettiği:* Mihrab'ın liste/ızgara geçişi zaten `matchedGeometryEffect` ile var (güzel), ama **favoriler bir filtre toggle'ı** olarak gizli. DailyArt favorileri **kalıcı bir yer** yapmış. 99 İsim'de favoriler `Deen` sekmesinde ayrı bir giriş olabilir.

**2. [Apple Books — Library](https://mobbin.com/screens/fb8d6cde-a349-4b0b-a1d5-4fbbc3fce77f)**
Sağ üstte sadece iki ikon (sıralama + "..."), altında büyük kapaklar ızgarası. Kapağın altında durum rozeti (GET / SAMPLE). En altta ince gri "2 books, 1 series" **sayaç satırı**.
→ *Öğrettiği:* Filtre uygulandığında sonuç sayısını göstermek ("99 isimden 12'si · Rahmet"). Mihrab'ın `entries` filtresi sessizce daralıyor; sayı satırı kullanıcıya nerede olduğunu söyler. Efor: S.

**3. [MD Vinyl — Albums](https://mobbin.com/screens/0f221ca7-9ced-464e-995e-614354da812c)**
Üstte 3'lü kontrol: sıralama ikonu (sol) — Albums/Playlists segment (orta) — ızgara ikonu (sağ). Altında arama alanı. Kapaklar **alfabetik harf başlıkları** (A, S) altında gruplanmış.
→ *Öğrettiği:* 99 uzun bir liste. Mihrab şu an düz akıyor. **Bölüm başlıkları** (1–33 / 34–66 / 67–99 ya da tema adları) + sağ kenarda hızlı atlama indeksi uzun listeyi gezilebilir yapar.

**4. [Instagram — Saved](https://mobbin.com/screens/7edc7b2f-e493-43ad-9c54-62b8bb0d3599)** ve **[Shop — Saved](https://mobbin.com/screens/e94fcbe5-b51e-4652-be3f-67cdecb1204a)**
Koleksiyon kapakları 2×2 mozaik olarak koleksiyonun içindeki ilk 4 öğeden **otomatik üretiliyor**. Shop ayrıca en üste "+ Create collection" boş kartını koymuş.
→ *Öğrettiği:* Mihrab'ın `EsmaCollections` sabit kürate koleksiyonlar. Kullanıcının kendi koleksiyonunu yapabilmesi (favoriler zaten var) ve kapağın 4 hattan mozaik üretmesi — Emerald Glass'ta 2×2 kaligrafi mozaiği çok güçlü görünür.

**5. [Letterboxd — Films](https://mobbin.com/screens/6ff987e9-4cea-48b4-b87e-2481883e5b03)**
Yoğun 4 sütunlu poster ızgarası; her posterin altında **mikro-durum satırı** (★★★★½ ♥ ≡). Bilgi yoğun ama okunabilir.
→ *Öğrettiği:* Mihrab'ın ızgara modu 2 sütun. 3 sütuna çıkıp her karonun altına küçük "okundu/favori" işareti konursa 99 isim **iki ekranda** görülebilir hale gelir — "koleksiyonu görmek" duygusu.

---

## 5. Sayaç / tekrar eden eylem (Zikirmatik)

### Referanslar

**1. [pushr — sayaç](https://mobbin.com/screens/15b9ef05-dfc8-49aa-9736-ea0093e1ab3c)** ⭐
Neredeyse boş bir ekran. Ortada **dev "3"**, üstünde küçük cam kapsül "SET 1 · TOTAL", altta cam kontrol satırı: süre (00:41.28) · duraklat · kırmızı kapat. Tüm ekran tap alanı.
→ *Öğrettiği:* Mihrab'ın Dhikr ekranında header (`DhikrGoalBar` + rutin banner) + counter + hint + footer var — **4 katman**. pushr sayıyı bırakıp geri kalan her şeyi cam kapsüllere sıkıştırmış. Mihrab'a bir **"Odak modu"** (tek tap ile chrome'un silinip sadece sayı + nefes alan shader'ın kalması) çok yakışır. Efor: M.

**2. [Apple Fitness — sayım](https://mobbin.com/screens/620e1c4b-46e7-4ba7-936d-a2bded2de22e)**
Siyah ekran, yeşil gradient halka, ortada tek rakam. Başka hiçbir şey yok.
→ *Öğrettiği:* Mihrab'ın hedef halkası zaten var. Apple'ın yaptığı: **hedefe yaklaşınca halkanın rengi ısınıyor**. 33'e giderken zümrüt → pirinç geçişi tamamlanma hissini artırır.

**3. [Forest — Breathe in](https://mobbin.com/screens/98e03470-479d-46ef-b679-21a83c0fb7bf)**
Koyu yeşil→turkuaz gradient, ortada parlayan nesne, üstte "Breathe in" + altında ince ilerleme çizgisi, altta "Keep holding to leave" — **çıkış bile basılı tutma gerektiriyor** ki yanlışlıkla seans bozulmasın.
→ *Öğrettiği:* Zikirmatikte 500'lük bir sette yanlışlıkla sıfırlama felakettir. Mihrab'ın sıfırlama butonu **basılı tutma** (long-press) olmalı, halka dolarak onay versin. Efor: S.

**4. [Calm Sleep — Breathe In](https://mobbin.com/screens/54e3f825-c301-4fc9-a3d1-3b72bc658591)**
Nefes halkası **çevresinde 4 küçük nokta** — döngünün fazlarını (in/hold/out/hold) işaretliyor. Kontroller altta 3 dairesel cam buton.
→ *Öğrettiği:* Mihrab'ın 33'lük setlerinde halkanın çevresine **her 11'de bir tik** konursa kullanıcı sayıya bakmadan nerede olduğunu bilir (tesbih taneleri metaforu). Efor: S.

**5. [Opal — Breathe In](https://mobbin.com/screens/b7a85dff-8e86-4211-9dec-73f5bf2ac492)**
Gerçek doğa videosu üzerine tek beyaz halka; alttaki CTA "Wait for 3s" olarak **devre dışı** — acele etmeye izin vermiyor.
→ *Öğrettiği:* Bir sonraki zikre geçiş butonunun set bitene kadar pasif kalması, rutin (tesbihat) akışında yanlış atlamayı engeller.

**6. [WHOOP — Increase Relaxation](https://mobbin.com/screens/35fce318-4db6-40d2-bdab-342d4ec900ca)**
Kesikli dış halka (hedef) + dolu iç halka (mevcut) + altında **talimat metni** ("One more sharp inhale through the nose"). Üstte seans süresi geri sayımı.
→ *Öğrettiği:* Mihrab'ın `hintLine`'ı bir kez görünüp kayboluyor. Rutin modunda "Sıradaki: Elhamdülillah · 33" gibi **kalıcı ama sessiz** bir alt satır, kullanıcıyı akıştan çıkarmadan yönlendirir.

**7. [stoic. — sayaç](https://mobbin.com/screens/398c589e-c4e1-409d-ada9-13c254b5e3c7)**
Tamamen boş beyaz ekran, ortada ince siyah çember, altta "Finish" + "Log +00:02". Ekstrem minimalizm.
→ *Öğrettiği:* Bitirme eylemi ("Finish") ile kaydedilen değer ("Log +00:02") aynı yerde. Mihrab'ta set bitince "+33 kaydedildi" mikro-toast'u aynı işi yapar.

---

## 6. Pusula / yön bulma

### Referanslar

**1. [Lumy — Sun position](https://mobbin.com/screens/6c285ffd-a76e-4528-a227-7ca21df20cd8)** ⭐
Koyu lacivert; kadranın çevresinde **ince derece tikleri**, içinde renk bantlarıyla gün/gece dilimleri, merkezde siyah daire içinde **"-42°↑"** — tek okunabilir rakam. Kadranın altında düz metin özeti ("Night ends in 2 hr, 42 min") ve altında **etiket/değer tablosu** (Daylight 12h 22m 29s · Altitude -42° · Azimuth 32.33° NE ↗).
→ *Öğrettiği:* Mihrab'ın `readout`'u kadranın altında. Lumy **kritik değeri kadranın merkezine** koymuş, detayları tabloya itmiş. Mihrab'da merkeze "12° sağa dön" gibi **eylem talimatı** gelmeli; mesafe/derece/açı alttaki tabloda kalsın.

**2. [Sunlitt — Monolitt](https://mobbin.com/screens/9b61f472-b3d8-47c6-abc9-9a9152b373bf)**
Ekranın ortasında yüzen küçük "Inaccurate Compass" **kapsül uyarısı** — kırmızı ikon + metin, kadranın hemen altında, sayfayı bozmadan.
→ *Öğrettiği:* Mihrab'ın `calibrationBanner`'ı kartın altında tam genişlik. Sunlitt'inki **yüzen kompakt kapsül** — daha az alarm, aynı bilgi. Ayrıca Sunlitt kadranı 3B bir objeyle göstermiş: Mihrab'ın Kâbe motifi kadranın merkezinde 3B/paralaks bir öğe olabilir.

**3. [Polestar — Schedule dial](https://mobbin.com/screens/13a0c3e2-30bf-4154-9a65-558909d65173)**
Koyu kadran; kalın turuncu yay + iki uçta beyaz dairesel tutamaç (ikonlu), merkezde büyük "17h 0m". Saat etiketleri (12am, 03, 06am...) kadranın **içinde**, tiklerin arasında.
→ *Öğrettiği:* Kadran içi tipografi hiyerarşisi: kalın yay (durum) > merkez değer > ince tikler > etiketler. Mihrab'ın kadranında N/E/S/W etiketleri ve kıble işareti aynı ağırlıkta yarışıyor olabilir — kıble işareti pirinç + ışıklı, yön harfleri soluk olmalı.

**4. [Starlink — "Point your camera up"](https://mobbin.com/screens/b845d028-60c3-41b4-9033-3ed9737d73aa)** ⭐ AR için
Siyah ekran, ortada **çember içinde tek büyük ok**, altında tek cümle talimat, **sağ altta küçük mini pusula** (E harfi görünür durumda). Başka hiçbir chrome yok.
→ *Öğrettiği:* Mihrab'ın `QiblaARView`'ı için altın standart: kameranın üstünde tek ok + tek cümle + köşede mini kadran (kullanıcı AR'dan çıkmadan yönünü doğrulayabiliyor).

**5. [Best Buy — AR onboarding](https://mobbin.com/screens/7239d336-049e-492e-aa8c-e07a998d24fb)**
AR başlamadan önce koyu kart içinde çizgi ikon + "Scan your room" + "Take a few steps in any direction to help the camera learn your space." Üstte 3D/AR segment toggle'ı.
→ *Öğrettiği:* AR'a geçişte **"telefonu 8 çizerek salla"** kalibrasyon talimatı Mihrab'da da bir kart olarak gösterilmeli — magnetometre kalibrasyonu kullanıcıya öğretilmezse AR yanlış yönü gösterir ve app suçlanır.

**6. [Placify — harita kontrolleri](https://mobbin.com/screens/ce65d2b9-fd40-45da-b807-853b98628ab5)**
Pusula/3D/Trafik seçenekleri **görsel önizlemeli kartlar** olarak, her birinde küçük harita thumbnail + toggle.
→ *Öğrettiği:* Mihrab'ın Ayarlar'ındaki görsel tercihler (aksan rengi, shader motifi) metin satırı yerine **önizlemeli kart** olarak sunulabilir.

---

## 7. İstatistik & seri (streak)

### Referanslar

**1. [Duolingo — Streak](https://mobbin.com/screens/736a41b0-0984-4010-b7da-33a2c922d0b9)** ⭐
PERSONAL/FRIENDS sekmeleri; "December 2025" + **PERFECT rozeti**; iki metrik kutucuğu (🔥10 Days practiced · ❄️0 Freezes used); altında **takvim ızgarası** — ardışık günler **turuncu kesintisiz kapsül** olarak birleştirilmiş (1-6 bir kapsül, 7-10 bir kapsül). Sonra "Streak Goal" ilerleme çubuğu ve "Streak Protection".
→ *Öğrettiği:* Mihrab'ın streak'i tek sayı. Duolingo'nun **ardışık günleri birleşik kapsül olarak çizmesi** seriyi tek bakışta okunur yapar ve kopuşları görünür kılar. Ayrıca "Streak Protection" kavramı — Mihrab'da **seyahat/hastalık günü** için affedici bir mekanizma (dini olarak da doğru bir mesaj) çok yerinde olur.

**2. [MacroFactor — Insights & Data](https://mobbin.com/screens/d7659072-cae4-4d38-8a5e-c8ebdb64c1a1)**
Üstte tek büyük halka "100% August Tracked Rate", altında "Nutrition Streaks · Longest & Current · 🎖️ 29 days · 28 Jul 2024 – Today", en altta **yıllık GitHub tarzı nokta ızgarası** (Jan–Dec, her gün bir kare).
→ *Öğrettiği:* Mihrab'ın `DhikrStatsView`'ı için: **yıllık ısı haritası** (365 kare, zümrüt yoğunluğu = o günkü zikir sayısı) Emerald Glass'ta muhteşem görünür ve "bir yıllık ibadet haritası" duygusal bir çıktı olur. Aynı zamanda paylaşılabilir bir görsel. Efor: M.

**3. [Google Fit — My activity](https://mobbin.com/screens/6f1f2225-c442-4de4-873d-8a5d47350fda)**
Day/Week/Month segmenti; hafta grafiğinde **hedefi aşan barların tepesinde küçük ✓ rozeti** ve grafiğin üzerinde kesikli hedef çizgisi. Altında günlük satır listesi, sağda yeşil daire içinde ✓.
→ *Öğrettiği:* Mihrab'ın günlük zikir hedefi (`dailyDhikrGoal`) var ama grafikte **hedef çizgisi** yok. Kesikli pirinç bir hedef çizgisi + hedefi geçen günlerde tepe rozeti, grafiği "veri"den "başarı"ya çevirir. Efor: S.

**4. [Withings Health Mate — Activity](https://mobbin.com/screens/bf36011d-000b-4212-9346-fa3b5c1fdc62)**
Grafiğin üstünde o haftanın **aktivite tipi ikonları** (koşu/basketbol/yoga); altında özet kartı: sol büyük metrik, sağda "0/5 ★" hedef halkası, altında satır satır ikincil metrikler.
→ *Öğrettiği:* Mihrab'ın istatistik ekranı hem namaz hem zikir verisi taşıyabilir — üstte hangi ibadetin işaretlendiğini gösteren ikon şeridi iki veri kümesini tek grafikte birleştirir.

**5. [Runna — Personal Records](https://mobbin.com/screens/1955e917-b83f-4dc4-a2a3-df744943d66d)**
Grafiğin altında **altıgen rozet ızgarası** (1K/1MI/2MI/5K...), her rozetin altında değer + tarih. Kazanılmamışlar soluk.
→ *Öğrettiği:* Mihrab'ın `DhikrAchievements`'ı zaten var. Runna gibi **istatistik ekranının altına** taşınırsa (ayrı sheet yerine) kullanıcı ilerlemeyle ödülü aynı ekranda görür.

**6. [Atoms — Habit progress](https://mobbin.com/screens/35c534be-70d1-4000-8ac6-65391a765881)**
Alışkanlığın adı + felsefi alt başlık ("A more fit and healthy individual") + dev sayı "2" + **3 aşamalı altıgen basamak** (3 Repetitions / 5 Repetitions / 7 Day Streak) — kazanılan altın, sonrakiler gri.
→ *Öğrettiği:* "Sıradaki kilometre taşı" görünürlüğü. Mihrab'ın başarım rozetleri sadece kazanılınca toast oluyor; **bir sonraki rozet her zaman görünür** olmalı ("7 gün daha → Sabır rozeti").

---

## 8. Ayarlar

### Referanslar

**1. [Cosmos — Settings](https://mobbin.com/screens/d40a9283-9bde-4f0b-93d0-2c01f818b914)** ⭐
Koyu tema. En üstte **yan yana iki kart**: profil (avatar + "Alex Smith / Edit profile") ve "All elements / 11 Saves". Altında gruplar: General / Permissions / Other. **Push notifications satırının sağında "Working" durum metni**; Appearance sağında "Dark"; Language sağında "English".
→ *Öğrettiği:* Mihrab'ın `notificationSection`'ı toggle taşıyor ama **sistem izni reddedilmişse** kullanıcı bunu ancak içeri girince anlıyor. Cosmos'un "Working" durum etiketi doğrudan satırda. Mihrab'da "Bildirimler · Kapalı (Ayarlar'dan aç)" satır sağında turuncu durum metni olarak görünmeli. Efor: S.

**2. [BeReal. — Settings](https://mobbin.com/screens/8468c58b-d7cb-48e2-aace-a69595ee584b)**
Koyu, gruplar FEATURES / SETTINGS / ABOUT büyük harf ince başlıklarla; her satırın solunda outline ikon. En altta kırmızı "Log Out".
→ *Öğrettiği:* Mihrab zaten `Form` kullanıyor ama `ornamentalCaps()` bölüm başlıkları BeReal'ın ritmine çok yakın — tutarlılık iyi.

**3. [Linktree — More](https://mobbin.com/screens/4725d253-1d23-4104-915c-7b55aa49b7c6)**
TOOLS bölümündeki satırlarda **ikon + başlık + açıklayıcı alt satır** ("Social planner / Schedule content and get inspired"). Alt bölümler (ACCOUNT) tek satır.
→ *Öğrettiği:* Mihrab'ın "Hesaplama yöntemi" gibi teknik satırları alt satırda mevcut değeri **ve neden önemli olduğunu** taşımalı ("Diyanet · Fecir 18°").

**4. [Phantom — Settings](https://mobbin.com/screens/08c93b02-3325-434c-85ed-2147f0b83e63)**
En üstte **arama alanı**, altında profil, sonra gruplar. Sağda sayaçlar ("Manage Accounts 2 >", "Active Networks All >").
→ *Öğrettiği:* Mihrab'ın arama filtresi zaten var ve iyi çalışıyor (`matches()`), ama arama **görsel bir alan değil** — `.searchable` yerine kod içi filtre. Phantom gibi görünür bir arama alanı keşfedilebilirliği artırır.

**5. [The Outsiders — Personal & Fitness Details](https://mobbin.com/screens/2c65b76b-441d-4734-ab27-e0436583ad0f)**
Gruplar PERSONAL / BODY / FITNESS; sağda değerler (190bpm, 55bpm). Değer okunabilir, satır tıklanabilir.
→ *Öğrettiği:* Salt okunur değer + chevron kalıbı; Mihrab'ın konum/yöntem satırları için doğru desen.

---

## 9. Boş durum, yükleniyor (skeleton), hata

### Boş durum

**1. [Coursera](https://mobbin.com/screens/7e5f69c8-bf8b-4a66-99dc-c811a1aeded7)** — çizgi ikon + soft renk lekesi arkada, "You haven't enrolled in any courses **(yet)**", 2 satır gövde, mavi CTA "Explore courses". "(yet)" kelimesi tonu yumuşatıyor.
**2. [Lex](https://mobbin.com/screens/15181740-6713-4946-b348-777d27483d2f)** — boş durum **çerçeveli bir kart içinde**, sayfaya yayılmıyor; küçük maskot + başlık + gövde + küçük yeşil buton.
**3. [Woolworths](https://mobbin.com/screens/b4f376ad-bc87-455e-9980-24586a3e2d71)** — marka renginde illüstrasyon, tam genişlik CTA "Start Shopping".
**4. [Postmates](https://mobbin.com/screens/2be73ba9-c3fa-4332-b1a5-cd2e1648d9ee)** — *arama sonucu boş*: "We didn't find a match / Try searching for something else" + "BACK TO STORE". Arama boşluğu ile veri boşluğu **ayrı ele alınmış**.

→ *Mihrab'a öğrettiği:* Mihrab'ın `MihrabEmptyState`'i SF Symbol + başlık + mesaj + retry — sağlam ama **jenerik**. İki iyileştirme: (a) Esma araması boş dönerse ayrı bir metin ("'X' için isim bulunamadı · Filtreleri temizle"), (b) sembol yerine **markanın kendi çizimleri** (mihrap kemeri, rub el hizb, hilal) — `MihrabArchMark` ve `EsmaRosette` zaten var, boş durumlarda kullanılmıyor.

### Yükleniyor / skeleton

**5. [AllTrails](https://mobbin.com/screens/a6a7bb97-d19a-410e-94cc-9473cbeeb39b)** ve **[Careem](https://mobbin.com/screens/9efed28e-6a50-40b8-a8a6-e504c351c151)** — iskelet blokları **gerçek layout'un birebir kopyası**: arama çubuğu, çip satırı, büyük kart, 2 satır metin, sonra 2 sütunlu ızgara. Careem'de bloklarda hafif diyagonal parlama (shimmer) var.
**6. [Lovi](https://mobbin.com/screens/278fa40d-ef7f-4935-b3a8-12e3ef1a4122)** — iskelet **ürünün siluetini** taklit ediyor (şişe formu), jenerik dikdörtgen değil.

→ *Mihrab'a öğrettiği:* `TodaySkeleton` şu an 4 blok (300 / 78+78 / 150). Gerçek ekran 11 kart. En az **hero + özet + vakit şeridi + log kartı** olarak 4 farklı şekilde genişletilmeli; ayrıca Lovi gibi hero bloğunun içine **halka silueti** konursa iskelet bile markalı olur. Ve Vakitler/Esma/Zikir ekranlarının hiç iskeleti yok — `MihrabEmptyState(symbol:"clock.arrow.2.circlepath")` spinner yerine iskelet gelmeli.

### Hata

**7. [Waymo — Offline](https://mobbin.com/screens/66ee96c8-a0e3-401b-a8d2-d7c80dbdaae7)** — bulut-slash ikonu, "Offline" başlığı, **iki satır tanı** ("Your network is unavailable. Check your data or WiFi connection."), mavi metin "Retry". Suçlayıcı değil, tanısal.
**8. [MyDyson](https://mobbin.com/screens/428368da-df49-4ae6-9f60-4244315ed039)** — hata mesajı ortada, **"Retry" ekranın en altında tam genişlik mor bant** olarak sabitlenmiş — parmağa en yakın yer.
**9. [Swiggy](https://mobbin.com/screens/25f4cc9d-9a98-4efb-87b3-58bd6fd98552)** — **ekranın üst kısmı (arama, kategoriler) çalışmaya devam ediyor**, sadece içerik alanı hata gösteriyor. Kısmi hata.

→ *Mihrab'a öğrettiği:* En kritik ders Swiggy'den: Mihrab vakitleri çekemediğinde **tüm Bugün ekranı** çöküyor (`isLoadingFirstTimes` / hero'da "timesUnavailableShort"). Oysa **kıble, zikirmatik, Esmaül Hüsna ve son bilinen vakitler tamamen offline çalışabilir**. Hata sadece etkilenen karta hapsedilmeli, geri kalan ekran ayakta kalmalı + "Son güncelleme: dün 21:40" gibi bayat-veri etiketi gösterilmeli.

---

## 10. Sezonluk / tematik mod (Ramazan)

### Referanslar

**1. [Duolingo — December Quest](https://mobbin.com/screens/9f9ad31c-ec4e-4a7c-98a0-764d40835315)** ⭐
Tüm üst bant sezon rengine (koyu magenta) boyanmış, "December Quest" + "⏱ 19 DAYS" kalan süre, altında beyaz kart içinde sezon hedefi + ilerleme çubuğu (11/30). Altında normal içerik gri zeminde devam ediyor — **sezon üstte, uygulama altta.**
→ *Öğrettiği:* Mihrab'ın Ramazan modu `theme.isRamadanMode` ile aksan rengini değiştiriyor ve `RamadanCard` listede 8. sırada. Duolingo modeli: Ramazan boyunca **Bugün ekranının üst bandı** (selamlama + hero) mor/altın Ramazan paletine geçsin, "Ramazan · 12. gün · 17 gün kaldı" bandı en üste otursun, geri kalan ekran normal kalsın.

**2. [Finch — September Season](https://mobbin.com/screens/8d96ed66-fee8-4c32-8266-fddd6d8291ab)**
Üstte sezon banner'ı (illüstrasyon + "SEPTEMBER SEASON / BEAKS AND BRUSHES"), yanında **"Ends in 29d 9h" sayacı** ve "Plus Active" rozeti; altında Free/Plus iki sütunlu ödül yolu, günlere göre kilitli/açık.
→ *Öğrettiği:* Ramazan'ın 30 günü doğal bir "yol" (path). Mihrab'ın `FastingLogStore` verisi 30 günlük bir **hilal dolum yolu** olarak çizilebilir — her gün bir hilal, oruç tutulan günler dolu altın. `CrescentFillMark` zaten var, tek güne uygulanıyor; 30'a çoğaltılmalı.

**3. [Apple TV — Holiday Spirit](https://mobbin.com/screens/e57ccf6f-771e-49a5-a6ec-9d37c36167fc)**
Sezonluk **tek büyük kart** (havai fişek illüstrasyonu + "Embrace the Holiday Spirit / Explore the festive collection"), uygulamanın geri kalanı hiç değişmemiş. En hafif dokunuş.
→ *Öğrettiği:* Kandil geceleri / üç aylar / Zilhicce için: tam tema değişimi gerekmez, **tek sezonluk kart** yeter. Mihrab'ın `ReligiousDayBanner`'ı zaten bu — ama sadece 7 gün kala ve çok ince bir satır. Kandil gününde tam kart olmalı.

**4. [Target — Halloween](https://mobbin.com/screens/c4c60075-c9ed-438f-8d87-527dc8828cea)**
Sezon rengi (turuncu) tüm sayfa zeminine yayılmış, üstte tema illüstrasyonu (kediler + tabela), altında koyu kartlar.
→ *Öğrettiği:* Agresif uçtaki örnek. Mihrab için **fazla** — ama Kadir Gecesi gibi tek gecelik bir olayda tüm arka planın gece-lacivert + yıldız shader'ına dönmesi hatırlanacak bir an yaratır.

**5. [BitePal — Halloween Today](https://mobbin.com/screens/52da1b20-f4f8-4289-82c1-7bf5fae0349d)** ve [gece hali](https://mobbin.com/screens/aa2a99a6-637c-4183-8321-f7d14ac93eca)
Aynı ekranın gündüz (mavi gökyüzü) ve gece (koyu, maskot uyuyor) varyantı — **saate göre değişen sahne**.
→ *Öğrettiği:* Mihrab'ın `MihrabBackdrop(surface:)` ve shader sistemi bunu yapabilir: sahne **bir sonraki vakte göre** kayabilir (fecir → soğuk mavi, öğle → açık zümrüt, akşam → pirinç/amber, yatsı → derin abis). Countdown zaten hangi vakitte olduğumuzu biliyor. Efor: M. **Bu tek başına Apple Design Award seviyesinde bir detay.**

---

# Mihrab için 18 somut UI/UX iyileştirme önerisi

Öncelik sırasına göre (etki × kolaylık).

| # | Ekran | Değişiklik | Neden daha iyi | Efor |
|---|---|---|---|---|
| **1** | Bugün (`TodayView.swift`) | **Kart sayısını 11'den ~6'ya indir.** Hero + (özet & log birleşik kart) + vakit şeridi + hızlı eylem şeridi + hadis + sezonluk. `SunArcView`, aylık takvim, zikir özeti ve dini gün → Vakitler sekmesine veya "Daha fazla" bölümüne. | Referansların hiçbirinde 11 kart yok (Calm 3, TIDE 5, Waking Up 4). Şu an her kart aynı `mihrabCard` ağırlığında olduğu için hiyerarşi yok; kullanıcı ne yapacağını değil ne okuyacağını görüyor. | **L** |
| **2** | Bugün — Hero | **Hero kartına tek birincil eylem şeridi ekle.** Halkanın altına tam genişlik kapsül: aktif vakit varsa "Namazı işaretle", vakit yaklaşıyorsa "Kıbleyi göster", Ramazan'da "İftara …". [Ten Percent Happier](https://mobbin.com/screens/383427ac-4b58-4d44-af80-82d2e9dcef66) deseni. | Hero şu an ekranın %35'ini kaplayıp sadece bilgi veriyor; tap → başka sekme. En değerli piksel eylem taşımalı. | **M** |
| **3** | Bugün / Vakitler / Esma | **Offline dayanıklılık.** Ağ hatasında tüm ekranı boş duruma düşürme; son bilinen vakitleri "Son güncelleme: dün 21:40" etiketiyle göster, hatayı sadece ilgili karta hapset. [Swiggy](https://mobbin.com/screens/25f4cc9d-9a98-4efb-87b3-58bd6fd98552) deseni. | Kıble, zikirmatik, Esma ve önbellekli vakitler internetsiz tamamen çalışabilir. Namaz vakti uygulamasının çevrimdışı boş ekran göstermesi güven kaybettirir. | **M** |
| **4** | Paywall (`PaywallView.swift`) | **3 planı yan yana sticky footer'a al** + her sütunda **haftalık birim fiyat** + CTA'da plan adı ("Yıllık plana geç"). [Bloom](https://mobbin.com/screens/71492042-1dac-41c0-a148-0150c6325c9d) + [Hevy](https://mobbin.com/screens/19fce77b-a3e7-428c-857c-79aa00fbe716). | Dikey 3 kart karşılaştırmayı zorlaştırır ve scroll gerektirir; fiyat sürekli görünür olunca karar hızlanır. Haftalık birim fiyat "%X tasarruf" rozetinden daha somut. | **M** |
| **5** | Paywall | **3 noktalı deneme zaman çizelgesi** (Bugün → 5. gün hatırlatma → 7. gün başlar) + **"Deneme bitmeden hatırlat" toggle'ı.** [Mimo](https://mobbin.com/screens/e257555e-bd98-4163-b095-198a8c58473b) + [Vocabulary](https://mobbin.com/screens/32238af5-552f-4ac3-bede-16981f4c23d3). | Mevcut tek satırlık `paywallReminderNote` aynı bilgiyi taşıyor ama endişeyi gidermiyor. Toggle, `NotificationEngine` zaten varken neredeyse bedava ve "dürüst paywall" duruşunu somutlaştırır. | **M** |
| **6** | Onboarding — bildirim adımı | **Gerçek ezan bildiriminin sahte önizlemesi** ("Mihrab · şimdi — İkindi vakti girdi · Ankara") + "Sonraki ekranda **İzin Ver**'i seçin" cümlesi. [Strava](https://mobbin.com/screens/c43f3937-d7e3-4af8-9a56-1bb85e63a06d) + [Affirm](https://mobbin.com/screens/c797ee4d-1c25-4e77-b592-9f6732e5725a). | Bildirim izni Mihrab'ın **çekirdek değeri** — reddedilirse uygulama işlevsiz kalır. Madde listesi yerine ürünün somut çıktısını göstermek kabul oranını belirgin artırır. | **S** |
| **7** | Onboarding — yöntem adımı | `methodPage`'i **teknik listeden kişiselleştirme sorusuna** çevir: "Vakitleri hangi kuruma göre istersin?" + 3-4 kapsül + "Emin değilim" kaçışı (konuma göre otomatik seçip söyle). [Tiimo](https://mobbin.com/screens/e2345aec-25d2-4584-9bcc-266601eaf9de). | `CalculationMethod.allCases` + segmented madhab picker, ilk 60 saniyede kullanıcıya sormaması gereken bir soru. Otomatik seçip "istersen değiştir" demek terk oranını düşürür. | **M** |
| **8** | Onboarding — ilerleme | 7 eşit capsule yerine **3 gruplu segmentli çubuk** (Tanışma · Ayarlar · Bonus). [Hers](https://mobbin.com/screens/c5d35999-99dd-4583-be65-93db284351a7). | 7 adım uzun görünür; 3 bölüm halinde gruplanınca algılanan uzunluk düşer. | **S** |
| **9** | Bugün — hızlı eylemler | 2×2 `LazyVGrid` → **tek satır yatay çip şeridi**, hero'nun hemen altına. [TIDE](https://mobbin.com/screens/50a3b0f2-b2be-41d3-bf9e-cac733217b14). | ~60pt dikey alan kazanılır ve hızlı eylemler scroll'suz görünür hale gelir (şu an 6. blok). | **S** |
| **10** | Bugün — `PrayerLogCard` | Bugünün 5 dairesinin altına **7 günlük geçmiş şeridi** (nokta/işaret) ekle; ardışık günleri birleşik kapsül olarak çiz. [timespent](https://mobbin.com/screens/c49184d7-4dc7-4f49-b7df-cce7563bc829) + [Duolingo](https://mobbin.com/screens/736a41b0-0984-4010-b7da-33a2c922d0b9). | Streak şu an tek bir sayı. Desen olarak görülünce süreklilik motive eder, kopuş suçlamadan görünür olur. | **M** |
| **11** | Zikirmatik (`DhikrView.swift`) | **Odak modu**: sayaç yüzeyine tek tap ile header/footer/hint kaybolur, sadece rakam + halka + nefes alan shader kalır; tekrar tap geri getirir. [pushr](https://mobbin.com/screens/15b9ef05-dfc8-49aa-9736-ea0093e1ab3c) + [stoic.](https://mobbin.com/screens/398c589e-c4e1-409d-ada9-13c254b5e3c7). | 871 satırlık ekranda 4 katman chrome var. Zikir dakikalarca süren tek amaçlı bir eylem; chrome'un çekilmesi hem estetik hem işlevsel. | **M** |
| **12** | Zikirmatik | **Sıfırlamayı basılı tutmaya çevir** (halka dolarak onay) + halkanın çevresine **her 11'de bir tik** (tesbih tanesi metaforu). [Forest](https://mobbin.com/screens/98e03470-479d-46ef-b679-21a83c0fb7bf) + [Calm Sleep](https://mobbin.com/screens/54e3f825-c301-4fc9-a3d1-3b72bc658591). | 500'lük bir sette yanlışlıkla sıfırlama telafi edilemez. Tikler ise sayıya bakmadan konum bilgisi verir. | **S** |
| **13** | Kıble (`QiblaCompassView.swift`) | **Kadranın merkezine eylem talimatı** koy ("12° sağa dön" / hizalıysa "Kıbleye dönüksün"); derece/mesafe/açı alttaki etiket-değer tablosuna insin. Kalibrasyon uyarısını tam genişlik banner'dan **yüzen kompakt kapsüle** çevir. [Lumy](https://mobbin.com/screens/6c285ffd-a76e-4528-a227-7ca21df20cd8) + [Sunlitt](https://mobbin.com/screens/9b61f472-b3d8-47c6-abc9-9a9152b373bf). | Kullanıcı pusulaya "kaç derece" diye değil "ne yapmalıyım" diye bakar. Merkez, gözün ilk gittiği yer. | **S** |
| **14** | Kıble — AR (`QiblaARView.swift`) | AR'da **tek büyük ok + tek cümle + sağ altta mini kadran**; girişte "telefonu 8 çizerek salla" kalibrasyon kartı. [Starlink](https://mobbin.com/screens/b845d028-60c3-41b4-9033-3ed9737d73aa) + [Best Buy](https://mobbin.com/screens/7239d336-049e-492e-aa8c-e07a998d24fb). | Magnetometre kalibre değilse AR yanlış yönü gösterir ve kullanıcı uygulamayı suçlar. Mini kadran AR'dan çıkmadan doğrulama sağlar. | **M** |
| **15** | Sezonluk (`Theme` + `TodayView`) | **Vakte göre kayan arka plan sahnesi**: fecir → soğuk mavi, öğle → açık zümrüt, ikindi/akşam → pirinç-amber, yatsı → derin abis. `MihrabBackdrop` + shader sistemi zaten mevcut, countdown zaten hangi vakitte olduğumuzu biliyor. [BitePal gündüz](https://mobbin.com/screens/52da1b20-f4f8-4289-82c1-7bf5fae0349d) / [gece](https://mobbin.com/screens/aa2a99a6-637c-4183-8321-f7d14ac93eca). | Uygulama günün ritmiyle nefes alır — Mihrab'ın "sakin/lüks" iddiasını kanıtlayan, ADA jürisinin fark edeceği türden bir detay. Altyapı hazır. | **M** |
| **16** | Ramazan (`RamadanHubView.swift`) | Ramazan boyunca **Bugün ekranının üst bandı** (selamlama + hero) Ramazan paletine geçsin; "Ramazan · 12. gün · 17 gün kaldı" bandı en üste otursun. Hub içinde `FastingLogStore` verisini **30 hilalli bir yol** olarak çiz (`CrescentFillMark` × 30). [Duolingo Quest](https://mobbin.com/screens/9f9ad31c-ec4e-4a7c-98a0-764d40835315) + [Finch Season](https://mobbin.com/screens/8d96ed66-fee8-4c32-8266-fddd6d8291ab). | Şu an Ramazan kartı listede 8. sırada ve mod sadece aksan rengini değiştiriyor. Ramazan yılın en yoğun kullanım dönemi — üst bant hak ediyor. | **M** |
| **17** | Esmaül Hüsna (`EsmaGridView.swift`) | Uzun listeye **bölüm başlıkları + sonuç sayacı** ("99 isimden 12'si · Rahmet") ekle; ızgara modunu 3 sütuna çıkar; **favoriler filtre toggle'ı olmaktan çıkıp kalıcı bir giriş** olsun. [MD Vinyl](https://mobbin.com/screens/0f221ca7-9ced-464e-995e-614354da812c) + [Apple Books](https://mobbin.com/screens/fb8d6cde-a349-4b0b-a1d5-4fbbc3fce77f) + [DailyArt](https://mobbin.com/screens/e32a1a29-45de-46d6-96bb-4b79f663ca4f). | 99 öğe düz akışta gezilemez; filtre uygulandığında kullanıcı kaç sonuç kaldığını bilmiyor. 3 sütun tüm koleksiyonu 2 ekrana sığdırır — "koleksiyona sahip olma" duygusu. | **M** |
| **18** | İstatistik (`DhikrStatsView.swift`) | **Yıllık ısı haritası** (365 kare, zümrüt yoğunluğu = günlük zikir) + grafikte **kesikli hedef çizgisi** ve hedefi aşan günlerde tepe rozeti + **bir sonraki rozet her zaman görünür**. [MacroFactor](https://mobbin.com/screens/d7659072-cae4-4d38-8a5e-c8ebdb64c1a1) + [Google Fit](https://mobbin.com/screens/6f1f2225-c442-4de4-873d-8a5d47350fda) + [Atoms](https://mobbin.com/screens/35c534be-70d1-4000-8ac6-65391a765881). | Isı haritası paylaşılabilir, duygusal ve Emerald Glass paletinde çok güzel görünür. Hedef çizgisi grafiği "veri"den "başarı"ya çevirir. | **M** |

### Bonus — küçük ama ucuz kazanımlar (hepsi S)

| # | Ekran | Değişiklik | Referans |
|---|---|---|---|
| 19 | Ayarlar | Bildirim satırının sağında **canlı durum etiketi** ("Açık" / "Kapalı — Ayarlar'dan aç", turuncu) | [Cosmos](https://mobbin.com/screens/d40a9283-9bde-4f0b-93d0-2c01f818b914) |
| 20 | Boş durumlar | `MihrabEmptyState`'te SF Symbol yerine **`MihrabArchMark` / `EsmaRosette` / hilal** motifleri; arama boşluğu ile veri boşluğu için ayrı metinler | [Lovi](https://mobbin.com/screens/278fa40d-ef7f-4935-b3a8-12e3ef1a4122), [Postmates](https://mobbin.com/screens/2be73ba9-c3fa-4332-b1a5-cd2e1648d9ee) |
| 21 | İskeletler | `TodaySkeleton`'ı gerçek yeni layout'a göre genişlet; Vakitler ve Esma ekranlarına da iskelet ekle (şu an spinner) | [AllTrails](https://mobbin.com/screens/a6a7bb97-d19a-410e-94cc-9473cbeeb39b), [Careem](https://mobbin.com/screens/9efed28e-6a50-40b8-a8a6-e504c351c151) |
| 22 | Paywall | **"Mihrab'ın kalbi hep ücretsiz"** bloğu (vakitler · kıble · zikirmatik asla kilitlenmez) dipnottan çıkarılıp faydaların üstüne alınsın | [timespent](https://mobbin.com/screens/c9098dc0-df20-49c8-9ff0-3720857cee3a) |
| 23 | Zikirmatik | Hedefe yaklaşınca halka rengi **zümrüt → pirinç** ısınsın; set bitince "+33 kaydedildi" mikro-toast | [Apple Fitness](https://mobbin.com/screens/620e1c4b-46e7-4ba7-936d-a2bded2de22e), [stoic.](https://mobbin.com/screens/398c589e-c4e1-409d-ada9-13c254b5e3c7) |
| 24 | Streak | **"Mazeret günü"** mekanizması (seyahat/hastalık) — seri kırılmasın. Duolingo "Streak Freeze" karşılığı; Mihrab bağlamında dini olarak da doğru bir mesaj | [Duolingo](https://mobbin.com/screens/736a41b0-0984-4010-b7da-33a2c922d0b9) |

---

## Korunması gereken şeyler (değiştirme)

Araştırma sırasında görülen kötü desenlerin **Mihrab'da zaten olmadığı** noktalar — bunlar rekabet avantajı:

1. **Geri sayımlı indirim yok.** [Peanut](https://mobbin.com/screens/fea3b0ed-9377-41d6-8282-8146146daefc) gibi "39% off ends in 47:27:13" baskısı Mihrab'ın tonuyla uyuşmaz. Kod yorumundaki "nothing counts down" ilkesi korunmalı.
2. **Kapatma butonu ilk kareden görünür.** Birçok paywall onu 3 saniye geciktiriyor.
3. **Ücretsiz katman adıyla anılıyor.** Sadece daha görünür yapılmalı, kaldırılmamalı.
4. **Reduce Motion her yerde dallanıyor.** `cardEntrance`, `BreathingRing`, `ParticleBurst`, sayfa geçişleri — hepsi kontrol ediyor. Yeni eklenen her animasyon (ısı haritası, sahne geçişi, hilal yolu) aynı disipline uymalı.
5. **Kalibre olmayan pusula dürüstçe söyleniyor.** "Emin değilsek iğneyi göstermeyiz" duruşu, güvenin temeli.
6. **Hesaplamalar türetiliyor, uydurulmuyor.** `DaySummaryRow` yorumundaki "Both derived — never invented" ilkesi.
