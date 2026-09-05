#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

enum PlayerBarLayoutMetrics {
    static var height: CGFloat { DesignTokens.Component.panelPlayerMinimumHeight.points }
    static var contentHeight: CGFloat { DesignTokens.Component.panelPlayerContentHeight.points }
    static var metadataMinimumWidth: CGFloat { DesignTokens.Component.panelPlayerMetadataMinimumWidth.points }
    static var metadataMaximumWidth: CGFloat { DesignTokens.Component.panelPlayerMetadataMaximumWidth.points }
    static var outputWidth: CGFloat { DesignTokens.Component.panelPlayerOutputWidth.points }
    static var transportMinimumWidth: CGFloat { DesignTokens.Component.panelPlayerTransportMinimumWidth.points }

    static func contentFrame(availableWidth: CGFloat) -> CGRect {
        CGRect(
            x: 0,
            y: (height - contentHeight) / 2 - DesignProductMetrics.cadence.textStack,
            width: max(availableWidth, 0),
            height: contentHeight
        )
    }

    static func metadataWidth(availableWidth: CGFloat) -> CGFloat {
        min(
            max(
                availableWidth
                    - outputWidth
                    - transportMinimumWidth
                    - DesignProductMetrics.cadence.pageInset * 2,
                metadataMinimumWidth
            ),
            metadataMaximumWidth
        )
    }
}

public struct PlayerBar<Artwork: View>: View {
    @Environment(\.designNativeEnvironment) private var environment
    @State private var isArtworkHovered = false
    private let presentation: PlayerBarPresentation
    private let actions: PlayerBarActions
    private let artwork: Artwork

    public init(
        presentation: PlayerBarPresentation,
        actions: PlayerBarActions,
        @ViewBuilder artwork: () -> Artwork
    ) {
        self.presentation = presentation
        self.actions = actions
        self.artwork = artwork()
    }

    public var body: some View {
        GeometryReader { geometry in
            let contentFrame = PlayerBarLayoutMetrics.contentFrame(
                availableWidth: geometry.size.width
            )
            HStack(spacing: DesignProductMetrics.cadence.pageInset) {
                nowPlaying
                    .frame(
                        width: PlayerBarLayoutMetrics.metadataWidth(
                            availableWidth: geometry.size.width
                        ),
                        alignment: .leading
                    )
                    .layoutPriority(2)

                transport
                    .frame(maxWidth: .infinity)
                    .layoutPriority(1)

                outputControls
                    .frame(width: PlayerBarLayoutMetrics.outputWidth, alignment: .trailing)
            }
            .frame(width: contentFrame.width, height: contentFrame.height)
            .position(x: contentFrame.midX, y: contentFrame.midY)
        }
        .padding(.horizontal, DesignProductMetrics.cadence.panelInset)
        .frame(height: PlayerBarLayoutMetrics.height)
        .background(playerBackground)
    }

    @ViewBuilder
    private var nowPlaying: some View {
        if let title = presentation.title {
            HStack(spacing: DesignProductMetrics.cadence.controlGap) {
                Button(action: actions.showNowPlaying) {
                    artwork
                        .frame(
                            width: DesignTokens.Component.panelPlayerArtworkSide.points,
                            height: DesignTokens.Component.panelPlayerArtworkSide.points
                        )
                        .overlay {
                            if isArtworkHovered {
                                RoundedRectangle(
                                    cornerRadius: DesignTokens.Radius.control,
                                    style: .continuous
                                )
                                .fill(
                                    .black.opacity(
                                        DesignTokens.Component.panelPlayerArtworkHoverOpacity.value
                                    )
                                )
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                }
                .buttonStyle(.plain)
                .onHover { isArtworkHovered = $0 }
                .accessibilityLabel(Text(verbatim: nowPlayingAccessibilityLabel(title: title)))
                .help(Text(verbatim: nowPlayingAccessibilityLabel(title: title)))

                VStack(alignment: .leading, spacing: DesignProductMetrics.cadence.textStack) {
                    Text(verbatim: title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    if let subtitle = presentation.subtitle {
                        Text(verbatim: subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        } else if let emptyTitle = presentation.emptyTitle {
            HStack(spacing: DesignProductMetrics.cadence.compactGap) {
                if let symbolName = presentation.emptySymbolName {
                    Image(systemName: symbolName)
                        .accessibilityHidden(true)
                }
                Text(verbatim: emptyTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(verbatim: emptyTitle))
        }
    }

    private var transport: some View {
        HStack(spacing: DesignProductMetrics.cadence.contentGap) {
            HStack(spacing: DesignProductMetrics.cadence.controlGap) {
                TransportControls(presentation: presentation, actions: actions)
                if let favorite = presentation.favorite {
                    FavoriteControl(presentation: favorite, action: actions.setFavorite)
                }
            }

            PlaybackProgressControl(
                presentation: presentation.progress,
                seek: actions.seek
            )
            .frame(
                minWidth: DesignTokens.Component.panelPlayerProgressMinimumWidth.points,
                idealWidth: DesignTokens.Component.panelPlayerProgressIdealWidth.points,
                maxWidth: DesignTokens.Component.panelPlayerProgressMaximumWidth.points
            )
        }
        .frame(minWidth: PlayerBarLayoutMetrics.transportMinimumWidth)
    }

    private var outputControls: some View {
        HStack(spacing: DesignProductMetrics.cadence.controlGap) {
            Button(action: actions.toggleMute) {
                Image(systemName: presentation.isMuted ? "speaker.slash.fill" : volumeSymbol)
                    .frame(
                        width: DesignTokens.Component.panelPlayerVolumeButtonSize.points,
                        height: DesignTokens.Component.panelPlayerVolumeButtonSize.points
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(presentation.isMuted ? Text("Unmute") : Text("Mute"))

            Slider(
                value: Binding(
                    get: { presentation.clampedVolume },
                    set: actions.setVolume
                ),
                in: 0 ... 1
            )
            .frame(width: DesignTokens.Component.panelPlayerVolumeWidth.points)
            .accessibilityLabel("Volume")

            Button(action: actions.showQueue) {
                Image(systemName: "list.bullet")
                    .frame(width: 34, height: 34)
                    .background {
                        if presentation.isQueuePresented {
                            RoundedRectangle(
                                cornerRadius: DesignTokens.Radius.control,
                                style: .continuous
                            )
                            .fill(Color(designToken: DesignTokens.Color.fillSelected))
                        }
                    }
            }
            .buttonStyle(.plain)
            .disabled(!presentation.hasCurrentItem)
            .accessibilityLabel("Queue")
            .accessibilityValue(presentation.isQueuePresented ? "Shown" : "Hidden")
        }
    }

    private var playerBackground: some ShapeStyle {
        environment.reducesTransparency
            ? AnyShapeStyle(Color(designToken: DesignTokens.Color.surfaceChrome))
            : AnyShapeStyle(.bar)
    }

    private var volumeSymbol: String {
        switch presentation.clampedVolume {
        case ...0: "speaker.slash.fill"
        case ..<0.34: "speaker.wave.1.fill"
        case ..<0.67: "speaker.wave.2.fill"
        default: "speaker.wave.3.fill"
        }
    }

    private func nowPlayingAccessibilityLabel(title: String) -> String {
        presentation.showNowPlayingAccessibilityLabel
            ?? [title, presentation.subtitle].compactMap { $0 }.joined(separator: ", ")
    }
}
#endif
