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

public struct InteractiveRowState: Equatable, Sendable {
    public let isHovered: Bool
    public let isFocused: Bool
    public let isSelected: Bool
    public let isDisabled: Bool
    public let isUnavailable: Bool
    public let isIncreasedContrast: Bool

    public init(
        isHovered: Bool = false,
        isFocused: Bool = false,
        isSelected: Bool = false,
        isDisabled: Bool = false,
        isUnavailable: Bool = false,
        isIncreasedContrast: Bool = false
    ) {
        self.isHovered = isHovered
        self.isFocused = isFocused
        self.isSelected = isSelected
        self.isDisabled = isDisabled
        self.isUnavailable = isUnavailable
        self.isIncreasedContrast = isIncreasedContrast
    }

    public var fill: DesignColorValue? {
        if isDisabled || isUnavailable {
            return DesignTokens.Color.fillDisabled
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
