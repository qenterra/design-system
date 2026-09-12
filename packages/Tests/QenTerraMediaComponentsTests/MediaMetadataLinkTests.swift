#if os(macOS)
import AppKit
import QenTerraMediaComponents
import SwiftUI
import Testing

@Test @MainActor func metadataLinkRendersCallerTextWithoutApplicationServices() throws {
    let renderer = ImageRenderer(
        content: MediaMetadataLink(
            "Artist — Исполнитель — 100%",
            accessibilityLabel: "Open artist details"
        ) {}
        .frame(width: 180, height: 32)
    )
    renderer.scale = 1
    let image = try #require(renderer.cgImage)
    #expect(image.width == 180)
    #expect(image.height == 32)
}

@Test @MainActor func metadataLinkHighlightFreezePreservesItsAction() throws {
    for freezesHighlights in [false, true] {
        var actionCount = 0
        let content = MediaMetadataLink(
            "Open Artist",
            accessibilityLabel: "Open artist details",
            freezesInteractionHighlights: freezesHighlights
        ) {
            actionCount += 1
        }
        .frame(width: 180, height: 40)
        let host = NSHostingView(rootView: content)
        host.sizingOptions = []
        host.frame = CGRect(x: 0, y: 0, width: 180, height: 40)
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 180, height: 40),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = host
        window.makeKeyAndOrderFront(nil)
        defer { window.close() }
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        host.layoutSubtreeIfNeeded()

        let timestamp = ProcessInfo.processInfo.systemUptime
        let location = CGPoint(x: 90, y: 20)
        let down = try #require(NSEvent.mouseEvent(
            with: .leftMouseDown,
            location: location,
            modifierFlags: [],
            timestamp: timestamp,
            windowNumber: window.windowNumber,
            context: nil,
            eventNumber: 1,
            clickCount: 1,
            pressure: 1
        ))
        let up = try #require(NSEvent.mouseEvent(
            with: .leftMouseUp,
            location: location,
            modifierFlags: [],
            timestamp: timestamp + 0.01,
            windowNumber: window.windowNumber,
            context: nil,
            eventNumber: 2,
            clickCount: 1,
            pressure: 0
        ))
        window.sendEvent(down)
        window.sendEvent(up)
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        #expect(actionCount == 1)
    }
}
#endif
