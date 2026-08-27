import Foundation

/// Copy owned by the Settings surface. Prefixed `set` so it can never collide
/// with the shared catalogue.
extension L10n {

    static var setSearchPrompt: String {
        string(en: "Search settings", tr: "Ayarlarda ara", ar: "ابحث في الإعدادات")
    }

    // MARK: - Groups
    //
    // Settings grew to fifteen sections in one scroll. These are the seven
    // doors that scroll is now behind; searching still flattens all of it.

    static var setGroupPrayer: String {
        string(en: "Prayer & times", tr: "Namaz ve vakitler", ar: "الصلاة والأوقات")
    }

    static var setGroupPrayerSub: String {
        string(en: "Method, madhab, source, offsets", tr: "Yöntem, mezhep, kaynak, sapma", ar: "الطريقة والمذهب والمصدر والفروق")
    }

    static var setGroupReminders: String {
        string(en: "Reminders & adhan", tr: "Hatırlatmalar ve ezan", ar: "التذكيرات والأذان")
    }

    static var setGroupRemindersSub: String {
        string(en: "Notifications, sounds, quiet hours", tr: "Bildirimler, sesler, sessiz saatler", ar: "الإشعارات والأصوات وساعات الصمت")
    }

    static var setGroupLocation: String {
        string(en: "Location & cities", tr: "Konum ve şehirler", ar: "الموقع والمدن")
    }

    static var setGroupLocationSub: String {
        string(en: "Current place and saved cities", tr: "Bulunduğun yer ve kayıtlı şehirler", ar: "الموقع الحالي والمدن المحفوظة")
    }

    static var setGroupWorship: String {
        string(en: "Worship tools", tr: "İbadet araçları", ar: "أدوات العبادة")
    }

    static var setGroupWorshipSub: String {
        string(en: "Qur'an, make-up prayers, zakat, calendar", tr: "Kur'an, kaza, zekât, takvim", ar: "القرآن والقضاء والزكاة والتقويم")
    }

    static var setGroupAppearance: String {
        string(en: "Appearance & language", tr: "Görünüm ve dil", ar: "المظهر واللغة")
    }

    static var setGroupAppearanceSub: String {
        string(en: "Backdrop, colour, texture, language", tr: "Arka plan, renk, doku, dil", ar: "الخلفية واللون والملمس واللغة")
    }

    static var setGroupAccount: String {
        string(en: "Account & sync", tr: "Hesap ve senkron", ar: "الحساب والمزامنة")
    }

    static var setGroupAccountSub: String {
        string(en: "iCloud sync across your devices", tr: "Cihazların arasında iCloud senkronu", ar: "مزامنة iCloud بين أجهزتك")
    }

    static var setGroupApp: String {
        string(en: "App", tr: "Uygulama", ar: "التطبيق")
    }

    static var setGroupAppSub: String {
        string(en: "Guide, privacy, feedback, about", tr: "Rehber, gizlilik, geri bildirim, hakkında", ar: "الدليل والخصوصية والملاحظات وحول")
    }

    static var setNoResults: String {
        string(en: "No settings match", tr: "Eşleşen ayar yok", ar: "لا توجد إعدادات مطابقة")
    }

    // MARK: - Sections

    static var setSectionNotifications: String {
        string(en: "Notifications", tr: "Bildirimler", ar: "الإشعارات")
    }

    static var setSectionLanguage: String {
        string(en: "Language", tr: "Dil", ar: "اللغة")
    }

    static var setSectionGuide: String {
        string(en: "Help & tour", tr: "Yardım ve tur", ar: "المساعدة والجولة")
    }

    static var setSectionData: String {
        string(en: "Data & privacy", tr: "Veri ve gizlilik", ar: "البيانات والخصوصية")
    }

    static var setSectionFeedback: String {
        string(en: "Feedback", tr: "Geri bildirim", ar: "ملاحظات")
    }

    static var setSectionCredits: String {
        string(en: "Sources", tr: "Kaynakça", ar: "المصادر")
    }

    // MARK: - Notifications

    static var setNotificationsMaster: String {
        string(en: "Prayer alerts", tr: "Vakit bildirimleri", ar: "تنبيهات الصلاة")
    }

    static var setNotificationsFooter: String {
        string(
            en: "Alerts are scheduled on this device only. Turn a prayer off to stay silent for that time.",
            tr: "Bildirimler yalnızca bu cihazda planlanır. Bir vakti kapatarak o vakitte sessiz kalabilirsin.",
            ar: "تُجدول التنبيهات على هذا الجهاز فقط. أوقف صلاة معيّنة لتبقى صامتة في وقتها."
        )
    }

