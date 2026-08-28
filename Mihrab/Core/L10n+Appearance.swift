import Foundation

/// Appearance / backdrop copy owned by the Core layer.
/// Prefixed `appr…` so it never collides with the shared catalogue.
extension L10n {

    // MARK: - Sections

    static var apprBackdropSection: String {
        string(en: "Background", tr: "Arka plan", ar: "الخلفية")
    }

    static var apprTextureSection: String {
        string(en: "Texture", tr: "Doku", ar: "النسيج")
    }

    static var apprColourSection: String {
        string(en: "Colour & theme", tr: "Renk ve tema", ar: "اللون والسمة")
    }

    // MARK: - Intensity

    static var apprIntensity: String {
        string(en: "Motion & depth", tr: "Hareket ve derinlik", ar: "الحركة والعمق")
    }

    static var apprIntensityCalm: String {
        string(en: "Calm", tr: "Sakin", ar: "هادئ")
    }

    static var apprIntensityStandard: String {
        string(en: "Balanced", tr: "Dengeli", ar: "متوازن")
    }

    static var apprIntensityVivid: String {
        string(en: "Vivid", tr: "Canlı", ar: "حيّ")
    }

    static var apprIntensityFooter: String {
        string(
            en: "Calm keeps every screen quiet behind the text. Vivid lets the backdrop breathe more. The counter screen always keeps its full texture.",
            tr: "Sakin, metnin arkasını sessiz tutar. Canlı, arka planın daha çok nefes almasına izin verir. Zikirmatik ekranı her zaman tam dokusunu korur.",
            ar: "«هادئ» يُبقي الخلفية ساكنة خلف النص، و«حيّ» يمنحها مساحة أوسع. تحتفظ شاشة العدّاد دائمًا بنسيجها الكامل."
        )
    }

    // MARK: - Card texture

    static var apprCardTexture: String {
        string(en: "Textured cards", tr: "Dokulu kartlar", ar: "بطاقات منقوشة")
    }

    static var apprCardTextureFooter: String {
        string(
            en: "Adds a slow, low-contrast pattern inside cards. Text contrast is preserved either way.",
            tr: "Kartların içine yavaş ve düşük kontrastlı bir desen ekler. Metin kontrastı her iki durumda da korunur.",
            ar: "يضيف نقشًا بطيئًا منخفض التباين داخل البطاقات، مع الحفاظ على وضوح النص."
        )
    }

    // MARK: - Motifs

    static var apprDhikrMotif: String {
        string(en: "Counter backdrop", tr: "Zikirmatik arka planı", ar: "خلفية العدّاد")
    }

    static var apprDhikrMotifFooter: String {
        string(
            en: "The full-screen texture behind the tasbih counter — the one place Revak lets the shader take over.",
            tr: "Tesbih sayacının arkasındaki tam ekran doku — Revak'ın shader'a söz hakkı verdiği tek yer.",
            ar: "النسيج الذي يملأ الشاشة خلف عدّاد التسبيح — المكان الوحيد الذي يتصدّر فيه المؤثّر."
        )
    }

    static var apprMotifLantern: String {
        string(en: "Lantern Glow", tr: "Fener Işığı", ar: "ضوء الفانوس")
    }

    static var apprMotifRipple: String {
        string(en: "Still Water", tr: "Durgun Su", ar: "ماء ساكن")
    }

    static var apprMotifKufic: String {
        string(en: "Kufic Lattice", tr: "Kûfi Kafes", ar: "شبكة كوفية")
    }

    // MARK: - Accessibility

    static var apprPreviewHint: String {
        string(en: "Live preview", tr: "Canlı önizleme", ar: "معاينة حية")
    }
}
