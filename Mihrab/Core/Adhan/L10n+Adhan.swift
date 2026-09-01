import Foundation

/// Adhan / alarm / notification copy owned by the Core layer.
/// Every key is prefixed `adh…` (adhan + sounds) or `ntf…` (notifications)
/// so it can never collide with the shared catalogue in `L10n.swift`.
extension L10n {

    // MARK: - Sections

    static var adhSectionSound: String {
        string(en: "Adhan & sounds", tr: "Ezan ve sesler", ar: "الأذان والأصوات")
    }

    static var adhSectionPerPrayer: String {
        string(en: "Sound per prayer", tr: "Vakte göre ses", ar: "الصوت لكل صلاة")
    }

    static var adhSectionLibrary: String {
        string(en: "Sound library", tr: "Ses kitaplığı", ar: "مكتبة الأصوات")
    }

    static var ntfSectionAlerts: String {
        string(en: "Reminders", tr: "Hatırlatmalar", ar: "التذكيرات")
    }

    static var ntfSectionExtras: String {
        string(en: "Extra reminders", tr: "Ek hatırlatmalar", ar: "تذكيرات إضافية")
    }

    static var ntfSectionQuiet: String {
        string(en: "Quiet hours", tr: "Sessiz saatler", ar: "ساعات الهدوء")
    }

    // MARK: - Reminder mode

    static var ntfModeTitle: String {
        string(en: "How Revak reminds you", tr: "Revak nasıl hatırlatsın", ar: "كيف يذكّرك رواق")
    }

    static var ntfModeAlarm: String {
        string(en: "Alarm (full adhan)", tr: "Alarm (tam ezan)", ar: "منبّه (أذان كامل)")
    }

    static var ntfModeNotification: String {
        string(en: "Notification", tr: "Bildirim", ar: "إشعار")
    }

    static var ntfModeAlarmFooter: String {
        string(
            en: "Alarms play the full adhan and break through Silent mode and Focus. Notifications are quieter and are capped at 30 seconds of sound by iOS.",
            tr: "Alarmlar ezanı tam uzunlukta çalar; Sessiz modu ve Odak'ı deler. Bildirimler daha sakindir ve iOS sesi 30 saniyeyle sınırlar.",
            ar: "تشغّل المنبّهات الأذان كاملاً وتخترق الوضع الصامت والتركيز. الإشعارات أهدأ ويحدّ iOS صوتها بثلاثين ثانية."
        )
    }

    static var ntfAlarmPermissionNeeded: String {
        string(
            en: "Allow alarms so the adhan can sound at prayer time.",
            tr: "Ezanın vakit girdiğinde çalabilmesi için alarm izni verin.",
            ar: "اسمح بالمنبّهات ليؤذَّن في وقت الصلاة."
        )
    }

    static var ntfAlarmPermissionDenied: String {
        string(
            en: "Alarm permission is off, so Revak falls back to notifications. You can turn alarms on in Settings ▸ Revak.",
            tr: "Alarm izni kapalı; Revak bildirimlere düşüyor. Alarmları Ayarlar ▸ Revak'dan açabilirsiniz.",
            ar: "إذن المنبّه مغلق، لذا يعود رواق إلى الإشعارات. يمكنك تفعيل المنبّهات من الإعدادات ▸ رواق."
        )
    }

    static var ntfAlarmLimitReached: String {
        string(
            en: "iOS will not accept any more alarms. Revak kept the nearest prayers as alarms; the rest arrive as notifications.",
            tr: "iOS daha fazla alarm kabul etmiyor. Revak en yakın vakitleri alarm olarak tuttu; kalanlar bildirim olarak gelecek.",
            ar: "لا يقبل iOS مزيدًا من المنبّهات. أبقى رواق أقرب الأوقات منبّهات، والباقي إشعارات."
        )
    }

    static var ntfAlarmUnavailable: String {
        string(
            en: "Alarms are unavailable on this device; Revak uses notifications instead.",
            tr: "Bu cihazda alarm kullanılamıyor; Revak bildirim kullanıyor.",
            ar: "المنبّهات غير متاحة على هذا الجهاز؛ يستخدم رواق الإشعارات."
        )
    }

    static var ntfEnableAlarms: String {
        string(en: "Allow alarms", tr: "Alarmlara izin ver", ar: "السماح بالمنبّهات")
    }

    static var ntfOpenSystemSettings: String {
        string(en: "Open iOS Settings", tr: "iOS Ayarları'nı aç", ar: "فتح إعدادات iOS")
    }

    // MARK: - Alarm alert buttons

    static var adhAlarmStop: String {
        string(en: "Dismiss", tr: "Sustur", ar: "إيقاف")
    }

    static var adhAlarmMarkPrayed: String {
        string(en: "Mark as prayed", tr: "Namazı işaretle", ar: "سجّل الصلاة")
    }

