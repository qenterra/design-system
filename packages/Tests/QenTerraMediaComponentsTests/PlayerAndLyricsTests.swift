#if os(macOS)
import AVFoundation
import QenTerraDesignTokens
@testable import QenTerraMediaComponents
import SwiftUI
import Testing

@Test func playbackProgressClampsFiniteAndNonfiniteMeasurementsWithoutFormattingTime() {
    let overrun = PlaybackProgressPresentation(
        progress: 1.4,
        leadingText: "4:02",
        trailingText: "4:02",
        accessibilityLabel: "Playback progress",
        isEnabled: true
    )
    let underrun = PlaybackProgressPresentation(
        progress: -0.2,
        leadingText: "−0:03",
        trailingText: "4:02",
        accessibilityLabel: "Playback progress",
        isEnabled: true
    )
    let invalid = PlaybackProgressPresentation(
        progress: .nan,
        leadingText: "Unknown elapsed",
        trailingText: "Unknown duration",
        accessibilityLabel: "Playback progress",
        isEnabled: false
    )

    #expect(overrun.clampedProgress == 1)
    #expect(overrun.leadingText == "4:02")
    #expect(overrun.trailingText == "4:02")
    #expect(underrun.clampedProgress == 0)
    #expect(underrun.leadingText == "−0:03")
    #expect(invalid.clampedProgress == 0)
    #expect(invalid.leadingText == "Unknown elapsed")
    #expect(invalid.trailingText == "Unknown duration")
    #expect(!invalid.isEnabled)
}

@Test func progressDragPublishesOnlyTheFinishedLocalValueThenClearsIt() {
    var drag = PlaybackProgressDragState()
    #expect(drag.displayedProgress(consumerProgress: 0.2) == 0.2)

    drag.update(to: 0.7)
    #expect(drag.displayedProgress(consumerProgress: 0.25) == 0.7)
    #expect(drag.finish() == 0.7)
    #expect(drag.displayedProgress(consumerProgress: 0.25) == 0.25)
    #expect(drag.finish() == nil)
}

@Test func transportLabelsAndAvailabilityFollowTheExplicitSnapshot() {
    let disabled = TransportControlPresentation.all(
        hasCurrentItem: false,
        isPlaying: false,
        isShuffleEnabled: false,
        repeatMode: .off
    )
    #expect(disabled.map(\.isEnabled) == Array(repeating: false, count: disabled.count))
    #expect(disabled.first(where: { $0.control == .playPause })?.accessibilityLabel == "Play")
    #expect(disabled.first(where: { $0.control == .playPause })?.accessibilityValue == nil)
    #expect(disabled.first(where: { $0.control == .repeatMode })?.accessibilityLabel == "Repeat Off")

    let playing = TransportControlPresentation.all(
        hasCurrentItem: true,
        isPlaying: true,
        isShuffleEnabled: true,
        repeatMode: .one
    )
    #expect(playing.first(where: { $0.control == .playPause })?.accessibilityLabel == "Pause")
    #expect(playing.first(where: { $0.control == .shuffle })?.isActive == true)
    #expect(playing.first(where: { $0.control == .shuffle })?.accessibilityValue == "On")
    #expect(playing.first(where: { $0.control == .repeatMode })?.accessibilityLabel == "Repeat One")
    #expect(playing.first(where: { $0.control == .repeatMode })?.symbolName == "repeat.1")

    let repeatingAll = TransportControlPresentation.resolve(
        .repeatMode,
        hasCurrentItem: true,
        isPlaying: false,
        isShuffleEnabled: false,
        repeatMode: .all
    )
    #expect(repeatingAll.accessibilityLabel == "Repeat All")
    #expect(repeatingAll.symbolName == "repeat")
    #expect(repeatingAll.isActive)
}

@Test func playerLayoutMatchesTheCadenceThreeRegionGeometry() {
    #expect(PlayerBarLayoutMetrics.metadataWidth(availableWidth: 860) == 244)
    #expect(PlayerBarLayoutMetrics.metadataWidth(availableWidth: 1_100) == 308)
    #expect(PlayerBarLayoutMetrics.metadataWidth(availableWidth: 1_400) == 380)

    let frame = PlayerBarLayoutMetrics.contentFrame(availableWidth: 1_100)
    #expect(frame.width == 1_100)
    #expect(frame.height == 56)
    #expect(frame.minY == 16)
}

@Test @MainActor func playerActionsForwardLiteralConsumerValues() {
    var events: [String] = []
    let actions = PlayerBarActions(
        showNowPlaying: { events.append("show") },
        togglePlayback: { events.append("toggle") },
        previous: { events.append("previous") },
        next: { events.append("next") },
        seek: { events.append("seek:\($0)") },
        setVolume: { events.append("volume:\($0)") },
        toggleMute: { events.append("mute") },
        showQueue: { events.append("queue") }
    )

    actions.showNowPlaying()
    actions.togglePlayback()
    actions.previous()
    actions.next()
    actions.seek(0.625)
    actions.setVolume(0.375)
    actions.toggleMute()
    actions.showQueue()

    #expect(events == [
        "show", "toggle", "previous", "next", "seek:0.625", "volume:0.375", "mute", "queue",
    ])
}

