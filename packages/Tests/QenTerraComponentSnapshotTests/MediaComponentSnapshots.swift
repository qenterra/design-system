#if os(macOS)
import AppKit
import QenTerraDesignTokens
import QenTerraMediaComponents
import SwiftUI
import Testing

@MainActor
@Suite("Native media component snapshots", .serialized)
struct MediaComponentSnapshots {
    @Test(arguments: [DesignAppearancePreference.light, .dark])
    func artworkStates(appearance: DesignAppearancePreference) throws {
        try snapshot("media-artwork-states", appearance: appearance, size: .init(width: 860, height: 250)) {
            ArtworkStatesFixture()
        }
    }

    @Test(arguments: [DesignAppearancePreference.light, .dark])
    func artworkMosaics(appearance: DesignAppearancePreference) throws {
        try snapshot("media-artwork-mosaics", appearance: appearance, size: .init(width: 860, height: 230)) {
            ArtworkMosaicsFixture()
        }
    }

    @Test(arguments: [DesignAppearancePreference.light, .dark])
    func collectionSurfaces(appearance: DesignAppearancePreference) throws {
        try snapshot("media-collections", appearance: appearance, size: .init(width: 1_080, height: 650)) {
            MediaCollectionsFixture()
        }
    }

    @Test(arguments: [DesignAppearancePreference.light, .dark])
    func favoriteAndPlaybackStates(appearance: DesignAppearancePreference) throws {
        try snapshot(
            "media-controls",
            appearance: appearance,
            size: .init(width: 680, height: 190),
            accessibility: .init(reducesMotion: false),
            presentationTime: 0,
            materializesLayerPresentation: true
        ) {
            MediaControlsFixture()
        }
    }

    @Test(arguments: [DesignAppearancePreference.light, .dark])
    func playerStates(appearance: DesignAppearancePreference) throws {
        try snapshot("media-player", appearance: appearance, size: .init(width: 1_280, height: 360)) {
            PlayerStatesFixture()
        }
    }

    @Test(arguments: [DesignAppearancePreference.light, .dark])
    func queueStates(appearance: DesignAppearancePreference) throws {
        try snapshot("media-queue", appearance: appearance, size: .init(width: 820, height: 560)) {
            QueueStatesFixture()
        }
    }

    @Test(arguments: [DesignAppearancePreference.light, .dark])
    func lyricStates(appearance: DesignAppearancePreference) throws {
        try snapshot("media-lyrics", appearance: appearance, size: .init(width: 920, height: 620)) {
            LyricsFixture()
        }
    }

    @Test(arguments: [DesignAppearancePreference.light, .dark])
    func reducedMotionLyrics(appearance: DesignAppearancePreference) throws {
        try snapshot(
            "media-lyrics-reduced-motion",
            appearance: appearance,
            size: .init(width: 640, height: 390),
            accessibility: .init(reducesMotion: true)
        ) {
            ReducedMotionLyricsFixture()
        }
    }

    @Test(arguments: [DesignAppearancePreference.light, .dark])
    func metadataAndAudioDetails(appearance: DesignAppearancePreference) throws {
        try snapshot("media-metadata", appearance: appearance, size: .init(width: 760, height: 320)) {
            MetadataFixture()
        }
    }

    @Test(arguments: [DesignAppearancePreference.light, .dark])
    func nativeTableStatesAndReuse(appearance: DesignAppearancePreference) throws {
        try snapshot("media-native-table", appearance: appearance, size: .init(width: 1_040, height: 390)) {
            NativeTableFixture(appearance: appearance)
        }
    }

    private func snapshot<Content: View>(
        _ stem: String,
        appearance: DesignAppearancePreference,
        size: CGSize,
        accessibility: SnapshotAccessibility = .init(reducesMotion: true),
        presentationTime: TimeInterval = 1,
        materializesLayerPresentation: Bool = false,
        @ViewBuilder content: () -> Content
    ) throws {
        let configuration = DesignSystemConfiguration(
            appearance: appearance,
            productProfile: .cadence,
            density: .standard
        )
        let host = try NativeSnapshotHost(
            size: size,
            configuration: configuration,
            accessibility: accessibility,
            presentationTime: presentationTime,
            materializesLayerPresentation: materializesLayerPresentation,
            content: content
        )
        try assertSnapshotImage(host.render(), name: "\(stem)-\(appearance.rawValue)")
    }
}

