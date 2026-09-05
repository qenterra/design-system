import AppKit
import Foundation
import QenTerraComponents
import QenTerraDesignTokens
import QenTerraMediaComponents
import SwiftUI

private struct HostConfiguration {
    let pidPath: String?
    let resultPath: String?
    let shouldHangForCleanupTest: Bool
    let shouldRunPlayerOnly: Bool

    static func current(arguments: [String] = CommandLine.arguments) -> HostConfiguration {
        func value(after option: String) -> String? {
            guard let index = arguments.firstIndex(of: option), arguments.indices.contains(index + 1) else {
                return nil
            }
            return arguments[index + 1]
        }

        return HostConfiguration(
            pidPath: value(after: "--qenterra-pid-path"),
            resultPath: value(after: "--qenterra-result-path"),
            shouldHangForCleanupTest: arguments.contains("--qenterra-test-hang"),
            shouldRunPlayerOnly: arguments.contains("--qenterra-player-only")
        )
    }
}

private func writeHostState(_ value: String, to path: String?) throws {
    guard let path else { return }
    try value.write(toFile: path, atomically: true, encoding: .utf8)
}

private enum HostFailure: Error, CustomStringConvertible {
    case assertion(String)

    var description: String {
        switch self {
        case let .assertion(message): message
        }
    }
}

@MainActor
private final class InteractionRecorder {
    var primaryActions = 0
    var accessoryActions = 0
    var context = MediaAccessoryInteractionContext()
    var containerFrame = CGRect.null
    var primaryFrame = CGRect.null
    var accessoryFrame = CGRect.null
}

@MainActor
private final class PlayerInteractionRecorder {
    private(set) var events: [String: Int] = [:]
    var metadataAccessoryFrame = CGRect.null
    var statusAccessoryFrame = CGRect.null
    var routeAccessoryFrame = CGRect.null
    var artworkFrame = CGRect.null

    func record(_ event: String) {
        events[event, default: 0] += 1
    }

    func count(_ event: String) -> Int {
        events[event, default: 0]
    }
}

private enum PlayerAccessoryRegion {
    case artwork
    case metadata
    case status
    case route
}

private struct PlayerAccessoryFrameReporter: View {
    let region: PlayerAccessoryRegion
    let recorder: PlayerInteractionRecorder

    var body: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .named("player-interaction-host"))
            Color.clear
                .onAppear { record(frame) }
                .onChange(of: frame) { _, value in record(value) }
        }
        .accessibilityHidden(true)
    }

    private func record(_ frame: CGRect) {
        switch region {
        case .artwork: recorder.artworkFrame = frame
        case .metadata: recorder.metadataAccessoryFrame = frame
        case .status: recorder.statusAccessoryFrame = frame
        case .route: recorder.routeAccessoryFrame = frame
        }
    }
}

private enum CompositionKind: String, CaseIterable {
    case tile
    case row
}

private enum InteractionRegion {
    case container
    case primary
    case accessory
}

private struct InteractionFrameReporter: View {
    let region: InteractionRegion
    let recorder: InteractionRecorder

    var body: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .named("media-interaction-host"))
            Color.clear
                .onAppear { record(frame) }
                .onChange(of: frame) { _, newValue in record(newValue) }
        }
        .accessibilityHidden(true)
    }

    private func record(_ frame: CGRect) {
        switch region {
        case .container: recorder.containerFrame = frame
        case .primary: recorder.primaryFrame = frame
        case .accessory: recorder.accessoryFrame = frame
        }
    }
}

private struct HostedFavoriteAccessory: View {
    let context: MediaAccessoryInteractionContext
    let presentation: FavoritePresentation
    let recorder: InteractionRecorder

    var body: some View {
        FavoriteControl(
            presentation: presentation,
            interactionContext: context
        ) { _ in
            recorder.accessoryActions += 1
        }
        .background(InteractionFrameReporter(region: .accessory, recorder: recorder))
        .onAppear { recorder.context = context }
        .onChange(of: context) { _, newValue in recorder.context = newValue }
    }
}

