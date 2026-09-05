#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public struct SettingsRow<Control: View>: View {
    @Environment(\.designNativeEnvironment) private var nativeEnvironment

    private let title: LocalizedStringKey
    private let description: LocalizedStringKey?
    private let control: Control

    public init(
        _ title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        @ViewBuilder control: () -> Control
    ) {
        self.title = title
        self.description = description
        self.control = control()
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Component.interactiveRowGap.points) {
            VStack(alignment: .leading, spacing: textStack) {
                Text(title)
                    .font(
                        .system(
                            size: DesignTokens.Typography.rowEmphasized.size,
                            weight: DesignTokens.Typography.rowEmphasized.swiftUIWeight
                        )
                    )
                    .foregroundStyle(Color(designToken: DesignTokens.Color.textPrimary))
                if let description {
                    Text(description)
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
            Spacer(minLength: DesignTokens.Component.interactiveRowGap.points)
            control
        }
        .frame(minHeight: rowHeight)
        .accessibilityElement(children: .combine)
    }

    private var textStack: Double {
        nativeEnvironment.productProfile == .cadence
            ? DesignProductMetrics.cadence.textStack
            : DesignTokens.Space.value1
    }

    private var rowHeight: Double {
        if nativeEnvironment.productProfile == .cadence {
            return DesignProductMetrics.cadence.rowHeight
        }
        switch nativeEnvironment.density {
        case .compact: return DesignTokens.Size.rowCompact
        case .standard: return DesignTokens.Size.rowStandard
        case .comfortable: return DesignTokens.Size.rowComfortable
        }
    }
}
#endif
