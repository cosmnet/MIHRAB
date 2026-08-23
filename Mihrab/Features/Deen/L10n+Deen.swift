import Foundation

/// Copy owned by the Esmaül Hüsna / Deen surface. Kept out of `L10n.swift`
/// so the shared catalog stays untouched. Every key is prefixed `esma`/`deen`.
extension L10n {

    // MARK: - Home

    static var esmaHeroCaps: String {
        string(en: "Name of the day", tr: "Günün ismi", ar: "اسم اليوم")
    }

    static var esmaHeroHint: String {
        string(en: "Tap to contemplate", tr: "Tefekkür için dokun", ar: "انقر للتأمل")
    }

    static var esmaJourneyCaps: String {
        string(en: "Your journey", tr: "Yolculuğun", ar: "رحلتك")
    }

    static func esmaDiscovered(_ n: Int) -> String {
        string(
            en: "\(n) of 99 names visited",
            tr: "99 isimden \(n) tanesini gezdin",
            ar: "زرت \(n) من ٩٩ اسماً"
        )
    }

    static func esmaFavoritesCount(_ n: Int) -> String {
        string(en: "\(n) favorites", tr: "\(n) favori", ar: "\(n) مفضّلة")
    }

    static var esmaCollectionsCaps: String {
        string(en: "Collections", tr: "Koleksiyonlar", ar: "المجموعات")
    }

    static func esmaCollectionCount(_ n: Int) -> String {
        string(en: "\(n) names", tr: "\(n) isim", ar: "\(n) اسماً")
    }

    static var esmaDhikrCaps: String {
        string(en: "Dhikr suggestion", tr: "Zikir önerisi", ar: "اقتراح ذكر")
    }

    static func esmaDhikrSuggestion(_ name: String, _ count: Int) -> String {
        string(
            en: "Recite \(name) \(count) times today.",
            tr: "Bugün \(name) ismini \(count) kez zikret.",
            ar: "اذكر \(name) \(count) مرة اليوم."
        )
    }

    static var esmaOpenDhikr: String {
        string(en: "Open the counter", tr: "Zikirmatik'i aç", ar: "افتح المسبحة")
    }

    // MARK: - Browser

    static var esmaViewModeCaps: String {
        string(en: "View", tr: "Görünüm", ar: "العرض")
    }

    static var esmaViewList: String {
        string(en: "List", tr: "Liste", ar: "قائمة")
    }

    static var esmaViewGrid: String {
        string(en: "Grid", tr: "Izgara", ar: "شبكة")
    }

    static var esmaFilterAll: String {
        string(en: "All", tr: "Tümü", ar: "الكل")
    }

    static var esmaFilterFavorites: String {
        string(en: "Favorites", tr: "Favorilerim", ar: "المفضلة")
    }

    static var esmaNoFavorites: String {
        string(en: "No favorites yet.", tr: "Henüz favorin yok.", ar: "لا مفضلات بعد.")
    }

    static var esmaNoFavoritesBody: String {
        string(
            en: "Tap the star on any Name to keep it close.",
            tr: "Bir ismi yanında tutmak için yıldıza dokun.",
            ar: "انقر النجمة بجانب أي اسم لتحتفظ به.")
    }

    // MARK: - Detail

    static var esmaMeaningCaps: String {
        string(en: "Meaning", tr: "Anlamı", ar: "المعنى")
    }

    static var esmaPronunciationCaps: String {
        string(en: "Pronunciation", tr: "Okunuşu", ar: "النطق")
    }

    static var esmaOtherLanguageCaps: String {
        string(en: "In Turkish", tr: "İngilizcesi", ar: "بالإنجليزية")
    }

    static var esmaReflectionCaps: String {
        string(en: "Reflection", tr: "Tefekkür", ar: "تأمل")
    }

    static func esmaReciteTimes(_ n: Int) -> String {
        string(en: "Recite ×\(n)", tr: "\(n) kez zikret", ar: "اذكر ×\(n)")
    }

    static var esmaSwipeHint: String {
        string(en: "Swipe for the next Name", tr: "Sonraki isim için kaydır", ar: "اسحب للاسم التالي")
    }

    static var esmaAddFavorite: String {
        string(en: "Add to favorites", tr: "Favorilere ekle", ar: "أضف إلى المفضلة")
    }

    static var esmaRemoveFavorite: String {
        string(en: "Remove from favorites", tr: "Favorilerden çıkar", ar: "أزل من المفضلة")
    }

    static var esmaShareTitle: String {
        string(en: "A Name of God", tr: "Esmaül Hüsna", ar: "اسم من أسماء الله")
    }

    static var esmaShareAction: String {
        string(en: "Share", tr: "Paylaş", ar: "شارك")
    }

    // MARK: - Collections

    static var esmaCollectionMercy: String {
        string(en: "Mercy & Forgiveness", tr: "Rahmet & Mağfiret", ar: "الرحمة والمغفرة")
    }

    static var esmaCollectionMercyNote: String {
        string(en: "The Names one whispers when hope runs thin.", tr: "Umut azaldığında fısıldanan isimler.", ar: "أسماء تُهمس حين يقلّ الرجاء.")
    }

    static var esmaCollectionMajesty: String {
        string(en: "Power & Majesty", tr: "Kudret & Azamet", ar: "القدرة والعظمة")
    }

    static var esmaCollectionMajestyNote: String {
        string(en: "Names that place the heart in its true size.", tr: "Kalbi gerçek ölçüsüne getiren isimler.", ar: "أسماء تُعيد القلب إلى حجمه الحقيقي.")
    }

    static var esmaCollectionKnowledge: String {
        string(en: "Knowledge & Wisdom", tr: "İlim & Hikmet", ar: "العلم والحكمة")
    }

    static var esmaCollectionKnowledgeNote: String {
        string(en: "Nothing is unseen, nothing unheard.", tr: "Görülmeyen yok, işitilmeyen yok.", ar: "لا شيء يغيب ولا شيء لا يُسمع.")
    }

    static var esmaCollectionProvision: String {
        string(en: "Provision & Generosity", tr: "Rızık & Cömertlik", ar: "الرزق والكرم")
    }

    static var esmaCollectionProvisionNote: String {
        string(en: "Doors open where none were drawn.", tr: "Çizilmemiş yerde kapı açılır.", ar: "تُفتح أبواب حيث لا باب.")
    }

    static var esmaCollectionJustice: String {
        string(en: "Justice & Balance", tr: "Adalet & Denge", ar: "العدل والميزان")
    }

    static var esmaCollectionJusticeNote: String {
        string(en: "Every weight is measured exactly.", tr: "Her tartı tam ölçülür.", ar: "كل وزن يُقاس بدقة.")
    }

    static var esmaCollectionLife: String {
        string(en: "Creation & Refuge", tr: "Yaratılış & Sığınak", ar: "الخلق والملاذ")
    }

    static var esmaCollectionLifeNote: String {
        string(en: "The One who begins, keeps and returns.", tr: "Başlatan, koruyan ve döndüren.", ar: "الذي يبدئ ويحفظ ويعيد.")
    }

    // MARK: - Deen surface

    static var deenSectionLibraryCaps: String {
        string(en: "The ninety-nine", tr: "Doksan dokuz", ar: "التسعة والتسعون")
    }

    static var deenHadithCaps: String {
        string(en: "Read & reflect", tr: "Oku & tefekkür et", ar: "اقرأ وتأمل")
    }
}
