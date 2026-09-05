#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public enum AboutResourceOpenRejection: Equatable, Sendable {
    case discarded
}

public struct AboutResourceRowPresentation: Equatable, Sendable {
    public let title: String
    public let accessibilityHint: String
    public let accessibilityValue: String
    public let isEnabled: Bool

    public init(resource: AboutResource) {
        title = resource.title
        accessibilityHint = resource.accessibilityHint
        accessibilityValue = resource.availability.accessibilityValue ?? resource.destination.absoluteString
        isEnabled = resource.availability.isEnabled
    }
}

@MainActor
public struct AboutResourceRow: View {
    @Environment(\.openURL) private var openURL

    private let resource: AboutResource
    private let injectedOpenURLAction: OpenURLAction?
    private let onOpenRejected: @MainActor @Sendable (AboutResourceOpenRejection) -> Void

    public init(
        resource: AboutResource,
        openURLAction: OpenURLAction? = nil,
        onOpenRejected: @escaping @MainActor @Sendable (AboutResourceOpenRejection) -> Void = { _ in }
    ) {
        self.resource = resource
        injectedOpenURLAction = openURLAction
        self.onOpenRejected = onOpenRejected
    }

    public var presentation: AboutResourceRowPresentation {
        AboutResourceRowPresentation(resource: resource)
    }

    public func activate() {
        guard presentation.isEnabled else { return }
        (injectedOpenURLAction ?? openURL)(resource.destination) { accepted in
            if !accepted {
                onOpenRejected(.discarded)
            }
        }
    }

    public var body: some View {
        Button {
            activate()
        } label: {
            HStack(spacing: DesignTokens.Space.value3) {
                Image(systemName: resource.symbol)
                    .foregroundStyle(Color(designToken: DesignTokens.Color.textLink))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: DesignTokens.Space.value1) {
                    Text(resource.title)
                        .foregroundStyle(Color(designToken: DesignTokens.Color.textLink))
                    Text(resource.subtitle)
                        .font(
                            .system(
                                size: DesignTokens.Typography.supporting.size,
                                weight: DesignTokens.Typography.supporting.swiftUIWeight
                            )
                        )
                        .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(Color(designToken: DesignTokens.Color.textLink))
                    .accessibilityHidden(true)
            }
            .padding(DesignTokens.Space.value4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(DesignButtonStyle(role: .link))
        .disabled(!presentation.isEnabled)
        .accessibilityLabel(presentation.title)
        .accessibilityHint(presentation.accessibilityHint)
        .accessibilityValue(presentation.accessibilityValue)
    }
}
#endif
