import Foundation

// Hatim copy.
//
// Two rules. First: never shame a slow pace — "kalan" and "bugünkü pay", never
// "geride kaldın". Second: never claim knowledge the app does not have. The
// shared hatim genuinely cannot see other participants, and the copy says that
// in the same size type as everything else.
extension L10n {

    // MARK: - Titles

    static var hatimTitle: String { string(en: "Hatim", tr: "Hatim", ar: "الختمة") }
    static var hatimSubtitle: String {
        string(en: "Finish the Qur'an at your own pace",
               tr: "Kur'an'ı kendi hızında hatmet",
               ar: "أتمم القرآن على وتيرتك")
    }
    static var hatimSectionTitle: String { string(en: "Hatim", tr: "Hatim", ar: "الختمة") }
    static var hatimFree: String {
        string(en: "Free, like the reader", tr: "Okuyucu gibi ücretsiz", ar: "مجانية كالقارئ")
    }

    // MARK: - Empty

    static var hatimEmptyTitle: String {
        string(en: "No hatim yet", tr: "Henüz hatim yok", ar: "لا توجد ختمة بعد")
    }
    static var hatimEmptyBody: String {
        string(
            en: "Set a date you'd like to finish by and Mihrab works out the daily share. Change it whenever you like — the plan follows you, not the other way round.",
            tr: "Bitirmek istediğin bir tarih seç, Mihrab günlük payı hesaplasın. İstediğin zaman değiştir — plan sana uyar, sen plana değil.",
            ar: "اختر تاريخاً تودّ الختم فيه ويحسب مِحراب النصيب اليومي. غيّره متى شئت — الخطة تتبعك لا العكس."
        )
    }

    // MARK: - Creating

    static var hatimNew: String { string(en: "New hatim", tr: "Yeni hatim", ar: "ختمة جديدة") }
    static var hatimIndividual: String { string(en: "On my own", tr: "Bireysel", ar: "فردية") }
    static var hatimShared: String { string(en: "Shared hatim", tr: "Ortak hatim", ar: "ختمة مشتركة") }
    static var hatimFinishBy: String { string(en: "Finish by", tr: "Bitiş tarihi", ar: "الختم بحلول") }
    static var hatimCreate: String { string(en: "Start", tr: "Başlat", ar: "ابدأ") }
    static var hatimCancel: String { string(en: "Cancel", tr: "Vazgeç", ar: "إلغاء") }
    static var hatimName: String { string(en: "Name", tr: "Ad", ar: "الاسم") }
    static var hatimDefaultName: String {
        string(en: "My hatim", tr: "Hatmim", ar: "ختمتي")
    }
    static var hatimEndOfRamadan: String {
        string(en: "End of Ramadan", tr: "Ramazan sonu", ar: "نهاية رمضان")
    }
    static var hatimInThirtyDays: String {
        string(en: "In 30 days", tr: "30 gün içinde", ar: "خلال ٣٠ يوماً")
    }
    static var hatimInAYear: String {
        string(en: "In a year", tr: "Bir yıl içinde", ar: "خلال سنة")
    }

    // MARK: - Progress

    static func hatimPercent(_ n: Int) -> String { "%\(n)" }
    static func hatimPagesOf(_ read: Int, _ total: Int) -> String {
        string(en: "\(read) of \(total) pages", tr: "\(total) sayfanın \(read)'i", ar: "\(read) من \(total) صفحة")
    }
    static func hatimJuzDone(_ value: Double) -> String {
        let n = String(format: "%.1f", value)
        return string(en: "\(n) juz", tr: "\(n) cüz", ar: "\(n) جزء")
    }
    static func hatimDaysLeft(_ n: Int) -> String {
        string(en: n == 1 ? "1 day left" : "\(n) days left",
               tr: "\(n) gün kaldı",
               ar: "بقي \(n) يوماً")
    }
    static var hatimTargetPassed: String {
        string(en: "The date has passed — pick a new one whenever you're ready.",
               tr: "Tarih geçti — hazır olduğunda yenisini seç.",
               ar: "مضى التاريخ — اختر آخر متى استعددت.")
    }
    static func hatimDailyShare(_ pages: Double) -> String {
        let n = pages < 10 ? String(format: "%.1f", pages) : String(Int(pages.rounded()))
        return string(en: "\(n) pages a day", tr: "günde \(n) sayfa", ar: "\(n) صفحة يومياً")
    }
    static var hatimDailyShareLabel: String {
        string(en: "Today's share", tr: "Bugünkü pay", ar: "نصيب اليوم")
    }
    static var hatimPaceLabel: String {
        string(en: "Your pace", tr: "Senin hızın", ar: "وتيرتك")
    }
    static func hatimProjected(_ date: String) -> String {
        string(en: "At this pace: \(date)", tr: "Bu hızla: \(date)", ar: "بهذه الوتيرة: \(date)")
    }
    static var hatimNoPaceYet: String {
        string(en: "Read a little and an estimate appears here.",
               tr: "Biraz okuduğunda burada bir tahmin belirir.",
               ar: "اقرأ قليلاً ليظهر التقدير هنا.")
    }
    static var hatimOnTrack: String {
        string(en: "On track", tr: "Yolunda", ar: "على المسار")
    }
    static var hatimBehind: String {
        string(en: "A little behind", tr: "Biraz gerideysin", ar: "متأخر قليلاً")
    }
    static var hatimComplete: String {
        string(en: "Hatim complete", tr: "Hatim tamamlandı", ar: "تمّت الختمة")
    }
    static func hatimCompletedCount(_ n: Int) -> String {
        string(en: n == 1 ? "1 hatim finished" : "\(n) hatims finished",
               tr: "\(n) hatim tamamlandı",
               ar: "\(n) ختمة مكتملة")
    }
    static var hatimContinueReading: String {
        string(en: "Continue reading", tr: "Okumaya devam et", ar: "تابع القراءة")
    }
    static var hatimMarkJuz: String {
        string(en: "Mark juz as read", tr: "Cüzü okundu işaretle", ar: "علّم الجزء مقروءاً")
    }
    static var hatimRestart: String { string(en: "Start over", tr: "Baştan başla", ar: "ابدأ من جديد") }
    static var hatimRestartConfirm: String {
        string(en: "Progress on this hatim goes back to zero. Nothing else is affected.",
               tr: "Bu hatimdeki ilerleme sıfırlanır. Başka hiçbir şey etkilenmez.",
               ar: "يعود تقدّم هذه الختمة إلى الصفر، ولا يتأثر شيء آخر.")
    }
    static var hatimDelete: String { string(en: "Delete hatim", tr: "Hatmi sil", ar: "احذف الختمة") }

