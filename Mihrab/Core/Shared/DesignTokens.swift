import SwiftUI

/// "Emerald Glass" design tokens — single source of truth, shared with widgets.
public enum MihrabColor {
    public static let abyss = Color(hex: 0x07120D)
    public static let forest = Color(hex: 0x0D2418)
    public static let moss = Color(hex: 0x143322)
    public static let emerald = Color(hex: 0x1FA96B)
    public static let mint = Color(hex: 0x7FE0B2)
    public static let sprout = Color(hex: 0xB8F5D6)
    public static let brass = Color(hex: 0xC9A24B)
    public static let textPrimary = Color(hex: 0xF2F7F4)
    public static let textSecondary = Color(hex: 0x9DB8AA)
    public static let textTertiary = Color(hex: 0x5F7A6B)
    public static let danger = Color(hex: 0xE4685C)
    public static let ramadanViolet = Color(hex: 0x2A2140)
    public static let ramadanGold = Color(hex: 0xE8C476)
    public static let parchment = Color(hex: 0xF6F3EC)
}

public extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

public enum MihrabFont {
    public static let amiriName = "AmiriQuran-Regular"

    public static func arabic(_ size: CGFloat = 30) -> Font {
        .custom(amiriName, size: size, relativeTo: .title)
    }

    public static func countdown(_ size: CGFloat = 60) -> Font {
        .system(size: size, weight: .bold, design: .rounded).monospacedDigit()
    }

    public static func timeDisplay(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .semibold, design: .rounded).monospacedDigit()
    }

    public static func quote(_ size: CGFloat = 21) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    public static func quoteItalic(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .regular, design: .serif).italic()
    }

    public static let ornamental = Font.system(size: 11, weight: .medium).smallCaps()
}

public enum MihrabMotion {
    public static var standardAnimation: Animation { .spring(response: 0.45, dampingFraction: 0.82) }
    public static var snappyAnimation: Animation { .spring(response: 0.28, dampingFraction: 0.7) }
    public static var gentleAnimation: Animation { .spring(response: 0.8, dampingFraction: 0.9) }
    /// Shortest-path compass: slower, heavier, no overshoot past the needle.
    public static var compassAnimation: Animation { .spring(response: 0.52, dampingFraction: 0.86) }
}
