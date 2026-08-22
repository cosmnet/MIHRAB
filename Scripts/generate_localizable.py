#!/usr/bin/env python3
"""Generate Localizable.xcstrings for Mihrab (en / tr / ar)."""
import json
from pathlib import Path

def loc(en, tr, ar):
    return {
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": en}},
            "tr": {"stringUnit": {"state": "translated", "value": tr}},
            "ar": {"stringUnit": {"state": "translated", "value": ar}},
        }
    }

strings = {}

# Prayer names
schedule = {
    "fajr": ("Fajr", "İmsak", "الفجر"),
    "sunrise": ("Sunrise", "Güneş", "الشروق"),
    "dhuhr": ("Dhuhr", "Öğle", "الظهر"),
    "asr": ("Asr", "İkindi", "العصر"),
    "maghrib": ("Maghrib", "Akşam", "المغرب"),
    "isha": ("Isha", "Yatsı", "العشاء"),
}
namaz = {
    "fajr": ("Fajr", "Sabah", "الفجر"),
    "sunrise": ("Sunrise", "Güneş", "الشروق"),
    "dhuhr": ("Dhuhr", "Öğle", "الظهر"),
    "asr": ("Asr", "İkindi", "العصر"),
    "maghrib": ("Maghrib", "Akşam", "المغرب"),
    "isha": ("Isha", "Yatsı", "العشاء"),
}
countdown = {
    "fajr": ("FAJR IN", "SABAH'A KALAN", "حتى الفجر"),
    "sunrise": ("SUNRISE IN", "GÜNEŞ'E KALAN", "حتى الشروق"),
    "dhuhr": ("DHUHR IN", "ÖĞLE'YE KALAN", "حتى الظهر"),
    "asr": ("ASR IN", "İKİNDİ'YE KALAN", "حتى العصر"),
    "maghrib": ("MAGHRIB IN", "AKŞAM'A KALAN", "حتى المغرب"),
    "isha": ("ISHA IN", "YATSI'YA KALAN", "حتى العشاء"),
}
short = {
    "fajr": ("Fajr", "İmsak", "فجر"),
    "sunrise": ("Sun", "Güneş", "شرق"),
    "dhuhr": ("Dhuhr", "Öğle", "ظهر"),
    "asr": ("Asr", "İkindi", "عصر"),
    "maghrib": ("Magh", "Akşam", "مغرب"),
    "isha": ("Isha", "Yatsı", "عشاء"),
}
for k, v in schedule.items():
    strings[f"prayer.schedule.{k}"] = loc(*v)
for k, v in namaz.items():
    strings[f"prayer.namaz.{k}"] = loc(*v)
for k, v in countdown.items():
    strings[f"prayer.countdown.{k}"] = loc(*v)
for k, v in short.items():
    strings[f"prayer.short.{k}"] = loc(*v)

hijri = [
    ("Muharram", "Muharrem", "محرم"),
    ("Safar", "Safer", "صفر"),
    ("Rabiʿ al-Awwal", "Rebiülevvel", "ربيع الأول"),
    ("Rabiʿ al-Thani", "Rebiülahir", "ربيع الآخر"),
    ("Jumada al-Ula", "Cemaziyelevvel", "جمادى الأولى"),
    ("Jumada al-Akhirah", "Cemaziyelahir", "جمادى الآخرة"),
    ("Rajab", "Recep", "رجب"),
    ("Shaʿban", "Şaban", "شعبان"),
    ("Ramadan", "Ramazan", "رمضان"),
    ("Shawwal", "Şevval", "شوال"),
    ("Dhul-Qaʿdah", "Zilkade", "ذو القعدة"),
    ("Dhul-Hijjah", "Zilhicce", "ذو الحجة"),
]
for i, v in enumerate(hijri, 1):
    strings[f"hijri.month.{i}"] = loc(*v)

strings["method.diyanet"] = loc("Diyanet (Türkiye)", "Diyanet İşleri", "رئاسة الشؤون الدينية")
strings["method.ummAlQura"] = loc("Umm al-Qura", "Ümmü'l-Kurâ", "أم القرى")
strings["method.isna"] = loc("ISNA", "ISNA", "الجمعية الإسلامية لأمريكا الشمالية")
strings["method.mwl"] = loc("Muslim World League", "Dünya İslam Birliği", "رابطة العالم الإسلامي")
strings["method.egypt"] = loc("Egyptian Authority", "Mısır Heyeti", "الهيئة المصرية")
strings["method.karachi"] = loc("Univ. of Karachi", "Karaçi Üniversitesi", "جامعة كراتشي")
strings["madhab.hanafi"] = loc("Hanafi", "Hanefi", "حنفي")
strings["madhab.shafi"] = loc("Shafi'i", "Şafii", "شافعي")

