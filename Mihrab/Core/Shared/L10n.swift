import Foundation

/// Hardcoded en/tr/ar copy. String Catalog interpolation was leaking raw keys
/// (`prayer.schedule.fajr`, `hijri.month.3`, `PRAYER.COUNTDOWN.ASR`) onto the UI.
enum L10n {
    enum Language: String {
        case english = "en"
        case turkish = "tr"
        case arabic = "ar"
    }

    static var language: Language {
        let codes = preferredLanguageCodes()
        if codes.contains(where: { $0.hasPrefix("tr") }) { return .turkish }
        if codes.contains(where: { $0.hasPrefix("ar") }) { return .arabic }
        return .english
    }

    static var localeIdentifier: String {
        switch language {
        case .turkish: "tr_TR"
        case .arabic: "ar"
        case .english: "en"
        }
    }

    /// `Date.formatted()` is not a SwiftUI view API, so it ignores the
    /// `\.locale` environment RootView sets and falls back to the device
    /// region — which renders month and weekday names in the wrong language.
    /// Every format style that produces a *name* must be given this locale.
    static var appLocale: Locale { Locale(identifier: localeIdentifier) }

    static var isTurkish: Bool { language == .turkish }
    static var isArabic: Bool { language == .arabic }

    static func string(en: String, tr: String, ar: String) -> String {
        switch language {
        case .turkish: tr
        case .arabic: ar
        case .english: en
        }
    }

    private static func preferredLanguageCodes() -> [String] {
        var codes: [String] = []
        if let code = Locale.autoupdatingCurrent.language.languageCode?.identifier {
            codes.append(code.lowercased())
        }
        codes.append(contentsOf: Locale.preferredLanguages.map { String($0.prefix(2)).lowercased() })
        if let region = Locale.autoupdatingCurrent.region?.identifier {
            codes.append(region.lowercased())
        }
        return codes
    }

    // MARK: - Tabs

    static var tabToday: String { string(en: "Today", tr: "Bugün", ar: "اليوم") }
    static var tabTimes: String { string(en: "Times", tr: "Vakitler", ar: "المواقيت") }
    static var tabQibla: String { string(en: "Qibla", tr: "Kıble", ar: "القبلة") }
    static var tabEsma: String { string(en: "Esmaül Hüsna", tr: "Esmaül Hüsna", ar: "أسماء الله الحسنى") }
    static var tabDhikr: String { string(en: "Zikirmatik", tr: "Zikirmatik", ar: "الذكر") }

    // MARK: - Greetings

    static var goodMorning: String { string(en: "Good morning", tr: "Günaydın", ar: "صباح الخير") }
    static var goodAfternoon: String { string(en: "Good afternoon", tr: "İyi günler", ar: "طاب يومك") }
    static var goodEvening: String { string(en: "Good evening", tr: "İyi akşamlar", ar: "مساء الخير") }
    static var goodNight: String { string(en: "Good night", tr: "İyi geceler", ar: "تصبح على خير") }

    // MARK: - Prayer schedule (strip / Times rows)

    static var prayerFajr: String { string(en: "Fajr", tr: "İmsak", ar: "الفجر") }
    static var prayerSunrise: String { string(en: "Sunrise", tr: "Güneş", ar: "الشروق") }
    static var prayerDhuhr: String { string(en: "Dhuhr", tr: "Öğle", ar: "الظهر") }
    static var prayerAsr: String { string(en: "Asr", tr: "İkindi", ar: "العصر") }
    static var prayerMaghrib: String { string(en: "Maghrib", tr: "Akşam", ar: "المغرب") }
    static var prayerIsha: String { string(en: "Isha", tr: "Yatsı", ar: "العشاء") }

    static var namazFajr: String { string(en: "Fajr", tr: "Sabah", ar: "الفجر") }
    static var namazSunrise: String { string(en: "Sunrise", tr: "Güneş", ar: "الشروق") }
    static var namazDhuhr: String { string(en: "Dhuhr", tr: "Öğle", ar: "الظهر") }
    static var namazAsr: String { string(en: "Asr", tr: "İkindi", ar: "العصر") }
    static var namazMaghrib: String { string(en: "Maghrib", tr: "Akşam", ar: "المغرب") }
    static var namazIsha: String { string(en: "Isha", tr: "Yatsı", ar: "العشاء") }

    static var countdownFajr: String { string(en: "Fajr in", tr: "İmsake kalan", ar: "حتى الفجر") }
    static var countdownSunrise: String { string(en: "Sunrise in", tr: "Güneşe kalan", ar: "حتى الشروق") }
    static var countdownDhuhr: String { string(en: "Dhuhr in", tr: "Öğleye kalan", ar: "حتى الظهر") }
    static var countdownAsr: String { string(en: "Asr in", tr: "İkindiye kalan", ar: "حتى العصر") }
    static var countdownMaghrib: String { string(en: "Maghrib in", tr: "Akşama kalan", ar: "حتى المغرب") }
    static var countdownIsha: String { string(en: "Isha in", tr: "Yatsıya kalan", ar: "حتى العشاء") }

