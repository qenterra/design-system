#if canImport(SwiftUI)
import QenTerraDesignTokens
import SwiftUI

public enum AboutResourceOpenRejection: Equatable, Sendable {
    case discarded
}

public enum AboutResourceRowStyle: Equatable, Sendable {
    case standard
    case cadence
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
    private let style: AboutResourceRowStyle
    private let injectedOpenURLAction: OpenURLAction?
    private let onOpenRejected: @MainActor @Sendable (AboutResourceOpenRejection) -> Void

    public init(
        resource: AboutResource,
        style: AboutResourceRowStyle = .standard,
        openURLAction: OpenURLAction? = nil,
        onOpenRejected: @escaping @MainActor @Sendable (AboutResourceOpenRejection) -> Void = { _ in }
    ) {
        self.resource = resource
        self.style = style
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
            HStack(spacing: style == .cadence ? DesignProductMetrics.cadence.controlGap : DesignTokens.Space.value3) {
                resourceSymbol.accessibilityHidden(true)
                VStack(alignment: .leading, spacing: DesignTokens.Space.value1) {
                    resourceTitle
                    Text(resource.subtitle)
                        .font(
                            .system(
                                size: DesignTokens.Typography.supporting.size,
                                weight: DesignTokens.Typography.supporting.swiftUIWeight
                            )
                        )
                        .foregroundStyle(
                            Color(
                                designToken: style == .cadence
                                    ? DesignTokens.Color.textTertiary
                                    : DesignTokens.Color.textSecondary
                            )
                        )
                        .lineLimit(style == .cadence ? 1 : nil)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(
                        Color(
                            designToken: style == .cadence
                                ? DesignTokens.Color.textSecondary
                                : DesignTokens.Color.textLink
                        )
                    )
                    .accessibilityHidden(true)
            }
            .padding(
                style == .cadence ? .horizontal : .all,
                style == .cadence
                    ? DesignProductMetrics.cadence.compactGap
                    : DesignTokens.Space.value4
            )
            .frame(
                maxWidth: .infinity,
                minHeight: style == .cadence ? 54 : nil,
                alignment: .leading
            )
        }
        .buttonStyle(DesignButtonStyle(role: .link))
        .disabled(!presentation.isEnabled)
        .accessibilityLabel(presentation.title)
        .accessibilityHint(presentation.accessibilityHint)
        .accessibilityValue(presentation.accessibilityValue)
    }

    @ViewBuilder private var resourceSymbol: some View {
        if style == .cadence {
            Image(systemName: resource.symbol)
                .font(.system(size: 15, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
                .frame(width: 26, height: 26)
        } else {
            Image(systemName: resource.symbol)
                .foregroundStyle(Color(designToken: DesignTokens.Color.textLink))
        }
    }

    @ViewBuilder private var resourceTitle: some View {
        if style == .cadence {
            Text(resource.title).font(.callout.weight(.medium))
                .foregroundStyle(Color(designToken: DesignTokens.Color.textPrimary))
        } else {
            Text(resource.title).foregroundStyle(Color(designToken: DesignTokens.Color.textLink))
        }
    }
}
#endif
