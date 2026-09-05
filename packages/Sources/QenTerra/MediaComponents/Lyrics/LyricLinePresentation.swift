#if os(macOS)
import QenTerraDesignTokens

public enum LyricLineTone: Equatable, Sendable {
    case primary
    case secondary
}

public struct LyricLinePresentation<ID: Hashable & Sendable>: Identifiable, Equatable, Sendable {
    public let id: ID
    public let text: String
    public let isActive: Bool
    public let isSynchronized: Bool
    public let inactiveBlurRadius: Double

    public init(
        id: ID,
        text: String,
        isActive: Bool,
        isSynchronized: Bool,
        inactiveBlurRadius: Double = DesignTokens.Component.panelLyricsInactiveBlurRadius.points
    ) {
        self.id = id
        self.text = text
        self.isActive = isActive
        self.isSynchronized = isSynchronized
        self.inactiveBlurRadius = inactiveBlurRadius.isFinite ? max(inactiveBlurRadius, 0) : 0
    }

    public var tone: LyricLineTone {
        isActive || !isSynchronized ? .primary : .secondary
    }

    public var opacity: Double {
        isActive || !isSynchronized
            ? 1
            : DesignTokens.Component.panelLyricsInactiveOpacity.value
    }

    public var blurRadius: Double {
        isActive || !isSynchronized ? 0 : inactiveBlurRadius
    }
}
#endif
