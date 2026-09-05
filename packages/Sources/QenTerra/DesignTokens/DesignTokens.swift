import Foundation

#if canImport(AppKit)
import AppKit

public extension NSImage {
    static func designIcon(
        _ icon: DesignIcon,
        accessibilityDescription: String? = nil
    ) -> NSImage? {
        NSImage(systemSymbolName: icon.systemName, accessibilityDescription: accessibilityDescription)
    }
}
#endif

public enum DesignAppearance: String, CaseIterable, Sendable {
    case light
    case dark
}

public struct DesignColorValue: Equatable, Sendable {
    public let light: String
    public let dark: String

    public init(light: String, dark: String) {
        self.light = light
        self.dark = dark
    }

    public func value(for appearance: DesignAppearance) -> String {
        appearance == .light ? light : dark
    }
}

public struct DesignTypographyValue: Equatable, Sendable {
    public let family: String
    public let size: Double
    public let lineHeight: Double
    public let weight: Double
    public let tracking: Double
    public let transform: String?
    public let numeric: String?

    public init(
        family: String,
        size: Double,
        lineHeight: Double,
        weight: Double,
        tracking: Double,
        transform: String?,
        numeric: String?
    ) {
        self.family = family
        self.size = size
        self.lineHeight = lineHeight
        self.weight = weight
        self.tracking = tracking
        self.transform = transform
        self.numeric = numeric
    }
}

public struct DesignMotionValue: Equatable, Sendable {
    public let seconds: Double
    public let curve: [Double]
    public let properties: [String]

    public init(seconds: Double, curve: [Double], properties: [String]) {
        self.seconds = seconds
        self.curve = curve
        self.properties = properties
    }
}

public struct DesignComponentMetric: Equatable, Sendable {
    public let points: Double

    public init(points: Double) {
        self.points = points
    }
}

public struct DesignComponentDuration: Equatable, Sendable {
    public let milliseconds: Double

    public init(milliseconds: Double) {
        self.milliseconds = milliseconds
    }
}

public struct DesignComponentOpacity: Equatable, Sendable {
    public let value: Double

    public init(value: Double) {
        self.value = value
    }
}

public struct DesignProductMetrics: Equatable, Sendable {
    public let textStack: Double
    public let compactGap: Double
    public let controlGap: Double
    public let contentGap: Double
    public let panelInset: Double
    public let pageInset: Double
    public let sectionGap: Double
    public let rowHeight: Double
    public let readableContentWidth: Double

    public init(
        textStack: Double,
        compactGap: Double,
        controlGap: Double,
        contentGap: Double,
        panelInset: Double,
        pageInset: Double,
        sectionGap: Double,
        rowHeight: Double,
        readableContentWidth: Double
    ) {
        self.textStack = textStack
        self.compactGap = compactGap
        self.controlGap = controlGap
        self.contentGap = contentGap
        self.panelInset = panelInset
        self.pageInset = pageInset
        self.sectionGap = sectionGap
        self.rowHeight = rowHeight
        self.readableContentWidth = readableContentWidth
    }

    public static let cadence = GeneratedProductProfiles.cadence
}

struct DesignColorComponents {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    init?(_ source: String) {
        let value = source.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") {
            let hex = String(value.dropFirst())
            guard hex.count == 6, let number = UInt64(hex, radix: 16) else { return nil }
            red = Double((number >> 16) & 0xFF) / 255
            green = Double((number >> 8) & 0xFF) / 255
            blue = Double(number & 0xFF) / 255
            alpha = 1
            return
        }

        guard value.lowercased().hasPrefix("rgba("), value.hasSuffix(")") else { return nil }
        let arguments = value.dropFirst(5).dropLast().split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard
            arguments.count == 4,
            let redChannel = Double(arguments[0]),
            let greenChannel = Double(arguments[1]),
            let blueChannel = Double(arguments[2]),
            let opacity = Double(arguments[3]),
            (0 ... 255).contains(redChannel),
            (0 ... 255).contains(greenChannel),
            (0 ... 255).contains(blueChannel),
            (0 ... 1).contains(opacity)
        else { return nil }

