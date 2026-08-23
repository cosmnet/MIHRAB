import Foundation

/// Times-screen UI copy owned by Agent W5. File named `L10n+TimesUI.swift`
/// because `Mihrab/Data/L10n+Times.swift` (Agent W1, provenance strings)
/// already claims the other name. Keys are prefixed `tmx…` so they never
/// collide with the shared catalogue's `tmz…` keys or with W1's
/// `resolution…` / `source…` provenance strings.
extension L10n {

    // MARK: - Transparency panel

    static var tmxWhereFromTitle: String {
        string(en: "Where this time comes from", tr: "Bu vakit nereden geliyor", ar: "من أين يأتي هذا الوقت")
    }

    static var tmxProvenanceCaps: String {
        string(en: "Provenance", tr: "Kaynak zinciri", ar: "سلسلة المصدر")
    }

    static var tmxCalculationCaps: String {
        string(en: "Calculation", tr: "Hesaplama", ar: "الحساب")
    }

    static var tmxAdjustmentsCaps: String {
        string(en: "Adjustments", tr: "Düzeltmeler", ar: "التعديلات")
    }

    static var tmxYourCorrectionCaps: String {
        string(en: "Your correction", tr: "Kendi düzeltmeniz", ar: "تعديلك الخاص")
    }

    static var tmxDataCaps: String {
        string(en: "Data", tr: "Veri", ar: "البيانات")
    }

    static var tmxTemkin: String {
        string(en: "Temkin margin", tr: "Temkin payı", ar: "هامش التمكين")
    }

    static var tmxMethodAdjustment: String {
        string(en: "Method adjustment", tr: "Yöntem düzeltmesi", ar: "تعديل الطريقة")
    }

    static var tmxTwilightAngle: String {
        string(en: "Twilight angle", tr: "Şafak açısı", ar: "زاوية الشفق")
    }

    static var tmxHighLatitudeRule: String {
        string(en: "High-latitude rule", tr: "Yüksek enlem kuralı", ar: "قاعدة خطوط العرض العليا")
    }

    static var tmxIshaInterval: String {
        string(en: "Fixed interval after maghrib", tr: "Akşamdan sonra sabit süre", ar: "مدة ثابتة بعد المغرب")
    }

    static var tmxNoAdjustments: String {
        string(en: "No margin is applied to this time.",
               tr: "Bu vakte herhangi bir pay eklenmiyor.",
               ar: "لا يُضاف أي هامش إلى هذا الوقت.")
    }

    static var tmxResolutionUnavailable: String {
        string(en: "Provenance for this day is not loaded yet.",
               tr: "Bu günün kaynak bilgisi henüz yüklenmedi.",
               ar: "لم تُحمَّل بعد بيانات مصدر هذا اليوم.")
    }

    // MARK: - Correction control

    static var tmxCorrectionTitle: String {
        string(en: "Shift this time", tr: "Bu vakti kaydır", ar: "أزِح هذا الوقت")
    }

    static func tmxCorrectionMinutes(_ minutes: Int) -> String {
        let signed = minutes > 0 ? "+\(minutes)" : "\(minutes)"
        return string(en: "\(signed) min", tr: "\(signed) dk", ar: "\(signed) د")
    }

    static var tmxCorrectionNone: String {
        string(en: "No shift", tr: "Kaydırma yok", ar: "بدون إزاحة")
    }

    static var tmxCorrectionFooter: String {
        string(
            en: "Use this only to match a mosque or a printed calendar you trust. It moves the notification too. Limited to ±30 minutes, because past that it is a different prayer time rather than a correction.",
            tr: "Bunu yalnızca güvendiğiniz bir cami ya da basılı takvimle eşitlemek için kullanın. Bildirimi de kaydırır. ±30 dakikayla sınırlıdır; ötesi düzeltme değil, başka bir vakit olur.",
            ar: "استخدم هذا فقط لمطابقة مسجد أو تقويم مطبوع تثق به؛ وهو يزيح التنبيه أيضًا. الحدّ ±٣٠ دقيقة، لأن ما بعدها يصبح وقتًا آخر لا تصحيحًا."
        )
    }