    static var shortFajr: String { string(en: "Fajr", tr: "İmsak", ar: "فجر") }
    static var shortSunrise: String { string(en: "Sun", tr: "Güneş", ar: "شروق") }
    static var shortDhuhr: String { string(en: "Dhuhr", tr: "Öğle", ar: "ظهر") }
    static var shortAsr: String { string(en: "Asr", tr: "İkindi", ar: "عصر") }
    static var shortMaghrib: String { string(en: "Maghrib", tr: "Akşam", ar: "مغرب") }
    static var shortIsha: String { string(en: "Isha", tr: "Yatsı", ar: "عشاء") }

    static var now: String { string(en: "NOW", tr: "ŞİMDİ", ar: "الآن") }
    static var prayerTimesTitle: String { string(en: "Prayer Times", tr: "Namaz Vakitleri", ar: "مواقيت الصلاة") }
    static var month: String { string(en: "Month", tr: "Ay", ar: "الشهر") }
    static var today: String { string(en: "Today", tr: "Bugün", ar: "اليوم") }
    static var day: String { string(en: "Day", tr: "Gün", ar: "اليوم") }
    static var locating: String { string(en: "Locating…", tr: "Konum alınıyor…", ar: "جارٍ تحديد الموقع…") }
    static var loadingTimes: String { string(en: "Loading prayer times", tr: "Vakitler yükleniyor", ar: "جاري تحميل المواقيت") }
    static var fetchingSchedule: String { string(en: "Fetching today’s schedule for your city.", tr: "Şehrin için bugünün vakitleri alınıyor.", ar: "جاري جلب مواقيت اليوم لمدينتك.") }
    static var locationNeeded: String { string(en: "Location needed", tr: "Konum gerekli", ar: "الموقع مطلوب") }
    static var locationNeededBody: String { string(en: "Allow location so Mihrab can load prayer times.", tr: "Namaz vakitleri için konuma izin ver.", ar: "اسمح بالموقع لتحميل المواقيت.") }
    static var timesUnavailable: String { string(en: "Times unavailable", tr: "Vakitler alınamadı", ar: "المواقيت غير متاحة") }
    static var checkConnection: String { string(en: "Check your connection and try again.", tr: "Bağlantını kontrol edip tekrar dene.", ar: "تحقق من الاتصال وحاول مرة أخرى.") }
    static var tryAgain: String { string(en: "Try Again", tr: "Tekrar Dene", ar: "حاول مرة أخرى") }
    static var enableLocation: String { string(en: "Enable Location", tr: "Konumu aç", ar: "تفعيل الموقع") }
    static var previousDay: String { string(en: "Previous day", tr: "Önceki gün", ar: "اليوم السابق") }
    static var nextDay: String { string(en: "Next day", tr: "Sonraki gün", ar: "اليوم التالي") }
    static var timesUnavailableShort: String { string(en: "Times unavailable — check connection", tr: "Vakitler alınamadı — bağlantıyı kontrol et", ar: "المواقيت غير متاحة — تحقق من الاتصال") }
    static var sunPath: String { string(en: "SUN PATH", tr: "GÜNEŞ YOLU", ar: "مسار الشمس") }
    static var alertsOn: String { string(en: "Alerts on", tr: "Uyarılar açık", ar: "التنبيهات مفعّلة") }
    static var alertsOff: String { string(en: "Alerts off", tr: "Uyarılar kapalı", ar: "التنبيهات متوقفة") }
    static var toggleAlertsHint: String { string(en: "Toggles prayer alerts", tr: "Namaz uyarılarını açıp kapatır", ar: "تبديل تنبيهات الصلاة") }

    // MARK: - Methods / madhab

    static var methodDiyanet: String { string(en: "Diyanet (Türkiye)", tr: "Diyanet (Türkiye)", ar: "Diyanet (Türkiye)") }
    static var methodUmmAlQura: String { string(en: "Umm al-Qura", tr: "Ümmü'l-Kurâ", ar: "أم القرى") }
    static var methodISNA: String { string(en: "ISNA", tr: "ISNA", ar: "الجمعية الإسلامية لأمريكا الشمالية") }
    static var methodMWL: String { string(en: "Muslim World League", tr: "Dünya İslam Birliği", ar: "رابطة العالم الإسلامي") }
    static var methodEgypt: String { string(en: "Egyptian Authority", tr: "Mısır Heyeti", ar: "الهيئة المصرية") }
    static var methodKarachi: String { string(en: "Univ. of Karachi", tr: "Karaçi Üniversitesi", ar: "جامعة كراتشي") }
    static var madhabShafi: String { string(en: "Shafi'i", tr: "Şafii", ar: "شافعي") }
    static var madhabHanafi: String { string(en: "Hanafi", tr: "Hanefi", ar: "حنفي") }
    static var madhab: String { string(en: "Madhab", tr: "Mezhep", ar: "المذهب") }

    // MARK: - Hijri months

