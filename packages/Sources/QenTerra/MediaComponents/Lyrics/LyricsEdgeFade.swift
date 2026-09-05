#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

public struct LyricsEdgeFade: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: DesignTokens.Component.panelLyricsEdgeFadeHeight.points)
            Spacer(minLength: 0)
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                .frame(height: DesignTokens.Component.panelLyricsEdgeFadeHeight.points)
        }
        .blendMode(.destinationOut)
        .compositingGroup()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
#endif
