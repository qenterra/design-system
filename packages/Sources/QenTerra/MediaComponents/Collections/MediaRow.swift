#if os(macOS)
import QenTerraComponents
import QenTerraDesignTokens
import SwiftUI

public struct MediaRow<ID: Hashable & Sendable, Artwork: View, TrailingAccessory: View>: View {
    @FocusState private var isFocused: Bool
    @State private var isHovered = false

    private let item: MediaItemPresentation<ID>
    private let accessibilityLabel: String
    private let accessibilityValue: String?
    private let artwork: Artwork
    private let trailingAccessory: TrailingAccessory
    private let action: @MainActor () -> Void

    public init(
        item: MediaItemPresentation<ID>,
        accessibilityLabel: String,
        accessibilityValue: String? = nil,
        @ViewBuilder artwork: () -> Artwork,
        @ViewBuilder trailingAccessory: () -> TrailingAccessory,
        action: @escaping @MainActor () -> Void
    ) {
        self.item = item
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityValue = accessibilityValue
        self.artwork = artwork()
        self.trailingAccessory = trailingAccessory()
        self.action = action
    }

    public var body: some View {
        InteractiveRowSurface(
            state: InteractiveRowState(
                isHovered: isHovered,
                isFocused: isFocused,
                isSelected: item.isSelected,
                isDisabled: !item.isAvailable
            )
        ) {
            HStack(spacing: rowGap) {
                primaryButton
                trailingAccessory
            }
            .padding(.horizontal, DesignTokens.Component.interactiveRowPaddingX.points)
            .frame(minHeight: rowHeight)
        }
        .onHover { isHovered = $0 }
    }

    private var primaryButton: some View {
        Button {
            MediaActivation(action: action).perform(
                from: .primaryContent,
                isAvailable: item.isAvailable
            )
        } label: {
            HStack(spacing: rowGap) {
                artwork
                    .frame(width: artworkSide, height: artworkSide)
                    .overlay { MediaRowPlaybackOverlay(item: item) }

                VStack(alignment: .leading, spacing: DesignProductMetrics.cadence.textStack) {
                    Text(verbatim: item.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(verbatim: item.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                if let metadata = item.metadata {
                    Text(verbatim: metadata)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                        .lineLimit(1)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(MediaActivationButtonStyle())
        .focused($isFocused)
        .disabled(!item.isAvailable)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: accessibilityLabel))
        .modifier(OptionalAccessibilityValue(value: accessibilityValue))
    }

    private var rowGap: CGFloat {
        CGFloat(DesignTokens.Component.panelMediaCollectionRowGap.points)
    }

    private var rowHeight: CGFloat {
        CGFloat(DesignTokens.Component.panelMediaCollectionRowHeight.points)
    }

    private var artworkSide: CGFloat {
        CGFloat(DesignTokens.Component.panelMediaCollectionRowArtworkSide.points)
    }
}

private struct MediaRowPlaybackOverlay<ID: Hashable & Sendable>: View {
    let item: MediaItemPresentation<ID>

    var body: some View {
        let presentation = MediaItemVisualPresentation(item)
        if presentation.isCurrent {
            ZStack {
                RoundedRectangle(
                    cornerRadius: DesignTokens.Radius.control,
                    style: .continuous
                )
                .fill(
                    .black.opacity(
                        DesignTokens.Component.panelMediaCollectionPlaybackIndicatorScrimOpacity.value
                    )
                )
                if presentation.showsPlaybackIndicator {
                    PlaybackIndicator(isPlaying: true)
                } else if presentation.showsPausedCurrentAffordance {
                    Image(systemName: "play.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            .accessibilityHidden(true)
            .allowsHitTesting(false)
        }
    }
}
#endif
