import Foundation

// Kaza copy. Deliberately encouraging: no "borç" framing that shames, no
// "geciken", no countdown to a deadline. Making up a prayer is presented as a
// door that stays open.
extension L10n {

    // MARK: - Titles

    static var qadaTitle: String { string(en: "Make-up Prayers", tr: "Kaza Namazı", ar: "قضاء الصلاة") }
    static var qadaShort: String { string(en: "Qada", tr: "Kaza", ar: "القضاء") }
    static var qadaSubtitle: String {
        string(en: "Track what is left, one prayer at a time",
               tr: "Kalanı takip et, her seferinde bir namaz",
               ar: "تابع ما بقي، صلاةً صلاة")
    }

    // MARK: - Empty / setup

    static var qadaEmptyTitle: String {
        string(en: "Start whenever you're ready", tr: "Hazır olduğunda başla", ar: "ابدأ متى شئت")
    }
    static var qadaEmptyBody: String {
        string(
            en: "Set up an estimate of what you'd like to make up. You can change it at any time — nothing here is a judgement.",
            tr: "Kılmak istediğin namazlar için bir tahmin oluştur. İstediğin an değiştirebilirsin — burada kimse seni yargılamıyor.",
            ar: "قدّر ما تودّ قضاءه، ويمكنك تعديله في أي وقت."
        )
    }
    static var qadaCancel: String { string(en: "Cancel", tr: "Vazgeç", ar: "إلغاء") }
    static var qadaSetUp: String { string(en: "Set up", tr: "Kurulum", ar: "الإعداد") }
    static var qadaWizardTitle: String { string(en: "Estimate", tr: "Tahmin", ar: "التقدير") }
    static var qadaWizardIntro: String {
        string(
            en: "An estimate is enough. Scholars accept a careful estimate — you do not need an exact number to begin.",
            tr: "Tahmin yeterlidir. Başlamak için kesin bir sayıya ihtiyacın yok; dikkatli bir tahmin kabul görür.",
            ar: "التقدير يكفي؛ لا تحتاج رقماً دقيقاً لتبدأ."
        )
    }
    static var qadaFrom: String { string(en: "From", tr: "Başlangıç", ar: "من") }
    static var qadaTo: String { string(en: "Until", tr: "Bitiş", ar: "إلى") }
    static var qadaByYears: String { string(en: "By number of years", tr: "Yıl sayısıyla", ar: "بعدد السنوات") }
    static var qadaByDates: String { string(en: "By dates", tr: "Tarih aralığıyla", ar: "بالتواريخ") }
    static func qadaYearsValue(_ n: Int) -> String {
        string(en: n == 1 ? "1 year" : "\(n) years", tr: "\(n) yıl", ar: "\(n) سنة")
    }
    static var qadaPrayedShare: String {
        string(en: "Of that time, roughly how much did you pray?",
               tr: "Bu sürenin yaklaşık ne kadarında kıldın?",
               ar: "كم صليت تقريباً من تلك المدة؟")
    }
    static var qadaPrayedShareHint: String {
        string(en: "Most people prayed some of the time. Moving this down keeps the estimate realistic.",
               tr: "Çoğu kişi bir kısmında kılmıştır. Bunu ayarlamak tahmini gerçekçi tutar.",
               ar: "أكثر الناس صلّوا بعض المدة، وهذا يجعل التقدير واقعياً.")
    }
    static var qadaWitrToggle: String {
        string(en: "Also track witr", tr: "Vitir de takip edilsin", ar: "تتبّع الوتر أيضاً")
    }
    static var qadaWitrNote: String {
        string(en: "In the Hanafi school witr is wajib and is made up alongside the five.",
               tr: "Hanefî mezhebinde vitir vaciptir ve beş vakitle birlikte kaza edilir.",
               ar: "الوتر واجب عند الحنفية ويُقضى مع الخمس.")
    }

    // MARK: - Monthly deduction (women)

    static var qadaMonthlyToggle: String {
        string(en: "Deduct monthly days", tr: "Hayız günlerini düş", ar: "خصم أيام الحيض")
    }
    static var qadaMonthlyExplain: String {
        string(
            en: "Prayers missed during menstruation are not made up. If this applies to you, we can subtract an average — you only give a number of days, nothing else is asked, stored or synced.",
            tr: "Hayız günlerinde kılınmayan namazlar kaza edilmez. Sana uyuyorsa ortalama bir gün sayısı düşebiliriz — yalnızca bir sayı istenir; başka hiçbir bilgi sorulmaz, saklanmaz veya senkronlanmaz.",
            ar: "لا تُقضى صلوات أيام الحيض. يمكن خصم متوسط عدد الأيام، ولا نطلب أو نحفظ أي بيانات أخرى."
        )
    }
    static var qadaMonthlyDays: String {
        string(en: "Average days per month", tr: "Ayda ortalama gün", ar: "متوسط الأيام شهرياً")
    }

    // MARK: - Estimate breakdown

