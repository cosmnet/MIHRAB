import Foundation

// Qur'an reader copy.
//
// Tone rule for this surface: the app never speaks *for* the text. It labels,
// it navigates, it credits — it does not interpret, praise or promise reward.
// Where content is missing the copy says so plainly rather than apologising.
extension L10n {

    // MARK: - Entry

    static var quranTitle: String { string(en: "Qur'an", tr: "Kur'an", ar: "القرآن") }
    static var quranSubtitle: String {
        string(en: "Read the full Arabic text, offline",
               tr: "Arapça tam metni çevrimdışı oku",
               ar: "اقرأ النص العربي كاملاً دون اتصال")
    }
    static var quranOpen: String { string(en: "Open", tr: "Aç", ar: "افتح") }
    static var quranFree: String {
        string(en: "Always free", tr: "Her zaman ücretsiz", ar: "مجاني دائماً")
    }

    // MARK: - Library

    static var quranSuras: String { string(en: "Suras", tr: "Sureler", ar: "السور") }
    static var quranJuz: String { string(en: "Juz", tr: "Cüz", ar: "الأجزاء") }
    static var quranHizb: String { string(en: "Hizb", tr: "Hizb", ar: "الأحزاب") }
    static var quranBookmarks: String { string(en: "Bookmarks", tr: "Yer imleri", ar: "العلامات") }

    static func quranJuzNumber(_ n: Int) -> String {
        string(en: "Juz \(n)", tr: "\(n). Cüz", ar: "الجزء \(n)")
    }
    static func quranHizbNumber(_ n: Int) -> String {
        string(en: "Hizb \(n)", tr: "\(n). Hizb", ar: "الحزب \(n)")
    }
    static func quranPageNumber(_ n: Int) -> String {
        string(en: "Page \(n)", tr: "Sayfa \(n)", ar: "صفحة \(n)")
    }
    static func quranAyahCount(_ n: Int) -> String {
        string(en: n == 1 ? "1 ayah" : "\(n) ayahs", tr: "\(n) ayet", ar: "\(n) آية")
    }
    static var quranMeccan: String { string(en: "Meccan", tr: "Mekkî", ar: "مكية") }
    static var quranMedinan: String { string(en: "Medinan", tr: "Medenî", ar: "مدنية") }

    static var quranSearchPrompt: String {
        string(en: "Search the Qur'an", tr: "Kur'an'da ara", ar: "ابحث في القرآن")
    }
    static var quranSearchHint: String {
        string(en: "Search Arabic without diacritics, or jump to a reference like 2:255.",
               tr: "Arapçayı harekesiz arayabilir ya da 2:255 gibi bir referansa atlayabilirsin.",
               ar: "ابحث بالعربية دون تشكيل، أو انتقل إلى مرجع مثل ٢:٢٥٥.")
    }
    static func quranSearchResults(_ n: Int) -> String {
        string(en: n == 1 ? "1 result" : "\(n) results", tr: "\(n) sonuç", ar: "\(n) نتيجة")
    }
    static var quranSearchEmptyTitle: String {
        string(en: "Nothing found", tr: "Sonuç yok", ar: "لا توجد نتائج")
    }
    static var quranSearchEmptyBody: String {
        string(en: "Try fewer letters, or drop the diacritics — the search ignores them.",
               tr: "Daha az harf dene ya da harekeleri bırak — arama zaten yok sayıyor.",
               ar: "جرّب حروفاً أقل، أو احذف التشكيل — البحث يتجاهله.")
    }
    static var quranSearchMatchedTranslation: String {
        string(en: "In the translation", tr: "Mealde", ar: "في الترجمة")
    }
    static var quranJumpToReference: String {
        string(en: "Go to", tr: "Şuraya git", ar: "اذهب إلى")
    }

    // MARK: - Resume

    static var quranResumeTitle: String {
        string(en: "Where you left off", tr: "Kaldığın yer", ar: "حيث توقفت")
    }
    static var quranResumeAction: String { string(en: "Continue", tr: "Devam et", ar: "متابعة") }
    static var quranStartReading: String {
        string(en: "Start reading", tr: "Okumaya başla", ar: "ابدأ القراءة")
    }

    // MARK: - Reader