    static func hijriMonth(_ month: Int) -> String {
        let names: [(en: String, tr: String, ar: String)] = [
            ("Muharram", "Muharrem", "محرم"),
            ("Safar", "Safer", "صفر"),
            ("Rabi' al-Awwal", "Rebiülevvel", "ربيع الأول"),
            ("Rabi' al-Thani", "Rebiülahir", "ربيع الآخر"),
            ("Jumada al-Ula", "Cemaziyelevvel", "جمادى الأولى"),
            ("Jumada al-Akhirah", "Cemaziyelahir", "جمادى الآخرة"),
            ("Rajab", "Recep", "رجب"),
            ("Sha'ban", "Şaban", "شعبان"),
            ("Ramadan", "Ramazan", "رمضان"),
            ("Shawwal", "Şevval", "شوال"),
            ("Dhul-Qa'dah", "Zilkade", "ذو القعدة"),
            ("Dhul-Hijjah", "Zilhicce", "ذو الحجة"),
        ]
        let i = min(max(month - 1, 0), 11)
        return string(en: names[i].en, tr: names[i].tr, ar: names[i].ar)
    }

    // MARK: - Today

    static var dailyHadith: String { string(en: "DAILY HADITH", tr: "GÜNÜN HADİSİ", ar: "حديث اليوم") }
    static var mosques: String { string(en: "Mosques", tr: "Camiler", ar: "المساجد") }
    static var qiblaAR: String { string(en: "Qibla AR", tr: "Kıble AR", ar: "القبلة AR") }
    static var zikirmatik: String { string(en: "Zikirmatik", tr: "Zikirmatik", ar: "الذكر") }
    static var ramadan: String { string(en: "RAMADAN", tr: "RAMAZAN", ar: "رمضان") }
    static var ramadanTitle: String { string(en: "Ramadan", tr: "Ramazan", ar: "رمضان") }
    static var dhikr: String { string(en: "DHIKR", tr: "ZİKİR", ar: "الذكر") }
    static func dailyGoal(_ n: Int) -> String {
        string(en: "Daily goal: \(n)", tr: "Günlük hedef: \(n)", ar: "الهدف اليومي: \(n)")
    }
    static func iftarLeft(_ time: String) -> String {
        string(en: "Iftar \(time)", tr: "İftar \(time)", ar: "الإفطار \(time)")
    }
    static var left: String { string(en: "left", tr: "kaldı", ar: "متبقٍ") }
    static func suhoorEnds(_ time: String) -> String {
        string(en: "Suhoor ends \(time)", tr: "Sahur bitiş \(time)", ar: "ينتهي السحور \(time)")
    }
    static func inDays(_ name: String, _ n: Int) -> String {
        if n == 1 { return string(en: "\(name) in 1 day", tr: "\(name) 1 gün sonra", ar: "\(name) بعد يوم") }
        return string(en: "\(name) in \(n) days", tr: "\(name) \(n) gün sonra", ar: "\(name) بعد \(n) أيام")
    }

    static var hourShort: String { string(en: "h", tr: "sa", ar: "س") }
    static var minuteShort: String { string(en: "m", tr: "dk", ar: "د") }

    /// Hours + minutes only — never seconds. TR: `1 sa 35 dk`.
    static func remainingHoursMinutes(_ hours: Int, _ minutes: Int) -> String {
        if hours <= 0 {
            return string(en: "\(minutes)m", tr: "\(minutes) dk", ar: "\(minutes) د")
        }
        return string(
            en: "\(hours)h \(minutes)m",
            tr: "\(hours) sa \(minutes) dk",
            ar: "\(hours) س \(minutes) د"
        )
    }

    // MARK: - Onboarding

    static var tagline: String { string(en: "Prayer, beautifully present.", tr: "Namaz, zarifçe yanında.", ar: "الصلاة، حاضرة بجمال.") }
    static var begin: String { string(en: "Begin", tr: "Başla", ar: "ابدأ") }
    static var locationTitle: String { string(en: "For precise prayer times", tr: "Hassas namaz vakitleri için", ar: "لأوقات صلاة دقيقة") }
    static var locationBody: String {
        string(
            en: "Mihrab uses your location only on-device to calculate prayer times, Qibla direction, and nearby mosques.",
            tr: "Mihrab konumunu yalnızca cihazda kullanır: namaz vakitleri, kıble ve yakındaki camiler.",
            ar: "يستخدم محراب موقعك على الجهاز فقط لحساب المواقيت والقبلة والمساجد القريبة."
        )
    }
    static var calculationMethod: String { string(en: "Calculation method", tr: "Hesaplama yöntemi", ar: "طريقة الحساب") }
    static var `continue`: String { string(en: "Continue", tr: "Devam", ar: "متابعة") }
    static var skip: String { string(en: "Skip", tr: "Atla", ar: "تخطي") }
    static var neverMiss: String { string(en: "Never miss a prayer", tr: "Hiçbir namazı kaçırma", ar: "لا تفوّت أي صلاة") }
    static var enableNotifications: String { string(en: "Enable Notifications", tr: "Bildirimleri aç", ar: "تفعيل الإشعارات") }
    static var alwaysWithYou: String { string(en: "Always with you", tr: "Her zaman yanında", ar: "دائماً معك") }
    static var widgetBody: String {
        string(
            en: "Add the Mihrab widget to your Home Screen, Lock Screen, and Dynamic Island. You can set it up later in Settings.",
            tr: "Mihrab widget’ını Ana Ekran, Kilit Ekranı ve Dynamic Island’a ekle. Bunu sonra Ayarlar’dan da yapabilirsin.",
            ar: "أضف ودجة محراب إلى الشاشة الرئيسية وشاشة القفل وDynamic Island. يمكنك إعدادها لاحقاً من الإعدادات."
        )
    }
    static var enterMihrab: String { string(en: "Enter Mihrab", tr: "Mihrab'a gir", ar: "ادخل محراب") }