@Test func playerPresentationClampsVolumeAndKeepsSnapshotCopyLiteral() {
    let presentation = PlayerBarPresentation(
        title: "Synthetic Track",
        subtitle: "Synthetic Artist",
        isPlaying: true,
        isShuffleEnabled: false,
        repeatMode: .all,
        progress: PlaybackProgressPresentation(
            progress: 0.5,
            leadingText: "2:01 elapsed",
            trailingText: "−2:01 remaining",
            accessibilityLabel: "Synthetic playback position",
            isEnabled: true
        ),
        volume: 1.4,
        isMuted: false,
        isQueuePresented: true,
        favorite: nil
    )

    #expect(presentation.hasCurrentItem)
    #expect(presentation.clampedVolume == 1)
    #expect(presentation.progress.leadingText == "2:01 elapsed")
    #expect(presentation.progress.trailingText == "−2:01 remaining")
    #expect(presentation.isQueuePresented)

    let empty = PlayerBarPresentation.empty(
        progress: PlaybackProgressPresentation(
            progress: 0,
            leadingText: "0:00",
            trailingText: "0:00",
            accessibilityLabel: "Playback progress",
            isEnabled: false
        ),
        title: "Choose something to play",
        symbolName: "music.note"
    )
    #expect(!empty.hasCurrentItem)
    #expect(empty.title == nil)
    #expect(empty.emptyTitle == "Choose something to play")
    #expect(empty.emptySymbolName == "music.note")
}

@Test func queuePresentationKeepsCurrentSelectionAndAvailabilityIndependent() {
    let current = PlaybackQueueRowPresentation(
        id: 1,
        title: "Current",
        subtitle: "Artist · Album",
        durationText: "3:42",
        isCurrent: true,
        isSelected: false,
        isAvailable: true,
        isDraggable: false,
        accessibilityLabel: "Current by Artist"
    )
    let unavailable = PlaybackQueueRowPresentation(
        id: 2,
        title: "Unavailable Track",
        subtitle: "The library no longer contains this queue item.",
        durationText: nil,
        isCurrent: false,
        isSelected: true,
        isAvailable: false,
        isDraggable: true,
        accessibilityLabel: "Unavailable queue item"
    )

    #expect(current.accessibilityValue == "Current track")
    #expect(!current.isSelected)
    #expect(unavailable.accessibilityValue == "Selected, unavailable")
    #expect(unavailable.isSelected)
    #expect(!unavailable.acceptsPlayback)
    #expect(!unavailable.isDraggable)
}

@Test func queueAccessibilityOffersOnlyActionsThatCanRun() {
    #expect(
        PlaybackQueueAccessibilityAction.available(
            acceptsPlayback: true,
            canRemove: true
        ) == [.play, .remove]
    )
    #expect(
        PlaybackQueueAccessibilityAction.available(
            acceptsPlayback: false,
            canRemove: true
        ) == [.remove]
    )
    #expect(
        PlaybackQueueAccessibilityAction.available(
            acceptsPlayback: true,
            canRemove: false
        ) == [.play]
    )
    #expect(
        PlaybackQueueAccessibilityAction.available(
            acceptsPlayback: false,
            canRemove: false
        ).isEmpty
    )
}

@Test func inactiveSynchronizedLyricsAreSubtleButReadable() {
    let inactive = LyricLinePresentation(
        id: 2,
        text: "Second synthetic line",
        isActive: false,
        isSynchronized: true,
        inactiveBlurRadius: 0.45
    )
    let active = LyricLinePresentation(
        id: 3,
        text: "Active line",
        isActive: true,
        isSynchronized: true,
        inactiveBlurRadius: 0.45
    )
    let unsynchronized = LyricLinePresentation(
        id: 4,
        text: "Untimed line",
        isActive: false,
        isSynchronized: false,
        inactiveBlurRadius: 0.45
    )

    #expect(inactive.tone == .secondary)
    #expect(inactive.opacity == 0.58)
    #expect(inactive.blurRadius == 0.45)
    #expect(active.tone == .primary)
    #expect(active.opacity == 1)
    #expect(active.blurRadius == 0)
    #expect(unsynchronized.tone == .primary)
    #expect(unsynchronized.opacity == 1)
    #expect(unsynchronized.blurRadius == 0)
}