    static var quranLoading: String {
        string(en: "Opening the mushaf…", tr: "Mushaf açılıyor…", ar: "يُفتح المصحف…")
    }
    static var quranLoadFailedTitle: String {
        string(en: "The text could not be opened", tr: "Metin açılamadı", ar: "تعذّر فتح النص")
    }
    static var quranLoadFailedBody: String {
        string(
            en: "The bundled Qur'an file is missing or unreadable. Reinstalling the app restores it — nothing you saved is lost.",
            tr: "Uygulamayla gelen Kur'an dosyası eksik ya da okunamıyor. Uygulamayı yeniden yüklemek dosyayı geri getirir — kaydettiklerin kaybolmaz.",
            ar: "ملف القرآن المرفق مفقود أو غير قابل للقراءة. إعادة تثبيت التطبيق تُعيده، ولن تفقد ما حفظت."
        )
    }
    static var quranSajdaMark: String {
        string(en: "Prostration", tr: "Secde ayeti", ar: "آية سجدة")
    }
    static var quranSajdaObligatory: String {
        string(en: "Obligatory prostration", tr: "Tilâvet secdesi (vâcib)", ar: "سجدة واجبة")
    }
    static var quranSajdaRecommended: String {
        string(en: "Recommended prostration", tr: "Tilâvet secdesi (müstehap)", ar: "سجدة مستحبة")
    }
    static var quranSajdaSchoolsNote: String {
        string(
            en: "Schools differ on which prostrations are obligatory. This label follows the classification published with the text.",
            tr: "Hangi secdenin vâcib olduğu mezheplere göre değişir. Buradaki etiket metinle birlikte yayımlanan tasnifi izler.",
            ar: "تختلف المذاهب في وجوب السجدات؛ هذا التصنيف هو المنشور مع النص."
        )
    }

    static var quranPreviousSura: String {
        string(en: "Previous sura", tr: "Önceki sure", ar: "السورة السابقة")
    }
    static var quranNextSura: String {
        string(en: "Next sura", tr: "Sonraki sure", ar: "السورة التالية")
    }

    // MARK: - Ayah actions

    static var quranCopy: String { string(en: "Copy", tr: "Kopyala", ar: "نسخ") }
    static var quranCopied: String { string(en: "Copied", tr: "Kopyalandı", ar: "تم النسخ") }
    static var quranShareVerse: String {
        string(en: "Share this ayah", tr: "Ayeti paylaş", ar: "شارك الآية")
    }
    static var quranAddBookmark: String {
        string(en: "Bookmark", tr: "Yer imi ekle", ar: "أضف علامة")
    }
    static var quranRemoveBookmark: String {
        string(en: "Remove bookmark", tr: "Yer imini kaldır", ar: "أزل العلامة")
    }
    static var quranSetResume: String {
        string(en: "Mark as where I stopped", tr: "Kaldığım yer olarak işaretle", ar: "علّم كموضع التوقف")
    }
    static var quranBookmarksEmptyTitle: String {
        string(en: "No bookmarks yet", tr: "Henüz yer imi yok", ar: "لا توجد علامات بعد")
    }
    static var quranBookmarksEmptyBody: String {
        string(en: "Press and hold any ayah to bookmark it. Bookmarks are free and unlimited.",
               tr: "Herhangi bir ayete basılı tutarak yer imi ekle. Yer imleri ücretsiz ve sınırsız.",
               ar: "اضغط مطولاً على أي آية لإضافة علامة. العلامات مجانية وبلا حدّ.")
    }
    static var quranBookmarkNotePrompt: String {
        string(en: "Note (optional)", tr: "Not (isteğe bağlı)", ar: "ملاحظة (اختياري)")
    }

    // MARK: - Display settings

