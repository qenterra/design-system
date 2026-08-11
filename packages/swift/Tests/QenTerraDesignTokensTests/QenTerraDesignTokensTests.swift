import AppKit
import SwiftUI
import Testing
@testable import QenTerraDesignTokens

@Test func publicFacadeVersionAndTypesRemainAvailable() {
    #expect(QDS.version == "1.12.0")
    #expect(QDSIcon.success.rawValue == "success")

    _ = QDSPrimaryButtonStyle(appearance: .light)
    _ = QDSGroupContainer(appearance: .light)
    _ = QDSInteractiveRowSurface(state: .init(), appearance: .light) { Text("Row") }
}

@Test func stableAPIExposesGeneratedScales() {
    #expect(QDS.Space.value4 == 16)
    #expect(QDS.Radius.control == 6)
    #expect(QDS.Stroke.hairline == 0.5)
    #expect(QDS.Size.controlStandard == 32)
    #expect(QDS.MotionSeconds.disclosure == 0.18)
    #expect(QDS.SemanticName.textPrimary == "text.primary")
    #expect(QDS.Color.textPrimary.value(for: .dark) == "#FFFFFF")
    #expect(QDS.Typography.body.size == 14)
    #expect(QDS.Motion.disclosureToggle.seconds == 0.18)
    #expect(QDS.Component.buttonHeightsStandard.points == 32)
    #expect(QDS.Icon.globe.rawValue == "globe")
}

@Test func rgbaSemanticColorsPreserveChannelsAndAlpha() throws {
    let color = NSColor(Color(qds: QDS.Color.fillHover, appearance: .light))
    let resolved = try #require(color.usingColorSpace(.deviceRGB))

    #expect(abs(resolved.redComponent - 15.0 / 255.0) < 0.001)
    #expect(abs(resolved.greenComponent - 15.0 / 255.0) < 0.001)
    #expect(abs(resolved.blueComponent - 17.0 / 255.0) < 0.001)
    #expect(abs(resolved.alphaComponent - 0.045) < 0.001)
}

@Test func interactiveRowStateUsesDeterministicSemanticPriority() {
    let selectedHover = QDSInteractiveRowState(isHovered: true, isSelected: true)
    #expect(selectedHover.fill == QDS.Color.fillSelected)
    #expect(selectedHover.border == QDS.Color.borderStrong)

    let focused = QDSInteractiveRowState(isFocused: true)
    #expect(focused.fill == nil)
    #expect(focused.border == QDS.Color.borderFocus)

    let disabledSelection = QDSInteractiveRowState(isSelected: true, isDisabled: true)
    #expect(disabledSelection.fill == QDS.Color.fillDisabled)
    #expect(disabledSelection.border == nil)
    #expect(disabledSelection.contentOpacity == 0.5)

    let increasedContrastSelection = QDSInteractiveRowState(
        isFocused: true,
        isSelected: true,
        isIncreasedContrast: true
    )
    #expect(increasedContrastSelection.fill == QDS.Color.fillSelectedStrong)
    #expect(increasedContrastSelection.borderWidth == QDS.Stroke.focus)
}
