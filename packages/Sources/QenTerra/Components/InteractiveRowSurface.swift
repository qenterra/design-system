#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public typealias InteractiveRowState = QenTerraDesignTokens.InteractiveRowState

public struct InteractiveRowSurface<Content: View>: View {
    @Environment(\.designNativeEnvironment) private var nativeEnvironment

    private let state: InteractiveRowState
    private let appearanceOverride: DesignAppearance?
    private let content: Content

    public init(
        state: InteractiveRowState,
        @ViewBuilder content: () -> Content
    ) {
        self.init(state: state, appearanceOverride: nil, content: content)
    }

    @available(*, deprecated, message: "Use InteractiveRowSurface(state:content:) with View.designSystem(_:) instead.")
    public init(
        state: InteractiveRowState,
        appearance: DesignAppearance,
        @ViewBuilder content: () -> Content
    ) {
        self.init(state: state, appearanceOverride: appearance, content: content)
    }

    public var body: some View {
        content
            .contentShape(Rectangle())
            .opacity(resolvedState.isLoading ? 0 : resolvedState.contentOpacity)
            .background(fillColor)
            .overlay {
                if let border = resolvedState.border {
                    RoundedRectangle(
                        cornerRadius: DesignTokens.Radius.control,
                        style: .continuous
                    )
                    .stroke(
                        color(border),
                        lineWidth: resolvedState.borderWidth
                    )
                }
                if resolvedState.isLoading {
                    loadingIndicator
                }
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: DesignTokens.Radius.control,
                    style: .continuous
                )
            )
            .allowsHitTesting(!resolvedState.isLoading)
            .animation(
                reducesMotion
                    ? nil
                    : .easeOut(duration: DesignTokens.Motion.feedbackPress.seconds),
                value: resolvedState
            )
            .accessibilityValue(resolvedState.isLoading ? Text("Loading") : Text(""))
    }

    private var fillColor: Color {
        resolvedState.fill.map(color) ?? .clear
    }

    private var resolvedState: InteractiveRowState {
        InteractiveRowState(
            isHovered: state.isHovered,
            isPressed: state.isPressed,
            isFocused: state.isFocused,
            isSelected: state.isSelected,
            isDisabled: state.isDisabled,
            isUnavailable: state.isUnavailable,
            isIncreasedContrast: state.isIncreasedContrast || isIncreasedContrast,
            isLoading: state.isLoading
        )
    }

    @ViewBuilder private var loadingIndicator: some View {
        if reducesMotion {
            Image(systemName: "ellipsis")
                .accessibilityHidden(true)
        } else {
            ProgressView()
                .controlSize(.small)
                .accessibilityHidden(true)
        }
    }

    private var reducesMotion: Bool {
        nativeEnvironment.reducesMotion
    }

    private var isIncreasedContrast: Bool {
        nativeEnvironment.isIncreasedContrast
    }

    private init(
        state: InteractiveRowState,
        appearanceOverride: DesignAppearance?,
        @ViewBuilder content: () -> Content
    ) {
        self.state = state
        self.appearanceOverride = appearanceOverride
        self.content = content()
    }

    private func color(_ token: DesignColorValue) -> Color {
        if let appearanceOverride {
            return Color(designToken: token, appearance: appearanceOverride)
        }
        return Color(designToken: token)
    }
}
#endif