    static var setNotificationsAllow: String {
        string(en: "Allow notifications", tr: "Bildirimlere izin ver", ar: "السماح بالإشعارات")
    }

    static var setNotificationsSystem: String {
        string(en: "Sound & banner style", tr: "Ses ve banner stili", ar: "الصوت ونمط الشعار")
    }

    static var setNotificationsSystemHint: String {
        string(
            en: "The alert sound follows your iOS notification settings for Mihrab.",
            tr: "Bildirim sesi, Mihrab için iOS bildirim ayarlarını izler.",
            ar: "يتبع صوت التنبيه إعدادات إشعارات iOS الخاصة بمحراب."
        )
    }

    // MARK: - Location

    static var setLocationFooter: String {
        string(
            en: "Your location never leaves the device except to fetch prayer times.",
            tr: "Konumun, yalnızca namaz vakitlerini almak dışında cihazdan çıkmaz.",
            ar: "لا يغادر موقعك الجهاز إلا لجلب مواقيت الصلاة."
        )
    }

    // MARK: - Language

    static var setLanguageCurrent: String {
        string(en: "App language", tr: "Uygulama dili", ar: "لغة التطبيق")
    }

    static var setLanguageName: String {
        string(en: "English", tr: "Türkçe", ar: "العربية")
    }

    static var setLanguageFooter: String {
        string(
            en: "Mihrab follows your iPhone language. Change it in iOS Settings.",
            tr: "Mihrab, iPhone dilini izler. iOS Ayarları'ndan değiştirebilirsin.",
            ar: "يتبع محراب لغة الآيفون. غيّرها من إعدادات iOS."
        )
    }

    // MARK: - Guide

    static var setReplayTour: String {
        string(en: "Replay the tour", tr: "Turu tekrar izle", ar: "أعد مشاهدة الجولة")
    }

    static var setReplayOnboarding: String {
        string(en: "Show onboarding again", tr: "Onboarding'i tekrar aç", ar: "أعد فتح التعريف")
    }

    static var setGuideFooter: String {
        string(
            en: "Coach marks reappear the next time you open each tab.",
            tr: "İpuçları, her sekmeyi bir sonraki açışında yeniden görünür.",
            ar: "تظهر التلميحات مجدداً عند فتح كل تبويب."
        )
    }

    // MARK: - Data

    static var setDataOnDevice: String {
        string(en: "Everything stays on device", tr: "Her şey cihazda kalır", ar: "كل شيء يبقى على الجهاز")
    }

    static var setDataFooter: String {
        string(
            en: "Counts, favourites and preferences are stored locally and synced only through your own iCloud.",
            tr: "Sayımlar, favoriler ve tercihler cihazda saklanır; yalnızca kendi iCloud'un üzerinden eşitlenir.",
            ar: "تُحفظ الأعداد والمفضلات والتفضيلات محلياً وتُزامن عبر iCloud الخاص بك فقط."
        )
    }

    static var setPrivacyPolicy: String {
        string(en: "Privacy", tr: "Gizlilik", ar: "الخصوصية")
    }

    // MARK: - Feedback

    static var setRateApp: String {
        string(en: "Rate Mihrab", tr: "Mihrab'ı değerlendir", ar: "قيّم محراب")
    }

    static var setSendFeedback: String {
        string(en: "Send feedback", tr: "Geri bildirim gönder", ar: "أرسل ملاحظاتك")
    }

    static var setFeedbackFooter: String {
        string(
            en: "A short note helps more than a star. Both are welcome.",
            tr: "Kısa bir not, bir yıldızdan daha çok yardımcı olur. İkisi de makbul.",
            ar: "ملاحظة قصيرة تساعد أكثر من نجمة. وكلاهما مُرحّب به."
        )
    }

    // MARK: - Credits

    static var setCreditsTitle: String {
        string(en: "Sources & credits", tr: "Kaynakça ve teşekkür", ar: "المصادر والشكر")
    }

    static var setCreditsTimes: String {
        string(en: "Prayer times", tr: "Namaz vakitleri", ar: "مواقيت الصلاة")
    }

    static var setCreditsTimesBody: String {
        string(
            en: "Times come from the Aladhan API, with the calculation method and madhab you choose above. Diyanet is the default in Türkiye.",
            tr: "Vakitler, yukarıda seçtiğin hesaplama yöntemi ve mezhebe göre Aladhan API'sinden gelir. Türkiye'de varsayılan Diyanet'tir.",
            ar: "تأتي المواقيت من واجهة Aladhan وفق طريقة الحساب والمذهب الذي تختاره أعلاه. الافتراضي في تركيا هو ديانت."
        )
    }