# Tabs & chrome
strings["Today"] = loc("Today", "Bugün", "اليوم")
strings["Times"] = loc("Times", "Vakitler", "المواقيت")
strings["Qibla"] = loc("Qibla", "Kıble", "القبلة")
strings["Esmaül Hüsna"] = loc("Esmaül Hüsna", "Esmaül Hüsna", "أسماء الله الحسنى")
strings["Dhikr"] = loc("Dhikr", "Zikirmatik", "الذكر")
strings["Zikirmatik"] = loc("Zikirmatik", "Zikirmatik", "المسبحة")
strings["Prayer Times"] = loc("Prayer Times", "Namaz Vakitleri", "أوقات الصلاة")
strings["Settings"] = loc("Settings", "Ayarlar", "الإعدادات")
strings["Month"] = loc("Month", "Ay", "الشهر")
strings["Done"] = loc("Done", "Tamam", "تم")
strings["Skip"] = loc("Skip", "Atla", "تخطي")
strings["NOW"] = loc("NOW", "ŞİMDİ", "الآن")
strings["Day"] = loc("Day", "Gün", "اليوم")

# Greetings
strings["Good morning"] = loc("Good morning", "Günaydın", "صباح الخير")
strings["Good afternoon"] = loc("Good afternoon", "Tünaydın", "مساء الخير")
strings["Good evening"] = loc("Good evening", "İyi akşamlar", "مساء الخير")
strings["Good night"] = loc("Good night", "İyi geceler", "تصبح على خير")

# Today / empty
strings["Locating…"] = loc("Locating…", "Konum alınıyor…", "جارٍ تحديد الموقع…")
strings["Times unavailable — check connection"] = loc(
    "Times unavailable — check connection",
    "Vakitler yüklenemedi — bağlantını kontrol et",
    "تعذر تحميل المواقيت — تحقق من الاتصال",
)
strings["Loading prayer times"] = loc("Loading prayer times", "Namaz vakitleri yükleniyor", "جارٍ تحميل أوقات الصلاة")
strings["Fetching today’s schedule for your city."] = loc(
    "Fetching today’s schedule for your city.",
    "Şehrin için bugünün vakitleri alınıyor.",
    "جارٍ جلب مواقيت اليوم لمدينتك.",
)
strings["Location needed"] = loc("Location needed", "Konum gerekli", "الموقع مطلوب")
strings["Allow location so Mihrab can load prayer times."] = loc(
    "Allow location so Mihrab can load prayer times.",
    "Namaz vakitleri için konuma izin ver.",
    "اسمح بالموقع ليتم تحميل أوقات الصلاة.",
)
strings["Enable Location"] = loc("Enable Location", "Konumu Aç", "تفعيل الموقع")
strings["Times unavailable"] = loc("Times unavailable", "Vakitler yok", "المواقيت غير متاحة")
strings["Check your connection and try again."] = loc(
    "Check your connection and try again.",
    "Bağlantını kontrol edip tekrar dene.",
    "تحقق من الاتصال وحاول مرة أخرى.",
)
strings["Try Again"] = loc("Try Again", "Tekrar Dene", "حاول مرة أخرى")
strings["No times this month"] = loc("No times this month", "Bu ay için vakit yok", "لا مواقيت لهذا الشهر")
strings["Prayer times could not be loaded for this month."] = loc(
    "Prayer times could not be loaded for this month.",
    "Bu ayın namaz vakitleri yüklenemedi.",
    "تعذر تحميل أوقات الصلاة لهذا الشهر.",
)
strings["Previous day"] = loc("Previous day", "Önceki gün", "اليوم السابق")
strings["Next day"] = loc("Next day", "Sonraki gün", "اليوم التالي")

