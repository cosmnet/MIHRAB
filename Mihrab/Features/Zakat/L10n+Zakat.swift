import Foundation

// Zakat copy. Two rules held throughout: never state a fatwa, never state a
// price we did not get from the user.
extension L10n {

    static var zakatTitle: String { string(en: "Zakat Calculator", tr: "Zekât Hesaplayıcı", ar: "حاسبة الزكاة") }
    static var zakatSubtitle: String {
        string(en: "Work out what is due, item by item",
               tr: "Kalem kalem hesapla",
               ar: "احسب ما يجب، بنداً بنداً")
    }
    static var zakatCancel: String { string(en: "Cancel", tr: "Vazgeç", ar: "إلغاء") }
    static var zakatReset: String { string(en: "Clear the worksheet", tr: "Hesabı temizle", ar: "مسح الحساب") }

    // MARK: - Prices

    static var zakatPricesHeader: String { string(en: "CURRENT GRAM PRICES", tr: "GÜNCEL GRAM FİYATLARI", ar: "أسعار الغرام الحالية") }
    static var zakatGoldPrice: String { string(en: "Gold, current price per gram", tr: "Altın, güncel gram fiyatı", ar: "سعر غرام الذهب الحالي") }
    static var zakatSilverPrice: String { string(en: "Silver, current price per gram", tr: "Gümüş, güncel gram fiyatı", ar: "سعر غرام الفضة الحالي") }
    static var zakatPricesNote: String {
        string(
            en: "Enter today's prices yourself. Mihrab does not fetch them: there is no free, reliable price source we can stand behind, and a stale price would quietly give you the wrong zakat.",
            tr: "Fiyatları kendin gir. Mihrab bunları çekmiyor: arkasında durabileceğimiz ücretsiz ve güvenilir bir kaynak yok; eski bir fiyat ise zekâtı sessizce yanlış hesaplar.",
            ar: "أدخل الأسعار بنفسك؛ لا نجلبها لعدم وجود مصدر مجاني موثوق، والسعر القديم يعطي زكاة خاطئة."
        )
    }
    static func zakatPricesUpdated(_ date: String) -> String {
        string(en: "Last entered \(date)", tr: "Son giriş: \(date)", ar: "آخر إدخال \(date)")
    }
    static var zakatPricesStale: String {
        string(en: "These prices may be out of date — check before you rely on the result.",
               tr: "Bu fiyatlar eskimiş olabilir — sonuca güvenmeden önce kontrol et.",
               ar: "قد تكون هذه الأسعار قديمة، فتحقق قبل الاعتماد على النتيجة.")
    }
    static var zakatPricesMissing: String {
        string(en: "Enter a gram price to see the nisab threshold.",
               tr: "Nisap eşiğini görmek için gram fiyatı gir.",
               ar: "أدخل سعر الغرام لعرض حد النصاب.")
    }
    static var zakatStampPrices: String { string(en: "Prices are current", tr: "Fiyatlar güncel", ar: "الأسعار محدثة") }

    // MARK: - Nisab

    static var zakatNisabHeader: String { string(en: "NISAB", tr: "NİSAP", ar: "النصاب") }

    /// Names the authority whose figures are on screen. The user asked us not
    /// to make them decide; the least we owe them is to say who did.
    static var zakatSourceDiyanet: String {
        string(en: "Figures from the Presidency of Religious Affairs (Diyanet İşleri Başkanlığı)",
               tr: "Rakamlar Diyanet İşleri Başkanlığı'ndan",
               ar: "الأرقام من رئاسة الشؤون الدينية التركية (ديانت)")
    }

    static var zakatBasisGold: String {
        string(en: "Gold — 80.18 g (Diyanet)", tr: "Altın — 80,18 gr (Diyanet)", ar: "الذهب — ٨٠٫١٨ غ (ديانت)")
    }
    static var zakatBasisSilver: String {
        string(en: "Silver — 561 g (classical)", tr: "Gümüş — 561 gr (klasik görüş)", ar: "الفضة — ٥٦١ غ (القول الكلاسيكي)")
    }
    static var zakatSilver595: String { string(en: "595 g (200 dirhem × 2.975 g)", tr: "595 gr (200 dirhem × 2,975 gr)", ar: "٥٩٥ غ") }
    static var zakatSilver561: String { string(en: "561 g (200 dirhem × 2.805 g)", tr: "561 gr (200 dirhem × 2,805 gr)", ar: "٥٦١ غ") }