    static var setCreditsHadith: String {
        string(en: "Hadith & supplications", tr: "Hadis ve dualar", ar: "الأحاديث والأدعية")
    }

    static var setCreditsHadithBody: String {
        string(
            en: "Texts are drawn from Sahih al-Bukhari, Sahih Muslim and Riyad as-Salihin, bundled with the app and shown with their source.",
            tr: "Metinler Sahih-i Buhârî, Sahih-i Müslim ve Riyâzü's-Sâlihîn'den alınmış, uygulamayla birlikte gelir ve kaynağıyla gösterilir.",
            ar: "النصوص مأخوذة من صحيح البخاري وصحيح مسلم ورياض الصالحين، مضمّنة مع التطبيق وتُعرض مع مصدرها."
        )
    }

    static var setCreditsQibla: String {
        string(en: "Qibla", tr: "Kıble", ar: "القبلة")
    }

    static var setCreditsQiblaBody: String {
        string(
            en: "The bearing is a great-circle calculation to the Kaaba (21.4225° N, 39.8262° E) using the device's true-north heading.",
            tr: "Yön, cihazın gerçek kuzey pusulasıyla Kâbe'ye (21.4225° K, 39.8262° D) büyük daire hesabıyla bulunur.",
            ar: "يُحسب الاتجاه بدائرة عظمى نحو الكعبة (21.4225° شمالاً، 39.8262° شرقاً) باستخدام الشمال الحقيقي للجهاز."
        )
    }

    static var setCreditsFont: String {
        string(en: "Typography", tr: "Tipografi", ar: "الخطوط")
    }

    static var setCreditsFontBody: String {
        string(
            en: "Arabic is set in Amiri Quran (SIL Open Font License). Latin type is the system face.",
            tr: "Arapça metinler Amiri Quran (SIL Open Font License) ile dizildi. Latin harfler sistem yazı tipidir.",
            ar: "النص العربي بخط أميري قرآن (رخصة SIL للخطوط المفتوحة). الحروف اللاتينية بخط النظام."
        )
    }

    static var setCreditsQuran: String {
        string(en: "Qur'an text", tr: "Kur'an metni", ar: "نص القرآن")
    }

    static var setCreditsQuranBody: String {
        string(
            en: "Uthmani text from the Tanzil Project (tanzil.net), used under Creative Commons Attribution 3.0 and reproduced verbatim.",
            tr: "Osmanî metin, Tanzil Project'ten (tanzil.net) Creative Commons Atıf 3.0 lisansıyla, harfi harfine değiştirilmeden alınmıştır.",
            ar: "النص العثماني من مشروع تنزيل (tanzil.net) بموجب رخصة المشاع الإبداعي — النسب 3.0، منقول حرفيًا دون تغيير."
        )
    }

    static var setCreditsOpenSource: String {
        string(en: "Open-source licences", tr: "Açık kaynak lisansları", ar: "تراخيص المصادر المفتوحة")
    }

    static var setCreditsOpenSourceBody: String {
        string(
            en: "Prayer-time astronomy: adhan-swift by Batoul Apps, MIT licence, © 2016 Batoul Apps. Arabic typeface: Amiri by the Amiri Project Authors, SIL Open Font License 1.1. Both notices ship with the app.",
            tr: "Vakit astronomisi: Batoul Apps tarafından geliştirilen adhan-swift, MIT lisansı, © 2016 Batoul Apps. Arapça yazı tipi: Amiri Project yazarlarınca Amiri, SIL Open Font License 1.1. Her iki lisans metni uygulamayla birlikte dağıtılır.",
            ar: "حساب المواقيت: adhan-swift من Batoul Apps برخصة MIT، © 2016 Batoul Apps. الخط العربي: أميري من مؤلفي مشروع أميري برخصة SIL OFL 1.1. يُوزَّع نص الرخصتين مع التطبيق."
        )
    }

    static var setCreditsDisclaimer: String {
        string(
            en: "Prayer times are calculated and may differ by a minute or two from your local mosque. When in doubt, follow your mosque.",
            tr: "Vakitler hesaplamayla bulunur ve mahalle camisinden bir iki dakika farklı olabilir. Tereddütte camini esas al.",
            ar: "المواقيت محسوبة وقد تختلف بدقيقة أو دقيقتين عن مسجدك. عند الشك، اتبع مسجدك."
        )
    }

    // MARK: - About

    static var setMadeWith: String {
        string(en: "Made with care for the ummah", tr: "Ümmet için özenle yapıldı", ar: "صُنع بعناية للأمة")
    }
}
