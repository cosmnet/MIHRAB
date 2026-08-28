import Foundation

/// Copy owned by the App Intents / widget surface. Every name is prefixed `int`
/// (intents) or `wgt` (widgets) so it can never collide with `L10n.swift`.
extension L10n {

    // MARK: - Errors

    static var intErrNoSchedule: String {
        string(
            en: "Revak has no saved prayer times yet. Open the app once so it can calculate them.",
            tr: "Revak'da henüz kayıtlı vakit yok. Hesaplayabilmesi için uygulamayı bir kez aç.",
            ar: "لا توجد مواقيت محفوظة بعد. افتح التطبيق مرة واحدة ليحسبها."
        )
    }

    static var intErrNoLocation: String {
        string(
            en: "Revak does not know where you are. Grant location access or pick a city in the app.",
            tr: "Revak konumunu bilmiyor. Konum izni ver ya da uygulamadan bir şehir seç.",
            ar: "لا يعرف رواق موقعك. امنح إذن الموقع أو اختر مدينة داخل التطبيق."
        )
    }

    static var intErrMissingPrayer: String {
        string(
            en: "That prayer is not in today's saved schedule.",
            tr: "Bu vakit bugünün kayıtlı cetvelinde yok.",
            ar: "هذا الوقت غير موجود في جدول اليوم المحفوظ."
        )
    }

    // MARK: - Duration phrasing

    static func intHoursMinutes(_ hours: Int, _ minutes: Int) -> String {
        string(
            en: "\(hours) h \(minutes) min",
            tr: "\(hours) sa \(minutes) dk",
            ar: "\(hours) س \(minutes) د"
        )
    }

    static func intMinutes(_ minutes: Int) -> String {
        string(en: "\(minutes) min", tr: "\(minutes) dk", ar: "\(minutes) د")
    }

    // MARK: - Next prayer

    static var intNextPrayerTitle: String {
        string(en: "Next Prayer", tr: "Sonraki Vakit", ar: "الوقت التالي")
    }

    static var intNextPrayerDescription: String {
        string(
            en: "Tells you which prayer is next and how long is left.",
            tr: "Sıradaki vaktin hangisi olduğunu ve ne kadar kaldığını söyler.",
            ar: "يخبرك بالصلاة التالية والوقت المتبقي لها."
        )
    }

    static func intNextPrayerAnswer(prayer: String, clock: String, remaining: String) -> String {
        string(
            en: "\(prayer) is at \(clock) — \(remaining) left.",
            tr: "\(prayer) \(clock)'da — \(remaining) kaldı.",
            ar: "\(prayer) في \(clock) — بقي \(remaining)."
        )
    }

    static var intRemainingCaption: String {
        string(en: "Remaining", tr: "Kalan", ar: "المتبقي")
    }

    // MARK: - Today's times

    static var intTodayTimesTitle: String {
        string(en: "Today's Prayer Times", tr: "Bugünün Vakitleri", ar: "مواقيت اليوم")
    }

    static var intTodayTimesDescription: String {
        string(
            en: "Returns every prayer time for today.",
            tr: "Bugünün bütün namaz vakitlerini verir.",
            ar: "يعرض جميع مواقيت الصلاة لهذا اليوم."
        )
    }

    // MARK: - Qibla

    static var intQiblaTitle: String {
        string(en: "Qibla Direction", tr: "Kıble Yönü", ar: "اتجاه القبلة")
    }

    static var intQiblaDescription: String {
        string(
            en: "Gives the compass bearing to the Kaaba from your saved location.",
            tr: "Kayıtlı konumundan Kâbe'ye olan pusula açısını verir.",
            ar: "يعطي زاوية البوصلة نحو الكعبة من موقعك المحفوظ."
        )
    }

    static func intQiblaAnswer(degrees: Int, compass: String, distance: Int) -> String {
        string(
            en: "The Qibla is \(degrees)° (\(compass)), \(distance) km away.",
            tr: "Kıble \(degrees)° (\(compass)) yönünde, \(distance) km uzakta.",
            ar: "القبلة على \(degrees)° (\(compass))، تبعد \(distance) كم."
        )
    }