    /// Shown under the gold basis. This is the recommended, pre-selected one.
    static var zakatBasisGoldNote: String {
        string(
            en: "This is what Diyanet recommends, and it is already selected. Its ruling is that the value of 80.18 g of 24-carat gold should be the threshold for everything you hold — cash, silver, trade goods and investments alike.",
            tr: "Diyanet'in tavsiyesi budur ve seçili gelir. Kararına göre 24 ayar 80,18 gram altının değeri; nakit, gümüş, ticaret malı ve yatırımlar dâhil elindeki her şey için nisap ölçüsüdür.",
            ar: "هذا ما توصي به ديانت وهو المحدد مسبقاً: قيمة ٨٠٫١٨ غراماً من الذهب عيار ٢٤ هي النصاب لكل ما تملك."
        )
    }

    /// Shown under the silver basis. Says plainly that it is *not* Diyanet's.
    static var zakatBasisSilverNote: String {
        string(
            en: "The classical 200-dirhem threshold. It is a recognised opinion, but it is not Diyanet's: Diyanet holds that silver has lost too much of its historical value to serve as the measure, and says to use the gold figure even for silver. The silver threshold is much lower, so choosing it makes more people liable.",
            tr: "Klasik 200 dirhem nisabı. Muteber bir görüştür ama Diyanet'in görüşü değildir: Diyanet, gümüşün tarihî değerini büyük ölçüde yitirdiğini, bu yüzden gümüş için de altın ölçüsünün alınmasını uygun görür. Gümüş nisabı çok daha düşüktür; onu seçmek daha çok kişiyi mükellef kılar.",
            ar: "نصاب ٢٠٠ درهم الكلاسيكي: قول معتبر لكنه ليس قول ديانت، إذ ترى اعتماد نصاب الذهب حتى في الفضة. ونصاب الفضة أدنى بكثير فيوسّع دائرة الوجوب."
        )
    }

    static var zakatBasisExplain: String {
        string(
            en: "Diyanet's own answer is already chosen for you. Change it only if you follow a different opinion.",
            tr: "Diyanet'in cevabı senin için seçildi. Başka bir görüşü takip ediyorsan değiştir.",
            ar: "اختير لك قول ديانت. لا تغيّره إلا إن كنت تتبع قولاً آخر."
        )
    }

    static func zakatNisabValue(_ amount: String) -> String {
        string(en: "Threshold: \(amount)", tr: "Nisap: \(amount)", ar: "النصاب: \(amount)")
    }

    // MARK: - Asset lines

    static var zakatAssetsHeader: String { string(en: "WHAT YOU HOLD", tr: "VARLIKLAR", ar: "ما تملك") }
    static var zakatDeductionsHeader: String { string(en: "WHAT COMES OFF", tr: "DÜŞÜLECEKLER", ar: "ما يُخصم") }
    static var zakatCash: String { string(en: "Cash", tr: "Nakit", ar: "نقد") }
    static var zakatBank: String { string(en: "Bank accounts", tr: "Banka hesapları", ar: "حسابات بنكية") }
    static var zakatGoldGrams: String { string(en: "Gold (grams)", tr: "Altın (gram)", ar: "ذهب (غرام)") }
    static var zakatSilverGrams: String { string(en: "Silver (grams)", tr: "Gümüş (gram)", ar: "فضة (غرام)") }
    static var zakatTradeGoods: String { string(en: "Trade goods", tr: "Ticaret malı", ar: "عروض التجارة") }
    static var zakatReceivables: String { string(en: "Money owed to you", tr: "Alacaklar", ar: "الديون لك") }
    static var zakatInvestments: String { string(en: "Investments", tr: "Yatırımlar", ar: "استثمارات") }
    static var zakatDebts: String { string(en: "Debts you owe", tr: "Borçlar", ar: "ديون عليك") }
    static var zakatEssentials: String { string(en: "Essential needs", tr: "Temel ihtiyaçlar", ar: "الحوائج الأصلية") }
    static var zakatEssentialsNote: String {
        string(en: "Housing, food and other basic needs are not zakatable.",
               tr: "Konut, gıda ve benzeri temel ihtiyaçlar zekâta tâbi değildir.",
               ar: "الحوائج الأصلية كالسكن والطعام لا زكاة فيها.")
    }