    // MARK: - Zikirmatik

    static func dhikrPhrase(_ id: String) -> String {
        switch id {
        case "subhanallah":
            string(en: "Subhanallah", tr: "Sübhanallah", ar: "سُبْحَانَ اللَّه")
        case "alhamdulillah":
            string(en: "Alhamdulillah", tr: "Elhamdülillah", ar: "الْحَمْدُ لِلَّه")
        case "allahu-akbar":
            string(en: "Allahu Akbar", tr: "Allahu Ekber", ar: "اللَّهُ أَكْبَر")
        case "la-ilaha":
            string(en: "La ilaha illallah", tr: "Lâ ilâhe illallah", ar: "لَا إِلَهَ إِلَّا اللَّه")
        case "salawat":
            string(en: "Salawat", tr: "Salavat", ar: "اللَّهُمَّ صَلِّ عَلَى مُحَمَّد")
        case "astaghfirullah":
            string(en: "Astaghfirullah", tr: "Estağfirullah", ar: "أَسْتَغْفِرُ اللَّه")
        default:
            id
        }
    }

    static func ofTargetSet(_ count: Int, _ target: Int, _ set: Int) -> String {
        string(
            en: "\(count) of \(target) • Set \(set)",
            tr: "\(count) / \(target) • set \(set)",
            ar: "\(count) من \(target) • المجموعة \(set)"
        )
    }

    static func setLabel(_ count: Int) -> String {
        string(en: count == 1 ? "set" : "sets", tr: "set", ar: count == 1 ? "مجموعة" : "مجموعات")
    }

    static var thisSession: String {
        string(en: "this session", tr: "bu oturum", ar: "هذه الجلسة")
    }

    static var setComplete: String { string(en: "Set complete", tr: "Set tamam", ar: "اكتملت المجموعة") }
    static var swipePhrase: String { string(en: "Swipe to change phrase", tr: "İfadeyi değiştirmek için kaydır", ar: "اسحب لتغيير الذكر") }
    static var dhikrStats: String { string(en: "Dhikr Stats", tr: "Zikir istatistikleri", ar: "إحصاءات الذكر") }
    static var keepAwake: String { string(en: "Keep screen awake", tr: "Ekranı açık tut", ar: "أبقِ الشاشة مستيقظة") }

    static var statsWeek: String { string(en: "Week", tr: "Hafta", ar: "الأسبوع") }
    static var statsAllTime: String { string(en: "All time", tr: "Tümü", ar: "الكل") }
    static var statsStreak: String { string(en: "Streak", tr: "Seri", ar: "التتابع") }
    static var thisWeek: String { string(en: "This week", tr: "Bu hafta", ar: "هذا الأسبوع") }
    static var dayUnit: String { string(en: "days", tr: "gün", ar: "أيام") }

    static func dhikrA11y(_ count: Int, _ target: Int) -> String {
        if target > 0 {
            return string(
                en: "Dhikr counter, \(count) of \(target)",
                tr: "Zikirmatik, \(target) içinden \(count)",
                ar: "عداد الذكر، \(count) من \(target)"
            )
        }
        return string(en: "Dhikr counter, \(count)", tr: "Zikirmatik, \(count)", ar: "عداد الذكر، \(count)")
    }

    static func dhikrA11yHint(_ phrase: String) -> String {
        string(en: "Tap to count \(phrase)", tr: "Saymak için dokun: \(phrase)", ar: "اضغط للعد \(phrase)")
    }

    static var achievements: String { string(en: "Rewards", tr: "Mükafatlar", ar: "الجوائز") }
    static var achievementsLexicon: String { string(en: "Dhikr lexicon", tr: "Tesbih lügati", ar: "معجم التسبيح") }
    static var achievementUnlocked: String { string(en: "Inscribed", tr: "İşlendi", ar: "نُقِش") }
    static var achievementInscribedMark: String { string(en: "Inscribed", tr: "İşlendi", ar: "منقوش") }

