#if os(macOS)
import AppKit
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
        repeatMode: .one,
        isShuffleActionAvailable: true,
        isRepeatActionAvailable: true
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

    let missingOptionalActions = TransportControlPresentation.all(
        hasCurrentItem: true,
        isPlaying: false,
        isShuffleEnabled: false,
        repeatMode: .off,
        isShuffleActionAvailable: false,
        isRepeatActionAvailable: false
    )
    #expect(
        missingOptionalActions.first(where: { $0.control == .shuffle })?.isEnabled == false
    )
    #expect(
        missingOptionalActions.first(where: { $0.control == .repeatMode })?.isEnabled == false
    )
    #expect(
        missingOptionalActions.first(where: { $0.control == .playPause })?.isEnabled == true
    )
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
        showQueue: { events.append("queue") },
        toggleShuffle: { events.append("shuffle") },
        cycleRepeatMode: { events.append("repeat") },
        setFavorite: { events.append("favorite:\($0)") }
    )

    actions.showNowPlaying()
    actions.togglePlayback()
    actions.previous()
    actions.next()
    actions.seek(0.625)
    actions.setVolume(0.375)
    actions.toggleMute()
    actions.showQueue()
    actions.toggleShuffle?()
    actions.cycleRepeatMode?()
    actions.setFavorite?(true)

    #expect(events == [
        "show", "toggle", "previous", "next", "seek:0.625", "volume:0.375", "mute", "queue",
        "shuffle", "repeat", "favorite:true",
    ])
}

