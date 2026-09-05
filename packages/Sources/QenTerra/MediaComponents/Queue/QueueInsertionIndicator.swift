#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

public struct QueueInsertionIndicator: View {
    public init() {}

    public var body: some View {
        Capsule()
            .fill(Color.primary.opacity(QueueVisualMetrics.insertionOpacity))
            .frame(height: DesignTokens.Component.panelQueueInsertionHeight.points)
            .padding(.horizontal, DesignTokens.Component.panelQueueInsertionHorizontalInset.points)
            .offset(y: QueueVisualMetrics.insertionYOffset)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
#endif
