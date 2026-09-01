import Foundation

/// Bahasa Indonesia — interface copy, keyed by the English text.
/// Generated from the `L10n.string(en:tr:ar:)` call sites; see `L10nCatalog`
/// for why the table lives in source rather than in a bundled resource.
enum L10nTableID {
    static let raw = """
Adhan & sounds	Azan & suara
Sound per prayer	Suara per waktu sholat
Sound library	Pustaka suara
Reminders	Pengingat
Extra reminders	Pengingat tambahan
Quiet hours	Jam tenang
How Revak reminds you	Cara Revak mengingatkanmu
Alarm (full adhan)	Alarm (azan penuh)
Notification	Notifikasi
Alarms play the full adhan and break through Silent mode and Focus. Notifications are quieter and are capped at 30 seconds of sound by iOS.	Alarm memutar azan sepenuhnya dan menembus mode Senyap serta Fokus. Notifikasi lebih lirih dan dibatasi 30 detik oleh iOS.
Allow alarms so the adhan can sound at prayer time.	Izinkan alarm agar azan dapat berkumandang tepat pada waktunya.
Alarm permission is off, so Revak falls back to notifications. You can turn alarms on in Settings ▸ Revak.	Izin alarm nonaktif, jadi Revak kembali memakai notifikasi. Kamu bisa menyalakan alarm di Pengaturan ▸ Revak.
iOS will not accept any more alarms. Revak kept the nearest prayers as alarms; the rest arrive as notifications.	iOS tidak menerima alarm lagi. Revak menyimpan waktu sholat terdekat sebagai alarm; sisanya datang sebagai notifikasi.
Alarms are unavailable on this device; Revak uses notifications instead.	Alarm tidak tersedia di perangkat ini; Revak memakai notifikasi sebagai gantinya.
Allow alarms	Izinkan alarm
Open iOS Settings	Buka Pengaturan iOS
Dismiss	Tutup
Mark as prayed	Tandai sudah sholat
Notification permission	Izin notifikasi
Allowed	Diizinkan
Blocked	Diblokir
Not asked yet	Belum diminta
Allow notifications	Izinkan notifikasi
Heads-up before prayer	Pemberitahuan sebelum sholat
Off	Nonaktif
Jumu'ah reminder	Pengingat Jumat
Daily hadith	Hadis harian
Holy days & nights	Hari & malam mulia
Makruh-time warning	Peringatan waktu makruh
A quiet note shortly before sunrise, solar noon and sunset — the three windows in which voluntary prayer is discouraged.	Catatan singkat sesaat sebelum matahari terbit, tengah hari dan terbenam — tiga jendela waktu ketika sholat sunnah tidak dianjurkan.
sunrise	matahari terbit
solar noon	tengah hari
sunset	matahari terbenam
Silence extra reminders	Bisukan pengingat tambahan
From	Dari
To	Sampai
Quiet hours never silence the prayer call itself — only the extras above.	Jam tenang tidak pernah membisukan seruan azan itu sendiri — hanya pengingat tambahan di atas.
Silent (vibrate only)	Senyap (hanya getar)
System default	Bawaan sistem
Brass bell	Lonceng kuningan
Two-tone gong	Gong dua nada
Dawn chime	Denting fajar
Same sound for every prayer	Suara sama untuk semua waktu
Fajr traditionally carries its own call — give it a separate sound if you wish.	Subuh secara tradisi punya seruan tersendiri — beri suara terpisah bila kamu mau.
Preview volume	Volume pratinjau
Alarm loudness follows the system alarm volume; this slider only affects previews inside the app.	Kekuatan alarm mengikuti volume alarm sistem; penggeser ini hanya memengaruhi pratinjau di dalam aplikasi.
Preview	Pratinjau
Stop preview	Hentikan pratinjau
Import a sound from Files…	Impor suara dari Files…
Bring your own licensed adhan recording. Alarms play it in full; notifications are trimmed to 30 seconds by iOS.	Bawa rekaman azan berlisensimu sendiri. Alarm memutarnya penuh; notifikasi dipangkas 30 detik oleh iOS.
That file could not be read as audio. Use CAF, WAV, AIFF, M4A or MP3.	Berkas itu tidak bisa dibaca sebagai audio. Gunakan CAF, WAV, AIFF, M4A atau MP3.
The sound could not be saved. Check available storage and try again.	Suara tidak dapat disimpan. Periksa ruang penyimpanan lalu coba lagi.
The file contains no audio.	Berkas itu tidak memuat audio.
Remove	Hapus
No adhan recordings are bundled with this build. Import your own, or pick one of the built-in tones.	Build ini tidak menyertakan rekaman azan. Impor milikmu sendiri, atau pilih salah satu nada bawaan.
Before dawn	Sebelum fajar
First light	Cahaya pertama
Morning	Pagi
Midday	Tengah hari
Afternoon	Sore
Dusk	Senja
Evening	Malam
Night	Larut malam
Background	Latar
Texture	Tekstur
Colour & theme	Warna & tema
Motion & depth	Gerak & kedalaman
Calm	Tenang
Balanced	Seimbang
Vivid	Hidup
Calm keeps every screen quiet behind the text. Vivid lets the backdrop breathe more. The counter screen always keeps its full texture.	Tenang membuat setiap layar diam di belakang teks. Hidup memberi latar lebih banyak ruang bernapas. Layar penghitung selalu mempertahankan teksturnya penuh.
Textured cards	Kartu bertekstur
Adds a slow, low-contrast pattern inside cards. Text contrast is preserved either way.	Menambahkan pola lambat berkontras rendah di dalam kartu. Kontras teks tetap terjaga.
Counter backdrop	Latar penghitung
The full-screen texture behind the tasbih counter — the one place Revak lets the shader take over.	Tekstur layar penuh di belakang penghitung tasbih — satu-satunya tempat Revak membiarkan shader mengambil alih.
Lantern Glow	Cahaya Lentera
Still Water	Air Tenang
Kufic Lattice	Kisi Kufi
Live preview	Pratinjau langsung
Today	Hari ini
Times	Waktu
Qibla	Kiblat
Esmaül Hüsna	Asmaul Husna
Zikirmatik	Dzikir
Good morning	Selamat pagi
Good afternoon	Selamat siang
Good evening	Selamat malam
Good night	Selamat beristirahat
Fajr	Subuh
Sunrise	Terbit
Dhuhr	Zuhur
Asr	Asar
Maghrib	Magrib
Isha	Isya
Fajr in	Subuh dalam
Sunrise in	Terbit dalam
Dhuhr in	Zuhur dalam
Asr in	Asar dalam
Maghrib in	Magrib dalam
Isha in	Isya dalam
Sun	Matahari
NOW	SEKARANG
Prayer Times	Jadwal Sholat
Month	Bulan
Day	Hari
Locating…	Mencari lokasi…
Loading prayer times	Memuat jadwal sholat
Fetching today’s schedule for your city.	Mengambil jadwal hari ini untuk kotamu.
Location needed	Lokasi diperlukan
Allow location so Revak can load prayer times.	Izinkan lokasi agar Revak dapat memuat jadwal sholat.
Times unavailable	Jadwal tidak tersedia
Check your connection and try again.	Periksa koneksimu lalu coba lagi.
Try Again	Coba Lagi
Enable Location	Aktifkan Lokasi
Previous day	Hari sebelumnya
Next day	Hari berikutnya
Times unavailable — check connection	Jadwal tidak tersedia — periksa koneksi
SUN PATH	LINTASAN MATAHARI
Alerts on	Pengingat aktif
Alerts off	Pengingat mati
Toggles prayer alerts	Mengalihkan pengingat sholat
Diyanet (Türkiye)	Diyanet (Turki)
Muslim World League	Liga Muslim Dunia
Egyptian Authority	Otoritas Mesir
Univ. of Karachi	Univ. Karachi
Shafi'i	Syafi'i
Madhab	Mazhab
DAILY HADITH	HADIS HARIAN
Mosques	Masjid
Qibla AR	Kiblat AR
DHIKR	DZIKIR
left	tersisa
h	j
Prayer, beautifully present.	Sholat, hadir dengan indah.
Begin	Mulai
For precise prayer times	Untuk waktu sholat yang tepat
Revak uses your location only on-device to calculate prayer times, Qibla direction, and nearby mosques.	Revak memakai lokasimu hanya di perangkat untuk menghitung waktu sholat, arah kiblat dan masjid terdekat.
Calculation method	Metode perhitungan
Continue	Lanjut
Skip	Lewati
Never miss a prayer	Jangan sampai terlewat satu sholat
Enable Notifications	Aktifkan Notifikasi
Always with you	Selalu bersamamu
Add the Revak widget to your Home Screen, Lock Screen, and Dynamic Island. You can set it up later in Settings.	Tambahkan widget Revak ke Layar Utama, Lock Screen dan Dynamic Island. Kamu bisa mengaturnya nanti di Pengaturan.
Enter Revak	Masuk ke Revak
this session	sesi ini
Set complete	Set selesai
Swipe to change phrase	Geser untuk mengganti kalimat
Dhikr Stats	Statistik Dzikir
Keep screen awake	Jaga layar tetap menyala
Week	Pekan
All time	Sepanjang waktu
Streak	Rentetan
This week	Pekan ini
days	hari
Rewards	Penghargaan
Dhikr lexicon	Leksikon dzikir
Inscribed	Tercatat
First tap	Ketukan pertama
First thirty-three	Tiga puluh tiga pertama
First ninety-nine	Sembilan puluh sembilan pertama
First hundred	Seratus pertama
Five hundred in a day	Lima ratus dalam sehari
Seven days	Tujuh hari
After-prayer tesbih	Tasbih setelah sholat
A thousand	Seribu
Thirty days	Tiga puluh hari
Six phrases	Enam kalimat
Ten thousand	Sepuluh ribu
The five-hundred set	Set lima ratus
The opening bead.	Butir pembuka.
A complete tesbih.	Satu tasbih penuh.
The ninety-nine.	Sembilan puluh sembilan.
A round hundred.	Seratus bulat.
Abundance in one day.	Berlimpah dalam satu hari.
A week of return.	Sepekan kembali.
Thirty-three thrice.	Tiga puluh tiga, tiga kali.
A thousand recitations.	Seribu bacaan.
A month of return.	Sebulan kembali.
Each of the six.	Masing-masing dari keenam.
Great abundance.	Limpahan besar.
The long tesbih.	Tasbih panjang.
You began a dhikr on Zikirmatik.	Kamu memulai dzikir di Dzikir.
You reached thirty-three recitations.	Kamu mencapai tiga puluh tiga bacaan.
You reached ninety-nine recitations.	Kamu mencapai sembilan puluh sembilan bacaan.
You reached one hundred recitations.	Kamu mencapai seratus bacaan.
Five hundred in a single day.	Lima ratus dalam satu hari.
Dhikr on seven consecutive days.	Dzikir tujuh hari berturut-turut.
33 Subhanallah, 33 Alhamdulillah, 33 Allahu Akbar in one day.	33 Subhanallah, 33 Alhamdulillah, 33 Allahu Akbar dalam sehari.
One thousand recitations in all.	Seribu bacaan seluruhnya.
Dhikr on thirty consecutive days.	Dzikir tiga puluh hari berturut-turut.
You recited each of the six phrases.	Kamu membaca keenam kalimat itu.
Ten thousand recitations in all.	Sepuluh ribu bacaan seluruhnya.
You completed a set of five hundred.	Kamu menyelesaikan satu set lima ratus.
ESMAÜL HÜSNA	ASMAUL HUSNA
Search	Cari
Search a Name	Cari sebuah Nama
Clear	Bersihkan
99 NAMES	99 NAMA
No names match.	Tidak ada nama yang cocok.
Name of the day	Nama hari ini
Recite ×100	Baca ×100
Done	Selesai
RELIGIOUS DAYS	HARI BESAR
View in AR	Lihat di AR
Align with the Qibla	Sejajarkan dengan kiblat
Facing the Qibla	Menghadap kiblat
Locked on Qibla	Terkunci pada kiblat
Hold your iPhone flat for the compass.	Pegang iPhone-mu rata untuk kompas.
Camera is used only to show direction. Nothing is recorded or uploaded.	Kamera hanya dipakai untuk menunjukkan arah. Tidak ada yang direkam atau diunggah.
AR needs camera access	AR butuh akses kamera
Enable the camera in Settings, or use the compass instead.	Aktifkan kamera di Pengaturan, atau pakai kompas saja.
Open Settings	Buka Pengaturan
Back to Compass	Kembali ke Kompas
N	U
NE	TL
E	T
SE	TG
SW	BD
W	B
NW	BL
Settings	Pengaturan
No times this month	Tidak ada jadwal bulan ini
Prayer times could not be loaded for this month.	Jadwal sholat untuk bulan ini tidak dapat dimuat.
It's Friday — don't forget Surah al-Kahf and the Jumu'ah prayer.	Hari ini Jumat — jangan lupa surah al-Kahfi dan sholat Jumat.
Try another spelling, or search in Arabic.	Coba ejaan lain, atau cari dalam bahasa Arab.
No upcoming days yet	Belum ada hari yang mendekat
Holy days appear once prayer times load.	Hari besar muncul setelah jadwal sholat termuat.
Daily Hadith	Hadis Harian
Prayer	Sholat
Location	Lokasi
Current	Saat ini
Use precise location	Pakai lokasi presisi
Clear manual override	Hapus penggantian manual
Appearance	Tampilan
Theme	Tema
Auto	Otomatis
Dark	Gelap
Light	Terang
Ramadan theme	Tema Ramadan
None	Tidak ada
Emerald Silk	Sutra Zamrud
Mosque Light	Cahaya Masjid
Aurora Veil	Selubung Aurora
Use on all screens	Pakai di semua layar
Accent	Aksen
Emerald	Zamrud
Brass	Kuningan
Violet	Ungu
About	Tentang
Version	Versi
Prayer times: Aladhan API · Hadith: bundled curated collection · No ads, no tracking, ever.	Waktu sholat: Aladhan API · Hadis: koleksi terkurasi bawaan · Tanpa iklan, tanpa pelacakan, selamanya.
Reset onboarding	Setel ulang pengenalan
Madhab (Asr)	Mazhab (Asar)
IFTAR IN	BERBUKA DALAM
SUHOOR ENDS IN	SAHUR BERAKHIR DALAM
SUHOOR ENDS	SAHUR BERAKHIR
IFTAR	BERBUKA
FASTING	PUASA
DAILY DUAS	DOA HARIAN
Iftar Dua	Doa Berbuka
Suhoor Intention	Niat Sahur
KHATAM TRACKER	PELACAK KHATAM
Log a juz	Catat satu juz
Eid al-Fitr in 1 day	Idul Fitri 1 hari lagi
May Allah accept your fast	Semoga Allah menerima puasamu
The month of mercy	Bulan penuh rahmat
Every moment is worship	Setiap saat adalah ibadah
Patience is half of faith	Sabar adalah separuh iman
Calendar source	Sumber kalender
Turkish calendars disagree about when true dawn begins, so imsak differs between them. Only calendars whose publisher states its own angles and temkin are offered here. Standard uses the calculation method you picked, untouched.	Kalender Turki berbeda pendapat tentang kapan fajar sebenarnya dimulai, sehingga imsak berbeda antar kalender. Hanya kalender yang penerbitnya menyatakan sudut dan temkin-nya sendiri yang ditawarkan di sini. Standar memakai metode perhitungan yang kamu pilih, tanpa diubah.
Standard (your method)	Standar (metodemu)
Fajr 18°, isha 17°, plus Diyanet's temkin: sunrise −7, dhuhr +5, asr +4, maghrib +7 minutes.	Subuh 18°, isya 17°, ditambah temkin Diyanet: terbit −7, zuhur +5, asar +4, magrib +7 menit.
Imsak 19°, isha 17°, with 10 minutes of temkin on every time — taken off imsak and sunrise, added to dhuhr, asr, maghrib and isha. Imsak lands noticeably earlier than Diyanet's.	Imsak 19°, isya 17°, dengan temkin 10 menit pada setiap waktu — dikurangi dari imsak dan terbit, ditambahkan ke zuhur, asar, magrib dan isya. Imsak jatuh jelas lebih awal daripada Diyanet.
This calendar is no longer offered: its publisher does not document the angles and margins it uses, so we could not show its times honestly. Diyanet's published times are used instead.	Kalender ini tidak lagi ditawarkan: penerbitnya tidak mendokumentasikan sudut dan margin yang dipakai, jadi kami tidak dapat menampilkan waktunya secara jujur. Waktu terbitan Diyanet dipakai sebagai gantinya.
No regional correction. Times follow the calculation method you picked, exactly as its authority publishes it.	Tanpa koreksi wilayah. Waktu mengikuti metode perhitungan yang kamu pilih, persis seperti yang diterbitkan otoritasnya.
These calendars describe practice in Türkiye. Outside Türkiye, Standard is usually the honest choice.	Kalender-kalender ini menggambarkan praktik di Turki. Di luar Turki, Standar biasanya pilihan yang jujur.
Source: Türkiye Takvimi (Hakîkat Kitabevi)	Sumber: Türkiye Takvimi (Hakîkat Kitabevi)
Source: Presidency of Religious Affairs (Diyanet İşleri Başkanlığı)	Sumber: Presidensi Urusan Agama Turki (Diyanet İşleri Başkanlığı)
Fine-tune each time	Setel halus setiap waktu
Shift an individual time by up to ±30 minutes to match the calendar your mosque follows. Corrections apply everywhere: schedule, widgets and notifications.	Geser satu waktu hingga ±30 menit agar cocok dengan kalender yang diikuti masjidmu. Koreksi berlaku di mana-mana: jadwal, widget dan notifikasi.
Reset all corrections	Setel ulang semua koreksi
On time	Tepat waktu
Calculated on device	Dihitung di perangkat
No connection right now, so these times come from the built-in astronomical engine. They refresh from the online calendar as soon as you are back online.	Tidak ada koneksi saat ini, jadi waktu-waktu ini berasal dari mesin astronomi bawaan. Semuanya disegarkan dari kalender online begitu kamu kembali daring.
At this latitude the sun does not rise or set today, so a normal schedule cannot be calculated. Scholars advise following the timings of the nearest moderate latitude — pick a city manually in Settings.	Pada lintang ini matahari tidak terbit atau terbenam hari ini, sehingga jadwal normal tidak dapat dihitung. Para ulama menganjurkan mengikuti waktu lintang moderat terdekat — pilih kota secara manual di Pengaturan.
calculated on device	dihitung di perangkat
from the online calendar	dari kalender online
from saved times	dari waktu tersimpan
Where this time comes from	Dari mana waktu ini berasal
one seventh of the night	sepertujuh malam
twilight angle	sudut senja
middle of the night	tengah malam
Religious Calendar	Kalender Keagamaan
Holy nights, the three months and voluntary fasts	Malam mulia, tiga bulan haram dan puasa sunnah
UPCOMING	MENDEKAT
THIS HIJRI YEAR	TAHUN HIJRIAH INI
VOLUNTARY FASTS	PUASA SUNNAH
Tonight	Malam ini
Tomorrow	Besok
The three months	Tiga bulan
Previous year	Tahun sebelumnya
Next year	Tahun berikutnya
Full calendar	Kalender lengkap
Nothing in the next few weeks	Tidak ada apa pun dalam beberapa pekan ke depan
The next entries will appear here as they approach.	Entri berikutnya akan muncul di sini saat waktunya mendekat.
Dates are computed with the Umm al-Qura calendar. The Diyanet calendar used in Türkiye is calculated separately and may differ by ±1 day — take the printed Diyanet calendar as the authority.	Tanggal dihitung dengan kalender Umm al-Qura. Kalender Diyanet yang dipakai di Turki dihitung terpisah dan bisa berbeda ±1 hari — jadikan kalender cetak Diyanet sebagai acuan.
An Islamic day begins at maghrib. A holy night therefore starts on the evening of the previous day.	Hari Islam dimulai saat magrib. Karena itu malam mulia dimulai pada petang hari sebelumnya.
Begins at maghrib the evening before	Dimulai saat magrib petang sebelumnya
1 day	1 hari
Fasting is not kept on this day	Puasa tidak dikerjakan pada hari ini
Voluntary fasts are recommendations, not obligations. Ramadan is excluded here because it is obligatory.	Puasa sunnah adalah anjuran, bukan kewajiban. Ramadan tidak dimasukkan di sini karena hukumnya wajib.
Hijri New Year	Tahun Baru Hijriah
Day of Ashura	Hari Asyura
Mawlid	Maulid
Rajab begins — the three months	Rajab dimulai — tiga bulan haram
Sha'ban begins	Syakban dimulai
Bara'ah	Nisfu Syakban
Ramadan begins	Ramadan dimulai
Laylat al-Qadr	Lailatulqadar
Eve of Eid al-Fitr	Malam Takbiran Idul Fitri
Eid al-Fitr	Idul Fitri
Day of Arafah	Hari Arafah
Eid al-Adha	Idul Adha
The first day of Muharram opens the Hijri year, counted from the Hijra to Medina.	Hari pertama Muharram membuka tahun Hijriah, dihitung sejak hijrah ke Madinah.
The tenth of Muharram. In Türkiye it is also marked by cooking and sharing aşure.	Sepuluh Muharram. Di Turki hari ini juga ditandai dengan memasak dan membagikan aşure.
Marks the birth of the Prophet Muhammad, observed on 12 Rabi' al-Awwal.	Menandai kelahiran Nabi Muhammad, diperingati pada 12 Rabiul Awal.
Rajab opens the three months — Rajab, Sha'ban, Ramadan — a period of increased worship in Turkish practice.	Rajab membuka tiga bulan haram — Rajab, Syakban, Ramadan — masa peningkatan ibadah dalam tradisi Turki.
Observed on the first Friday night of Rajab — a weekday rule, so its date moves every year.	Diperingati pada malam Jumat pertama bulan Rajab — aturannya berbasis hari, jadi tanggalnya bergeser setiap tahun.
Commemorates the night journey and ascension, observed on 27 Rajab.	Memperingati perjalanan malam dan mikraj, diperingati pada 27 Rajab.
The second of the three months.	Bulan kedua dari tiga bulan haram.
Observed on the night of 15 Sha'ban.	Diperingati pada malam 15 Syakban.
The month of fasting begins. Its first taraweeh is prayed the night before the first fast.	Bulan puasa dimulai. Tarawih pertamanya dikerjakan pada malam sebelum puasa pertama.
Sought in the last ten nights of Ramadan; in Türkiye it is observed on the night of 27 Ramadan.	Dicari pada sepuluh malam terakhir Ramadan; di Turki diperingati pada malam 27 Ramadan.
The last day of Ramadan. Fitre is given before the eid prayer.	Hari terakhir Ramadan. Fitrah diberikan sebelum sholat id.
Three days beginning 1 Shawwal. Fasting is not kept on the first day.	Tiga hari mulai 1 Syawal. Puasa tidak dikerjakan pada hari pertama.
9 Dhul-Hijjah, when pilgrims stand at Arafat.	9 Zulhijah, saat jemaah haji wukuf di Arafah.
Four days beginning 10 Dhul-Hijjah. Fasting is not kept on any of them.	Empat hari mulai 10 Zulhijah. Puasa tidak dikerjakan pada satu pun di antaranya.
Night of 12 Rabi' al-Awwal	Malam 12 Rabiul Awal
First Friday night of Rajab	Malam Jumat pertama Rajab
Night of 27 Rajab	Malam 27 Rajab
1 Sha'ban	1 Syakban
Night of 15 Sha'ban	Malam 15 Syakban
Night of 27 Ramadan	Malam 27 Ramadan
Last day of Ramadan	Hari terakhir Ramadan
1–3 Shawwal	1–3 Syawal
9 Dhul-Hijjah	9 Zulhijah
10–13 Dhul-Hijjah	10–13 Zulhijah
Monday & Thursday	Senin & Kamis
White days	Ayyamul bidh
Tasu'a & Ashura	Tasu'a & Asyura
First ten of Dhul-Hijjah	Sepuluh hari pertama Zulhijah
Six days of Shawwal	Enam hari Syawal
Kept weekly on Mondays and Thursdays.	Dikerjakan tiap pekan pada Senin dan Kamis.
The 13th, 14th and 15th of each Hijri month, when the moon is full.	Tanggal 13, 14 dan 15 setiap bulan Hijriah, saat bulan sedang penuh.
9 and 10 Muharram, kept together.	9 dan 10 Muharram, dikerjakan berpasangan.
The first nine days of Dhul-Hijjah. The tenth is the bayram, when fasting is not kept.	Sembilan hari pertama Zulhijah. Hari kesepuluh adalah hari raya, saat puasa tidak dikerjakan.
9 Dhul-Hijjah, the day before Eid al-Adha.	9 Zulhijah, sehari sebelum Idul Adha.
Any six days of Shawwal after the bayram; the days shown here are simply the first run.	Enam hari mana pun di bulan Syawal setelah hari raya; hari-hari yang ditampilkan di sini hanyalah rangkaian pertama.
Cities	Kota
Your cities	Kotamu
Add a city	Tambah kota
Current location	Lokasi saat ini
Not set	Belum disetel
No cities yet. Search below to add one.	Belum ada kota. Cari di bawah untuk menambahkan.
Edit	Ubah
City name	Nama kota
Search online	Cari daring
Type at least two letters to search.	Ketik minimal dua huruf untuk mencari.
Use this city for prayer times.	Pakai kota ini untuk waktu sholat.
Add to your cities.	Tambahkan ke kotamu.
Manage the cities you follow.	Kelola kota yang kamu ikuti.
Follow as many cities as you like with Revak Plus — family abroad, a trip next week, the mosque you grew up near.	Ikuti sebanyak apa pun kota dengan Revak Plus — keluarga di luar negeri, perjalanan pekan depan, masjid tempat kamu tumbuh.
Sync with iCloud	Sinkronkan dengan iCloud
Syncing	Menyinkronkan
Checking…	Memeriksa…
Paused — Plus ended	Dijeda — Plus berakhir
No iCloud account	Tidak ada akun iCloud
Restricted on this device	Dibatasi di perangkat ini
iCloud status unavailable	Status iCloud tidak tersedia
iCloud temporarily unavailable	iCloud sementara tidak tersedia
Last synced	Terakhir disinkronkan
Sync now	Sinkronkan sekarang
Reopen Revak to finish switching iCloud sync.	Buka kembali Revak untuk menyelesaikan pergantian sinkronisasi iCloud.
Dhikr sessions, saved hadith, khatam progress, prayer and fasting marks are kept in your private iCloud database. Nobody else can read them — not even us.	Sesi dzikir, hadis tersimpan, progres khatam, catatan sholat dan puasa disimpan di basis data iCloud pribadimu. Tidak ada orang lain yang bisa membacanya — kami pun tidak.
Sign in to iCloud in Settings to turn this on. Your data stays on this device until you do.	Masuk ke iCloud di Pengaturan untuk menyalakan ini. Datamu tetap di perangkat ini sampai kamu melakukannya.
Syncing is paused because Revak Plus ended. Nothing was deleted — your data is still here and in iCloud, and syncing resumes if you subscribe again.	Sinkronisasi dijeda karena Revak Plus berakhir. Tidak ada yang dihapus — datamu masih di sini dan di iCloud, dan sinkronisasi berlanjut jika kamu berlangganan lagi.
Tap to contemplate	Ketuk untuk merenung
Your journey	Perjalananmu
Collections	Koleksi
Dhikr suggestion	Saran dzikir
Open the counter	Buka penghitung
View	Tampilan
List	Daftar
Grid	Kisi
All	Semua
Favorites	Favorit
No favorites yet.	Belum ada favorit.
Tap the star on any Name to keep it close.	Ketuk bintang pada Nama mana pun agar tetap dekat.
Meaning	Makna
Pronunciation	Pelafalan
In Turkish	Dalam bahasa Turki
Reflection	Renungan
Swipe for the next Name	Geser untuk Nama berikutnya
Add to favorites	Tambahkan ke favorit
Favorite	Favorit
Remove from favorites	Hapus dari favorit
A Name of God	Salah satu Nama Allah
Share	Bagikan
Mercy & Forgiveness	Rahmat & Ampunan
The Names one whispers when hope runs thin.	Nama-nama yang dibisikkan ketika harapan menipis.
Power & Majesty	Kuasa & Keagungan
Names that place the heart in its true size.	Nama-nama yang menempatkan hati pada ukuran sejatinya.
Knowledge & Wisdom	Ilmu & Hikmah
Nothing is unseen, nothing unheard.	Tidak ada yang tak terlihat, tidak ada yang tak terdengar.
Provision & Generosity	Rezeki & Kedermawanan
Doors open where none were drawn.	Pintu terbuka di tempat yang tak pernah digambar.
Justice & Balance	Keadilan & Keseimbangan
Every weight is measured exactly.	Setiap timbangan diukur dengan tepat.
Creation & Refuge	Penciptaan & Perlindungan
The One who begins, keeps and returns.	Dia yang memulai, memelihara dan mengembalikan.
The ninety-nine	Sembilan puluh sembilan
Read & reflect	Baca & renungkan
Worship tools	Perangkat ibadah
Counter	Penghitung
Counting mode	Mode hitung
Switch to tasbih	Beralih ke tasbih
Switch to counter	Beralih ke penghitung
More	Lainnya
Drag the beads — flick to run several	Tarik butirannya — sentil untuk menjalankan beberapa
Ebony	Kayu hitam
Olive wood	Kayu zaitun
Bead material	Bahan butiran
Change bead material	Ganti bahan butiran
Double-tap the strand to change the beads	Ketuk dua kali pada tali untuk mengganti butiran
Bead click	Klik butiran
A short synthesised click as each bead passes. Follows the silent switch.	Klik sintetis singkat setiap kali sebuah butiran lewat. Mengikuti sakelar senyap.
Tap anywhere to count	Ketuk di mana saja untuk menghitung
Hold to reset	Tahan untuk menyetel ulang
Counter reset	Penghitung disetel ulang
Focus mode	Mode fokus
Leave focus mode	Keluar dari mode fokus
Tap the background or swipe down to leave	Ketuk latar atau geser ke bawah untuk keluar
Hides everything but the dial	Menyembunyikan segalanya kecuali dial
Dim screen in focus mode	Redupkan layar dalam mode fokus
Brightness is restored when you leave focus mode or the app.	Kecerahan dipulihkan saat kamu keluar dari mode fokus atau dari aplikasi.
Dhikr library	Pustaka dzikir
Phrases	Kalimat
Routines	Rutin
My dhikr	Dzikirku
Names of Allah	Nama-nama Allah
New dhikr	Dzikir baru
Name	Nama
Arabic (optional)	Arab (opsional)
Save	Simpan
Cancel	Batal
Delete	Hapus
No dhikr of your own yet	Belum ada dzikir milikmu sendiri
Create a phrase with your own wording and target count.	Buat kalimat dengan susunan kata dan jumlah targetmu sendiri.
Free count	Hitungan bebas
Start routine	Mulai rutin
End routine	Akhiri rutin
Routine complete	Rutin selesai
Next	Berikutnya
After-prayer tasbihat	Tasbihat setelah sholat
Morning remembrance	Zikir pagi
Evening remembrance	Zikir petang
Seeking forgiveness	Memohon ampunan
Blessings on the Prophet	Salawat untuk Nabi
33 · 33 · 33 and tawhid	33 · 33 · 33 dan tauhid
Recited after Fajr	Dibaca setelah Subuh
Recited after Maghrib	Dibaca setelah Magrib
One hundred, unhurried	Seratus, tanpa tergesa
One hundred blessings	Seratus salawat
Kalima Tawhid	Kalimat Tauhid
Ya Shafi	Ya Syafi
Glory be to Allah	Mahasuci Allah
All praise is for Allah	Segala puji bagi Allah
Allah is the Greatest	Allah Mahabesar
There is no god but Allah	Tiada tuhan selain Allah
Blessings upon the Prophet ﷺ	Salawat untuk Nabi ﷺ
I seek Allah's forgiveness	Aku memohon ampunan Allah
Allah is sufficient for us	Cukuplah Allah bagi kami
No power except with Allah	Tiada kekuatan kecuali dengan Allah
Glory and praise be to Allah	Mahasuci Allah dan segala puji bagi-Nya
The Most Compassionate	Yang Maha Pengasih
The Most Merciful	Yang Maha Penyayang
The Subtle, the Gentle	Yang Mahalembut
The Opener of ways	Yang Membuka jalan
The Healer	Yang Menyembuhkan
The Preserver	Yang Memelihara
The Loving	Yang Mahamengasihi
The Provider	Yang Memberi rezeki
The Patient	Yang Mahasabar
Today's goal	Target hari ini
Daily goal reached	Target harian tercapai
Best day	Hari terbaik
Daily average	Rata-rata harian
History	Riwayat
Last 30 days	30 hari terakhir
By phrase	Per kalimat
Nothing counted yet	Belum ada yang dihitung
Your counts will appear here once you begin.	Hitunganmu akan muncul di sini setelah kamu mulai.
Dhikr	Dzikir
Tap sound	Suara ketukan
Vibration	Getaran
Keep screen awake while counting	Jaga layar menyala saat menghitung
Open in Tasbih mode	Buka dalam mode Tasbih
Daily goal	Target harian
Full history is a Plus feature	Riwayat penuh adalah fitur Plus
Custom dhikr is a Plus feature	Dzikir kustom adalah fitur Plus
Unlock	Buka kunci
Hatim	Khatam
Finish the Qur'an at your own pace	Selesaikan Al-Quran dengan iramamu sendiri
Free, like the reader	Gratis, seperti pembacanya
No hatim yet	Belum ada khatam
Set a date you'd like to finish by and Revak works out the daily share. Change it whenever you like — the plan follows you, not the other way round.	Tetapkan tanggal yang kamu inginkan untuk selesai dan Revak menghitung bagian hariannya. Ubah kapan saja — rencananya mengikutimu, bukan sebaliknya.
New hatim	Khatam baru
On my own	Sendiri
Shared hatim	Khatam bersama
Finish by	Selesai pada
Start	Mulai
My hatim	Khatamku
End of Ramadan	Akhir Ramadan
In 30 days	Dalam 30 hari
In a year	Dalam setahun
The date has passed — pick a new one whenever you're ready.	Tanggalnya sudah lewat — pilih yang baru kapan pun kamu siap.
Today's share	Bagian hari ini
Your pace	Iramamu
Read a little and an estimate appears here.	Baca sedikit dan perkiraan akan muncul di sini.
On track	Sesuai rencana
A little behind	Sedikit tertinggal
Hatim complete	Khatam selesai
Continue reading	Lanjut membaca
Mark juz as read	Tandai juz sudah dibaca
Start over	Mulai dari awal
Progress on this hatim goes back to zero. Nothing else is affected.	Progres khatam ini kembali ke nol. Tidak ada hal lain yang terpengaruh.
Delete hatim	Hapus khatam
Organise a shared hatim	Atur khatam bersama
Join with a code	Gabung dengan kode
Split into	Bagi menjadi
My share	Bagianku
Pick the juz you'll read	Pilih juz yang akan kamu baca
Send the invite	Kirim undangan
Paste the code or link	Tempel kode atau tautan
That code could not be read. Ask for it again — codes are long and get cut off in messages.	Kode itu tidak bisa dibaca. Minta lagi — kode itu panjang dan sering terpotong di pesan.
Join	Gabung
How the shared hatim works	Cara kerja khatam bersama
Revak has no servers and collects nothing, so a shared hatim lives in the invite itself. Everyone tracks their own juz on their own phone. That means the app cannot show you who has claimed which juz or how far anyone else has read — agree that between yourselves, the way a hatim has always been arranged.	Revak tidak punya server dan tidak mengumpulkan apa pun, jadi khatam bersama hidup di dalam undangannya sendiri. Setiap orang melacak juznya di ponselnya masing-masing. Artinya aplikasi tidak bisa menunjukkan siapa mengambil juz mana atau sudah sejauh mana orang lain membaca — sepakati itu di antara kalian, sebagaimana khatam selalu diatur.
Claimed on this iPhone	Diambil di iPhone ini
Back	Kembali
Step %d of %d	Langkah %d dari %d
Welcome to Revak	Selamat datang di Revak
Prayer times, qibla, dhikr and the names of Allah — in one calm, quiet place.	Waktu sholat, kiblat, dzikir dan nama-nama Allah — dalam satu tempat yang tenang.
Let's begin	Mari mulai
What should we call you?	Kami memanggilmu apa?
Only used to greet you inside the app. It never leaves your device.	Hanya dipakai untuk menyapamu di dalam aplikasi. Tidak pernah keluar dari perangkatmu.
Your name	Namamu
Not now	Nanti saja
Times that match your sky	Waktu yang cocok dengan langitmu
Prayer times and the qibla direction depend on exactly where you stand.	Waktu sholat dan arah kiblat bergantung pada tempatmu berdiri, persisnya.
Used only while the app is open	Dipakai hanya saat aplikasi terbuka
Never uploaded, never shared	Tidak pernah diunggah, tidak pernah dibagikan
You can pick a city by hand instead	Kamu bisa memilih kota secara manual
Allow location	Izinkan lokasi
Choose a city manually	Pilih kota secara manual
Location is off. Pick a city by hand, or enable it later in Settings.	Lokasi nonaktif. Pilih kota secara manual, atau aktifkan nanti di Pengaturan.
Select city	Pilih kota
Search for a city	Cari kota
No match yet — keep typing, then tap Search.	Belum ada yang cocok — teruskan mengetik, lalu ketuk Cari.
How should we calculate?	Bagaimana kami menghitung?
Different authorities use different sun angles. Pick the one your community follows.	Otoritas yang berbeda memakai sudut matahari yang berbeda. Pilih yang diikuti komunitasmu.
Recommended	Disarankan
The madhab changes only the Asr time — we'll ask about that next, with both real times.	Mazhab hanya mengubah waktu Asar — kami akan menanyakannya berikutnya, dengan kedua waktu sebenarnya.
A gentle call, on time	Seruan yang lembut, tepat waktu
Choose which prayers should reach you. You can change this any time.	Pilih sholat mana yang harus sampai kepadamu. Kamu bisa mengubahnya kapan saja.
Reminders are on	Pengingat aktif
Notifications are off. You can enable them later in iOS Settings.	Notifikasi nonaktif. Kamu bisa mengaktifkannya nanti di Pengaturan iOS.
Select all	Pilih semua
Three things to try first	Tiga hal untuk dicoba lebih dulu
Times & Live Activity	Waktu & Live Activity
The countdown to the next prayer lives on your Lock Screen and Dynamic Island.	Hitungan menuju sholat berikutnya hidup di Lock Screen dan Dynamic Island-mu.
Find the qibla	Temukan kiblat
A compass that locks on with a haptic pulse the moment you face the Kaaba.	Kompas yang terkunci dengan denyut haptik begitu kamu menghadap Kabah.
Dhikr counter	Penghitung dzikir
Tap anywhere to count. Haptics swell as you approach 33, 99 and beyond.	Ketuk di mana saja untuk menghitung. Haptik menguat saat kamu mendekati 33, 99 dan seterusnya.
Try everything free for 7 days — no charge until the trial ends.	Coba semuanya gratis 7 hari — tidak ada biaya sampai masa coba berakhir.
Every shader theme & widget	Semua tema shader & widget
Esmaül Hüsna collections & reflections	Koleksi & renungan Asmaul Husna
Dhikr statistics & achievements	Statistik & pencapaian dzikir
See plans	Lihat paket
Maybe later	Mungkin nanti
Got it	Paham
Skip tour	Lewati tur
Your day at a glance — next prayer, countdown and today's hadith.	Harimu dalam sekilas — sholat berikutnya, hitungan waktu dan hadis hari ini.
See every prayer of the day, plus the whole month.	Lihat setiap sholat hari ini, plus sebulan penuh.
Point your phone and let the compass lock onto the Kaaba.	Arahkan ponselmu dan biarkan kompas terkunci pada Kabah.
The 99 names, hadith and religious days — all in one place.	99 nama, hadis dan hari besar keagamaan — semua di satu tempat.
Count your dhikr with haptics, goals and streaks.	Hitung dzikirmu dengan haptik, target dan rentetan.
When does Asr begin for you?	Kapan Asar mulai bagimu?
Scholars differ on the shadow length that marks Asr. Both readings are valid — pick the one you follow.	Para ulama berbeda pendapat tentang panjang bayangan yang menandai Asar. Kedua bacaan itu sah — pilih yang kamu ikuti.
Match the Diyanet calendar	Cocokkan kalender Diyanet
Majority rule (shadow 1×)	Pendapat mayoritas (bayangan 1×)
Asr starts when a shadow equals the object's own length. This is the rule the Diyanet calendar is printed with.	Asar mulai saat bayangan sama dengan panjang bendanya sendiri. Inilah aturan yang dipakai dalam cetakan kalender Diyanet.
Asr starts when a shadow equals the object's own length — the Shafi, Maliki and Hanbali position.	Asar mulai saat bayangan sama dengan panjang bendanya sendiri — posisi Syafi'i, Maliki dan Hanbali.
Hanafi Asr (shadow 2×)	Asar Hanafi (bayangan 2×)
Asr starts when a shadow reaches twice the object's length, so it begins later.	Asar mulai saat bayangan mencapai dua kali panjang bendanya, jadi mulainya lebih lambat.
Today both land on the same minute here.	Hari ini keduanya jatuh pada menit yang sama di sini.
Times will appear here once your location is known.	Waktu akan muncul di sini setelah lokasimu diketahui.
You can change this any time in Settings › Prayer times.	Kamu bisa mengubah ini kapan saja di Pengaturan › Waktu sholat.
Asr today	Asar hari ini
And more inside	Dan lebih banyak lagi di dalam
Qada prayer tracking, a zakat calculator, several cities at once, and your choice of adhan voice.	Pelacakan sholat qadha, kalkulator zakat, beberapa kota sekaligus, dan pilihan suara azanmu.
A calmer, deeper Revak	Revak yang lebih tenang, lebih dalam
Prayer times, qibla and adhan alerts are free — and always will be. Plus adds the beauty around them.	Waktu sholat, kiblat dan pengingat azan gratis — dan akan selalu begitu. Plus menambahkan keindahan di sekitarnya.
Worship essentials stay free, forever.	Inti ibadah tetap gratis, selamanya.
Rich widgets & Live Activity	Widget kaya & Live Activity
Every size, every style, on your Lock Screen and Home Screen.	Setiap ukuran, setiap gaya, di Lock Screen dan Layar Utamamu.
Themes & backdrops	Tema & latar
Emerald, Ramadan and night palettes, with living shader backdrops.	Palet zamrud, Ramadan dan malam, dengan latar shader yang hidup.
Unlimited dhikr & full history	Dzikir tanpa batas & riwayat penuh
Your own targets, streaks and statistics kept for good.	Target, rentetan dan statistikmu sendiri disimpan selamanya.
Esmaül Hüsna collections	Koleksi Asmaul Husna
Curated sets, meanings and tafakkur readings for each name.	Set terkurasi, makna dan bacaan tafakur untuk setiap nama.
Ramadan planner & AR qibla	Perencana Ramadan & kiblat AR
Plan your month and find the qibla through the camera.	Rencanakan bulanmu dan temukan kiblat lewat kamera.
Yearly	Tahunan
Monthly	Bulanan
Lifetime	Seumur hidup
per year	per tahun
per month	per bulan
one-time	sekali bayar
Most popular	Paling populer
Pay once, keep Plus for as long as Revak lives.	Bayar sekali, Plus tetap milikmu selama Revak hidup.
Try 7 days free	Coba 7 hari gratis
Buy once	Beli sekali
We'll remind you two days before the free week ends.	Kami akan mengingatkanmu dua hari sebelum pekan gratis berakhir.
Restore purchases	Pulihkan pembelian
Privacy Policy	Kebijakan Privasi
Terms of Use	Ketentuan Penggunaan
Close	Tutup
Prices shown are indicative — the App Store will confirm the exact amount before you pay.	Harga yang ditampilkan bersifat indikatif — App Store akan memastikan jumlah tepatnya sebelum kamu membayar.
Processing…	Memproses…
Welcome to Plus	Selamat datang di Plus
May it be a means of good. Everything is unlocked.	Semoga menjadi jalan kebaikan. Semuanya terbuka.
No previous purchase was found on this Apple Account.	Tidak ditemukan pembelian sebelumnya pada Akun Apple ini.
The App Store isn't reachable right now. Please try again later.	App Store tidak dapat dijangkau saat ini. Silakan coba lagi nanti.
The purchase couldn't be verified.	Pembelian tidak dapat diverifikasi.
Purchase cancelled.	Pembelian dibatalkan.
No connection. Check your internet and try again.	Tidak ada koneksi. Periksa internetmu lalu coba lagi.
Something went wrong. Please try again.	Terjadi kesalahan. Silakan coba lagi.
Advanced widgets	Widget lanjutan
Themes	Tema
Adhan voices	Suara azan
Custom dhikr goals	Target dzikir kustom
Full dhikr history	Riwayat dzikir penuh
Esma collections	Koleksi Asmaul Husna
Tafakkur readings	Bacaan tafakur
Ramadan planner	Perencana Ramadan
AR qibla	Kiblat AR
Multiple cities	Banyak kota
iCloud backup	Pencadangan iCloud
Share cards	Kartu bagikan
Included with Revak Plus.	Termasuk dalam Revak Plus.
Free	Gratis
Plus member	Anggota Plus
Trial ended	Masa coba berakhir
See Revak Plus	Lihat Revak Plus
Start 7-day free trial	Mulai masa coba 7 hari gratis
Manage subscription	Kelola langganan
Thank you for supporting Revak.	Terima kasih telah mendukung Revak.
Plan	Paket
Two days of Plus left	Dua hari Plus tersisa
Your free week ends in two days. Nothing is charged unless you choose a plan.	Pekan gratismu berakhir dalam dua hari. Tidak ada biaya kecuali kamu memilih paket.
Your free week ends today	Pekan gratismu berakhir hari ini
Prayer times, qibla and adhan alerts continue free as always.	Waktu sholat, kiblat dan pengingat azan tetap gratis seperti selalu.
Multiple cities & iCloud	Banyak kota & iCloud
Follow as many cities as you like, and keep your dhikr, saved hadith and prayer marks in your private iCloud.	Ikuti sebanyak apa pun kota, dan simpan dzikir, hadis tersimpan dan catatan sholatmu di iCloud pribadimu.
Subscription details	Rincian langganan
1 year	1 tahun
1 month	1 bulan
one-time purchase	pembelian sekali bayar
What your subscription includes	Apa saja yang termasuk dalam langgananmu
Your free week has ended	Pekan gratismu telah berakhir
Nothing was deleted. Your dhikr, cities, saved hadith and prayer marks are all still here — the Plus surfaces are simply locked until you subscribe.	Tidak ada yang dihapus. Dzikir, kota, hadis tersimpan dan catatan sholatmu semuanya masih di sini — bagian Plus hanya terkunci sampai kamu berlangganan.
You already have Revak Plus.	Kamu sudah memiliki Revak Plus.
Billed once	Ditagih sekali
The heart of Revak stays free	Inti Revak tetap gratis
Prayer times, the qibla, adhan alerts, the dhikr counter, the 99 names and the Ramadan imsakiye are never locked — with no ads, on any tier.	Waktu sholat, kiblat, pengingat azan, penghitung dzikir, 99 nama dan imsakiyah Ramadan tidak pernah dikunci — tanpa iklan, di tingkat mana pun.
Make-up Prayers	Sholat Qadha
Qada	Qadha
Track what is left, one prayer at a time	Lacak yang tersisa, satu sholat setiap kali
Start whenever you're ready	Mulai kapan pun kamu siap
Set up an estimate of what you'd like to make up. You can change it at any time — nothing here is a judgement.	Susun perkiraan apa yang ingin kamu qadha. Kamu bisa mengubahnya kapan saja — tidak ada penghakiman di sini.
Set up	Susun
Estimate	Perkiraan
An estimate is enough. Scholars accept a careful estimate — you do not need an exact number to begin.	Perkiraan sudah cukup. Para ulama menerima perkiraan yang cermat — kamu tidak perlu angka pasti untuk mulai.
Until	Sampai
By number of years	Berdasarkan jumlah tahun
By dates	Berdasarkan tanggal
Of that time, roughly how much did you pray?	Dari waktu itu, kira-kira berapa banyak yang sudah kamu sholatkan?
Most people prayed some of the time. Moving this down keeps the estimate realistic.	Sebagian besar orang sholat pada sebagian waktu. Menurunkan ini menjaga perkiraan tetap realistis.
Also track witr	Lacak witir juga
In the Hanafi school witr is wajib and is made up alongside the five.	Dalam mazhab Hanafi witir itu wajib dan diqadha bersama yang lima.
Deduct monthly days	Kurangi hari bulanan
Prayers missed during menstruation are not made up. If this applies to you, we can subtract an average — you only give a number of days, nothing else is asked, stored or synced.	Sholat yang terlewat saat haid tidak diqadha. Jika ini berlaku untukmu, kami bisa mengurangi rata-ratanya — kamu hanya memberi jumlah hari, tidak ada lagi yang diminta, disimpan atau disinkronkan.
Average days per month	Rata-rata hari per bulan
BREAKDOWN	RINCIAN
Saving replaces your current counts. Your daily record is kept.	Menyimpan akan mengganti hitunganmu saat ini. Catatan harianmu tetap disimpan.
REMAINING	TERSISA
TODAY	HARI INI
None yet today	Belum ada hari ini
Witr	Witir
Add one	Tambah satu
Undo	Batalkan
Make up one prayer and we'll estimate a finish date.	Qadha satu sholat dan kami akan memperkirakan tanggal selesainya.
Edit counts	Ubah hitungan
Adjust any prayer directly if you remember more or fewer.	Sesuaikan sholat mana pun secara langsung jika kamu ingat lebih banyak atau lebih sedikit.
All made up	Semua telah diqadha
Every prayer you set out to make up is done. May it be accepted.	Setiap sholat yang kamu niatkan qadha sudah selesai. Semoga diterima.
Keep going at whatever pace suits you.	Teruslah dengan irama yang cocok untukmu.
MAKE-UP PRAYERS	SHOLAT QADHA
Opens the make-up prayer tracker	Membuka pelacak sholat qadha
Not set up	Belum disusun
Reset make-up tracking	Setel ulang pelacakan qadha
This deletes your counts and your daily record. It cannot be undone.	Ini menghapus hitungan dan catatan harianmu. Tidak dapat dibatalkan.
STATISTICS	STATISTIK
True north	Utara sejati
Magnetic north	Utara magnetik
No location fix yet, so this reading is measured from magnetic north. It can be several degrees off the real Qibla until location is available.	Belum ada penentuan lokasi, jadi bacaan ini diukur dari utara magnetik. Bisa menyimpang beberapa derajat dari kiblat sebenarnya sampai lokasi tersedia.
Reference	Acuan
This heading is measured from true north, the same north the Qibla bearing is drawn against.	Arah ini diukur dari utara sejati, utara yang sama dengan acuan penggambaran kiblat.
How do I check this?	Bagaimana aku memeriksanya?
Checking the Qibla	Memeriksa kiblat
Direction not reliable	Arah tidak dapat diandalkan
Your device cannot measure a trustworthy heading right now, so we are not going to pretend it can. Move away from metal, magnets, cases with magnets, cars and speakers, then calibrate below.	Perangkatmu tidak dapat mengukur arah yang dapat dipercaya saat ini, jadi kami tidak akan berpura-pura bisa. Jauhkan dari logam, magnet, casing bermagnet, mobil dan speaker, lalu kalibrasi di bawah.
Magnetic interference	Gangguan magnetik
Margin of error unknown	Margin galat tidak diketahui
Compass steady	Kompas stabil
Draw a figure eight	Gambar angka delapan
Hold the phone flat and sweep it through a slow figure eight two or three times. This re-teaches the magnetometer where north is.	Pegang ponsel rata dan sapukan dalam angka delapan yang lambat dua atau tiga kali. Ini mengajari ulang magnetometer di mana utara berada.
Compass recovered	Kompas pulih
Check with the sun	Periksa dengan matahari
Sensor-free check	Pemeriksaan tanpa sensor
No compass can be checked by another compass. The sun can. Face the sun, then turn by the amount below.	Tidak ada kompas yang bisa diperiksa oleh kompas lain. Matahari bisa. Hadapkan dirimu ke matahari, lalu berputar sebesar nilai di bawah.
The sun is on the Qibla right now	Matahari tepat di arah kiblat saat ini
A vertical object's shadow points the opposite way from the sun — sight along it if the sun is too bright to face.	Bayangan benda tegak menunjuk arah berlawanan dari matahari — bidik sepanjang bayangannya jika matahari terlalu terang untuk dihadapi.
The sun is below the horizon — no shadow to check against right now.	Matahari di bawah horizon — tidak ada bayangan untuk diperiksa saat ini.
The sun is too low for a readable shadow.	Matahari terlalu rendah untuk bayangan yang terbaca.
Sun over the Kaaba	Matahari di atas Kabah
Twice a year the sun passes directly over the Kaaba. At that moment every shadow on the sunlit half of the earth points away from the Qibla — the oldest and most reliable check there is, and it needs no device.	Dua kali setahun matahari melintas tepat di atas Kabah. Pada saat itu setiap bayangan di belahan bumi yang tersinari menunjuk menjauhi kiblat — pemeriksaan tertua dan paling dapat dipercaya yang ada, dan tidak memerlukan perangkat apa pun.
At that moment the sun is below your horizon, so the shadow check is not available where you are.	Pada saat itu matahari berada di bawah horizonmu, jadi pemeriksaan bayangan tidak tersedia di tempatmu.
How this check works	Cara kerja pemeriksaan ini
Qibla bearing is a great-circle direction to the Kaaba, drawn against true north. Solar positions are computed on this device.	Arah kiblat adalah arah lingkaran besar menuju Kabah, digambar terhadap utara sejati. Posisi matahari dihitung di perangkat ini.
Qur'an	Al-Quran
Read the full Arabic text, offline	Baca seluruh teks Arab, tanpa internet
Open	Buka
Always free	Selalu gratis
Suras	Surah
Bookmarks	Penanda
Meccan	Makkiyah
Medinan	Madaniyah
Search the Qur'an	Cari di Al-Quran
Search Arabic without diacritics, or jump to a reference like 2:255.	Cari bahasa Arab tanpa harakat, atau langsung ke rujukan seperti 2:255.
Nothing found	Tidak ditemukan
Try fewer letters, or drop the diacritics — the search ignores them.	Coba huruf lebih sedikit, atau buang harakatnya — pencarian mengabaikannya.
In the translation	Di terjemahan
Go to	Menuju
Where you left off	Tempat kamu berhenti
Start reading	Mulai membaca
Opening the mushaf…	Membuka mushaf…
The text could not be opened	Teks tidak dapat dibuka
The bundled Qur'an file is missing or unreadable. Reinstalling the app restores it — nothing you saved is lost.	Berkas Al-Quran bawaan hilang atau tidak terbaca. Memasang ulang aplikasi memulihkannya — tidak ada yang kamu simpan hilang.
Prostration	Sujud
Obligatory prostration	Sujud wajib
Recommended prostration	Sujud dianjurkan
Schools differ on which prostrations are obligatory. This label follows the classification published with the text.	Mazhab berbeda pendapat tentang sujud mana yang wajib. Label ini mengikuti klasifikasi yang diterbitkan bersama teksnya.
Previous sura	Surah sebelumnya
Next sura	Surah berikutnya
Copy	Salin
Copied	Tersalin
Share this ayah	Bagikan ayat ini
Bookmark	Tandai
Remove bookmark	Hapus penanda
Mark as where I stopped	Tandai sebagai tempat aku berhenti
No bookmarks yet	Belum ada penanda
Press and hold any ayah to bookmark it. Bookmarks are free and unlimited.	Tekan dan tahan ayat mana pun untuk menandainya. Penanda gratis dan tanpa batas.
Note (optional)	Catatan (opsional)
Display	Tampilan
Text size	Ukuran teks
Line spacing	Jarak baris
Reading mode	Mode baca
Paper	Kertas
Layout	Tata letak
Verse by verse	Ayat per ayat
Continuous	Menyambung
Typography	Tipografi
Classic	Klasik
Scholar	Ilmiah
Keep the screen on	Jaga layar tetap menyala
Translation	Terjemahan
Show translation	Tampilkan terjemahan
No translation is bundled	Tidak ada terjemahan bawaan
The Arabic text ships under a Creative Commons licence, so it is here in full. Every translation we reviewed is either copyrighted or licensed for non-commercial use only, and Revak will not ship text it has no right to — or invent one.	Teks Arab hadir di sini sepenuhnya karena berlisensi Creative Commons. Setiap terjemahan yang kami tinjau berhak cipta atau berlisensi hanya untuk penggunaan nonkomersial, dan Revak tidak akan menyertakan teks yang tidak berhak dipakainya — atau mengarangnya sendiri.
What we checked	Apa yang kami periksa
Text source	Sumber teks
About this text	Tentang teks ini
The Arabic text is the Tanzil Project's verified Uthmani edition, reproduced verbatim under a Creative Commons Attribution licence. Not one character has been altered.	Teks Arab adalah edisi Utsmani terverifikasi dari Tanzil Project, direproduksi kata per kata di bawah lisensi Creative Commons Attribution. Tidak satu karakter pun diubah.
Opens the reader. Reading, bookmarks and hatim tracking are free.	Membuka pembaca. Membaca, penanda dan pelacakan khatam gratis.
Search settings	Cari pengaturan
Prayer & times	Sholat & waktu
Method, madhab, source, offsets	Metode, mazhab, sumber, koreksi
Reminders & adhan	Pengingat & azan
Notifications, sounds, quiet hours	Notifikasi, suara, jam tenang
Location & cities	Lokasi & kota
Current place and saved cities	Tempat saat ini dan kota tersimpan
Qur'an, make-up prayers, zakat, calendar	Al-Quran, sholat qadha, zakat, kalender
Appearance & language	Tampilan & bahasa
Backdrop, colour, texture, language	Latar, warna, tekstur, bahasa
Account & sync	Akun & sinkronisasi
iCloud sync across your devices	Sinkronisasi iCloud di seluruh perangkatmu
App	Aplikasi
Guide, privacy, feedback, about	Panduan, privasi, umpan balik, tentang
No settings match	Tidak ada pengaturan yang cocok
Notifications	Notifikasi
Language	Bahasa
Help & tour	Bantuan & tur
Data & privacy	Data & privasi
Feedback	Umpan balik
Sources	Sumber
Prayer alerts	Pengingat sholat
Alerts are scheduled on this device only. Turn a prayer off to stay silent for that time.	Pengingat dijadwalkan di perangkat ini saja. Matikan satu sholat untuk tetap sunyi pada waktu itu.
Sound & banner style	Gaya suara & banner
The alert sound follows your iOS notification settings for Revak.	Suara pengingat mengikuti pengaturan notifikasi iOS-mu untuk Revak.
Your location never leaves the device except to fetch prayer times.	Lokasimu tidak pernah keluar dari perangkat kecuali untuk mengambil waktu sholat.
App language	Bahasa aplikasi
English	Bahasa Inggris
Revak follows your iPhone language. Change it in iOS Settings.	Revak mengikuti bahasa iPhone-mu. Ubah di Pengaturan iOS.
Replay the tour	Putar ulang tur
Show onboarding again	Tampilkan pengenalan lagi
Coach marks reappear the next time you open each tab.	Tanda panduan muncul lagi saat kamu membuka setiap tab berikutnya.
Everything stays on device	Semuanya tetap di perangkat
Counts, favourites and preferences are stored locally and synced only through your own iCloud.	Hitungan, favorit dan preferensi disimpan secara lokal dan hanya disinkronkan melalui iCloud milikmu sendiri.
Privacy	Privasi
Rate Revak	Beri nilai Revak
Send feedback	Kirim umpan balik
A short note helps more than a star. Both are welcome.	Catatan singkat lebih membantu daripada bintang. Keduanya kami terima dengan senang hati.
Sources & credits	Sumber & kredit
Prayer times	Waktu sholat
Times come from the Aladhan API, with the calculation method and madhab you choose above. Diyanet is the default in Türkiye.	Waktu berasal dari Aladhan API, dengan metode perhitungan dan mazhab yang kamu pilih di atas. Diyanet adalah bawaan di Turki.
Hadith & supplications	Hadis & doa
Texts are drawn from Sahih al-Bukhari, Sahih Muslim and Riyad as-Salihin, bundled with the app and shown with their source.	Teks diambil dari Sahih al-Bukhari, Sahih Muslim dan Riyad as-Salihin, disertakan dalam aplikasi dan ditampilkan bersama sumbernya.
The bearing is a great-circle calculation to the Kaaba (21.4225° N, 39.8262° E) using the device's true-north heading.	Arahnya adalah perhitungan lingkaran besar menuju Kabah (21,4225° LU, 39,8262° BT) memakai arah utara sejati dari perangkat.
Arabic is set in Amiri Quran (SIL Open Font License). Latin type is the system face.	Bahasa Arab diatur dengan Amiri Quran (SIL Open Font License). Huruf Latin adalah huruf sistem.
Qur'an text	Teks Al-Quran
Uthmani text from the Tanzil Project (tanzil.net), used under Creative Commons Attribution 3.0 and reproduced verbatim.	Teks Utsmani dari Tanzil Project (tanzil.net), dipakai di bawah Creative Commons Attribution 3.0 dan direproduksi kata per kata.
Open-source licences	Lisensi sumber terbuka
Prayer-time astronomy: adhan-swift by Batoul Apps, MIT licence, © 2016 Batoul Apps. Arabic typeface: Amiri by the Amiri Project Authors, SIL Open Font License 1.1. Both notices ship with the app.	Astronomi waktu sholat: adhan-swift oleh Batoul Apps, lisensi MIT, © 2016 Batoul Apps. Huruf Arab: Amiri oleh Amiri Project Authors, SIL Open Font License 1.1. Kedua pemberitahuan disertakan dalam aplikasi.
Prayer times are calculated and may differ by a minute or two from your local mosque. When in doubt, follow your mosque.	Waktu sholat dihitung dan dapat berbeda satu atau dua menit dari masjid setempatmu. Jika ragu, ikuti masjidmu.
Made with care for the ummah	Dibuat dengan sepenuh hati untuk umat
Provenance	Asal
Calculation	Perhitungan
Adjustments	Penyesuaian
Your correction	Koreksimu
Temkin margin	Margin temkin
Method adjustment	Penyesuaian metode
Twilight angle	Sudut senja
High-latitude rule	Aturan lintang tinggi
Fixed interval after maghrib	Selang tetap setelah magrib
No margin is applied to this time.	Tidak ada margin yang diterapkan pada waktu ini.
Provenance for this day is not loaded yet.	Asal untuk hari ini belum dimuat.
Shift this time	Geser waktu ini
No shift	Tanpa geseran
Use this only to match a mosque or a printed calendar you trust. It moves the notification too. Limited to ±30 minutes, because past that it is a different prayer time rather than a correction.	Pakai ini hanya untuk mencocokkan masjid atau kalender cetak yang kamu percaya. Notifikasinya bergeser juga. Dibatasi ±30 menit, karena melebihi itu bukan koreksi lagi melainkan waktu sholat yang lain.
Reset	Setel ulang
One minute earlier	Satu menit lebih awal
One minute later	Satu menit lebih lambat
Calendar tradition	Tradisi kalender
Why is this different from Diyanet?	Mengapa ini berbeda dari Diyanet?
Computed on this device	Dihitung di perangkat ini
From the online calendar	Dari kalender online
Never synced — running fully offline	Belum pernah disinkronkan — berjalan sepenuhnya luring
Prayer times never depend on a connection. They are calculated here, and the network only refines them when it is available.	Waktu sholat tidak pernah bergantung pada koneksi. Semuanya dihitung di sini, dan jaringan hanya menghaluskannya saat tersedia.
No schedule at this latitude	Tidak ada jadwal di lintang ini
Where you are, the sun does not cross the horizon today, so there is no astronomical dawn or sunset to anchor the times to. Choose a reference city in Settings and we will follow its schedule instead of inventing one.	Di tempatmu, matahari tidak melintasi horizon hari ini, jadi tidak ada fajar atau magrib astronomis untuk menambatkan waktunya. Pilih kota acuan di Pengaturan dan kami akan mengikuti jadwalnya alih-alih mengarang sendiri.
Disliked times	Waktu yang dimakruhkan
Just after sunrise	Sesaat setelah matahari terbit
Sun at its peak	Matahari di puncaknya
As the sun sets	Saat matahari terbenam
Voluntary prayer is not offered in these three intervals. The peak window runs from the true solar transit computed on this device to the öğle time your calendar publishes — the gap between them is exactly the temkin. The sunrise and sunset windows use the common convention that the sun must be about 5° above the horizon, roughly the classical "length of a spear".	Sholat sunnah tidak dikerjakan dalam tiga selang ini. Jendela puncak berjalan dari transit matahari sebenarnya yang dihitung di perangkat ini hingga waktu zuhur yang diterbitkan kalendermu — jarak di antaranya persis sebesar temkin. Jendela terbit dan terbenam memakai konvensi umum bahwa matahari harus sekitar 5° di atas horizon, kira-kira sepanjang tombak dalam ukuran klasik.
These windows cannot be derived for this day and place.	Jendela ini tidak dapat diturunkan untuk hari dan tempat ini.
The night	Malam
Middle of the night	Tengah malam
Last third of the night	Sepertiga malam terakhir
Measured from maghrib to the following imsak, not from clock midnight. The last third is when tahajjud is offered.	Diukur dari magrib hingga imsak berikutnya, bukan dari tengah malam menurut jam. Sepertiga terakhir adalah waktu tahajud.
Needs tomorrow's imsak — not loaded yet.	Butuh imsak besok — belum dimuat.
Friday	Jumat
Jumu'ah is prayed at the öğle time	Sholat Jumat dikerjakan pada waktu zuhur
Share imsakiye	Bagikan imsakiyah
Prayer timetable	Jadwal sholat
Preparing…	Menyiapkan…
Solar noon	Tengah hari
Tap a time to see where it comes from	Ketuk sebuah waktu untuk melihat asalnya
Alert for this prayer	Pengingat untuk sholat ini
DAY AT A GLANCE	HARI DALAM SEKILAS
All of today's prayers have passed	Semua sholat hari ini telah lewat
DAYLIGHT	CAHAYA SIANG
Finding your city…	Mencari kotamu…
PRAYER LOG	CATATAN SHOLAT
Tap a prayer once you have prayed it.	Ketuk sebuah sholat setelah kamu mengerjakannya.
Start your streak today	Mulai rentetanmu hari ini
Show the qibla	Tunjukkan kiblat
Start dhikr	Mulai dzikir
LAST 7 DAYS	7 HARI TERAKHIR
Times could not be refreshed	Waktu tidak dapat disegarkan
Qibla, dhikr and the Names still work offline.	Kiblat, dzikir dan Nama-nama tetap bekerja tanpa internet.
No schedule can be produced for this location today.	Tidak ada jadwal yang dapat dibuat untuk lokasi ini hari ini.
QUICK ACTIONS	AKSI CEPAT
Pull to refresh	Tarik untuk menyegarkan
Yesterday	Kemarin
NEXT	BERIKUTNYA
Loading the month…	Memuat bulan…
Full month	Sebulan penuh
SCHEDULE	JADWAL
Compass needs calibrating	Kompas perlu dikalibrasi
Move the phone in a figure-eight, away from metal and magnets.	Gerakkan ponsel membentuk angka delapan, jauh dari logam dan magnet.
Reading is unreliable right now	Bacaan tidak dapat diandalkan saat ini
HEADING	ARAH
TO MAKKAH	KE MEKAH
Mosques nearby	Masjid terdekat
Search this area	Cari area ini
Searching…	Mencari…
No mosques found nearby	Tidak ada masjid ditemukan di dekat sini
Directions	Petunjuk arah
Call	Telepon
Jumu'ah today	Jumat hari ini
FASTING LOG	CATATAN PUASA
I fasted today	Aku puasa hari ini
Today is logged	Hari ini tercatat
fasted	puasa
not logged	belum tercatat
Zakat Calculator	Kalkulator Zakat
Work out what is due, item by item	Hitung yang wajib, pos per pos
Clear the worksheet	Bersihkan lembar kerja
CURRENT GRAM PRICES	HARGA PER GRAM SAAT INI
Gold, current price per gram	Emas, harga per gram saat ini
Silver, current price per gram	Perak, harga per gram saat ini
Enter today's prices yourself. Revak does not fetch them: there is no free, reliable price source we can stand behind, and a stale price would quietly give you the wrong zakat.	Masukkan harga hari ini sendiri. Revak tidak mengambilnya: tidak ada sumber harga gratis dan dapat dipercaya yang bisa kami pertanggungjawabkan, dan harga usang akan diam-diam memberimu zakat yang salah.
These prices may be out of date — check before you rely on the result.	Harga ini mungkin sudah kedaluwarsa — periksa sebelum kamu bersandar pada hasilnya.
Enter a gram price to see the nisab threshold.	Masukkan harga per gram untuk melihat batas nisab.
Prices are current	Harga terkini
Figures from the Presidency of Religious Affairs (Diyanet İşleri Başkanlığı)	Angka dari Presidensi Urusan Agama Turki (Diyanet İşleri Başkanlığı)
Gold — 80.18 g (Diyanet)	Emas — 80,18 g (Diyanet)
Silver — 561 g (classical)	Perak — 561 g (klasik)
595 g (200 dirhem × 2.975 g)	595 g (200 dirham × 2,975 g)
561 g (200 dirhem × 2.805 g)	561 g (200 dirham × 2,805 g)
This is what Diyanet recommends, and it is already selected. Its ruling is that the value of 80.18 g of 24-carat gold should be the threshold for everything you hold — cash, silver, trade goods and investments alike.	Inilah yang dianjurkan Diyanet, dan sudah dipilih. Ketetapannya: nilai 80,18 g emas 24 karat menjadi batas untuk segala yang kamu miliki — kas, perak, barang dagangan maupun investasi.
The classical 200-dirhem threshold. It is a recognised opinion, but it is not Diyanet's: Diyanet holds that silver has lost too much of its historical value to serve as the measure, and says to use the gold figure even for silver. The silver threshold is much lower, so choosing it makes more people liable.	Batas klasik 200 dirham. Ini pendapat yang diakui, tetapi bukan pendapat Diyanet: Diyanet berpandangan perak telah kehilangan terlalu banyak nilai historisnya untuk menjadi ukuran, dan menyarankan memakai angka emas bahkan untuk perak. Batas perak jauh lebih rendah, jadi memilihnya membuat lebih banyak orang wajib zakat.
Diyanet's own answer is already chosen for you. Change it only if you follow a different opinion.	Jawaban Diyanet sendiri sudah dipilih untukmu. Ubah hanya jika kamu mengikuti pendapat lain.
WHAT YOU HOLD	YANG KAMU MILIKI
WHAT COMES OFF	YANG DIKURANGKAN
Cash	Kas
Bank accounts	Rekening bank
Gold (grams)	Emas (gram)
Silver (grams)	Perak (gram)
Trade goods	Barang dagangan
Money owed to you	Uang yang dipinjamkan kepada orang lain
Investments	Investasi
Debts you owe	Utangmu
Essential needs	Kebutuhan pokok
Housing, food and other basic needs are not zakatable.	Tempat tinggal, makanan dan kebutuhan dasar lain tidak dikenai zakat.
RESULT	HASIL
1/40 of net wealth (2.5%)	1/40 dari harta bersih (2,5%)
Below the threshold — no zakat is due on this amount.	Di bawah batas — tidak ada zakat yang wajib atas jumlah ini.
Enter a gram price and we can compare your wealth to the threshold.	Masukkan harga per gram dan kami dapat membandingkan hartamu dengan batasnya.
This is a calculation aid, not a fatwa. Rulings differ between schools and situations — check with someone qualified before you act on it.	Ini alat bantu hitung, bukan fatwa. Ketetapan berbeda antar mazhab dan keadaan — periksa dengan orang yang berkompeten sebelum kamu bertindak atasnya.
ZAKAT YEAR	TAHUN ZAKAT
Zakat falls due once a full lunar year (havl) has passed over wealth that stayed above the threshold. Record the day your year began and we'll show the anniversary.	Zakat jatuh wajib setelah satu tahun kamariah penuh (haul) berlalu atas harta yang tetap di atas batas. Catat hari tahunmu mulai dan kami akan menampilkan ulang tahunnya.
My zakat year starts today	Tahun zakatku mulai hari ini
Clear the date	Hapus tanggal
Fitre	Fitrah
FITRE (SADAQAT AL-FITR)	FITRAH (SADAQAT AL-FITR)
Amount per person	Jumlah per orang
People in the household	Orang dalam rumah tangga
Fitre is a fixed amount per person, not a percentage, and it is given before the eid prayer. In Türkiye the minimum is announced each year by the Din İşleri Yüksek Kurulu.	Fitrah adalah jumlah tetap per orang, bukan persentase, dan diberikan sebelum sholat id. Di Turki jumlah minimumnya diumumkan setiap tahun oleh Din İşleri Yüksek Kurulu.
This year's figure has not been added yet. Check the amount announced by the Din İşleri Yüksek Kurulu and enter it here.	Angka tahun ini belum ditambahkan. Periksa jumlah yang diumumkan Din İşleri Yüksek Kurulu lalu masukkan di sini.
Share summary	Bagikan ringkasan
Zakat summary	Ringkasan zakat
Opens the zakat calculator	Membuka kalkulator zakat
No date set	Tidak ada tanggal disetel
Revak has no saved prayer times yet. Open the app once so it can calculate them.	Revak belum menyimpan waktu sholat. Buka aplikasinya sekali agar dapat menghitungnya.
Revak does not know where you are. Grant location access or pick a city in the app.	Revak tidak tahu di mana kamu berada. Berikan akses lokasi atau pilih kota di aplikasi.
That prayer is not in today's saved schedule.	Sholat itu tidak ada dalam jadwal tersimpan hari ini.
Next Prayer	Sholat Berikutnya
Tells you which prayer is next and how long is left.	Memberitahumu sholat mana yang berikutnya dan berapa lama tersisa.
Remaining	Tersisa
Today's Prayer Times	Waktu Sholat Hari Ini
Returns every prayer time for today.	Mengembalikan setiap waktu sholat untuk hari ini.
Qibla Direction	Arah Kiblat
Gives the compass bearing to the Kaaba from your saved location.	Memberikan arah kompas menuju Kabah dari lokasi tersimpanmu.
Distance to Makkah	Jarak ke Mekah
Count Dhikr	Hitung Dzikir
Adds to today's dhikr count without opening the app.	Menambah hitungan dzikir hari ini tanpa membuka aplikasi.
How many	Berapa banyak
Dhikr today	Dzikir hari ini
Start Dhikr Session	Mulai Sesi Dzikir
Opens the counter on a chosen phrase.	Membuka penghitung pada kalimat pilihan.
Target count	Jumlah target
Mark Prayer as Prayed	Tandai Sholat Sudah Dikerjakan
Marks one of the five daily prayers as prayed for today.	Menandai satu dari lima sholat harian sudah dikerjakan hari ini.
Open Revak	Buka Revak
Opens Revak on a chosen screen.	Membuka Revak pada layar pilihan.
Screen	Layar
Revak Screen	Layar Revak
City	Kota
Current Location	Lokasi Saat Ini
Dhikr Counter	Penghitung Dzikir
Tap to count without opening Revak.	Ketuk untuk menghitung tanpa membuka Revak.
Prayer Times by City	Waktu Sholat per Kota
Pick which city's prayer times this widget shows.	Pilih waktu sholat kota mana yang ditampilkan widget ini.
Iftar & Suhoor	Berbuka & Sahur
Countdown to iftar, then to the end of suhoor.	Hitungan menuju berbuka, lalu menuju akhir sahur.
Opens the Qibla compass.	Membuka kompas kiblat.
One tap adds one to today's dhikr count.	Satu ketukan menambah satu pada hitungan dzikir hari ini.
Shows the next prayer and opens the schedule.	Menampilkan sholat berikutnya dan membuka jadwal.
Time for prayer	Waktunya sholat
Prayers	Sholat
Now	Sekarang
Open Revak on your iPhone once to send your settings.	Buka Revak di iPhone-mu sekali untuk mengirim pengaturanmu.
No location yet	Belum ada lokasi
Revak needs a location to calculate times. Allow location on the watch, or open the iPhone app.	Revak butuh lokasi untuk menghitung waktu. Izinkan lokasi di jam, atau buka aplikasi iPhone.
At this latitude the sun does not cross the horizon today, so these times cannot be calculated.	Pada lintang ini matahari tidak melintasi horizon hari ini, jadi waktu-waktu ini tidak dapat dihitung.
Watch location	Lokasi jam
Turn until the mark is at the top	Putar sampai tandanya di atas
No compass on this watch	Tidak ada kompas di jam ini
This model has no compass, so the direction cannot be shown live here. Open Qibla on your iPhone.	Model ini tidak punya kompas, jadi arahnya tidak dapat ditampilkan langsung di sini. Buka Kiblat di iPhone-mu.
Magnetic north — may be a few degrees off	Utara magnetik — bisa menyimpang beberapa derajat
Move your wrist in a figure eight to calibrate	Gerakkan pergelanganmu membentuk angka delapan untuk kalibrasi
Turn the Crown or tap to count	Putar Crown atau ketuk untuk menghitung
Phrase	Kalimat
Target reached	Target tercapai
Mark what you have prayed	Tandai yang sudah kamu sholatkan
Will sync to iPhone	Akan disinkronkan ke iPhone
Time remaining until the next prayer.	Waktu tersisa hingga sholat berikutnya.
Dhikr Count	Hitungan Dzikir
Today's dhikr total.	Total dzikir hari ini.
%d prayers left today	%d sholat lagi hari ini
%d day streak	rentetan %d hari
%d missed prayers	%d sholat qadha
%d days fasted	%d hari puasa
"""
}
