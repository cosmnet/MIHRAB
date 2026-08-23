import Foundation

/// Onboarding, splash and coach-mark copy. Owned by the Onboarding feature —
/// every key is prefixed `ob` / `coach` so it never collides with `L10n.swift`.
extension L10n {
    // MARK: - Splash

    static var obSplashSubtitle: String {
        string(
            en: "Prayer, beautifully present.",
            tr: "Namaz, zarifçe yanında.",
            ar: "الصلاة، حاضرة بجمال."
        )
    }

    // MARK: - Chrome

    static var obBack: String { string(en: "Back", tr: "Geri", ar: "رجوع") }
    static var obNext: String { string(en: "Continue", tr: "Devam et", ar: "متابعة") }
    static var obStepFormat: String { string(en: "Step %d of %d", tr: "Adım %d / %d", ar: "الخطوة %d من %d") }

    // MARK: - 1 · Welcome

    static var obWelcomeTitle: String {
        string(en: "Welcome to Mihrab", tr: "Mihrab'a hoş geldin", ar: "مرحباً بك في محراب")
    }

    static var obWelcomeBody: String {
        string(
            en: "Prayer times, qibla, dhikr and the names of Allah — in one calm, quiet place.",
            tr: "Namaz vakitleri, kıble, zikir ve Esmaül Hüsna — tek bir sakin yerde.",
            ar: "مواقيت الصلاة، القبلة، الذكر وأسماء الله الحسنى — في مكان واحد هادئ."
        )
    }

    static var obWelcomeCTA: String { string(en: "Let's begin", tr: "Hadi başlayalım", ar: "لنبدأ") }

    // MARK: - 2 · Name

    static var obNameTitle: String {
        string(en: "What should we call you?", tr: "Sana nasıl hitap edelim?", ar: "بماذا نناديك؟")
    }

    static var obNameBody: String {
        string(
            en: "Only used to greet you inside the app. It never leaves your device.",
            tr: "Yalnızca uygulama içindeki selamlamada kullanılır. Cihazından asla çıkmaz.",
            ar: "يُستخدم فقط لتحيتك داخل التطبيق. ولا يغادر جهازك أبداً."
        )
    }

    static var obNamePlaceholder: String { string(en: "Your name", tr: "Adın", ar: "اسمك") }
    static var obNameSkip: String { string(en: "Not now", tr: "Şimdi değil", ar: "ليس الآن") }

    static func obNameGreeting(_ name: String) -> String {
        string(
            en: "Peace be upon you, \(name).",
            tr: "Selamün aleyküm, \(name).",
            ar: "السلام عليكم يا \(name)."
        )
    }

    // MARK: - 3 · Location

    static var obLocationTitle: String {
        string(en: "Times that match your sky", tr: "Gökyüzüne birebir vakitler", ar: "مواقيت تُطابق سماءك")
    }

    static var obLocationBody: String {
        string(
            en: "Prayer times and the qibla direction depend on exactly where you stand.",
            tr: "Namaz vakitleri ve kıble yönü, tam olarak nerede durduğuna bağlıdır.",
            ar: "تعتمد مواقيت الصلاة واتجاه القبلة على مكانك بالضبط."
        )
    }

    static var obLocationPoint1: String {
        string(
            en: "Used only while the app is open",
            tr: "Yalnızca uygulama açıkken kullanılır",
            ar: "يُستخدم فقط أثناء فتح التطبيق"
        )
    }

    static var obLocationPoint2: String {
        string(
            en: "Never uploaded, never shared",
            tr: "Hiçbir yere gönderilmez, paylaşılmaz",
            ar: "لا يُرفع ولا يُشارك أبداً"
        )
    }

    static var obLocationPoint3: String {
        string(
            en: "You can pick a city by hand instead",
            tr: "İstersen şehri elle de seçebilirsin",
            ar: "يمكنك اختيار المدينة يدوياً بدلاً من ذلك"
        )
    }

    static var obAllowLocationNow: String {
        string(en: "Allow location", tr: "Şimdi izin ver", ar: "السماح بالموقع")
    }

    static var obChooseCity: String {
        string(en: "Choose a city manually", tr: "Şehri elle seç", ar: "اختر المدينة يدوياً")
    }