# Ornamental
strings["DAILY HADITH"] = loc("DAILY HADITH", "GÜNÜN HADİSİ", "حديث اليوم")
strings["DHIKR"] = loc("DHIKR", "ZİKİR", "الذكر")
strings["RAMADAN"] = loc("RAMADAN", "RAMAZAN", "رمضان")
strings["SUN PATH"] = loc("SUN PATH", "GÜNEŞ YOLU", "مسار الشمس")
strings["ESMAÜL HÜSNA"] = loc("ESMAÜL HÜSNA", "ESMAÜL HÜSNA", "أسماء الله الحسنى")
strings["RELIGIOUS DAYS"] = loc("RELIGIOUS DAYS", "DİNİ GÜNLER", "الأيام الدينية")
strings["THIS WEEK"] = loc("THIS WEEK", "BU HAFTA", "هذا الأسبوع")
strings["FASTING"] = loc("FASTING", "ORUÇ", "الصيام")
strings["DAILY DUAS"] = loc("DAILY DUAS", "GÜNLÜK DUALAR", "أدعية اليوم")
strings["KHATAM TRACKER"] = loc("KHATAM TRACKER", "HATİM TAKİBİ", "ختم القرآن")
strings["IFTAR IN"] = loc("IFTAR IN", "İFTARA KALAN", "حتى الإفطار")
strings["SUHOOR ENDS IN"] = loc("SUHOOR ENDS IN", "SAHUR BİTİŞİ", "حتى نهاية السحور")
strings["SUHOOR ENDS"] = loc("SUHOOR ENDS", "SAHUR BİTİŞİ", "نهاية السحور")
strings["IFTAR"] = loc("IFTAR", "İFTAR", "الإفطار")

# Quick actions
strings["Mosques"] = loc("Mosques", "Camiler", "المساجد")
strings["Qibla AR"] = loc("Qibla AR", "Kıble AR", "القبلة بالواقع المعزز")
strings["Daily goal: %lld"] = loc("Daily goal: %lld", "Günlük hedef: %lld", "الهدف اليومي: %lld")

# Qibla
strings["View in AR"] = loc("View in AR", "AR ile Gör", "عرض بالواقع المعزز")
strings["Facing the Qibla ✓"] = loc("Facing the Qibla ✓", "Kıbleye dönüksünüz ✓", "أنت تواجه القبلة ✓")
strings["Qibla %lld° %@"] = loc("Qibla %lld° %@", "Kıble %lld° %@", "القبلة %lld° %@")
strings["%lld km to Makkah"] = loc("%lld km to Makkah", "Mekke’ye %lld km", "%lld كم إلى مكة")
strings["Camera is used only to show direction. Nothing is recorded or uploaded."] = loc(
    "Camera is used only to show direction. Nothing is recorded or uploaded.",
    "Kamera yalnızca yön göstermek için kullanılır. Kayıt veya yükleme yoktur.",
    "تُستخدم الكاميرا فقط لإظهار الاتجاه. لا يتم التسجيل أو الرفع.",
)
strings["AR needs camera access"] = loc("AR needs camera access", "AR için kamera izni gerekli", "الواقع المعزز يحتاج إلى الكاميرا")
strings["Enable the camera in Settings, or use the compass instead."] = loc(
    "Enable the camera in Settings, or use the compass instead.",
    "Kamerayı Ayarlar’dan aç veya pusulayı kullan.",
    "فعّل الكاميرا من الإعدادات، أو استخدم البوصلة.",
)
strings["Back to Compass"] = loc("Back to Compass", "Pusulaya Dön", "العودة إلى البوصلة")
strings["Open Settings"] = loc("Open Settings", "Ayarları Aç", "فتح الإعدادات")
strings["Align with the Qibla"] = loc("Align with the Qibla", "Kıbleye hizala", "وجّه نحو القبلة")
strings["Locked on Qibla"] = loc("Locked on Qibla", "Kıble kilitlendi", "تم تثبيت القبلة")
strings["Point your phone toward the glowing Kaaba"] = loc(
    "Point your phone toward the glowing Kaaba",
    "Telefonunu parlayan Kâbe’ye doğru tut",
    "وجّه هاتفك نحو الكعبة المتوهجة",
)
strings["compass.N"] = loc("N", "K", "ش")
strings["compass.E"] = loc("E", "D", "ق")
strings["compass.S"] = loc("S", "G", "ج")
strings["compass.W"] = loc("W", "B", "غ")
strings["compass.NE"] = loc("NE", "KD", "ش ق")
strings["compass.SE"] = loc("SE", "GD", "ج ق")
strings["compass.SW"] = loc("SW", "GB", "ج غ")
strings["compass.NW"] = loc("NW", "KB", "ش غ")
strings["Waiting for compass…"] = loc("Waiting for compass…", "Pusula bekleniyor…", "بانتظار البوصلة…")
strings["Hold your iPhone flat for the compass."] = loc(
    "Hold your iPhone flat for the compass.",
    "Pusula için iPhone’u düz tut.",
    "أمسك الآيفون بشكل مستوٍ للبوصلة.",
)