@MainActor
private func composition(
    _ kind: CompositionKind,
    isAvailable: Bool,
    isPending: Bool,
    recorder: InteractionRecorder
) -> AnyView {
    let item = MediaItemPresentation(
        id: "synthetic-\(kind.rawValue)",
        title: "Synthetic Track",
        subtitle: "Synthetic Artist",
        metadata: "3:42",
        isSelected: false,
        isCurrent: false,
        isPlaying: false,
        isAvailable: isAvailable
    )
    let favorite = FavoritePresentation(
        isFavorite: false,
        isPending: isPending,
        isRevealed: false,
        accessibilityLabel: "Add Synthetic Track to saved items",
        accessibilityValue: isPending ? "Saving" : "Not saved"
    )

    switch kind {
    case .tile:
        return AnyView(
            MediaTile(item: item, accessibilityLabel: "Play Synthetic Track") {
                Color.blue
                    .frame(width: 140, height: 140)
                    .overlay(alignment: .bottomLeading) {
                        Color.clear
                            .frame(width: 24, height: 24)
                            .background(
                                InteractionFrameReporter(region: .primary, recorder: recorder)
                            )
                    }
            } trailingAccessory: { context in
                HostedFavoriteAccessory(
                    context: context,
                    presentation: favorite,
                    recorder: recorder
                )
            } action: {
                recorder.primaryActions += 1
            }
            .frame(width: 220, height: 250)
            .background(InteractionFrameReporter(region: .container, recorder: recorder))
            .frame(width: 480, height: 360)
            .coordinateSpace(name: "media-interaction-host")
        )
    case .row:
        return AnyView(
            MediaRow(item: item, accessibilityLabel: "Play Synthetic Track") {
                Color.blue
                    .overlay {
                        Color.clear
                            .frame(width: 24, height: 24)
                            .background(
                                InteractionFrameReporter(region: .primary, recorder: recorder)
                            )
                    }
            } trailingAccessory: { context in
                HostedFavoriteAccessory(
                    context: context,
                    presentation: favorite,
                    recorder: recorder
                )
            } action: {
                recorder.primaryActions += 1
            }
            .frame(width: 360, height: 80)
            .background(InteractionFrameReporter(region: .container, recorder: recorder))
            .frame(width: 480, height: 360)
            .coordinateSpace(name: "media-interaction-host")
        )
    }
}

@MainActor
private final class NativeInteractionHarness {
    private let window: NSWindow
    private let host: NSHostingView<AnyView>

