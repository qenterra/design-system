#if os(macOS)
import AppKit
import QenTerraDesignTokens
@testable import QenTerraMediaComponents
import SwiftUI
import Testing

@Test func mediaPresentationKeepsDomainIdentityOpaqueAndStatesLiteral() {
    let identity = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    let item = MediaItemPresentation(
        id: identity,
        title: "Synthetic Track",
        subtitle: "Synthetic Artist",
        metadata: "3:42",
        isSelected: false,
        isCurrent: true,
        isPlaying: true,
        isAvailable: true
    )

    #expect(item.id == identity)
    #expect(item.title == "Synthetic Track")
    #expect(item.subtitle == "Synthetic Artist")
    #expect(item.metadata == "3:42")
    #expect(!item.isSelected)
    #expect(item.isCurrent)
    #expect(item.isPlaying)
    #expect(item.isAvailable)
}

@Test func selectedAndCurrentRemainIndependentPresentationStates() {
    let current = MediaItemPresentation(
        id: 1,
        title: "Current",
        subtitle: "Artist",
        metadata: nil,
        isSelected: false,
        isCurrent: true,
        isPlaying: true,
        isAvailable: true
    )
    let selected = MediaItemPresentation(
        id: 2,
        title: "Selected",
        subtitle: "Artist",
        metadata: nil,
        isSelected: true,
        isCurrent: false,
        isPlaying: true,
        isAvailable: true
    )

    #expect(!MediaItemVisualPresentation(current).isSelected)
    #expect(MediaItemVisualPresentation(current).showsPlaybackIndicator)
    #expect(MediaItemVisualPresentation(selected).isSelected)
    #expect(!MediaItemVisualPresentation(selected).showsPlaybackIndicator)
}

@Test @MainActor func embeddedControlsNeverPerformTheRowActivation() {
    var activations = 0
    let activation = MediaActivation { activations += 1 }

    activation.perform(from: .embeddedControl, isAvailable: true)
    #expect(activations == 0)

    activation.perform(from: .primaryContent, isAvailable: false)
    #expect(activations == 0)

    activation.perform(from: .primaryContent, isAvailable: true)
    #expect(activations == 1)
}

@Test func favoritePresentationRevealsOnHoverOrFocusAndKeepsConsumerCopy() {
    let hidden = FavoritePresentation.resolve(
        isFavorite: false,
        isPending: false,
        isHovered: false,
        isFocused: false,
        accessibilityLabel: "Add Synthetic Track to saved items",
        accessibilityValue: "Not saved"
    )
    let hovered = FavoritePresentation.resolve(
        isFavorite: false,
        isPending: false,
        isHovered: true,
        isFocused: false,
        accessibilityLabel: "Add Synthetic Track to saved items",
        accessibilityValue: "Not saved"
    )
    let focused = FavoritePresentation.resolve(
        isFavorite: true,
        isPending: true,
        isHovered: false,
        isFocused: true,
        accessibilityLabel: "Remove Synthetic Track from saved items",
        accessibilityValue: "Saved"
    )

    #expect(!hidden.isRevealed)
    #expect(hidden.visualOpacity == 0)
    #expect(!hidden.acceptsPointerInteraction)
    #expect(hovered.isRevealed)
    #expect(hovered.visualOpacity == 1)
    #expect(hovered.acceptsPointerInteraction)
    #expect(focused.isRevealed)
    #expect(focused.isPending)
    #expect(!focused.isEnabled)
    #expect(focused.requestedValue == false)
    #expect(focused.accessibilityLabel == "Remove Synthetic Track from saved items")
    #expect(focused.accessibilityValue == "Saved")
}

@Test func adaptiveGridUsesCadenceProfileAndLiteralConsumerOverrides() {
    let cadence = MediaGridLayout.resolve(productProfile: .cadence)
    #expect(cadence.minimumWidth == 164)
    #expect(cadence.maximumWidth == 196)
    #expect(cadence.spacing == 16)
    #expect(cadence.metrics(availableWidth: 376).columnCount == 2)
    #expect(cadence.metrics(availableWidth: 376).itemWidth == 180)
    #expect(cadence.metrics(availableWidth: 800).columnCount == 4)
    #expect(cadence.metrics(availableWidth: 800).itemWidth == 188)

    let cadenceWithOverrides = MediaGridLayout.resolve(
        productProfile: .cadence,
        minimumWidth: 120,
        maximumWidth: 180,
        spacing: 12
    )
    #expect(cadenceWithOverrides.minimumWidth == 164)
    #expect(cadenceWithOverrides.maximumWidth == 196)
    #expect(cadenceWithOverrides.spacing == 16)

    let overridden = MediaGridLayout.resolve(
        productProfile: .standard,
        minimumWidth: 120,
        maximumWidth: 180,
        spacing: 12
    )
    #expect(overridden.minimumWidth == 120)
    #expect(overridden.maximumWidth == 180)
    #expect(overridden.spacing == 12)
    #expect(overridden.metrics(availableWidth: 384).columnCount == 3)
    #expect(overridden.metrics(availableWidth: 384).itemWidth == 120)
}

