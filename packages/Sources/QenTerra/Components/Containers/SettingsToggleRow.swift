#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public struct SettingsToggleRow: View {
    @Environment(\.designNativeEnvironment) private var nativeEnvironment

    private let title: LocalizedStringKey
    private let isOn: Binding<Bool>

    public init(_ title: LocalizedStringKey, isOn: Binding<Bool>) {
        self.title = title
        self.isOn = isOn
    }

    public var body: some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(
                    .system(
                        size: DesignTokens.Typography.rowEmphasized.size,
                        weight: DesignTokens.Typography.rowEmphasized.swiftUIWeight
                    )
                )
        }
        .frame(minHeight: rowHeight)
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
