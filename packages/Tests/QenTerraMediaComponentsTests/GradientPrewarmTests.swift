#if os(macOS)
import Metal
@testable import QenTerraMediaComponents
import Testing

@Test func gradientPrewarmReusesTheCompiledLibraryWithoutReplacingInjectedShader() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let source = try #require(ArtworkAccentGradientShader.source)
    let first = try #require(ArtworkAccentGradientResources.library(device: device, shaderSource: source))
    let second = try #require(ArtworkAccentGradientResources.library(device: device, shaderSource: source))
    #expect(first === second)
    #expect(ArtworkAccentGradientResources.library(device: device, shaderSource: nil) == nil)
    #expect(ArtworkAccentGradientResources.library(device: device, shaderSource: "invalid shader") == nil)
}
#endif
