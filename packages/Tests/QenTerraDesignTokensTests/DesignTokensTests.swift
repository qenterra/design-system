import Testing
@testable import QenTerraDesignTokens

@Test func publicTokenFacadeExposesCanonicalVersion() {
    #expect(DesignTokens.version == "5.3.0")
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
