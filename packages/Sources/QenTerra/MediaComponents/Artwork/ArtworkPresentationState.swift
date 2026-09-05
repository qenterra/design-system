#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

public enum ArtworkPresentationState: Equatable, Sendable {
    case loading
    case content
    case placeholder(ArtworkPlaceholderKind)
    case error(ArtworkPlaceholderKind)

    public var placeholderKind: ArtworkPlaceholderKind? {
        switch self {
        case .content: nil
        case .loading: .track
        case let .placeholder(kind), let .error(kind): kind
        }
    }

    public var showsProgress: Bool {
        self == .loading
    }

    public var accessibilityValue: String {
        switch self {
        case .content: ""
        case .loading: String(localized: "Loading artwork")
        case .placeholder: String(localized: "No artwork")
        case .error: String(localized: "Artwork unavailable")
        }
    }
}

struct ArtworkSurfacePresentation {
    let accessibilityLabel: String
    let borderWidth: CGFloat

    init(state _: ArtworkPresentationState, title: String, showsBorder: Bool, increasedContrast: Bool) {
        accessibilityLabel = String(localized: "Artwork for \(title)")
        borderWidth = showsBorder ? (increasedContrast ? DesignTokens.Stroke.default : DesignTokens.Stroke.hairline) : 0
    }
}
#endif
