#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public struct IconActionButton: View {
    private let icon: DesignIcon
    private let accessibilityLabel: LocalizedStringKey
    private let help: LocalizedStringKey?
    private let isEnabled: Bool
    private let action: () -> Void
    private let state: DesignButtonState

    public init(
        designIcon: DesignIcon,
        accessibilityLabel: LocalizedStringKey,
        help: LocalizedStringKey? = nil,
        isEnabled: Bool = true,
        state: DesignButtonState = .init(),
        action: @escaping () -> Void
    ) {
        icon = designIcon
        self.accessibilityLabel = accessibilityLabel
        self.help = help
        self.isEnabled = isEnabled
        self.state = state
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(designIcon: icon)
                .frame(
                    width: DesignTokens.Size.iconM,
                    height: DesignTokens.Size.iconM
                )
        }
        .buttonStyle(DesignButtonStyle(role: .icon, state: state))
        .disabled(!isEnabled)
        .accessibilityLabel(accessibilityLabel)
        .help(Text(help ?? accessibilityLabel))
    }
}
#endif
