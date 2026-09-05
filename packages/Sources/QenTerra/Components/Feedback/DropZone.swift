#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public enum DropZoneState: Equatable, Sendable {
    case ready(accessibilityValue: String)
    case targeted(accessibilityValue: String)
    case unavailable(accessibilityValue: String)

    public var presentation: DropZonePresentation {
        switch self {
        case let .ready(accessibilityValue):
            DropZonePresentation(isEnabled: true, isTargeted: false, accessibilityValue: accessibilityValue)
        case let .targeted(accessibilityValue):
            DropZonePresentation(isEnabled: true, isTargeted: true, accessibilityValue: accessibilityValue)
        case let .unavailable(accessibilityValue):
            DropZonePresentation(isEnabled: false, isTargeted: false, accessibilityValue: accessibilityValue)
        }
    }
}

public struct DropZonePresentation: Equatable, Sendable {
    public let isEnabled: Bool
    public let isTargeted: Bool
    public let accessibilityValue: String

    public init(isEnabled: Bool, isTargeted: Bool, accessibilityValue: String) {
        self.isEnabled = isEnabled
        self.isTargeted = isTargeted
        self.accessibilityValue = accessibilityValue
    }
}

public struct DropZone: View {
    private let state: DropZoneState
    private let title: String
    private let message: String

    public init(state: DropZoneState, title: String, message: String) {
        self.state = state
        self.title = title
        self.message = message
    }

    public var body: some View {
        VStack(spacing: DesignTokens.Space.value2) {
            Image(systemName: presentation.isTargeted ? "arrow.down.to.line.compact.fill" : "arrow.down.to.line.compact")
                .font(.title2)
                .accessibilityHidden(true)
            Text(title)
                .font(
                    .system(
                        size: DesignTokens.Typography.rowEmphasized.size,
                        weight: DesignTokens.Typography.rowEmphasized.swiftUIWeight
                    )
                )
                .foregroundStyle(Color(designToken: DesignTokens.Color.textPrimary))
            Text(message)
                .font(
                    .system(
                        size: DesignTokens.Typography.supporting.size,
                        weight: DesignTokens.Typography.supporting.swiftUIWeight
                    )
                )
                .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
                .multilineTextAlignment(.center)
        }
        .padding(DesignTokens.Space.value6)
        .frame(maxWidth: .infinity)
        .background(Color(designToken: DesignTokens.Color.surfaceSecondary))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.group, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.group, style: .continuous)
                .stroke(border, style: StrokeStyle(lineWidth: DesignTokens.Stroke.hairline, dash: [DesignTokens.Space.value1]))
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.group, style: .continuous)
                .stroke(
                    Color(designToken: DesignTokens.Color.textPrimary),
                    lineWidth: presentation.isTargeted ? DesignTokens.Stroke.focus : 0
                )
        }
        .opacity(presentation.isEnabled ? 1 : DesignTokens.Opacity.disabled)
        .disabled(!presentation.isEnabled)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(presentation.accessibilityValue)
    }

    private var presentation: DropZonePresentation { state.presentation }

    private var border: Color {
        switch state {
        case .ready: Color(designToken: DesignTokens.Color.borderDefault)
        case .targeted: Color(designToken: DesignTokens.Color.borderFocus)
        case .unavailable: Color(designToken: DesignTokens.Color.borderDefault)
        }
    }
}
#endif