    static var intQiblaDistanceCaption: String {
        string(en: "Distance to Makkah", tr: "Mekke'ye uzaklık", ar: "المسافة إلى مكة")
    }

    /// Compass points, spoken form.
    static func intCompassPoint(_ index: Int) -> String {
        let en = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let tr = ["K", "KD", "D", "GD", "G", "GB", "B", "KB"]
        let ar = ["شمال", "شمال شرق", "شرق", "جنوب شرق", "جنوب", "جنوب غرب", "غرب", "شمال غرب"]
        let i = ((index % 8) + 8) % 8
        return string(en: en[i], tr: tr[i], ar: ar[i])
    }

    // MARK: - Dhikr

    static var intAddDhikrTitle: String {
        string(en: "Count Dhikr", tr: "Zikir Say", ar: "عدّ الذكر")
    }

    static var intAddDhikrDescription: String {
        string(
            en: "Adds to today's dhikr count without opening the app.",
            tr: "Uygulamayı açmadan bugünkü zikir sayısına ekler.",
            ar: "يضيف إلى عدد الذكر اليوم دون فتح التطبيق."
        )
    }

    static var intAddDhikrAmount: String {
        string(en: "How many", tr: "Kaç adet", ar: "كم عدد")
    }

    static func intAddDhikrAnswer(added: Int, total: Int) -> String {
        string(
            en: "Added \(added). Today's total is \(total).",
            tr: "\(added) eklendi. Bugünkü toplam \(total).",
            ar: "أُضيف \(added). المجموع اليوم \(total)."
        )
    }

    static var intDhikrTodayCaption: String {
        string(en: "Dhikr today", tr: "Bugünkü zikir", ar: "ذكر اليوم")
    }

    static var intStartDhikrTitle: String {
        string(en: "Start Dhikr Session", tr: "Zikir Seti Başlat", ar: "ابدأ جلسة ذكر")
    }

    static var intStartDhikrDescription: String {
        string(
            en: "Opens the counter on a chosen phrase.",
            tr: "Sayacı seçtiğin zikirle açar.",
            ar: "يفتح العدّاد على الذكر المختار."
        )
    }

    static var intStartDhikrPhrase: String {
        string(en: "Dhikr", tr: "Zikir", ar: "الذكر")
    }

    static var intStartDhikrTarget: String {
        string(en: "Target count", tr: "Hedef sayı", ar: "العدد المستهدف")
    }

    // MARK: - Prayer log

    static var intMarkPrayedTitle: String {
        string(en: "Mark Prayer as Prayed", tr: "Namazı Kılındı İşaretle", ar: "تسجيل أداء الصلاة")
    }

    static var intMarkPrayedDescription: String {
        string(
            en: "Marks one of the five daily prayers as prayed for today.",
            tr: "Beş vakit namazdan birini bugün için kılındı işaretler.",
            ar: "يسجّل إحدى الصلوات الخمس كمؤدّاة اليوم."
        )
    }

    static var intMarkPrayedParameter: String {
        string(en: "Prayer", tr: "Vakit", ar: "الصلاة")
    }

    static func intMarkPrayedAnswer(prayer: String, done: Int, total: Int) -> String {
        string(
            en: "\(prayer) marked as prayed — \(done) of \(total) today.",
            tr: "\(prayer) kılındı olarak işaretlendi — bugün \(total) vakitten \(done).",
            ar: "تم تسجيل \(prayer) — \(done) من \(total) اليوم."
        )
    }

    static func intMarkPrayedAlready(prayer: String) -> String {
        string(
            en: "\(prayer) was already marked as prayed today.",
            tr: "\(prayer) bugün zaten kılındı olarak işaretliydi.",
            ar: "\(prayer) مسجّلة بالفعل اليوم."
        )
    }

    // MARK: - Open

    static var intOpenTitle: String {
        string(en: "Open Revak", tr: "Revak'ı Aç", ar: "افتح رواق")
    }