@Test @MainActor func omittedOptionalPlayerActionsAreExplicitlyUnavailable() {
    let actions = PlayerBarActions(
        showNowPlaying: {},
        togglePlayback: {},
        previous: {},
        next: {},
        seek: { _ in },
        setVolume: { _ in },
        toggleMute: {},
        showQueue: {}
    )

    #expect(actions.toggleShuffle == nil)
    #expect(actions.cycleRepeatMode == nil)
    #expect(actions.setFavorite == nil)
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

@Test @MainActor func queueMetricBackedViewsExposeExactRenderedGeometry() throws {
    let recorder = QueueGeometryRecorder()
    let preview = QueueDragPreview(title: "Synthetic", subtitle: "Artist") {
        Color.red
            .background(QueueGeometryReporter(kind: .artwork, recorder: recorder))
    }
    .background(QueueGeometryReporter(kind: .preview, recorder: recorder))
    .frame(width: 400, height: 90, alignment: .topLeading)
    .coordinateSpace(name: "queue-geometry-test")

    let previewHost = NSHostingView(rootView: preview)
    previewHost.frame = NSRect(x: 0, y: 0, width: 400, height: 90)
    previewHost.layoutSubtreeIfNeeded()
    RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    previewHost.layoutSubtreeIfNeeded()

    #expect(recorder.preview.width == 330)
    #expect(recorder.artwork.width == 38)
    #expect(recorder.artwork.height == 38)

    let insertionRenderer = ImageRenderer(
        content: QueueInsertionIndicator()
            .frame(width: 100, height: 20, alignment: .top)
    )
    insertionRenderer.scale = 1
    let insertionImage = try #require(insertionRenderer.cgImage)
    let insertionBitmap = NSBitmapImageRep(cgImage: insertionImage)
    let visibleRows = (0 ..< insertionBitmap.pixelsHigh).filter { y in
        (0 ..< insertionBitmap.pixelsWide).contains { x in
            (insertionBitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.05
        }
    }
    let maximumAlpha = (0 ..< insertionBitmap.pixelsHigh).flatMap { y in
        (0 ..< insertionBitmap.pixelsWide).map { x in
            insertionBitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0
        }
    }.max() ?? 0
    let literalOpacityRenderer = ImageRenderer(
        content: Capsule()
            .fill(Color.primary.opacity(0.9))
            .frame(width: 84, height: 2)
    )
    literalOpacityRenderer.scale = 1
    let literalOpacityBitmap = NSBitmapImageRep(
        cgImage: try #require(literalOpacityRenderer.cgImage)
    )
    let literalMaximumAlpha = (0 ..< literalOpacityBitmap.pixelsHigh).flatMap { y in
        (0 ..< literalOpacityBitmap.pixelsWide).map { x in
            literalOpacityBitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0
        }
    }.max() ?? 0

    #expect(visibleRows.count == 1)
    #expect(abs(maximumAlpha - literalMaximumAlpha) < 0.005)
}

@Test @MainActor func queueDragPreviewRendersProtectedArtworkAndTextGaps() throws {
    let preview = try renderedBitmap(
        QueueDragPreview(title: "████", subtitle: "████") { Color.red }
            .foregroundStyle(.green),
        width: 400,
        height: 90
    )
    let greenPixels = matchingPixels(preview) { color in
        color.greenComponent > color.redComponent * 1.35
            && color.greenComponent > color.blueComponent * 1.35
            && color.greenComponent > 0.25
    }
    let artworkPixels = matchingPixels(preview) { color in
        color.redComponent > 0.75
            && color.greenComponent < 0.25
            && color.blueComponent < 0.25
    }
    let artworkBounds = pixelBounds(artworkPixels)
    let textBounds = pixelBounds(greenPixels)
    let textRows = contiguousRanges(greenPixels.map(\.y))
    let titleRows = try #require(textRows.first)
    let subtitleRows = try #require(textRows.dropFirst().first)

    #expect(artworkBounds == CGRect(x: 10, y: 10, width: 38, height: 38))
    #expect(textBounds == CGRect(x: 58, y: 16, width: 45, height: 27))
    #expect(textBounds.minX - artworkBounds.maxX == 10)
    #expect(textRows.count == 2)
    #expect(titleRows == 16 ... 26)
    #expect(subtitleRows == 33 ... 42)
    // The two fonts contribute four pixels of ink leading; the remaining two
    // pixels are the protected title/subtitle stack spacing.
    #expect(subtitleRows.lowerBound - titleRows.upperBound - 1 == 6)
}

@Test @MainActor func progressLabelsAndPlayerQueueControlRenderProtectedWidths() throws {
    let progress = PlaybackProgressPresentation(
        progress: 1,
        leadingText: "",
        trailingText: "",
        accessibilityLabel: "Playback progress",
        isEnabled: true
    )
    let actualRanges = hostedSliderHorizontalRanges(
        PlaybackProgressControl(presentation: progress, seek: { _ in })
    )
    // Empty text contributes no native views. Compare the real slider subtree
    // with a literal reference on this OS: two 34-point labels and two 8-point
    // gaps leave x=42...198. Native thumb/track tint and focus/AX permissions
    // are deliberately not part of this horizontal-layout contract.
    let referenceRanges = hostedSliderHorizontalRanges(
        HStack(spacing: 8) {
            Text("").frame(minWidth: 34, alignment: .leading)
            Slider(value: .constant(1), in: 0 ... 1)
            Text("").frame(minWidth: 34, alignment: .trailing)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .monospacedDigit()
    )
    #expect(referenceRanges.contains(42 ... 198))
    #expect(!actualRanges.isEmpty)
    #expect(actualRanges == referenceRanges)

    let queueShown = try renderedPlayerBarBitmap(isQueuePresented: true)
    let queueHidden = try renderedPlayerBarBitmap(isQueuePresented: false)
    let queueDifference = differingPixels(queueShown, queueHidden)
    #expect(pixelBounds(queueDifference) == CGRect(x: 1_186, y: 27, width: 34, height: 34))
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

    let releaseDeadline = Date().addingTimeInterval(1)
    while probe.player != nil, Date() < releaseDeadline {
        RunLoop.main.run(until: Date().addingTimeInterval(0.01))
    }
    #expect(probe.player == nil)
    withExtendedLifetime(picker) {}
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
    let actions = PlayerBarActions(
        showNowPlaying: {},
        togglePlayback: {},
        previous: {},
        next: {},
        seek: { _ in },
        setVolume: { _ in },
        toggleMute: {},
        showQueue: {},
        toggleShuffle: {},
        cycleRepeatMode: {},
        setFavorite: { _ in }
    )
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
        AnyView(
            PlayerBar(presentation: player, actions: actions) {
                Color.blue
            } metadataAccessory: {
                Text(verbatim: "External")
            } statusAccessory: {
                Text(verbatim: "Failure")
            } routeAccessory: {
                Text(verbatim: "AirPlay")
            }
        ),
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

@MainActor
private final class QueueGeometryRecorder {
    var artwork = CGRect.null
    var preview = CGRect.null
}

private enum QueueGeometryKind {
    case artwork
    case preview
}

private struct QueueGeometryReporter: View {
    let kind: QueueGeometryKind
    let recorder: QueueGeometryRecorder

    var body: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .named("queue-geometry-test"))
            Color.clear
                .onAppear { record(frame) }
                .onChange(of: frame) { _, value in record(value) }
        }
    }

    private func record(_ frame: CGRect) {
        switch kind {
        case .artwork: recorder.artwork = frame
        case .preview: recorder.preview = frame
        }
    }
}

private struct PixelCoordinate: Hashable {
    let x: Int
    let y: Int
}

@MainActor
private func hostedSliderHorizontalRanges<Content: View>(
    _ content: Content
) -> [ClosedRange<CGFloat>] {
    let host = NSHostingView(rootView: content.frame(width: 240, height: 40, alignment: .topLeading))
    host.sizingOptions = []
    let window = NSWindow(
        contentRect: NSRect(x: 100, y: 100, width: 240, height: 40),
        styleMask: [.borderless], backing: .buffered, defer: false
    )
    window.isReleasedWhenClosed = false
    window.contentView = host
    defer { window.close() }
    host.layoutSubtreeIfNeeded()
    RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    host.layoutSubtreeIfNeeded()

    func ranges(in view: NSView) -> [ClosedRange<CGFloat>] {
        view.subviews.flatMap { child in
            let frame = host.convert(child.alignmentRect(forFrame: child.frame), from: child.superview)
            return [frame.minX ... frame.maxX] + ranges(in: child)
        }
    }
    return ranges(in: host)
}

@MainActor
private func renderedBitmap<Content: View>(
    _ content: Content,
    width: CGFloat,
    height: CGFloat
) throws -> NSBitmapImageRep {
    let renderer = ImageRenderer(
        content: content
            .frame(width: width, height: height, alignment: .topLeading)
            .environment(\.colorScheme, .light)
    )
    renderer.scale = 1
    return NSBitmapImageRep(cgImage: try #require(renderer.cgImage))
}

private func matchingPixels(
    _ bitmap: NSBitmapImageRep,
    predicate: (NSColor) -> Bool
) -> [PixelCoordinate] {
    (0 ..< bitmap.pixelsHigh).flatMap { y in
        (0 ..< bitmap.pixelsWide).compactMap { x in
            guard let color = bitmap.colorAt(x: x, y: y), predicate(color) else { return nil }
            return PixelCoordinate(x: x, y: y)
        }
    }
}

private func differingPixels(
    _ lhs: NSBitmapImageRep,
    _ rhs: NSBitmapImageRep
) -> [PixelCoordinate] {
    precondition(lhs.pixelsWide == rhs.pixelsWide && lhs.pixelsHigh == rhs.pixelsHigh)
    return (0 ..< lhs.pixelsHigh).flatMap { y in
        (0 ..< lhs.pixelsWide).compactMap { x in
            guard let left = lhs.colorAt(x: x, y: y),
                  let right = rhs.colorAt(x: x, y: y)
            else { return nil }
            let delta = max(
                abs(left.redComponent - right.redComponent),
                abs(left.greenComponent - right.greenComponent),
                abs(left.blueComponent - right.blueComponent),
                abs(left.alphaComponent - right.alphaComponent)
            )
            return delta > 0.04 ? PixelCoordinate(x: x, y: y) : nil
        }
    }
}

private func pixelBounds(_ pixels: [PixelCoordinate]) -> CGRect {
    guard let first = pixels.first else { return .null }
    let xs = pixels.map(\.x)
    let ys = pixels.map(\.y)
    return CGRect(
        x: xs.min() ?? first.x,
        y: ys.min() ?? first.y,
        width: (xs.max() ?? first.x) - (xs.min() ?? first.x) + 1,
        height: (ys.max() ?? first.y) - (ys.min() ?? first.y) + 1
    )
}

private func contiguousRanges(_ values: [Int]) -> [ClosedRange<Int>] {
    let sorted = Array(Set(values)).sorted()
    guard let first = sorted.first else { return [] }
    var ranges: [ClosedRange<Int>] = []
    var lower = first
    var upper = first
    for value in sorted.dropFirst() {
        if value == upper + 1 {
            upper = value
        } else {
            ranges.append(lower ... upper)
            lower = value
            upper = value
        }
    }
    ranges.append(lower ... upper)
    return ranges
}

@MainActor
private func renderedPlayerBarBitmap(isQueuePresented: Bool) throws -> NSBitmapImageRep {
    let progress = PlaybackProgressPresentation(
        progress: 0.5,
        leadingText: "2:01",
        trailingText: "4:02",
        accessibilityLabel: "Playback progress",
        isEnabled: true
    )
    let presentation = PlayerBarPresentation(
        title: "Synthetic Track",
        subtitle: "Synthetic Artist",
        isPlaying: false,
        isShuffleEnabled: false,
        repeatMode: .off,
        progress: progress,
        volume: 0.5,
        isMuted: false,
        isQueuePresented: isQueuePresented,
        favorite: nil
    )
    let actions = PlayerBarActions(
        showNowPlaying: {},
        togglePlayback: {},
        previous: {},
        next: {},
        seek: { _ in },
        setVolume: { _ in },
        toggleMute: {},
        showQueue: {}
    )
    return try renderedBitmap(
        PlayerBar(presentation: presentation, actions: actions) { Color.blue },
        width: 1_240,
        height: 160
    )
}
#endif
