import Foundation

/// Copy owned by the Zikirmatik surface. Every key is prefixed `dhk` so it can
/// never collide with the shared catalogue in `L10n.swift`.
extension L10n {

    // MARK: - Modes

    static var dhkModeCounter: String {
        string(en: "Counter", tr: "Sayaç", ar: "العدّاد")
    }

    static var dhkModeStrand: String {
        string(en: "Tasbih", tr: "Tesbih", ar: "المسبحة")
    }

    static var dhkModeSwitch: String {
        string(en: "Counting mode", tr: "Sayma modu", ar: "وضع العد")
    }

    /// The mode button names where it takes you, not where you are — one
    /// control instead of two, and no "which one is lit?" to work out.
    static var dhkModeToStrand: String {
        string(en: "Switch to tasbih", tr: "Tesbihe geç", ar: "التبديل إلى المسبحة")
    }

    static var dhkModeToCounter: String {
        string(en: "Switch to counter", tr: "Sayaca geç", ar: "التبديل إلى العدّاد")
    }

    static var dhkMore: String {
        string(en: "More", tr: "Daha fazla", ar: "المزيد")
    }

    static var dhkStrandHint: String {
        string(
            en: "Drag the beads — flick to run several",
            tr: "Taneleri çevir — fiskele, birkaçı birden geçsin",
            ar: "اسحب الحبات — انقر بسرعة لتمرير عدة حبات"
        )
    }

    // MARK: - Tasbih material

    static func dhkMaterialName(_ id: String) -> String {
        switch id {
        case "amber": string(en: "Amber", tr: "Kehribar", ar: "كهرمان")
        case "ebony": string(en: "Ebony", tr: "Abanoz", ar: "أبنوس")
        case "olive": string(en: "Olive wood", tr: "Zeytin ağacı", ar: "خشب الزيتون")
        default: id
        }
    }

    static var dhkMaterial: String {
        string(en: "Bead material", tr: "Tane malzemesi", ar: "مادة الحبات")
    }

    static var dhkMaterialNext: String {
        string(en: "Change bead material", tr: "Tane malzemesini değiştir", ar: "تغيير مادة الحبات")
    }

    static var dhkMaterialHint: String {
        string(
            en: "Double-tap the strand to change the beads",
            tr: "Taneleri değiştirmek için tesbihe çift dokun",
            ar: "انقر مرتين على المسبحة لتغيير الحبات"
        )
    }

    static var dhkPrefBeadSound: String {
        string(en: "Bead click", tr: "Tane tıkırtısı", ar: "نقرة الحبة")
    }

    static var dhkPrefBeadSoundFooter: String {
        string(
            en: "A short synthesised click as each bead passes. Follows the silent switch.",
            tr: "Her tane geçerken kısa, sentezlenmiş bir tık. Sessiz düğmesine uyar.",
            ar: "نقرة قصيرة مركّبة عند مرور كل حبة. تتبع مفتاح الصامت."
        )
    }

    static var dhkTapHint: String {
        string(en: "Tap anywhere to count", tr: "Saymak için ekrana dokun", ar: "انقر في أي مكان للعد")
    }

    static var dhkHoldToReset: String {
        string(en: "Hold to reset", tr: "Sıfırlamak için basılı tut", ar: "اضغط مطولاً للتصفير")
    }

    static var dhkResetDone: String {
        string(en: "Counter reset", tr: "Sayaç sıfırlandı", ar: "تم تصفير العدّاد")
    }

    // MARK: - Focus mode

    static var dhkFocusEnter: String {
        string(en: "Focus mode", tr: "Odak modu", ar: "وضع التركيز")
    }

    static var dhkFocusExit: String {
        string(en: "Leave focus mode", tr: "Odak modundan çık", ar: "الخروج من وضع التركيز")
    }

    static var dhkFocusExitHint: String {
        string(
            en: "Tap the background or swipe down to leave",
            tr: "Çıkmak için boşluğa dokun ya da aşağı kaydır",
            ar: "انقر على الخلفية أو اسحب للأسفل للخروج"
        )
    }

    static var dhkFocusEnterHint: String {
        string(
            en: "Hides everything but the dial",
            tr: "Kadran dışındaki her şeyi gizler",
            ar: "يخفي كل شيء ما عدا القرص"
        )
    }

    static var dhkPrefFocusDim: String {
        string(en: "Dim screen in focus mode", tr: "Odak modunda ekranı karart", ar: "خفض سطوع الشاشة في وضع التركيز")
    }

