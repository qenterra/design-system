import AppKit
import Metal
import QenTerraComponents
import QenTerraDesignTokens
import QenTerraMediaComponents
import SwiftUI

@MainActor
func verifyPublicCatalog() {
    let artworkState = ArtworkPresentationState.content
    let artwork = ArtworkSurface(state: artworkState, title: "Public artwork") {
        Color.blue
    }
    let placeholder = ArtworkPlaceholder(kind: .album)
    let mosaic = ArtworkMosaic(slotCount: 4, title: "Public mosaic") { index in
        Color(hue: Double(index) / 4, saturation: 0.7, brightness: 0.8)
    }

    let item = MediaItemPresentation(
        id: "public-item",
        title: "Public Track",
        subtitle: "Public Artist",
        metadata: "2026 · FLAC",
        isSelected: true,
        isCurrent: true,
        isPlaying: true,
        isAvailable: true
    )
    let tile = MediaTile(item: item, accessibilityLabel: "Public Track") {
        artwork
    } trailingAccessory: {
        FavoriteControl(
            presentation: FavoritePresentation(
                isFavorite: true,
                isPending: false,
                isRevealed: true,
                accessibilityLabel: "Unfavorite Public Track",
                accessibilityValue: "Favorite"
            ),
            action: { _ in }
        )
    } action: {}
    let row = MediaRow(item: item, accessibilityLabel: "Public Track") {
        artwork
    } trailingAccessory: {
        PlaybackIndicator(isPlaying: true)
    } action: {}
    let grid = MediaGrid { tile }

    let progress = PlaybackProgressPresentation(
        progress: 0.5,
        leadingText: "1:00",
        trailingText: "2:00",
        accessibilityLabel: "Playback progress",
        isEnabled: true
    )
    let player = PlayerBarPresentation(
        title: "Public Track",
        subtitle: "Public Artist",
        isPlaying: true,
        isShuffleEnabled: false,
        repeatMode: .off,
        progress: progress,
        volume: 0.5,
        isMuted: false,
        isQueuePresented: false,
        favorite: nil
    )
    let actions = PlayerBarActions(
        showNowPlaying: {}, togglePlayback: {}, previous: {}, next: {}, seek: { _ in },
        setVolume: { _ in }, toggleMute: {}, showQueue: {}
    )
    let playerBar = PlayerBar(presentation: player, actions: actions) {
        artwork
    } metadataAccessory: {
        MediaMetadataBadge(label: "FLAC")
    } statusAccessory: {
        EmptyView()
    } routeAccessory: {
        Image(systemName: "airplayaudio")
    }

    let queuePresentation = PlaybackQueueRowPresentation(
        id: "public-queue-item",
        title: "Public Track",
        subtitle: "Public Artist",
        durationText: "2:00",
        isCurrent: false,
        isSelected: true,
        isAvailable: true,
        isDraggable: true,
        accessibilityLabel: "Public Track"
    )
    let queue = PlaybackQueueRow(
        presentation: queuePresentation,
        dragPayload: "public-queue-item",
        play: {},
        remove: {},
        artwork: { artwork },
        contextMenu: { Text("Remove") },
        dragPreview: { QueueDragPreview(title: "Public Track", subtitle: "Public Artist") { artwork } }
    )
    let insertion = QueueInsertionIndicator()

    let lyric = LyricLinePresentation(
        id: "public-lyric",
        text: "Public lyric",
        isActive: true,
        isSynchronized: true,
        inactiveBlurRadius: 0.45
    )
    let lyrics = LyricsViewport(
        lines: [lyric],
        currentIdentity: lyric.id,
        textSize: 24,
        alignment: .leading,
        selectLine: { _ in },
        editLine: { _ in }
    )
    let audio = AudioDetailsView(
        title: "Audio details",
        details: [AudioDetail(id: "codec", label: "Codec", value: "FLAC", order: 0)]
    )

    let tableRow = MediaTableRowPresentation(
        id: "public-table-item",
        title: "Public Track",
        creator: "Public Artist",
        collection: "Public Collection",
        year: "2026",
        duration: "2:00",
        isExplicit: false,
        isFavorite: true,
        isCurrent: true,
        isPlaying: false,
        isAvailable: true,
        artworkIdentity: "public-artwork"
    )
    let tableCell = NativeMediaTableCell()
    tableCell.configure(
        presentation: tableRow,
        state: .standard,
        actions: NativeMediaTableActions(select: { _ in }, play: { _ in })
    )
    let table = NativeMediaTableView()
    table.configureKeyboardActions(onReturn: {}, onSpace: {}, onDelete: {})
    let tablePlaceholder = MediaTablePlaceholderRow()

    let palette = ArtworkAccentPalette(colors: [
        ArtworkAccentColor(red: 0.2, green: 0.4, blue: 0.8),
        ArtworkAccentColor(red: 0.9, green: 0.5, blue: 0.1),
    ])
    let environment = DesignNativeEnvironment(
        appearance: .dark,
        productProfile: .standard,
        density: .standard,
        isIncreasedContrast: false,
        reducesMotion: true,
        reducesTransparency: false
    )
    let gradientAppearance = ArtworkAccentGradientAppearance.resolve(
        palette: palette,
        isEffectActive: true,
        environment: environment
    )
    let gradient = ArtworkAccentGradient(palette: palette, appearance: gradientAppearance)
    let nativeGradient = ArtworkAccentGradientView(frame: .zero, device: nil)
    nativeGradient.update(palette: palette, appearance: gradientAppearance)
    let gradientSnapshot = ArtworkAccentGradientSnapshot.render(
        palette: palette,
        size: CGSize(width: 32, height: 32),
        time: 0,
        device: nil
    )

    _ = [AnyView(placeholder), AnyView(mosaic), AnyView(row), AnyView(grid), AnyView(playerBar)]
    _ = [AnyView(queue), AnyView(insertion), AnyView(lyrics), AnyView(audio), AnyView(tablePlaceholder), AnyView(gradient)]
    precondition(tableCell.representedItemID == AnyHashable(tableRow.id))
    precondition(table.numberOfRows == 0)
    precondition(gradientSnapshot != nil)
    precondition(ArtworkAccentGradientResourceAvailability.hasPackagedShader)
    precondition(MediaComponents.version == DesignTokens.version)
}

await verifyPublicCatalog()
print("PUBLIC_MEDIA_CATALOG_OK")
