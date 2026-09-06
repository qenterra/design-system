#if os(macOS)
import AppKit
import QenTerraDesignTokens
@testable import QenTerraMediaComponents
import Testing

@Test @MainActor func nativeCellPublishesCropAndRetainsMenuEventAndAnchorAcrossReuse() throws {
    let cell = NativeMediaTableCell()
    let image = try #require(NSImage(size: NSSize(width: 4, height: 4), flipped: false) { rect in
        NSColor.red.setFill()
        rect.fill()
        return true
    }.cgImage(forProposedRect: nil, context: nil, hints: nil))
    var requests: [MediaTableArtworkRequest<Int>] = []
    var observed: [(Int, NSEvent)] = []
    var anchors: [(Int, NSButton)] = []
    let menu = NSMenu()
    let event = try #require(NSEvent.mouseEvent(
        with: .rightMouseDown, location: NSPoint(x: 31, y: 17), modifierFlags: [.command],
        timestamp: 0, windowNumber: 0, context: nil, eventNumber: 1, clickCount: 1, pressure: 1
    ))
    for id in [1, 2] {
        cell.configure(
            presentation: MediaTableRowPresentation(
                id: id, title: "Track", creator: "Creator", collection: "Collection",
                year: "2026", duration: "3:42", isExplicit: false, isFavorite: false,
                isCurrent: true, isPlaying: true, isAvailable: true, artworkIdentity: "same",
                favoriteAccessibilityLabel: "Save to collection", actionsAccessibilityLabel: "Track commands"
            ), state: .standard, requestArtwork: { requests.append($0) },
            actions: NativeMediaTableActions<Int>(
                actionsMenu: { anchors.append(($0, $1)) },
                contextMenu: { observed.append(($0, $1)); return menu }
            )
        )
        #expect(cell.menu(for: event) === menu)
        cell.performAction(.actions)
    }
    let crop = CGRect(x: 0.25, y: 0.125, width: 0.5, height: 0.75)
    #expect(!cell.publishArtwork(image, for: requests[0], contentsRect: crop))
    #expect(cell.publishArtwork(image, for: requests[1], contentsRect: crop))
    #expect(cell.publishedArtworkContentsRect == crop)
    #expect(observed.map(\.0) == [1, 2])
    #expect(observed.allSatisfy { $0.1 === event })
    #expect(anchors.map(\.0) == [1, 2])
    #expect(anchors[0].1 === anchors[1].1)
    #expect(anchors[0].1.superview === cell)
    #expect(anchors[0].1.accessibilityLabel() == "Track commands")
    #expect(anchors[0].1.toolTip == "Track commands")
    #expect(!cell.publishArtwork(image, for: requests[1], contentsRect: CGRect(x: -0.1, y: 0, width: 1, height: 1)))
    #expect(cell.publishedArtworkContentsRect == crop)
    cell.configurePlaceholder(label: "Loading…", accessibilityLabel: "Loading track", state: .standard)
    #expect(cell.representedItemID == nil)
    #expect(cell.publishedArtworkContentsRect == CGRect(x: 0, y: 0, width: 1, height: 1))
    #expect(cell.accessibilityLabel() == "Loading track")
    #expect(cell.menu(for: event) == nil)
    cell.performAction(.actions)
    #expect(anchors.count == 2)
    #expect(!cell.publishArtwork(image, for: requests[1], contentsRect: crop))
}

@Test @MainActor func nativeConfigureObservationMeasuresActualContentAndLayoutWork() {
    let cell = NativeMediaTableCell()
    let row = MediaTableRowPresentation(
        id: 1, title: "Track", creator: "Creator", collection: "Collection", year: "", duration: "",
        isExplicit: false, isFavorite: false, isCurrent: false, isPlaying: false,
        isAvailable: true, artworkIdentity: nil
    )
    let first = cell.configure(presentation: row, state: .standard)
    let selection = cell.configure(presentation: row, state: MediaTableCellState(isSelected: true))
    #expect(first.contentApplied && first.layoutInvalidated)
    #expect(!selection.contentApplied && !selection.layoutInvalidated)
}

@Test @MainActor func nativeConsumerGeometryAndPrimaryTintAreExplicitOptIns() throws {
    let cell = NativeMediaTableCell(frame: CGRect(x: 0, y: 0, width: 900, height: 58))
    let row = MediaTableRowPresentation(
        id: 1, title: "Track", creator: "Creator", collection: "Collection", year: "", duration: "",
        isExplicit: false, isFavorite: false, isCurrent: false, isPlaying: false,
        isAvailable: true, artworkIdentity: nil
    )
    let environment = DesignNativeEnvironment(
        appearance: .light, productProfile: .cadence, density: .standard,
        isIncreasedContrast: false, reducesMotion: true, reducesTransparency: false
    )
    cell.configure(presentation: row, state: MediaTableCellState(environment: environment))
    cell.setPointerHovered(true)
    cell.layoutSubtreeIfNeeded()
    let actions = try #require(cell.subviews.first { $0.identifier?.rawValue == "media-table.actions" } as? NSButton)
    let artwork = try #require(cell.subviews.first { $0.identifier?.rawValue == "media-table.artwork" })
    #expect(actions.contentTintColor == .labelColor)
    #expect(artwork.frame.minX == 66)
    let update = cell.configure(
        presentation: row,
        state: MediaTableCellState(environment: environment, favoriteControlWidth: 22, usesPrimaryActionTint: true)
    )
    cell.layoutSubtreeIfNeeded()
    #expect(update.layoutInvalidated && !update.contentApplied)
    #expect(artwork.frame.minX == 58)
    let actualTint = try #require(actions.contentTintColor?.usingColorSpace(.sRGB))
    let expectedTint = try #require(NSColor.designToken(DesignTokens.Color.actionPrimary).usingColorSpace(.sRGB))
    #expect(abs(actualTint.redComponent - expectedTint.redComponent) < 0.000_001)
    #expect(abs(actualTint.greenComponent - expectedTint.greenComponent) < 0.000_001)
    #expect(abs(actualTint.blueComponent - expectedTint.blueComponent) < 0.000_001)
    #expect(MediaTableCellState(favoriteControlWidth: .nan).favoriteControlWidth == 30)
}
#endif
