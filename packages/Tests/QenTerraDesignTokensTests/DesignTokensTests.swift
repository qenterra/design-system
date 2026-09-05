import Testing
@testable import QenTerraDesignTokens

#if canImport(AppKit)
import AppKit
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

@Test func publicTokenFacadeExposesCanonicalVersion() {
    #expect(DesignTokens.version == "1.0.1")
    #expect(DesignTokens.Space.value4 == 16)
    #expect(DesignTokens.Radius.control == 6)
}

@Test func semanticColorsResolveByAppearance() {
    let value = DesignTokens.Color.surfaceContent
    #expect(value.value(for: .light) == "#F4F4F6")
    #expect(value.value(for: .dark) == "#171719")
}

@Test func interactiveRowStateUsesDeterministicPriority() {
    let disabledSelected = InteractiveRowState(isSelected: true, isDisabled: true)
    #expect(disabledSelected.fill == DesignTokens.Color.fillDisabled)
    #expect(disabledSelected.border == nil)
    #expect(disabledSelected.contentOpacity == DesignTokens.Opacity.disabled)

    let focusedSelected = InteractiveRowState(isFocused: true, isSelected: true)
    #expect(focusedSelected.border == DesignTokens.Color.borderFocus)
}

@Test func cadenceProfileExposesTheApprovedFourPointLayout() {
    let metrics = DesignProductMetrics.cadence
    #expect(metrics.textStack == 4)
    #expect(metrics.compactGap == 8)
    #expect(metrics.controlGap == 12)
    #expect(metrics.contentGap == 16)
    #expect(metrics.panelInset == 20)
    #expect(metrics.pageInset == 24)
    #expect(metrics.sectionGap == 32)
    #expect(metrics.rowHeight == 48)
    #expect(metrics.readableContentWidth == 760)
}

@Test func componentSemanticValuesRetainUnitAwareSwiftTypes() {
    #expect(GeneratedTokens.Component.panelLyricsFollowDurationMs.milliseconds == 320)
    #expect(GeneratedTokens.Component.panelLyricsInactiveOpacity.value == 0.56)
    #expect(GeneratedTokens.Component.panelLyricsLineGap.points == 12)
}

#if canImport(SwiftUI)
@Test func systemPreferenceDoesNotFreezeAResolvedAppearance() {
    #expect(DesignAppearancePreference.system.preferredColorScheme == nil)
}

@Test func standaloneEnvironmentTracksNativeAppearanceAndConfiguration() {
    var values = EnvironmentValues()
    values.colorScheme = .dark
    values.designSystemConfiguration = .init(productProfile: .cadence, density: .comfortable)
    #expect(values.designNativeEnvironment.appearance == .dark)
    #expect(values.designNativeEnvironment.productProfile == .cadence)
    #expect(values.designNativeEnvironment.density == .comfortable)
    #expect(values.designProductProfile == .cadence)
    #expect(values.designDensity == .comfortable)

    values.colorScheme = .light
    values.designProductProfile = .standard
    values.designDensity = .compact
    #expect(values.designNativeEnvironment.appearance == .light)
    #expect(values.designNativeEnvironment.productProfile == .standard)
    #expect(values.designNativeEnvironment.density == .compact)
}

@Test(arguments: [false, true])
func explicitNativeEnvironmentWinsOverOpposingNativeInputs(reduced: Bool) {
    var values = EnvironmentValues()
    values.colorScheme = .dark
    values.designSystemConfiguration = .init(appearance: .dark, productProfile: .cadence, density: .comfortable)
    let injected = DesignNativeEnvironment(
        appearance: .light, productProfile: .standard, density: .compact,
        isIncreasedContrast: reduced, reducesMotion: reduced, reducesTransparency: reduced
    )
    values.designNativeEnvironment = injected

    // This is the getter's production resolution path, with controlled inputs for SDK read-only keys.
    let resolved = values.resolvedDesignNativeEnvironment(
        colorScheme: .dark, colorSchemeContrast: reduced ? .standard : .increased,
        reducesMotion: !reduced, reducesTransparency: !reduced
    )
    #expect(resolved == injected)
    #expect(values.designNativeEnvironment == injected)
    // An explicit aggregate does not mutate the other public keys.
    #expect(values.designSystemConfiguration.productProfile == .cadence)
    #expect(values.designProductProfile == .cadence)
    #expect(values.designDensity == .comfortable)
}

@Test func uninjectedEnvironmentResolvesEveryLiveAccessibilityInput() {
    let values = EnvironmentValues()
    let motion = values.resolvedDesignNativeEnvironment(
        colorScheme: .dark, colorSchemeContrast: .standard,
        reducesMotion: true, reducesTransparency: false
    )
    #expect(motion.appearance == .dark)
    #expect(motion.reducesMotion)
    #expect(!motion.isIncreasedContrast)
    #expect(!motion.reducesTransparency)

    let contrastAndTransparency = values.resolvedDesignNativeEnvironment(
        colorScheme: .light, colorSchemeContrast: .increased,
        reducesMotion: false, reducesTransparency: true
    )
    #expect(contrastAndTransparency.appearance == .light)
    #expect(!contrastAndTransparency.reducesMotion)
    #expect(contrastAndTransparency.isIncreasedContrast)
    #expect(contrastAndTransparency.reducesTransparency)
}
#endif

#if canImport(AppKit) && canImport(SwiftUI)
@Test func nativeColorTokensResolveDynamicallyForEachAppKitAppearance() {
    let dynamic = NSColor.designToken(DesignTokens.Color.surfaceContent)
    var light: NSColor?
    NSAppearance(named: .aqua)!.performAsCurrentDrawingAppearance {
        light = dynamic.usingColorSpace(.sRGB)
    }
    var dark: NSColor?
    NSAppearance(named: .darkAqua)!.performAsCurrentDrawingAppearance {
        dark = dynamic.usingColorSpace(.sRGB)
    }
    let swiftUIColor = Color(designToken: DesignTokens.Color.surfaceContent)

    #expect(abs((light?.redComponent ?? 0) - 244.0 / 255.0) < 0.000_001)
    #expect(abs((dark?.redComponent ?? 0) - 23.0 / 255.0) < 0.000_001)
    #expect(swiftUIColor != Color.clear)
}
#endif
