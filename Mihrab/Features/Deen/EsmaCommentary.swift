import Foundation

/// Short contemplative notes for the Names. These are reflections, not
/// transmitted texts — deliberately gentle and non-juridical.
/// Curated per Name where a Name is widely contemplated; otherwise the
/// Name's collection supplies the note.
enum EsmaCommentary {

    /// 1-based Name number → reflection paragraph in the active language.
    static func reflection(for number: Int) -> String {
        if let curated = curated(number) { return curated }
        return themed(EsmaCollections.primaryCollection(for: number).id)
    }

    static func suggestedCount(for number: Int) -> Int {
        EsmaCollections.primaryCollection(for: number).dhikrCount
    }

    // MARK: - Curated

    private static func curated(_ number: Int) -> String? {
        switch number {
        case 1:
            L10n.string(
                en: "A mercy that arrives before it is asked for, spread over everything that breathes.",
                tr: "İstenmeden önce gelen, nefes alan her şeyin üzerine serilen bir rahmet.",
                ar: "رحمة تسبق السؤال، تنبسط على كل ما يتنفس."
            )
        case 2:
            L10n.string(
                en: "The mercy that stays: patient with the same weakness, again and again.",
                tr: "Kalıcı olan rahmet: aynı zaafa, her defasında yeniden sabreden.",
                ar: "الرحمة الباقية: تصبر على الضعف نفسه مرة بعد مرة."
            )
        case 17:
            L10n.string(
                en: "Provision arrives on its own hour. Your task is the effort, not the timing.",
                tr: "Rızık kendi saatinde gelir. Sana düşen gayret, zamanlama değil.",
                ar: "الرزق يأتي في وقته. عليك السعي، لا التوقيت."
            )
        case 19:
            L10n.string(
                en: "What you cannot put into words is already known, in full.",
                tr: "Kelimelere dökemediğin şey, eksiksiz biliniyor zaten.",
                ar: "ما عجزت عن قوله معلوم تماماً."
            )
        case 26:
            L10n.string(
                en: "A prayer said under the breath is not a quieter prayer.",
                tr: "İçinden edilen dua, daha sessiz bir dua değildir.",
                ar: "الدعاء الخافت ليس أخفت عند السميع."
            )
        case 27:
            L10n.string(
                en: "Nothing done in private is done unseen — including the good.",
                tr: "Gizlide yapılan hiçbir şey görülmeden kalmaz — iyilik de dahil.",
                ar: "لا شيء في الخفاء يمضي بلا رؤية، والخير كذلك."
            )
        case 34:
            L10n.string(
                en: "Forgiveness here is not a narrow door. Turn, and it is already open.",
                tr: "Buradaki bağışlanma dar bir kapı değil. Yönel, zaten açık.",
                ar: "المغفرة ليست باباً ضيقاً. أقبل تجده مفتوحاً."
            )
        case 38:
            L10n.string(
                en: "What is entrusted is not lost. Not a deed, not a grief, not a name.",
                tr: "Emanet edilen kaybolmaz. Ne bir amel, ne bir keder, ne bir isim.",
                ar: "ما استُودع لا يضيع: لا عمل ولا حزن ولا اسم."
            )
        case 42:
            L10n.string(
                en: "Generosity that gives before being asked, and does not count what it gave.",
                tr: "İstenmeden veren ve verdiğini saymayan bir cömertlik.",
                ar: "كرمٌ يعطي قبل السؤال ولا يُحصي ما أعطى."
            )
        case 44:
            L10n.string(
                en: "Every call is answered — in its own form, at its own hour.",
                tr: "Her çağrı karşılık bulur — kendi biçiminde, kendi saatinde.",
                ar: "كل نداء يُجاب، بصورته وفي وقته."
            )
        case 46:
            L10n.string(
                en: "Wisdom is what makes the delay part of the answer.",
                tr: "Hikmet, gecikmeyi cevabın parçası kılan şeydir.",
                ar: "الحكمة تجعل التأخير جزءاً من الجواب."
            )
        case 47:
            L10n.string(
                en: "Love that precedes worthiness, and does not wait to be deserved.",
                tr: "Layık olmayı beklemeyen, ondan önce gelen bir sevgi.",
                ar: "محبة تسبق الاستحقاق ولا تنتظره."
            )
        case 52:
            L10n.string(
                en: "Do what is yours to do, then set the outcome down. It is carried.",
                tr: "Sana düşeni yap, sonra sonucu bırak. O taşınıyor.",
                ar: "افعل ما عليك ثم ضع النتيجة؛ فهي محمولة."
            )
        case 55:
            L10n.string(
                en: "A nearness that does not depend on how near you feel.",
                tr: "Kendini ne kadar yakın hissettiğine bağlı olmayan bir yakınlık.",
                ar: "قربٌ لا يتعلق بما تشعر به من قرب."
            )
        case 62:
            L10n.string(
                en: "Everything alive is borrowing life. One is life itself.",
                tr: "Yaşayan her şey hayatı ödünç alır. Biri ise hayatın kendisidir.",
                ar: "كل حي مستعير للحياة، وواحد هو الحي بذاته."
            )
        case 63:
            L10n.string(
                en: "Nothing stands on its own. Everything is being held right now.",
                tr: "Hiçbir şey kendi başına durmuyor. Her şey şu an tutuluyor.",
                ar: "لا شيء قائم بنفسه؛ كل شيء ممسوك الآن."
            )
        case 69:
            L10n.string(
                en: "Where your ability ends is not where possibility ends.",
                tr: "Senin gücünün bittiği yer, imkânın bittiği yer değildir.",
                ar: "حيث تنتهي قدرتك لا تنتهي الإمكان."
            )
        case 80:
            L10n.string(
                en: "Return is always available — and the returning itself is a gift given to you.",
                tr: "Dönüş her zaman mümkün — hem dönüşün kendisi sana verilmiş bir lütuf.",
                ar: "التوبة متاحة دائماً، وهي نفسها عطاء لك."
            )
        case 82:
            L10n.string(
                en: "Pardon that not only forgives the fault but erases its trace.",
                tr: "Kusuru yalnız bağışlamayan, izini de silen bir af.",
                ar: "عفوٌ لا يغفر الزلة فحسب بل يمحو أثرها."
            )
        case 93:
            L10n.string(
                en: "Light is not one thing among things — it is what lets things be seen.",
                tr: "Nur, şeyler arasında bir şey değil; şeylerin görülmesini sağlayandır.",
                ar: "النور ليس شيئاً بين الأشياء، بل به تُرى الأشياء."
            )
        case 94:
            L10n.string(
                en: "Guidance is asked for daily, seventeen times, by those already walking.",
                tr: "Hidayet, çoktan yürüyenler tarafından her gün on yedi kez istenir.",
                ar: "الهداية يسألها السائرون كل يوم سبع عشرة مرة."
            )
        case 99:
            L10n.string(
                en: "Patience without weariness — the kind that never becomes resentment.",
                tr: "Yorulmayan bir sabır — asla darılmaya dönüşmeyen.",
                ar: "صبرٌ لا يملّ ولا يستحيل عتباً."
            )
        default:
            nil
        }
    }

