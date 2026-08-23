import Foundation

/// Paywall, subscription and trial copy. Tone rule for this file: honest and
/// respectful. No countdown pressure, no fake scarcity, no "limited offer",
/// no shaming the "no thanks" button. Worship features are free and we say so.
extension L10n {

    // MARK: - Paywall hero

    static var paywallTitle: String {
        string(
            en: "Mihrab Plus",
            tr: "Mihrab Plus",
            ar: "محراب بلس"
        )
    }

    static var paywallHeadline: String {
        string(
            en: "A calmer, deeper Mihrab",
            tr: "Daha sakin, daha derin bir Mihrab",
            ar: "محراب أهدأ وأعمق"
        )
    }

    static var paywallSubtitle: String {
        string(
            en: "Prayer times, qibla and adhan alerts are free — and always will be. Plus adds the beauty around them.",
            tr: "Namaz vakitleri, kıble ve ezan bildirimleri ücretsiz — ve hep öyle kalacak. Plus, etrafındaki güzelliği ekler.",
            ar: "المواقيت والقبلة وتنبيهات الأذان مجانية — وستبقى كذلك. «بلس» يضيف الجمال من حولها."
        )
    }

    static var paywallFreeForeverNote: String {
        string(
            en: "Worship essentials stay free, forever.",
            tr: "İbadetin temeli her zaman ücretsiz.",
            ar: "أساسيات العبادة مجانية دائمًا."
        )
    }

    // MARK: - Benefits

    static var paywallBenefitWidgetsTitle: String {
        string(en: "Rich widgets & Live Activity", tr: "Zengin widget'lar ve Live Activity", ar: "عناصر واجهة غنية ونشاط مباشر")
    }

    static var paywallBenefitWidgetsBody: String {
        string(
            en: "Every size, every style, on your Lock Screen and Home Screen.",
            tr: "Kilit ve ana ekranın için her boyut ve her stil.",
            ar: "كل الأحجام والأنماط على شاشة القفل والشاشة الرئيسية."
        )
    }

    // NOTE: this used to advertise "a choice of muezzins". The adhan-sound
    // library is not in the binary yet (it is W2's `AdhanLibrary`), and the
    // paywall must not sell what the app cannot do — Guideline 2.3.1. Once
    // `AdhanLibrary` ships and `PremiumFeature.customAdhan` is wired, put the
    // voices back into this line.
    static var paywallBenefitThemesTitle: String {
        string(en: "Themes & backdrops", tr: "Temalar ve arka planlar", ar: "السمات والخلفيات")
    }

    static var paywallBenefitThemesBody: String {
        string(
            en: "Emerald, Ramadan and night palettes, with living shader backdrops.",
            tr: "Zümrüt, Ramazan ve gece paletleri; canlı shader arka planları.",
            ar: "ألوان الزمرد ورمضان والليل، مع خلفيات حيّة."
        )
    }

    static var paywallBenefitDhikrTitle: String {
        string(en: "Unlimited dhikr & full history", tr: "Sınırsız zikir ve tam geçmiş", ar: "ذكر بلا حدود وسجل كامل")
    }

    static var paywallBenefitDhikrBody: String {
        string(
            en: "Your own targets, streaks and statistics kept for good.",
            tr: "Kendi hedeflerin, serilerin ve istatistiklerin kalıcı olarak saklanır.",
            ar: "أهدافك وسلاسلك وإحصاءاتك محفوظة دائمًا."
        )
    }

    static var paywallBenefitEsmaTitle: String {
        string(en: "Esmaül Hüsna collections", tr: "Esmaül Hüsna koleksiyonları", ar: "مجموعات أسماء الله الحسنى")
    }

    static var paywallBenefitEsmaBody: String {
        string(
            en: "Curated sets, meanings and tafakkur readings for each name.",
            tr: "Her isim için derlenmiş setler, anlamlar ve tefekkür metinleri.",
            ar: "مجموعات مختارة ومعانٍ ونصوص تفكّر لكل اسم."
        )
    }

    static var paywallBenefitRamadanTitle: String {
        string(en: "Ramadan planner & AR qibla", tr: "Ramazan planlayıcı ve AR kıble", ar: "مخطط رمضان وقبلة الواقع المعزز")
    }

