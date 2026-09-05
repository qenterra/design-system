#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

enum QueueVisualMetrics {
    static var dragPreviewGap: CGFloat {
        DesignTokens.Component.panelQueueDragPreviewGap.points
    }

    static var dragPreviewArtworkSide: CGFloat {
        DesignTokens.Component.panelQueueDragPreviewArtworkSide.points
    }

    static var dragPreviewTextGap: CGFloat {
        DesignTokens.Component.panelQueueDragPreviewTextGap.points
    }

    static var insertionOpacity: Double {
        DesignTokens.Component.panelQueueInsertionOpacity.value
    }

    static var insertionYOffset: CGFloat {
        DesignTokens.Component.panelQueueInsertionYOffset.points
    }
}

public struct QueueDragPreview<Artwork: View>: View {
    private let title: String
    private let subtitle: String
    private let artwork: Artwork

    public init(
        title: String,
        subtitle: String,
        @ViewBuilder artwork: () -> Artwork
    ) {
        self.title = title
        self.subtitle = subtitle
        self.artwork = artwork()
    }

    public var body: some View {
        HStack(spacing: QueueVisualMetrics.dragPreviewGap) {
            artwork
                .frame(
                    width: QueueVisualMetrics.dragPreviewArtworkSide,
                    height: QueueVisualMetrics.dragPreviewArtworkSide
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: DesignTokens.Radius.control,
                        style: .continuous
                    )
                )
            VStack(alignment: .leading, spacing: QueueVisualMetrics.dragPreviewTextGap) {
                Text(verbatim: title)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                Text(verbatim: subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(DesignTokens.Component.panelQueueDragPreviewPadding.points)
        .frame(width: DesignTokens.Component.panelQueueDragPreviewWidth.points, alignment: .leading)
        .background(Color(designToken: DesignTokens.Color.surfaceOverlay))
        .clipShape(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.group, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.group, style: .continuous)
                .strokeBorder(
                    Color.primary.opacity(
                        DesignTokens.Component.panelQueueDragPreviewBorderOpacity.value
                    )
                )
        }
        .shadow(
            color: .black.opacity(
                DesignTokens.Component.panelQueueDragPreviewShadowOpacity.value
            ),
            radius: DesignTokens.Component.panelQueueDragPreviewShadowRadius.points,
            y: DesignTokens.Component.panelQueueDragPreviewShadowYOffset.points
        )
        .accessibilityElement(children: .combine)
    }
}
#endif
