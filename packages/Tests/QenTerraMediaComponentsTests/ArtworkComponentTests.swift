#if os(macOS)
import AppKit
import QenTerraDesignTokens
@testable import QenTerraMediaComponents
import SwiftUI
import Testing

@Test func mosaicPreservesAllSlotsAndOnePointGutters() {
    let bounds = CGRect(x: 10, y: 20, width: 201, height: 101)
    let fixtures: [[CGRect]] = [
        [],
        [CGRect(x: 10, y: 20, width: 201, height: 101)],
        [CGRect(x: 10, y: 20, width: 100, height: 101), CGRect(x: 111, y: 20, width: 100, height: 101)],
        [CGRect(x: 10, y: 20, width: 100, height: 101), CGRect(x: 111, y: 20, width: 100, height: 50), CGRect(x: 111, y: 71, width: 100, height: 50)],
        [CGRect(x: 10, y: 20, width: 100, height: 50), CGRect(x: 111, y: 20, width: 100, height: 50), CGRect(x: 10, y: 71, width: 100, height: 50), CGRect(x: 111, y: 71, width: 100, height: 50)],
    ]
    for count in 0 ... 4 {
        #expect(
            ArtworkMosaicLayout(slotCount: count).frames(in: bounds)
                == fixtures[count]
        )
    }
    #expect(ArtworkMosaicLayout(slotCount: -1).frames(in: bounds).isEmpty)
    #expect(ArtworkMosaicLayout(slotCount: 9).frames(in: bounds) == fixtures[4])
    #expect(
        ArtworkMosaicLayout(slotCount: 4).frames(in: .zero)
            .allSatisfy { $0.width >= 0 && $0.height >= 0 }
    )
}

@Test func cropRetainsAspectFillOverflowBeforeApplyingZoom() {
    let transform = ArtworkCropTransform(
        scale: 2,
        normalizedOffset: CGSize(width: 8, height: -8)
    )
    #expect(
        transform.offset(
            in: CGSize(width: 200, height: 200),
            sourceSize: CGSize(width: 400, height: 200)
        ) == CGSize(width: 300, height: -100)
    )
    let unzoomed = ArtworkCropTransform(scale: 1, normalizedOffset: CGSize(width: 1, height: 1))
    #expect(
        unzoomed.offset(
            in: CGSize(width: 200, height: 200),
            sourceSize: CGSize(width: 200, height: 400)
        ) == CGSize(width: 0, height: 100)
    )
}

@Test func invalidCropInputsCannotPublishNonfiniteGeometry() {
    #expect(ArtworkCropTransform(scale: -3).scale == 1)
    #expect(ArtworkCropTransform(scale: 12).scale == 4)
    #expect(ArtworkCropTransform(scale: .infinity).scale == 1)
    let transform = ArtworkCropTransform(
        scale: 2,
        normalizedOffset: CGSize(width: CGFloat.nan, height: CGFloat.infinity)
    )
    #expect(
        transform.offset(
            in: CGSize(width: 200, height: 200),
            sourceSize: CGSize(width: 200, height: 200)
        ) == .zero
    )
    #expect(transform.offset(in: .zero, sourceSize: CGSize(width: 200, height: 200)) == .zero)
    #expect(transform.offset(in: CGSize(width: 200, height: 200), sourceSize: .zero) == .zero)
}

@Test func placeholdersKeepRecognizableSymbolsAndOpticalInsets() {
    let fixtures: [(ArtworkPlaceholderKind, String, CGFloat, CGFloat)] = [
        (.artist, "person.fill", 20, 1.3), (.album, "square.stack.fill", 26, 0),
        (.track, "music.note", 30, 0), (.playlist, "music.note.list", 26, 0),
        (.collection, "sparkles.rectangle.stack", 26, 0),
    ]
    for (kind, symbol, inset, offset) in fixtures {
        #expect(kind.symbolName == symbol)
        #expect(kind.padding(in: CGSize(width: 100, height: 140)) == inset)
        #expect(kind.horizontalOffset(in: CGSize(width: 100, height: 140)) == offset)
    }
}

@Test func syntheticArtworkGeometryScalesAndCapsItsSymbol() {
    let geometry = ArtworkPlaceholderGeometry(size: CGSize(width: 200, height: 100))
    #expect(geometry.highlightSize == CGSize(width: 144, height: 72))
    #expect(geometry.highlightOffset == CGSize(width: 40, height: -18))
    #expect(geometry.blurRadius == 24)
    #expect(geometry.symbolSize == 34)
    #expect(ArtworkPlaceholderGeometry(size: CGSize(width: 20, height: 20)).symbolSize == 10)
}

