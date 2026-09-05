#if os(macOS)
import AppKit
import QenTerraDesignTokens
@testable import QenTerraMediaComponents
import SwiftUI
import Testing

@Test func tableGeometryPreservesCompactAndStandardCadenceLayouts() {
    let compact = MediaTableGeometry(density: .compact)
    #expect(compact.rowHeight == 50)
    #expect(compact.headerHeight == 34)
    #expect(compact.artworkSize == 34)

    let standard = MediaTableGeometry(density: .standard)
    #expect(standard.rowHeight == 58)
    #expect(standard.headerHeight == 38)
    #expect(standard.artworkSize == 40)
    #expect(standard.horizontalInset == 24)
    #expect(standard.selectionHorizontalInset == 8)
    #expect(standard.columnSpacing == 12)
    #expect(standard.actionWidth == 28)
    #expect(standard.favoriteControlWidth == 30)
    #expect(standard.minimumSongWidth == 360)
    #expect(standard.fixedWidth(for: .collection) == 190)
    #expect(standard.fixedWidth(for: .year) == 64)
    #expect(standard.fixedWidth(for: .duration) == 64)

    let widths = standard.resolvedWidths(
        availableWidth: 900,
        columns: [.collection, .year, .duration]
    )
    #expect(widths.title == 446)
    #expect(widths.collection == 190)
    #expect(widths.year == 64)
    #expect(widths.duration == 64)
}

@Test func tableGeometryRejectsNonfiniteWidthsWithoutTrapping() {
    let geometry = MediaTableGeometry(density: .standard)
    let invalid = geometry.resolvedWidths(
        availableWidth: .nan,
        columns: [.collection, .year]
    )
    #expect(invalid == MediaTableResolvedWidths(title: 1, collection: 190, year: 64, duration: 0))
    let huge = geometry.resolvedWidths(
        availableWidth: .greatestFiniteMagnitude,
        columns: [.duration]
    )
    #expect(huge.title.isFinite)
    #expect(huge.duration == 64)
}

@Test func tableRowPresentationKeepsGenericIdentityAndLiteralState() {
    let row = syntheticRow(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
        isExplicit: true,
        isFavorite: true,
        isCurrent: true,
        isPlaying: true,
        isAvailable: false,
        artworkIdentity: "artwork-11"
    )
    #expect(row.id.uuidString == "00000000-0000-0000-0000-000000000011")
    #expect(row.title == "Synthetic Track")
    #expect(row.creator == "Synthetic Creator")
    #expect(row.collection == "Synthetic Collection")
    #expect(row.year == "2026")
    #expect(row.duration == "3:42")
    #expect(row.isExplicit)
    #expect(row.isFavorite)
    #expect(row.isCurrent)
    #expect(row.isPlaying)
    #expect(!row.isAvailable)
    #expect(row.artworkIdentity == "artwork-11")
}

@Test @MainActor func nativeCellKeepsOneStableRenderHierarchyAcrossOneThousandReconfigures() {
    let cell = NativeMediaTableCell(frame: CGRect(x: 0, y: 0, width: 900, height: 58))
    let hierarchy = cell.renderHierarchyIdentity
    let layerCount = cell.renderLayerCount
    var requested: [(Int, String)] = []

    for index in 0 ..< 1_000 {
        cell.configure(
            presentation: syntheticRow(id: index, artworkIdentity: "artwork-\(index)"),
            state: .standard,
            columns: [.collection, .year, .duration],
            widths: MediaTableResolvedWidths(title: 446, collection: 190, year: 64, duration: 64),
            requestArtwork: { requested.append(($0, $1)) },
            onAction: { _, _ in }
        )
    }

    #expect(cell.renderHierarchyIdentity == hierarchy)
    #expect(cell.renderLayerCount == layerCount)
    #expect(cell.representedItemID == AnyHashable(999))
    #expect(requested.count == 1_000)
    #expect(requested.last?.0 == 999)
    #expect(requested.last?.1 == "artwork-999")
}

