#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public struct GroupContainer: ViewModifier {
    private let appearance: DesignAppearance

    public init(appearance: DesignAppearance) {
        self.appearance = appearance
    }

    public func body(content: Content) -> some View {
        content
            .padding(DesignTokens.Component.groupPadding.points)
            .background(
                Color(designToken: DesignTokens.Color.surfaceSecondary, appearance: appearance)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: DesignTokens.Radius.group,
                    style: .continuous
                )
            )
    }
}

public extension View {
    func designGroupContainer(appearance: DesignAppearance) -> some View {
        modifier(GroupContainer(appearance: appearance))
    }
}
#endif
