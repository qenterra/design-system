#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public enum StatusTone: String, Equatable, Sendable {
    case informative
    case success
    case warning
    case destructive
}

public struct StatusBannerConfiguration: Equatable, Sendable, Identifiable {
    public let id: String
    public let tone: StatusTone
    public let title: String
    public let message: String?

    public init(
        id: String,
        tone: StatusTone,
        title: String,
        message: String? = nil
    ) {
        self.id = id
        self.tone = tone
        self.title = title
        self.message = message
    }
}

@MainActor
public struct StatusBanner: View {
    private let configuration: StatusBannerConfiguration
    private let action: PresentationAction?
    private let dismiss: PresentationAction?

    public init(
        configuration: StatusBannerConfiguration,
        action: PresentationAction? = nil,
        dismiss: PresentationAction? = nil
    ) {
        self.configuration = configuration
        self.action = action
        self.dismiss = dismiss
    }

    public var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Space.value3) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: DesignTokens.Space.value1) {
                Text(configuration.title)
                    .font(
                        .system(
                            size: DesignTokens.Typography.rowEmphasized.size,
                            weight: DesignTokens.Typography.rowEmphasized.swiftUIWeight
                        )
                    )
                    .foregroundStyle(Color(designToken: DesignTokens.Color.textPrimary))
                if let message = configuration.message {
                    Text(message)
                        .font(
                            .system(
                                size: DesignTokens.Typography.supporting.size,
                                weight: DesignTokens.Typography.supporting.swiftUIWeight
                            )
                        )
                        .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            if let action {
                Button(action.title) {
                    action.perform()
                }
                .buttonStyle(DesignButtonStyle(role: .quiet))
            }
            if let dismiss {
                Button(dismiss.title) {
                    dismiss.perform()
                }
                .buttonStyle(DesignButtonStyle(role: .icon))
            }
        }
        .padding(DesignTokens.Space.value4)
        .background(Color(designToken: DesignTokens.Color.surfaceRaised))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.group, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.group, style: .continuous)
                .stroke(tint, lineWidth: DesignTokens.Stroke.hairline)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(configuration.id)
    }

    private var symbol: String {
        switch configuration.tone {
        case .informative: "info.circle"
        case .success: "checkmark.circle"
        case .warning: "exclamationmark.triangle"
        case .destructive: "xmark.octagon"
        }
    }

    private var tint: Color {
        switch configuration.tone {
        case .informative: Color(designToken: DesignTokens.Color.stateInformative)
        case .success: Color(designToken: DesignTokens.Color.stateSuccess)
        case .warning: Color(designToken: DesignTokens.Color.stateWarning)
        case .destructive: Color(designToken: DesignTokens.Color.stateDestructive)
        }
    }
}
#endif
