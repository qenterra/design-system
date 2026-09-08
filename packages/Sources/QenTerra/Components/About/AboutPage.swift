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

public struct AboutPagePresentation: Equatable, Sendable {
    public let scrollOwnership: PageScrollOwnership
    public let iconSize: Double
    public let resourceRowHeight: Double
    public let usesCompactProductHero: Bool

    public static let standard = Self(
        scrollOwnership: .component,
        iconSize: 0,
        resourceRowHeight: 0,
        usesCompactProductHero: false
    )
    public static let cadenceSettings = Self(
        scrollOwnership: .consumer,
        iconSize: 72,
        resourceRowHeight: 54,
        usesCompactProductHero: true
    )

    public init(
        scrollOwnership: PageScrollOwnership,
        iconSize: Double,
        resourceRowHeight: Double,
        usesCompactProductHero: Bool
    ) {
        self.scrollOwnership = scrollOwnership
        self.iconSize = iconSize
        self.resourceRowHeight = resourceRowHeight
        self.usesCompactProductHero = usesCompactProductHero
    }
}

public struct AboutPage<Icon: View>: View {
    private let configuration: AboutPageConfiguration
    private let icon: Icon
    private let presentation: AboutPagePresentation

    public init(
        configuration: AboutPageConfiguration,
        presentation: AboutPagePresentation = .standard,
        @ViewBuilder icon: () -> Icon
    ) {
        self.configuration = configuration
        self.presentation = presentation
        self.icon = icon()
    }

    public var body: some View {
        let accessibility = accessibilityPresentation
        Group {
            if presentation.scrollOwnership == .component {
                ScrollView { pageContent }
            } else {
                pageContent
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibility.applicationName)
        .accessibilityValue(accessibility.value)
    }

    @ViewBuilder
    private var pageContent: some View {
        if presentation.usesCompactProductHero {
            VStack(spacing: DesignProductMetrics.cadence.contentGap) {
                compactHero
                SettingsSection(
                    LocalizedStringKey(configuration.resourcesTitle),
                    symbol: "link",
                    presentation: .cadence
                ) {
                    VStack(spacing: 0) {
                        ForEach(Array(configuration.resources.enumerated()), id: \.element.id) { index, resource in
                            AboutResourceRow(resource: resource, style: .cadence)
                            if index < configuration.resources.count - 1 {
                                DesignSeparator()
                                    .padding(.leading, 38)
                            }
                        }
                    }
                }
            }
        } else {
            VStack(alignment: .leading, spacing: DesignTokens.Space.value6) {
                standardHero
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
    }

    private var standardHero: some View {
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
    }

    private var compactHero: some View {
        VStack(alignment: .leading, spacing: DesignProductMetrics.cadence.contentGap) {
            HStack(spacing: DesignProductMetrics.cadence.contentGap) {
                icon
                    .frame(width: presentation.iconSize, height: presentation.iconSize)
                    .clipShape(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.panel, style: .continuous)
                    )
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: DesignProductMetrics.cadence.textStack) {
                    Text(configuration.applicationName)
                        .font(.title2.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
                    Text(configuration.versionText)
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
                    Text(configuration.tagline)
                        .font(.callout)
                        .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
                }
                Spacer(minLength: 0)
            }
            Text(configuration.description)
                .font(.callout)
                .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
                .fixedSize(horizontal: false, vertical: true)
            DesignSeparator()
            HStack {
                Label(configuration.creatorText, systemImage: "person.crop.circle")
                    .font(.caption)
                    .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
                Spacer()
                Text(configuration.copyrightText)
                    .font(.caption)
                    .foregroundStyle(Color(designToken: DesignTokens.Color.textTertiary))
            }
        }
        .padding(DesignProductMetrics.cadence.contentGap)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(designToken: DesignTokens.Color.surfaceSecondary))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.panel, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.panel, style: .continuous)
                .strokeBorder(Color(designToken: DesignTokens.Color.borderDefault), lineWidth: DesignTokens.Stroke.hairline)
        }
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