@Test @MainActor func nativeCellUsesActualCompactAndStandardSubviewFrames() throws {
    let cell = NativeMediaTableCell(frame: CGRect(x: 0, y: 0, width: 900, height: 58))
    cell.configure(
        presentation: syntheticRow(id: "standard", isExplicit: true),
        state: .standard,
        columns: [.collection, .year, .duration],
        widths: MediaTableResolvedWidths(title: 446, collection: 190, year: 64, duration: 64)
    )
    cell.layoutSubtreeIfNeeded()

    let standardArtwork = try #require(cell.descendant(identifier: "media-table.artwork"))
    let standardFavorite = try #require(cell.descendant(identifier: "media-table.favorite"))
    let standardTitle = try #require(cell.descendant(identifier: "media-table.title"))
    let standardAction = try #require(cell.descendant(identifier: "media-table.actions"))
    #expect(standardFavorite.frame == CGRect(x: 24, y: 14, width: 30, height: 30))
    #expect(standardArtwork.frame == CGRect(x: 66, y: 9, width: 40, height: 40))
    #expect(standardTitle.frame == CGRect(x: 114, y: 30, width: 333, height: 19))
    #expect(standardAction.frame == CGRect(x: 848, y: 15, width: 28, height: 28))

    cell.frame.size.height = 50
    cell.configure(
        presentation: syntheticRow(id: "compact", isExplicit: false),
        state: .compact,
        columns: [.duration],
        widths: MediaTableResolvedWidths(title: 724, collection: 0, year: 0, duration: 64)
    )
    cell.layoutSubtreeIfNeeded()
    let compactArtwork = try #require(cell.descendant(identifier: "media-table.artwork"))
    let compactTitle = try #require(cell.descendant(identifier: "media-table.title"))
    #expect(compactArtwork.frame == CGRect(x: 66, y: 8, width: 34, height: 34))
    #expect(compactTitle.frame == CGRect(x: 108, y: 26, width: 640, height: 19))
}

@Test @MainActor func hoverResetsWhenRepresentedIdentityChanges() throws {
    let cell = NativeMediaTableCell()
    cell.configure(presentation: syntheticRow(id: "track-a"), state: .standard)
    cell.setPointerHovered(true)
    #expect(cell.isPointerHovered)
    #expect(!(try #require(cell.descendant(identifier: "media-table.favorite"))).isHidden)

    cell.configure(presentation: syntheticRow(id: "track-b"), state: .standard)
    #expect(!cell.isPointerHovered)
    #expect((try #require(cell.descendant(identifier: "media-table.favorite"))).isHidden)
}

@Test @MainActor func selectedFocusedHoveredAndUnavailableRemainDistinct() throws {
    let cell = NativeMediaTableCell(frame: CGRect(x: 0, y: 0, width: 900, height: 58))
    cell.configure(
        presentation: syntheticRow(id: "focus-only"),
        state: MediaTableCellState(isFocused: true)
    )
    #expect(cell.isAccessibilitySelected() == false)
    #expect(cell.selectionLayerBorderWidth == 0.5)
    #expect(cell.selectionLayerBackgroundAlpha == 0)

    cell.configure(
        presentation: syntheticRow(id: "selected"),
        state: MediaTableCellState(isSelected: true)
    )
    #expect(cell.isAccessibilitySelected() == true)
    #expect(cell.selectionLayerBackgroundAlpha > 0)

    cell.setPointerHovered(true)
    #expect(cell.selectionLayerBackgroundAlpha > 0)

    var actions: [(String, NativeMediaTableAction)] = []
    cell.configure(
        presentation: syntheticRow(id: "unavailable", isAvailable: false),
        state: .standard,
        onAction: { actions.append(($0, $1)) }
    )
    let favorite = try #require(cell.descendant(identifier: "media-table.favorite") as? NSButton)
    #expect(!favorite.isEnabled)
    cell.performAction(.favorite)
    cell.performAction(.play)
    #expect(actions.isEmpty)
    #expect(cell.contentOpacity < 1)
}

@Test @MainActor func explicitFavoriteCurrentAndPlaybackChromeFollowPresentation() throws {
    let cell = NativeMediaTableCell()
    cell.configure(
        presentation: syntheticRow(
            id: "playing",
            isExplicit: true,
            isFavorite: true,
            isCurrent: true,
            isPlaying: true
        ),
        state: .standard
    )

    let explicit = try #require(cell.descendant(identifier: "media-table.explicit"))
    let favorite = try #require(cell.descendant(identifier: "media-table.favorite") as? NSButton)
    let play = try #require(cell.descendant(identifier: "media-table.artwork") as? NSButton)
    let indicator = try #require(cell.subviews.first { $0 is NativePlaybackIndicatorView } as? NativePlaybackIndicatorView)
    #expect(!explicit.isHidden)
    #expect(!favorite.isHidden)
    #expect(favorite.image?.isTemplate == true)
    #expect(play.isHidden)
    #expect(!indicator.isHidden)
    #expect(indicator.isAnimating)

    cell.configure(
        presentation: syntheticRow(id: "paused", isCurrent: true, isPlaying: false),
        state: .standard
    )
    #expect(explicit.isHidden)
    #expect(favorite.isHidden)
    #expect(!play.isHidden)
    #expect(indicator.isHidden)
    #expect(!indicator.isAnimating)
}

