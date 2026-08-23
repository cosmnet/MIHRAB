import Foundation

// Religious-calendar copy. Names and *dating rules* only — no narrated
// traditions, no claims of merit that would need a chain of transmission.
extension L10n {

    // MARK: - Screen chrome

    static var calendarTitle: String {
        string(en: "Religious Calendar", tr: "Dinî Takvim", ar: "التقويم الديني")
    }
    static var calendarSubtitle: String {
        string(en: "Holy nights, the three months and voluntary fasts",
               tr: "Kandiller, üç aylar ve nafile oruçlar",
               ar: "الليالي المباركة والأشهر الثلاثة وصيام التطوع")
    }
    static var calendarUpcoming: String { string(en: "UPCOMING", tr: "YAKLAŞAN", ar: "القادم") }
    static var calendarThisYear: String { string(en: "THIS HIJRI YEAR", tr: "BU HİCRÎ YIL", ar: "هذا العام الهجري") }
    static var calendarFasts: String { string(en: "VOLUNTARY FASTS", tr: "NAFİLE ORUÇLAR", ar: "صيام التطوع") }
    static var calendarTonight: String { string(en: "Tonight", tr: "Bu akşam", ar: "هذه الليلة") }
    static var calendarToday: String { string(en: "Today", tr: "Bugün", ar: "اليوم") }
    static var calendarTomorrow: String { string(en: "Tomorrow", tr: "Yarın", ar: "غداً") }
    static var calendarThreeMonths: String { string(en: "The three months", tr: "Üç aylar", ar: "الأشهر الثلاثة") }
    static func calendarThreeMonthsRange(_ range: String) -> String {
        string(en: "Rajab → Ramadan · \(range)", tr: "Recep → Ramazan · \(range)", ar: "رجب ← رمضان · \(range)")
    }
    static var calendarPreviousYear: String { string(en: "Previous year", tr: "Önceki yıl", ar: "العام السابق") }
    static var calendarNextYear: String { string(en: "Next year", tr: "Sonraki yıl", ar: "العام القادم") }
    static var calendarOpenFull: String { string(en: "Full calendar", tr: "Tüm takvim", ar: "التقويم الكامل") }
    static var calendarNoUpcoming: String {
        string(en: "Nothing in the next few weeks", tr: "Önümüzdeki haftalarda bir gün yok", ar: "لا شيء في الأسابيع القادمة")
    }
    static var calendarNoUpcomingBody: String {
        string(en: "The next entries will appear here as they approach.",
               tr: "Yaklaşan günler burada görünecek.",
               ar: "ستظهر الأيام القادمة هنا عند اقترابها.")
    }

    /// The honesty note. Shown wherever a date is displayed.
    static var calendarAccuracyNote: String {
        string(
            en: "Dates are computed with the Umm al-Qura calendar. The Diyanet calendar used in Türkiye is calculated separately and may differ by ±1 day — take the printed Diyanet calendar as the authority.",
            tr: "Tarihler Ümmü'l-Kurâ takvimiyle hesaplanır. Türkiye'de kullanılan Diyanet hesaplamalı takvimi ayrı hesaplanır ve ±1 gün fark edebilir — esas olan Diyanet takvimidir.",
            ar: "تُحسب التواريخ بتقويم أم القرى، وقد يختلف تقويم ديانت التركي بمقدار يوم واحد."
        )
    }

    /// The evening rule, said plainly.
    static var calendarEveningRule: String {
        string(
            en: "An Islamic day begins at maghrib. A holy night therefore starts on the evening of the previous day.",
            tr: "İslamî gün akşam ezanıyla başlar. Bu yüzden kandil gecesi bir önceki günün akşamıdır.",
            ar: "يبدأ اليوم الهجري من المغرب، فليلة الاحتفال هي مساء اليوم السابق."
        )
    }

