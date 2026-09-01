import Foundation

/// Copy owned by the Home surfaces — Today, Times, Qibla, Ramadan, Mosques.
/// Prefixed (`home…`, `tmz…`, `qib…`, `ram…`) so it can never collide with the
/// shared catalogue in `L10n.swift`.
extension L10n {

    // MARK: - Today · day summary

    static var homeTodayCaps: String {
        string(en: "TODAY", tr: "BUGÜN", ar: "اليوم")
    }

    static var homeSummaryCaps: String {
        string(en: "DAY AT A GLANCE", tr: "GÜNÜN ÖZETİ", ar: "ملخص اليوم")
    }

    static func homePrayersLeft(_ count: Int) -> String {
        switch language {
        case .turkish: count == 1 ? "Bugün 1 vakit kaldı" : "Bugün \(count) vakit kaldı"
        case .arabic: "بقيت \(count) صلوات اليوم"
        case .english: count == 1 ? "1 prayer left today" : "\(count) prayers left today"
        default:
            L10nCatalog.plural("%d prayers left today", count)
                ?? (count == 1 ? "1 prayer left today" : "\(count) prayers left today")
        }
    }

    static var homeAllPrayersDone: String {
        string(
            en: "All of today's prayers have passed",
            tr: "Bugünün vakitleri tamamlandı",
            ar: "انقضت جميع صلوات اليوم"
        )
    }

    static func homeDaylight(_ hours: Int, _ minutes: Int) -> String {
        string(
            en: "\(hours) h \(minutes) m of daylight",
            tr: "\(hours) sa \(minutes) dk gündüz",
            ar: "\(hours) س \(minutes) د من النهار"
        )
    }

    static var homeDaylightCaps: String {
        string(en: "DAYLIGHT", tr: "GÜNDÜZ", ar: "النهار")
    }

    static var homeLocatingCity: String {
        string(en: "Finding your city…", tr: "Şehrin bulunuyor…", ar: "جارٍ تحديد مدينتك…")
    }

    // MARK: - Today · prayer log & streak

    static var homeLogCaps: String {
        string(en: "PRAYER LOG", tr: "NAMAZ TAKİBİ", ar: "سجل الصلاة")
    }

    static var homeLogHint: String {
        string(
            en: "Tap a prayer once you have prayed it.",
            tr: "Kıldığın vakte dokunarak işaretle.",
            ar: "انقر على الصلاة بعد أدائها."
        )
    }

    static func homeLogProgress(_ done: Int, _ total: Int) -> String {
        string(en: "\(done) of \(total)", tr: "\(done) / \(total)", ar: "\(done) من \(total)")
    }

    static func homeStreakDays(_ days: Int) -> String {
        switch language {
        case .turkish: days == 1 ? "1 günlük seri" : "\(days) günlük seri"
        case .arabic: "سلسلة \(days) يوم"
        case .english: days == 1 ? "1 day streak" : "\(days) day streak"
        default:
            L10nCatalog.plural("%d day streak", days)
                ?? (days == 1 ? "1 day streak" : "\(days) day streak")
        }
    }

    static var homeStreakStart: String {
        string(en: "Start your streak today", tr: "Serini bugün başlat", ar: "ابدأ سلسلتك اليوم")
    }

    static func homeMarkedPrayed(_ prayer: String) -> String {
        string(en: "\(prayer) marked as prayed", tr: "\(prayer) kılındı olarak işaretlendi", ar: "تم تسجيل \(prayer)")
    }

    static func homeMarkPrayed(_ prayer: String) -> String {
        string(en: "Mark \(prayer) as prayed", tr: "\(prayer) namazını kılındı işaretle", ar: "سجّل صلاة \(prayer)")
    }

    // MARK: - Today · primary action

    static func homeActionMarkPrayed(_ prayer: String) -> String {
        string(en: "I prayed \(prayer)", tr: "\(prayer) namazını kıldım", ar: "أديت صلاة \(prayer)")
    }

    static var homeActionShowQibla: String {
        string(en: "Show the qibla", tr: "Kıbleyi göster", ar: "أظهر القبلة")
    }

    static var homeActionStartDhikr: String {
        string(en: "Start dhikr", tr: "Zikre başla", ar: "ابدأ الذكر")
    }