    static func adhAlarmTitle(_ prayer: String) -> String {
        string(en: "\(prayer) — time to pray", tr: "\(prayer) vakti girdi", ar: "حان وقت \(prayer)")
    }

    // MARK: - Notification permission

    static var ntfPermissionTitle: String {
        string(en: "Notification permission", tr: "Bildirim izni", ar: "إذن الإشعارات")
    }

    static var ntfPermissionGranted: String {
        string(en: "Allowed", tr: "İzin verildi", ar: "مسموح")
    }

    static var ntfPermissionDenied: String {
        string(en: "Blocked", tr: "Engelli", ar: "محظور")
    }

    static var ntfPermissionNotDetermined: String {
        string(en: "Not asked yet", tr: "Henüz sorulmadı", ar: "لم يُسأل بعد")
    }

    static var ntfRequestPermission: String {
        string(en: "Allow notifications", tr: "Bildirimlere izin ver", ar: "السماح بالإشعارات")
    }

    // MARK: - Extras

    static var ntfPreReminder: String {
        string(en: "Heads-up before prayer", tr: "Vakit öncesi hatırlatma", ar: "تنبيه قبل الوقت")
    }

    static var ntfPreReminderOff: String {
        string(en: "Off", tr: "Kapalı", ar: "مغلق")
    }

    static func ntfMinutesBefore(_ minutes: Int) -> String {
        string(en: "\(minutes) min before", tr: "\(minutes) dk önce", ar: "قبل \(minutes) د")
    }

    static func ntfPreReminderBody(_ prayer: String, _ minutes: Int) -> String {
        string(
            en: "\(minutes) minutes to \(prayer).",
            tr: "\(prayer) vaktine \(minutes) dakika kaldı.",
            ar: "بقي \(minutes) دقيقة على \(prayer)."
        )
    }

    static var ntfJumuah: String {
        string(en: "Jumu'ah reminder", tr: "Cuma hatırlatması", ar: "تذكير الجمعة")
    }

    static var ntfDailyHadith: String {
        string(en: "Daily hadith", tr: "Günün hadisi", ar: "حديث اليوم")
    }

    static var ntfReligiousDays: String {
        string(en: "Holy days & nights", tr: "Dinî gün ve geceler", ar: "الأيام والليالي المباركة")
    }

    static var ntfKarahat: String {
        string(en: "Makruh-time warning", tr: "Kerahat vakti uyarısı", ar: "تنبيه وقت الكراهة")
    }

    static var ntfKarahatFooter: String {
        string(
            en: "A quiet note shortly before sunrise, solar noon and sunset — the three windows in which voluntary prayer is discouraged.",
            tr: "Güneş doğmadan, tam tepedeyken ve batarken kısa bir not — nafile namazın hoş görülmediği üç vakit.",
            ar: "ملاحظة قصيرة قبيل الشروق والاستواء والغروب — الأوقات الثلاثة التي تُكره فيها النافلة."
        )
    }

    static func ntfKarahatBody(_ window: String) -> String {
        string(
            en: "Makruh time is approaching (\(window)).",
            tr: "Kerahat vakti yaklaşıyor (\(window)).",
            ar: "يقترب وقت الكراهة (\(window))."
        )
    }

    static var ntfKarahatSunrise: String {
        string(en: "sunrise", tr: "güneşin doğuşu", ar: "الشروق")
    }

    static var ntfKarahatZenith: String {
        string(en: "solar noon", tr: "istiva", ar: "الاستواء")
    }

    static var ntfKarahatSunset: String {
        string(en: "sunset", tr: "güneşin batışı", ar: "الغروب")
    }

    static var ntfQuietHours: String {
        string(en: "Silence extra reminders", tr: "Ek hatırlatmaları sustur", ar: "إسكات التذكيرات الإضافية")
    }

    static var ntfQuietFrom: String {
        string(en: "From", tr: "Başlangıç", ar: "من")
    }

    static var ntfQuietTo: String {
        string(en: "To", tr: "Bitiş", ar: "إلى")
    }

    static var ntfQuietFooter: String {
        string(
            en: "Quiet hours never silence the prayer call itself — only the extras above.",
            tr: "Sessiz saatler ezanı asla susturmaz; yalnızca yukarıdaki ek hatırlatmaları kapatır.",
            ar: "لا تُسكت ساعات الهدوء نداء الصلاة نفسه، بل التذكيرات الإضافية فقط."
        )
    }

    static func ntfBudgetFooter(_ used: Int, _ total: Int) -> String {
        string(
            en: "\(used) of \(total) reminder slots in use. iOS keeps only 64 pending notifications, so distant days are dropped first.",
            tr: "\(total) hatırlatma yuvasının \(used) tanesi dolu. iOS yalnızca 64 bekleyen bildirim tutar; önce uzak günler düşer.",
            ar: "\(used) من \(total) خانة تذكير مستخدمة. يحتفظ iOS بـ64 إشعارًا معلّقًا فقط، لذا تُحذف الأيام البعيدة أولًا."
        )
    }