    static var quranDisplay: String { string(en: "Display", tr: "Görünüm", ar: "العرض") }
    static var quranTextSize: String { string(en: "Text size", tr: "Punto", ar: "حجم الخط") }
    static var quranLineSpacing: String {
        string(en: "Line spacing", tr: "Satır aralığı", ar: "تباعد الأسطر")
    }
    static var quranReadingMode: String {
        string(en: "Reading mode", tr: "Okuma modu", ar: "وضع القراءة")
    }
    static var quranModeNight: String { string(en: "Night", tr: "Gece", ar: "ليلي") }
    static var quranModeSepia: String { string(en: "Paper", tr: "Kâğıt", ar: "ورقي") }
    static var quranModeDay: String { string(en: "Day", tr: "Gündüz", ar: "نهاري") }
    static var quranFlowTitle: String { string(en: "Layout", tr: "Akış", ar: "التنسيق") }
    static var quranFlowVerse: String { string(en: "Verse by verse", tr: "Ayet ayet", ar: "آية آية") }
    static var quranFlowContinuous: String {
        string(en: "Continuous", tr: "Kesintisiz", ar: "متصل")
    }
    static var quranTypography: String {
        string(en: "Typography", tr: "Tipografi", ar: "الطباعة")
    }
    static var quranThemeClassic: String { string(en: "Classic", tr: "Klasik", ar: "كلاسيكي") }
    static var quranThemeMushaf: String { string(en: "Mushaf", tr: "Mushaf", ar: "مصحفي") }
    static var quranThemeScholar: String { string(en: "Scholar", tr: "Tetkik", ar: "دراسي") }
    static var quranKeepAwake: String {
        string(en: "Keep the screen on", tr: "Ekran açık kalsın", ar: "أبقِ الشاشة مضاءة")
    }

    // MARK: - Translation layer (currently empty on purpose)

    static var quranTranslation: String { string(en: "Translation", tr: "Meal", ar: "الترجمة") }
    static var quranShowTranslation: String {
        string(en: "Show translation", tr: "Meali göster", ar: "أظهر الترجمة")
    }
    static var quranNoTranslationTitle: String {
        string(en: "No translation is bundled",
               tr: "Uygulamada meal yok",
               ar: "لا توجد ترجمة مرفقة")
    }
    static var quranNoTranslationBody: String {
        string(
            en: "The Arabic text ships under a Creative Commons licence, so it is here in full. Every translation we reviewed is either copyrighted or licensed for non-commercial use only, and Mihrab will not ship text it has no right to — or invent one.",
            tr: "Arapça metin Creative Commons lisanslı olduğu için eksiksiz burada. İncelediğimiz her meal ya telifli ya da yalnızca ticari olmayan kullanıma açık. Mihrab hakkı olmayan bir metni yayımlamaz — uydurmaz da.",
            ar: "النص العربي مرخّص برخصة المشاع الإبداعي فهو هنا كاملاً. أما الترجمات التي راجعناها فمحمية أو مرخّصة لغير الأغراض التجارية، ولن ينشر مِحراب نصاً لا يملك حقه ولن يختلقه."
        )
    }
    static var quranNoTranslationDetail: String {
        string(en: "What we checked", tr: "Neye baktık", ar: "ما راجعناه")
    }

    // MARK: - Licence

    static var quranTextSource: String {
        string(en: "Text source", tr: "Metin kaynağı", ar: "مصدر النص")
    }
    static var quranLicenceTitle: String {
        string(en: "About this text", tr: "Bu metin hakkında", ar: "عن هذا النص")
    }
    static var quranLicenceIntro: String {
        string(
            en: "The Arabic text is the Tanzil Project's verified Uthmani edition, reproduced verbatim under a Creative Commons Attribution licence. Not one character has been altered.",
            tr: "Arapça metin, Tanzil Project'in doğrulanmış Osmanî sürümüdür; Creative Commons Atıf lisansı altında birebir aktarılmıştır. Tek bir karakteri değiştirilmemiştir.",
            ar: "النص العربي هو نسخة مشروع تنزيل العثمانية المدقّقة، منقولة حرفياً برخصة المشاع الإبداعي — لم يُغيَّر منه حرف."
        )
    }
    static var quranVisitSource: String {
        string(en: "tanzil.net", tr: "tanzil.net", ar: "tanzil.net")
    }

    // MARK: - Settings section

    static var quranSectionTitle: String { string(en: "Qur'an", tr: "Kur'an", ar: "القرآن") }
    static var quranSettingsHint: String {
        string(en: "Opens the reader. Reading, bookmarks and hatim tracking are free.",
               tr: "Okuyucuyu açar. Okuma, yer imleri ve hatim takibi ücretsizdir.",
               ar: "يفتح القارئ. القراءة والعلامات ومتابعة الختمة مجانية.")
    }
    static var quranStatsToday: String { string(en: "Today", tr: "Bugün", ar: "اليوم") }
    static func quranStreakDays(_ n: Int) -> String {
        string(en: n == 1 ? "1 day" : "\(n) days", tr: "\(n) gün", ar: "\(n) يوم")
    }
    static var quranStreakLabel: String { string(en: "Streak", tr: "Seri", ar: "التتابع") }
}
