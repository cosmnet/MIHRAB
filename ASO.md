# Revak — ASO ve Yayın Paketi

> Sahibi: Ajan X2 · Kaynak: [`RESEARCH_MARKET.md`](RESEARCH_MARKET.md) bölüm 5 · Yol haritası #22
> Son güncelleme: 2026-08-23 · Hedef sezon: **Ramazan 2027 = 8 Şubat 2027**

Bu dosya araştırmayı **kopyala-yapıştır edilebilir** bir teslim paketine çeviriyor.
Aşağıdaki metinlerin hepsi doğrudan App Store Connect'e girilebilir.

---

## 0. Bir sayfada özet

| Ne | Karar |
|---|---|
| Birincil pazar | **Türkiye** (ASA'da CPI ≈ $1,02 — ABD'nin ~¼'ü, marka dışı organik hâlâ mümkün) |
| Birincil dil | `tr` · Türkiye storefront'unda ikincil `en-GB` = **+100 indekslenebilir karakter, bedava** |
| Başlık stratejisi | `Revak:` öneki kısa, kalan alan jenerik terimlere. TR'de marka-önce isimlendirme ölçülebilir dezavantaj |
| Kazanılacak ana terim | **zikirmatik** (ilk 12'nin toplamı ~55K — kazanılabilir en iyi ana terim) |
| Bedava terimler | **kaza namazı** (1. sıradaki uygulamanın <1.000 puanı var), **esmaül hüsna**, **hac umre** |
| En büyük tek kaldıraç | **CPP'ler** — 70 adet, artık anahtar kelime atanabiliyor ve organik arama sonucunda görünüyor |
| Kritik tarih | **~11 Aralık 2026** (üç aylar). Sezon Şubat'ta değil Aralık'ta başlıyor |

---

## 1. Metadata — Türkiye (`tr`, birincil)

### 1.1 Yıl boyu (varsayılan)

```
Başlık   (28/30): Revak: Namaz Vakti ve Kıble
Alt başlık(28/30): Ezan, Zikirmatik ve İmsakiye
Anahtar (100/100): imsak,iftar,sahur,dua,tesbih,esmaül,hüsna,kuran,ramazan,kandil,hicri,takvim,kaza,diyanet,hadis,kible
```

**Karakter sayımı**

| Alan | Karakter | Limit | UTF-8 bayt |
|---|---|---|---|
| Başlık | 28 | 30 | 29 (`ı` çift bayt) |
| Alt başlık | 28 | 30 | 29 (`İ` çift bayt) |
| Anahtar kelime | 100 | 100 | **102** (`ü`×2 çift bayt) |

> ⚠️ **Bayt riski.** App Store Connect anahtar kelime alanını bugün *karakter* olarak sayıyor,
> ama araştırma notu pratikte bayt sınırı gözlendiğini söylüyor. ASC alanı 100'de kesiyorsa
> aşağıdaki **94 karakter / 96 bayt** güvenli varyantı kullan (yalnızca `kible` çıkarıldı):
>
> ```
> imsak,iftar,sahur,dua,tesbih,esmaül,hüsna,kuran,ramazan,kandil,hicri,takvim,kaza,diyanet,hadis
> ```
>
> `kible` (noktasız-i) kaybı önemli: Türkçe mağaza hem `kıble` hem `kible` yazımını ayrı indeksliyor
> ve `kıble` zaten **başlıkta**. Bayt sınırı yoksa mutlaka `kible`'yi tut.

**Neden bu kelimeler yok:** `namaz`, `vakti`, `kıble`, `ezan`, `zikirmatik`, `imsakiye`, `mihrab`
başlık/alt başlıkta zaten geçiyor — Apple bunları tekrar yazmanı istemiyor, alan israfı olur.
Virgülden sonra boşluk **yok**; boşluk bir karakter yer.

### 1.2 Ramazan varyantı

Şaban'ın başında (≈ **10 Ocak 2027**) değiştir, bayramdan bir hafta sonra (**~18 Mart 2027**) geri al.

```
Başlık   (29/30): Revak: Ramazan İmsakiye 2027
Alt başlık(30/30): Namaz Vakti, İftar, Sahur, Dua
```

Karakter/bayt: başlık **29 karakter / 30 bayt**, alt başlık **30 karakter / 31 bayt**.
Başlık ve alt başlık alanlarının *karakter* saydığı kesin (ASC bu iki alanda 30 karakterde
kesiyor), dolayısıyla 31 bayt sorun değil.

> **Bilinçli takas:** Ramazan başlığı `kıble`yi başlıktan düşürüyor. Kıble talebi Ramazan'da
> zaten ikinci plandadır; `imsakiye` + `ramazan` ifadesini **tam eşleme** yakalamak buna değer.
> Kıble, dönem boyunca `kible` anahtar kelimesi ve **kıble CPP'si** üzerinden savunulur.

### 1.3 Türkiye storefront'unda ikincil dil: `en-GB`

Apple her mağazada ikincil dilleri de indeksler. Türkiye mağazasında `tr` + `en-GB` = **320
indekslenebilir karakter**. Bu ekstra alan hiçbir Türk kullanıcıya görünmez, sadece indekse girer.

```
Anahtar (94/100): prayer,times,qibla,compass,muslim,islam,dhikr,tasbih,athan,adhan,fasting,salah,tracker,counter
```

Başlık/alt başlığı `tr` ile **aynı** bırak (kullanıcıya görünen bu değil, ama tutarlılık için).
Kural: aynı kelimeyi iki dilde yazma — kombinasyonlar yalnızca aynı dil içinde oluşur.

---

## 2. Metadata — ABD / global (`en-US`)

```
Başlık   (28/30): Revak: Prayer Times & Qibla
Alt başlık(29/30): Athan, Dhikr, Ramadan & Hijri
Anahtar (98/100): adhan,azan,salah,salat,namaz,tasbih,tasbeeh,zikr,dua,99,names,allah,asma,husna,iftar,suhoor,muslim
```

98 karakter, tamamı ASCII = **98 bayt**. Bayt riski yok.

> ⚠️ **`quran` bilerek yok.** Kur'an okuyucu (yol haritası #15) henüz binary'de değil.
> Olmayan özelliği metadata'da satmak Guideline 2.3.1 ihlali. #15 çıktığında
> alt başlığı `Athan, Dhikr, Quran & Ramadan` (29) yap ve `quran`'ı anahtar alanından çıkar.

### 2.1 ABD storefront'unda ikincil dil: Arapça

ABD mağazasında Arapça bir ikincil dildir — Arapça İslami terimleri oraya yazarsan ABD'de o
terimlerde sıfır maliyetle sıralanırsın.

```
Anahtar (50 karakter / 93 bayt):
مواقيت,الصلاة,أذان,القبلة,أذكار,تسبيح,أسماء,الحسنى
```

> Arapça harfler UTF-8'de **2 bayt**. Araştırmadaki 11 terimlik uzun liste 70 karakter ama
> **~129 bayt** — bayt sınırı varsa reddedilir. Yukarıdaki 8 terimlik liste 93 baytla güvenli.
> Bayt sınırı olmadığı doğrulanırsa `رمضان,إمساكية,بوصلة` eklenir.

---

## 3. Açıklama metni

**İlk 3 satır kritik:** iPhone'da "daha fazla"dan önce ~170 karakter görünür. Oraya
özelliği değil **ahlaki vaadi** koy — kategorinin gerçek acısı bu.

### 3.1 Türkçe

```
Reklamsız. Veri toplamayan. Diyanet uyumlu.

Revak; namaz vakitlerini, kıbleyi, ezan bildirimlerini ve zikirmatiği hiçbir
zaman ücret ya da reklam duvarının arkasına koymaz. İbadetin kendisi ücretsiz.

— NAMAZ VAKİTLERİ, GERÇEKTEN DOĞRU
Vakitler cihazında hesaplanır: uçakta, çekmeyen yerde, sunucu kesintisinde
susmaz. Diyanet temkin süreleri uygulanır; istersen Fazilet ya da Türkiye
Takvimi geleneğini seçersin. Her vakti dakikası dakikasına kendin de
düzeltebilirsin — ve hangi sayının nereden geldiğini şeffaflık panelinde
görürsün.

— İKİNDİ SORUSUNU SORUYORUZ
Diyanet takvimi ikindiyi çoğunluk (Şafi) kuralıyla yayımlar; Türkiye'de
çoğunluk Hanefi kuralını takip eder. Aradaki fark İstanbul'da bir saati
bulabiliyor. Revak kurulumda bunu sessizce seçmez — iki saati de yan yana
gösterir, tercihi sen yaparsın.

— GERÇEK EZAN, TAM UZUNLUKTA
iOS 26 AlarmKit ile ezan 30 saniyede kesilmez. Ezan sesini seçersin.

— KIBLE, DÜRÜSTÇE
Pusula kalibre değilse iğneyi göstermeyiz; yanlış yön göstermektense
söylemeyi tercih ederiz. Güneşle doğrulama ve AR modu içinde.

— ZİKİRMATİK, ESMÂ-ÜL HÜSNÂ, KAZA TAKİBİ, ZEKÂT
99 ismin tamamı ücretsiz. Zikirmatikte hedefler, seriler, titreşim.
Kaza namazı takibi ve zekât hesaplayıcı da ücretsiz.

— RAMAZAN
İmsakiye, iftar ve sahur geri sayımı, Kilit Ekranı'nda Live Activity,
oruç günlüğü ve hatim takibi.

— MİHRAB PLUS
İbadetin temeli hep ücretsiz kalır. Plus; temaları, gelişmiş widget'ları,
tam zikir geçmişini, çoklu şehri ve iCloud eşitlemeyi ekler.
7 gün ücretsiz denenir, geri sayım baskısı yoktur, iptal Ayarlar'dan tek
dokunuşla yapılır.
```

### 3.2 İngilizce

```
No ads. No data collection. Times you can trust.

Revak never puts prayer times, the qibla, adhan alerts or the dhikr counter
behind a paywall or an ad. Worship itself is free.

— PRAYER TIMES, COMPUTED ON YOUR DEVICE
No server, no signal, no problem. Choose your calculation authority, apply
per-prayer corrections down to the minute, and see exactly where every number
came from in the transparency panel.

— WE ASK ABOUT ASR
The majority and Hanafi rulings can put Asr almost an hour apart. Revak shows
you both real times during setup and lets you choose, instead of picking one
for you.

— A REAL ADHAN, AT FULL LENGTH
With iOS 26 AlarmKit the adhan is no longer cut off after 30 seconds.

— AN HONEST QIBLA
If the compass isn't calibrated we say so rather than point you the wrong way.
Sun-based verification and an AR mode are included.

— DHIKR, THE 99 NAMES, QADA TRACKING, ZAKAT
All 99 names are free. So is qada prayer tracking and the zakat calculator.

— RAMADAN
Imsakiye, iftar and suhoor countdowns, a Lock Screen Live Activity, a fasting
log and khatm tracking.

— MIHRAB PLUS
The essentials stay free forever. Plus adds themes, advanced widgets, full
dhikr history, multiple cities and iCloud sync. Seven days free, no countdown
pressure, cancel in one tap.
```

> **Doğrulama notu.** Yukarıdaki iki metin yalnızca binary'de **var olan** özellikleri anlatıyor
> (dalga 1: cihaz üstü hesaplama, AlarmKit, ezan kütüphanesi, temkin + kaynak seçici, kaza takibi,
> zekât, çoklu şehir, şeffaflık paneli). Kur'an okuyucu, Apple Watch ve Hac/Umre **bilerek yok**.
> Bunlar çıkana kadar metne eklenmeyecek.

---

## 4. Custom Product Page (CPP) planı

2026'da CPP sayısı 35 → **70**'e çıktı, artık **anahtar kelime atanabiliyor** ve arama
sonuçlarında **organik** görünüyorlar. Bu, CPP'yi reklam iniş sayfası olmaktan çıkarıp bir ASO
varlığına dönüştürdü. Tipik kazanç: varsayılan sayfaya göre **%18–26 dönüşüm artışı**.

### 4.1 İlk üç CPP (lansmanda hazır olacaklar)

| # | CPP | Kitle | Atanacak anahtar kelimeler | 6 ekran görüntüsü sırası |
|---|---|---|---|---|
| **1** | `ramazan-imsakiye` | Ramazan'a hazırlanan, yılda bir uygulama indiren geniş kitle. **Yılın en yüksek hacimli, en kısa pencereli kitlesi.** | ramazan, imsakiye, iftar, sahur, oruç, teravih, kadir gecesi | ① İmsakiye + iftara geri sayım ② Kilit ekranında iftar Live Activity ③ Ramazan hub'ı + oruç günlüğü ④ Sahur bildirimi ⑤ Hatim takibi ⑥ "Sıfır reklam" vaadi |
| **2** | `kible` | **Ayrı, büyük ve para kazandıran bir niyet** — ilk 12 sonucun 6'sı yalnızca kıble uygulaması. Seyahat eden, otelde yön arayan kullanıcı. | kıble, kible, kıble bulucu, pusula, kabe, kıble yönü | ① Kadran + "12° sağa dön" talimatı ② AR kıble ③ Doğruluk / kalibrasyon dürüstlüğü ④ Güneşle doğrulama ⑤ Çevrimdışı çalışır ⑥ Namaz vakti de içinde |
| **3** | `kaza-namazi` | **Tamamen açık terim** — 1. sıradaki uygulamanın 1.000'den az puanı var. Duygusal olarak en bağlayıcı kitle; en yüksek elde tutma. | kaza namazı, kaza takibi, borç namaz, 5te5, namaz takip | ① Kaza sayacı + kalan toplam ② Günlük ilerleme ve seri ③ Duraklama modu (seyahat/hastalık) ④ Vakitler ekranı ⑤ Zikirmatik ⑥ "Ücretsiz — reklamsız" |

**Neden bu üçü:** biri **sezonluk zirve** (hacim), biri **ayrı satın alma niyeti** (dönüşüm),
biri **rekabetsiz boşluk** (bedava trafik). Üçü de farklı bir işi yapıyor; üçü de aynı jenerik
"namaz vakti" terimini kovalamıyor.

### 4.2 İkinci dalga (Aralık 2026'ya kadar)

`zikir-tesbih` · `esma-ul-husna` · `apple-watch` (watch hedefi çıktığında) ve bunların
`en` / `ar` karşılıkları. Toplam hedef: **12 CPP** — 70'lik kotanın çok altında, yönetilebilir.

### 4.3 Apple Search Ads eşlemesi

**Mart 2026'dan itibaren CPA tavanları kalktı**; otomatik teklif verme hacim istiyor — çok sayıda
küçük kampanya yerine **tema başına tek kampanya** kur. Her kampanya kendi CPP'sine gitsin:

| Kampanya | Amaç | CPP |
|---|---|---|
| Marka savunması (`mihrab`) | Ucuz ve **zorunlu** — rakipler adına teklif verir | varsayılan |
| TR ana terimler (tam eşleme) | namaz vakti, ezan vakti | varsayılan |
| Kıble | ayrı niyet | `kible` |
| Ramazan (sezonluk) | T−3 hafta'da açılır | `ramazan-imsakiye` |
| Kaza / takip | ucuz, yüksek elde tutma | `kaza-namazi` |
| Rakip terimleri | savunma + hacim | varsayılan |
| Keşif | otomatik | varsayılan |

---

## 5. Ekran görüntüsü stratejisi (varsayılan sayfa, 6 kare)

**İlk kare her şeydir** — aramada yalnızca ilk 1–2 kare görünür. Türkçe mağazada **Türkçe**
ekran görüntüsü kullan (araştırmanın açıkça vurguladığı nokta).

| # | Başlık (TR) | Başlık (EN) | Ne gösterecek |
|---|---|---|---|
| **1** | **Sıfır reklam. Diyanet uyumlu.** | **No ads. Times you can trust.** | Bugün ekranının hero'su: sonraki vakit + geri sayım halkası, vakte göre kayan arka plan sahnesi. Tek cümlelik ahlaki vaat en üstte. Bu karenin işi özellik anlatmak değil, **kategorinin acısına dokunmak** |
| **2** | **Kilit ekranında, açmadan** | **On your Lock Screen** | Widget + Live Activity + Dynamic Island geri sayımı. Rakiplerin en çok övüldüğü ve en çok şikayet edildiği yer; aynı zamanda TikTok/Reels'te en kaydedilebilir varlık |
| **3** | **Yanlış yön göstermeyiz** | **We won't point you wrong** | Kıble kadranı, merkezde "12° sağa dön" talimatı, altta doğruluk göstergesi + kalibrasyon dürüstlüğü. AR modu köşede |
| **4** | **Vakit neden bu? Göster.** | **Where does this time come from?** | Şeffaflık paneli: kaynak (Diyanet / Fazilet / Türkiye Takvimi), temkin dakikaları, kullanıcı düzeltmesi. **Kategorinin 1 numaralı şikâyetine verilen görsel cevap** |
| **5** | **Zikirmatik ve 99 isim** | **Dhikr & the 99 Names** | Zikirmatik odak modu + Esmâ-ül Hüsnâ ızgarası. Esmâ görsel olarak **en çarpıcı** ekran; kazanılacak terim (`zikirmatik`) burada |
| **6** | **Kaza, zekât, çoklu şehir** | **Qada, zakat, multiple cities** | Kaza sayacı + zekât hesaplayıcı + şehir listesi. "Tek uygulamam" iddiasının kanıtı |

**Sezonda:** Ramazan hub'ı karesini **1. sıraya** al (kare 1 yedeğe düşer, kare 6 çıkar).
Bunu **Creative Assets** ile tam uygulama güncellemesi göndermeden yapabilirsin.

**App Preview videosu** (15–30 sn, **sessiz izlenebilir**): geri sayım → ezan → kıble → zikir.
Ses olmadan anlaşılmalı; App Store önizlemeleri sessiz başlar.

---

## 6. In-App Event planı

Kurallar: **15 onaylı / 10 canlı / her biri 31 güne kadar / başlangıçtan 14 gün önce yayınlanabilir.**
Etkinlik adları **aranabilir ve indekslenir** — ana metadata'nın taşıyamadığı sezonluk terimler
buradan sıralanır. Ayrıca ASC içinden **Apple editoryal değerlendirmesine** sunulabilir.

> 2026 kural değişikliği: In-App Event'ler ve kritik hata düzeltmeleri artık incelemedeki bir
> sürümden **ayrı** gönderilebiliyor. Ramazan etkinliğin bekleyen bir build'e takılmaz.

| Etkinlik adı (TR) | Tür | Yayına alma | Etkinlik penceresi | Not |
|---|---|---|---|---|
| **Üç Aylar Başlıyor** | Major Update | 27 Kas 2026 | 11 Ara 2026 – 10 Oca 2027 (31 gün) | Sezonun açılışı. Kandil bildirimleri ve nafile oruç hatırlatıcısı bu etkinlikte tanıtılır |
| **Mirac Kandili** | Special Event | ~22 Oca 2027 | 5–6 Şub 2027 civarı (2 gün) | Kandil gecesi paylaşılabilir tebrik kartı — TR'de bedava dağıtım motoru |
| **Berat Kandili** | Special Event | ~9 Oca 2027 | 22–23 Oca 2027 civarı (2 gün) | Aynı desen |
| **Ramazan 2027 İmsakiye** | Major Update | **25 Oca 2027** | 8 Şub – 8 Mar 2027 (29–30 gün) | **Yılın en önemli tek varlığı.** 14 gün erken yayınlanması, en yüksek değerli edinme penceresine denk gelmesi için şart. Apple editoryal değerlendirmesine mutlaka sun |
| **Kadir Gecesi** | Special Event | ~20 Şub 2027 | 5–6 Mar 2027 | **Yılın tek en büyük etkileşim gecesi.** Ayrı etkinlik hak ediyor |
| **Ramazan Bayramı** | Special Event | ~24 Şub 2027 | 9–11 Mar 2027 | Bayram tebrik kartları. **Harcamayı kesme** — Utilities kurulumları bayram sonrası +%43 |
| **Şevval Orucu** | Challenge | ~5 Mar 2027 | 12 Mar – 11 Nis 2027 (31 gün) | Bayram sonrası elde tutma kampanyası; 6 günlük oruç takibi |

Kandil tarihleri hilal gözlemine göre ±1 gün kayabilir — etkinlik pencerelerini
`IslamicCalendar.upcomingObservances` ile **yayından önce doğrula**, tahminle girme.

---

## 7. Ramazan 2027 geri sayımı

**Tarihler:** Ramazan 2027 = **8 Şubat 2027** · Üç aylar ≈ **11 Aralık 2026** · Kadir Gecesi ≈ 5–6 Mart · Bayram 9–11 Mart.
Sonraki yıllar: 2028 → 28 Ocak, 2029 → 16 Ocak.

**Neden Aralık:** En yüksek yaşam boyu değere sahip kullanıcılar Ramazan'dan **~2 hafta önce**
ediniliyor (bu kohortlarda D7/D14/D30 elde tutma ~%20 daha yüksek). Ramazan'da indirmeler
**1,6×–2,2×**, zirve **ilk 1–2 gün**. Oturum süresi 22,5 → 37 dakika.

| Hafta | Tarih | Ne hazır olacak |
|---|---|---|
| **T−14** | 2–8 Kas 2026 | **Apple Featuring Nomination gönderilir** (Apple en az 3 hafta ister, 3 aya kadar önerir — bu tek asimetrik hamle). **Influencer anlaşmaları imzalanır** — Ramazan'da fiyatlar ~%40 artıyor |
| **T−13** | 9–15 Kas | Gizlilik politikası sayfası **canlıda** (`PaywallView.privacyURL` placeholder'ı değişir). Ürün kimlikleri ASC'de tanımlı, TR fiyatları **elle** girilmiş |
| **T−12** | 16–22 Kas | 6 varsayılan ekran görüntüsü TR + EN çekildi. App Preview videosu çekildi |
| **T−11** | 23–29 Kas | İlk 3 CPP (`ramazan-imsakiye`, `kible`, `kaza-namazi`) oluşturuldu, anahtar kelimeleri atandı. "Üç Aylar Başlıyor" etkinliği gönderildi |
| **T−10** | 30 Kas – 6 Ara | **Sürüm yayında.** ASA marka savunması + TR ana terim kampanyaları açık (düşük bütçe, öğrenme fazı) |
| **T−9** | **7–13 Ara** | **⚑ Üç aylar başlıyor (~11 Ara).** Kandil bildirimleri canlı. İlk metadata değişimi yapıldı. Bu tarihten sonra çıkan her hata pahalı |
| **T−8 … T−6** | 14 Ara – 3 Oca | İkinci dalga CPP'ler (`zikir-tesbih`, `esma-ul-husna`). Ekran görüntüsü kreatif testi (ASA ile). CloudKit şeması **dondurulur** — yayına alındıktan sonra yalnızca eklemeli değişir |
| **T−5** | 4–10 Oca | Ramazan metadata varyantı hazır (henüz gönderilmez). Ramazan Creative Assets yüklendi |
| **T−4** | **10–17 Oca** | **Şaban başı: Ramazan başlık/alt başlık varyantı devreye alınır.** Miraç ve Berat kandilleri — organik içerik zirveleri, kreatif testinin sonucu okunur |
| **T−3** | **18–24 Oca** | **Ramazan CPP'leri anahtar kelimeleriyle canlı.** İmsakiye özelliği çıkmış ve test edilmiş. Camii/dernek dağıtımı için QR kodlu basılı imsakiye kartları basımda (DİTİB dahil Avrupa Türk cemaat merkezleri) |
| **T−2** | **25 Oca – 7 Şub** | **⚑ EN YÜKSEK DEĞERLİ EDİNME PENCERESİ. Ücretli harcamanın zirvesi.** "Ramazan 2027 İmsakiye" In-App Event yayına alınır (25 Oca). Influencer içerikleri yayınlanır |
| **0** | **8 Şub** | **Ramazan başlıyor.** İndirme zirvesi ilk 1–2 günde. Sunucu/bildirim yükü kontrol edilir |
| **+4** | **5–6 Mar** | **Kadir Gecesi — yılın tek en büyük etkileşim gecesi.** Ayrı etkinlik + paylaşılabilir kart |
| **+5** | **9–11 Mar** | **Ramazan Bayramı.** Ayrı kreatif fazı. **Harcamayı kesme** |
| **+6/+7** | **12–26 Mar** | **Bayram sonrası: Utilities kurulumları burada zirve yapıyor (+%43).** Şevval orucu, kaza takibi ve hatim devamı ile elde tutma kampanyası |
| **+8** | ~18 Mar | Metadata yıl-boyu varyantına geri döner |

**Türkiye özel not:** TR'de Ramazan dönemi kurulum artışı ~%9 (Suudi Arabistan +%34, Pakistan +%21).
Yani TR'de asıl kazanç **hacim sıçramasında değil, kohort kalitesinde** — T−2 penceresinde edinilen
kullanıcının elde tutması belirgin biçimde daha iyi. Bütçeyi oraya yığ.

---

## 8. Yayın öncesi kontrol listesi

Sahibinin App Store Connect'te / dışarıda yapması gerekenler. Kod tarafı değil.

### 8.1 Engelleyiciler (bunlar olmadan gönderilemez)

- [ ] **Gizlilik politikası URL'si canlı.** `PaywallView.privacyURL` şu an `https://mihrab.app/privacy`
      — **bu alan adı yayında değil.** Guideline 3.1.2 paywall'da *çalışan* bir gizlilik bağlantısı
      şart koşuyor. Sayfa yayına alınıp URL koda girilmeli. (Kullanım Şartları Apple'ın standart
      EULA'sına bağlı, o çalışıyor.)
- [ ] **`PrivacyInfo.xcprivacy`** dosyası hedefte (`UserDefaults` → sebep kodu `CA92.1`).
      Yol haritası #5. Bu olmadan yükleme reddediliyor.
- [ ] **Ürün kimlikleri ASC'de tanımlı** — koddaki `MihrabProduct` ile **birebir**:
      - `com.caferkarakaya.mihrab.plus.monthly` — Otomatik yenilenen, 1 ay
      - `com.caferkarakaya.mihrab.plus.yearly` — Otomatik yenilenen, 1 yıl
      - `com.caferkarakaya.mihrab.plus.lifetime` — Non-consumable
      - Abonelik grubu adı: **Revak Plus** (aylık + yıllık aynı grupta ki yükseltme/düşürme çalışsın)
- [ ] **Aylık ve yıllığa 1 hafta ücretsiz giriş teklifi** (yalnızca yeni aboneler).
      Kod mağazada gerçek bir giriş teklifi görürse Apple akışını kullanır; görmezse kartsız yerel
      denemeye düşer. Teklif tanımlıysa dönüşüm belirgin biçimde daha iyi.
- [ ] **TR fiyatları elle girildi** — otomatik USD→TRY dönüşümü Türkiye'yi 2–3 kat aşırı fiyatlıyor.
      Hedef: aylık ₺129,99 · yıllık ₺649,99 · ömür boyu ₺1.299,99.
- [ ] **Üç üründe de Aile Paylaşımı açık** (`familyShareable: true` koddaki niyetle uyumlu).
- [ ] **Ekran görüntüleri:** 6.9" ve 6.5" zorunlu boyutlar, **tr ve en ayrı ayrı**, 6 kare.
- [ ] **Yaş sınırı: 4+.** Uygulamada kullanıcı üretimi içerik, reklam, dış bağlantı akışı ya da
      hassas içerik yok. Yaş sınırı anketinde tüm kategoriler "Yok".
- [ ] **Kategori:** Birincil **Referans** (TR Referans kategorisinin ~%20'si artık İslami uygulama —
      rakiplerin bulunduğu yer burası). İkincil **Yaşam Tarzı**.
      *Alternatif değerlendirme:* Araçlar (Utilities) kategorisi bayram sonrası kurulum zirvesini
      yakalıyor, ama Referans'ta kategori sıralamasına girme şansı daha yüksek.

### 8.2 Şemadan önce dondurulacaklar

- [ ] **CloudKit şeması Production'a alındı ve donduruldu.** Yol haritası #18: şema yayına
      alındıktan sonra **yalnızca eklemeli** değiştirilebilir. Alan silmek/yeniden adlandırmak
      mümkün değil. Ramazan trafiği gelmeden önce şemanın doğru olduğundan emin ol.
- [ ] App Group kimliği ve `PremiumEntitlement` aynası uzantı hedeflerinde doğrulandı.

### 8.3 Yayın sonrası ilk hafta

- [ ] ASA marka savunması kampanyası **canlı** (rakipler "mihrab" terimine teklif verir).
- [ ] **Featuring Nomination gönderildi** — ASC → Featuring Nominations. Kriterler: görsel işçilik
      (en yüksek ağırlık), **yeni Apple çerçevelerinin benimsenmesi** (WidgetKit, Live Activities,
      Dynamic Island, App Intents, AlarmKit, Control Center), mevsimsel uyum, geliştirici hikâyesi.
      Revak'ın iOS 26 / Liquid Glass tabanlı olması burada bir **varlık**.
- [ ] **IAP promosyon kodları kullanma** — 26 Mart 2026'da sona erdiler. **Teklif kodlarına (offer
      codes)** geç; artık tüm IAP türlerini kapsıyorlar.
- [ ] TR fiyatları için **6 aylık gözden geçirme** takvime kondu (enflasyon ARPU'yu sessizce eritir).

---

## 9. Doğrulanamayanlar / dikkat

Dürüstlük kuralı gereği, bu dosyada **kesin** diye sunulmayan şeyler:

- **Anahtar kelime alanının bayt mı karakter mi saydığı** doğrulanmadı. Her iki varyant da yukarıda
  duruyor; ASC alanı metni kesiyorsa güvenli varyantı kullan.
- **Kandil tarihleri** hilal gözlemine göre ±1 gün kayabilir. In-App Event pencerelerini girmeden
  önce `IslamicCalendar` ile doğrula.
- **Arama hacmi rakamları** (~491K, ~74K, ~28K) üçüncü taraf ASO araçlarının tahminleridir,
  Apple'ın açıkladığı veriler değil. Sıralama önceliği için yeterli, bütçe modeli için değil.
- **Ramazan 2027 = 8 Şubat** astronomik hesaba göredir; Diyanet takvimi bunu teyit ediyor, ancak
  hilal gözlemi yapan ülkelerde ±1 gün kayabilir — kullanıcıya başlangıç günü seçtirilmesi
  gerektiği yol haritasında zaten not edilmiş.