# Dhikr
strings["of %lld · Set %lld"] = loc("of %lld · Set %lld", "%lld / set %lld", "%lld · المجموعة %lld")
strings["Sets"] = loc("Sets", "Set", "مجموعات")
strings["Session"] = loc("Session", "Oturum", "الجلسة")
strings["SET COMPLETE"] = loc("SET COMPLETE", "SET TAMAM", "اكتملت المجموعة")
strings["Long-press to reset"] = loc("Long-press to reset", "Sıfırlamak için basılı tut", "اضغط مطولاً للتصفير")
strings["Swipe to change phrase"] = loc("Swipe to change phrase", "İfadeyi değiştirmek için kaydır", "اسحب لتغيير الذكر")
strings["Dhikr Stats"] = loc("Dhikr Stats", "Zikir İstatistikleri", "إحصاءات الذكر")
strings["All Time"] = loc("All Time", "Tümü", "الكل")
strings["Streak"] = loc("Streak", "Seri", "التتابع")
strings["Week"] = loc("Week", "Hafta", "الأسبوع")
strings["days"] = loc("days", "gün", "أيام")
strings["Keep screen awake"] = loc("Keep screen awake", "Ekranı açık tut", "إبقاء الشاشة مستيقظة")

# Deen
strings["Hadith"] = loc("Hadith", "Hadis", "الحديث")
strings["Daily Hadith"] = loc("Daily Hadith", "Günün Hadisi", "حديث اليوم")
strings["Recite ×100"] = loc("Recite ×100", "100 kez zikret", "اقرأ ×١٠٠")
strings["Name of the day"] = loc("Name of the day", "Günün ismi", "اسم اليوم")
strings["%lld of 99"] = loc("%lld of 99", "99’dan %lld", "%lld من ٩٩")

# Onboarding
strings["Begin"] = loc("Begin", "Başla", "ابدأ")
strings["Enter Mihrab"] = loc("Enter Mihrab", "Mihrab’a Gir", "ادخل محراب")
strings["Continue"] = loc("Continue", "Devam", "متابعة")
strings["Enable Notifications"] = loc("Enable Notifications", "Bildirimleri Aç", "تفعيل الإشعارات")
strings["Prayer, beautifully present."] = loc(
    "Prayer, beautifully present.",
    "Namaz, güzellikle yanında.",
    "الصلاة، بحضور جميل.",
)
strings["For precise prayer times"] = loc("For precise prayer times", "Hassas namaz vakitleri için", "لأوقات صلاة دقيقة")
strings["Mihrab uses your location only on-device to calculate prayer times, Qibla direction, and nearby mosques."] = loc(
    "Mihrab uses your location only on-device to calculate prayer times, Qibla direction, and nearby mosques.",
    "Mihrab konumunu yalnızca cihazda namaz vakitleri, kıble ve yakındaki camiler için kullanır.",
    "يستخدم محراب موقعك على الجهاز فقط لحساب أوقات الصلاة والقبلة والمساجد القريبة.",
)
strings["Calculation method"] = loc("Calculation method", "Hesaplama yöntemi", "طريقة الحساب")
strings["Madhab"] = loc("Madhab", "Mezhep", "المذهب")
strings["Madhab (Asr)"] = loc("Madhab (Asr)", "Mezhep (İkindi)", "المذهب (العصر)")
strings["Never miss a prayer"] = loc("Never miss a prayer", "Hiçbir namazı kaçırma", "لا تفوّت أي صلاة")
strings["Always with you"] = loc("Always with you", "Her zaman yanında", "دائماً معك")
strings["Add the Mihrab widget to your Home Screen, Lock Screen, and Dynamic Island. You can set it up later in Settings."] = loc(
    "Add the Mihrab widget to your Home Screen, Lock Screen, and Dynamic Island. You can set it up later in Settings.",
    "Mihrab pencere öğesini Ana Ekran, Kilit Ekranı ve Dynamic Island’a ekle. Bunu sonra Ayarlar’dan yapabilirsin.",
    "أضف ودجة محراب إلى الشاشة الرئيسية وشاشة القفل والجزيرة الديناميكية. يمكنك إعدادها لاحقاً من الإعدادات.",
)