    static func achievementsInscribed(_ n: Int, _ total: Int) -> String {
        string(
            en: "\(n) of \(total) inscribed",
            tr: "\(n) / \(total) işlendi",
            ar: "\(n) من \(total) منقوش"
        )
    }

    static func achievementProgress(_ current: Int, _ goal: Int) -> String {
        string(en: "\(current) / \(goal)", tr: "\(current) / \(goal)", ar: "\(current) / \(goal)")
    }

    static func achievementTitle(_ id: String) -> String {
        switch id {
        case "firstTap": string(en: "First tap", tr: "İlk dokunuş", ar: "أول لمسة")
        case "first33": string(en: "First thirty-three", tr: "İlk otuz üç", ar: "أول ثلاث وثلاثين")
        case "first99": string(en: "First ninety-nine", tr: "İlk doksan dokuz", ar: "أول تسع وتسعين")
        case "first100": string(en: "First hundred", tr: "İlk yüz", ar: "أول مئة")
        case "day500": string(en: "Five hundred in a day", tr: "Günün beş yüzü", ar: "خمسمائة في يوم")
        case "streak7": string(en: "Seven days", tr: "Yedi gün", ar: "سبعة أيام")
        case "afterPrayer": string(en: "After-prayer tesbih", tr: "Namaz tesbihi", ar: "تسبيح ما بعد الصلاة")
        case "allTime1000": string(en: "A thousand", tr: "Bin zikir", ar: "ألف ذكر")
        case "streak30": string(en: "Thirty days", tr: "Otuz gün", ar: "ثلاثون يوماً")
        case "allPhrases": string(en: "Six phrases", tr: "Altı kelime", ar: "ست كلمات")
        case "allTime10000": string(en: "Ten thousand", tr: "On bin", ar: "عشرة آلاف")
        case "set500": string(en: "The five-hundred set", tr: "Beş yüz seti", ar: "مجموعة الخمسمائة")
        default: id
        }
    }

    static func achievementLemma(_ id: String) -> String {
        switch id {
        case "firstTap": string(en: "The opening bead.", tr: "Tesbihin evveli.", ar: "أول حبة.")
        case "first33": string(en: "A complete tesbih.", tr: "Bir tesbih tamam.", ar: "تسبيحة تامة.")
        case "first99": string(en: "The ninety-nine.", tr: "Esma tesbihi.", ar: "التسعة والتسعون.")
        case "first100": string(en: "A round hundred.", tr: "Yüz tesbih.", ar: "مئة تامة.")
        case "day500": string(en: "Abundance in one day.", tr: "Yevm-i kesret.", ar: "كثرة في يوم.")
        case "streak7": string(en: "A week of return.", tr: "Haftalık devam.", ar: "أسبوع من العودة.")
        case "afterPrayer": string(en: "Thirty-three thrice.", tr: "Otuz üç, üç kez.", ar: "ثلاث وثلاثون ثلاثاً.")
        case "allTime1000": string(en: "A thousand recitations.", tr: "Elf-i zikir.", ar: "ألف تلاوة.")
        case "streak30": string(en: "A month of return.", tr: "Aylık devam.", ar: "شهر من العودة.")
        case "allPhrases": string(en: "Each of the six.", tr: "Altısının her biri.", ar: "كلّ من الست.")
        case "allTime10000": string(en: "Great abundance.", tr: "Kesret.", ar: "كثرة عظيمة.")
        case "set500": string(en: "The long tesbih.", tr: "Uzun tesbih.", ar: "التسبيح الطويل.")
        default: id
        }
    }

    static func achievementDetail(_ id: String) -> String {
        switch id {
        case "firstTap":
            string(en: "You began a dhikr on Zikirmatik.", tr: "Zikirmatiğe ilk kez dokundun.", ar: "بدأت الذكر على الذكرماتيك.")
        case "first33":
            string(en: "You reached thirty-three recitations.", tr: "İlk 33 zikre ulaştın.", ar: "بلغت ثلاثاً وثلاثين.")
        case "first99":
            string(en: "You reached ninety-nine recitations.", tr: "99 zikre ulaştın.", ar: "بلغت تسعاً وتسعين.")
        case "first100":
            string(en: "You reached one hundred recitations.", tr: "100 zikre ulaştın.", ar: "بلغت مئة.")
        case "day500":
            string(en: "Five hundred in a single day.", tr: "Bir günde 500 zikir.", ar: "خمسمائة في يوم واحد.")
        case "streak7":
            string(en: "Dhikr on seven consecutive days.", tr: "Yedi gün üst üste zikir.", ar: "ذكر في سبعة أيام متتالية.")
        case "afterPrayer":
            string(
                en: "33 Subhanallah, 33 Alhamdulillah, 33 Allahu Akbar in one day.",
                tr: "Aynı günde 33 Sübhanallah, 33 Elhamdülillah, 33 Allahu Ekber.",
                ar: "٣٣ سبحان الله و٣٣ الحمد لله و٣٣ الله أكبر في يوم واحد."
            )
        case "allTime1000":
            string(en: "One thousand recitations in all.", tr: "Toplam 1000 zikir.", ar: "ألف ذكر في المجموع.")
        case "streak30":
            string(en: "Dhikr on thirty consecutive days.", tr: "Otuz gün üst üste zikir.", ar: "ذكر في ثلاثين يوماً متتالياً.")
        case "allPhrases":
            string(en: "You recited each of the six phrases.", tr: "Altı zikir ifadesinin her birini okudun.", ar: "تلوت كلّاً من الكلمات الست.")
        case "allTime10000":
            string(en: "Ten thousand recitations in all.", tr: "Toplam 10.000 zikir.", ar: "عشرة آلاف ذكر في المجموع.")
        case "set500":
            string(en: "You completed a set of five hundred.", tr: "500’lük bir seti tamamladın.", ar: "أتممت مجموعة من خمسمائة.")
        default: id
        }
    }