    static func calendarBeginsAt(_ time: String, day: String) -> String {
        string(en: "Begins \(day) at \(time) (maghrib)",
               tr: "\(day) \(time)'de (akşam ezanı) başlar",
               ar: "يبدأ \(day) الساعة \(time) (المغرب)")
    }
    static var calendarBeginsAtMaghribUnknown: String {
        string(en: "Begins at maghrib the evening before",
               tr: "Bir önceki akşam, akşam ezanıyla başlar",
               ar: "يبدأ مع أذان المغرب في المساء السابق")
    }
    static func calendarDaysLeft(_ n: Int) -> String {
        if n == 0 { return string(en: "Today", tr: "Bugün", ar: "اليوم") }
        if n == 1 { return string(en: "1 day", tr: "1 gün", ar: "يوم") }
        return string(en: "\(n) days", tr: "\(n) gün", ar: "\(n) يوم")
    }
    static var calendarFastForbidden: String {
        string(en: "Fasting is not kept on this day", tr: "Bu günde oruç tutulmaz", ar: "لا يُصام هذا اليوم")
    }
    static var calendarFastsNote: String {
        string(
            en: "Voluntary fasts are recommendations, not obligations. Ramadan is excluded here because it is obligatory.",
            tr: "Nafile oruçlar tavsiyedir, farz değildir. Ramazan farz olduğu için bu listede yer almaz.",
            ar: "صيام التطوع مستحب لا واجب، ورمضان غير مدرج لأنه فرض."
        )
    }

    // MARK: - Observance names

    static func observanceName(_ key: String) -> String {
        switch key {
        case "hijriNewYear": string(en: "Hijri New Year", tr: "Hicrî Yılbaşı", ar: "رأس السنة الهجرية")
        case "ashura": string(en: "Day of Ashura", tr: "Aşure Günü", ar: "يوم عاشوراء")
        case "mawlid": string(en: "Mawlid", tr: "Mevlid Kandili", ar: "المولد النبوي")
        case "threeMonthsStart": string(en: "Rajab begins — the three months", tr: "Recep — üç aylar başlıyor", ar: "بداية رجب — الأشهر الثلاثة")
        case "regaib": string(en: "Raghaib", tr: "Regaib Kandili", ar: "ليلة الرغائب")
        case "miraj": string(en: "Mi'raj", tr: "Miraç Kandili", ar: "ليلة الإسراء والمعراج")
        case "shaban": string(en: "Sha'ban begins", tr: "Şaban ayı başlıyor", ar: "بداية شعبان")
        case "barat": string(en: "Bara'ah", tr: "Berat Kandili", ar: "ليلة البراءة")
        case "ramadanStart": string(en: "Ramadan begins", tr: "Ramazan başlıyor", ar: "بداية رمضان")
        case "qadr": string(en: "Laylat al-Qadr", tr: "Kadir Gecesi", ar: "ليلة القدر")
        case "eidFitrEve": string(en: "Eve of Eid al-Fitr", tr: "Ramazan Bayramı Arefesi", ar: "ليلة عيد الفطر")
        case "eidFitr": string(en: "Eid al-Fitr", tr: "Ramazan Bayramı", ar: "عيد الفطر")
        case "arafah": string(en: "Day of Arafah", tr: "Arefe Günü", ar: "يوم عرفة")
        case "eidAdha": string(en: "Eid al-Adha", tr: "Kurban Bayramı", ar: "عيد الأضحى")
        default: key
        }
    }