    init(rootView: AnyView, size: CGSize = CGSize(width: 480, height: 360)) throws {
        window = NSWindow(
            contentRect: NSRect(origin: NSPoint(x: 120, y: 120), size: size),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        host = NSHostingView(rootView: rootView)
        host.sizingOptions = []
        host.frame = NSRect(origin: .zero, size: size)
        host.autoresizingMask = [.width, .height]
        window.contentView = host
        window.acceptsMouseMovedEvents = true
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(host)
        window.orderFrontRegardless()
        let activationDeadline = Date().addingTimeInterval(5)
        repeat {
            NSApp.activate()
            _ = NSRunningApplication.current.activate(
                options: [.activateAllWindows, .activateIgnoringOtherApps]
            )
            window.makeKey()
            pump()
        } while (!NSApp.isActive || !window.isKeyWindow) && Date() < activationDeadline

        try require(
            window.isKeyWindow,
            "application host did not create a key NSWindow (active=\(NSApp.isActive))"
        )
        try require(NSApp.isActive, "application host is not active")
    }

    func validateFrames(_ recorder: InteractionRecorder) throws {
        pump()
        let namedFrames = [
            ("container", recorder.containerFrame),
            ("primary", recorder.primaryFrame),
            ("accessory", recorder.accessoryFrame),
        ]
        for (name, frame) in namedFrames {
            try require(
                frame.origin.x.isFinite
                    && frame.origin.y.isFinite
                    && frame.width.isFinite
                    && frame.height.isFinite
                    && frame.width > 0
                    && frame.height > 0,
                "\(name) published an invalid interaction frame: \(frame)"
            )
        }
        try require(
            recorder.containerFrame.contains(recorder.primaryFrame),
            "primary interaction frame escaped the container"
        )
        try require(
            recorder.containerFrame.contains(recorder.accessoryFrame),
            "accessory interaction frame escaped the container"
        )
        try require(
            recorder.primaryFrame.intersection(recorder.accessoryFrame).isNull,
            "primary and accessory interaction frames overlap"
        )
    }

    func movePointer(to frame: CGRect) throws {
        let physicalCursor = NSEvent.mouseLocation
        let targetBeforeMove = window.convertPoint(toScreen: windowPoint(for: frame))
        window.setFrameOrigin(
            NSPoint(
                x: window.frame.origin.x + physicalCursor.x - targetBeforeMove.x,
                y: window.frame.origin.y + physicalCursor.y - targetBeforeMove.y
            )
        )
        window.orderFrontRegardless()
        window.makeKey()
        pump()

        let targetAfterMove = window.convertPoint(toScreen: windowPoint(for: frame))
        try require(
            abs(targetAfterMove.x - physicalCursor.x) < 1
                && abs(targetAfterMove.y - physicalCursor.y) < 1,
            "window could not place the published target under the physical cursor"
        )
        NSApp.postEvent(
            try mouseEvent(
                type: .mouseMoved,
                point: windowPoint(for: frame),
                clickCount: 0,
                pressure: 0
            ),
            atStart: false
        )
        pump()
    }

    func moveContainerAwayFromPointer() throws {
        let physicalCursor = NSEvent.mouseLocation
        window.setFrameOrigin(
            NSPoint(x: physicalCursor.x + 80, y: physicalCursor.y + 80)
        )
        NSApp.postEvent(
            try mouseEvent(
                type: .mouseMoved,
                point: window.convertPoint(fromScreen: physicalCursor),
                clickCount: 0,
                pressure: 0
            ),
            atStart: false
        )
        pump()
    }

    func click(_ frame: CGRect) throws {
        let point = windowPoint(for: frame)
        NSApp.postEvent(
            try mouseEvent(type: .leftMouseDown, point: point, clickCount: 1, pressure: 1),
            atStart: false
        )
        NSApp.postEvent(
            try mouseEvent(type: .leftMouseUp, point: point, clickCount: 1, pressure: 0),
            atStart: false
        )
        pump()
    }

    func pressTab() throws {
        window.recalculateKeyViewLoop()
        NSApp.postEvent(
            try keyEvent(
                type: .keyDown,
                characters: "\t",
                keyCode: 48
            ),
            atStart: false
        )
        NSApp.postEvent(
            try keyEvent(
                type: .keyUp,
                characters: "\t",
                keyCode: 48
            ),
            atStart: false
        )
        pump()
    }

    func pressSpace() throws {
        NSApp.postEvent(try keyEvent(type: .keyDown, characters: " ", keyCode: 49), atStart: false)
        NSApp.postEvent(try keyEvent(type: .keyUp, characters: " ", keyCode: 49), atStart: false)
        pump()
    }

    func validateAccessibility(
        primaryLabel: String,
        accessoryLabel: String,
        accessoryValue: String,
        accessoryEnabled: Bool
    ) throws -> Bool {
        pump()
        let nodes = accessibilityDescendants(of: .view(host))
        let labelledNodes = nodes.compactMap { node in
            node.label.map { ($0, node) }
        }
        guard !labelledNodes.isEmpty else { return false }
        try require(
            labelledNodes.contains { $0.0 == primaryLabel },
            "accessibility tree changed consumer primary label; labels: \(labelledNodes.map(\.0))"
        )
        let accessory = try requireValue(
            labelledNodes.first { $0.0 == accessoryLabel }?.1,
            "accessibility tree changed consumer accessory label; labels: \(labelledNodes.map(\.0))"
        )
        try require(
            accessory.value == accessoryValue,
            "accessibility tree changed consumer accessory value"
        )
        try require(
            accessory.isEnabled == accessoryEnabled,
            "accessibility tree changed accessory enabled state"
        )
        return true
    }

    func close() {
        window.orderOut(nil)
        window.close()
        pump()
    }

    func pointerDiagnostics(for frame: CGRect) -> String {
        let windowPoint = windowPoint(for: frame)
        let hostPoint = host.convert(windowPoint, from: nil)
        let hit = host.hitTest(hostPoint).map { String(describing: type(of: $0)) } ?? "nil"
        let tracking = trackingAreaDescriptions(in: host, hostPoint: hostPoint)
        return "frame=\(frame) hostFlipped=\(host.isFlipped) windowPoint=\(windowPoint) hit=\(hit) trackingAreas=\(tracking) mouse=\(window.mouseLocationOutsideOfEventStream)"
    }

    private func windowPoint(for frame: CGRect) -> NSPoint {
        host.convert(NSPoint(x: frame.midX, y: frame.midY), to: nil)
    }

    private func trackingAreaDescriptions(in view: NSView, hostPoint: NSPoint) -> [String] {
        let point = view.convert(hostPoint, from: host)
        let local = view.trackingAreas.map { area in
            let owner = area.owner.map { String(describing: type(of: $0)) } ?? "nil"
            return "view=\(type(of: view)) owner=\(owner) rect=\(area.rect) contains=\(area.rect.contains(point)) options=\(area.options.rawValue)"
        }
        return local + view.subviews.flatMap { trackingAreaDescriptions(in: $0, hostPoint: hostPoint) }
    }

    private func mouseEvent(
        type: NSEvent.EventType,
        point: NSPoint,
        clickCount: Int,
        pressure: Float
    ) throws -> NSEvent {
        try requireValue(
            NSEvent.mouseEvent(
                with: type,
                location: point,
                modifierFlags: [],
                timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: window.windowNumber,
                context: nil,
                eventNumber: 0,
                clickCount: clickCount,
                pressure: pressure
            ),
            "failed to create \(type) event"
        )
    }

    private func keyEvent(
        type: NSEvent.EventType,
        characters: String,
        keyCode: UInt16,
        modifierFlags: NSEvent.ModifierFlags = []
    ) throws -> NSEvent {
        try requireValue(
            NSEvent.keyEvent(
                with: type,
                location: .zero,
                modifierFlags: modifierFlags,
                timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: window.windowNumber,
                context: nil,
                characters: characters,
                charactersIgnoringModifiers: characters,
                isARepeat: false,
                keyCode: keyCode
            ),
            "failed to create keyboard event"
        )
    }

    private func pump() {
        window.layoutIfNeeded()
        host.layoutSubtreeIfNeeded()
        while let event = NSApp.nextEvent(
            matching: .any,
            until: Date(),
            inMode: .default,
            dequeue: true
        ) {
            NSApp.sendEvent(event)
        }
        RunLoop.main.run(until: Date().addingTimeInterval(0.06))
        window.layoutIfNeeded()
        host.layoutSubtreeIfNeeded()
    }
}

private enum AccessibilityNode {
    case view(NSView)
    case virtual(NSAccessibilityElement)

