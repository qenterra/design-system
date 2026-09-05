#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public struct DesignComponentMetrics: Equatable, Sendable {
    public let textStack: Double
    public let compactGap: Double
    public let controlGap: Double
    public let contentGap: Double
    public let panelInset: Double
    public let pageInset: Double
    public let sectionGap: Double
    public let rowHeight: Double

    public static func resolve(for environment: DesignNativeEnvironment) -> Self {
        if environment.productProfile == .cadence {
            let cadence = DesignProductMetrics.cadence
            return Self(
                textStack: cadence.textStack,
                compactGap: cadence.compactGap,
                controlGap: cadence.controlGap,
                contentGap: cadence.contentGap,
                panelInset: cadence.panelInset,
                pageInset: cadence.pageInset,
                sectionGap: cadence.sectionGap,
                rowHeight: cadence.rowHeight
            )
        }

        switch environment.density {
        case .compact:
            return Self(
                textStack: DesignTokens.Space.value1,
                compactGap: DesignTokens.Space.value1,
                controlGap: DesignTokens.Space.value2,
                contentGap: DesignTokens.Space.value3,
                panelInset: DesignTokens.Space.value3,
                pageInset: DesignTokens.Space.value4,
                sectionGap: DesignTokens.Space.value6,
                rowHeight: DesignTokens.Size.rowCompact
            )
        case .standard:
            return Self(
                textStack: DesignTokens.Space.value1,
                compactGap: DesignTokens.Space.value2,
                controlGap: DesignTokens.Space.value3,
                contentGap: DesignTokens.Space.value4,
                panelInset: DesignTokens.Space.value5,
                pageInset: DesignTokens.Space.value6,
                sectionGap: DesignTokens.Space.value8,
                rowHeight: DesignTokens.Size.rowStandard
            )
        case .comfortable:
            return Self(
                textStack: DesignTokens.Space.value2,
                compactGap: DesignTokens.Space.value3,
                controlGap: DesignTokens.Space.value4,
                contentGap: DesignTokens.Space.value5,
                panelInset: DesignTokens.Space.value6,
                pageInset: DesignTokens.Space.value8,
                sectionGap: DesignTokens.Space.value10,
                rowHeight: DesignTokens.Size.rowComfortable
            )
        }
    }
}

public struct PageHeader<Actions: View>: View {
    @Environment(\.designNativeEnvironment) private var nativeEnvironment

    private let title: String
    private let subtitle: String?
    private let actions: Actions

    public init(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actions = actions()
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: metrics.contentGap) {
            VStack(alignment: .leading, spacing: metrics.textStack) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color(designToken: DesignTokens.Color.textPrimary))
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
                }
            }
            Spacer(minLength: metrics.contentGap)
            actions
        }
        .accessibilityElement(children: .contain)
    }

    private var metrics: DesignComponentMetrics {
        DesignComponentMetrics.resolve(for: nativeEnvironment)
    }
}

public extension PageHeader where Actions == EmptyView {
    init(_ title: String, subtitle: String? = nil) {
        self.init(title, subtitle: subtitle) {
            EmptyView()
        }
    }
}
#endif