    /// One factual sentence. Encyclopedic or calendrical only.
    static func observanceNote(_ key: String) -> String {
        switch key {
        case "hijriNewYear":
            return string(en: "The first day of Muharram opens the Hijri year, counted from the Hijra to Medina.",
                          tr: "Muharrem'in ilk günü hicrî yılı açar; hicrî takvim Medine'ye hicretten itibaren sayılır.",
                          ar: "أول المحرم يفتتح السنة الهجرية المحسوبة من الهجرة إلى المدينة.")
        case "ashura":
            return string(en: "The tenth of Muharram. In Türkiye it is also marked by cooking and sharing aşure.",
                          tr: "Muharrem'in onuncu günü. Türkiye'de aşure pişirip paylaşma geleneğiyle de anılır.",
                          ar: "عاشر المحرم، ويُطبخ فيه العاشوراء ويُوزَّع في تركيا.")
        case "mawlid":
            return string(en: "Marks the birth of the Prophet Muhammad, observed on 12 Rabi' al-Awwal.",
                          tr: "Hz. Peygamber'in doğumunun anıldığı gecedir; 12 Rebîülevvel'de kutlanır.",
                          ar: "ليلة مولد النبي محمد، وتُحيا في ١٢ ربيع الأول.")
        case "threeMonthsStart":
            return string(en: "Rajab opens the three months — Rajab, Sha'ban, Ramadan — a period of increased worship in Turkish practice.",
                          tr: "Recep, üç ayları açar: Recep, Şaban, Ramazan. Türkiye'de ibadetin yoğunlaştığı dönemdir.",
                          ar: "يفتتح رجب الأشهر الثلاثة: رجب وشعبان ورمضان.")
        case "regaib":
            return string(en: "Observed on the first Friday night of Rajab — a weekday rule, so its date moves every year.",
                          tr: "Recep ayının ilk cuma gecesinde idrak edilir; tarihi sabit değildir, her yıl değişir.",
                          ar: "تُحيا في أول ليلة جمعة من رجب، فتاريخها يتغير كل عام.")
        case "miraj":
            return string(en: "Commemorates the night journey and ascension, observed on 27 Rajab.",
                          tr: "İsrâ ve Miraç hadisesinin anıldığı gecedir; 27 Recep'te idrak edilir.",
                          ar: "ليلة الإسراء والمعراج، وتُحيا في ٢٧ رجب.")
        case "shaban":
            return string(en: "The second of the three months.",
                          tr: "Üç ayların ikincisi.",
                          ar: "ثاني الأشهر الثلاثة.")
        case "barat":
            return string(en: "Observed on the night of 15 Sha'ban.",
                          tr: "Şaban ayının 15. gecesinde idrak edilir.",
                          ar: "تُحيا ليلة النصف من شعبان.")
        case "ramadanStart":
            return string(en: "The month of fasting begins. Its first taraweeh is prayed the night before the first fast.",
                          tr: "Oruç ayı başlar. İlk teravih, ilk orucun bir önceki akşamında kılınır.",
                          ar: "يبدأ شهر الصيام، وتُصلى أول تراويح في الليلة السابقة لأول صوم.")
        case "qadr":
            return string(en: "Sought in the last ten nights of Ramadan; in Türkiye it is observed on the night of 27 Ramadan.",
                          tr: "Ramazan'ın son on gecesinde aranır; Türkiye'de 27. gece idrak edilir.",
                          ar: "تُلتمس في العشر الأواخر، وتُحيا في تركيا ليلة السابع والعشرين.")
        case "eidFitrEve":
            return string(en: "The last day of Ramadan. Fitre is given before the eid prayer.",
                          tr: "Ramazan'ın son günü. Fitre, bayram namazından önce verilir.",
                          ar: "آخر أيام رمضان، وتُخرج الفطرة قبل صلاة العيد.")
        case "eidFitr":
            return string(en: "Three days beginning 1 Shawwal. Fasting is not kept on the first day.",
                          tr: "1 Şevval'de başlayan üç günlük bayram. Bayramın ilk günü oruç tutulmaz.",
                          ar: "ثلاثة أيام تبدأ في ١ شوال، ولا يُصام أولها.")
        case "arafah":
            return string(en: "9 Dhul-Hijjah, when pilgrims stand at Arafat.",
                          tr: "9 Zilhicce; hacıların Arafat'ta vakfeye durduğu gündür.",
                          ar: "التاسع من ذي الحجة، يوم الوقوف بعرفة.")
        case "eidAdha":
            return string(en: "Four days beginning 10 Dhul-Hijjah. Fasting is not kept on any of them.",
                          tr: "10 Zilhicce'de başlayan dört günlük bayram. Bu günlerde oruç tutulmaz.",
                          ar: "أربعة أيام تبدأ في ١٠ ذي الحجة، ولا يُصام فيها.")
        default:
            return ""
        }
    }

