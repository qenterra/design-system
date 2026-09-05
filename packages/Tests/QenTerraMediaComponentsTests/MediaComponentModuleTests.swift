#if os(macOS)
import Testing
@testable import QenTerraMediaComponents
@testable import QenTerraDesignTokens

@Test func mediaComponentModuleUsesTheDesignSystemVersion() {
    #expect(MediaComponents.version == "1.0.1")
}

@Test func nativeEnvironmentResolvesAppearanceAndAccessibilityFromLiveValues() {
    let system = DesignSystemConfiguration(
        appearance: .system,
        productProfile: .cadence,
        density: .comfortable
    ).resolvedNativeEnvironment(
        colorScheme: .dark,
        colorSchemeContrast: .increased,
        reducesMotion: true,
        reducesTransparency: true
    )
    #expect(system.appearance == .dark)
    #expect(system.productProfile == .cadence)
    #expect(system.density == .comfortable)
    #expect(system.isIncreasedContrast)
    #expect(system.reducesMotion)
    #expect(system.reducesTransparency)

    let light = DesignSystemConfiguration(appearance: .light).resolvedNativeEnvironment(
        colorScheme: .dark,
        colorSchemeContrast: .standard,
        reducesMotion: false,
        reducesTransparency: false
    )
    #expect(light.appearance == .light)

    let dark = DesignSystemConfiguration(appearance: .dark).resolvedNativeEnvironment(
        colorScheme: .light,
        colorSchemeContrast: .standard,
        reducesMotion: false,
        reducesTransparency: false
    )
    #expect(dark.appearance == .dark)
}
#endif