    // MARK: - Esma

    static var esmaTitle: String { string(en: "ESMAÜL HÜSNA", tr: "ESMAÜL HÜSNA", ar: "أسماء الله الحسنى") }
    static var search: String { string(en: "Search", tr: "Ara", ar: "بحث") }
    static var searchEsma: String { string(en: "Search a Name", tr: "İsim ara", ar: "ابحث عن اسم") }
    static var clear: String { string(en: "Clear", tr: "Temizle", ar: "مسح") }
    static var esmaNinetyNine: String { string(en: "99 NAMES", tr: "99 İSİM", ar: "٩٩ اسماً") }
    static func esmaResultCount(_ n: Int) -> String {
        string(en: "\(n) names", tr: "\(n) isim", ar: "\(n) أسماء")
    }
    static var esmaNoResults: String { string(en: "No names match.", tr: "Eşleşen isim yok.", ar: "لا توجد أسماء مطابقة.") }
    static func esmaReflection(_ meaning: String) -> String {
        string(
            en: "A Beautiful Name of Allah: \(meaning). Sit with it; let the heart settle before you speak it.",
            tr: "Allah’ın güzel isimlerinden: \(meaning). Bu isimle kalbi sakinleştir, sonra huşu ile oku.",
            ar: "من أسماء الله الحسنى: \(meaning). اسكن القلب ثم اذكره."
        )
    }
    static var nameOfTheDay: String { string(en: "Name of the day", tr: "Günün ismi", ar: "اسم اليوم") }
    static var recite100: String { string(en: "Recite ×100", tr: "100 kez oku", ar: "اقرأ ×100") }
    static var done: String { string(en: "Done", tr: "Tamam", ar: "تم") }
    static var religiousDays: String { string(en: "RELIGIOUS DAYS", tr: "DİNİ GÜNLER", ar: "الأيام الدينية") }
    static func daysShort(_ n: Int) -> String {
        string(en: "\(n)d", tr: "\(n)g", ar: "\(n)ي")
    }

    // MARK: - Qibla / AR

    static var viewInAR: String { string(en: "View in AR", tr: "AR’da gör", ar: "عرض بالواقع المعزز") }
    static var alignQibla: String { string(en: "Align with the Qibla", tr: "Kıbleye hizala", ar: "حاذِ القبلة") }
    static var facingQibla: String { string(en: "Facing the Qibla", tr: "Kıbleye dönüksünüz", ar: "أنت مواجه للقبلة") }
    static var lockedOnQibla: String { string(en: "Locked on Qibla", tr: "Kıbleye kilitlendi", ar: "ثُبّت على القبلة") }
    static func kmToMakkah(_ km: Int) -> String {
        string(en: "\(km) km to Makkah", tr: "Mekke’ye \(km) km", ar: "\(km) كم إلى مكة")
    }
    static func qiblaDegrees(_ deg: Int, _ cardinal: String) -> String {
        string(en: "Qibla \(deg)° \(cardinal)", tr: "Kıble \(deg)° \(cardinal)", ar: "القبلة \(deg)° \(cardinal)")
    }
    static var holdFlat: String { string(en: "Hold your iPhone flat for the compass.", tr: "Pusula için iPhone’u düz tut.", ar: "أمسك الآيفون بشكل مسطح للبوصلة.") }
    static var cameraPrivacy: String {
        string(
            en: "Camera is used only to show direction. Nothing is recorded or uploaded.",
            tr: "Kamera yalnızca yön göstermek için kullanılır. Kayıt veya yükleme yok.",
            ar: "تُستخدم الكاميرا فقط لإظهار الاتجاه. لا يتم التسجيل أو الرفع."
        )
    }
    static var arNeedsCamera: String { string(en: "AR needs camera access", tr: "AR için kamera izni gerekli", ar: "الواقع المعزز يحتاج إلى الكاميرا") }
    static var arCameraBody: String { string(en: "Enable the camera in Settings, or use the compass instead.", tr: "Kamerayı Ayarlar’dan aç veya pusulayı kullan.", ar: "فعّل الكاميرا من الإعدادات، أو استخدم البوصلة.") }
    static var openSettings: String { string(en: "Open Settings", tr: "Ayarları aç", ar: "فتح الإعدادات") }
    static var backToCompass: String { string(en: "Back to Compass", tr: "Pusulaya dön", ar: "العودة إلى البوصلة") }

