#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

struct ArtworkHazePresentation: Equatable {
    let isVisible: Bool
    let leadingOpacity: Double
    let trailingOpacity: Double
    let backgroundOpacity: Double
    let saturation: Double
    let usesPlusLighter: Bool
    let accessibilityHidden = true
    let allowsHitTesting = false

    init(appearance: DesignAppearance, reducesTransparency: Bool) {
        isVisible = !reducesTransparency
        switch appearance {
        case .dark:
            leadingOpacity = DesignTokens.Component.panelArtworkHazeDarkLeadingOpacity.value
            trailingOpacity = DesignTokens.Component.panelArtworkHazeDarkTrailingOpacity.value
            backgroundOpacity = DesignTokens.Component.panelArtworkHazeDarkBackgroundOpacity.value
            saturation = DesignTokens.Component.panelArtworkHazeDarkSaturation.value
            usesPlusLighter = true
        case .light:
            leadingOpacity = DesignTokens.Component.panelArtworkHazeLightLeadingOpacity.value
            trailingOpacity = DesignTokens.Component.panelArtworkHazeLightTrailingOpacity.value
            backgroundOpacity = DesignTokens.Component.panelArtworkHazeLightBackgroundOpacity.value
            saturation = DesignTokens.Component.panelArtworkHazeLightSaturation.value
            usesPlusLighter = false
        }
    }
}

/// Decorative haze from ready palette colors. The caller owns palette extraction.
public struct ArtworkHaze: View {
    @Environment(\.designNativeEnvironment) private var environment
    private let palette: ArtworkPalette

    public init(palette: ArtworkPalette) {
        self.palette = palette
    }

    public var body: some View {
        let presentation = ArtworkHazePresentation(
            appearance: environment.appearance,
            reducesTransparency: environment.reducesTransparency
        )
        Group {
            if presentation.isVisible {
                ZStack {
                    RadialGradient(
                        colors: [
                            palette.leading.opacity(presentation.leadingOpacity),
                            palette.leading.opacity(
                                presentation.leadingOpacity
                                    * DesignTokens.Component.panelArtworkHazeFalloffRatio.value
                            ),
                            .clear,
                        ],
                        center: .topLeading,
                        startRadius: DesignTokens.Component.panelArtworkHazeLeadingStartRadius.points,
                        endRadius: DesignTokens.Component.panelArtworkHazeLeadingEndRadius.points
                    )
                    RadialGradient(
                        colors: [
                            palette.trailing.opacity(presentation.trailingOpacity),
                            palette.trailing.opacity(
                                presentation.trailingOpacity
                                    * DesignTokens.Component.panelArtworkHazeFalloffRatio.value
                            ),
                            .clear,
                        ],
                        center: .bottomTrailing,
                        startRadius: DesignTokens.Component.panelArtworkHazeTrailingStartRadius.points,
                        endRadius: DesignTokens.Component.panelArtworkHazeTrailingEndRadius.points
                    )
                    LinearGradient(
                        colors: [
                            palette.leading.opacity(presentation.backgroundOpacity),
                            palette.trailing.opacity(
                                presentation.backgroundOpacity
                                    * DesignTokens.Component.panelArtworkHazeBackgroundFalloffRatio.value
                            ),
                            .clear,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .saturation(presentation.saturation)
                .blur(radius: DesignTokens.Component.panelArtworkHazeBlurRadius.points)
                .blendMode(presentation.usesPlusLighter ? .plusLighter : .normal)
            }
        }
        .allowsHitTesting(presentation.allowsHitTesting)
        .accessibilityHidden(presentation.accessibilityHidden)
    }
}
#endif
