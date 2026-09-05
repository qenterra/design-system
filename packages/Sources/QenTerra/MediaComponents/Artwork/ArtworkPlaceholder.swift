#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

public enum ArtworkPlaceholderKind: Equatable, Sendable {
    case artist, album, track, playlist, collection

    public var symbolName: String {
        switch self {
        case .artist: "person.fill"
        case .album: "square.stack.fill"
        case .track: "music.note"
        case .playlist: "music.note.list"
        case .collection: "sparkles.rectangle.stack"
        }
    }

    public func padding(in size: CGSize) -> CGFloat {
        let ratio: Double = switch self {
        case .artist: DesignTokens.Component.panelArtworkArtistPaddingRatio.value
        case .track: DesignTokens.Component.panelArtworkTrackPaddingRatio.value
        case .album, .playlist, .collection: DesignTokens.Component.panelArtworkCollectionPaddingRatio.value
        }
        return max(0, min(size.width, size.height)) * ratio
    }

    public func horizontalOffset(in size: CGSize) -> CGFloat {
        self == .artist
            ? max(0, min(size.width, size.height))
            * DesignTokens.Component.panelArtworkArtistOffsetRatio.value
            : 0
    }
}

struct ArtworkPlaceholderGeometry {
    let highlightSize: CGSize
    let highlightOffset: CGSize
    let blurRadius: CGFloat
    let symbolSize: CGFloat

    init(size: CGSize) {
        let metrics = DesignTokens.Component.self
        highlightSize = CGSize(
            width: size.width * metrics.panelArtworkHighlightSizeRatio.value,
            height: size.height * metrics.panelArtworkHighlightSizeRatio.value
        )
        highlightOffset = CGSize(
            width: size.width * metrics.panelArtworkHighlightOffsetXRatio.value,
            height: size.height * metrics.panelArtworkHighlightOffsetYRatio.value
        )
        blurRadius = size.width * metrics.panelArtworkHighlightBlurRatio.value
        symbolSize = min(
            max(
                size.width * metrics.panelArtworkSymbolSizeRatio.value,
                metrics.panelArtworkSymbolMinimumSize.points
            ),
            metrics.panelArtworkSymbolMaximumSize.points
        )
    }
}

/// Decorative placeholder; its enclosing artwork surface supplies the accessible title.
public struct ArtworkPlaceholder: View {
    @Environment(\.designNativeEnvironment) private var environment
    private let kind: ArtworkPlaceholderKind?
    private let palette: ArtworkPalette?

    public init(kind: ArtworkPlaceholderKind) {
        self.kind = kind
        palette = nil
    }

    public init(palette: ArtworkPalette) {
        kind = nil
        self.palette = palette
    }

    public var body: some View {
        GeometryReader { geometry in
            if let palette {
                synthetic(palette, size: geometry.size)
            } else if let kind {
                ZStack {
                    Color(designToken: DesignTokens.Color.surfaceSecondary, appearance: environment.appearance)
                    Image(systemName: kind.symbolName)
                        .resizable().scaledToFit().symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                        .padding(kind.padding(in: geometry.size))
                        .offset(x: kind.horizontalOffset(in: geometry.size))
                }
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }

    private func synthetic(_ palette: ArtworkPalette, size: CGSize) -> some View {
        let geometry = ArtworkPlaceholderGeometry(size: size)
        return ZStack {
            LinearGradient(
                colors: [palette.leading, palette.trailing],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            if !environment.reducesTransparency {
                Circle()
                    .fill(
                        palette.highlight.opacity(
                            DesignTokens.Component.panelArtworkHighlightOpacity.value
                        )
                    )
                    .frame(width: geometry.highlightSize.width, height: geometry.highlightSize.height)
                    .blur(radius: geometry.blurRadius)
                    .offset(x: geometry.highlightOffset.width, y: geometry.highlightOffset.height)
            }
            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(DesignTokens.Component.panelArtworkScrimOpacity.value),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            Image(systemName: palette.symbolName)
                .font(.system(size: geometry.symbolSize, weight: .ultraLight))
                .foregroundStyle(
                    .white.opacity(
                        environment.isIncreasedContrast
                            ? 1
                            : DesignTokens.Component.panelArtworkSymbolOpacity.value
                    )
                )
                .symbolRenderingMode(.hierarchical)
        }
    }
}
#endif
