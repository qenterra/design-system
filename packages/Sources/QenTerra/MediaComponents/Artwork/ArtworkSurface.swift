#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

/// Frames supplied ready content. Loading and error truth are owned by the caller.
public struct ArtworkSurface<Content: View>: View {
    @Environment(\.designNativeEnvironment) private var environment
    private let state: ArtworkPresentationState
    private let title: String
    private let cornerRadius: CGFloat
    private let showsBorder: Bool
    private let fillsAvailableSpace: Bool
    private let content: Content

    public init(
        state: ArtworkPresentationState,
        title: String,
        cornerRadius: CGFloat = DesignTokens.Component.panelArtworkSurfaceCornerRadius.points,
        showsBorder: Bool = true,
        fillsAvailableSpace: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.state = state
        self.title = title
        self.cornerRadius = cornerRadius.isFinite ? max(cornerRadius, 0) : 0
        self.showsBorder = showsBorder
        self.fillsAvailableSpace = fillsAvailableSpace
        self.content = content()
    }

    public var body: some View {
        if fillsAvailableSpace {
            surface
        } else {
            surface.aspectRatio(1, contentMode: .fit)
        }
    }

    private var surface: some View {
        let presentation = ArtworkSurfacePresentation(
            state: state,
            title: title,
            showsBorder: showsBorder,
            increasedContrast: environment.isIncreasedContrast
        )
        return framedContent
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                if presentation.borderWidth > 0 {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            Color(
                                designToken: DesignTokens.Color.borderDefault,
                                appearance: environment.appearance
                            ),
                            lineWidth: presentation.borderWidth
                        )
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(presentation.accessibilityLabel)
            .accessibilityValue(state.accessibilityValue)
    }

    private var framedContent: some View {
        GeometryReader { geometry in
            ZStack {
                if state == .content {
                    content
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else if let kind = state.placeholderKind {
                    ArtworkPlaceholder(kind: kind)
                }
                if state.showsProgress {
                    ProgressView().controlSize(.small)
                }
            }
        }
    }
}
#endif