    // MARK: - Today · week strip

    static var homeWeekCaps: String {
        string(en: "LAST 7 DAYS", tr: "SON 7 GÜN", ar: "آخر ٧ أيام")
    }

    static func homeWeekDayA11y(_ weekday: String, _ done: Int, _ total: Int) -> String {
        string(
            en: "\(weekday): \(done) of \(total) prayers",
            tr: "\(weekday): \(total) vaktin \(done) tanesi",
            ar: "\(weekday): \(done) من \(total) صلوات"
        )
    }

    /// Shown on the log card once Agent W7's `QadaStore` lands.
    static func homeQadaOwed(_ count: Int) -> String {
        switch language {
        case .turkish: "\(count) kaza namazı"
        case .arabic: "\(count) صلاة قضاء"
        case .english: count == 1 ? "1 missed prayer" : "\(count) missed prayers"
        default:
            L10nCatalog.plural("%d missed prayers", count)
                ?? (count == 1 ? "1 missed prayer" : "\(count) missed prayers")
        }
    }

    // MARK: - Today · data provenance

    static var homeOnDeviceBadge: String {
        string(en: "Calculated on device", tr: "Cihazda hesaplandı", ar: "محسوب على الجهاز")
    }

    static func homeLastUpdated(_ when: String) -> String {
        string(en: "Last updated \(when)", tr: "Son güncelleme: \(when)", ar: "آخر تحديث: \(when)")
    }

    static var homeTimesErrorTitle: String {
        string(en: "Times could not be refreshed", tr: "Vakitler yenilenemedi", ar: "تعذر تحديث المواقيت")
    }

    static var homeTimesErrorBody: String {
        string(
            en: "Qibla, dhikr and the Names still work offline.",
            tr: "Kıble, zikirmatik ve Esmaül Hüsna çevrimdışı çalışmaya devam ediyor.",
            ar: "القبلة والذكر وأسماء الله الحسنى تعمل دون اتصال."
        )
    }

    static var homeTimesUnavailableHere: String {
        string(
            en: "No schedule can be produced for this location today.",
            tr: "Bu konum için bugün vakit hesaplanamıyor.",
            ar: "لا يمكن حساب المواقيت لهذا الموقع اليوم."
        )
    }

    // MARK: - Today · misc

    static var homeQuickCaps: String {
        string(en: "QUICK ACTIONS", tr: "HIZLI EYLEMLER", ar: "إجراءات سريعة")
    }

    static var homeMonthlyTimes: String {
        string(en: "Month", tr: "Aylık", ar: "الشهر")
    }

    static func homePrayerEntered(_ prayer: String) -> String {
        string(en: "\(prayer) has begun", tr: "\(prayer) vakti girdi", ar: "دخل وقت \(prayer)")
    }

    static var homePullToRefresh: String {
        string(en: "Pull to refresh", tr: "Yenilemek için çek", ar: "اسحب للتحديث")
    }

    // MARK: - Times

    static var tmzModeDay: String {
        string(en: "Day", tr: "Gün", ar: "يوم")
    }

    static var tmzModeMonth: String {
        string(en: "Month", tr: "Ay", ar: "شهر")
    }

    static var tmzYesterday: String {
        string(en: "Yesterday", tr: "Dün", ar: "أمس")
    }

    static var tmzTomorrow: String {
        string(en: "Tomorrow", tr: "Yarın", ar: "غدًا")
    }

    static var tmzNextCaps: String {
        string(en: "NEXT", tr: "SIRADAKİ", ar: "التالي")
    }

    static var tmzLoadingMonth: String {
        string(en: "Loading the month…", tr: "Ay yükleniyor…", ar: "جارٍ تحميل الشهر…")
    }

    static var tmzOpenFullMonth: String {
        string(en: "Full month", tr: "Tüm ay", ar: "الشهر كامل")
    }

    static var tmzScheduleCaps: String {
        string(en: "SCHEDULE", tr: "VAKİTLER", ar: "المواقيت")
    }

    // MARK: - Qibla

