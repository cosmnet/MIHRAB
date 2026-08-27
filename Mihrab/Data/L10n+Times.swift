import Foundation

/// Copy owned by the prayer-times layer (source selection, per-prayer
/// corrections, provenance panel). Kept out of `Core/Shared/L10n.swift`.
extension L10n {

    // MARK: - Prayer sources

    static var sourceSectionTitle: String {
        string(en: "Calendar source", tr: "Takvim kaynağı", ar: "مصدر التقويم")
    }

    static var sourceSectionFooter: String {
        string(
            en: "Turkish calendars disagree about when true dawn begins, so imsak differs between them. Only calendars whose publisher states its own angles and temkin are offered here. Standard uses the calculation method you picked, untouched.",
            tr: "Türkiye'deki takvimler fecr-i sâdıkın başlangıcında hemfikir değil; bu yüzden imsak aralarında değişir. Burada yalnızca kendi açılarını ve temkinini yayımlayan takvimler sunulur. Standart ise seçtiğin hesaplama yöntemini olduğu gibi kullanır.",
            ar: "تختلف التقاويم في تركيا حول بداية الفجر الصادق فيختلف الإمساك بينها. ولا يُعرض هنا إلا تقويم ينشر ناشره زواياه وتمكينه. أما الخيار القياسي فيتبع طريقة الحساب التي اخترتها كما هي."
        )
    }

    static var sourceDiyanet: String {
        string(en: "Diyanet", tr: "Diyanet", ar: "ديانت")
    }

    static var sourceFazilet: String {
        string(en: "Fazilet Takvimi", tr: "Fazilet Takvimi", ar: "تقويم فضيلت")
    }

    static var sourceTurkiyeTakvimi: String {
        string(en: "Türkiye Takvimi", tr: "Türkiye Takvimi", ar: "تقويم تركيا")
    }

    static var sourceStandard: String {
        string(en: "Standard (your method)", tr: "Standart (seçtiğin yöntem)", ar: "قياسي (طريقتك)")
    }

    static var sourceDiyanetDetail: String {
        string(
            en: "Fajr 18°, isha 17°, plus Diyanet's temkin: sunrise −7, dhuhr +5, asr +4, maghrib +7 minutes.",
            tr: "İmsak 18°, yatsı 17°, artı Diyanet temkini: güneş −7, öğle +5, ikindi +4, akşam +7 dakika.",
            ar: "الفجر ١٨°، العشاء ١٧°، مع تمكين ديانت: الشروق ٧− والظهر ٥+ والعصر ٤+ والمغرب ٧+ دقائق."
        )
    }

    static var sourceTurkiyeTakvimiDetail: String {
        string(
            en: "Imsak 19°, isha 17°, with 10 minutes of temkin on every time — taken off imsak and sunrise, added to dhuhr, asr, maghrib and isha. Imsak lands noticeably earlier than Diyanet's.",
            tr: "İmsak 19°, yatsı 17°, her vakitte 10 dakika temkin — imsak ve güneşten düşülür; öğle, ikindi, akşam ve yatsıya eklenir. İmsak, Diyanet'e göre belirgin biçimde daha erkendir.",
            ar: "الإمساك ١٩°، العشاء ١٧°، مع تمكين ١٠ دقائق لكل وقت: يُطرح من الإمساك والشروق ويُضاف إلى الظهر والعصر والمغرب والعشاء. فيأتي الإمساك أبكر من ديانت بوضوح."
        )
    }

    /// Shown only if an old install still has a withdrawn tradition stored.
    /// Says plainly what happened and what is being used instead.
    static var sourceWithdrawnDetail: String {
        string(
            en: "This calendar is no longer offered: its publisher does not document the angles and margins it uses, so we could not show its times honestly. Diyanet's published times are used instead.",
            tr: "Bu takvim artık sunulmuyor: yayıncısı kullandığı açıları ve temkin paylarını açıklamıyor, bu yüzden vakitlerini dürüstçe gösteremiyorduk. Onun yerine Diyanet'in yayımladığı vakitler kullanılıyor.",
            ar: "لم يعد هذا التقويم متاحاً لعدم نشر ناشره الزوايا والهوامش المعتمدة، وتُستخدم بدلاً منه أوقات ديانت المنشورة."
        )
    }

