import Foundation

/// Qibla copy owned by Agent W5. Prefixed `qbl…` so it never collides with the
/// existing `qib…` keys in the shared catalogue.
extension L10n {

    // MARK: - North reference

    static var qblTrueNorth: String {
        string(en: "True north", tr: "Gerçek kuzey", ar: "الشمال الحقيقي")
    }

    static var qblMagneticNorth: String {
        string(en: "Magnetic north", tr: "Manyetik kuzey", ar: "الشمال المغناطيسي")
    }

    /// Shown whenever we could not get a true-north heading. Being told is the
    /// whole point — a silent magnetic reading is the bug we are avoiding.
    static var qblMagneticNorthWarning: String {
        string(
            en: "No location fix yet, so this reading is measured from magnetic north. It can be several degrees off the real Qibla until location is available.",
            tr: "Henüz konum alınamadı; bu değer manyetik kuzeye göre ölçülüyor. Konum gelene kadar gerçek kıbleden birkaç derece sapabilir.",
            ar: "لا يوجد تحديد للموقع بعد، لذا يُقاس هذا الاتجاه من الشمال المغناطيسي وقد ينحرف بضع درجات عن القبلة الحقيقية."
        )
    }

    static var qblNorthReferenceCaps: String {
        string(en: "Reference", tr: "Referans", ar: "المرجع")
    }

    /// The good case, stated once in the verification sheet instead of sitting
    /// permanently under the dial as a badge.
    static var qblReferenceTrueSentence: String {
        string(
            en: "This heading is measured from true north, the same north the Qibla bearing is drawn against.",
            tr: "Bu yön, gerçek kuzeye göre ölçülüyor — kıble açısının da çizildiği kuzey.",
            ar: "يُقاس هذا الاتجاه من الشمال الحقيقي، وهو الشمال نفسه الذي تُنسب إليه زاوية القبلة."
        )
    }

    // MARK: - Verification sheet

    /// The single visible entry point to everything the compass screen used to
    /// explain inline.
    static var qblVerifyEntry: String {
        string(en: "How do I check this?", tr: "Nasıl doğrularım?", ar: "كيف أتحقّق؟")
    }

    static var qblVerifyTitle: String {
        string(en: "Checking the Qibla", tr: "Kıbleyi doğrulama", ar: "التحقّق من القبلة")
    }

    // MARK: - Accuracy gate

    static var qblUnreliableTitle: String {
        string(en: "Direction not reliable", tr: "Yön güvenilir değil", ar: "الاتجاه غير موثوق")
    }

    static var qblUnreliableBody: String {
        string(
            en: "Your device cannot measure a trustworthy heading right now, so we are not going to pretend it can. Move away from metal, magnets, cases with magnets, cars and speakers, then calibrate below.",
            tr: "Cihaz şu anda güvenilir bir yön ölçemiyor; ölçebiliyormuş gibi davranmayacağız. Metal, mıknatıs, mıknatıslı kılıf, araç ve hoparlörlerden uzaklaşın, ardından aşağıdaki kalibrasyonu yapın.",
            ar: "لا يستطيع جهازك قياس اتجاه موثوق الآن، ولن ندّعي غير ذلك. ابتعد عن المعادن والمغناطيس والحافظات المغناطيسية والسيارات ومكبّرات الصوت، ثم عايِر البوصلة أدناه."
        )
    }

    static var qblInterferenceTitle: String {
        string(en: "Magnetic interference", tr: "Manyetik bozulma", ar: "تشويش مغناطيسي")
    }

    static func qblErrorMargin(_ degrees: Int) -> String {
        string(en: "Margin of error about ±\(degrees)°",
               tr: "Hata payı yaklaşık ±\(degrees)°",
               ar: "هامش الخطأ نحو ±\(degrees)°")
    }

    static var qblErrorUnknown: String {
        string(en: "Margin of error unknown", tr: "Hata payı bilinmiyor", ar: "هامش الخطأ غير معروف")
    }

    static var qblPrecise: String {
        string(en: "Compass steady", tr: "Pusula kararlı", ar: "البوصلة مستقرة")
    }

    // MARK: - Calibration