@Test func artworkStatesKeepLoadingAndFailureDistinctAndLabelsUntruncated() {
    let title = String(repeating: "Очень длинное название — ", count: 30)
    #expect(ArtworkPresentationState.content.placeholderKind == nil)
    #expect(ArtworkPresentationState.loading.showsProgress)
    #expect(!ArtworkPresentationState.error(.album).showsProgress)
    #expect(ArtworkPresentationState.error(.album).placeholderKind == .album)
    #expect(ArtworkPresentationState.placeholder(.artist).placeholderKind == .artist)
    #expect(ArtworkPresentationState.error(.track).accessibilityValue == String(localized: "Artwork unavailable"))
    #expect(
        ArtworkSurfacePresentation(
            state: .content,
            title: title,
            showsBorder: true,
            increasedContrast: false
        ).accessibilityLabel.contains(title)
    )
    #expect(
        ArtworkSurfacePresentation(
            state: .content,
            title: title,
            showsBorder: true,
            increasedContrast: false
        ).borderWidth == 0.5
    )
    #expect(
        ArtworkSurfacePresentation(
            state: .content,
            title: title,
            showsBorder: true,
            increasedContrast: true
        ).borderWidth == 1
    )
    #expect(
        ArtworkSurfacePresentation(
            state: .content,
            title: title,
            showsBorder: false,
            increasedContrast: true
        ).borderWidth == 0
    )
}

@Test func hazeDropsAllLayersUnderReducedTransparencyAndNeverInterceptsInput() {
    let reduced = ArtworkHazePresentation(appearance: .dark, reducesTransparency: true)
    #expect(!reduced.isVisible)
    #expect(reduced.accessibilityHidden)
    #expect(!reduced.allowsHitTesting)
    let light = ArtworkHazePresentation(appearance: .light, reducesTransparency: false)
    #expect(light.isVisible)
    #expect(light.leadingOpacity == 0.62)
    #expect(light.trailingOpacity == 0.54)
    #expect(light.backgroundOpacity == 0.22)
    #expect(light.saturation == 1.28)
    #expect(!light.usesPlusLighter)
    let dark = ArtworkHazePresentation(appearance: .dark, reducesTransparency: false)
    #expect(dark.leadingOpacity == 0.48)
    #expect(dark.trailingOpacity == 0.40)
    #expect(dark.backgroundOpacity == 0.12)
    #expect(dark.saturation == 1.12)
    #expect(dark.usesPlusLighter)
}

@Test @MainActor func reducedTransparencyHazeRendersNoDecorativePixels() throws {
    let environment = DesignNativeEnvironment(
        appearance: .dark,
        productProfile: .cadence,
        density: .standard,
        isIncreasedContrast: false,
        reducesMotion: false,
        reducesTransparency: true
    )
    let renderer = ImageRenderer(
        content: ArtworkHaze(
            palette: ArtworkPalette(leading: .blue, trailing: .purple)
        )
        .environment(\.designNativeEnvironment, environment)
        .frame(width: 80, height: 80)
    )
    let image = try #require(renderer.cgImage)
    let color = try #require(
        NSBitmapImageRep(cgImage: image)
            .colorAt(x: 40, y: 40)?
            .usingColorSpace(.deviceRGB)
    )
    #expect(color.alphaComponent == 0)
}

@Test @MainActor func surfaceRendersReadyContentOnlyInContentState() throws {
    func center(_ state: ArtworkPresentationState) throws -> NSColor {
        let renderer = ImageRenderer(
            content: ArtworkSurface(
                state: state,
                title: "Fixture",
                cornerRadius: 0,
                showsBorder: false
            ) {
                Color.red
            }
            .frame(width: 80, height: 80)
        )
        let cgImage = try #require(renderer.cgImage)
        return try #require(
            NSBitmapImageRep(cgImage: cgImage)
                .colorAt(x: 5, y: 5)?
                .usingColorSpace(.deviceRGB)
        )
    }
    let content = try center(.content)
    let isReadyContent = content.redComponent > 0.8
        && content.greenComponent < 0.5
        && content.blueComponent < 0.5
    #expect(isReadyContent)
    for state: ArtworkPresentationState in [.placeholder(.album), .error(.track), .loading] {
        let color = try center(state)
        #expect(
            abs(color.redComponent - content.redComponent) > 0.1
                || abs(color.greenComponent - content.greenComponent) > 0.1
                || abs(color.blueComponent - content.blueComponent) > 0.1
        )
    }
}

@Test @MainActor func allArtworkViewsRenderWithReadyInputsAndNoApplicationServices() throws {
    let palette = ArtworkPalette(leading: .blue, trailing: .purple, symbolName: "waveform")
    let views: [AnyView] = [
        AnyView(ArtworkPlaceholder(palette: palette)),
        AnyView(ArtworkPlaceholder(kind: .artist)),
        AnyView(
            ArtworkCropSurface(
                transform: ArtworkCropTransform(scale: 2),
                sourceSize: CGSize(width: 400, height: 200),
                viewportSize: CGSize(width: 200, height: 200),
                shape: .circle,
                title: "Crop"
            ) {
                Color.orange
            }
        ),
        AnyView(
            ArtworkMosaic(slotCount: 3, title: "Collection") { index in
                index == 0 ? Color.blue : Color.green
            }
        ),
        AnyView(ArtworkMosaic(slotCount: 0, title: "Empty") { _ in Color.red }),
        AnyView(ArtworkHaze(palette: palette)),
    ]
    for view in views {
        let renderer = ImageRenderer(content: view.frame(width: 200, height: 200))
        #expect(try #require(renderer.cgImage).width == 200)
    }
}
#endif