private let mediaPalette = ArtworkPalette(
    leading: Color(red: 0.16, green: 0.33, blue: 0.78),
    trailing: Color(red: 0.82, green: 0.24, blue: 0.45),
    highlight: Color(red: 0.96, green: 0.58, blue: 0.20),
    symbolName: "waveform"
)

private struct SyntheticArtwork: View {
    let index: Int

    var body: some View {
        ZStack {
            LinearGradient(
                colors: index.isMultiple(of: 2)
                    ? [Color(red: 0.12, green: 0.32, blue: 0.72), Color(red: 0.80, green: 0.20, blue: 0.42)]
                    : [Color(red: 0.10, green: 0.58, blue: 0.58), Color(red: 0.94, green: 0.55, blue: 0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: index.isMultiple(of: 2) ? "waveform" : "music.note")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

private struct ArtworkStatesFixture: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Artwork states").font(.title2.bold())
            HStack(spacing: 16) {
                artwork(.content, "Content", 0)
                artwork(.loading, "Loading", 1)
                artwork(.placeholder(.album), "Placeholder", 2)
                artwork(.error(.track), "Unavailable", 3)
            }
        }
        .padding(24)
    }

    private func artwork(_ state: ArtworkPresentationState, _ title: String, _ index: Int) -> some View {
        VStack(spacing: 8) {
            ArtworkSurface(state: state, title: title) { SyntheticArtwork(index: index) }
                .frame(width: 170, height: 170)
            Text(title).font(.caption)
        }
    }
}

private struct ArtworkMosaicsFixture: View {
    var body: some View {
        HStack(spacing: 20) {
            ForEach(1 ... 4, id: \.self) { count in
                VStack(spacing: 8) {
                    ArtworkMosaic(slotCount: count, title: "\(count) artwork mosaic") { index in
                        SyntheticArtwork(index: index)
                    }
                    .frame(width: 170, height: 170)
                    Text("\(count) \(count == 1 ? "item" : "items")").font(.caption)
                }
            }
        }
        .padding(24)
    }
}

private func mediaItem(
    _ id: Int,
    selected: Bool = false,
    current: Bool = false,
    playing: Bool = false,
    available: Bool = true
) -> MediaItemPresentation<Int> {
    MediaItemPresentation(
        id: id,
        title: ["Signal Bloom", "Night Transit", "Glass Horizon", "Static Gardens"][id % 4],
        subtitle: ["Aster Vale", "Orchid Unit", "Mira North", "Low Atlas"][id % 4],
        metadata: id.isMultiple(of: 2) ? "2026 · 9 tracks" : "Single",
        isSelected: selected,
        isCurrent: current,
        isPlaying: playing,
        isAvailable: available
    )
}

private struct MediaCollectionsFixture: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Collection surfaces").font(.title2.bold())
            HStack(alignment: .top, spacing: 24) {
                MediaTile(item: mediaItem(0, selected: true, current: true, playing: true), accessibilityLabel: "Signal Bloom") {
                    SyntheticArtwork(index: 0)
                } trailingAccessory: { context in
                    FavoriteControl(
                        presentation: .resolve(
                            isFavorite: true,
                            isPending: false,
                            isHovered: context.isContainerHovered,
                            isFocused: context.isContainerFocused,
                            accessibilityLabel: "Unfavorite Signal Bloom",
                            accessibilityValue: "Favorite"
                        ),
                        action: { _ in }
                    )
                } action: {}
                .frame(width: 210)

                VStack(spacing: 10) {
                    MediaRow(item: mediaItem(1, selected: true), accessibilityLabel: "Night Transit") {
                        SyntheticArtwork(index: 1)
                    } trailingAccessory: {
                        MediaMetadataBadge(label: "Lossless", symbolName: "waveform")
                    } action: {}
                    MediaRow(item: mediaItem(2, available: false), accessibilityLabel: "Glass Horizon unavailable") {
                        SyntheticArtwork(index: 2)
                    } trailingAccessory: {
                        Text("Unavailable").font(.caption).foregroundStyle(.secondary)
                    } action: {}
                }
                .frame(width: 360)

                MediaGrid(minimumWidth: 140, maximumWidth: 150, spacing: 12) {
                    ForEach(0 ..< 4, id: \.self) { index in
                        MediaTile(item: mediaItem(index), accessibilityLabel: "Grid item \(index + 1)") {
                            SyntheticArtwork(index: index)
                        } trailingAccessory: { EmptyView() } action: {}
                    }
                }
                .frame(width: 380)
            }
        }
        .padding(24)
    }
}