    static var dhkPrefFocusDimFooter: String {
        string(
            en: "Brightness is restored when you leave focus mode or the app.",
            tr: "Odak modundan ya da uygulamadan çıkınca parlaklık geri yüklenir.",
            ar: "تتم استعادة السطوع عند مغادرة وضع التركيز أو التطبيق."
        )
    }

    // MARK: - Library

    static var dhkLibrary: String {
        string(en: "Dhikr library", tr: "Zikir kütüphanesi", ar: "مكتبة الأذكار")
    }

    static var dhkLibraryPhrases: String {
        string(en: "Phrases", tr: "Zikirler", ar: "الأذكار")
    }

    static var dhkLibraryRoutines: String {
        string(en: "Routines", tr: "Tesbihat", ar: "الأوراد")
    }

    static var dhkLibraryCustom: String {
        string(en: "My dhikr", tr: "Zikirlerim", ar: "أذكاري")
    }

    static var dhkLibraryEsma: String {
        string(en: "Names of Allah", tr: "Esmaül Hüsna", ar: "أسماء الله الحسنى")
    }

    static var dhkNewCustom: String {
        string(en: "New dhikr", tr: "Yeni zikir", ar: "ذكر جديد")
    }

    static var dhkCustomName: String {
        string(en: "Name", tr: "Ad", ar: "الاسم")
    }

    static var dhkCustomArabic: String {
        string(en: "Arabic (optional)", tr: "Arapça (isteğe bağlı)", ar: "العربية (اختياري)")
    }

    static var dhkCustomTarget: String {
        string(en: "Target", tr: "Hedef", ar: "الهدف")
    }

    static var dhkSave: String {
        string(en: "Save", tr: "Kaydet", ar: "حفظ")
    }

    static var dhkCancel: String {
        string(en: "Cancel", tr: "Vazgeç", ar: "إلغاء")
    }

    static var dhkDelete: String {
        string(en: "Delete", tr: "Sil", ar: "حذف")
    }

    static var dhkCustomEmpty: String {
        string(en: "No dhikr of your own yet", tr: "Henüz kendi zikrin yok", ar: "لا توجد أذكار خاصة بك بعد")
    }

    static var dhkCustomEmptyBody: String {
        string(
            en: "Create a phrase with your own wording and target count.",
            tr: "Kendi metnin ve hedef sayınla bir zikir oluştur.",
            ar: "أنشئ ذكراً بصياغتك وعدد الهدف الخاص بك."
        )
    }

    static func dhkTargetLabel(_ n: Int) -> String {
        n == 0
            ? string(en: "Free count", tr: "Serbest sayım", ar: "عدّ حر")
            : string(en: "\(n)×", tr: "\(n)×", ar: "\(n)×")
    }

    // MARK: - Routines

    static var dhkRoutineStart: String {
        string(en: "Start routine", tr: "Tesbihatı başlat", ar: "ابدأ الورد")
    }

    static var dhkRoutineStop: String {
        string(en: "End routine", tr: "Tesbihatı bitir", ar: "إنهاء الورد")
    }

    static func dhkRoutineStep(_ index: Int, _ total: Int) -> String {
        string(en: "Step \(index) of \(total)", tr: "Adım \(index) / \(total)", ar: "الخطوة \(index) من \(total)")
    }

    static var dhkRoutineComplete: String {
        string(en: "Routine complete", tr: "Tesbihat tamamlandı", ar: "اكتمل الورد")
    }

    static var dhkNextPhrase: String {
        string(en: "Next", tr: "Sonraki", ar: "التالي")
    }

    static func dhkRoutineTotal(_ n: Int) -> String {
        string(en: "\(n) total", tr: "toplam \(n)", ar: "المجموع \(n)")
    }

    static func dhkRoutineTitle(_ id: String) -> String {
        switch id {
        case "tesbihat":
            return string(en: "After-prayer tasbihat", tr: "Namaz sonrası tesbihat", ar: "تسبيحات بعد الصلاة")
        case "sabah":
            return string(en: "Morning remembrance", tr: "Sabah zikri", ar: "أذكار الصباح")
        case "aksam":
            return string(en: "Evening remembrance", tr: "Akşam zikri", ar: "أذكار المساء")
        case "istigfar":
            return string(en: "Seeking forgiveness", tr: "İstiğfar virdi", ar: "ورد الاستغفار")
        case "salavat":
            return string(en: "Blessings on the Prophet", tr: "Salavat virdi", ar: "ورد الصلاة على النبي")
        default:
            return id
        }
    }