    static var compassN: String { string(en: "N", tr: "K", ar: "ش") }
    static var compassNE: String { string(en: "NE", tr: "KD", ar: "ش ق") }
    static var compassE: String { string(en: "E", tr: "D", ar: "ق") }
    static var compassSE: String { string(en: "SE", tr: "GD", ar: "ج ق") }
    static var compassS: String { string(en: "S", tr: "G", ar: "ج") }
    static var compassSW: String { string(en: "SW", tr: "GB", ar: "ج غ") }
    static var compassW: String { string(en: "W", tr: "B", ar: "غ") }
    static var compassNW: String { string(en: "NW", tr: "KB", ar: "ش غ") }

    static func cardinal(for bearing: Double) -> String {
        let list = [compassN, compassNE, compassE, compassSE, compassS, compassSW, compassW, compassNW]
        return list[Int((bearing + 22.5) / 45) % 8]
    }

    static func cardinalForDegrees(_ degrees: Double) -> String {
        switch Int(degrees) {
        case 0: compassN
        case 90: compassE
        case 180: compassS
        case 270: compassW
        default: compassN
        }
    }

    // MARK: - Settings / empty

    static var settings: String { string(en: "Settings", tr: "Ayarlar", ar: "الإعدادات") }
    static var noTimesMonth: String { string(en: "No times this month", tr: "Bu ay vakit yok", ar: "لا مواقيت هذا الشهر") }
    static var noTimesMonthBody: String { string(en: "Prayer times could not be loaded for this month.", tr: "Bu ayın vakitleri yüklenemedi.", ar: "تعذر تحميل مواقيت هذا الشهر.") }

    static func prayerAlertTitle(_ name: String) -> String {
        string(en: "Time for \(name)", tr: "\(name) vakti", ar: "حان وقت \(name)")
    }

    static func prayerAlertBody(_ name: String) -> String {
        string(en: "It's time for \(name).", tr: "\(name) namazı vakti.", ar: "حان وقت صلاة \(name).")
    }

    static var jumuahTitle: String { string(en: "Jumu'ah Mubarak", tr: "Cuma Mübarek Olsun", ar: "جمعة مباركة") }
    static var jumuahBody: String {
        string(
            en: "It's Friday — don't forget Surah al-Kahf and the Jumu'ah prayer.",
            tr: "Cuma — Kehf suresini ve cuma namazını unutma.",
            ar: "إنه يوم الجمعة — لا تنسَ سورة الكهف وصلاة الجمعة."
        )
    }

    static var esmaNoResultsBody: String {
        string(
            en: "Try another spelling, or search in Arabic.",
            tr: "Farklı bir yazım dene veya Arapça ara.",
            ar: "جرّب كتابة أخرى أو ابحث بالعربية."
        )
    }
    static var noUpcomingDays: String { string(en: "No upcoming days yet", tr: "Yaklaşan gün yok", ar: "لا أيام قادمة بعد") }
    static var noUpcomingDaysBody: String {
        string(
            en: "Holy days appear once prayer times load.",
            tr: "Dini günler vakitler yüklenince görünür.",
            ar: "تظهر الأيام الدينية بعد تحميل المواقيت."
        )
    }
    static var shareHadith: String { string(en: "Daily Hadith", tr: "Günün hadisi", ar: "حديث اليوم") }

    // MARK: - Settings copy

