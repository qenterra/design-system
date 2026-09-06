#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

/// Normalized positions bounding the opaque plateau of a whole-viewport mask.
public struct LyricsEdgeFadeMaskConfiguration: Equatable, Sendable {
    public let topOpaqueLocation: Double
    public let bottomOpaqueLocation: Double

    /// Clamps finite positions to 0...1 and orders them. Nonfinite values fall
    /// back to the corresponding viewport edge, preserving readable content.
    public init(topOpaqueLocation: Double, bottomOpaqueLocation: Double) {
        let top = topOpaqueLocation.isFinite ? min(1, max(0, topOpaqueLocation)) : 0
        let bottom = bottomOpaqueLocation.isFinite ? min(1, max(0, bottomOpaqueLocation)) : 1
        self.topOpaqueLocation = min(top, bottom)
        self.bottomOpaqueLocation = max(top, bottom)
    }
}

public enum LyricsEdgeFadePresentation: Equatable, Sendable {
    /// The original fixed-height destination-out overlay.
    case edgeOverlay
    /// A top-to-bottom alpha mask for use with SwiftUI's `mask` modifier.
    case viewportMask(LyricsEdgeFadeMaskConfiguration)
}

public struct LyricsEdgeFade: View {
    private let presentation: LyricsEdgeFadePresentation

    public init() {
        presentation = .edgeOverlay
    }

    public init(presentation: LyricsEdgeFadePresentation) {
        self.presentation = presentation
    }

    public var body: some View {
        content
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var content: some View {
        switch presentation {
        case .edgeOverlay:
            edgeOverlay
        case let .viewportMask(configuration):
            LinearGradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: configuration.topOpaqueLocation),
                .init(color: .black, location: configuration.bottomOpaqueLocation),
                .init(color: .clear, location: 1),
            ], startPoint: .top, endPoint: .bottom)
        }
    }

    private var edgeOverlay: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: DesignTokens.Component.panelLyricsEdgeFadeHeight.points)
            Spacer(minLength: 0)
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                .frame(height: DesignTokens.Component.panelLyricsEdgeFadeHeight.points)
        }
        .blendMode(.destinationOut)
        .compositingGroup()
    }
}
#endif