    static var intOpenDescription: String {
        string(
            en: "Opens Revak on a chosen screen.",
            tr: "Revak'ı seçtiğin ekranda açar.",
            ar: "يفتح رواق على الشاشة المختارة."
        )
    }

    static var intOpenParameter: String {
        string(en: "Screen", tr: "Ekran", ar: "الشاشة")
    }

    // MARK: - Entities

    static var intPrayerEntityType: String {
        string(en: "Prayer", tr: "Namaz Vakti", ar: "وقت الصلاة")
    }

    static var intTabEntityType: String {
        string(en: "Revak Screen", tr: "Revak Ekranı", ar: "شاشة رواق")
    }

    static var intCityEntityType: String {
        string(en: "City", tr: "Şehir", ar: "المدينة")
    }

    static var intCurrentLocation: String {
        string(en: "Current Location", tr: "Mevcut Konum", ar: "الموقع الحالي")
    }

    // MARK: - Widgets

    static var wgtDhikrCounterName: String {
        string(en: "Dhikr Counter", tr: "Zikirmatik", ar: "عدّاد الذكر")
    }

    static var wgtDhikrCounterDescription: String {
        string(
            en: "Tap to count without opening Mihrab.",
            tr: "Revak'ı açmadan dokunarak say.",
            ar: "انقر للعد دون فتح التطبيق."
        )
    }

    static var wgtCityTimesName: String {
        string(en: "Prayer Times by City", tr: "Şehre Göre Vakitler", ar: "المواقيت حسب المدينة")
    }

    static var wgtCityTimesDescription: String {
        string(
            en: "Pick which city's prayer times this widget shows.",
            tr: "Bu widget'ın hangi şehrin vakitlerini göstereceğini seç.",
            ar: "اختر المدينة التي يعرض هذا العنصر مواقيتها."
        )
    }

    static var wgtCityParameter: String {
        string(en: "City", tr: "Şehir", ar: "المدينة")
    }

    static var wgtRamadanName: String {
        string(en: "Iftar & Suhoor", tr: "İftar ve Sahur", ar: "الإفطار والسحور")
    }

    static var wgtRamadanDescription: String {
        string(
            en: "Countdown to iftar, then to the end of suhoor.",
            tr: "İftara, sonra sahurun bitişine geri sayım.",
            ar: "عد تنازلي للإفطار ثم لانتهاء السحور."
        )
    }

    static var wgtOpenAppHint: String {
        string(en: "Open Revak", tr: "Revak'ı aç", ar: "افتح رواق")
    }

    static var wgtControlQiblaName: String {
        string(en: "Qibla", tr: "Kıble", ar: "القبلة")
    }

    static var wgtControlQiblaDescription: String {
        string(
            en: "Opens the Qibla compass.",
            tr: "Kıble pusulasını açar.",
            ar: "يفتح بوصلة القبلة."
        )
    }

    static var wgtControlDhikrName: String {
        string(en: "Count Dhikr", tr: "Zikir Say", ar: "عدّ الذكر")
    }

    static var wgtControlDhikrDescription: String {
        string(
            en: "One tap adds one to today's dhikr count.",
            tr: "Tek dokunuş bugünkü zikir sayısını bir artırır.",
            ar: "نقرة واحدة تزيد عدد الذكر اليوم."
        )
    }

    static var wgtControlNextPrayerName: String {
        string(en: "Next Prayer", tr: "Sonraki Vakit", ar: "الوقت التالي")
    }

    static var wgtControlNextPrayerDescription: String {
        string(
            en: "Shows the next prayer and opens the schedule.",
            tr: "Sonraki vakti gösterir, cetveli açar.",
            ar: "يعرض الوقت التالي ويفتح الجدول."
        )
    }

    // MARK: - Live Activity / alarm

    static var wgtAlarmAdhanTitle: String {
        string(en: "Time for prayer", tr: "Namaz vakti", ar: "حان وقت الصلاة")
    }
}