    static var paywallBenefitRamadanBody: String {
        string(
            en: "Plan your month and find the qibla through the camera.",
            tr: "Ayını planla, kıbleyi kamerayla bul.",
            ar: "خطّط لشهرك وجد القبلة عبر الكاميرا."
        )
    }

    // MARK: - Plans

    static var paywallPlanYearly: String { string(en: "Yearly", tr: "Yıllık", ar: "سنوي") }
    static var paywallPlanMonthly: String { string(en: "Monthly", tr: "Aylık", ar: "شهري") }
    static var paywallPlanLifetime: String { string(en: "Lifetime", tr: "Ömür boyu", ar: "مدى الحياة") }

    static var paywallPeriodYear: String { string(en: "per year", tr: "yılda", ar: "سنويًا") }
    static var paywallPeriodMonth: String { string(en: "per month", tr: "ayda", ar: "شهريًا") }
    static var paywallPeriodOnce: String { string(en: "one-time", tr: "tek seferlik", ar: "دفعة واحدة") }

    static var paywallMostPopular: String {
        string(en: "Most popular", tr: "En popüler", ar: "الأكثر اختيارًا")
    }

    static func paywallSaveBadge(_ percent: Int) -> String {
        string(en: "Save \(percent)%", tr: "%\(percent) tasarruf", ar: "وفّر \(percent)٪")
    }

    static func paywallMonthlyEquivalent(_ price: String) -> String {
        string(en: "≈ \(price) / month", tr: "≈ \(price) / ay", ar: "≈ \(price) / شهر")
    }

    static var paywallLifetimeNote: String {
        string(
            en: "Pay once, keep Plus for as long as Mihrab lives.",
            tr: "Bir kez öde, Mihrab yaşadığı sürece Plus senin olsun.",
            ar: "ادفع مرة واحدة واحتفظ بـ«بلس» ما دام محراب موجودًا."
        )
    }

    // MARK: - CTA & trust

    static var paywallStartTrial: String {
        string(en: "Try 7 days free", tr: "7 gün ücretsiz dene", ar: "جرّب ٧ أيام مجانًا")
    }

    static var paywallSubscribeNow: String {
        string(en: "Continue", tr: "Devam et", ar: "متابعة")
    }

    static var paywallBuyLifetime: String {
        string(en: "Buy once", tr: "Tek seferde al", ar: "شراء لمرة واحدة")
    }

    static func paywallTrialFootnote(_ price: String, period: String) -> String {
        string(
            en: "Free for 7 days, then \(price) \(period). Cancel any time.",
            tr: "7 gün ücretsiz, sonra \(price) \(period). İstediğin an iptal edebilirsin.",
            ar: "مجانًا لمدة ٧ أيام، ثم \(price) \(period). يمكنك الإلغاء في أي وقت."
        )
    }

    static func paywallDirectFootnote(_ price: String, period: String) -> String {
        string(
            en: "\(price) \(period). Cancel any time.",
            tr: "\(price) \(period). İstediğin an iptal edebilirsin.",
            ar: "\(price) \(period). يمكنك الإلغاء في أي وقت."
        )
    }

    static var paywallReminderNote: String {
        string(
            en: "We'll remind you two days before the free week ends.",
            tr: "Ücretsiz hafta bitmeden iki gün önce sana hatırlatırız.",
            ar: "سنذكّرك قبل يومين من انتهاء الأسبوع المجاني."
        )
    }

    static var paywallNotNow: String {
        string(en: "Not now", tr: "Şimdi değil", ar: "ليس الآن")
    }

    static var paywallRestore: String {
        string(en: "Restore purchases", tr: "Satın alımları geri yükle", ar: "استعادة المشتريات")
    }

    static var paywallPrivacy: String {
        string(en: "Privacy Policy", tr: "Gizlilik Politikası", ar: "سياسة الخصوصية")
    }

    static var paywallTerms: String {
        string(en: "Terms of Use", tr: "Kullanım Şartları", ar: "شروط الاستخدام")
    }

    static var paywallClose: String {
        string(en: "Close", tr: "Kapat", ar: "إغلاق")
    }

