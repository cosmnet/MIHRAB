import Foundation

/// Copy for the multiple-cities feature *and* the iCloud sync section
/// (`Mihrab/Core/Sync/`). Kept in one file so W4's strings stay in one place.
/// Every key is prefixed `cities…` / `sync…` so it can never collide.
extension L10n {

    // MARK: - Cities

    static var citiesTitle: String {
        string(en: "Cities", tr: "Şehirler", ar: "المدن")
    }

    static var citiesSectionTitle: String {
        string(en: "Location", tr: "Konum", ar: "الموقع")
    }

    static var citiesSectionSaved: String {
        string(en: "Your cities", tr: "Şehirlerin", ar: "مدنك")
    }

    static var citiesSectionAdd: String {
        string(en: "Add a city", tr: "Şehir ekle", ar: "إضافة مدينة")
    }

    static var citiesCurrentLocation: String {
        string(en: "Current location", tr: "Mevcut konum", ar: "الموقع الحالي")
    }

    static var citiesNoneSelected: String {
        string(en: "Not set", tr: "Seçilmedi", ar: "غير محدد")
    }

    static var citiesEmpty: String {
        string(
            en: "No cities yet. Search below to add one.",
            tr: "Henüz şehir yok. Aşağıdan arayarak ekleyebilirsin.",
            ar: "لا توجد مدن بعد. ابحث أدناه لإضافة واحدة."
        )
    }

    static var citiesEdit: String { string(en: "Edit", tr: "Düzenle", ar: "تحرير") }
    static var citiesDoneEditing: String { string(en: "Done", tr: "Bitti", ar: "تم") }

    static var citiesSearchPlaceholder: String {
        string(en: "City name", tr: "Şehir adı", ar: "اسم المدينة")
    }

    static var citiesSearchAction: String {
        string(en: "Search online", tr: "Çevrimiçi ara", ar: "بحث عبر الإنترنت")
    }

    static var citiesSearchHint: String {
        string(
            en: "Type at least two letters to search.",
            tr: "Aramak için en az iki harf yaz.",
            ar: "اكتب حرفين على الأقل للبحث."
        )
    }

    static var citiesActivateHint: String {
        string(
            en: "Use this city for prayer times.",
            tr: "Namaz vakitleri için bu şehri kullan.",
            ar: "استخدم هذه المدينة لمواقيت الصلاة."
        )
    }

    static var citiesAddHint: String {
        string(en: "Add to your cities.", tr: "Şehirlerine ekle.", ar: "أضف إلى مدنك.")
    }

    static var citiesSettingsHint: String {
        string(
            en: "Manage the cities you follow.",
            tr: "Takip ettiğin şehirleri yönet.",
            ar: "أدر المدن التي تتابعها."
        )
    }

    static var citiesUpgradePrompt: String {
        string(
            en: "Follow as many cities as you like with Revak Plus — family abroad, a trip next week, the mosque you grew up near.",
            tr: "Revak Plus ile dilediğin kadar şehri takip et — yurt dışındaki ailen, gelecek haftaki yolculuğun, büyüdüğün mahallenin camisi.",
            ar: "تابع ما شئت من المدن مع رواق بلس — أهلك في الخارج، رحلة الأسبوع القادم، مسجد حيّك."
        )
    }

    static func citiesFreeTierFooter(_ limit: Int, remaining: Int) -> String {
        if remaining > 0 {
            return string(
                en: "Free plan: \(limit) city. \(remaining) slot left.",
                tr: "Ücretsiz plan: \(limit) şehir. \(remaining) hak kaldı.",
                ar: "الخطة المجانية: \(limit) مدينة. بقي \(remaining)."
            )
        }
        return string(
            en: "Free plan: \(limit) city. Revak Plus removes the limit.",
            tr: "Ücretsiz plan: \(limit) şehir. Revak Plus sınırı kaldırır.",
            ar: "الخطة المجانية: \(limit) مدينة. رواق بلس يزيل الحد."
        )
    }

    static func citiesFreeTierNote(_ limit: Int) -> String {
        string(
            en: "The free plan follows \(limit) city — wherever you are.",
            tr: "Ücretsiz plan \(limit) şehri takip eder — bulunduğun yeri.",
            ar: "تتابع الخطة المجانية \(limit) مدينة — حيث أنت."
        )
    }

    static func citiesLimitReachedMessage(_ limit: Int) -> String {
        string(
            en: "The free plan holds \(limit) city. Revak Plus lets you keep as many as you like.",
            tr: "Ücretsiz plan \(limit) şehir tutar. Revak Plus ile dilediğin kadar ekleyebilirsin.",
            ar: "تحتفظ الخطة المجانية بـ\(limit) مدينة. مع رواق بلس أضف ما شئت."
        )
    }