    // MARK: - Sound library

    static var adhSoundSilent: String {
        string(en: "Silent (vibrate only)", tr: "Sessiz (yalnız titreşim)", ar: "صامت (اهتزاز فقط)")
    }

    static var adhSoundSystem: String {
        string(en: "System default", tr: "Sistem sesi", ar: "الصوت الافتراضي")
    }

    static var adhToneBrassBell: String {
        string(en: "Brass bell", tr: "Pirinç çan", ar: "جرس نحاسي")
    }

    static var adhToneGong: String {
        string(en: "Two-tone gong", tr: "İki tonlu gong", ar: "غونغ بنغمتين")
    }

    static var adhToneDawnChime: String {
        string(en: "Dawn chime", tr: "Seher çanı", ar: "رنين الفجر")
    }

    static var adhSameForAll: String {
        string(en: "Same sound for every prayer", tr: "Her vakit için aynı ses", ar: "الصوت نفسه لكل صلاة")
    }

    static var adhFajrHint: String {
        string(
            en: "Fajr traditionally carries its own call — give it a separate sound if you wish.",
            tr: "Sabah ezanı geleneksel olarak farklıdır — dilerseniz ona ayrı bir ses verin.",
            ar: "لأذان الفجر تقليدٌ خاص — يمكنك تخصيص صوت مستقل له."
        )
    }

    static var adhVolume: String {
        string(en: "Preview volume", tr: "Önizleme ses düzeyi", ar: "مستوى الاستماع")
    }

    static var adhVolumeFooter: String {
        string(
            en: "Alarm loudness follows the system alarm volume; this slider only affects previews inside the app.",
            tr: "Alarm sesi sistem alarm düzeyine uyar; bu kaydırıcı yalnızca uygulama içi önizlemeyi etkiler.",
            ar: "يتبع صوت المنبّه مستوى منبّه النظام؛ هذا المؤشر يخصّ الاستماع داخل التطبيق فقط."
        )
    }

    static var adhPreview: String {
        string(en: "Preview", tr: "Önizle", ar: "استماع")
    }

    static var adhStopPreview: String {
        string(en: "Stop preview", tr: "Önizlemeyi durdur", ar: "إيقاف الاستماع")
    }

    static var adhImport: String {
        string(en: "Import a sound from Files…", tr: "Dosyalar'dan ses ekle…", ar: "استيراد صوت من الملفات…")
    }

    static var adhImportFooter: String {
        string(
            en: "Bring your own licensed adhan recording. Alarms play it in full; notifications are trimmed to 30 seconds by iOS.",
            tr: "Kendi lisanslı ezan kaydınızı ekleyin. Alarmlar tam uzunlukta çalar; bildirimleri iOS 30 saniyeye kırpar.",
            ar: "أضف تسجيل أذانك المرخّص. تشغّله المنبّهات كاملًا، بينما يقصّه iOS إلى ثلاثين ثانية في الإشعارات."
        )
    }

    static func adhImportedTrimWarning(_ seconds: Int) -> String {
        string(
            en: "This file is \(seconds) s long. Alarms play all of it; notification sound stops at 30 s.",
            tr: "Bu dosya \(seconds) sn. Alarmlar tamamını çalar; bildirim sesi 30 sn'de durur.",
            ar: "مدة الملف \(seconds) ثانية. تشغّله المنبّهات كاملًا، ويتوقف صوت الإشعار عند 30 ثانية."
        )
    }

    static var adhImportFailedFormat: String {
        string(
            en: "That file could not be read as audio. Use CAF, WAV, AIFF, M4A or MP3.",
            tr: "Bu dosya ses olarak okunamadı. CAF, WAV, AIFF, M4A veya MP3 kullanın.",
            ar: "تعذّرت قراءة الملف كصوت. استخدم CAF أو WAV أو AIFF أو M4A أو MP3."
        )
    }

    static var adhImportFailedCopy: String {
        string(
            en: "The sound could not be saved. Check available storage and try again.",
            tr: "Ses kaydedilemedi. Boş alanı kontrol edip tekrar deneyin.",
            ar: "تعذّر حفظ الصوت. تحقّق من المساحة وحاول مجددًا."
        )
    }

    static var adhImportEmpty: String {
        string(en: "The file contains no audio.", tr: "Dosyada ses yok.", ar: "لا يحتوي الملف على صوت.")
    }

    static var adhDelete: String {
        string(en: "Remove", tr: "Kaldır", ar: "حذف")
    }

    static var adhBundledEmptyNote: String {
        string(
            en: "No adhan recordings are bundled with this build. Import your own, or pick one of the built-in tones.",
            tr: "Bu sürümde gömülü ezan kaydı yok. Kendi kaydınızı ekleyin veya yerleşik tonlardan birini seçin.",
            ar: "لا تسجيلات أذان مضمّنة في هذه النسخة. استورد تسجيلك أو اختر إحدى النغمات المدمجة."
        )
    }
}