    static var settingsPrayer: String { string(en: "Prayer", tr: "Namaz", ar: "الصلاة") }
    static var settingsLocation: String { string(en: "Location", tr: "Konum", ar: "الموقع") }
    static var settingsCurrent: String { string(en: "Current", tr: "Şu an", ar: "الحالي") }
    static var usePreciseLocation: String { string(en: "Use precise location", tr: "Hassas konumu kullan", ar: "استخدم الموقع الدقيق") }
    static var clearManualOverride: String { string(en: "Clear manual override", tr: "Manuel konumu temizle", ar: "مسح التعيين اليدوي") }
    static var settingsAppearance: String { string(en: "Appearance", tr: "Görünüm", ar: "المظهر") }
    static var settingsTheme: String { string(en: "Theme", tr: "Tema", ar: "السمة") }
    static var themeAuto: String { string(en: "Auto", tr: "Otomatik", ar: "تلقائي") }
    static var themeDark: String { string(en: "Dark", tr: "Koyu", ar: "داكن") }
    static var themeLight: String { string(en: "Light", tr: "Açık", ar: "فاتح") }
    static var ramadanTheme: String { string(en: "Ramadan theme", tr: "Ramazan teması", ar: "سمة رمضان") }
    static var dhikrShader: String { string(en: "Texture", tr: "Doku", ar: "النسيج") }
    static var shaderNone: String { string(en: "None", tr: "Yok", ar: "بدون") }
    static var shaderSilk: String { string(en: "Emerald Silk", tr: "Zümrüt İpek", ar: "حرير الزمرد") }
    static var shaderCaustics: String { string(en: "Mosque Light", tr: "Cami Nuru", ar: "نور المسجد") }
    static var shaderAurora: String { string(en: "Aurora Veil", tr: "Kutup Perdesi", ar: "حجاب الشفق") }
    static var shaderEverywhere: String { string(en: "Use on all screens", tr: "Tüm ekranlarda kullan", ar: "استخدم في كل الشاشات") }
    static var accentColor: String { string(en: "Accent", tr: "Vurgu", ar: "اللون") }
    static var accentEmerald: String { string(en: "Emerald", tr: "Zümrüt", ar: "زمرد") }
    static var accentBrass: String { string(en: "Brass", tr: "Pirinç", ar: "نحاس") }
    static var accentViolet: String { string(en: "Violet", tr: "Menekşe", ar: "بنفسجي") }
    static var settingsAbout: String { string(en: "About", tr: "Hakkında", ar: "حول") }
    static var settingsVersion: String { string(en: "Version", tr: "Sürüm", ar: "الإصدار") }
    static var settingsAboutBody: String {
        string(
            en: "Prayer times: Aladhan API · Hadith: bundled curated collection · No ads, no tracking, ever.",
            tr: "Namaz vakitleri: Aladhan API · Hadis: seçilmiş derleme · Reklam yok, takip yok.",
            ar: "المواقيت: Aladhan · الحديث: مجموعة مختارة · بلا إعلانات ولا تتبع."
        )
    }
    static var resetOnboarding: String { string(en: "Reset onboarding", tr: "Kurulumu sıfırla", ar: "إعادة التهيئة") }
    static func prayerNotification(_ name: String) -> String {
        string(en: "\(name) notification", tr: "\(name) bildirimi", ar: "تنبيه \(name)")
    }
    static var madhabAsr: String { string(en: "Madhab (Asr)", tr: "Mezhep (İkindi)", ar: "المذهب (العصر)") }

    // MARK: - Ramadan hub

    static var iftarIn: String { string(en: "IFTAR IN", tr: "İFTARA", ar: "حتى الإفطار") }
    static var suhoorEndsIn: String { string(en: "SUHOOR ENDS IN", tr: "SAHUR BİTİŞİ", ar: "ينتهي السحور خلال") }
    static var suhoorEndsCaps: String { string(en: "SUHOOR ENDS", tr: "SAHUR BİTİŞ", ar: "نهاية السحور") }
    static var iftarCaps: String { string(en: "IFTAR", tr: "İFTAR", ar: "الإفطار") }
    static var fastingCaps: String { string(en: "FASTING", tr: "ORUÇ", ar: "الصيام") }
    static func ramadanDayOf(_ day: Int) -> String {
        string(en: "Day \(day) of ~29", tr: "\(day). gün / ~29", ar: "اليوم \(day) من ~٢٩")
    }
    static var dailyDuas: String { string(en: "DAILY DUAS", tr: "GÜNLÜK DUALAR", ar: "أدعية اليوم") }
    static var iftarDua: String { string(en: "Iftar Dua", tr: "İftar duası", ar: "دعاء الإفطار") }
    static var suhoorIntention: String { string(en: "Suhoor Intention", tr: "Sahur niyeti", ar: "نية السحور") }
    static var khatamTracker: String { string(en: "KHATAM TRACKER", tr: "HATİM TAKİBİ", ar: "تتبع الختم") }
    static func juzCount(_ n: Int) -> String {
        string(en: "\(n) / 30 juz", tr: "\(n) / 30 cüz", ar: "\(n) / ٣٠ جزء")
    }
    static var logJuz: String { string(en: "Log a juz", tr: "Cüz işaretle", ar: "سجّل جزءاً") }
    static func eidInDays(_ n: Int) -> String {
        if n == 1 {
            return string(en: "Eid al-Fitr in 1 day", tr: "Ramazan Bayramı 1 gün sonra", ar: "عيد الفطر بعد يوم")
        }
        return string(en: "Eid al-Fitr in \(n) days", tr: "Ramazan Bayramı \(n) gün sonra", ar: "عيد الفطر بعد \(n) أيام")
    }
    static var ramadanQuote1: String { string(en: "May Allah accept your fast", tr: "Allah orucunu kabul etsin", ar: "تقبّل الله صيامك") }
    static var ramadanQuote2: String { string(en: "Ramadan Mubarak", tr: "Ramazan mübarek olsun", ar: "رمضان مبارك") }
    static var ramadanQuote3: String { string(en: "The month of mercy", tr: "Rahmet ayı", ar: "شهر الرحمة") }
    static var ramadanQuote4: String { string(en: "Every moment is worship", tr: "Her an ibadet", ar: "كل لحظة عبادة") }
    static var ramadanQuote5: String { string(en: "Patience is half of faith", tr: "Sabır imanın yarısıdır", ar: "الصبر نصف الإيمان") }
}