    // MARK: - Shared hatim

    static var hatimSharedSetUp: String {
        string(en: "Organise a shared hatim", tr: "Ortak hatim kur", ar: "نظّم ختمة مشتركة")
    }
    static var hatimSharedJoin: String {
        string(en: "Join with a code", tr: "Kodla katıl", ar: "انضم برمز")
    }
    static var hatimShareCount: String {
        string(en: "Split into", tr: "Kaça bölünsün", ar: "التقسيم إلى")
    }
    static func hatimShareCountValue(_ n: Int) -> String {
        string(en: "\(n) shares", tr: "\(n) pay", ar: "\(n) نصيب")
    }
    static var hatimMyJuz: String {
        string(en: "My share", tr: "Benim payım", ar: "نصيبي")
    }
    static func hatimJuzLabel(_ n: Int) -> String {
        string(en: "Juz \(n)", tr: "\(n). Cüz", ar: "الجزء \(n)")
    }
    static var hatimPickJuz: String {
        string(en: "Pick the juz you'll read", tr: "Okuyacağın cüzleri seç", ar: "اختر الأجزاء التي ستقرؤها")
    }
    static var hatimInviteAction: String {
        string(en: "Send the invite", tr: "Daveti gönder", ar: "أرسل الدعوة")
    }
    static var hatimCodeField: String {
        string(en: "Paste the code or link", tr: "Kodu ya da bağlantıyı yapıştır", ar: "الصق الرمز أو الرابط")
    }
    static var hatimCodeInvalid: String {
        string(en: "That code could not be read. Ask for it again — codes are long and get cut off in messages.",
               tr: "Bu kod okunamadı. Yeniden iste — kodlar uzundur ve mesajlarda kırpılabilir.",
               ar: "تعذّرت قراءة الرمز. اطلبه ثانية — الرموز طويلة وقد تُقتطع في الرسائل.")
    }
    static var hatimJoin: String { string(en: "Join", tr: "Katıl", ar: "انضم") }

    /// The honesty panel. This is the whole point of the section — it must not
    /// be softened into marketing.
    static var hatimNoServerTitle: String {
        string(en: "How the shared hatim works", tr: "Ortak hatim nasıl çalışır", ar: "كيف تعمل الختمة المشتركة")
    }
    static var hatimNoServerBody: String {
        string(
            en: "Mihrab has no servers and collects nothing, so a shared hatim lives in the invite itself. Everyone tracks their own juz on their own phone. That means the app cannot show you who has claimed which juz or how far anyone else has read — agree that between yourselves, the way a hatim has always been arranged.",
            tr: "Mihrab'ın sunucusu yok ve hiçbir veri toplamıyor; bu yüzden ortak hatim davetin kendisinde yaşıyor. Herkes kendi cüzünü kendi telefonunda takip eder. Yani uygulama kimin hangi cüzü aldığını ya da kimin ne kadar okuduğunu gösteremez — bunu aranızda konuşun; hatim zaten hep böyle kurulmuştur.",
            ar: "لا خوادم لمِحراب ولا يجمع بيانات، فالختمة المشتركة تعيش في الدعوة نفسها: كلٌّ يتابع جزأه على هاتفه. لذا لا يستطيع التطبيق إظهار من أخذ أي جزء ولا مقدار قراءة غيرك — اتفقوا على ذلك بينكم كما جرت العادة."
        )
    }

    static func hatimInviteMessage(name: String, shares: Int, date: String, link: String) -> String {
        string(
            en: """
            \(name) — a shared hatim, split into \(shares) parts, to finish by \(date).

            Pick your juz and track it in Mihrab:
            \(link)
            """,
            tr: """
            \(name) — \(shares) paya bölünmüş ortak hatim, \(date) tarihine kadar.

            Cüzünü seç ve Mihrab'da takip et:
            \(link)
            """,
            ar: """
            \(name) — ختمة مشتركة من \(shares) أنصبة، تُختم بحلول \(date).

            اختر جزأك وتابعه في مِحراب:
            \(link)
            """
        )
    }

    static var hatimSharedLocalNote: String {
        string(en: "Claimed on this iPhone", tr: "Bu telefonda alınan", ar: "المأخوذ على هذا الهاتف")
    }
}