    static var tmxResetCorrection: String {
        string(en: "Reset", tr: "Sıfırla", ar: "إعادة تعيين")
    }

    static var tmxDecreaseMinute: String {
        string(en: "One minute earlier", tr: "Bir dakika erken", ar: "دقيقة أبكر")
    }

    static var tmxIncreaseMinute: String {
        string(en: "One minute later", tr: "Bir dakika geç", ar: "دقيقة لاحقًا")
    }

    // MARK: - Source switch

    static var tmxSourceTitle: String {
        string(en: "Calendar tradition", tr: "Takvim geleneği", ar: "تقويم مُعتمد")
    }

    static var tmxWhyDifferentTitle: String {
        string(en: "Why is this different from Diyanet?",
               tr: "Neden Diyanet'ten farklı?",
               ar: "لماذا يختلف هذا عن ديانت؟")
    }

    static var tmxWhyDifferentBody: String {
        string(
            en: """
            Two things move a printed prayer time, and neither of them is a mistake.

            First, the angle. A calendar has to decide how far below the horizon the sun must be before dawn counts as begun. Diyanet uses 18° for imsak and 17° for yatsı; Fazilet Takvimi and Türkiye Takvimi place dawn deeper, which is why their imsak lands earlier.

            Second, temkin — a deliberate safety margin so that someone praying exactly on the printed minute is still inside the valid window anywhere in the city. Diyanet publishes öğle five minutes after the true transit for this reason, and pulls sunrise seven minutes earlier.

            Mihrab tells you which of these applies to the number you are looking at, and lets you shift it yourself if your mosque follows something else.
            """,
            tr: """
            Basılı bir vakti iki şey oynatır ve ikisi de hata değildir.

            Birincisi açı. Bir takvim, güneşin ufkun ne kadar altındayken fecrin başladığını kabul edeceğine karar vermek zorundadır. Diyanet imsak için 18°, yatsı için 17° kullanır; Fazilet Takvimi ve Türkiye Takvimi fecri daha derin bir açıya koyar — imsaklarının daha erken olmasının sebebi budur.

            İkincisi temkin: basılı dakikada namaz kılan birinin şehrin her yerinde vaktin içinde kalması için bilerek eklenen güvenlik payı. Diyanet öğleyi bu yüzden gerçek zeval geçişinden beş dakika sonra yayımlar, güneşi yedi dakika öne çeker.

            Mihrab, baktığınız sayıya bunlardan hangisinin uygulandığını söyler; caminiz başka bir usul izliyorsa vakti kendiniz kaydırabilirsiniz.
            """,
            ar: """
            أمران يُحرّكان الوقت المطبوع، وليس أيٌّ منهما خطأ.

            الأول: الزاوية. على كل تقويم أن يحدّد كم يجب أن تنخفض الشمس تحت الأفق ليبدأ الفجر. تعتمد ديانت 18° للإمساك و17° للعشاء، بينما يضع تقويما «فاضيلات» و«تركيا» الفجر عند زاوية أعمق، ولذلك يتقدّم إمساكهما.

            الثاني: التمكين، وهو هامش أمان مقصود ليبقى المصلّي في الوقت الصحيح في أي مكان من المدينة. لهذا تنشر ديانت الظهر بعد الزوال الحقيقي بخمس دقائق، وتقدّم الشروق سبع دقائق.

            يوضّح «محراب» أيًّا من هذين ينطبق على الرقم الذي تراه، ويتيح لك إزاحته إن كان مسجدك يتبع غير ذلك.
            """
        )
    }

    // MARK: - Freshness badges

