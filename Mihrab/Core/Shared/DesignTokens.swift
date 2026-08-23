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

    /// Amiri already scales: `.custom(_:size:relativeTo:)` runs the size through
    /// `UIFontMetrics` for us.
    public static func arabic(_ size: CGFloat = 30) -> Font {
        .custom(amiriName, size: size, relativeTo: .title)
    }

    /// The `size` these three take is a **point size, already scaled** — SwiftUI's
    /// `Font.system(size:)` has no `relativeTo:` and does not track Dynamic Type
    /// on its own. In app UI, reach for the `.mihrabCountdown` / `.mihrabTime` /
    /// `.mihrabQuote` view modifiers below, which feed a `@ScaledMetric` size in
    /// and cap the growth. These raw builders stay for widgets and for images
    /// rendered with `ImageRenderer`, where there is no Dynamic Type to honour.
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

// MARK: - Dynamic Type

/// Applies one of the point-sized `MihrabFont` builders at a size that tracks
/// the user's text-size setting, with an optional ceiling.
///
/// The ceiling is not laziness: the countdown and the dhikr count live inside a
/// fixed circle, and past AX2 a freely growing glyph stops being "large text"
/// and becomes a clipped one. Everything without a hard geometric container is
/// left uncapped.
public struct MihrabScaledFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    private let build: (CGFloat) -> Font
    private let ceiling: DynamicTypeSize?

    public init(
        size: CGFloat,
        relativeTo style: Font.TextStyle,
        ceiling: DynamicTypeSize? = nil,
        build: @escaping (CGFloat) -> Font
    ) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
        self.build = build
        self.ceiling = ceiling
    }

    @ViewBuilder
    public func body(content: Content) -> some View {
        if let ceiling {
            content.font(build(size)).dynamicTypeSize(...ceiling)
        } else {
            content.font(build(size))
        }
    }
}

public extension View {
    /// Big rounded monospaced-digit numerals (countdowns, dhikr counts).
    func mihrabCountdown(
        _ size: CGFloat = 60,
        relativeTo style: Font.TextStyle = .largeTitle,
        ceiling: DynamicTypeSize? = .accessibility2
    ) -> some View {
        modifier(MihrabScaledFont(size: size, relativeTo: style, ceiling: ceiling) {
            MihrabFont.countdown($0)
        })
    }

    /// Prayer-time style numerals — smaller, semibold.
    func mihrabTime(
        _ size: CGFloat = 28,
        relativeTo style: Font.TextStyle = .title2,
        ceiling: DynamicTypeSize? = .accessibility3
    ) -> some View {
        modifier(MihrabScaledFont(size: size, relativeTo: style, ceiling: ceiling) {
            MihrabFont.timeDisplay($0)
        })
    }

    /// Serif body copy for hadith, du'a and Name meanings. Uncapped by default:
    /// these all sit in flowing, vertically scrollable layouts.
    func mihrabQuote(
        _ size: CGFloat = 21,
        relativeTo style: Font.TextStyle = .body,
        italic: Bool = false,
        ceiling: DynamicTypeSize? = nil
    ) -> some View {
        modifier(MihrabScaledFont(size: size, relativeTo: style, ceiling: ceiling) {
            italic ? MihrabFont.quoteItalic($0) : MihrabFont.quote($0)
        })
    }

    /// Amiri calligraphy. The font already scales via `relativeTo:`, so this
    /// only adds the ceiling for glyphs that sit inside fixed geometry.
    @ViewBuilder
    func mihrabArabic(_ size: CGFloat = 30, ceiling: DynamicTypeSize? = nil) -> some View {
        if let ceiling {
            font(MihrabFont.arabic(size)).dynamicTypeSize(...ceiling)
        } else {
            font(MihrabFont.arabic(size))
        }
    }
}

public enum MihrabMotion {
    public static var standardAnimation: Animation { .spring(response: 0.45, dampingFraction: 0.82) }
    public static var snappyAnimation: Animation { .spring(response: 0.28, dampingFraction: 0.7) }
    public static var gentleAnimation: Animation { .spring(response: 0.8, dampingFraction: 0.9) }
    /// Shortest-path compass: slower, heavier, no overshoot past the needle.
    public static var compassAnimation: Animation { .spring(response: 0.52, dampingFraction: 0.86) }
}
