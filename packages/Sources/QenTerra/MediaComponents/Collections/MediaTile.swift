#if os(macOS)
import QenTerraComponents
import QenTerraDesignTokens
import SwiftUI

public enum MediaTileHorizontalAlignment: Equatable, Sendable {
    case leading
    case center
}

public enum MediaTileAccessoryPlacement: Equatable, Sendable {
    case artworkOverlay
    case labelTrailing
    case titleLeadingOverlay
}

public enum MediaTileMetadataStyle: Equatable, Sendable {
    case secondary
    case tertiary
}

public struct MediaTilePresentation: Equatable, Sendable {
    public let horizontalAlignment: MediaTileHorizontalAlignment
    public let padding: CGFloat
    public let contentSpacing: CGFloat
    public let textSpacing: CGFloat
    public let titleLineLimit: Int
    public let accessoryPlacement: MediaTileAccessoryPlacement
    public let titleAccessoryInset: CGFloat
    public let metadataStyle: MediaTileMetadataStyle
    public let showsPlaybackOverlay: Bool

    public init(
        horizontalAlignment: MediaTileHorizontalAlignment,
        padding: CGFloat,
        contentSpacing: CGFloat,
        textSpacing: CGFloat,
        titleLineLimit: Int,
        accessoryPlacement: MediaTileAccessoryPlacement,
        titleAccessoryInset: CGFloat = 0,
        metadataStyle: MediaTileMetadataStyle = .tertiary,
        showsPlaybackOverlay: Bool = true
    ) {
        self.horizontalAlignment = horizontalAlignment
        self.padding = padding
        self.contentSpacing = contentSpacing
        self.textSpacing = textSpacing
        self.titleLineLimit = titleLineLimit
        self.accessoryPlacement = accessoryPlacement
        self.titleAccessoryInset = titleAccessoryInset
        self.metadataStyle = metadataStyle
        self.showsPlaybackOverlay = showsPlaybackOverlay
    }

    public static let standard = Self(
        horizontalAlignment: .leading,
        padding: CGFloat(DesignTokens.Component.panelMediaCollectionTilePadding.points),
        contentSpacing: CGFloat(DesignTokens.Component.panelMediaCollectionTilePadding.points),
        textSpacing: CGFloat(DesignTokens.Component.panelMediaCollectionTileTextGap.points),
        titleLineLimit: 2,
        accessoryPlacement: .artworkOverlay
    )

    public static let cadenceHome = Self(
        horizontalAlignment: .leading,
        padding: 8,
        contentSpacing: 8,
        textSpacing: 4,
        titleLineLimit: 2,
        accessoryPlacement: .labelTrailing,
        showsPlaybackOverlay: false
    )

    public static func cadenceCatalog(
        contentSpacing: CGFloat = 10,
        metadataStyle: MediaTileMetadataStyle = .tertiary
    ) -> Self {
        Self(
            horizontalAlignment: .center,
            padding: 10,
            contentSpacing: contentSpacing,
            textSpacing: contentSpacing,
            titleLineLimit: 1,
            accessoryPlacement: .titleLeadingOverlay,
            titleAccessoryInset: 26,
            metadataStyle: metadataStyle
        )
    }
}

public struct MediaTile<ID: Hashable & Sendable, Artwork: View, TrailingAccessory: View>: View {
    @FocusState private var isFocused: Bool
    @State private var isHovered = false

    private let item: MediaItemPresentation<ID>
    private let accessibilityLabel: String
    private let accessibilityValue: String?
    private let presentation: MediaTilePresentation
    private let artwork: Artwork
    private let trailingAccessory: (MediaAccessoryInteractionContext) -> TrailingAccessory
    private let action: @MainActor () -> Void

    public init(
        item: MediaItemPresentation<ID>,
        accessibilityLabel: String,
        accessibilityValue: String? = nil,
        presentation: MediaTilePresentation = .standard,
        @ViewBuilder artwork: () -> Artwork,
        @ViewBuilder trailingAccessory: @escaping (MediaAccessoryInteractionContext) -> TrailingAccessory,
        action: @escaping @MainActor () -> Void
    ) {
        self.item = item
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityValue = accessibilityValue
        self.presentation = presentation
        self.artwork = artwork()
        self.trailingAccessory = trailingAccessory
        self.action = action
    }

    public init(
        item: MediaItemPresentation<ID>,
        accessibilityLabel: String,
        accessibilityValue: String? = nil,
        presentation: MediaTilePresentation = .standard,
        @ViewBuilder artwork: () -> Artwork,
        @ViewBuilder trailingAccessory: @escaping () -> TrailingAccessory,
        action: @escaping @MainActor () -> Void
    ) {
        self.init(
            item: item,
            accessibilityLabel: accessibilityLabel,
            accessibilityValue: accessibilityValue,
            presentation: presentation,
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
            primaryButton
                .overlay { accessoryOverlay }
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
            VStack(alignment: swiftUIAlignment, spacing: presentation.contentSpacing) {
                artwork
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .overlay {
                        if presentation.showsPlaybackOverlay {
                            MediaArtworkPlaybackOverlay(item: item)
                        }
                    }

                HStack(alignment: .top, spacing: presentation.padding) {
                    VStack(alignment: swiftUIAlignment, spacing: presentation.textSpacing) {
                        Text(verbatim: item.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(presentation.titleLineLimit)
                            .padding(
                                .horizontal,
                                presentation.accessoryPlacement == .titleLeadingOverlay
                                    ? presentation.titleAccessoryInset
                                    : 0
                            )
                            .frame(maxWidth: .infinity, alignment: frameAlignment)
                        if !item.subtitle.isEmpty {
                            Text(verbatim: item.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: frameAlignment)
                        }
                        if let metadata = item.metadata {
                            Text(verbatim: metadata)
                                .font(.caption)
                                .foregroundStyle(metadataForegroundStyle)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: frameAlignment)
                        }
                    }
                    if presentation.horizontalAlignment == .leading {
                        Spacer(minLength: presentation.textSpacing)
                    }
                }
            }
            .padding(presentation.padding)
            .frame(maxWidth: .infinity, alignment: frameAlignment)
            .contentShape(Rectangle())
        }
        .buttonStyle(MediaActivationButtonStyle())
        .focused($isFocused)
        .disabled(!item.isAvailable)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: accessibilityLabel))
        .modifier(OptionalAccessibilityValue(value: accessibilityValue))
    }

    @ViewBuilder
    private var accessoryOverlay: some View {
        switch presentation.accessoryPlacement {
        case .artworkOverlay:
            VStack {
                HStack {
                    Spacer()
                    trailingAccessory(accessoryInteractionContext)
                }
                Spacer()
            }
        case .labelTrailing:
            VStack(spacing: presentation.contentSpacing) {
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                HStack {
                    Spacer()
                    trailingAccessory(accessoryInteractionContext)
                }
                Spacer(minLength: 0)
            }
            .padding(presentation.padding)
        case .titleLeadingOverlay:
            VStack(spacing: presentation.contentSpacing) {
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                HStack {
                    trailingAccessory(accessoryInteractionContext)
                    Spacer()
                }
                Spacer(minLength: 0)
            }
            .padding(presentation.padding)
        }
    }

    private var swiftUIAlignment: HorizontalAlignment {
        presentation.horizontalAlignment == .center ? .center : .leading
    }

    private var frameAlignment: Alignment {
        presentation.horizontalAlignment == .center ? .center : .leading
    }

    private var metadataForegroundStyle: HierarchicalShapeStyle {
        presentation.metadataStyle == .secondary ? .secondary : .tertiary
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
