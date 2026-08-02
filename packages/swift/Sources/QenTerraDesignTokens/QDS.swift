import Foundation

public enum QDSAppearance: String, CaseIterable, Sendable {
    case light
    case dark
}

public struct QDSColorValue: Equatable, Sendable {
    public let light: String
    public let dark: String

    public init(light: String, dark: String) {
        self.light = light
        self.dark = dark
    }

    public func value(for appearance: QDSAppearance) -> String {
        appearance == .light ? light : dark
    }
}

public struct QDSTypographyValue: Equatable, Sendable {
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

public struct QDSMotionValue: Equatable, Sendable {
    public let seconds: Double
    public let curve: [Double]
    public let properties: [String]

    public init(seconds: Double, curve: [Double], properties: [String]) {
        self.seconds = seconds
        self.curve = curve
        self.properties = properties
    }
}

public struct QDSComponentMetric: Equatable, Sendable {
    public let points: Double

    public init(points: Double) {
        self.points = points
    }
}

/// Stable public entry point for locally generated QenTerra design tokens.
public enum QDS {
    public static let version = QDSGeneratedTokens.version

    public typealias Space = QDSGeneratedTokens.Space
    public typealias Radius = QDSGeneratedTokens.Radius
    public typealias Stroke = QDSGeneratedTokens.Stroke
    public typealias Size = QDSGeneratedTokens.Size
    public typealias MotionSeconds = QDSGeneratedTokens.MotionSeconds
    public typealias SemanticName = QDSGeneratedTokens.SemanticName
    public typealias Color = QDSGeneratedTokens.Color
    public typealias Typography = QDSGeneratedTokens.Typography
    public typealias Motion = QDSGeneratedTokens.Motion
    public typealias Component = QDSGeneratedTokens.Component
    public typealias Icon = QDSIcon
}
