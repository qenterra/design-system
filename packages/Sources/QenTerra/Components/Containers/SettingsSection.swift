#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public struct SettingsSectionPresentation: Equatable, Sendable {
    public let cardInset: Double
    public let contentSpacing: Double
    public let integratesHeader: Bool

    public static let standard = Self(
        cardInset: DesignTokens.Component.groupPadding.points,
        contentSpacing: DesignTokens.Space.value1,
        integratesHeader: false
    )
    public static let cadence = Self(
        cardInset: DesignProductMetrics.cadence.contentGap,
        contentSpacing: DesignProductMetrics.cadence.controlGap,
        integratesHeader: true
    )

    public init(cardInset: Double, contentSpacing: Double, integratesHeader: Bool) {
        self.cardInset = cardInset
        self.contentSpacing = contentSpacing
        self.integratesHeader = integratesHeader
    }
}

public struct SettingsSection<Content: View>: View {
    @Environment(\.designNativeEnvironment) private var nativeEnvironment

    private let title: LocalizedStringKey
    private let symbol: String?
    private let presentation: SettingsSectionPresentation
    private let content: Content

    public init(
        _ title: LocalizedStringKey,
        symbol: String? = nil,
        presentation: SettingsSectionPresentation = .standard,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.symbol = symbol
        self.presentation = presentation
        self.content = content()
    }

    @ViewBuilder
    public var body: some View {
        if presentation.integratesHeader {
            VStack(alignment: .leading, spacing: presentation.contentSpacing) {
                header
                content
            }
            .padding(presentation.cardInset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(designToken: DesignTokens.Color.surfaceSecondary))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.group))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.group)
                    .strokeBorder(
                        Color(designToken: DesignTokens.Color.borderDefault),
                        lineWidth: DesignTokens.Stroke.hairline
                    )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(title)
        } else {
            VStack(alignment: .leading, spacing: sectionSpacing) {
                header
                CardContainer {
                    VStack(alignment: .leading, spacing: rowSpacing) {
                        content
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(title)
        }
    }

    @ViewBuilder
    private var header: some View {
        if let symbol {
            Label(title, systemImage: symbol)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
        } else {
            Text(title)
                .font(
                    .system(
                        size: DesignTokens.Typography.sectionTitle.size,
                        weight: DesignTokens.Typography.sectionTitle.swiftUIWeight
                    )
                )
                .foregroundStyle(Color(designToken: DesignTokens.Color.textPrimary))
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var sectionSpacing: Double {
        nativeEnvironment.productProfile == .cadence
            ? DesignProductMetrics.cadence.controlGap
            : DesignTokens.Space.value4
    }

    private var rowSpacing: Double {
        nativeEnvironment.productProfile == .cadence
            ? DesignProductMetrics.cadence.textStack
            : DesignTokens.Space.value1
    }
}
#endif
