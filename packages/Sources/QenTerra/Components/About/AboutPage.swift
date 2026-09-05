#if canImport(SwiftUI)
import SwiftUI
import Foundation
import QenTerraDesignTokens

public enum AboutResourceAvailability: Equatable, Sendable {
    case available
    case unavailable(accessibilityValue: String)

    public var isEnabled: Bool {
        if case .available = self { return true }
        return false
    }

    public var accessibilityValue: String? {
        if case let .unavailable(accessibilityValue) = self {
            return accessibilityValue
        }
        return nil
    }
}

public struct AboutResource: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let symbol: String
    public let destination: URL
    public let accessibilityHint: String
    public let availability: AboutResourceAvailability

    public init(
        id: String,
        title: String,
        subtitle: String,
        symbol: String,
        destination: URL,
        accessibilityHint: String,
        availability: AboutResourceAvailability = .available
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.destination = destination
        self.accessibilityHint = accessibilityHint
        self.availability = availability
    }
}

public struct AboutPageConfiguration: Equatable, Sendable {
    public let applicationName: String
    public let tagline: String
    public let description: String
    public let versionText: String
    public let creatorText: String
    public let copyrightText: String
    public let resourcesTitle: String
    public let resources: [AboutResource]

    public init(
        applicationName: String,
        tagline: String,
        description: String,
        versionText: String,
        creatorText: String,
        copyrightText: String,
        resourcesTitle: String,
        resources: [AboutResource]
    ) {
        self.applicationName = applicationName
        self.tagline = tagline
        self.description = description
        self.versionText = versionText
        self.creatorText = creatorText
        self.copyrightText = copyrightText
        self.resourcesTitle = resourcesTitle
        self.resources = resources
    }
}

public struct AboutPage<Icon: View>: View {
    private let configuration: AboutPageConfiguration
    private let icon: Icon

    public init(
        configuration: AboutPageConfiguration,
        @ViewBuilder icon: () -> Icon
    ) {
        self.configuration = configuration
        self.icon = icon()
    }

    public var body: some View {
        let accessibility = accessibilityPresentation
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.value6) {
                VStack(alignment: .leading, spacing: DesignTokens.Space.value3) {
                    icon
                        .accessibilityHidden(true)
                    Text(configuration.applicationName)
                        .font(
                            .system(
                                size: DesignTokens.Typography.screenTitle.size,
                                weight: DesignTokens.Typography.screenTitle.swiftUIWeight
                            )
                        )
                        .foregroundStyle(Color(designToken: DesignTokens.Color.textPrimary))
                        .accessibilityAddTraits(.isHeader)
                    Text(configuration.tagline)
                        .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
                    Text(configuration.description)
                        .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(configuration.versionText)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color(designToken: DesignTokens.Color.textTertiary))
                    Text(configuration.creatorText)
                        .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
                    Text(configuration.copyrightText)
                        .foregroundStyle(Color(designToken: DesignTokens.Color.textTertiary))
                }
                VStack(alignment: .leading, spacing: DesignTokens.Space.value3) {
                    Text(configuration.resourcesTitle)
                        .font(
                            .system(
                                size: DesignTokens.Typography.sectionTitle.size,
                                weight: DesignTokens.Typography.sectionTitle.swiftUIWeight
                            )
                        )
                        .foregroundStyle(Color(designToken: DesignTokens.Color.textPrimary))
                        .accessibilityAddTraits(.isHeader)
                    ForEach(configuration.resources) { resource in
                        AboutResourceRow(resource: resource)
                    }
                }
            }
            .padding(DesignTokens.Space.value6)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibility.applicationName)
        .accessibilityValue(accessibility.value)
    }

    public var accessibilityPresentation: AboutPageAccessibilityPresentation {
        AboutPageAccessibilityPresentation(configuration: configuration)
    }
}

public struct AboutPageAccessibilityPresentation: Equatable, Sendable {
    public let applicationName: String
    public let versionText: String
    public let creatorText: String
    public let resources: [AboutResourceAccessibilityPresentation]

    public init(configuration: AboutPageConfiguration) {
        applicationName = configuration.applicationName
        versionText = configuration.versionText
        creatorText = configuration.creatorText
        resources = configuration.resources.map(AboutResourceAccessibilityPresentation.init)
    }

    public var value: String {
        ([versionText, creatorText] + resources.flatMap { [$0.title, $0.destination] })
            .joined(separator: "\n")
    }
}

public struct AboutResourceAccessibilityPresentation: Equatable, Sendable {
    public let title: String
    public let destination: String

    public init(resource: AboutResource) {
        title = resource.title
        destination = resource.destination.absoluteString
    }
}
#endif
