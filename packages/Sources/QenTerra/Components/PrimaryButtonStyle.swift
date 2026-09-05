#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public struct PrimaryButtonStyle: ButtonStyle {
    private let style: DesignButtonStyle

    public init(state: DesignButtonState = .init()) {
        style = DesignButtonStyle(role: .primary, state: state)
    }

    @available(*, deprecated, message: "Use PrimaryButtonStyle() with View.designSystem(_:) instead.")
    public init(appearance: DesignAppearance) {
        style = DesignButtonStyle(role: .primary, appearanceOverride: appearance)
    }

    public func makeBody(configuration: Configuration) -> some View {
        style.makeBody(configuration: configuration)
    }
}
#endif