        red = redChannel / 255
        green = greenChannel / 255
        blue = blueChannel / 255
        alpha = opacity
    }
}

#if canImport(AppKit)
public extension NSColor {
    static func designToken(_ value: DesignColorValue) -> NSColor {
        NSColor(name: nil) { appearance in
            let resolved: DesignAppearance = appearance.bestMatch(
                from: [.darkAqua, .aqua]
            ) == .darkAqua ? .dark : .light
            return NSColor(designHexOrRGBA: value.value(for: resolved)) ?? .clear
        }
    }
}

private extension NSColor {
    convenience init?(designHexOrRGBA source: String) {
        guard let components = DesignColorComponents(source) else { return nil }
        self.init(
            srgbRed: components.red,
            green: components.green,
            blue: components.blue,
            alpha: components.alpha
        )
    }
}
#endif

public struct InteractiveRowState: Equatable, Sendable {
    public let isHovered: Bool
    public let isPressed: Bool
    public let isFocused: Bool
    public let isSelected: Bool
    public let isDisabled: Bool
    public let isUnavailable: Bool
    public let isIncreasedContrast: Bool
    public let isLoading: Bool

    public init(
        isHovered: Bool = false,
        isPressed: Bool = false,
        isFocused: Bool = false,
        isSelected: Bool = false,
        isDisabled: Bool = false,
        isUnavailable: Bool = false,
        isIncreasedContrast: Bool = false,
        isLoading: Bool = false
    ) {
        self.isHovered = isHovered
        self.isPressed = isPressed
        self.isFocused = isFocused
        self.isSelected = isSelected
        self.isDisabled = isDisabled
        self.isUnavailable = isUnavailable
        self.isIncreasedContrast = isIncreasedContrast
        self.isLoading = isLoading
    }

    public var fill: DesignColorValue? {
        if isDisabled || isUnavailable {
            return DesignTokens.Color.fillDisabled
        }
        if isPressed {
            return DesignTokens.Color.fillPressed
        }
        if isSelected {
            return isIncreasedContrast
                ? DesignTokens.Color.fillSelectedStrong
                : DesignTokens.Color.fillSelected
        }
        if isHovered {
            return DesignTokens.Color.fillHover
        }
        return nil
    }

    public var border: DesignColorValue? {
        if isDisabled || isUnavailable {
            return nil
        }
        if isFocused {
            return DesignTokens.Color.borderFocus
        }
        if isSelected {
            return DesignTokens.Color.borderStrong
        }
        return nil
    }

    public var contentOpacity: Double {
        isDisabled || isUnavailable ? DesignTokens.Opacity.disabled : 1
    }

    public var borderWidth: Double {
        isFocused && isIncreasedContrast
            ? DesignTokens.Stroke.focus
            : DesignTokens.Stroke.hairline
    }
}

/// Stable public entry point for generated QenTerra design tokens.
public enum DesignTokens {
    public static let version = GeneratedTokens.version

    public typealias Space = GeneratedTokens.Space
    public typealias Radius = GeneratedTokens.Radius
    public typealias Stroke = GeneratedTokens.Stroke
    public typealias Size = GeneratedTokens.Size
    public typealias Opacity = GeneratedTokens.Opacity
    public typealias ZIndex = GeneratedTokens.ZIndex
    public typealias MotionSeconds = GeneratedTokens.MotionSeconds
    public typealias SemanticName = GeneratedTokens.SemanticName
    public typealias Color = GeneratedTokens.Color
    public typealias Typography = GeneratedTokens.Typography
    public typealias Motion = GeneratedTokens.Motion
    public typealias Component = GeneratedTokens.Component
    public typealias Icon = DesignIcon
}