@Test @MainActor func increasedContrastStrengthensFocusWithoutChangingSelectionSemantics() {
    let normal = NativeMediaTableCell()
    normal.configure(
        presentation: syntheticRow(id: "normal"),
        state: MediaTableCellState(isFocused: true, environment: nativeEnvironment())
    )
    let increased = NativeMediaTableCell()
    increased.configure(
        presentation: syntheticRow(id: "increased"),
        state: MediaTableCellState(
            isFocused: true,
            environment: nativeEnvironment(isIncreasedContrast: true)
        )
    )

    #expect(normal.selectionLayerBorderWidth == 0.5)
    #expect(increased.selectionLayerBorderWidth == 2)
    #expect(normal.isAccessibilitySelected() == false)
    #expect(increased.isAccessibilitySelected() == false)
}

@Test @MainActor func reducedMotionUsesStaticPlaybackBars() throws {
    let cell = NativeMediaTableCell()
    let playing = syntheticRow(id: "playing", isCurrent: true, isPlaying: true)
    cell.configure(
        presentation: playing,
        state: MediaTableCellState(environment: nativeEnvironment(reducesMotion: true))
    )
    let indicator = try #require(cell.subviews.first { $0 is NativePlaybackIndicatorView } as? NativePlaybackIndicatorView)
    #expect(!indicator.isAnimating)
    #expect(indicator.animationCount == 0)

    cell.configure(
        presentation: playing,
        state: MediaTableCellState(environment: nativeEnvironment(reducesMotion: false))
    )
    #expect(indicator.isAnimating)
    #expect(indicator.animationCount == 3)
}

@Test @MainActor func cellDisablesImplicitLayerActionsAndRejectsStaleArtworkPublication() throws {
    let cell = NativeMediaTableCell()
    var requests: [(String, String)] = []
    cell.configure(
        presentation: syntheticRow(id: "track-a", artworkIdentity: "art-a"),
        state: .standard,
        requestArtwork: { requests.append(($0, $1)) }
    )
    cell.configure(
        presentation: syntheticRow(id: "track-b", artworkIdentity: "art-b"),
        state: .standard,
        requestArtwork: { requests.append(($0, $1)) }
    )

    let image = try makeOnePixelImage()
    #expect(!cell.publishArtwork(image, forItemID: "track-a", artworkIdentity: "art-a"))
    #expect(cell.publishedArtworkIdentity == nil)
    #expect(cell.publishArtwork(image, forItemID: "track-b", artworkIdentity: "art-b"))
    #expect(cell.publishedArtworkIdentity == "art-b")
    #expect(requests.map(\.0) == ["track-a", "track-b"])
    #expect(cell.hasDisabledImplicitLayerActions)
}

@Test @MainActor func hiddenArtworkDefersItsRequestUntilTheArtworkColumnBecomesVisible() {
    let cell = NativeMediaTableCell()
    var requests: [(String, String)] = []
    let row = syntheticRow(id: "track", artworkIdentity: "art")

    cell.configure(
        presentation: row,
        state: MediaTableCellState(showsArtwork: false),
        requestArtwork: { requests.append(($0, $1)) }
    )
    #expect(requests.isEmpty)

    cell.configure(
        presentation: row,
        state: MediaTableCellState(showsArtwork: true),
        requestArtwork: { requests.append(($0, $1)) }
    )
    #expect(requests.count == 1)
    #expect(requests.first?.0 == "track")
    #expect(requests.first?.1 == "art")
}

@Test @MainActor func nativeCellRemovalClearsIdentityHoverArtworkAndPlaybackAnimations() throws {
    let host = NSView()
    let cell = NativeMediaTableCell()
    host.addSubview(cell)
    cell.configure(
        presentation: syntheticRow(
            id: "track",
            isCurrent: true,
            isPlaying: true,
            artworkIdentity: "art"
        ),
        state: .standard
    )
    cell.setPointerHovered(true)
    #expect(cell.publishArtwork(try makeOnePixelImage(), forItemID: "track", artworkIdentity: "art"))
    cell.removeFromSuperview()

    let indicator = try #require(cell.subviews.first { $0 is NativePlaybackIndicatorView } as? NativePlaybackIndicatorView)
    #expect(cell.representedItemID == nil)
    #expect(cell.publishedArtworkIdentity == nil)
    #expect(!cell.isPointerHovered)
    #expect(!indicator.isAnimating)
    #expect(indicator.animationCount == 0)
}