    /// The dating rule, shown as a caption so the user can check it themselves.
    static func observanceRule(_ key: String) -> String {
        switch key {
        case "hijriNewYear": return string(en: "1 Muharram", tr: "1 Muharrem", ar: "١ محرم")
        case "ashura": return string(en: "10 Muharram", tr: "10 Muharrem", ar: "١٠ محرم")
        case "mawlid": return string(en: "Night of 12 Rabi' al-Awwal", tr: "12 Rebîülevvel gecesi", ar: "ليلة ١٢ ربيع الأول")
        case "threeMonthsStart": return string(en: "1 Rajab", tr: "1 Recep", ar: "١ رجب")
        case "regaib": return string(en: "First Friday night of Rajab", tr: "Recep'in ilk cuma gecesi", ar: "أول ليلة جمعة من رجب")
        case "miraj": return string(en: "Night of 27 Rajab", tr: "27 Recep gecesi", ar: "ليلة ٢٧ رجب")
        case "shaban": return string(en: "1 Sha'ban", tr: "1 Şaban", ar: "١ شعبان")
        case "barat": return string(en: "Night of 15 Sha'ban", tr: "15 Şaban gecesi", ar: "ليلة ١٥ شعبان")
        case "ramadanStart": return string(en: "1 Ramadan", tr: "1 Ramazan", ar: "١ رمضان")
        case "qadr": return string(en: "Night of 27 Ramadan", tr: "27 Ramazan gecesi", ar: "ليلة ٢٧ رمضان")
        case "eidFitrEve": return string(en: "Last day of Ramadan", tr: "Ramazan'ın son günü", ar: "آخر يوم من رمضان")
        case "eidFitr": return string(en: "1–3 Shawwal", tr: "1–3 Şevval", ar: "١–٣ شوال")
        case "arafah": return string(en: "9 Dhul-Hijjah", tr: "9 Zilhicce", ar: "٩ ذو الحجة")
        case "eidAdha": return string(en: "10–13 Dhul-Hijjah", tr: "10–13 Zilhicce", ar: "١٠–١٣ ذو الحجة")
        default: return ""
        }
    }

    // MARK: - Voluntary fasts

    static func fastKindName(_ kind: VoluntaryFastKind) -> String {
        switch kind {
        case .weekly: string(en: "Monday & Thursday", tr: "Pazartesi – Perşembe", ar: "الاثنين والخميس")
        case .whiteDays: string(en: "White days", tr: "Eyyâm-ı bîd", ar: "الأيام البيض")
        case .ashura: string(en: "Tasu'a & Ashura", tr: "Tâsûâ ve Aşure", ar: "تاسوعاء وعاشوراء")
        case .dhulHijjah: string(en: "First ten of Dhul-Hijjah", tr: "Zilhicce'nin ilk on günü", ar: "عشر ذي الحجة")
        case .arafah: string(en: "Day of Arafah", tr: "Arefe Günü", ar: "يوم عرفة")
        case .shawwalSix: string(en: "Six days of Shawwal", tr: "Şevval orucu (altı gün)", ar: "ست من شوال")
        }
    }

    static func fastKindNote(_ kind: VoluntaryFastKind) -> String {
        switch kind {
        case .weekly:
            string(en: "Kept weekly on Mondays and Thursdays.", tr: "Her hafta pazartesi ve perşembe günleri tutulur.", ar: "يُصام كل اثنين وخميس.")
        case .whiteDays:
            string(en: "The 13th, 14th and 15th of each Hijri month, when the moon is full.", tr: "Her hicrî ayın 13, 14 ve 15. günleri — ayın dolunay olduğu günler.", ar: "الثالث عشر والرابع عشر والخامس عشر من كل شهر هجري.")
        case .ashura:
            string(en: "9 and 10 Muharram, kept together.", tr: "9 ve 10 Muharrem, birlikte tutulur.", ar: "التاسع والعاشر من المحرم معاً.")
        case .dhulHijjah:
            string(en: "The first nine days of Dhul-Hijjah. The tenth is the bayram, when fasting is not kept.", tr: "Zilhicce'nin ilk dokuz günü. Onuncu gün bayramdır, oruç tutulmaz.", ar: "الأيام التسعة الأولى من ذي الحجة، والعاشر عيد لا يُصام.")
        case .arafah:
            string(en: "9 Dhul-Hijjah, the day before Eid al-Adha.", tr: "9 Zilhicce, Kurban Bayramı'ndan bir önceki gün.", ar: "التاسع من ذي الحجة، اليوم السابق للعيد.")
        case .shawwalSix:
            string(en: "Any six days of Shawwal after the bayram; the days shown here are simply the first run.", tr: "Bayramdan sonra Şevval'in herhangi altı gününde tutulabilir; burada gösterilenler yalnızca ilk sıradır.", ar: "ستة أيام من شوال بعد العيد، وما يظهر هنا أول ترتيب ممكن.")
        }
    }
}