# Settings
strings["Prayer"] = loc("Prayer", "Namaz", "الصلاة")
strings["Location"] = loc("Location", "Konum", "الموقع")
strings["Appearance"] = loc("Appearance", "Görünüm", "المظهر")
strings["About"] = loc("About", "Hakkında", "حول")
strings["Current"] = loc("Current", "Şu an", "الحالي")
strings["Detecting…"] = loc("Detecting…", "Algılanıyor…", "جارٍ الكشف…")
strings["Use precise location"] = loc("Use precise location", "Hassas konumu kullan", "استخدام الموقع الدقيق")
strings["Clear manual override"] = loc("Clear manual override", "Elle seçimi temizle", "مسح التحديد اليدوي")
strings["Theme"] = loc("Theme", "Tema", "السمة")
strings["Auto"] = loc("Auto", "Otomatik", "تلقائي")
strings["Dark"] = loc("Dark", "Koyu", "داكن")
strings["Light"] = loc("Light", "Açık", "فاتح")
strings["Ramadan theme"] = loc("Ramadan theme", "Ramazan teması", "سمة رمضان")
strings["Version"] = loc("Version", "Sürüm", "الإصدار")
strings["Reset onboarding"] = loc("Reset onboarding", "Karşılama ekranını sıfırla", "إعادة شاشات البداية")
strings["Prayer times: Aladhan API · Hadith: bundled curated collection · No ads, no tracking, ever."] = loc(
    "Prayer times: Aladhan API · Hadith: bundled curated collection · No ads, no tracking, ever.",
    "Namaz vakitleri: Aladhan API · Hadis: seçilmiş derleme · Reklam yok, takip yok.",
    "أوقات الصلاة: Aladhan · الحديث: مجموعة منتقاة · بلا إعلانات ولا تتبع أبداً.",
)
strings["%@ notification"] = loc("%@ notification", "%@ bildirimi", "إشعار %@")

# Notifications
strings["notification.prayer.title %@"] = loc("%@ Time", "%@ vakti", "حان وقت %@")
strings["notification.prayer.body %@ %@"] = loc(
    "It's time for %@ prayer. %@",
    "%@ namazı vakti. %@",
    "حان وقت صلاة %@. %@",
)
strings["Jumu'ah Mubarak"] = loc("Jumu'ah Mubarak", "Cuma Mübarek Olsun", "جمعة مباركة")
strings["It's Friday — don't forget Surah al-Kahf and the Jumu'ah prayer."] = loc(
    "It's Friday — don't forget Surah al-Kahf and the Jumu'ah prayer.",
    "Bugün Cuma — Kehf suresini ve Cuma namazını unutma.",
    "اليوم الجمعة — لا تنسَ سورة الكهف وصلاة الجمعة.",
)

