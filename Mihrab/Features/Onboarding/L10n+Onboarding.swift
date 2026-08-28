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
        string(en: "Welcome to Revak", tr: "Revak'a hoş geldin", ar: "مرحباً بك في رواق")
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

    /// Now a hand-off to the dedicated Asr step rather than a caption under a
    /// segmented madhab picker.
    static var obMadhabHint: String {
        string(
            en: "The madhab changes only the Asr time — we'll ask about that next, with both real times.",
            tr: "Mezhep yalnızca ikindi vaktini değiştirir — bunu sıradaki adımda iki gerçek saatle birlikte soracağız.",
            ar: "المذهب يغيّر وقت العصر فقط — سنسألك عنه في الخطوة التالية مع الوقتين الحقيقيين."
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

    static var obPlusTitle: String { string(en: "Revak Plus", tr: "Revak Plus", ar: "رواق بلس") }

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

    static var obFinish: String { string(en: "Enter Revak", tr: "Revak'a gir", ar: "ادخل رواق") }

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

// MARK: - W2 additions — the Asr / madhab question
//
// Wave 1 verified a real contradiction: Diyanet publishes Asr with the
// majority (Shafi) rule, while the app hands a Turkish device the Hanafi
// default. Picking one silently is where "the times are wrong" reviews start,
// so we ask — with both real times on screen and without taking a side.
extension L10n {

    static var obAsrTitle: String {
        string(
            en: "When does Asr begin for you?",
            tr: "İkindi senin için ne zaman başlar?",
            ar: "متى يبدأ العصر عندك؟"
        )
    }

    static var obAsrBody: String {
        string(
            en: "Scholars differ on the shadow length that marks Asr. Both readings are valid — pick the one you follow.",
            tr: "İkindiyi belirleyen gölge uzunluğunda âlimler ihtilaf etmiştir. İkisi de meşrudur — takip ettiğini seç.",
            ar: "اختلف العلماء في طول الظل الذي يبدأ به العصر. كلا القولين معتبر — اختر ما تتبعه."
        )
    }

    /// Shown only when the user actually picked Diyanet on the previous step —
    /// otherwise we must not claim the calendar match.
    static var obAsrOptionDiyanetTitle: String {
        string(
            en: "Match the Diyanet calendar",
            tr: "Diyanet takvimiyle birebir aynı olsun",
            ar: "مطابقة تقويم ديانت"
        )
    }

    static var obAsrOptionMajorityTitle: String {
        string(
            en: "Majority rule (shadow 1×)",
            tr: "Çoğunluk kuralı (gölge 1×)",
            ar: "قول الجمهور (الظل ١×)"
        )
    }

    static var obAsrOptionMajorityDetail: String {
        string(
            en: "Asr starts when a shadow equals the object's own length. This is the rule the Diyanet calendar is printed with.",
            tr: "Gölge, cismin kendi boyu kadar olduğunda ikindi girer. Diyanet takvimi bu kuralla yayımlanır.",
            ar: "يبدأ العصر حين يصير ظل الشيء مثله. وبهذا القول يُطبع تقويم ديانت."
        )
    }

    static var obAsrOptionMajorityDetailNonDiyanet: String {
        string(
            en: "Asr starts when a shadow equals the object's own length — the Shafi, Maliki and Hanbali position.",
            tr: "Gölge, cismin kendi boyu kadar olduğunda ikindi girer — Şafi, Maliki ve Hanbeli görüşü.",
            ar: "يبدأ العصر حين يصير ظل الشيء مثله — قول الشافعية والمالكية والحنابلة."
        )
    }

    static var obAsrOptionHanafiTitle: String {
        string(
            en: "Hanafi Asr (shadow 2×)",
            tr: "Hanefi ikindi (gölge 2×)",
            ar: "العصر الحنفي (الظل ٢×)"
        )
    }

    static var obAsrOptionHanafiDetail: String {
        string(
            en: "Asr starts when a shadow reaches twice the object's length, so it begins later.",
            tr: "Gölge, cismin iki katına ulaştığında ikindi girer; yani daha geç başlar.",
            ar: "يبدأ العصر حين يبلغ الظل مثليه، فيدخل متأخرًا."
        )
    }

    static func obAsrDifference(_ minutes: Int) -> String {
        string(
            en: "Today the two are \(minutes) minutes apart.",
            tr: "Bugün ikisi arasında \(minutes) dakika fark var.",
            ar: "الفرق بينهما اليوم \(minutes) دقيقة."
        )
    }

    static var obAsrSameToday: String {
        string(
            en: "Today both land on the same minute here.",
            tr: "Bugün burada ikisi de aynı dakikaya denk geliyor.",
            ar: "اليوم يقع القولان على الدقيقة نفسها هنا."
        )
    }

    static func obAsrReferenceNote(_ city: String) -> String {
        string(
            en: "Example times for \(city) — we don't know your location yet. Once it's set you'll see your own.",
            tr: "Örnek: \(city) için bugünkü saatler — konumun henüz belli değil. Belli olunca kendi saatlerini göreceksin.",
            ar: "أوقات نموذجية لـ\(city) — موقعك غير معروف بعد. عند تحديده سترى أوقاتك."
        )
    }

    static var obAsrUnavailable: String {
        string(
            en: "Times will appear here once your location is known.",
            tr: "Konumun belli olduğunda saatler burada görünecek.",
            ar: "ستظهر الأوقات هنا بعد تحديد موقعك."
        )
    }

    static var obAsrChangeLater: String {
        string(
            en: "You can change this any time in Settings › Prayer times.",
            tr: "Bunu istediğin an Ayarlar › Namaz vakitleri'nden değiştirebilirsin.",
            ar: "يمكنك تغيير ذلك في أي وقت من الإعدادات › مواقيت الصلاة."
        )
    }

    static var obAsrTodayLabel: String {
        string(en: "Asr today", tr: "Bugün ikindi", ar: "العصر اليوم")
    }

    // MARK: Feature tour — the wave 1 features, named without adding a step

    static var obTourMoreTitle: String {
        string(en: "And more inside", tr: "Ve içinde dahası var", ar: "والمزيد بالداخل")
    }

    static var obTourMoreBody: String {
        string(
            en: "Qada prayer tracking, a zakat calculator, several cities at once, and your choice of adhan voice.",
            tr: "Kaza namazı takibi, zekât hesaplayıcı, aynı anda birden fazla şehir ve ezan sesi seçimi.",
            ar: "تتبّع الصلوات الفائتة، حاسبة الزكاة، عدة مدن في آنٍ واحد، واختيار صوت الأذان."
        )
    }
}
