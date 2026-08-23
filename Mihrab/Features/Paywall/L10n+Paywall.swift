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

    static var paywallBenefitThemesTitle: String {
        string(en: "Themes & adhan voices", tr: "Temalar ve ezan sesleri", ar: "السمات وأصوات الأذان")
    }

    static var paywallBenefitThemesBody: String {
        string(
            en: "Emerald, Ramadan and night palettes, plus a choice of muezzins.",
            tr: "Zümrüt, Ramazan ve gece paletleri; dilediğin müezzin sesi.",
            ar: "ألوان الزمرد ورمضان والليل، مع اختيار صوت المؤذن."
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
            en: "Plan your month, find the qibla through the camera, sync across devices.",
            tr: "Ayını planla, kıbleyi kamerayla bul, cihazların arasında yedekle.",
            ar: "خطّط لشهرك، وجد القبلة عبر الكاميرا، وزامن بين أجهزتك."
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