    static var paywallIndicativePriceNote: String {
        string(
            en: "Prices shown are indicative — the App Store will confirm the exact amount before you pay.",
            tr: "Görünen fiyatlar bilgilendirme amaçlıdır — kesin tutarı ödeme öncesi App Store gösterir.",
            ar: "الأسعار المعروضة إرشادية — سيؤكد App Store المبلغ الدقيق قبل الدفع."
        )
    }

    // MARK: - States & errors

    static var paywallPurchasing: String {
        string(en: "Processing…", tr: "İşleniyor…", ar: "جارٍ المعالجة…")
    }

    static var paywallThankYouTitle: String {
        string(en: "Welcome to Plus", tr: "Plus'a hoş geldin", ar: "أهلًا بك في «بلس»")
    }

    static var paywallThankYouBody: String {
        string(
            en: "May it be a means of good. Everything is unlocked.",
            tr: "Hayırlara vesile olsun. Her şey açıldı.",
            ar: "جعله الله سببًا للخير. تم فتح كل المزايا."
        )
    }

    static var paywallRestoreNothing: String {
        string(
            en: "No previous purchase was found on this Apple Account.",
            tr: "Bu Apple Hesabı'nda önceki bir satın alım bulunamadı.",
            ar: "لم يُعثر على عملية شراء سابقة على حساب Apple هذا."
        )
    }

    static var paywallStoreUnavailable: String {
        string(
            en: "The App Store isn't reachable right now. Please try again later.",
            tr: "App Store'a şu an ulaşılamıyor. Lütfen daha sonra tekrar dene.",
            ar: "تعذّر الوصول إلى App Store الآن. حاول لاحقًا."
        )
    }

    static var paywallVerificationFailed: String {
        string(
            en: "The purchase couldn't be verified.",
            tr: "Satın alım doğrulanamadı.",
            ar: "تعذّر التحقق من عملية الشراء."
        )
    }

    static var paywallCancelled: String {
        string(en: "Purchase cancelled.", tr: "Satın alım iptal edildi.", ar: "أُلغيت عملية الشراء.")
    }

    static var paywallNetworkError: String {
        string(
            en: "No connection. Check your internet and try again.",
            tr: "Bağlantı yok. İnternetini kontrol edip tekrar dene.",
            ar: "لا يوجد اتصال. تحقق من الإنترنت وحاول مجددًا."
        )
    }

    static var paywallGenericError: String {
        string(
            en: "Something went wrong. Please try again.",
            tr: "Bir şeyler ters gitti. Lütfen tekrar dene.",
            ar: "حدث خطأ ما. حاول مرة أخرى."
        )
    }

    // MARK: - Premium features

    static var premiumFeatureWidgets: String {
        string(en: "Advanced widgets", tr: "Gelişmiş widget'lar", ar: "عناصر واجهة متقدمة")
    }

    static var premiumFeatureThemes: String {
        string(en: "Themes", tr: "Temalar", ar: "السمات")
    }

    static var premiumFeatureAdhan: String {
        string(en: "Adhan voices", tr: "Ezan sesleri", ar: "أصوات الأذان")
    }

    static var premiumFeatureDhikrGoals: String {
        string(en: "Custom dhikr goals", tr: "Özel zikir hedefleri", ar: "أهداف ذكر مخصصة")
    }

    static var premiumFeatureDhikrHistory: String {
        string(en: "Full dhikr history", tr: "Tam zikir geçmişi", ar: "سجل الذكر الكامل")
    }

    static var premiumFeatureEsma: String {
        string(en: "Esma collections", tr: "Esma koleksiyonları", ar: "مجموعات الأسماء")
    }

    static var premiumFeatureTafakkur: String {
        string(en: "Tafakkur readings", tr: "Tefekkür metinleri", ar: "نصوص التفكّر")
    }

    static var premiumFeatureRamadan: String {
        string(en: "Ramadan planner", tr: "Ramazan planlayıcı", ar: "مخطط رمضان")
    }

    static var premiumFeatureQiblaAR: String {
        string(en: "AR qibla", tr: "AR kıble", ar: "قبلة الواقع المعزز")
    }

