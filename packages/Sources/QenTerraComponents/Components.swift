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

public struct GroupContainer: ViewModifier {
    private let appearance: DesignAppearance

    public init(appearance: DesignAppearance) {
        self.appearance = appearance
    }

    public func body(content: Content) -> some View {
        content
            .padding(DesignTokens.Component.groupPadding.points)
            .background(
                Color(designToken: DesignTokens.Color.surfaceSecondary, appearance: appearance)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: DesignTokens.Radius.group,
                    style: .continuous
                )
            )
    }
}

public struct InteractiveRowSurface<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let state: InteractiveRowState
    private let appearance: DesignAppearance
    private let content: Content

    public init(
        state: InteractiveRowState,
        appearance: DesignAppearance,
        @ViewBuilder content: () -> Content
    ) {
        self.state = state
        self.appearance = appearance
        self.content = content()
    }

    public var body: some View {
        content
            .contentShape(Rectangle())
            .background(fillColor)
            .overlay {
                if let border = state.border {
                    RoundedRectangle(
                        cornerRadius: DesignTokens.Radius.control,
                        style: .continuous
                    )
                    .stroke(
                        Color(designToken: border, appearance: appearance),
                        lineWidth: state.borderWidth
                    )
                }
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: DesignTokens.Radius.control,
                    style: .continuous
                )
            )
            .opacity(state.contentOpacity)
            .animation(
                reduceMotion
                    ? nil
                    : .easeOut(duration: DesignTokens.Motion.feedbackPress.seconds),
                value: state
            )
    }

    private var fillColor: Color {
        state.fill.map {
            Color(designToken: $0, appearance: appearance)
        } ?? .clear
    }
}

public extension View {
    func designGroupContainer(appearance: DesignAppearance) -> some View {
        modifier(GroupContainer(appearance: appearance))
    }
}
#endif