    static var tmxComputedOnDevice: String {
        string(en: "Computed on this device", tr: "Cihazda hesaplandı", ar: "حُسب على هذا الجهاز")
    }

    static var tmxFromNetwork: String {
        string(en: "From the online calendar", tr: "Çevrimiçi takvimden", ar: "من التقويم الشبكي")
    }

    static func tmxLastUpdated(_ date: Date) -> String {
        // The app's language is chosen by L10n, which can differ from the
        // device region — format in that locale or Turkish UI shows US dates.
        let formatted = date.formatted(
            Date.FormatStyle(date: .abbreviated, time: .shortened)
                .locale(Locale(identifier: L10n.localeIdentifier))
        )
        return string(en: "Last update: \(formatted)",
                      tr: "Son güncelleme: \(formatted)",
                      ar: "آخر تحديث: \(formatted)")
    }

    static var tmxTraditionCaps: String {
        string(en: "Calendar tradition", tr: "Takvim geleneği", ar: "تقليد التقويم")
    }

    static var tmxNeverUpdated: String {
        string(en: "Never synced — running fully offline",
               tr: "Hiç eşitlenmedi — tamamen çevrimdışı çalışıyor",
               ar: "لم تُزامَن قط — يعمل دون اتصال تمامًا")
    }

    static var tmxOfflineExplain: String {
        string(
            en: "Prayer times never depend on a connection. They are calculated here, and the network only refines them when it is available.",
            tr: "Vakitler hiçbir zaman bağlantıya bağlı değildir. Burada hesaplanır; ağ yalnızca eriştiğinde onları inceltir.",
            ar: "لا تعتمد المواقيت على الاتصال إطلاقًا؛ تُحسب هنا، ولا يزيدها الاتصال إلا دقّة عند توفّره."
        )
    }

    static var tmxEngineUnavailableTitle: String {
        string(en: "No schedule at this latitude", tr: "Bu enlemde vakit çıkarılamıyor", ar: "لا يمكن استخراج مواقيت عند هذا العرض")
    }

    static var tmxEngineUnavailableBody: String {
        string(
            en: "Where you are, the sun does not cross the horizon today, so there is no astronomical dawn or sunset to anchor the times to. Choose a reference city in Settings and we will follow its schedule instead of inventing one.",
            tr: "Bulunduğunuz yerde güneş bugün ufku geçmiyor; vakitleri bağlayacak astronomik bir fecir ya da gurup yok. Ayarlar'dan bir referans şehir seçin, uydurmak yerine onun takvimini izleyelim.",
            ar: "في موقعك لا تعبر الشمس الأفق اليوم، فلا فجر ولا غروب فلكي تُبنى عليه المواقيت. اختر مدينة مرجعية من الإعدادات لنتبع تقويمها بدل اختلاق أوقات."
        )
    }

    // MARK: - Makruh (kerahat)

    static var tmxMakruhCaps: String {
        string(en: "Disliked times", tr: "Kerahat vakitleri", ar: "أوقات الكراهة")
    }

    static var tmxMakruhIshraq: String {
        string(en: "Just after sunrise", tr: "Güneş doğarken", ar: "بُعيد الشروق")
    }

    static var tmxMakruhIstiwa: String {
        string(en: "Sun at its peak", tr: "Zeval (istiva)", ar: "الاستواء")
    }

    static var tmxMakruhIsfirar: String {
        string(en: "As the sun sets", tr: "Güneş batarken", ar: "عند الغروب")
    }

