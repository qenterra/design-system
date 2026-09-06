#if os(macOS)
import AppKit
import QenTerraMediaComponents
import SwiftUI
import Testing

@MainActor
struct LyricsEdgeFadeTests {
    @Test
    func defaultRetainsOriginalEdgeOverlayPixels() throws {
        let actual = Color.white.overlay { LyricsEdgeFade() }.compositingGroup()
        let original = Color.white.overlay {
            VStack(spacing: 0) {
                LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 32)
                Spacer(minLength: 0)
                LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                    .frame(height: 32)
            }
            .blendMode(.destinationOut)
            .compositingGroup()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }.compositingGroup()
        let equal = try pixels(actual) == pixels(original)
        #expect(equal)
    }

    @Test
    func viewportMaskMatchesExactWholeViewportGradient() throws {
        let actual = Color.white.mask {
            LyricsEdgeFade(presentation: .viewportMask(.init(
                topOpaqueLocation: 0.18, bottomOpaqueLocation: 0.88
            )))
        }
        let reference = Color.white.mask {
            LinearGradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: 0.18),
                .init(color: .black, location: 0.88),
                .init(color: .clear, location: 1),
            ], startPoint: .top, endPoint: .bottom)
        }
        let actualImage = try render(actual)
        let equal = try pixels(actual) == pixels(reference)
        #expect(equal)
        let bitmap = NSBitmapImageRep(cgImage: actualImage)
        let top = try #require(bitmap.colorAt(x: 60, y: 0))
        let plateau = try #require(bitmap.colorAt(x: 60, y: 100))
        let bottom = try #require(bitmap.colorAt(x: 60, y: 199))
        #expect(top.alphaComponent < 0.05)
        #expect(plateau.alphaComponent > 0.99)
        #expect(bottom.alphaComponent < 0.05)
    }

    @Test
    func maskConfigurationClampsOrdersAndRejectsNonfiniteLocations() {
        let cases: [(Double, Double, Double, Double)] = [
            (0.18, 0.88, 0.18, 0.88),
            (-0.2, 1.2, 0, 1),
            (0.9, 0.1, 0.1, 0.9),
            (.nan, .infinity, 0, 1),
            (-.infinity, .nan, 0, 1),
            (0.5, 0.5, 0.5, 0.5),
        ]
        for (top, bottom, expectedTop, expectedBottom) in cases {
            let configuration = LyricsEdgeFadeMaskConfiguration(
                topOpaqueLocation: top, bottomOpaqueLocation: bottom
            )
            #expect(configuration.topOpaqueLocation == expectedTop)
            #expect(configuration.bottomOpaqueLocation == expectedBottom)
        }
    }

    private func pixels(_ view: some View) throws -> Data {
        let image = try render(view)
        return try #require(image.dataProvider?.data) as Data
    }

    private func render(_ view: some View) throws -> CGImage {
        let renderer = ImageRenderer(content: view.frame(width: 120, height: 200))
        renderer.scale = 1
        return try #require(renderer.cgImage)
    }
}
#endif