    static var premiumFeatureCities: String {
        string(en: "Multiple cities", tr: "Çoklu şehir", ar: "مدن متعددة")
    }

    static var premiumFeatureBackup: String {
        string(en: "iCloud backup", tr: "iCloud yedekleme", ar: "نسخ احتياطي على iCloud")
    }

    static var premiumFeatureShare: String {
        string(en: "Share cards", tr: "Paylaşım kartları", ar: "بطاقات المشاركة")
    }

    static var premiumLockBadgeLabel: String {
        string(en: "Plus", tr: "Plus", ar: "بلس")
    }

    static var premiumLockedHint: String {
        string(
            en: "Included with Mihrab Plus.",
            tr: "Mihrab Plus ile birlikte gelir.",
            ar: "متاح مع محراب بلس."
        )
    }

    // MARK: - Settings section

    static var subsSectionTitle: String {
        string(en: "Mihrab Plus", tr: "Mihrab Plus", ar: "محراب بلس")
    }

    static var subsStatusLabel: String {
        string(en: "Status", tr: "Durum", ar: "الحالة")
    }

    static var subsStatusFree: String {
        string(en: "Free", tr: "Ücretsiz", ar: "مجاني")
    }

    static var subsStatusMember: String {
        string(en: "Plus member", tr: "Plus üyesi", ar: "عضو بلس")
    }

    static func subsStatusTrial(_ days: Int) -> String {
        string(
            en: days == 1 ? "Trial · 1 day left" : "Trial · \(days) days left",
            tr: "Deneme · \(days) gün kaldı",
            ar: "تجربة · بقي \(days) يوم"
        )
    }

    static var subsStatusTrialEnded: String {
        string(en: "Trial ended", tr: "Deneme sona erdi", ar: "انتهت التجربة")
    }

    static var subsUpgrade: String {
        string(en: "See Mihrab Plus", tr: "Mihrab Plus'ı gör", ar: "استعرض محراب بلس")
    }

    static var subsStartTrial: String {
        string(en: "Start 7-day free trial", tr: "7 günlük ücretsiz denemeyi başlat", ar: "ابدأ تجربة ٧ أيام مجانًا")
    }

    static var subsManage: String {
        string(en: "Manage subscription", tr: "Aboneliği yönet", ar: "إدارة الاشتراك")
    }

    static var subsRestore: String {
        string(en: "Restore purchases", tr: "Satın alımları geri yükle", ar: "استعادة المشتريات")
    }

    static var subsThanks: String {
        string(
            en: "Thank you for supporting Mihrab.",
            tr: "Mihrab'ı desteklediğin için teşekkürler.",
            ar: "شكرًا لدعمك محراب."
        )
    }

    static var subsPlanLabel: String {
        string(en: "Plan", tr: "Plan", ar: "الخطة")
    }

    // MARK: - Trial reminders

    static var trialReminderTitle: String {
        string(en: "Two days of Plus left", tr: "Plus denemene iki gün kaldı", ar: "بقي يومان من «بلس»")
    }

    static var trialReminderBody: String {
        string(
            en: "Your free week ends in two days. Nothing is charged unless you choose a plan.",
            tr: "Ücretsiz haftan iki gün sonra bitiyor. Bir plan seçmedikçe hiçbir ücret alınmaz.",
            ar: "ينتهي أسبوعك المجاني بعد يومين. لن يُخصم شيء ما لم تختر خطة."
        )
    }

    static var trialEndingTitle: String {
        string(en: "Your free week ends today", tr: "Ücretsiz haftan bugün bitiyor", ar: "ينتهي أسبوعك المجاني اليوم")
    }

    static var trialEndingBody: String {
        string(
            en: "Prayer times, qibla and adhan alerts continue free as always.",
            tr: "Namaz vakitleri, kıble ve ezan bildirimleri her zamanki gibi ücretsiz devam eder.",
            ar: "تستمر المواقيت والقبلة وتنبيهات الأذان مجانًا كالمعتاد."
        )
    }
}

// MARK: - W4 additions
//
// Copy required for App Store Guideline 3.1.2 and Schedule 2 §3.8(b): the
// paywall must show, on screen, the subscription name, its length, its price
// (with the billed amount as the most prominent price on the layout), what the
// subscription provides, working Terms of Use and Privacy Policy links, and a
// way to restore purchases.
extension L10n {