    static var obLocationDenied: String {
        string(
            en: "Location is off. Pick a city by hand, or enable it later in Settings.",
            tr: "Konum kapalı. Şehri elle seçebilir ya da sonra Ayarlar'dan açabilirsin.",
            ar: "الموقع مُعطّل. اختر مدينة يدوياً أو فعّله لاحقاً من الإعدادات."
        )
    }

    // MARK: - City picker

    static var obCityPickerTitle: String { string(en: "Select city", tr: "Şehir seç", ar: "اختر مدينة") }

    static var obCitySearchPlaceholder: String {
        string(en: "Search for a city", tr: "Şehir ara", ar: "ابحث عن مدينة")
    }

    static var obCitySearchEmpty: String {
        string(
            en: "No match yet — keep typing, then tap Search.",
            tr: "Sonuç yok — yazmaya devam edip Ara'ya dokun.",
            ar: "لا نتائج بعد — تابع الكتابة ثم اضغط بحث."
        )
    }

    static var obCitySearchAction: String { string(en: "Search", tr: "Ara", ar: "بحث") }

    // MARK: - 4 · Method

    static var obMethodTitle: String {
        string(en: "How should we calculate?", tr: "Vakitleri nasıl hesaplayalım?", ar: "كيف نحسب المواقيت؟")
    }

    static var obMethodBody: String {
        string(
            en: "Different authorities use different sun angles. Pick the one your community follows.",
            tr: "Her kurum farklı güneş açıları kullanır. Çevrenin takip ettiğini seç.",
            ar: "تستخدم الجهات زوايا شمس مختلفة. اختر ما يتبعه مجتمعك."
        )
    }

    static var obRecommended: String { string(en: "Recommended", tr: "Önerilen", ar: "موصى به") }

    static var obMadhabHint: String {
        string(
            en: "The madhab only changes the Asr time.",
            tr: "Mezhep yalnızca ikindi vaktini değiştirir.",
            ar: "المذهب يغيّر وقت العصر فقط."
        )
    }

    // MARK: - 5 · Notifications

    static var obNotificationsTitle: String {
        string(en: "A gentle call, on time", tr: "Vaktinde, zarif bir hatırlatma", ar: "تذكير لطيف في وقته")
    }

    static var obNotificationsBody: String {
        string(
            en: "Choose which prayers should reach you. You can change this any time.",
            tr: "Hangi vakitlerde hatırlatalım? Bunu istediğin zaman değiştirebilirsin.",
            ar: "اختر الصلوات التي تريد التذكير بها. يمكنك تغيير ذلك في أي وقت."
        )
    }

    static var obNotificationsGranted: String {
        string(en: "Reminders are on", tr: "Hatırlatmalar açık", ar: "التذكيرات مفعّلة")
    }

    static var obNotificationsDenied: String {
        string(
            en: "Notifications are off. You can enable them later in iOS Settings.",
            tr: "Bildirimler kapalı. Sonradan iOS Ayarları'ndan açabilirsin.",
            ar: "الإشعارات مُعطّلة. يمكنك تفعيلها لاحقاً من إعدادات iOS."
        )
    }

    static var obSelectAll: String { string(en: "Select all", tr: "Tümünü seç", ar: "تحديد الكل") }

    // MARK: - 6 · Feature tour

    static var obTourTitle: String {
        string(en: "Three things to try first", tr: "Önce şu üçünü dene", ar: "ثلاثة أشياء لتجربها أولاً")
    }

    static var obTourTimesTitle: String {
        string(en: "Times & Live Activity", tr: "Vakitler ve Live Activity", ar: "المواقيت والنشاط المباشر")
    }

    static var obTourTimesBody: String {
        string(
            en: "The countdown to the next prayer lives on your Lock Screen and Dynamic Island.",
            tr: "Sonraki vakte kalan süre Kilit Ekranı'nda ve Dynamic Island'da yaşar.",
            ar: "العد التنازلي للصلاة القادمة يظهر على شاشة القفل وجزيرة الشاشة."
        )
    }

    static var obTourQiblaTitle: String { string(en: "Find the qibla", tr: "Kıbleyi bul", ar: "اعثر على القبلة") }