    static var qibCalibrateTitle: String {
        string(en: "Compass needs calibrating", tr: "Pusula kalibrasyon istiyor", ar: "البوصلة تحتاج معايرة")
    }

    static var qibCalibrateBody: String {
        string(
            en: "Move the phone in a figure-eight, away from metal and magnets.",
            tr: "Telefonu sekiz çizerek çevir; metal ve mıknatıslardan uzak tut.",
            ar: "حرّك الهاتف على شكل رقم ثمانية بعيدًا عن المعادن والمغناطيس."
        )
    }

    static func qibAccuracy(_ degrees: Int) -> String {
        string(en: "±\(degrees)° accuracy", tr: "±\(degrees)° doğruluk", ar: "دقة ±\(degrees)°")
    }

    static var qibAccuracyLow: String {
        string(
            en: "Reading is unreliable right now",
            tr: "Şu an ölçüm güvenilir değil",
            ar: "القراءة غير موثوقة الآن"
        )
    }

    static func qibTurnRight(_ degrees: Int) -> String {
        string(en: "Turn right \(degrees)°", tr: "\(degrees)° sağa dön", ar: "استدر يمينًا \(degrees)°")
    }

    static func qibTurnLeft(_ degrees: Int) -> String {
        string(en: "Turn left \(degrees)°", tr: "\(degrees)° sola dön", ar: "استدر يسارًا \(degrees)°")
    }

    static var qibHeadingCaps: String {
        string(en: "HEADING", tr: "YÖN", ar: "الاتجاه")
    }

    static var qibDistanceCaps: String {
        string(en: "TO MAKKAH", tr: "MEKKE'YE", ar: "إلى مكة")
    }

    // MARK: - Mosques

    static var msqTitle: String {
        string(en: "Mosques nearby", tr: "Yakındaki camiler", ar: "المساجد القريبة")
    }

    static var msqSearchArea: String {
        string(en: "Search this area", tr: "Bu alanda ara", ar: "ابحث في هذه المنطقة")
    }

    static var msqSearching: String {
        string(en: "Searching…", tr: "Aranıyor…", ar: "جارٍ البحث…")
    }

    static var msqNoneFound: String {
        string(en: "No mosques found nearby", tr: "Yakında cami bulunamadı", ar: "لم يتم العثور على مساجد قريبة")
    }

    static var msqDirections: String {
        string(en: "Directions", tr: "Yol tarifi", ar: "الاتجاهات")
    }

    static var msqCall: String {
        string(en: "Call", tr: "Ara", ar: "اتصل")
    }

    static var msqJumuahToday: String {
        string(en: "Jumu'ah today", tr: "Bugün Cuma", ar: "الجمعة اليوم")
    }

    static func msqWalkMinutes(_ minutes: Int) -> String {
        string(en: "\(minutes) min walk", tr: "\(minutes) dk yürüme", ar: "\(minutes) دقيقة سيرًا")
    }

    // MARK: - Ramadan · fasting log

    static var ramFastingLogCaps: String {
        string(en: "FASTING LOG", tr: "ORUÇ TAKİBİ", ar: "سجل الصيام")
    }

    static func ramFastedDays(_ count: Int) -> String {
        switch language {
        case .turkish: "\(count) gün oruç"
        case .arabic: "\(count) يوم صيام"
        case .english: count == 1 ? "1 day fasted" : "\(count) days fasted"
        default:
            L10nCatalog.plural("%d days fasted", count)
                ?? (count == 1 ? "1 day fasted" : "\(count) days fasted")
        }
    }

    static var ramMarkFastToday: String {
        string(en: "I fasted today", tr: "Bugün oruç tuttum", ar: "صمت اليوم")
    }

    static var ramFastedTodayDone: String {
        string(en: "Today is logged", tr: "Bugün işaretlendi", ar: "تم تسجيل اليوم")
    }

    static func ramFastDayA11y(_ day: Int, _ fasted: Bool) -> String {
        let state = fasted
            ? string(en: "fasted", tr: "oruçlu", ar: "صائم")
            : string(en: "not logged", tr: "işaretlenmedi", ar: "غير مسجل")
        return string(en: "Day \(day), \(state)", tr: "\(day). gün, \(state)", ar: "اليوم \(day)، \(state)")
    }
}