    // MARK: - Themed fallback

    private static func themed(_ collectionID: String) -> String {
        switch collectionID {
        case "mercy":
            L10n.string(
                en: "Sit with this Name when you are hardest on yourself. It answers there.",
                tr: "Kendine en sert davrandığın anda bu isimle otur. Cevabı oradadır.",
                ar: "اجلس مع هذا الاسم حين تقسو على نفسك؛ هناك يجيب."
            )
        case "majesty":
            L10n.string(
                en: "Held against this Name, what worries you today finds its true size.",
                tr: "Bu ismin yanına konduğunda, bugün seni kaygılandıran şey gerçek boyutunu bulur.",
                ar: "بجانب هذا الاسم يجد همُّ اليوم حجمه الحقيقي."
            )
        case "knowledge":
            L10n.string(
                en: "You are not asked to understand everything — only to trust that it is understood.",
                tr: "Her şeyi anlaman istenmiyor — yalnızca anlaşıldığına güvenmen.",
                ar: "لست مطالباً بفهم كل شيء، بل بالثقة أنه مفهوم."
            )
        case "provision":
            L10n.string(
                en: "Count today what actually arrived, not what you feared would not.",
                tr: "Bugün gelmemesinden korktuklarını değil, gerçekten geleni say.",
                ar: "عُدّ اليوم ما وصل فعلاً، لا ما خشيت ألا يصل."
            )
        case "justice":
            L10n.string(
                en: "Nothing is overlooked and nothing is over-charged. The scale is exact.",
                tr: "Ne göz ardı edilen var, ne fazla yüklenen. Terazi tam.",
                ar: "لا إغفال ولا إثقال؛ الميزان دقيق."
            )
        default:
            L10n.string(
                en: "Beginning, keeping, returning — the same care runs through all three.",
                tr: "Başlatmak, korumak, döndürmek — üçünde de aynı ihtimam var.",
                ar: "الإبداء والحفظ والإعادة: عناية واحدة في الثلاثة."
            )
        }
    }
}