    // MARK: - Result

    static var zakatResultHeader: String { string(en: "RESULT", tr: "SONUÇ", ar: "النتيجة") }
    static func zakatGross(_ amount: String) -> String {
        string(en: "Total held: \(amount)", tr: "Toplam varlık: \(amount)", ar: "إجمالي المال: \(amount)")
    }
    static func zakatDeductionsLine(_ amount: String) -> String {
        string(en: "Deductions: −\(amount)", tr: "Düşülenler: −\(amount)", ar: "المخصوم: −\(amount)")
    }
    static func zakatNet(_ amount: String) -> String {
        string(en: "Net wealth: \(amount)", tr: "Net varlık: \(amount)", ar: "صافي المال: \(amount)")
    }
    static func zakatDue(_ amount: String) -> String {
        string(en: "Zakat due: \(amount)", tr: "Ödenecek zekât: \(amount)", ar: "الزكاة الواجبة: \(amount)")
    }
    static var zakatRateLine: String {
        string(en: "1/40 of net wealth (2.5%)", tr: "Net varlığın 1/40'ı (%2,5)", ar: "ربع العشر (٢٫٥٪)")
    }
    static var zakatBelowNisab: String {
        string(en: "Below the threshold — no zakat is due on this amount.",
               tr: "Nisabın altında — bu tutar üzerinden zekât gerekmez.",
               ar: "دون النصاب، فلا زكاة على هذا المقدار.")
    }
    static var zakatNoPrices: String {
        string(en: "Enter a gram price and we can compare your wealth to the threshold.",
               tr: "Gram fiyatını gir, varlığını nisapla karşılaştıralım.",
               ar: "أدخل سعر الغرام لنقارن مالك بالنصاب.")
    }

    /// The disclaimer. Shown on the result and burned into the share card.
    static var zakatDisclaimer: String {
        string(
            en: "This is a calculation aid, not a fatwa. Rulings differ between schools and situations — check with someone qualified before you act on it.",
            tr: "Bu bir hesaplama aracıdır, fetva değildir. Hükümler mezhebe ve duruma göre değişir — uygulamadan önce ehline danış.",
            ar: "هذه أداة حساب لا فتوى؛ تختلف الأحكام باختلاف المذاهب والأحوال، فاستشر أهل العلم."
        )
    }

    // MARK: - Zakat year

    static var zakatYearHeader: String { string(en: "ZAKAT YEAR", tr: "ZEKÂT YILI", ar: "الحول") }
    static var zakatHawlExplain: String {
        string(
            en: "Zakat falls due once a full lunar year (havl) has passed over wealth that stayed above the threshold. Record the day your year began and we'll show the anniversary.",
            tr: "Zekât, nisap miktarındaki malın üzerinden bir kameri yıl (havelân-ı havl) geçince gerekir. Yılın başladığı günü kaydet, yıldönümünü gösterelim.",
            ar: "تجب الزكاة بعد حولان الحول على مال بلغ النصاب. سجّل بداية حولك لنعرض موعده."
        )
    }
    static var zakatStartYear: String { string(en: "My zakat year starts today", tr: "Zekât yılım bugün başlıyor", ar: "يبدأ حولي اليوم") }
    static var zakatClearYear: String { string(en: "Clear the date", tr: "Tarihi temizle", ar: "مسح التاريخ") }
    static func zakatAnniversary(_ date: String) -> String {
        string(en: "Next due around \(date)", tr: "Sonraki zekât: yaklaşık \(date)", ar: "الموعد القادم نحو \(date)")
    }
    static func zakatAnniversaryDays(_ n: Int) -> String {
        string(en: n == 1 ? "in 1 day" : "in \(n) days", tr: "\(n) gün sonra", ar: "بعد \(n) يوماً")
    }