    static var obTourQiblaBody: String {
        string(
            en: "A compass that locks on with a haptic pulse the moment you face the Kaaba.",
            tr: "Kâbe'ye döndüğün an titreşimle kilitlenen bir pusula.",
            ar: "بوصلة تُثبّت باهتزاز لطيف لحظة استقبالك الكعبة."
        )
    }

    static var obTourDhikrTitle: String { string(en: "Dhikr counter", tr: "Zikirmatik", ar: "عدّاد الذكر") }

    static var obTourDhikrBody: String {
        string(
            en: "Tap anywhere to count. Haptics swell as you approach 33, 99 and beyond.",
            tr: "Saymak için ekrana dokun. 33'e, 99'a yaklaştıkça titreşim yükselir.",
            ar: "المس أي مكان للعد. يتصاعد الاهتزاز كلما اقتربت من 33 و99."
        )
    }

    // MARK: - 7 · Mihrab Plus

    static var obPlusTitle: String { string(en: "Mihrab Plus", tr: "Mihrab Plus", ar: "محراب بلس") }

    static var obPlusBody: String {
        string(
            en: "Try everything free for 7 days — no charge until the trial ends.",
            tr: "7 gün boyunca her şeyi ücretsiz dene — deneme bitene kadar ücret yok.",
            ar: "جرّب كل شيء مجاناً لمدة ٧ أيام — بلا رسوم حتى تنتهي التجربة."
        )
    }

    static var obPlusPoint1: String {
        string(en: "Every shader theme & widget", tr: "Tüm shader temaları ve widget'lar", ar: "كل السمات والودجات")
    }

    static var obPlusPoint2: String {
        string(en: "Esmaül Hüsna collections & reflections", tr: "Esmaül Hüsna koleksiyonları ve tefekkür metinleri", ar: "مجموعات الأسماء الحسنى وتأملاتها")
    }

    static var obPlusPoint3: String {
        string(en: "Dhikr statistics & achievements", tr: "Zikir istatistikleri ve başarımlar", ar: "إحصاءات الذكر والإنجازات")
    }

    static var obPlusSeeOptions: String {
        string(en: "See plans", tr: "Planları gör", ar: "عرض الخطط")
    }

    static var obPlusLater: String {
        string(en: "Maybe later", tr: "Belki sonra", ar: "ربما لاحقاً")
    }

    static var obFinish: String { string(en: "Enter Mihrab", tr: "Mihrab'a gir", ar: "ادخل محراب") }

    // MARK: - Coach marks

    static var coachGotIt: String { string(en: "Got it", tr: "Anladım", ar: "فهمت") }
    static var coachNext: String { string(en: "Next", tr: "İleri", ar: "التالي") }
    static var coachSkipTour: String { string(en: "Skip tour", tr: "Turu atla", ar: "تخطي الجولة") }

    static var coachTodayBody: String {
        string(
            en: "Your day at a glance — next prayer, countdown and today's hadith.",
            tr: "Günün özeti — sonraki vakit, geri sayım ve günün hadisi.",
            ar: "يومك بلمحة — الصلاة القادمة والعد التنازلي وحديث اليوم."
        )
    }

    static var coachTimesBody: String {
        string(
            en: "See every prayer of the day, plus the whole month.",
            tr: "Günün tüm vakitlerini ve ayın tamamını buradan gör.",
            ar: "شاهد كل صلوات اليوم، وكذلك الشهر كاملاً."
        )
    }

    static var coachQiblaBody: String {
        string(
            en: "Point your phone and let the compass lock onto the Kaaba.",
            tr: "Telefonu çevir; pusula Kâbe'ye kilitlensin.",
            ar: "وجّه هاتفك ودع البوصلة تُثبّت على الكعبة."
        )
    }

    static var coachEsmaBody: String {
        string(
            en: "The 99 names, hadith and religious days — all in one place.",
            tr: "99 isim, hadisler ve dini günler — hepsi tek yerde.",
            ar: "الأسماء التسعة والتسعون والأحاديث والأيام الدينية في مكان واحد."
        )
    }

    static var coachDhikrBody: String {
        string(
            en: "Count your dhikr with haptics, goals and streaks.",
            tr: "Zikrini titreşim, hedef ve serilerle say.",
            ar: "عُدّ أذكارك بالاهتزاز والأهداف والسلاسل."
        )
    }
}