private struct MediaControlsFixture: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Controls and playback").font(.title2.bold())
            HStack(spacing: 28) {
                favorite("Hidden", .init(isFavorite: false, isPending: false, isRevealed: false, accessibilityLabel: "Favorite", accessibilityValue: "Not favorite"))
                favorite("Revealed", .init(isFavorite: true, isPending: false, isRevealed: true, accessibilityLabel: "Unfavorite", accessibilityValue: "Favorite"))
                favorite("Pending", .init(isFavorite: true, isPending: true, isRevealed: true, accessibilityLabel: "Updating favorite", accessibilityValue: "Favorite"))
                indicator("Playing", true)
                indicator("Static", false)
            }
        }
        .padding(24)
    }

    private func favorite(_ title: String, _ presentation: FavoritePresentation) -> some View {
        VStack(spacing: 8) {
            FavoriteControl(presentation: presentation, action: { _ in })
                .frame(width: 40, height: 40)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            Text(title).font(.caption)
        }
    }

    private func indicator(_ title: String, _ isPlaying: Bool) -> some View {
        VStack(spacing: 8) {
            HostedPlaybackIndicator(isPlaying: isPlaying)
                .frame(width: 40, height: 40)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            Text(title).font(.caption)
        }
    }
}

private struct HostedPlaybackIndicator: NSViewRepresentable {
    let isPlaying: Bool

    func makeNSView(context _: Context) -> NativePlaybackIndicatorView {
        NativePlaybackIndicatorView(frame: .zero)
    }

    func updateNSView(_ view: NativePlaybackIndicatorView, context _: Context) {
        view.setPlaying(isPlaying, reduceMotion: false)
    }
}

private let playerActions = PlayerBarActions(
    showNowPlaying: {}, togglePlayback: {}, previous: {}, next: {}, seek: { _ in },
    setVolume: { _ in }, toggleMute: {}, showQueue: {}, toggleShuffle: {},
    cycleRepeatMode: {}, setFavorite: { _ in }
)

private func progress(_ value: Double, enabled: Bool) -> PlaybackProgressPresentation {
    PlaybackProgressPresentation(
        progress: value,
        leadingText: value == 0 ? "0:00" : "1:42",
        trailingText: "3:48",
        accessibilityLabel: "Playback progress",
        isEnabled: enabled
    )
}

private struct PlayerStatesFixture: View {
    var body: some View {
        VStack(spacing: 16) {
            player(.empty(progress: progress(0, enabled: false), title: "Choose something to play", symbolName: "music.note"), label: "Empty")
            player(
                PlayerBarPresentation(
                    title: "Signal Bloom", subtitle: "Aster Vale", isPlaying: true,
                    isShuffleEnabled: true, repeatMode: .all, progress: progress(0.45, enabled: true),
                    volume: 0.72, isMuted: false, isQueuePresented: true,
                    favorite: .init(isFavorite: true, isPending: false, isRevealed: true, accessibilityLabel: "Unfavorite", accessibilityValue: "Favorite")
                ),
                label: "Playing"
            )
            player(
                PlayerBarPresentation(
                    title: "Offline master", subtitle: "Drive unavailable", isPlaying: false,
                    isShuffleEnabled: false, repeatMode: .off, progress: progress(0.2, enabled: false),
                    volume: 0, isMuted: true, isQueuePresented: false, favorite: nil
                ),
                label: "Disabled progress"
            )
        }
        .padding(.horizontal, 20)
    }

