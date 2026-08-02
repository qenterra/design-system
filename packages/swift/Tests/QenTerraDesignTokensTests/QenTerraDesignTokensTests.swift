import Testing
@testable import QenTerraDesignTokens

@Test func stableAPIExposesGeneratedScales() {
    #expect(QDS.Space.value4 == 16)
    #expect(QDS.Radius.control == 6)
    #expect(QDS.Stroke.hairline == 0.5)
    #expect(QDS.Size.controlStandard == 32)
    #expect(QDS.MotionSeconds.disclosure == 0.18)
    #expect(QDS.SemanticName.textPrimary == "text.primary")
}
