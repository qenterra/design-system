#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public struct PrimaryButtonStyle: ButtonStyle {
    private let appearance: DesignAppearance

    public init(appearance: DesignAppearance) {
        self.appearance = appearance
    }

    public func makeBody(configuration: Configuration) -> some View {
        PrimaryButtonBody(
            label: configuration.label,
            isPressed: configuration.isPressed,
            appearance: appearance
        )
    }
}

private struct PrimaryButtonBody<Label: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let label: Label
    let isPressed: Bool
    let appearance: DesignAppearance

    var body: some View {
        label
            .font(
                .system(
                    size: DesignTokens.Typography.bodyEmphasized.size,
                    weight: DesignTokens.Typography.bodyEmphasized.swiftUIWeight
                )
            )
            .foregroundStyle(
                Color(
                    designToken: DesignTokens.Color.actionPrimaryContent,
                    appearance: appearance
                )
            )
            .padding(.horizontal, DesignTokens.Component.buttonPaddingXStandard.points)
            .frame(minHeight: DesignTokens.Component.buttonHeightsStandard.points)
            .background(
                Color(designToken: DesignTokens.Color.actionPrimary, appearance: appearance)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: DesignTokens.Radius.control,
                    style: .continuous
                )
            )
            .opacity(contentOpacity)
            .animation(
                reduceMotion ? nil : .easeOut(duration: DesignTokens.Motion.feedbackPress.seconds),
                value: isPressed
            )
    }

    private var contentOpacity: Double {
        if !isEnabled { return DesignTokens.Opacity.disabled }
        return isPressed ? DesignTokens.Opacity.pressed : 1
    }
}
#endif
