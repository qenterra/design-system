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

public struct PageHeaderPresentation: Equatable, Sendable {
    public enum TitleStyle: Equatable, Sendable {
        case sectionTitle
        case largeTitleBold
    }

    public enum Alignment: Equatable, Sendable {
        case firstTextBaseline
        case bottom
    }

    public let titleStyle: TitleStyle
    public let alignment: Alignment

    public static let standard = Self(titleStyle: .sectionTitle, alignment: .firstTextBaseline)
    public static let cadence = Self(titleStyle: .largeTitleBold, alignment: .bottom)

    public init(titleStyle: TitleStyle, alignment: Alignment) {
        self.titleStyle = titleStyle
        self.alignment = alignment
    }
}

public struct PageHeader<Actions: View>: View {
    @Environment(\.designNativeEnvironment) private var nativeEnvironment

    private let title: String
    private let subtitle: String?
    private let presentation: PageHeaderPresentation
    private let actions: Actions

    public init(
        _ title: String,
        subtitle: String? = nil,
        presentation: PageHeaderPresentation = .standard,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = title
        self.subtitle = subtitle
        self.presentation = presentation
        self.actions = actions()
    }

    public var body: some View {
        HStack(
            alignment: presentation.alignment == .bottom ? .bottom : .firstTextBaseline,
            spacing: presentation == .cadence ? metrics.panelInset : metrics.contentGap
        ) {
            VStack(alignment: .leading, spacing: metrics.textStack) {
                Text(title)
                    .font(
                        presentation.titleStyle == .largeTitleBold
                            ? .largeTitle.bold()
                            : .title2.weight(.semibold)
                    )
                    .foregroundStyle(titleForegroundStyle)
                if let subtitle {
                    Text(subtitle)
                        .font(presentation == .cadence ? .callout : .subheadline)
                        .foregroundStyle(subtitleForegroundStyle)
                }
            }
            Spacer(minLength: presentation == .cadence ? metrics.pageInset : metrics.contentGap)
            actions
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    private var metrics: DesignComponentMetrics {
        DesignComponentMetrics.resolve(for: nativeEnvironment)
    }

    private var titleForegroundStyle: AnyShapeStyle {
        presentation == .cadence
            ? AnyShapeStyle(.primary)
            : AnyShapeStyle(Color(designToken: DesignTokens.Color.textPrimary))
    }

    private var subtitleForegroundStyle: AnyShapeStyle {
        presentation == .cadence
            ? AnyShapeStyle(.secondary)
            : AnyShapeStyle(Color(designToken: DesignTokens.Color.textSecondary))
    }
}

public extension PageHeader where Actions == EmptyView {
    init(
        _ title: String,
        subtitle: String? = nil,
        presentation: PageHeaderPresentation = .standard
    ) {
        self.init(title, subtitle: subtitle, presentation: presentation) {
            EmptyView()
        }
    }
}
#endif