    static var tmxMakruhExplain: String {
        string(
            en: "Voluntary prayer is not offered in these three intervals. The peak window runs from the true solar transit computed on this device to the öğle time your calendar publishes — the gap between them is exactly the temkin. The sunrise and sunset windows use the common convention that the sun must be about 5° above the horizon, roughly the classical \"length of a spear\".",
            tr: "Bu üç aralıkta nafile namaz kılınmaz. Zeval aralığı, cihazda hesaplanan gerçek öğle geçişinden takviminizin yayımladığı öğle vaktine kadardır — aradaki fark tam olarak temkindir. Doğuş ve batış aralıkları, güneşin ufuktan yaklaşık 5° yükselmesi gerektiği yolundaki yaygın kabule (klasik ifadeyle \"bir mızrak boyu\") dayanır.",
            ar: "لا تُصلّى النوافل في هذه الفترات الثلاث. تمتد فترة الاستواء من الزوال الحقيقي المحسوب على هذا الجهاز إلى وقت الظهر الذي ينشره تقويمك، والفارق بينهما هو التمكين تمامًا. أما فترتا الشروق والغروب فتعتمدان العرف الشائع بارتفاع الشمس نحو 5° عن الأفق، أي \"قدر رمح\" في التعبير الكلاسيكي."
        )
    }

    static var tmxMakruhUnavailable: String {
        string(en: "These windows cannot be derived for this day and place.",
               tr: "Bu gün ve konum için bu aralıklar çıkarılamıyor.",
               ar: "لا يمكن استخراج هذه الفترات لهذا اليوم والموقع.")
    }

    // MARK: - Night thirds

    static var tmxNightCaps: String {
        string(en: "The night", tr: "Gece", ar: "الليل")
    }

    static var tmxMidnight: String {
        string(en: "Middle of the night", tr: "Gece yarısı", ar: "منتصف الليل")
    }

    static var tmxLastThird: String {
        string(en: "Last third of the night", tr: "Gecenin son üçte biri", ar: "الثلث الأخير من الليل")
    }

    static var tmxNightExplain: String {
        string(
            en: "Measured from maghrib to the following imsak, not from clock midnight. The last third is when tahajjud is offered.",
            tr: "Saat gece yarısından değil, akşamdan ertesi imsağa kadar ölçülür. Son üçte bir, teheccüdün kılındığı bölümdür.",
            ar: "تُقاس من المغرب إلى إمساك اليوم التالي، لا من منتصف الليل بالساعة. والثلث الأخير هو وقت التهجّد."
        )
    }

    static var tmxNightNeedsTomorrow: String {
        string(en: "Needs tomorrow's imsak — not loaded yet.",
               tr: "Yarının imsakı gerekiyor — henüz yüklenmedi.",
               ar: "يحتاج إمساك الغد، ولم يُحمَّل بعد.")
    }

    // MARK: - Friday

    static var tmxFridayBadge: String {
        string(en: "Friday", tr: "Cuma", ar: "الجمعة")
    }

    static var tmxJumuah: String {
        string(en: "Jumu'ah is prayed at the öğle time", tr: "Cuma namazı öğle vaktinde kılınır", ar: "تُصلّى الجمعة في وقت الظهر")
    }

    // MARK: - Imsakiye sharing

    static var tmxShareImsakiye: String {
        string(en: "Share imsakiye", tr: "İmsakiye paylaş", ar: "مشاركة الإمساكية")
    }

    static var tmxImsakiyeTitle: String {
        string(en: "Prayer timetable", tr: "İmsakiye", ar: "الإمساكية")
    }

    static var tmxPreparingShare: String {
        string(en: "Preparing…", tr: "Hazırlanıyor…", ar: "جارٍ التحضير…")
    }

    // MARK: - Sun

    static var tmxSolarNoon: String {
        string(en: "Solar noon", tr: "Gerçek öğle (zeval)", ar: "الزوال الحقيقي")
    }

    static var tmxDetailHint: String {
        string(en: "Tap a time to see where it comes from",
               tr: "Bir vakte dokunup nereden geldiğini görün",
               ar: "اضغط على وقت لترى مصدره")
    }

    static var tmxNotificationToggle: String {
        string(en: "Alert for this prayer", tr: "Bu vakit için bildirim", ar: "تنبيه لهذا الوقت")
    }
}
