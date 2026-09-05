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
    let pendingHidden = FavoritePresentation(
        isFavorite: false,
        isPending: true,
        isRevealed: false,
        accessibilityLabel: "Add Synthetic Track to saved items",
        accessibilityValue: "Saving"
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
    #expect(pendingHidden.visualOpacity == 1)
    #expect(!pendingHidden.acceptsPointerInteraction)
    #expect(!pendingHidden.isEnabled)
    #expect(pendingHidden.accessibilityLabel == "Add Synthetic Track to saved items")
    #expect(pendingHidden.accessibilityValue == "Saving")
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

@Test func adaptiveGridCapsOrFallsBackBeforeExtremeFiniteArithmeticCanTrap() {
    let ordinary = MediaGridLayout.resolve(productProfile: .standard)
    let capped = ordinary.metrics(availableWidth: .greatestFiniteMagnitude)
    #expect(capped.columnCount == 10_000)
    #expect(capped.itemWidth == 196)
    #expect(capped.itemWidth.isFinite)

    let overflowingDenominator = MediaGridLayout.resolve(
        productProfile: .standard,
        minimumWidth: .greatestFiniteMagnitude,
        maximumWidth: .greatestFiniteMagnitude,
        spacing: .greatestFiniteMagnitude
    ).metrics(availableWidth: .greatestFiniteMagnitude)
    #expect(overflowingDenominator.columnCount == 1)
    #expect(overflowingDenominator.itemWidth == .greatestFiniteMagnitude)
    #expect(overflowingDenominator.itemWidth.isFinite)

    let overflowingNumerator = MediaGridLayout.resolve(
        productProfile: .standard,
        minimumWidth: 1,
        maximumWidth: 2,
        spacing: .greatestFiniteMagnitude
    ).metrics(availableWidth: .greatestFiniteMagnitude)
    #expect(overflowingNumerator.columnCount == 1)
    #expect(overflowingNumerator.itemWidth == 2)
    #expect(overflowingNumerator.itemWidth.isFinite)

    let negative = ordinary.metrics(availableWidth: -.greatestFiniteMagnitude)
    #expect(negative.columnCount == 1)
    #expect(negative.itemWidth == 164)
    #expect(negative.itemWidth.isFinite)
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
    #expect(active.scale(forBar: 1, elapsed: 0.1) == 0.72)
    #expect(active.scale(forBar: 2, elapsed: 0.2) == 0.46)
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

    let initialBeginTimes = nativeAnimationBeginTimes(in: view)
    #expect(initialBeginTimes.count == 3)
    #expect(abs((initialBeginTimes[1] - initialBeginTimes[0]) - 0.1) < 0.000_001)
    #expect(abs((initialBeginTimes[2] - initialBeginTimes[1]) - 0.1) < 0.000_001)

    view.setState(
        PlaybackIndicatorState(isPlaying: true, reducesMotion: false),
        color: .systemRed
    )
    #expect(nativeAnimationBeginTimes(in: view) == initialBeginTimes)
    #expect(
        view.layer?.sublayers?.allSatisfy { layer in
            layer.backgroundColor == NSColor.systemRed.cgColor
        } == true
    )

    view.prepareForReuse()
    #expect(!view.isAnimating)
    #expect(view.animationCount == 0)

    view.setState(PlaybackIndicatorState(isPlaying: true, reducesMotion: false))
    view.removeFromSuperview()
    #expect(!view.isAnimating)
    #expect(view.animationCount == 0)
}

@MainActor
private func nativeAnimationBeginTimes(in view: NativePlaybackIndicatorView) -> [CFTimeInterval] {
    view.layer?.sublayers?.compactMap { layer in
        guard let key = layer.animationKeys()?.first else { return nil }
        return layer.animation(forKey: key)?.beginTime
    } ?? []
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

@Test @MainActor func mediaTileUsesTheGroupBoundaryInNormalAndIncreasedContrast() throws {
    let normal = try renderedMediaTileAlphaMask(isIncreasedContrast: false)
    let increased = try renderedMediaTileAlphaMask(isIncreasedContrast: true)
    let group = try renderedClippedRectangleAlphaMask(
        width: normal.width,
        height: normal.height,
        radius: CGFloat(DesignTokens.Radius.group)
    )
    let control = try renderedClippedRectangleAlphaMask(
        width: normal.width,
        height: normal.height,
        radius: CGFloat(DesignTokens.Radius.control)
    )
    #expect(cornerDistance(normal, increased) <= 2)
    #expect(cornerDistance(normal, group) < cornerDistance(normal, control))
    #expect(cornerDistance(increased, group) < cornerDistance(increased, control))
}

private func cornerSignature(_ mask: (width: Int, height: Int, alphaMask: [Bool])) -> [Int] {
    (0 ..< 12).map { row in
        (0 ..< mask.width).first { mask.alphaMask[(row * mask.width) + $0] } ?? mask.width
    }
}

private func cornerDistance(
    _ lhs: (width: Int, height: Int, alphaMask: [Bool]),
    _ rhs: (width: Int, height: Int, alphaMask: [Bool])
) -> Int {
    zip(cornerSignature(lhs), cornerSignature(rhs)).reduce(into: 0) { distance, pair in
        distance += abs(pair.0 - pair.1)
    }
}

@MainActor
private func renderedMediaTileAlphaMask(
    isIncreasedContrast: Bool
) throws -> (width: Int, height: Int, alphaMask: [Bool]) {
    let item = MediaItemPresentation(
        id: "radius-probe",
        title: "Tile",
        subtitle: "Boundary",
        metadata: nil,
        isSelected: true,
        isCurrent: false,
        isPlaying: false,
        isAvailable: true
    )
    let view = MediaTile(item: item, accessibilityLabel: "Tile") {
        Color.white.frame(width: 140, height: 140)
    } trailingAccessory: {
        EmptyView()
    } action: {}
    .environment(
        \.designNativeEnvironment,
        DesignNativeEnvironment(
            appearance: .light,
            productProfile: .cadence,
            density: .standard,
            isIncreasedContrast: isIncreasedContrast,
            reducesMotion: true,
            reducesTransparency: false
        )
    )

    let renderer = ImageRenderer(content: view)
    renderer.scale = 1
    return try alphaMask(of: #require(renderer.cgImage))
}

@MainActor
private func renderedClippedRectangleAlphaMask(
    width: Int,
    height: Int,
    radius: CGFloat
) throws -> (width: Int, height: Int, alphaMask: [Bool]) {
    let renderer = ImageRenderer(
        content: Color.white
            .frame(width: CGFloat(width), height: CGFloat(height))
            .clipShape(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
            )
        )
    renderer.scale = 1
    return try alphaMask(of: #require(renderer.cgImage))
}

private func alphaMask(of image: CGImage) throws -> (width: Int, height: Int, alphaMask: [Bool]) {
    let bitmap = NSBitmapImageRep(cgImage: image)
    let mask = (0 ..< image.height).flatMap { y in
        (0 ..< image.width).map { x in
            (bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0
        }
    }
    return (image.width, image.height, mask)
}

#endif
