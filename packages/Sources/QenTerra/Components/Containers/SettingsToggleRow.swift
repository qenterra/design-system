#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public struct SettingsTogglePresentation: Equatable, Sendable {
    public enum ControlSize: Equatable, Sendable {
        case inherited
        case small
    }

    public enum ControlAlignment: Equatable, Sendable {
        case native
        case trailing
    }

    public let controlSize: ControlSize
    public let controlAlignment: ControlAlignment

    public static let standard = Self(controlSize: .inherited, controlAlignment: .native)
    public static let cadence = Self(controlSize: .small, controlAlignment: .trailing)

    public init(controlSize: ControlSize, controlAlignment: ControlAlignment) {
        self.controlSize = controlSize
        self.controlAlignment = controlAlignment
    }
}

public struct SettingsToggleRow: View {
    @Environment(\.designNativeEnvironment) private var nativeEnvironment

    private let title: LocalizedStringKey
    private let isOn: Binding<Bool>
    private let presentation: SettingsTogglePresentation

    public init(
        _ title: LocalizedStringKey,
        isOn: Binding<Bool>,
        presentation: SettingsTogglePresentation = .standard
    ) {
        self.title = title
        self.isOn = isOn
        self.presentation = presentation
    }

    @ViewBuilder
    public var body: some View {
        if presentation.controlAlignment == .trailing {
            HStack(spacing: metrics.controlGap) {
                Text(title)
                    .accessibilityHidden(true)
                Spacer(minLength: metrics.contentGap)
                Toggle(title, isOn: isOn)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
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

    private var metrics: DesignComponentMetrics {
        DesignComponentMetrics.resolve(for: nativeEnvironment)
    }
}
#endif
