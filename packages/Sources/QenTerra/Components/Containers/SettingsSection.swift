#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public struct SettingsSection<Content: View>: View {
    @Environment(\.designNativeEnvironment) private var nativeEnvironment

    private let title: LocalizedStringKey
    private let content: Content

    public init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            Text(title)
                .font(
                    .system(
                        size: DesignTokens.Typography.sectionTitle.size,
                        weight: DesignTokens.Typography.sectionTitle.swiftUIWeight
                    )
                )
                .foregroundStyle(Color(designToken: DesignTokens.Color.textPrimary))
                .accessibilityAddTraits(.isHeader)
            CardContainer {
                VStack(alignment: .leading, spacing: rowSpacing) {
                    content
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
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