    static var sourceStandardDetail: String {
        string(
            en: "No regional correction. Times follow the calculation method you picked, exactly as its authority publishes it.",
            tr: "Bölgesel düzeltme yok. Vakitler, seçtiğin hesaplama yönteminin yayımladığı hâliyle kullanılır.",
            ar: "بدون تصحيح إقليمي. تُتبع طريقة الحساب التي اخترتها كما تنشرها جهتها."
        )
    }

    static var sourceTurkeyOnlyNote: String {
        string(
            en: "These calendars describe practice in Türkiye. Outside Türkiye, Standard is usually the honest choice.",
            tr: "Bu takvimler Türkiye'deki uygulamayı anlatır. Türkiye dışında genellikle Standart daha doğru olur.",
            ar: "تصف هذه التقاويم الممارسة في تركيا. وخارج تركيا يكون الخيار القياسي أصدق عادةً."
        )
    }

    /// Names the authority on screen. Shown under the Diyanet source.
    static var sourceAuthorityTurkiyeTakvimi: String {
        string(en: "Source: Türkiye Takvimi (Hakîkat Kitabevi)",
               tr: "Kaynak: Türkiye Takvimi (Hakîkat Kitabevi)",
               ar: "المصدر: تقويم تركيا (مكتبة الحقيقة)")
    }

    static var sourceAuthorityDiyanet: String {
        string(en: "Source: Presidency of Religious Affairs (Diyanet İşleri Başkanlığı)",
               tr: "Kaynak: Diyanet İşleri Başkanlığı",
               ar: "المصدر: رئاسة الشؤون الدينية التركية (ديانت)")
    }

    // MARK: - Per-prayer corrections

    static var offsetsTitle: String {
        string(en: "Fine-tune each time", tr: "Vakit başına düzeltme", ar: "ضبط دقيق لكل وقت")
    }

    static var offsetsFooter: String {
        string(
            en: "Shift an individual time by up to ±30 minutes to match the calendar your mosque follows. Corrections apply everywhere: schedule, widgets and notifications.",
            tr: "Camiinin takip ettiği takvime uyması için her vakti ±30 dakikaya kadar kaydırabilirsin. Düzeltmeler her yerde geçerlidir: liste, widget'lar ve bildirimler.",
            ar: "يمكنك إزاحة أي وقت حتى ±٣٠ دقيقة ليطابق تقويم مسجدك. تُطبَّق التصحيحات في كل مكان: القائمة والأدوات والإشعارات."
        )
    }

    static var offsetsReset: String {
        string(en: "Reset all corrections", tr: "Tüm düzeltmeleri sıfırla", ar: "إعادة تعيين كل التصحيحات")
    }

    static func offsetMinutes(_ minutes: Int) -> String {
        if minutes == 0 { return string(en: "On time", tr: "Değişiklik yok", ar: "بدون تغيير") }
        let sign = minutes > 0 ? "+" : "−"
        let value = abs(minutes)
        return string(en: "\(sign)\(value) min", tr: "\(sign)\(value) dk", ar: "\(sign)\(value) د")
    }

    static func offsetAccessibilityValue(_ prayer: Prayer, _ minutes: Int) -> String {
        "\(prayer.localizedName), \(offsetMinutes(minutes))"
    }

    // MARK: - Offline / provenance

    static var timesOfflineBadge: String {
        string(en: "Calculated on device", tr: "Cihazda hesaplandı", ar: "محسوب على الجهاز")
    }

    static var timesOfflineExplanation: String {
        string(
            en: "No connection right now, so these times come from the built-in astronomical engine. They refresh from the online calendar as soon as you are back online.",
            tr: "Şu an bağlantı yok; bu vakitler cihazdaki astronomik hesaplayıcıdan geliyor. Bağlantı gelir gelmez çevrimiçi takvimden tazelenecek.",
            ar: "لا يوجد اتصال الآن، لذا تأتي هذه الأوقات من المحرك الفلكي داخل التطبيق. ستُحدَّث من التقويم عبر الإنترنت فور عودة الاتصال."
        )
    }

