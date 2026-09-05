#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public struct GroupContainer: ViewModifier {
    private let appearanceOverride: DesignAppearance?

    public init() {
        appearanceOverride = nil
    }

    @available(*, deprecated, message: "Use GroupContainer() with View.designSystem(_:) instead.")
    public init(appearance: DesignAppearance) {
        appearanceOverride = appearance
    }

    public func body(content: Content) -> some View {
        content
            .padding(DesignTokens.Component.groupPadding.points)
            .background(
                color(DesignTokens.Color.surfaceSecondary)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: DesignTokens.Radius.group,
                    style: .continuous
                )
            )
    }

    private func color(_ token: DesignColorValue) -> Color {
        if let appearanceOverride {
            return Color(designToken: token, appearance: appearanceOverride)
        }
        return Color(designToken: token)
    }
}

public extension View {
    func designGroupContainer() -> some View {
        modifier(GroupContainer())
    }

    @available(*, deprecated, message: "Use designGroupContainer() with View.designSystem(_:) instead.")
    func designGroupContainer(appearance: DesignAppearance) -> some View {
        modifier(GroupContainer(appearance: appearance))
    }
}
#endif