    static var qblCalibrateHowTitle: String {
        string(en: "Draw a figure eight", tr: "Havada 8 çizin", ar: "ارسم رقم ٨ في الهواء")
    }

    static var qblCalibrateHowBody: String {
        string(
            en: "Hold the phone flat and sweep it through a slow figure eight two or three times. This re-teaches the magnetometer where north is.",
            tr: "Telefonu düz tutup yavaşça iki üç kez havada 8 çizin. Bu, manyetometreye kuzeyin nerede olduğunu yeniden öğretir.",
            ar: "أمسك الهاتف مستويًا وحرّكه ببطء على شكل رقم ٨ مرتين أو ثلاثًا؛ يعيد ذلك معايرة مستشعر المغناطيسية."
        )
    }

    static var qblCalibrateDone: String {
        string(en: "Compass recovered", tr: "Pusula toparlandı", ar: "استعادت البوصلة دقتها")
    }

    // MARK: - Sun verification

    static var qblSunCheckTitle: String {
        string(en: "Check with the sun", tr: "Güneşle doğrula", ar: "تحقّق بالشمس")
    }

    static var qblSunCheckCaps: String {
        string(en: "Sensor-free check", tr: "Pusulasız kontrol", ar: "تحقّق بلا بوصلة")
    }

    static var qblSunCheckIntro: String {
        string(
            en: "No compass can be checked by another compass. The sun can. Face the sun, then turn by the amount below.",
            tr: "Bir pusula başka bir pusulayla doğrulanamaz; güneşle doğrulanabilir. Güneşe dönün, sonra aşağıdaki kadar dönün.",
            ar: "لا تُختبر البوصلة ببوصلة أخرى، بل بالشمس. استقبل الشمس ثم استدر بالمقدار الموضّح أدناه."
        )
    }

    static func qblSunLeftOfQibla(_ degrees: Int) -> String {
        string(en: "The sun is \(degrees)° to the left of the Qibla",
               tr: "Güneş kıbleden \(degrees)° solda",
               ar: "الشمس على يسار القبلة بـ \(degrees)°")
    }

    static func qblSunRightOfQibla(_ degrees: Int) -> String {
        string(en: "The sun is \(degrees)° to the right of the Qibla",
               tr: "Güneş kıbleden \(degrees)° sağda",
               ar: "الشمس على يمين القبلة بـ \(degrees)°")
    }

    static var qblSunOnQiblaNow: String {
        string(en: "The sun is on the Qibla right now",
               tr: "Güneş şu anda tam kıble yönünde",
               ar: "الشمس الآن في اتجاه القبلة تمامًا")
    }

    static func qblFaceSunTurnLeft(_ degrees: Int) -> String {
        string(en: "Face the sun, then turn \(degrees)° left",
               tr: "Güneşe dönün, sonra \(degrees)° sola dönün",
               ar: "استقبل الشمس ثم استدر \(degrees)° يسارًا")
    }

    static func qblFaceSunTurnRight(_ degrees: Int) -> String {
        string(en: "Face the sun, then turn \(degrees)° right",
               tr: "Güneşe dönün, sonra \(degrees)° sağa dönün",
               ar: "استقبل الشمس ثم استدر \(degrees)° يمينًا")
    }

    static var qblShadowHint: String {
        string(
            en: "A vertical object's shadow points the opposite way from the sun — sight along it if the sun is too bright to face.",
            tr: "Dik bir cismin gölgesi güneşin tam tersini gösterir; güneşe bakamıyorsanız gölgeyi izleyin.",
            ar: "ظلّ الجسم القائم يشير عكس الشمس تمامًا؛ استعن به إن تعذّر النظر إلى الشمس."
        )
    }

    static var qblSunBelowHorizon: String {
        string(en: "The sun is below the horizon — no shadow to check against right now.",
               tr: "Güneş ufkun altında — şu an doğrulanacak bir gölge yok.",
               ar: "الشمس تحت الأفق، فلا ظلّ للتحقّق به الآن.")
    }

    static var qblSunTooLow: String {
        string(en: "The sun is too low for a readable shadow.",
               tr: "Güneş okunabilir bir gölge için fazla alçak.",
               ar: "الشمس منخفضة جدًا لظلّ يمكن قراءته.")
    }