    private func player(_ presentation: PlayerBarPresentation, label: String) -> some View {
        PlayerBar(presentation: presentation, actions: playerActions) {
            SyntheticArtwork(index: label.count)
        } metadataAccessory: {
            if presentation.hasCurrentItem { MediaMetadataBadge(label: "FLAC") }
        } statusAccessory: {
            if presentation.isPlaying { Image(systemName: "waveform") }
        } routeAccessory: {
            Image(systemName: "airplayaudio")
        }
        .overlay(alignment: .topLeading) {
            Text(label).font(.caption2).padding(4).foregroundStyle(.secondary)
        }
    }
}

private func queueItem(
    _ id: Int,
    current: Bool = false,
    selected: Bool = false,
    available: Bool = true,
    draggable: Bool = false
) -> PlaybackQueueRowPresentation<Int> {
    PlaybackQueueRowPresentation(
        id: id,
        title: ["Signal Bloom", "Night Transit", "Glass Horizon", "Static Gardens"][id % 4],
        subtitle: ["Aster Vale", "Orchid Unit", "Mira North", "Low Atlas"][id % 4],
        durationText: ["3:48", "4:12", "2:57", "5:06"][id % 4],
        isCurrent: current,
        isSelected: selected,
        isAvailable: available,
        isDraggable: draggable,
        accessibilityLabel: "Queue item \(id + 1)"
    )
}

private struct QueueStatesFixture: View {
    var body: some View {
        HStack(alignment: .top, spacing: 28) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Queue states").font(.title2.bold()).padding(.bottom, 6)
                row(queueItem(0, current: true), index: 0)
                row(queueItem(1, selected: true), index: 1)
                QueueInsertionIndicator().frame(width: 430)
                row(queueItem(2, available: false), index: 2)
                row(queueItem(3, draggable: true), index: 3)
            }
            VStack(alignment: .leading, spacing: 14) {
                Text("Drag preview").font(.headline)
                QueueDragPreview(title: "Static Gardens", subtitle: "Low Atlas") {
                    SyntheticArtwork(index: 3)
                }
            }
        }
        .padding(24)
    }

    private func row(_ presentation: PlaybackQueueRowPresentation<Int>, index: Int) -> some View {
        PlaybackQueueRow(
            presentation: presentation,
            dragPayload: presentation.isDraggable ? "queue-\(index)" : nil,
            play: {}, remove: {}, artwork: { SyntheticArtwork(index: index) },
            contextMenu: { Text("Remove") },
            dragPreview: { QueueDragPreview(title: presentation.title, subtitle: presentation.subtitle) { SyntheticArtwork(index: index) } }
        )
        .frame(width: 430)
    }
}

private let lyricLines = [
    LyricLinePresentation(id: 0, text: "City lights dissolve into the rain", isActive: false, isSynchronized: true, inactiveBlurRadius: 0.45),
    LyricLinePresentation(id: 1, text: "We move in time with a quieter signal", isActive: true, isSynchronized: true, inactiveBlurRadius: 0.45),
    LyricLinePresentation(id: 2, text: "An unsynchronized line remains readable", isActive: false, isSynchronized: false, inactiveBlurRadius: 0.45),
    LyricLinePresentation(id: 3, text: "This deliberately long lyric demonstrates wrapping across several lines without clipping the text or hiding its final words from the listener.", isActive: false, isSynchronized: true, inactiveBlurRadius: 0.45),
]

private struct LyricsFixture: View {
    var body: some View {
        HStack(spacing: 20) {
            LyricsViewport(lines: lyricLines, currentIdentity: 1, textSize: 28, alignment: .leading, selectLine: { _ in }, editLine: { _ in })
            LyricsViewport(lines: lyricLines, currentIdentity: nil, textSize: 24, alignment: .center, selectLine: { _ in }, editLine: { _ in })
        }
        .padding(24)
        .overlay(alignment: .bottomTrailing) {
            Text(verbatim: "Inactive lyric · opacity \(Int(lyricLines[0].opacity * 100))% · blur \(Int(lyricLines[0].blurRadius * 100))/100 pt")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(28)
        }
    }
}