@Test func lyricScrollDecisionUsesOnlyIdentityAndReducedMotion() {
    #expect(
        LyricsScrollDecision.resolve(
            previousIdentity: 1,
            currentIdentity: 2,
            reducesMotion: false
        ) == .line(id: 2, duration: 0.32)
    )
    #expect(
        LyricsScrollDecision.resolve(
            previousIdentity: 1,
            currentIdentity: 2,
            reducesMotion: true
        ) == .line(id: 2, duration: 0)
    )
    #expect(
        LyricsScrollDecision.resolve(
            previousIdentity: 2,
            currentIdentity: 2,
            reducesMotion: false
        ) == .none
    )
    #expect(
        LyricsScrollDecision.resolve(
            previousIdentity: 2,
            currentIdentity: nil,
            reducesMotion: false
        ) == .none
    )
}

@Test func audioDetailsPreserveConsumerOrderingWithoutDerivingPlaybackMetadata() {
    let details = [
        AudioDetail(id: "output", label: "Output", value: "Built-in", order: 30),
        AudioDetail(id: "codec", label: "Codec", value: "FLAC", order: 10),
        AudioDetail(id: "rate", label: "Sample rate", value: "96 kHz", order: 20),
    ]

    #expect(AudioDetail.ordered(details).map(\.id) == ["codec", "rate", "output"])
    #expect(AudioDetail.ordered(details).map(\.value) == ["FLAC", "96 kHz", "Built-in"])
}

@Test @MainActor func airPlayPickerRoutesOnlyAPlayerWithACurrentItem() {
    let empty = AVPlayer()
    #expect(AirPlayRoutePicker.routingPlayer(empty) == nil)

    let item = AVPlayerItem(url: URL(fileURLWithPath: "/private/tmp/qenterra-synthetic-audio"))
    let ready = AVPlayer(playerItem: item)
    #expect(AirPlayRoutePicker.routingPlayer(ready) === ready)
}

@Test @MainActor func airPlayPickerDoesNotRetainTheConsumerPlayer() {
    let probe = WeakPlayerProbe()
    let picker = makeAirPlayPicker(probe: probe)

    #expect(probe.player == nil)
    _ = picker
}

private final class WeakPlayerProbe {
    weak var player: AVPlayer?
}

@MainActor
private func makeAirPlayPicker(probe: WeakPlayerProbe) -> AirPlayRoutePicker {
    let player = AVPlayer()
    probe.player = player
    #expect(probe.player != nil)
    return AirPlayRoutePicker(player: player)
}

@Test @MainActor func playerQueueLyricsAndMetadataViewsRenderFromReadyPresentationOnly() throws {
    let progress = PlaybackProgressPresentation(
        progress: 0.5,
        leadingText: "2:01",
        trailingText: "4:02",
        accessibilityLabel: "Playback progress",
        isEnabled: true
    )
    let player = PlayerBarPresentation(
        title: "Synthetic Track",
        subtitle: "Synthetic Artist",
        isPlaying: true,
        isShuffleEnabled: false,
        repeatMode: .off,
        progress: progress,
        volume: 0.5,
        isMuted: false,
        isQueuePresented: false,
        favorite: nil
    )
    let actions = PlayerBarActions.noop
    let queue = PlaybackQueueRowPresentation(
        id: "queue",
        title: "Synthetic Track",
        subtitle: "Synthetic Artist",
        durationText: "4:02",
        isCurrent: true,
        isSelected: false,
        isAvailable: true,
        isDraggable: true,
        accessibilityLabel: "Synthetic Track"
    )
    let lyrics = [
        LyricLinePresentation(
            id: 1,
            text: "First synthetic line",
            isActive: true,
            isSynchronized: true,
            inactiveBlurRadius: 0.45
        ),
    ]
    let views: [AnyView] = [
        AnyView(PlayerBar(presentation: player, actions: actions) { Color.blue }),
        AnyView(PlaybackProgressControl(presentation: progress, seek: { _ in })),
        AnyView(TransportControls(presentation: player, actions: actions)),
        AnyView(
            PlaybackQueueRow(
                presentation: queue,
                play: {},
                remove: nil,
                artwork: { Color.blue },
                contextMenu: { EmptyView() },
                dragPreview: { EmptyView() }
            )
        ),
        AnyView(QueueInsertionIndicator()),
        AnyView(QueueDragPreview(title: "Synthetic Track", subtitle: "Synthetic Artist") { Color.blue }),
        AnyView(LyricLine(presentation: lyrics[0], textSize: 22, alignment: .leading, select: {}, edit: {})),
        AnyView(LyricsViewport(lines: lyrics, currentIdentity: 1, textSize: 22, alignment: .leading, selectLine: { _ in }, editLine: { _ in })),
        AnyView(LyricsEdgeFade()),
        AnyView(MediaMetadataBadge(label: "Lossless", symbolName: "waveform")),
        AnyView(AudioDetailsView(title: "Audio Details", subtitle: "Current playback path", details: [AudioDetail(id: "codec", label: "Codec", value: "FLAC", order: 0)])),
    ]

    for view in views {
        let renderer = ImageRenderer(content: view.frame(width: 520, height: 180))
        #expect(renderer.cgImage != nil)
    }
}
#endif
