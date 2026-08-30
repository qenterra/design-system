#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

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
#endif