    static func qblSunOnQiblaAt(_ time: Date) -> String {
        let formatted = time.formatted(date: .omitted, time: .shortened)
        return string(en: "Today at \(formatted) the sun stands exactly on your Qibla — whatever your shadow does then is the direction.",
                      tr: "Bugün saat \(formatted)'da güneş tam kıble yönünüzde olacak — o an gölgeniz yönü gösterir.",
                      ar: "اليوم عند \(formatted) تقف الشمس تمامًا في اتجاه قبلتك، وعندها يدلّك ظلّك على الاتجاه.")
    }

    // MARK: - Rashdul Qibla

    static var qblRashdulTitle: String {
        string(en: "Sun over the Kaaba", tr: "Güneş Kâbe'nin üzerinde", ar: "استواء الشمس فوق الكعبة")
    }

    static var qblRashdulExplain: String {
        string(
            en: "Twice a year the sun passes directly over the Kaaba. At that moment every shadow on the sunlit half of the earth points away from the Qibla — the oldest and most reliable check there is, and it needs no device.",
            tr: "Yılda iki kez güneş tam Kâbe'nin üzerinden geçer. O anda dünyanın aydınlık yarısındaki her gölge kıblenin tam tersini gösterir — en eski ve en güvenilir kontrol, hiçbir cihaz gerektirmez.",
            ar: "مرّتين في السنة تمرّ الشمس فوق الكعبة تمامًا، فتشير كل الظلال في النصف المضيء من الأرض عكس القبلة — أقدم وأوثق تحقّق، ولا يحتاج جهازًا."
        )
    }

    static func qblRashdulToday(_ time: Date) -> String {
        let formatted = time.formatted(date: .omitted, time: .shortened)
        return string(en: "Today at \(formatted) your shadow will point exactly away from the Qibla.",
                      tr: "Bugün saat \(formatted)'da gölgeniz tam kıblenin tersini gösterecek.",
                      ar: "اليوم عند \(formatted) سيشير ظلّك عكس القبلة تمامًا.")
    }

    static func qblRashdulTomorrow(_ time: Date) -> String {
        let formatted = time.formatted(date: .omitted, time: .shortened)
        return string(en: "Tomorrow at \(formatted) your shadow will point exactly away from the Qibla.",
                      tr: "Yarın saat \(formatted)'da gölgeniz tam kıblenin tersini gösterecek.",
                      ar: "غدًا عند \(formatted) سيشير ظلّك عكس القبلة تمامًا.")
    }

    static func qblRashdulOn(_ date: Date) -> String {
        let formatted = date.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened).locale(L10n.appLocale))
        return string(en: "Next: \(formatted) (your local time)",
                      tr: "Sıradaki: \(formatted) (yerel saatinizle)",
                      ar: "التالي: \(formatted) (بتوقيتك المحلي)")
    }

    static var qblRashdulNightNote: String {
        string(
            en: "At that moment the sun is below your horizon, so the shadow check is not available where you are.",
            tr: "O anda güneş sizin ufkunuzun altında olacak; bu yüzden gölge kontrolü bulunduğunuz yerde yapılamaz.",
            ar: "تكون الشمس حينها تحت أفقك، فلا يتاح فحص الظلّ في موقعك."
        )
    }

    static var qblHowItWorks: String {
        string(en: "How this check works", tr: "Bu kontrol nasıl çalışır", ar: "كيف يعمل هذا التحقّق")
    }

    static var qblAccuracyMethodNote: String {
        string(
            en: "Qibla bearing is a great-circle direction to the Kaaba, drawn against true north. Solar positions are computed on this device.",
            tr: "Kıble açısı, Kâbe'ye büyük daire yönüdür ve gerçek kuzeye göre çizilir. Güneş konumları bu cihazda hesaplanır.",
            ar: "زاوية القبلة هي اتجاه الدائرة العظمى إلى الكعبة منسوبًا إلى الشمال الحقيقي، ومواضع الشمس تُحسب على هذا الجهاز."
        )
    }
}