private struct ReducedMotionLyricsFixture: View {
    var body: some View {
        LyricsViewport(lines: lyricLines, currentIdentity: 1, textSize: 26, alignment: .leading, selectLine: { _ in }, editLine: { _ in })
            .padding(24)
    }
}

private struct MetadataFixture: View {
    var body: some View {
        HStack(alignment: .top, spacing: 28) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Metadata").font(.title2.bold())
                HStack {
                    MediaMetadataBadge(label: "Lossless", symbolName: "waveform", accessibilityLabel: "Lossless audio")
                    MediaMetadataBadge(label: "24-bit")
                    MediaMetadataBadge(label: "96 kHz")
                }
            }
            AudioDetailsView(
                title: "Audio details",
                subtitle: "Synthetic local file",
                details: [
                    AudioDetail(id: "codec", label: "Codec", value: "FLAC", order: 0),
                    AudioDetail(id: "rate", label: "Sample rate", value: "96 kHz", order: 1),
                    AudioDetail(id: "depth", label: "Bit depth", value: "24-bit", order: 2),
                    AudioDetail(id: "channels", label: "Channels", value: "Stereo", order: 3),
                ]
            )
        }
        .padding(24)
    }
}

private struct NativeTableFixture: NSViewRepresentable {
    let appearance: DesignAppearancePreference

    func makeNSView(context _: Context) -> NSView {
        let container = NSView(frame: .zero)
        container.wantsLayer = true
        let variants: [(String, Bool, Bool, Bool)] = [
            ("Selected", true, false, false),
            ("Hovered", false, false, true),
            ("Focused", false, true, false),
            ("Reused", false, false, false),
        ]
        for (index, variant) in variants.enumerated() {
            let cell = NativeMediaTableCell()
            cell.identifier = NSUserInterfaceItemIdentifier("snapshot-\(variant.0.lowercased())")
            cell.frame = NSRect(x: 0, y: CGFloat(3 - index) * 86, width: 992, height: 78)
            if variant.0 == "Reused" {
                configure(cell, index: 99, title: "Stale item that must disappear", selected: true, focused: true)
                cell.prepareForReuse()
            }
            configure(cell, index: index, title: variant.0 + " table row", selected: variant.1, focused: variant.2)
            cell.setPointerHovered(variant.3)
            container.addSubview(cell)
        }
        return container
    }

    func updateNSView(_: NSView, context _: Context) {}

    private func configure(
        _ cell: NativeMediaTableCell,
        index: Int,
        title: String,
        selected: Bool,
        focused: Bool
    ) {
        let environment = DesignNativeEnvironment(
            appearance: appearance == .dark ? .dark : .light,
            productProfile: .cadence,
            density: .standard,
            isIncreasedContrast: false,
            reducesMotion: true,
            reducesTransparency: false
        )
        cell.configure(
            presentation: MediaTableRowPresentation(
                id: index,
                title: title,
                creator: "Aster Vale",
                collection: "Signal Bloom",
                year: "2026",
                duration: "3:48",
                isExplicit: index == 1,
                isFavorite: index != 2,
                isCurrent: index == 0,
                isPlaying: index == 0,
                isAvailable: index != 2,
                artworkIdentity: nil
            ),
            state: MediaTableCellState(
                isSelected: selected,
                isFocused: focused,
                showsArtwork: true,
                density: .standard,
                typography: .standard,
                environment: environment
            ),
            columns: [.collection, .year, .duration],
            widths: MediaTableResolvedWidths(title: 460, collection: 190, year: 64, duration: 64),
            actions: NativeMediaTableActions(
                select: { _ in }, play: { _ in }, favorite: { _ in }, creator: { _ in },
                collection: { _ in }, actions: { _ in }
            )
        )
        cell.needsLayout = true
        cell.layoutSubtreeIfNeeded()
    }
}
#endif
