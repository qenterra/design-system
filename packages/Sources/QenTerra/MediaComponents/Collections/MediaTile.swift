#if os(macOS)
import QenTerraComponents
import QenTerraDesignTokens
import SwiftUI

public struct MediaTile<ID: Hashable & Sendable, Artwork: View, TrailingAccessory: View>: View {
    @FocusState private var isFocused: Bool
    @State private var isHovered = false

    private let item: MediaItemPresentation<ID>
    private let accessibilityLabel: String
    private let accessibilityValue: String?
    private let artwork: Artwork
    private let trailingAccessory: (MediaAccessoryInteractionContext) -> TrailingAccessory
    private let action: @MainActor () -> Void

    public init(
        item: MediaItemPresentation<ID>,
        accessibilityLabel: String,
        accessibilityValue: String? = nil,
        @ViewBuilder artwork: () -> Artwork,
        @ViewBuilder trailingAccessory: @escaping (MediaAccessoryInteractionContext) -> TrailingAccessory,
        action: @escaping @MainActor () -> Void
    ) {
        self.item = item
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityValue = accessibilityValue
        self.artwork = artwork()
        self.trailingAccessory = trailingAccessory
        self.action = action
    }

    public init(
        item: MediaItemPresentation<ID>,
        accessibilityLabel: String,
        accessibilityValue: String? = nil,
        @ViewBuilder artwork: () -> Artwork,
        @ViewBuilder trailingAccessory: @escaping () -> TrailingAccessory,
        action: @escaping @MainActor () -> Void
    ) {
        self.init(
            item: item,
            accessibilityLabel: accessibilityLabel,
            accessibilityValue: accessibilityValue,
            artwork: artwork,
            trailingAccessory: { _ in trailingAccessory() },
            action: action
        )
    }

    public var body: some View {
        InteractiveRowSurface(
            state: InteractiveRowState(
                isHovered: isHovered,
                isFocused: isFocused,
                isSelected: item.isSelected,
                isDisabled: !item.isAvailable
            ),
            cornerRadius: .group
        ) {
            ZStack(alignment: .topTrailing) {
                primaryButton
                trailingAccessory(accessoryInteractionContext)
            }
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
            VStack(alignment: .leading, spacing: tilePadding) {
                artwork
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .overlay { MediaArtworkPlaybackOverlay(item: item) }

                HStack(alignment: .top, spacing: tilePadding) {
                    VStack(alignment: .leading, spacing: tileTextGap) {
                        Text(verbatim: item.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        Text(verbatim: item.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        if let metadata = item.metadata {
                            Text(verbatim: metadata)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: tileTextGap)
                }
            }
            .padding(tilePadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(MediaActivationButtonStyle())
        .focused($isFocused)
        .disabled(!item.isAvailable)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: accessibilityLabel))
        .modifier(OptionalAccessibilityValue(value: accessibilityValue))
    }

    private var tilePadding: CGFloat {
        CGFloat(DesignTokens.Component.panelMediaCollectionTilePadding.points)
    }

    private var tileTextGap: CGFloat {
        CGFloat(DesignTokens.Component.panelMediaCollectionTileTextGap.points)
    }

    private var accessoryInteractionContext: MediaAccessoryInteractionContext {
        MediaAccessoryInteractionContext(
            isContainerHovered: isHovered,
            isContainerFocused: isFocused
        )
    }
}

struct MediaActivationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(
            configuration.isPressed
                ? DesignTokens.Component.panelMediaCollectionPressedOpacity.value
                : 1
        )
    }
}

struct OptionalAccessibilityValue: ViewModifier {
    let value: String?

    func body(content: Content) -> some View {
        if let value {
            content.accessibilityValue(Text(verbatim: value))
        } else {
            content
        }
    }
}

private struct MediaArtworkPlaybackOverlay<ID: Hashable & Sendable>: View {
    let item: MediaItemPresentation<ID>

    var body: some View {
        let presentation = MediaItemVisualPresentation(item)
        if presentation.isCurrent {
            ZStack {
                RoundedRectangle(
                    cornerRadius: DesignTokens.Radius.group,
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
