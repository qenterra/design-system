#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public struct CardContainer<Content: View>: View {
    @Environment(\.designNativeEnvironment) private var nativeEnvironment

    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(DesignTokens.Component.groupPadding.points)
            .background(Color(designToken: DesignTokens.Color.surfaceRaised))
            .clipShape(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.group, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.group, style: .continuous)
                    .stroke(
                        Color(designToken: DesignTokens.Color.borderDefault),
                        lineWidth: isIncreasedContrast ? DesignTokens.Stroke.default : DesignTokens.Stroke.hairline
                    )
            }
    }

    private var isIncreasedContrast: Bool {
        nativeEnvironment.isIncreasedContrast
    }
}
#endif
