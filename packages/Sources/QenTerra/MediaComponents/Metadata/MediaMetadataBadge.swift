#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

public struct MediaMetadataBadge: View {
    private let label: String
    private let symbolName: String?
    private let accessibilityLabel: String

    public init(
        label: String,
        symbolName: String? = nil,
        accessibilityLabel: String? = nil
    ) {
        self.label = label
        self.symbolName = symbolName
        self.accessibilityLabel = accessibilityLabel ?? label
    }

    public var body: some View {
        Group {
            if let symbolName {
                Label(label, systemImage: symbolName)
            } else {
                Text(verbatim: label)
            }
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, DesignTokens.Component.panelMetadataBadgeHorizontalPadding.points)
        .frame(height: DesignTokens.Component.panelMetadataBadgeHeight.points)
        .background(
            Color(designToken: DesignTokens.Color.fillHover),
            in: Capsule()
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: accessibilityLabel))
    }
}
#endif
