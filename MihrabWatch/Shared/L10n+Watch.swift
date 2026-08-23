import Foundation

/// Copy owned by the watch surfaces. Same three languages as the phone.
/// `L10n` itself (`Mihrab/Core/Shared/L10n.swift`) is untouched — this only
/// extends it, per the wave contract.
extension L10n {

    // MARK: - Navigation

    static var wTimes: String { string(en: "Times", tr: "Vakitler", ar: "المواقيت") }
    static var wQibla: String { string(en: "Qibla", tr: "Kıble", ar: "القبلة") }
    static var wDhikr: String { string(en: "Dhikr", tr: "Zikir", ar: "الذكر") }
    static var wLog: String { string(en: "Prayers", tr: "Namaz", ar: "الصلوات") }

    // MARK: - Times

    static var wNextPrayer: String { string(en: "Next", tr: "Sıradaki", ar: "التالية") }
    static var wToday: String { string(en: "Today", tr: "Bugün", ar: "اليوم") }
    static var wNow: String { string(en: "Now", tr: "Şu an", ar: "الآن") }

    static var wWaitingForPhone: String {
        string(en: "Open Mihrab on your iPhone once to send your settings.",
               tr: "Ayarları göndermek için iPhone'unda Mihrab'ı bir kez aç.",
               ar: "افتح مِحراب على الآيفون مرة واحدة لإرسال إعداداتك.")
    }

    static var wNoLocation: String {
        string(en: "No location yet", tr: "Konum yok", ar: "لا يوجد موقع")
    }

    static var wNoLocationDetail: String {
        string(en: "Mihrab needs a location to calculate times. Allow location on the watch, or open the iPhone app.",
               tr: "Vakitleri hesaplamak için konum gerekiyor. Saatte konuma izin ver ya da iPhone uygulamasını aç.",
               ar: "يحتاج مِحراب إلى موقع لحساب المواقيت. اسمح بالموقع على الساعة أو افتح تطبيق الآيفون.")
    }

    static var wPolarUnavailable: String {
        string(en: "At this latitude the sun does not cross the horizon today, so these times cannot be calculated.",
               tr: "Bu enlemde bugün güneş ufku geçmiyor; vakitler hesaplanamıyor.",
               ar: "في هذا العرض الجغرافي لا تعبر الشمس الأفق اليوم، لذا لا يمكن حساب المواقيت.")
    }

    static var wUsingWatchLocation: String {
        string(en: "Watch location", tr: "Saat konumu", ar: "موقع الساعة")
    }

    // MARK: - Qibla

    static var wQiblaAlign: String {
        string(en: "Turn until the mark is at the top",
               tr: "İşaret yukarı gelene kadar dön",
               ar: "استدر حتى تصل العلامة إلى الأعلى")
    }

    static var wQiblaAligned: String {
        string(en: "Facing the Qibla", tr: "Kıbleye dönüksün", ar: "أنت مواجه للقبلة")
    }

    static var wQiblaNoCompass: String {
        string(en: "No compass on this watch", tr: "Bu saatte pusula yok", ar: "لا توجد بوصلة في هذه الساعة")
    }

    static var wQiblaNoCompassDetail: String {
        string(en: "This model has no compass, so the direction cannot be shown live here. Open Qibla on your iPhone.",
               tr: "Bu modelde pusula yok, yön burada canlı gösterilemiyor. Kıble'yi iPhone'unda aç.",
               ar: "لا تحتوي هذه الساعة على بوصلة، لذا لا يمكن عرض الاتجاه مباشرة هنا. افتح القبلة على الآيفون.")
    }

    static var wQiblaMagneticOnly: String {
        string(en: "Magnetic north — may be a few degrees off",
               tr: "Manyetik kuzey — birkaç derece sapabilir",
               ar: "الشمال المغناطيسي — قد ينحرف بضع درجات")
    }

    static func wQiblaBearing(_ degrees: Int) -> String {
        string(en: "Qibla \(degrees)°", tr: "Kıble \(degrees)°", ar: "القبلة \(degrees)°")
    }

    static var wCalibrate: String {
        string(en: "Move your wrist in a figure eight to calibrate",
               tr: "Kalibrasyon için bileğini sekiz çizerek hareket ettir",
               ar: "حرّك معصمك على شكل رقم ثمانية للمعايرة")
    }

    // MARK: - Dhikr

    static var wDhikrCrownHint: String {
        string(en: "Turn the Crown or tap to count",
               tr: "Saymak için Crown'u çevir veya dokun",
               ar: "أدر التاج أو انقر للعد")
    }

    static var wDhikrReset: String { string(en: "Reset", tr: "Sıfırla", ar: "تصفير") }
    static var wDhikrPhrase: String { string(en: "Phrase", tr: "Zikir", ar: "الذكر") }
    static var wDhikrDone: String { string(en: "Target reached", tr: "Hedefe ulaştın", ar: "بلغت الهدف") }

    static func wDhikrTodayTotal(_ total: Int) -> String {
        string(en: "\(total) today", tr: "Bugün \(total)", ar: "\(total) اليوم")
    }

    static func wDhikrProgress(_ count: Int, _ target: Int) -> String {
        "\(count) / \(target)"
    }

    // MARK: - Prayer log

    static var wLogPrompt: String {
        string(en: "Mark what you have prayed", tr: "Kıldıklarını işaretle", ar: "علّم ما صليته")
    }

    static func wLogProgress(_ done: Int, _ total: Int) -> String {
        string(en: "\(done) of \(total)", tr: "\(total) vakitten \(done)", ar: "\(done) من \(total)")
    }

    static var wLogSyncPending: String {
        string(en: "Will sync to iPhone", tr: "iPhone'a aktarılacak", ar: "ستتم المزامنة مع الآيفون")
    }

    // MARK: - Complications

    static var wComplicationNextName: String {
        string(en: "Next Prayer", tr: "Sıradaki Vakit", ar: "الصلاة التالية")
    }

    static var wComplicationNextDescription: String {
        string(en: "Time remaining until the next prayer.",
               tr: "Sıradaki vakte kalan süre.",
               ar: "الوقت المتبقي حتى الصلاة التالية.")
    }

    static var wComplicationDhikrName: String {
        string(en: "Dhikr Count", tr: "Zikir Sayacı", ar: "عدّاد الذكر")
    }

    static var wComplicationDhikrDescription: String {
        string(en: "Today's dhikr total.",
               tr: "Bugünkü zikir toplamın.",
               ar: "مجموع أذكارك اليوم.")
    }

    static var wComplicationPlaceholder: String {
        string(en: "—", tr: "—", ar: "—")
    }
}
