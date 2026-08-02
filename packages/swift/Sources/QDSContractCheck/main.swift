import QenTerraDesignTokens

precondition(QDS.Space.value4 == 16)
precondition(QDS.Radius.control == 6)
precondition(QDS.Stroke.hairline == 0.5)
precondition(QDS.Size.controlStandard == 32)
precondition(QDS.MotionSeconds.disclosure == 0.18)
precondition(QDS.SemanticName.textPrimary == "text.primary")
precondition(QDS.Color.textPrimary.value(for: .light) == "#1A1A1C")
precondition(QDS.Typography.body.lineHeight == 20)
precondition(QDS.Motion.feedbackPress.seconds == 0.08)
precondition(QDS.Component.navigationSidebarStandard.points == 256)

print("QenTerraDesignTokens \(QDS.version) contract passed")