    static func dhkRoutineSubtitle(_ id: String) -> String {
        switch id {
        case "tesbihat":
            return string(en: "33 · 33 · 33 and tawhid", tr: "33 · 33 · 33 ve tevhid", ar: "٣٣ · ٣٣ · ٣٣ والتوحيد")
        case "sabah":
            return string(en: "Recited after Fajr", tr: "Sabah namazından sonra", ar: "بعد صلاة الفجر")
        case "aksam":
            return string(en: "Recited after Maghrib", tr: "Akşam namazından sonra", ar: "بعد صلاة المغرب")
        case "istigfar":
            return string(en: "One hundred, unhurried", tr: "Yüz kez, acelesiz", ar: "مائة مرة، بتمهّل")
        case "salavat":
            return string(en: "One hundred blessings", tr: "Yüz salavat", ar: "مائة صلاة")
        default:
            return ""
        }
    }

    // MARK: - Phrase names beyond the shared six

    static func dhkPhraseName(_ id: String) -> String {
        switch id {
        case "subhanallah", "alhamdulillah", "allahu-akbar",
             "la-ilaha", "salawat", "astaghfirullah":
            return dhikrPhrase(id)
        case "hasbunallah":
            return string(en: "Hasbunallah", tr: "Hasbünallah", ar: "حَسْبُنَا اللَّه")
        case "la-hawla":
            return string(en: "La hawla wa la quwwata", tr: "Lâ havle velâ kuvvete", ar: "لَا حَوْلَ وَلَا قُوَّة")
        case "subhanallahi-bihamdihi":
            return string(en: "Subhanallahi wa bihamdih", tr: "Sübhânallâhi ve bihamdih", ar: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ")
        case "tevhid":
            return string(en: "Kalima Tawhid", tr: "Kelime-i Tevhid", ar: "كلمة التوحيد")
        case "esma-rahman":
            return string(en: "Ya Rahman", tr: "Yâ Rahmân", ar: "يَا رَحْمَٰن")
        case "esma-rahim":
            return string(en: "Ya Rahim", tr: "Yâ Rahîm", ar: "يَا رَحِيم")
        case "esma-latif":
            return string(en: "Ya Latif", tr: "Yâ Latîf", ar: "يَا لَطِيف")
        case "esma-fettah":
            return string(en: "Ya Fattah", tr: "Yâ Fettâh", ar: "يَا فَتَّاح")
        case "esma-shafi":
            return string(en: "Ya Shafi", tr: "Yâ Şâfî", ar: "يَا شَافِي")
        case "esma-hafiz":
            return string(en: "Ya Hafiz", tr: "Yâ Hafîz", ar: "يَا حَفِيظ")
        case "esma-vedud":
            return string(en: "Ya Wadud", tr: "Yâ Vedûd", ar: "يَا وَدُود")
        case "esma-rezzak":
            return string(en: "Ya Razzaq", tr: "Yâ Rezzâk", ar: "يَا رَزَّاق")
        case "esma-sabur":
            return string(en: "Ya Sabur", tr: "Yâ Sabûr", ar: "يَا صَبُور")
        default:
            return id
        }
    }

    static func dhkPhraseMeaning(_ id: String) -> String {
        switch id {
        case "subhanallah":
            return string(en: "Glory be to Allah", tr: "Allah'ı tenzih ederim", ar: "تنزيهاً لله")
        case "alhamdulillah":
            return string(en: "All praise is for Allah", tr: "Hamd Allah'a mahsustur", ar: "الحمد لله")
        case "allahu-akbar":
            return string(en: "Allah is the Greatest", tr: "Allah en büyüktür", ar: "الله أكبر")
        case "la-ilaha", "tevhid":
            return string(en: "There is no god but Allah", tr: "Allah'tan başka ilah yoktur", ar: "لا إله إلا الله")
        case "salawat":
            return string(en: "Blessings upon the Prophet ﷺ", tr: "Peygamber'e ﷺ salavat", ar: "الصلاة على النبي ﷺ")
        case "astaghfirullah":
            return string(en: "I seek Allah's forgiveness", tr: "Allah'tan bağışlanma dilerim", ar: "أستغفر الله")
        case "hasbunallah":
            return string(en: "Allah is sufficient for us", tr: "Allah bize yeter", ar: "حسبنا الله")
        case "la-hawla":
            return string(en: "No power except with Allah", tr: "Güç ancak Allah'tandır", ar: "لا قوة إلا بالله")
        case "subhanallahi-bihamdihi":
            return string(en: "Glory and praise be to Allah", tr: "Allah'ı hamd ile tesbih ederim", ar: "سبحان الله وبحمده")
        case "esma-rahman":
            return string(en: "The Most Compassionate", tr: "Rahmeti sonsuz olan", ar: "الرحمن")
        case "esma-rahim":
            return string(en: "The Most Merciful", tr: "Çok merhametli olan", ar: "الرحيم")
        case "esma-latif":
            return string(en: "The Subtle, the Gentle", tr: "Lütfu bol olan", ar: "اللطيف")
        case "esma-fettah":
            return string(en: "The Opener of ways", tr: "Yolları açan", ar: "الفتاح")
        case "esma-shafi":
            return string(en: "The Healer", tr: "Şifa veren", ar: "الشافي")
        case "esma-hafiz":
            return string(en: "The Preserver", tr: "Koruyan", ar: "الحفيظ")
        case "esma-vedud":
            return string(en: "The Loving", tr: "Çok seven, sevilen", ar: "الودود")
        case "esma-rezzak":
            return string(en: "The Provider", tr: "Rızık veren", ar: "الرزاق")
        case "esma-sabur":
            return string(en: "The Patient", tr: "Sabrı sonsuz olan", ar: "الصبور")
        default:
            return ""
        }
    }

    // MARK: - Goal & stats

    static var dhkGoalToday: String {
        string(en: "Today's goal", tr: "Bugünkü hedef", ar: "هدف اليوم")
    }

    static func dhkGoalProgress(_ done: Int, _ goal: Int) -> String {
        string(en: "\(done) of \(goal)", tr: "\(goal) hedefin \(done)'i", ar: "\(done) من \(goal)")
    }

    static var dhkGoalReached: String {
        string(en: "Daily goal reached", tr: "Günlük hedefe ulaşıldı", ar: "تم بلوغ هدف اليوم")
    }

    static func dhkStreakDays(_ n: Int) -> String {
        string(en: "\(n)-day streak", tr: "\(n) günlük seri", ar: "تتابع \(n) يوم")
    }

    static var dhkBestDay: String {
        string(en: "Best day", tr: "En iyi gün", ar: "أفضل يوم")
    }

    static var dhkAverage: String {
        string(en: "Daily average", tr: "Günlük ortalama", ar: "المعدل اليومي")
    }

    static var dhkHistory: String {
        string(en: "History", tr: "Geçmiş", ar: "السجل")
    }

    static var dhkHistory30: String {
        string(en: "Last 30 days", tr: "Son 30 gün", ar: "آخر ٣٠ يوماً")
    }

    static var dhkByPhrase: String {
        string(en: "By phrase", tr: "Zikre göre", ar: "حسب الذكر")
    }

    static var dhkNoData: String {
        string(en: "Nothing counted yet", tr: "Henüz sayım yok", ar: "لا يوجد عدّ بعد")
    }

    static var dhkNoDataBody: String {
        string(
            en: "Your counts will appear here once you begin.",
            tr: "Zikre başladığında sayıların burada görünecek.",
            ar: "ستظهر أعدادك هنا بمجرد أن تبدأ."
        )
    }

    // MARK: - Preferences

    static var dhkPrefs: String {
        string(en: "Dhikr", tr: "Zikir", ar: "الذكر")
    }

    static var dhkPrefSound: String {
        string(en: "Tap sound", tr: "Dokunma sesi", ar: "صوت النقر")
    }

    static var dhkPrefHaptics: String {
        string(en: "Vibration", tr: "Titreşim", ar: "الاهتزاز")
    }

    static var dhkPrefKeepAwake: String {
        string(en: "Keep screen awake while counting", tr: "Sayarken ekranı açık tut", ar: "أبقِ الشاشة مضاءة أثناء العد")
    }

    static var dhkPrefStrandDefault: String {
        string(en: "Open in Tasbih mode", tr: "Tesbih modunda aç", ar: "افتح في وضع المسبحة")
    }

    static var dhkPrefGoal: String {
        string(en: "Daily goal", tr: "Günlük hedef", ar: "الهدف اليومي")
    }

    // MARK: - Premium

    static var dhkPremiumHistoryTitle: String {
        string(en: "Full history is a Plus feature", tr: "Tüm geçmiş Plus özelliğidir", ar: "السجل الكامل ميزة Plus")
    }

    static var dhkPremiumCustomTitle: String {
        string(en: "Custom dhikr is a Plus feature", tr: "Özel zikir Plus özelliğidir", ar: "الذكر المخصص ميزة Plus")
    }

    static var dhkUnlock: String {
        string(en: "Unlock", tr: "Kilidi aç", ar: "افتح")
    }
}