@Test func invalidGridOverridesCannotPublishNonfiniteOrInvertedGeometry() {
    let layout = MediaGridLayout.resolve(
        productProfile: .standard,
        minimumWidth: .nan,
        maximumWidth: -4,
        spacing: .infinity
    )
    #expect(layout.minimumWidth == 164)
    #expect(layout.maximumWidth == 196)
    #expect(layout.spacing == 16)
    let metrics = layout.metrics(availableWidth: .nan)
    #expect(metrics.columnCount == 1)
    #expect(metrics.itemWidth == 164)
}

@Test func reducedMotionPlaybackIndicatorUsesExactStaticBars() {
    let state = PlaybackIndicatorState(isPlaying: true, reducesMotion: true)
    #expect(state.animates == false)
    #expect(state.staticScales == [0.48, 0.82, 0.62])
    #expect((0 ..< 3).map { state.scale(forBar: $0, elapsed: 10) } == state.staticScales)

    let active = PlaybackIndicatorState(isPlaying: true, reducesMotion: false)
    #expect(active.animates)
    #expect(active.scale(forBar: 0, elapsed: 0) == 0.32)
    #expect(active.scale(forBar: 1, elapsed: 0) == 0.72)
    #expect(active.scale(forBar: 2, elapsed: 0) == 0.46)
}

@Test func playbackIndicatorGeometryMatchesTheCadenceBarContract() {
    let geometry = PlaybackIndicatorGeometry()
    #expect(geometry.barCount == 3)
    #expect(geometry.barWidth == 3)
    #expect(geometry.gap == 2.5)
    #expect(geometry.maximumHeight == 17)
    #expect(geometry.cornerRadius == 1.5)
    #expect(
        geometry.frames(in: CGRect(x: 0, y: 0, width: 24, height: 31)) == [
            CGRect(x: 5, y: 7, width: 3, height: 17),
            CGRect(x: 10.5, y: 7, width: 3, height: 17),
            CGRect(x: 16, y: 7, width: 3, height: 17),
        ]
    )
}

@Test @MainActor func nativePlaybackIndicatorDisablesImplicitActionsAndCleansUpAnimations() {
    let view = NativePlaybackIndicatorView(frame: CGRect(x: 0, y: 0, width: 24, height: 31))
    #expect(view.barCount == 3)
    #expect(view.hasDisabledImplicitLayerActions)

    view.setState(PlaybackIndicatorState(isPlaying: true, reducesMotion: false))
    #expect(view.isAnimating)
    #expect(view.animationCount == 3)

    view.prepareForReuse()
    #expect(!view.isAnimating)
    #expect(view.animationCount == 0)

    view.setState(PlaybackIndicatorState(isPlaying: true, reducesMotion: false))
    view.removeFromSuperview()
    #expect(!view.isAnimating)
    #expect(view.animationCount == 0)
}

@Test @MainActor func collectionViewsRenderReadyContentWithoutOwningDataWork() throws {
    let item = MediaItemPresentation(
        id: "synthetic",
        title: "Synthetic Track",
        subtitle: "Synthetic Artist",
        metadata: "3:42",
        isSelected: true,
        isCurrent: true,
        isPlaying: true,
        isAvailable: true
    )
    let favorite = FavoritePresentation(
        isFavorite: true,
        isPending: false,
        isRevealed: true,
        accessibilityLabel: "Remove Synthetic Track from saved items",
        accessibilityValue: "Saved"
    )
    let views: [AnyView] = [
        AnyView(MediaTile(item: item, accessibilityLabel: "Play Synthetic Track") {
            Color.blue
        } trailingAccessory: {
            FavoriteControl(presentation: favorite) { _ in }
        } action: {}),
        AnyView(MediaRow(item: item, accessibilityLabel: "Play Synthetic Track") {
            Color.blue
        } trailingAccessory: {
            FavoriteControl(presentation: favorite) { _ in }
        } action: {}),
        AnyView(MediaGrid { Color.blue.frame(height: 40) }),
        AnyView(MediaShelf(title: "Recently played", subtitle: "Ready items only") {
            Color.blue.frame(height: 40)
        }),
        AnyView(PlaybackIndicator(isPlaying: true)),
    ]

    for view in views {
        let renderer = ImageRenderer(content: view.frame(width: 260, height: 180))
        #expect(renderer.cgImage != nil)
    }
}
#endif
