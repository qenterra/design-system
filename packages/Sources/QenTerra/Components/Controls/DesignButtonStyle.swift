#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public enum DesignButtonRole: String, CaseIterable, Sendable {
    case primary
    case secondary
    case quiet
    case destructive
    case icon
    case menuRow
    case link
}

public struct DesignButtonState: Equatable, Sendable {
    public var isHovered: Bool
    public var isPressed: Bool
    public var isFocused: Bool
    public var isSelected: Bool
    public var isLoading: Bool

    public init(
        isHovered: Bool = false,
        isPressed: Bool = false,
        isFocused: Bool = false,
        isSelected: Bool = false,
        isLoading: Bool = false
    ) {
        self.isHovered = isHovered
        self.isPressed = isPressed
        self.isFocused = isFocused
        self.isSelected = isSelected
        self.isLoading = isLoading
    }
}

public struct DesignButtonStyle: ButtonStyle {
    private let role: DesignButtonRole
    private let state: DesignButtonState
    private let appearanceOverride: DesignAppearance?

    public init(role: DesignButtonRole, state: DesignButtonState = .init()) {
        self.role = role
        self.state = state
        appearanceOverride = nil
    }

    init(role: DesignButtonRole, state: DesignButtonState = .init(), appearanceOverride: DesignAppearance) {
        self.role = role
        self.state = state
        self.appearanceOverride = appearanceOverride
    }

    public func makeBody(configuration: Configuration) -> some View {
        DesignButtonBody(
            role: role,
            state: state,
            label: configuration.label,
            isPressed: configuration.isPressed,
            appearanceOverride: appearanceOverride
        )
    }
}

private struct DesignButtonBody<Label: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.designNativeEnvironment) private var nativeEnvironment

    let role: DesignButtonRole
    let state: DesignButtonState
    let label: Label
    let isPressed: Bool
    let appearanceOverride: DesignAppearance?

    var body: some View {
        ZStack {
            label.opacity(resolvedState.isLoading ? 0 : 1)
            if resolvedState.isLoading {
                loadingIndicator
            }
        }
        .font(
            .system(
                size: DesignTokens.Typography.bodyEmphasized.size,
                weight: DesignTokens.Typography.bodyEmphasized.swiftUIWeight
            )
        )
        .foregroundStyle(color(foregroundToken))
        .padding(.horizontal, horizontalPadding)
        .frame(minHeight: DesignTokens.Component.buttonHeightsStandard.points)
        .background(color(backgroundToken))
        .clipShape(shape)
        .overlay {
            if resolvedState.isFocused {
                shape.stroke(
                    color(DesignTokens.Color.borderFocus),
                    lineWidth: DesignTokens.Stroke.focus
                )
            }
        }
        .opacity(opacity)
        .animation(
            reducesMotion
                ? nil
                : .easeOut(duration: DesignTokens.Motion.feedbackPress.seconds),
            value: resolvedState.isPressed
        )
        .accessibilityValue(resolvedState.isLoading ? Text("Loading") : Text(""))
        .accessibilityHint(resolvedState.isLoading ? Text("Loading") : Text(""))
    }

    private var resolvedState: DesignButtonState {
        var resolved = state
        resolved.isPressed = resolved.isPressed || isPressed
        return resolved
    }

    @ViewBuilder private var loadingIndicator: some View {
        if reducesMotion {
            Image(systemName: "ellipsis")
                .accessibilityHidden(true)
        } else {
            ProgressView()
                .controlSize(.small)
                .tint(Color(designToken: foregroundToken, appearance: appearanceOverride ?? nativeEnvironment.appearance))
                .environment(\.colorScheme, loadingColorScheme)
                .accessibilityHidden(true)
        }
    }

    private var reducesMotion: Bool {
        nativeEnvironment.reducesMotion
    }

    private var loadingColorScheme: ColorScheme {
        let appearance = appearanceOverride ?? nativeEnvironment.appearance
        // Native progress indicators use appearance for their monochrome strokes on macOS.
        let usesInverseContent = foregroundToken == DesignTokens.Color.actionPrimaryContent
        return (appearance == .dark) != usesInverseContent ? .dark : .light
    }

    private var isIncreasedContrast: Bool {
        nativeEnvironment.isIncreasedContrast
    }

    private func color(_ token: DesignColorValue) -> Color {
        if let appearanceOverride {
            return Color(designToken: token, appearance: appearanceOverride)
        }
        return Color(designToken: token)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous)
    }

    private var horizontalPadding: Double {
        role == .icon ? DesignTokens.Component.buttonPaddingXCompact.points : DesignTokens.Component.buttonPaddingXStandard.points
    }

    private var opacity: Double {
        guard isEnabled else { return DesignTokens.Opacity.disabled }
        return resolvedState.isPressed ? DesignTokens.Opacity.pressed : 1
    }

    private var backgroundToken: DesignColorValue {
        if resolvedState.isSelected {
            return isIncreasedContrast
                ? DesignTokens.Color.fillSelectedStrong
                : DesignTokens.Color.fillSelected
        }
        if resolvedState.isPressed {
            return role == .primary ? DesignTokens.Color.actionPrimary : DesignTokens.Color.fillPressed
        }
        if resolvedState.isHovered {
            return role == .primary ? DesignTokens.Color.actionPrimary : DesignTokens.Color.fillHover
        }
        return switch role {
        case .primary: DesignTokens.Color.actionPrimary
        case .secondary: DesignTokens.Color.actionSecondary
        case .destructive: DesignTokens.Color.stateDestructive
        case .quiet, .icon, .menuRow, .link: DesignTokens.Color.surfaceContent
        }
    }

    private var foregroundToken: DesignColorValue {
        if resolvedState.isSelected || (role == .destructive && (resolvedState.isHovered || resolvedState.isPressed)) {
            return DesignTokens.Color.actionSecondaryContent
        }
        return switch role {
        case .primary, .destructive: DesignTokens.Color.actionPrimaryContent
        case .secondary: DesignTokens.Color.actionSecondaryContent
        case .quiet, .icon, .menuRow: DesignTokens.Color.actionQuietContent
        case .link: DesignTokens.Color.textLink
        }
    }
}
#endif