    // MARK: Real features added in this wave

    static var paywallBenefitCitiesTitle: String {
        string(en: "Multiple cities & iCloud", tr: "Çoklu şehir ve iCloud", ar: "مدن متعددة وiCloud")
    }

    static var paywallBenefitCitiesBody: String {
        string(
            en: "Follow as many cities as you like, and keep your dhikr, saved hadith and prayer marks in your private iCloud.",
            tr: "Dilediğin kadar şehri takip et; zikirlerin, kaydettiğin hadisler ve namaz işaretlerin özel iCloud'unda dursun.",
            ar: "تابع ما شئت من المدن، واحفظ أذكارك وأحاديثك وعلامات صلاتك في iCloud الخاص بك."
        )
    }

    // MARK: Subscription terms (must be visible on the paywall)

    static var paywallTermsHeading: String {
        string(en: "Subscription details", tr: "Abonelik ayrıntıları", ar: "تفاصيل الاشتراك")
    }

    static var paywallDurationYear: String {
        string(en: "1 year", tr: "1 yıl", ar: "سنة واحدة")
    }

    static var paywallDurationMonth: String {
        string(en: "1 month", tr: "1 ay", ar: "شهر واحد")
    }

    static var paywallDurationLifetime: String {
        string(en: "one-time purchase", tr: "tek seferlik satın alma", ar: "شراء لمرة واحدة")
    }

    /// Name · length · price, followed by the auto-renewal statement.
    static func paywallSubscriptionTerms(name: String, duration: String, price: String) -> String {
        string(
            en: "\(name) · \(duration) · \(price), billed to your Apple Account. It renews automatically for the same price each period unless you cancel at least 24 hours before the period ends. Manage or cancel in Settings › Apple Account › Subscriptions.",
            tr: "\(name) · \(duration) · \(price), Apple Hesabı'ndan tahsil edilir. Dönem bitiminden en az 24 saat önce iptal etmezsen her dönem aynı fiyattan otomatik yenilenir. Ayarlar › Apple Hesabı › Abonelikler'den yönetebilir veya iptal edebilirsin.",
            ar: "\(name) · \(duration) · \(price)، تُخصم من حساب Apple. يتجدد تلقائيًا بالسعر نفسه كل فترة ما لم تُلغِ قبل انتهائها بـ24 ساعة على الأقل. يمكنك الإدارة أو الإلغاء من الإعدادات › حساب Apple › الاشتراكات."
        )
    }

    static func paywallLifetimeTerms(name: String, price: String) -> String {
        string(
            en: "\(name) · one-time purchase · \(price). Not a subscription — nothing renews and there is nothing to cancel.",
            tr: "\(name) · tek seferlik satın alma · \(price). Abonelik değildir — yenilenmez, iptal edilecek bir şey yoktur.",
            ar: "\(name) · شراء لمرة واحدة · \(price). ليس اشتراكًا — لا تجديد ولا شيء لإلغائه."
        )
    }

    static func paywallTrialTerms(price: String, duration: String) -> String {
        string(
            en: "The first 7 days are free. After that it is \(price) per \(duration) unless you cancel during the free week.",
            tr: "İlk 7 gün ücretsiz. Ücretsiz hafta içinde iptal etmezsen sonrasında \(duration) başına \(price).",
            ar: "الأيام السبعة الأولى مجانية. بعدها \(price) لكل \(duration) ما لم تُلغِ خلال الأسبوع المجاني."
        )
    }

    static var paywallIncludedHeading: String {
        string(
            en: "What your subscription includes",
            tr: "Aboneliğinle neler geliyor",
            ar: "ما يشمله اشتراكك"
        )
    }

    // MARK: Trial / member state

    static func paywallTrialDaysLeft(_ days: Int) -> String {
        string(
            en: days == 1 ? "1 day left in your free week" : "\(days) days left in your free week",
            tr: "Ücretsiz haftandan \(days) gün kaldı",
            ar: "بقي \(days) يومًا من أسبوعك المجاني"
        )
    }