@Test @MainActor func nativeTableDispatchesReturnSpaceAndDeleteForTheExactAvailableIdentity() throws {
    let table = NativeMediaTableView()
    var target = (id: "track-a", isAvailable: true)
    var events: [(String, NativeMediaTableAction)] = []
    table.configureKeyboardActions(
        target: { target },
        onAction: { events.append(($0, $1)) }
    )

    table.keyDown(with: try keyEvent(keyCode: 36))
    table.keyDown(with: try keyEvent(keyCode: 49))
    table.keyDown(with: try keyEvent(keyCode: 51))
    #expect(events.map(\.0) == ["track-a", "track-a", "track-a"])
    #expect(events.map(\.1) == [.play, .togglePlayback, .delete])

    target = (id: "track-b", isAvailable: false)
    table.keyDown(with: try keyEvent(keyCode: 36))
    table.keyDown(with: try keyEvent(keyCode: 49))
    table.keyDown(with: try keyEvent(keyCode: 117))
    #expect(events.count == 3)
}

@Test @MainActor func nativeTablePublishesFirstResponderFocusIndependentlyOfSelection() {
    let frame = CGRect(x: 0, y: 0, width: 400, height: 200)
    let window = NSWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
    let table = NativeMediaTableView(frame: frame)
    let other = NSTextField(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
    window.contentView = NSView(frame: frame)
    window.contentView?.addSubview(table)
    window.contentView?.addSubview(other)
    var focusEvents: [Bool] = []
    table.onFocusChange = { focusEvents.append($0) }

    #expect(window.makeFirstResponder(table))
    #expect(table.hasTableFocus)
    #expect(table.selectedRowIndexes.isEmpty)
    #expect(window.makeFirstResponder(other))
    #expect(!table.hasTableFocus)
    #expect(focusEvents == [true, false])
}

@Test @MainActor func placeholderRendersDensityHeightAndOptionalArtworkWithoutOwningData() throws {
    func image(density: DesignDensity, showsArtwork: Bool) throws -> CGImage {
        let renderer = ImageRenderer(
            content: MediaTablePlaceholderRow(density: density, showsArtwork: showsArtwork)
                .frame(width: 500)
        )
        renderer.scale = 1
        return try #require(renderer.cgImage)
    }

    #expect(try image(density: .compact, showsArtwork: true).height == 50)
    #expect(try image(density: .standard, showsArtwork: false).height == 58)
}

private func syntheticRow<ID: Hashable & Sendable>(
    id: ID,
    isExplicit: Bool = false,
    isFavorite: Bool = false,
    isCurrent: Bool = false,
    isPlaying: Bool = false,
    isAvailable: Bool = true,
    artworkIdentity: String? = nil
) -> MediaTableRowPresentation<ID> {
    MediaTableRowPresentation(
        id: id,
        title: "Synthetic Track",
        creator: "Synthetic Creator",
        collection: "Synthetic Collection",
        year: "2026",
        duration: "3:42",
        isExplicit: isExplicit,
        isFavorite: isFavorite,
        isCurrent: isCurrent,
        isPlaying: isPlaying,
        isAvailable: isAvailable,
        artworkIdentity: artworkIdentity
    )
}

private func nativeEnvironment(
    isIncreasedContrast: Bool = false,
    reducesMotion: Bool = false
) -> DesignNativeEnvironment {
    DesignNativeEnvironment(
        appearance: .light,
        productProfile: .cadence,
        density: .standard,
        isIncreasedContrast: isIncreasedContrast,
        reducesMotion: reducesMotion,
        reducesTransparency: false
    )
}

@MainActor
private func keyEvent(keyCode: UInt16) throws -> NSEvent {
    try #require(
        NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "",
            charactersIgnoringModifiers: "",
            isARepeat: false,
            keyCode: keyCode
        )
    )
}

private func makeOnePixelImage() throws -> CGImage {
    let colorSpace = try #require(CGColorSpace(name: CGColorSpace.sRGB))
    let context = try #require(
        CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    )
    context.setFillColor(NSColor.systemBlue.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
    return try #require(context.makeImage())
}

private extension NSView {
    func descendant(identifier: String) -> NSView? {
        if self.identifier?.rawValue == identifier { return self }
        return subviews.lazy.compactMap { $0.descendant(identifier: identifier) }.first
    }
}
#endif