    init?(_ rawElement: Any) {
        if let view = rawElement as? NSView {
            self = .view(view)
        } else if let element = rawElement as? NSAccessibilityElement {
            self = .virtual(element)
        } else {
            return nil
        }
    }

    var label: String? {
        switch self {
        case let .view(view): view.accessibilityLabel()
        case let .virtual(element): element.accessibilityLabel()
        }
    }

    var value: String? {
        let rawValue: Any?
        switch self {
        case let .view(view): rawValue = view.accessibilityValue()
        case let .virtual(element): rawValue = element.accessibilityValue()
        }
        return rawValue as? String
    }

    var isEnabled: Bool {
        switch self {
        case let .view(view): view.isAccessibilityEnabled()
        case let .virtual(element): element.isAccessibilityEnabled()
        }
    }

    var children: [AccessibilityNode] {
        let rawChildren: [Any]?
        switch self {
        case let .view(view): rawChildren = view.accessibilityChildren()
        case let .virtual(element): rawChildren = element.accessibilityChildren()
        }
        return rawChildren?.compactMap(AccessibilityNode.init) ?? []
    }

}

private func accessibilityDescendants(of root: AccessibilityNode) -> [AccessibilityNode] {
    [root] + root.children.flatMap(accessibilityDescendants(of:))
}

@MainActor
private func exercise(_ kind: CompositionKind) throws -> Bool {
    var accessibilityWasAvailable = false

    do {
        let recorder = InteractionRecorder()
        let harness = try NativeInteractionHarness(
            rootView: composition(kind, isAvailable: true, isPending: false, recorder: recorder)
        )
        defer { harness.close() }
        try harness.validateFrames(recorder)
        try harness.movePointer(to: recorder.primaryFrame)
        try require(
            recorder.context.isContainerHovered,
            "\(kind.rawValue) did not publish hover context; \(harness.pointerDiagnostics(for: recorder.primaryFrame))"
        )
        try harness.moveContainerAwayFromPointer()
        try require(!recorder.context.isContainerHovered, "\(kind.rawValue) did not clear hover context")
        try harness.movePointer(to: recorder.primaryFrame)
        try require(recorder.context.isContainerHovered, "\(kind.rawValue) did not restore hover context")
        accessibilityWasAvailable = try harness.validateAccessibility(
            primaryLabel: "Play Synthetic Track",
            accessoryLabel: "Add Synthetic Track to saved items",
            accessoryValue: "Not saved",
            accessoryEnabled: true
        ) || accessibilityWasAvailable
        try harness.click(recorder.accessoryFrame)
        try require(recorder.accessoryActions == 1, "\(kind.rawValue) pointer accessory action count was \(recorder.accessoryActions)")
        try require(recorder.primaryActions == 0, "\(kind.rawValue) pointer accessory activated primary")
    }

    if NSApp.isFullKeyboardAccessEnabled {
        let recorder = InteractionRecorder()
        let harness = try NativeInteractionHarness(
            rootView: composition(kind, isAvailable: true, isPending: false, recorder: recorder)
        )
        defer { harness.close() }
        try harness.validateFrames(recorder)
        try harness.pressTab()
        try require(recorder.context.isContainerFocused, "\(kind.rawValue) primary did not publish keyboard focus context")
        try harness.pressTab()
        try require(!recorder.context.isContainerFocused, "\(kind.rawValue) primary retained focus after Tab reached accessory")
        try harness.pressSpace()
        try require(recorder.accessoryActions == 1, "\(kind.rawValue) keyboard accessory action count was \(recorder.accessoryActions)")
        try require(recorder.primaryActions == 0, "\(kind.rawValue) keyboard accessory activated primary")
    }

    do {
        let recorder = InteractionRecorder()
        let harness = try NativeInteractionHarness(
            rootView: composition(kind, isAvailable: true, isPending: false, recorder: recorder)
        )
        defer { harness.close() }
        try harness.validateFrames(recorder)
        try harness.click(recorder.primaryFrame)
        try require(recorder.primaryActions == 1, "\(kind.rawValue) primary action count was \(recorder.primaryActions)")
        try require(recorder.accessoryActions == 0, "\(kind.rawValue) primary activated accessory")
    }

    do {
        let recorder = InteractionRecorder()
        let harness = try NativeInteractionHarness(
            rootView: composition(kind, isAvailable: false, isPending: false, recorder: recorder)
        )
        defer { harness.close() }
        try harness.validateFrames(recorder)
        try harness.movePointer(to: recorder.primaryFrame)
        try harness.click(recorder.primaryFrame)
        try require(recorder.primaryActions == 0, "\(kind.rawValue) unavailable primary activated")
        try harness.click(recorder.accessoryFrame)
        try require(recorder.accessoryActions == 1, "\(kind.rawValue) valid accessory was suppressed by unavailable primary")
        try require(recorder.primaryActions == 0, "\(kind.rawValue) accessory activated unavailable primary")
    }

    do {
        let recorder = InteractionRecorder()
        let harness = try NativeInteractionHarness(
            rootView: composition(kind, isAvailable: true, isPending: true, recorder: recorder)
        )
        defer { harness.close() }
        try harness.validateFrames(recorder)
        accessibilityWasAvailable = try harness.validateAccessibility(
            primaryLabel: "Play Synthetic Track",
            accessoryLabel: "Add Synthetic Track to saved items",
            accessoryValue: "Saving",
            accessoryEnabled: false
        ) || accessibilityWasAvailable
        try harness.click(recorder.accessoryFrame)
        try require(recorder.accessoryActions == 0, "\(kind.rawValue) pending favorite activated")
        try require(recorder.primaryActions == 0, "\(kind.rawValue) pending favorite activated primary")
    }

    return accessibilityWasAvailable
}

@MainActor
private func playerPresentation(favorite: FavoritePresentation?) -> PlayerBarPresentation {
    PlayerBarPresentation(
        title: "Synthetic Track",
        subtitle: "Synthetic Artist",
        isPlaying: false,
        isShuffleEnabled: false,
        repeatMode: .off,
        progress: PlaybackProgressPresentation(
            progress: 0.5,
            leadingText: "2:01",
            trailingText: "4:02",
            accessibilityLabel: "Playback Position",
            isEnabled: true
        ),
        volume: 0.5,
        isMuted: false,
        isQueuePresented: false,
        favorite: favorite,
        showNowPlayingAccessibilityLabel: "Show Synthetic Track"
    )
}

@MainActor
private func playerActions(
    recorder: PlayerInteractionRecorder,
    includesOptionalActions: Bool
) -> PlayerBarActions {
    let toggleShuffle: (@MainActor @Sendable () -> Void)?
    let cycleRepeatMode: (@MainActor @Sendable () -> Void)?
    let setFavorite: (@MainActor @Sendable (Bool) -> Void)?
    if includesOptionalActions {
        toggleShuffle = { recorder.record("shuffle") }
        cycleRepeatMode = { recorder.record("repeat") }
        setFavorite = { _ in recorder.record("favorite") }
    } else {
        toggleShuffle = nil
        cycleRepeatMode = nil
        setFavorite = nil
    }
    return PlayerBarActions(
        showNowPlaying: { recorder.record("show") },
        togglePlayback: { recorder.record("play") },
        previous: { recorder.record("previous") },
        next: { recorder.record("next") },
        seek: { _ in recorder.record("seek") },
        setVolume: { _ in recorder.record("volume") },
        toggleMute: { recorder.record("mute") },
        showQueue: { recorder.record("queue") },
        toggleShuffle: toggleShuffle,
        cycleRepeatMode: cycleRepeatMode,
        setFavorite: setFavorite
    )
}

@MainActor
private func fullPlayerBar(recorder: PlayerInteractionRecorder) -> AnyView {
    let favorite = FavoritePresentation(
        isFavorite: false,
        isPending: false,
        isRevealed: true,
        accessibilityLabel: "Save Synthetic Track",
        accessibilityValue: "Not saved"
    )
    return AnyView(
        PlayerBar(
            presentation: playerPresentation(favorite: favorite),
            actions: playerActions(recorder: recorder, includesOptionalActions: true)
        ) {
            Color.blue
                .background(PlayerAccessoryFrameReporter(region: .artwork, recorder: recorder))
        } metadataAccessory: {
            Button("External Item") { recorder.record("external") }
                .background(PlayerAccessoryFrameReporter(region: .metadata, recorder: recorder))
        } statusAccessory: {
            Button("Playback Status") { recorder.record("status") }
                .background(PlayerAccessoryFrameReporter(region: .status, recorder: recorder))
        } routeAccessory: {
            Button("Audio Output") { recorder.record("route") }
                .background(PlayerAccessoryFrameReporter(region: .route, recorder: recorder))
        }
        .frame(width: 1_240, height: 160)
        .coordinateSpace(name: "player-interaction-host")
    )
}

@MainActor
private func exercisePlayerControls() throws {
    var transportFrames: [String: CGRect] = [:]
    do {
        let recorder = PlayerInteractionRecorder()
        let controls = TransportControls(
            presentation: playerPresentation(favorite: nil),
            actions: playerActions(recorder: recorder, includesOptionalActions: true)
        )
        let harness = try NativeInteractionHarness(
            rootView: AnyView(controls.frame(width: 520, height: 120)),
            size: CGSize(width: 520, height: 120)
        )
        defer { harness.close() }
        transportFrames = try discoverActionFrames(
            harness: harness,
            recorder: recorder,
            xRange: 0 ... 520,
            y: 60,
            expectedEvents: ["shuffle", "previous", "play", "next", "repeat"]
        )
        try require(
            Set(transportFrames.keys) == ["shuffle", "previous", "play", "next", "repeat"],
            "transport did not expose every visible action: \(transportFrames.keys.sorted())"
        )
        try require(recorder.events.values.allSatisfy { $0 == 1 }, "transport dispatched duplicate events: \(recorder.events)")
    }

    do {
        let recorder = PlayerInteractionRecorder()
        let controls = TransportControls(
            presentation: playerPresentation(favorite: nil),
            actions: playerActions(recorder: recorder, includesOptionalActions: false)
        )
        let harness = try NativeInteractionHarness(
            rootView: AnyView(controls.frame(width: 520, height: 120)),
            size: CGSize(width: 520, height: 120)
        )
        defer { harness.close() }
        for event in ["shuffle", "repeat"] {
            try harness.click(try requireValue(transportFrames[event], "missing full-action \(event) frame"))
        }
        try require(recorder.events.isEmpty, "missing optional transport actions dispatched events")
    }

    do {
        let recorder = PlayerInteractionRecorder()
        let harness = try NativeInteractionHarness(
            rootView: fullPlayerBar(recorder: recorder),
            size: CGSize(width: 1_240, height: 160)
        )
        defer { harness.close() }
        try harness.click(recorder.artworkFrame)
        try harness.click(recorder.metadataAccessoryFrame)
        let playerTransportFrames = try discoverActionFrames(
            harness: harness,
            recorder: recorder,
            xRange: 400 ... 950,
            y: recorder.artworkFrame.midY,
            expectedEvents: ["shuffle", "previous", "play", "next", "repeat", "favorite", "seek"]
        )
        try require(
            Set(playerTransportFrames.keys) == ["shuffle", "previous", "play", "next", "repeat", "favorite", "seek"],
            "player bar did not expose every visible transport action: \(playerTransportFrames.keys.sorted())"
        )
        let outputFrames = try discoverActionFrames(
            harness: harness,
            recorder: recorder,
            xRange: recorder.statusAccessoryFrame.minX ... 1_240,
            y: recorder.artworkFrame.midY,
            expectedEvents: ["status", "mute", "volume", "route", "queue"]
        )
        try require(
            Set(outputFrames.keys) == ["status", "mute", "volume", "route", "queue"],
            "player bar did not expose every visible output control: \(outputFrames.keys.sorted())"
        )
        try require(recorder.events.count == 14, "player bar missed visible controls: \(recorder.events)")
        try require(recorder.events.values.allSatisfy { $0 == 1 }, "player bar dispatched duplicate events: \(recorder.events)")
        try require(recorder.metadataAccessoryFrame.maxX < 620, "metadata accessory escaped the leading region")
        try require(recorder.statusAccessoryFrame.minX > 620, "status accessory escaped the output region")
        try require(recorder.routeAccessoryFrame.minX > 620, "route accessory escaped the output region")
        try require(recorder.statusAccessoryFrame != recorder.routeAccessoryFrame, "output accessories collapsed into one frame")
    }

    do {
        let recorder = PlayerInteractionRecorder()
        let harness = try NativeInteractionHarness(
            rootView: fullPlayerBar(recorder: recorder),
            size: CGSize(width: 1_240, height: 160)
        )
        defer { harness.close() }
        let queueHitColumns = try discoverHorizontalActionHitColumns(
            harness: harness,
            recorder: recorder,
            event: "queue",
            xRange: 1_170 ... 1_230,
            y: recorder.artworkFrame.midY
        )
        try require(
            queueHitColumns == Array(1_186 ... 1_219),
            "queue control did not expose the protected 34-point hit region: \(queueHitColumns)"
        )
    }

    do {
        let recorder = PlayerInteractionRecorder()
        let favorite = FavoritePresentation(
            isFavorite: false,
            isPending: false,
            isRevealed: true,
            accessibilityLabel: "Save Synthetic Track",
            accessibilityValue: "Not saved"
        )
        let bar = PlayerBar(
            presentation: playerPresentation(favorite: favorite),
            actions: playerActions(recorder: recorder, includesOptionalActions: false)
        ) { Color.blue }
        let harness = try NativeInteractionHarness(
            rootView: AnyView(bar.frame(width: 1_240, height: 160)),
            size: CGSize(width: 1_240, height: 160)
        )
        defer { harness.close() }
        let missingFrames = try discoverActionFrames(
            harness: harness,
            recorder: recorder,
            xRange: 400 ... 950,
            y: 80,
            expectedEvents: ["previous", "play", "next", "seek"]
        )
        try require(
            Set(missingFrames.keys) == ["previous", "play", "next", "seek"],
            "optional-action bar exposed an unexpected action: \(missingFrames.keys.sorted())"
        )
        try require(recorder.events.values.allSatisfy { $0 == 1 }, "optional-action bar dispatched duplicate events")
        try require(recorder.count("shuffle") == 0, "missing shuffle action activated")
        try require(recorder.count("repeat") == 0, "missing repeat action activated")
        try require(recorder.count("favorite") == 0, "missing favorite action activated")
    }
}

@MainActor
private func discoverActionFrames(
    harness: NativeInteractionHarness,
    recorder: PlayerInteractionRecorder,
    xRange: ClosedRange<CGFloat>,
    y: CGFloat,
    expectedEvents: Set<String>
) throws -> [String: CGRect] {
    var result: [String: CGRect] = [:]
    var x = xRange.lowerBound
    while x <= xRange.upperBound, Set(result.keys) != expectedEvents {
        let before = recorder.events
        let target = CGRect(x: x, y: y, width: 1, height: 1)
        try harness.click(target)
        let changed = recorder.events.filter { event, count in
            count != before[event, default: 0]
        }
        if let event = changed.keys.first {
            try require(changed.count == 1, "one pointer activation dispatched multiple actions: \(changed)")
            try require(expectedEvents.contains(event), "unexpected action \(event) while discovering controls")
            try require(result[event] == nil, "action \(event) was reachable from multiple scan points")
            try require(recorder.count(event) == 1, "action \(event) dispatched more than once")
            result[event] = target
            x += event == "volume" ? 90 : 38
        } else {
            x += 3
        }
    }
    return result
}

@MainActor
private func discoverHorizontalActionHitColumns(
    harness: NativeInteractionHarness,
    recorder: PlayerInteractionRecorder,
    event: String,
    xRange: ClosedRange<Int>,
    y: CGFloat
) throws -> [Int] {
    var hitColumns: [Int] = []
    for x in xRange {
        let before = recorder.count(event)
        try harness.click(CGRect(x: CGFloat(x), y: y, width: 1, height: 1))
        let after = recorder.count(event)
        try require(after == before || after == before + 1, "one pointer click dispatched \(event) repeatedly")
        if after == before + 1 {
            hitColumns.append(x)
        }
    }
    return hitColumns
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw HostFailure.assertion(message) }
}

