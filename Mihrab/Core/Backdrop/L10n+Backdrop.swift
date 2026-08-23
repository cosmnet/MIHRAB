import Foundation

/// Copy owned by the backdrop layer. Prefixed `seg…` so it can never collide
/// with the shared catalogue in `L10n.swift`.
extension L10n {
    static var segFajr: String {
        string(en: "Before dawn", tr: "Fecir", ar: "الفجر")
    }

    static var segSunrise: String {
        string(en: "First light", tr: "Gün doğumu", ar: "الشروق")
    }

    static var segMorning: String {
        string(en: "Morning", tr: "Sabah", ar: "الصباح")
    }

    static var segDhuhr: String {
        string(en: "Midday", tr: "Öğle", ar: "الظهيرة")
    }

    static var segAsr: String {
        string(en: "Afternoon", tr: "İkindi", ar: "العصر")
    }

    static var segMaghrib: String {
        string(en: "Dusk", tr: "Akşam", ar: "الغروب")
    }

    static var segIsha: String {
        string(en: "Evening", tr: "Yatsı", ar: "المساء")
    }

    static var segNight: String {
        string(en: "Night", tr: "Gece", ar: "الليل")
    }
}