    static var paywallTrialEndedTitle: String {
        string(en: "Your free week has ended", tr: "Ücretsiz haftan bitti", ar: "انتهى أسبوعك المجاني")
    }

    static var paywallTrialEndedBody: String {
        string(
            en: "Nothing was deleted. Your dhikr, cities, saved hadith and prayer marks are all still here — the Plus surfaces are simply locked until you subscribe.",
            tr: "Hiçbir şey silinmedi. Zikirlerin, şehirlerin, kaydettiğin hadisler ve namaz işaretlerin duruyor — sadece Plus bölümleri abone olana kadar kilitli.",
            ar: "لم يُحذف شيء. أذكارك ومدنك وأحاديثك وعلامات صلاتك ما زالت هنا — مزايا «بلس» مقفلة فقط حتى تشترك."
        )
    }

    static var paywallAlreadyMember: String {
        string(
            en: "You already have Mihrab Plus.",
            tr: "Mihrab Plus'a zaten sahipsin.",
            ar: "لديك محراب بلس بالفعل."
        )
    }
}

// MARK: - W2 additions — side-by-side plan columns
//
// Roadmap #23 (Bloom + Hevy): three plans in a row, a comparable per-week unit
// price under each billed price, and the selected plan's name inside the CTA.
// Guideline 3.1.2 / Schedule 2 §3.8(b) is unchanged by this: the billed amount
// remains the most prominent price element, and the unit price is marked "≈"
// so it can never be read as the charge.
extension L10n {

    // MARK: Column labels

    static var paywallPerYearShort: String {
        string(en: "per year", tr: "yılda", ar: "سنويًا")
    }

    static var paywallPerMonthShort: String {
        string(en: "per month", tr: "ayda", ar: "شهريًا")
    }

    static var paywallOnceShort: String {
        string(en: "one-time", tr: "tek seferlik", ar: "مرة واحدة")
    }

    /// Comparable unit price. Always prefixed "≈" — it is a derived figure,
    /// not the amount Apple will charge.
    static func paywallPerWeek(_ price: String) -> String {
        string(en: "≈ \(price) / week", tr: "≈ \(price) / hafta", ar: "≈ \(price) / أسبوع")
    }

    static var paywallBilledOnce: String {
        string(en: "Billed once", tr: "Tek ödeme", ar: "دفعة واحدة")
    }

    // MARK: CTA carrying the plan name

    static func paywallStartTrialWithPlan(_ plan: String) -> String {
        string(
            en: "Try \(plan) free for 7 days",
            tr: "\(plan) ile 7 gün ücretsiz dene",
            ar: "جرّب خطة \(plan) مجانًا ٧ أيام"
        )
    }

    static func paywallContinueWithPlan(_ plan: String) -> String {
        string(
            en: "Continue with \(plan)",
            tr: "\(plan) ile devam et",
            ar: "المتابعة بخطة \(plan)"
        )
    }

    static func paywallBuyLifetimeWithPlan(_ plan: String) -> String {
        string(
            en: "Buy \(plan) once",
            tr: "\(plan) erişimi tek seferde al",
            ar: "شراء \(plan) لمرة واحدة"
        )
    }

    // MARK: The free tier, named rather than footnoted

    static var paywallFreeCoreHeading: String {
        string(
            en: "The heart of Mihrab stays free",
            tr: "Mihrab'ın kalbi hep ücretsiz kalacak",
            ar: "قلب محراب يبقى مجانًا"
        )
    }

    static var paywallFreeCoreBody: String {
        string(
            en: "Prayer times, the qibla, adhan alerts, the dhikr counter, the 99 names and the Ramadan imsakiye are never locked — with no ads, on any tier.",
            tr: "Namaz vakitleri, kıble, ezan bildirimleri, zikirmatik, 99 isim ve Ramazan imsakiyesi hiçbir zaman kilitlenmez — hiçbir katmanda reklam da yok.",
            ar: "مواقيت الصلاة والقبلة وتنبيهات الأذان وعدّاد الذكر والأسماء التسعة والتسعون وإمساكية رمضان لا تُقفل أبدًا — وبلا إعلانات في أي مستوى."
        )
    }
}