private func requireValue<Value>(_ value: Value?, _ message: String) throws -> Value {
    guard let value else { throw HostFailure.assertion(message) }
    return value
}

@MainActor
private func run() throws {
    try require(NSApp.activationPolicy() == .regular, "application host is not a regular app")

    try exercisePlayerControls()
    print("PLAYER_INTERACTION_HOST_OK")

    var accessibilityWasAvailable = false
    for kind in CompositionKind.allCases {
        accessibilityWasAvailable = try exercise(kind) || accessibilityWasAvailable
    }
    if !accessibilityWasAvailable {
        print("MEDIA_INTERACTION_HOST_AX_UNAVAILABLE")
    }
    if !NSApp.isFullKeyboardAccessEnabled {
        print("MEDIA_INTERACTION_HOST_KEYBOARD_FOCUS_UNAVAILABLE")
    }
}

private final class ApplicationDelegate: NSObject, NSApplicationDelegate {
    private let configuration: HostConfiguration
    private var hangWindow: NSWindow?

    init(configuration: HostConfiguration) {
        self.configuration = configuration
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate()
        if configuration.shouldHangForCleanupTest {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 240, height: 120),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Media cleanup regression host"
            window.makeKeyAndOrderFront(nil)
            hangWindow = window
            try? writeHostState("HANG_READY\n", to: configuration.resultPath)

            // A hard test-only watchdog prevents an infrastructure failure from
            // leaving the deliberately hung regression host alive indefinitely.
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                exit(86)
            }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            do {
                if self.configuration.shouldRunPlayerOnly {
                    try exercisePlayerControls()
                    print("PLAYER_INTERACTION_HOST_OK")
                } else {
                    try run()
                }
                try writeHostState("OK\n", to: self.configuration.resultPath)
                print("MEDIA_INTERACTION_HOST_OK")
                exit(0)
            } catch {
                try? writeHostState("FAILURE: \(error)\n", to: self.configuration.resultPath)
                print("MEDIA_INTERACTION_HOST_FAILURE: \(error)")
                exit(1)
            }
        }
    }
}

private let hostConfiguration = HostConfiguration.current()
do {
    try writeHostState("\(ProcessInfo.processInfo.processIdentifier)\n", to: hostConfiguration.pidPath)
} catch {
    print("MEDIA_INTERACTION_HOST_FAILURE: could not record process identifier: \(error)")
    exit(1)
}

let application = NSApplication.shared
if application.activationPolicy() != .regular {
    guard application.setActivationPolicy(.regular) else {
        print("MEDIA_INTERACTION_HOST_FAILURE: could not enable application activation policy")
        exit(1)
    }
}
private let applicationDelegate = ApplicationDelegate(configuration: hostConfiguration)
application.delegate = applicationDelegate
application.run()
