#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public enum DesignSeparatorOrientation: Sendable {
    case horizontal
    case vertical
}

public struct DesignSeparator: View {
    private let orientation: DesignSeparatorOrientation

    public init(orientation: DesignSeparatorOrientation = .horizontal) {
        self.orientation = orientation
    }

    public var body: some View {
        Rectangle()
            .fill(Color(designToken: DesignTokens.Color.borderSubtle))
            .frame(
                maxWidth: orientation == .horizontal ? .infinity : nil,
                maxHeight: orientation == .vertical ? .infinity : nil
            )
            .frame(
                width: orientation == .vertical ? DesignTokens.Stroke.hairline : nil,
                height: orientation == .horizontal ? DesignTokens.Stroke.hairline : nil
            )
            .accessibilityHidden(true)
    }
}
#endif