    static var qadaBreakdown: String { string(en: "BREAKDOWN", tr: "DÖKÜM", ar: "التفصيل") }
    static func qadaTotalDays(_ n: Int) -> String {
        string(en: "\(n) days in range", tr: "Aralıktaki gün: \(n)", ar: "\(n) يوماً في المدة")
    }
    static func qadaDeductedDays(_ n: Int) -> String {
        string(en: "− \(n) days deducted", tr: "− \(n) gün düşüldü", ar: "− \(n) يوماً مخصومة")
    }
    static func qadaEffectiveDays(_ n: Int) -> String {
        string(en: "\(n) days to make up", tr: "Kaza edilecek gün: \(n)", ar: "\(n) يوماً للقضاء")
    }
    static func qadaPerPrayer(_ n: Int) -> String {
        string(en: "\(n) per prayer", tr: "Her vakit için \(n)", ar: "\(n) لكل صلاة")
    }
    static func qadaTotalPrayers(_ n: Int) -> String {
        string(en: "\(n) prayers in total", tr: "Toplam \(n) namaz", ar: "\(n) صلاة إجمالاً")
    }
    static var qadaSaveEstimate: String { string(en: "Save", tr: "Kaydet", ar: "حفظ") }
    static var qadaReplaceWarning: String {
        string(en: "Saving replaces your current counts. Your daily record is kept.",
               tr: "Kaydetmek mevcut sayıları değiştirir. Günlük kayıtların korunur.",
               ar: "الحفظ يستبدل الأعداد الحالية مع الاحتفاظ بسجلك اليومي.")
    }

    // MARK: - Daily screen

    static var qadaRemaining: String { string(en: "REMAINING", tr: "KALAN", ar: "المتبقي") }
    static var qadaTodayHeader: String { string(en: "TODAY", tr: "BUGÜN", ar: "اليوم") }
    static func qadaRemainingCount(_ n: Int) -> String {
        string(en: "\(n) left", tr: "\(n) kaldı", ar: "بقي \(n)")
    }
    static func qadaMadeUpToday(_ n: Int) -> String {
        if n == 0 {
            return string(en: "None yet today", tr: "Bugün henüz yok", ar: "لا شيء اليوم بعد")
        }
        return string(en: "\(n) made up today", tr: "Bugün \(n) kaza", ar: "\(n) قضاء اليوم")
    }
    static func qadaStreak(_ n: Int) -> String {
        string(en: n == 1 ? "1 day in a row" : "\(n) days in a row", tr: "\(n) gün üst üste", ar: "\(n) يوماً متتالياً")
    }
    static var qadaWitr: String { string(en: "Witr", tr: "Vitir", ar: "الوتر") }
    static var qadaAdd: String { string(en: "Add one", tr: "Bir ekle", ar: "أضف واحدة") }
    static var qadaUndo: String { string(en: "Undo", tr: "Geri al", ar: "تراجع") }
    static func qadaPaceLine(_ date: String) -> String {
        string(en: "At your current pace: about \(date)",
               tr: "Bu hızla: yaklaşık \(date)",
               ar: "بهذه الوتيرة: نحو \(date)")
    }
    static var qadaPaceUnknown: String {
        string(en: "Make up one prayer and we'll estimate a finish date.",
               tr: "Bir namaz kaza et, bitiş tarihini tahmin edelim.",
               ar: "اقضِ صلاة واحدة لنقدّر تاريخ الانتهاء.")
    }
    static func qadaProgressPercent(_ n: Int) -> String {
        string(en: "\(n)% made up", tr: "%\(n) tamamlandı", ar: "\(n)٪ مقضية")
    }
    static var qadaEditCounts: String { string(en: "Edit counts", tr: "Sayıları düzenle", ar: "تعديل الأعداد") }
    static var qadaEditHint: String {
        string(en: "Adjust any prayer directly if you remember more or fewer.",
               tr: "Daha fazla veya az hatırlıyorsan her vakti doğrudan düzeltebilirsin.",
               ar: "عدّل أي صلاة مباشرة إن تذكرت أكثر أو أقل.")
    }

    // MARK: - Celebration

    static var qadaDoneTitle: String {
        string(en: "All made up", tr: "Hepsi tamamlandı", ar: "تم القضاء كله")
    }
    static var qadaDoneBody: String {
        string(en: "Every prayer you set out to make up is done. May it be accepted.",
               tr: "Kaza etmeyi hedeflediğin bütün namazlar tamam. Kabul olsun.",
               ar: "تمّ كل ما نويت قضاءه، تقبّل الله.")
    }
    static func qadaMilestoneTitle(_ percent: Int) -> String {
        percent >= 100
            ? qadaDoneTitle
            : string(en: "\(percent)% of the way", tr: "%\(percent) tamamlandı", ar: "\(percent)٪ من الطريق")
    }
    static var qadaMilestoneBody: String {
        string(en: "Keep going at whatever pace suits you.",
               tr: "Sana uyan hızda devam et.",
               ar: "واصل بالوتيرة التي تناسبك.")
    }
    static var qadaCelebrateDismiss: String { string(en: "Continue", tr: "Devam", ar: "متابعة") }

    // MARK: - Settings

    static var qadaSectionTitle: String { string(en: "MAKE-UP PRAYERS", tr: "KAZA NAMAZI", ar: "قضاء الصلاة") }
    static var qadaSettingsHint: String {
        string(en: "Opens the make-up prayer tracker", tr: "Kaza namazı takibini açar", ar: "يفتح متابعة قضاء الصلاة")
    }
    static var qadaSettingsNone: String { string(en: "Not set up", tr: "Kurulmadı", ar: "غير مُعد") }
    static var qadaReset: String { string(en: "Reset make-up tracking", tr: "Kaza takibini sıfırla", ar: "إعادة ضبط القضاء") }
    static var qadaResetConfirm: String {
        string(en: "This deletes your counts and your daily record. It cannot be undone.",
               tr: "Bu işlem sayıları ve günlük kaydı siler. Geri alınamaz.",
               ar: "سيحذف هذا الأعداد والسجل اليومي نهائياً.")
    }
    static var qadaStatsTitle: String { string(en: "STATISTICS", tr: "İSTATİSTİK", ar: "الإحصاءات") }
    static func qadaAveragePerDay(_ value: String) -> String {
        string(en: "\(value) per day, last 30 days", tr: "Son 30 günde günde \(value)", ar: "\(value) يومياً خلال ٣٠ يوماً")
    }
}
