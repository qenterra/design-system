#if os(macOS)
import AppKit
import MetalKit
@testable import QenTerraMediaComponents
import SwiftUI
import Testing

@Test @MainActor func swiftUIGradientCompositionPreservesNativeMultiplyAndOpaqueFallback() throws {
    let palette = ArtworkAccentPalette.fallback
    let size = CGSize(width: 320, height: 240)
    let raw = try #require(ArtworkAccentGradientSnapshot.render(
        palette: palette, size: size, time: 2.5, device: MTLCreateSystemDefaultDevice()
    ))
    for active in [false, true] {
        let appearance = ArtworkAccentGradientAppearance(
            isAnimated: false, maximumFramesPerSecond: 60,
            tint: .resolve(palette: palette, isEffectActive: active, reducesMotion: true)
        )
        let reference = ImageRenderer(content: ZStack {
            Image(decorative: raw, scale: 1).resizable()
            Color.black.opacity(ArtworkAccentGradientTint.baseOpacity(for: palette))
            Color(red: appearance.tint.color.red, green: appearance.tint.color.green, blue: appearance.tint.color.blue)
                .blendMode(.multiply).opacity(appearance.tint.amount)
        }.frame(width: size.width, height: size.height))
        let candidate = ImageRenderer(content: ArtworkAccentGradientComposition(palette: palette, appearance: appearance) {
            Image(decorative: raw, scale: 1).resizable()
        }.frame(width: size.width, height: size.height))
        reference.scale = 1
        candidate.scale = 1
        let lhs = try #require(reference.cgImage?.dataProvider?.data as Data?)
        let rhs = try #require(candidate.cgImage?.dataProvider?.data as Data?)
        #expect(lhs == rhs)

        let fallback = Color(red: 0.2, green: 0.3, blue: 0.4)
        let failure = ImageRenderer(content: ArtworkAccentGradientComposition(
            palette: palette, appearance: appearance, hasTerrain: false
        ) { fallback }.frame(width: 32, height: 32))
        let opaqueReference = ImageRenderer(content: fallback.frame(width: 32, height: 32))
        failure.scale = 1
        opaqueReference.scale = 1
        #expect(try #require(failure.cgImage?.dataProvider?.data as Data?)
            == #require(opaqueReference.cgImage?.dataProvider?.data as Data?))
    }
}

@Test @MainActor func swiftUISurfaceUsesRawNativeTerrainWithoutDoubleOverlays() throws {
    let host = NSHostingView(rootView: ArtworkAccentGradient(palette: .fallback, isEffectActive: true))
    host.frame = CGRect(x: 0, y: 0, width: 320, height: 240)
    host.layoutSubtreeIfNeeded()
    func surface(in view: NSView) -> ArtworkAccentGradientView? {
        (view as? ArtworkAccentGradientView) ?? view.subviews.lazy.compactMap { surface(in: $0) }.first
    }
    let native = try #require(surface(in: host))
    #expect(native.delegate != nil)
    #expect(!native.appliesAppearanceOverlays)
    // The visible native colour layers are zero-opacity; SwiftUI supplies both overlays.
    for overlay in native.subviews where !(overlay is MTKView) && !overlay.isHidden {
        #expect(overlay.layer?.opacity == 0)
    }
}
#endif