    // MARK: - Fitre

    static var fitreTitle: String { string(en: "Fitre", tr: "Fitre", ar: "زكاة الفطر") }
    static var fitreHeader: String { string(en: "FITRE (SADAQAT AL-FITR)", tr: "FİTRE (SADAKA-İ FITIR)", ar: "زكاة الفطر") }
    static var fitrePerPerson: String { string(en: "Amount per person", tr: "Kişi başı tutar", ar: "المبلغ لكل شخص") }
    static var fitrePeople: String { string(en: "People in the household", tr: "Hane halkı sayısı", ar: "عدد أفراد البيت") }
    static func fitreTotal(_ amount: String) -> String {
        string(en: "Total fitre: \(amount)", tr: "Toplam fitre: \(amount)", ar: "إجمالي الفطرة: \(amount)")
    }
    static var fitreNote: String {
        string(
            en: "Fitre is a fixed amount per person, not a percentage, and it is given before the eid prayer. In Türkiye the minimum is announced each year by the Din İşleri Yüksek Kurulu.",
            tr: "Fitre yüzde değil, kişi başı sabit bir tutardır ve bayram namazından önce verilir. Türkiye'de asgari tutar her yıl Din İşleri Yüksek Kurulu'nca açıklanır.",
            ar: "الفطرة مقدار ثابت لكل شخص تُخرج قبل صلاة العيد، ويُعلن حدها الأدنى سنوياً."
        )
    }

    /// One-tap suggestion, shown only while the announced figure is still valid.
    static func fitreDiyanetAmount(_ amount: String) -> String {
        string(en: "Use Diyanet's figure: \(amount)",
               tr: "Diyanet'in tutarını kullan: \(amount)",
               ar: "استخدم مبلغ ديانت: \(amount)")
    }

    static func fitreDiyanetNote(_ date: String) -> String {
        string(
            en: "The Din İşleri Yüksek Kurulu announced this minimum on \(date). It is a floor, not a cap — give more if you can. The same amount is the daily fidye for a missed fast.",
            tr: "Din İşleri Yüksek Kurulu bu asgari tutarı \(date) tarihinde açıkladı. Alt sınırdır, üst sınır değil — gücün yeterse fazlasını ver. Aynı tutar, tutulamayan orucun günlük fidyesidir.",
            ar: "أعلن مجلس الشؤون الدينية هذا الحد الأدنى في \(date). وهو حد أدنى لا أقصى، وهو نفسه فدية اليوم الواحد."
        )
    }

    /// Shown once the announced figure has been superseded.
    static var fitreFigureOutdated: String {
        string(
            en: "This year's figure has not been added yet. Check the amount announced by the Din İşleri Yüksek Kurulu and enter it here.",
            tr: "Bu yılın tutarı henüz eklenmedi. Din İşleri Yüksek Kurulu'nun açıkladığı tutara bakıp buraya gir.",
            ar: "لم يُضف مبلغ هذا العام بعد. راجع ما أعلنه مجلس الشؤون الدينية وأدخله هنا."
        )
    }

    // MARK: - Share

    static var zakatShare: String { string(en: "Share summary", tr: "Özeti paylaş", ar: "مشاركة الملخص") }
    static var zakatShareTitle: String { string(en: "Zakat summary", tr: "Zekât özeti", ar: "ملخص الزكاة") }

    // MARK: - Settings

    static var zakatSectionTitle: String { string(en: "ZAKAT", tr: "ZEKÂT", ar: "الزكاة") }
    static var zakatSettingsHint: String {
        string(en: "Opens the zakat calculator", tr: "Zekât hesaplayıcıyı açar", ar: "يفتح حاسبة الزكاة")
    }
    static var zakatSettingsNoYear: String { string(en: "No date set", tr: "Tarih yok", ar: "لا يوجد تاريخ") }
}