    static func citiesDuplicateMessage(_ name: String) -> String {
        string(
            en: "\(name) is already in your list.",
            tr: "\(name) zaten listende.",
            ar: "\(name) موجودة بالفعل في قائمتك."
        )
    }

    // MARK: - iCloud sync

    static var syncSectionTitle: String {
        string(en: "iCloud", tr: "iCloud", ar: "iCloud")
    }

    static var syncToggleTitle: String {
        string(en: "Sync with iCloud", tr: "iCloud ile eşitle", ar: "المزامنة مع iCloud")
    }

    static var syncStatusLabel: String {
        string(en: "Status", tr: "Durum", ar: "الحالة")
    }

    static var syncStatusOff: String {
        string(en: "Off", tr: "Kapalı", ar: "معطّلة")
    }

    static var syncStatusActive: String {
        string(en: "Syncing", tr: "Eşitleniyor", ar: "تتم المزامنة")
    }

    static var syncStatusChecking: String {
        string(en: "Checking…", tr: "Kontrol ediliyor…", ar: "جارٍ التحقق…")
    }

    static var syncStatusNotEntitled: String {
        string(en: "Paused — Plus ended", tr: "Duraklatıldı — Plus bitti", ar: "متوقفة — انتهى «بلس»")
    }

    static var syncStatusNoAccount: String {
        string(en: "No iCloud account", tr: "iCloud hesabı yok", ar: "لا يوجد حساب iCloud")
    }

    static var syncStatusRestricted: String {
        string(en: "Restricted on this device", tr: "Bu cihazda kısıtlı", ar: "مقيّدة على هذا الجهاز")
    }

    static var syncErrorUnknown: String {
        string(
            en: "iCloud status unavailable",
            tr: "iCloud durumu alınamadı",
            ar: "تعذّر معرفة حالة iCloud"
        )
    }

    static var syncErrorTemporary: String {
        string(
            en: "iCloud temporarily unavailable",
            tr: "iCloud geçici olarak kullanılamıyor",
            ar: "iCloud غير متاح مؤقتًا"
        )
    }

    static var syncLastSynced: String {
        string(en: "Last synced", tr: "Son eşitleme", ar: "آخر مزامنة")
    }

    static var syncNow: String {
        string(en: "Sync now", tr: "Şimdi eşitle", ar: "زامن الآن")
    }

    static var syncRelaunchNote: String {
        string(
            en: "Reopen Revak to finish switching iCloud sync.",
            tr: "iCloud eşitlemesinin tamamlanması için Revak'ı yeniden aç.",
            ar: "أعد فتح رواق لإكمال تبديل مزامنة iCloud."
        )
    }

    static var syncFooterGeneral: String {
        string(
            en: "Dhikr sessions, saved hadith, khatam progress, prayer and fasting marks are kept in your private iCloud database. Nobody else can read them — not even us.",
            tr: "Zikir oturumların, kaydettiğin hadisler, hatim ilerlemen, namaz ve oruç işaretlerin özel iCloud veritabanında tutulur. Kimse okuyamaz — biz bile.",
            ar: "تُحفظ جلسات الذكر والأحاديث المحفوظة وتقدّم الختمة وعلامات الصلاة والصوم في قاعدة بيانات iCloud الخاصة بك. لا أحد يستطيع قراءتها — ولا نحن."
        )
    }

    static var syncFooterNoAccount: String {
        string(
            en: "Sign in to iCloud in Settings to turn this on. Your data stays on this device until you do.",
            tr: "Bunu açmak için Ayarlar'dan iCloud'a giriş yap. O zamana kadar verilerin bu cihazda kalır.",
            ar: "سجّل الدخول إلى iCloud من الإعدادات لتفعيل هذا. تبقى بياناتك على هذا الجهاز حتى ذلك الحين."
        )
    }

    static var syncFooterNotEntitled: String {
        string(
            en: "Syncing is paused because Revak Plus ended. Nothing was deleted — your data is still here and in iCloud, and syncing resumes if you subscribe again.",
            tr: "Revak Plus bittiği için eşitleme duraklatıldı. Hiçbir şey silinmedi — verilerin hem burada hem iCloud'da duruyor, yeniden abone olursan eşitleme kaldığı yerden devam eder.",
            ar: "توقّفت المزامنة لانتهاء «رواق بلس». لم يُحذف شيء — بياناتك هنا وفي iCloud، وتستأنف المزامنة إن اشتركت مجددًا."
        )
    }
}
