#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

/// A metadata action whose destination and accessible label belong to the caller.
public struct MediaMetadataLink: View {
    private let title: String
    private let accessibilityLabel: String
    private let freezesInteractionHighlights: Bool
    private let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isFocused: Bool
    @State private var isHovered = false

    public init(
        _ title: String,
        accessibilityLabel: String,
        freezesInteractionHighlights: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.accessibilityLabel = accessibilityLabel
        self.freezesInteractionHighlights = freezesInteractionHighlights
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(isHighlighted ? Color.primary : Color.secondary)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .onHover { isHovered = $0 }
        .animation(
            reduceMotion
                ? nil
                : .easeOut(duration: DesignTokens.Motion.feedbackHover.seconds),
            value: isHighlighted
        )
        .accessibilityLabel(accessibilityLabel)
        .help(accessibilityLabel)
    }

    private var isHighlighted: Bool {
        !freezesInteractionHighlights && (isHovered || isFocused)
    }
}
#endif