    static var timesPolarUnavailable: String {
        string(
            en: "At this latitude the sun does not rise or set today, so a normal schedule cannot be calculated. Scholars advise following the timings of the nearest moderate latitude — pick a city manually in Settings.",
            tr: "Bu enlemde bugün güneş doğup batmıyor; olağan bir vakit cetveli hesaplanamıyor. Âlimler en yakın ılıman enlemin vakitlerine uymayı tavsiye eder — Ayarlar'dan elle bir şehir seç.",
            ar: "في هذا العرض لا تشرق الشمس ولا تغرب اليوم، فلا يمكن حساب جدول اعتيادي. يوصي أهل العلم باتباع توقيت أقرب عرض معتدل — اختر مدينة يدويًا من الإعدادات."
        )
    }

    static var originDevice: String {
        string(en: "calculated on device", tr: "cihazda hesaplandı", ar: "محسوب على الجهاز")
    }

    static var originNetwork: String {
        string(en: "from the online calendar", tr: "çevrimiçi takvimden", ar: "من التقويم عبر الإنترنت")
    }

    static var originCache: String {
        string(en: "from saved times", tr: "kayıtlı vakitlerden", ar: "من الأوقات المحفوظة")
    }

    static var resolutionTitle: String {
        string(en: "Where this time comes from", tr: "Bu vakit nereden geliyor", ar: "من أين يأتي هذا الوقت")
    }

    static func resolutionMethod(_ name: String) -> String {
        string(en: "Method: \(name)", tr: "Yöntem: \(name)", ar: "الطريقة: \(name)")
    }

    static func resolutionMadhab(_ name: String) -> String {
        string(en: "Asr shadow: \(name)", tr: "İkindi gölgesi: \(name)", ar: "ظل العصر: \(name)")
    }

    static func resolutionAngle(_ prayer: String, _ angle: Double) -> String {
        let formatted = String(format: "%.1f", angle)
        return string(en: "\(prayer) angle: \(formatted)°",
                      tr: "\(prayer) açısı: \(formatted)°",
                      ar: "زاوية \(prayer): \(formatted)°")
    }

    static func resolutionIshaInterval(_ minutes: Int) -> String {
        string(en: "Isha: \(minutes) minutes after maghrib",
               tr: "Yatsı: akşamdan \(minutes) dakika sonra",
               ar: "العشاء: بعد المغرب بـ \(minutes) دقيقة")
    }

    static func resolutionTemkin(_ minutes: Int) -> String {
        let sign = minutes > 0 ? "+" : "−"
        return string(en: "Temkin already included: \(sign)\(abs(minutes)) min",
                      tr: "İçinde temkin var: \(sign)\(abs(minutes)) dk",
                      ar: "يتضمن تمكينًا: \(sign)\(abs(minutes)) د")
    }

    static func resolutionMethodAdjustment(_ minutes: Int) -> String {
        let sign = minutes > 0 ? "+" : "−"
        return string(en: "Method adjustment: \(sign)\(abs(minutes)) min",
                      tr: "Yöntem düzeltmesi: \(sign)\(abs(minutes)) dk",
                      ar: "تعديل الطريقة: \(sign)\(abs(minutes)) د")
    }

    static func resolutionUserOffset(_ minutes: Int) -> String {
        let sign = minutes > 0 ? "+" : "−"
        return string(en: "Your correction: \(sign)\(abs(minutes)) min",
                      tr: "Senin düzeltmen: \(sign)\(abs(minutes)) dk",
                      ar: "تصحيحك: \(sign)\(abs(minutes)) د")
    }

    static func resolutionHighLatitude(_ rule: String) -> String {
        let readable: String
        switch rule {
        case "seventhOfTheNight":
            readable = string(en: "one seventh of the night", tr: "gecenin yedide biri", ar: "سُبع الليل")
        case "twilightAngle":
            readable = string(en: "twilight angle", tr: "şafak açısı", ar: "زاوية الشفق")
        default:
            readable = string(en: "middle of the night", tr: "gece yarısı", ar: "منتصف الليل")
        }
        return string(en: "High-latitude rule: \(readable)",
                      tr: "Yüksek enlem kuralı: \(readable)",
                      ar: "قاعدة العروض العليا: \(readable)")
    }

    static func resolutionUpdatedAt(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: L10n.localeIdentifier)
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        let value = formatter.string(from: date)
        return string(en: "Updated \(value)", tr: "Güncellendi: \(value)", ar: "آخر تحديث: \(value)")
    }
}