# Misc
strings["left"] = loc("left", "kaldı", "متبقي")
strings["Suhoor ends %@"] = loc("Suhoor ends %@", "Sahur bitiş %@", "ينتهي السحور %@")
strings["Ramadan"] = loc("Ramadan", "Ramazan", "رمضان")
strings["Log a juz"] = loc("Log a juz", "Cüz işaretle", "سجّل جزءاً")
strings["Iftar Dua"] = loc("Iftar Dua", "İftar Duası", "دعاء الإفطار")
strings["Suhoor Intention"] = loc("Suhoor Intention", "Sahur Niyeti", "نية السحور")
strings["Day %lld of ~29"] = loc("Day %lld of ~29", "~29 günden %lld. gün", "اليوم %lld من نحو ٢٩")
strings["Eid al-Fitr in %lld days"] = loc("Eid al-Fitr in %lld days", "Ramazan Bayramı’na %lld gün", "عيد الفطر بعد %lld يوم")
strings["%lld / 30 juz"] = loc("%lld / 30 juz", "%lld / 30 cüz", "%lld / ٣٠ جزءاً")
strings["May Allah accept your fast"] = loc("May Allah accept your fast", "Allah orucunu kabul etsin", "تقبل الله صيامك")
strings["Ramadan Mubarak"] = loc("Ramadan Mubarak", "Ramazan Mübarek Olsun", "رمضان مبارك")
strings["The month of mercy"] = loc("The month of mercy", "Rahmet ayı", "شهر الرحمة")
strings["Every moment is worship"] = loc("Every moment is worship", "Her an ibadet", "كل لحظة عبادة")
strings["Patience is half of faith"] = loc("Patience is half of faith", "Sabır imanın yarısıdır", "الصبر نصف الإيمان")
strings["Mosques Nearby"] = loc("Mosques Nearby", "Yakındaki Camiler", "المساجد القريبة")
strings["No mosques found nearby"] = loc("No mosques found nearby", "Yakında cami bulunamadı", "لم يُعثر على مساجد قريبة")
strings["Search a wider area or check location."] = loc(
    "Search a wider area or check location.",
    "Daha geniş bir alan dene veya konumu kontrol et.",
    "ابحث في نطاق أوسع أو تحقق من الموقع.",
)
strings["Open Mihrab"] = loc("Open Mihrab", "Mihrab’ı Aç", "افتح محراب")
strings["Prayer Times"] = strings["Prayer Times"]
strings["Next Prayer"] = loc("Next Prayer", "Sonraki Namaz", "الصلاة التالية")
strings["Next prayer at a glance."] = loc("Next prayer at a glance.", "Sonraki namaz bir bakışta.", "الصلاة التالية بنظرة.")
strings["Prayer Schedule"] = loc("Prayer Schedule", "Namaz Çizelgesi", "جدول الصلاة")
strings["Next prayer and today's times."] = loc(
    "Next prayer and today's times.",
    "Sonraki namaz ve bugünün vakitleri.",
    "الصلاة التالية ومواقيت اليوم.",
)
strings["Next Prayer Inline"] = loc("Next Prayer Inline", "Sonraki Namaz (satır)", "الصلاة التالية في سطر")
strings["Next prayer, inline."] = loc("Next prayer, inline.", "Sonraki namaz, satır içi.", "الصلاة التالية في السطر.")
strings["Next prayer countdown and today's schedule."] = loc(
    "Next prayer countdown and today's schedule.",
    "Sonraki namaza geri sayım ve bugünün çizelgesi.",
    "عدّاد الصلاة التالية وجدول اليوم.",
)
strings["Mihrab"] = loc("Mihrab", "Mihrab", "محراب")
strings["MIHRAB"] = loc("MIHRAB", "MIHRAB", "محراب")
strings["%lldd"] = loc("%lldd", "%lldg", "%lldي")
strings["%@ in %lld days"] = loc("%@ in %lld days", "%@ — %lld gün sonra", "%@ بعد %lld يوم")
strings["%@ in %lld day"] = loc("%@ in %lld day", "%@ — %lld gün sonra", "%@ بعد %lld يوم")
strings["Toggle %@ notification"] = loc("Toggle %@ notification", "%@ bildirimini aç/kapat", "تبديل إشعار %@")
strings["Next: %@, %@"] = loc("Next: %@, %@", "Sıradaki: %@, %@", "التالي: %@، %@")
strings["Current: %@, %@"] = loc("Current: %@, %@", "Şimdi: %@, %@", "الحالي: %@، %@")
strings["Loading prayer times"] = strings["Loading prayer times"]
strings["Search"] = loc("Search", "Ara", "بحث")
strings["Search this area"] = loc("Search this area", "Bu alanı ara", "ابحث في هذه المنطقة")
strings["Directions"] = loc("Directions", "Yol tarifi", "الاتجاهات")
strings["Jumu'ah today"] = loc("Jumu'ah today", "Bugün Cuma", "الجمعة اليوم")
strings["· %lld min"] = loc("· %lld min", "· %lld dk", "· %lld د")

catalog = {
    "sourceLanguage": "en",
    "strings": strings,
    "version": "1.0",
}

out = Path("/Users/cosm/Desktop/MIHRAB/Mihrab/Resources/Localizable.xcstrings")
out.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"Wrote {len(strings)} keys to {out}")
