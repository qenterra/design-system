#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

public struct QueueInsertionIndicator: View {
    public init() {}

    public var body: some View {
        Capsule()
            .fill(Color.primary.opacity(0.9))
            .frame(height: DesignTokens.Component.panelQueueInsertionHeight.points)
            .padding(.horizontal, DesignTokens.Component.panelQueueInsertionHorizontalInset.points)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
#endif
