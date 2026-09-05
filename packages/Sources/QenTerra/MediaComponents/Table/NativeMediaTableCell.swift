#if os(macOS)
import AppKit
import QenTerraDesignTokens
import QuartzCore

@MainActor
private final class MediaTableMetadataControl: NSTextField {
    var hoverChanged: (@MainActor () -> Void)?
    private(set) var isPointerHovered = false
    private var hoverTrackingArea: NSTrackingArea?

    override var acceptsFirstResponder: Bool { isEnabled }

    override func updateTrackingAreas() {
        if let hoverTrackingArea { removeTrackingArea(hoverTrackingArea) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeInActiveApp, .inVisibleRect, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        hoverTrackingArea = area
        super.updateTrackingAreas()
    }

    override func mouseEntered(with _: NSEvent) { setPointerHovered(true) }
    override func mouseExited(with _: NSEvent) { setPointerHovered(false) }

    override func mouseDown(with _: NSEvent) {
        guard isEnabled else { return }
        window?.makeFirstResponder(self)
        sendConfiguredAction()
    }

    override func keyDown(with event: NSEvent) {
        guard isEnabled else {
            super.keyDown(with: event)
            return
        }
        switch event.keyCode {
        case 36, 49: sendConfiguredAction()
        default: super.keyDown(with: event)
        }
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: isEnabled ? .pointingHand : .arrow)
    }

    func setPointerHovered(_ value: Bool) {
        guard isPointerHovered != value else { return }
        isPointerHovered = value
        hoverChanged?()
    }

    func resetPointerHover() { isPointerHovered = false }

    private func sendConfiguredAction() {
        guard let action else { return }
        NSApp.sendAction(action, to: target, from: self)
    }
}

@MainActor
public final class NativeMediaTableCell: NSTableCellView {
    private struct Presentation: Equatable {
        let id: AnyHashable
        let title: String
        let creator: String
        let collection: String
        let year: String
        let duration: String
        let isExplicit: Bool
        let isFavorite: Bool
        let isCurrent: Bool
        let isPlaying: Bool
        let isAvailable: Bool
        let artworkIdentity: String?
    }

    private static let disabledLayerActions: [String: any CAAction] = [
        "anchorPoint": NSNull(),
        "backgroundColor": NSNull(),
        "borderColor": NSNull(),
        "borderWidth": NSNull(),
        "bounds": NSNull(),
        "contents": NSNull(),
        "contentsRect": NSNull(),
        "cornerRadius": NSNull(),
        "opacity": NSNull(),
        "position": NSNull(),
        "sublayers": NSNull(),
        "transform": NSNull(),
    ]
    private static let emptyHeartImage = NSImage(systemSymbolName: "heart", accessibilityDescription: nil)
    private static let filledHeartImage = NSImage(systemSymbolName: "heart.fill", accessibilityDescription: nil)
    private static let playImage = NSImage(systemSymbolName: "play.fill", accessibilityDescription: nil)

    private let selectionLayer = CALayer()
    private let artworkLayer = CALayer()
    private let artworkOverlayLayer = CALayer()
    private let favoriteButton = NSButton()
    private let artworkButton = NSButton()
    private let playbackIndicator = NativePlaybackIndicatorView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let creatorButton = MediaTableMetadataControl()
    private let explicitLabel = NSTextField(labelWithString: "E")
    private let collectionButton = MediaTableMetadataControl()
    private let yearLabel = NSTextField(labelWithString: "")
    private let durationLabel = NSTextField(labelWithString: "")
    private let actionButton = NSButton()

    private var hoverTrackingArea: NSTrackingArea?
    private var presentation: Presentation?
    private var state = MediaTableCellState.standard
    private var columns: [MediaTableColumn] = []
    private var widths = MediaTableResolvedWidths(title: 360, collection: 190, year: 64, duration: 64)
    private var actionHandler: (@MainActor (NativeMediaTableAction) -> Void)?
    private var representedArtworkIdentity: String?

    public private(set) var representedItemID: AnyHashable?
    public private(set) var publishedArtworkIdentity: String?
    public private(set) var isPointerHovered = false
    public private(set) var contentOpacity: Double = 1

    public override init(frame frameRect: NSRect = .zero) {
        super.init(frame: frameRect)
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
        layer?.masksToBounds = false
        layer?.actions = Self.disabledLayerActions
        for managedLayer in [selectionLayer, artworkLayer, artworkOverlayLayer] {
            managedLayer.cornerRadius = CGFloat(DesignTokens.Radius.control)
            managedLayer.actions = Self.disabledLayerActions
            layer?.addSublayer(managedLayer)
        }
        artworkLayer.masksToBounds = true
        configureSubviews()
        setAccessibilityElement(true)
        setAccessibilityRole(.row)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { nil }

    public var renderHierarchyIdentity: [ObjectIdentifier] {
        [
            ObjectIdentifier(selectionLayer),
            ObjectIdentifier(artworkLayer),
            ObjectIdentifier(artworkOverlayLayer),
        ] + subviews.map(ObjectIdentifier.init)
    }

    public var renderLayerCount: Int {
        func count(_ layer: CALayer) -> Int {
            1 + (layer.sublayers ?? []).reduce(0) { $0 + count($1) }
        }
        return layer.map(count) ?? 0
    }

    public var hasDisabledImplicitLayerActions: Bool {
        let keys = Array(Self.disabledLayerActions.keys)
        let layers = [layer, selectionLayer, artworkLayer, artworkOverlayLayer].compactMap { $0 }
        return layers.allSatisfy { candidate in
            keys.allSatisfy { candidate.actions?[$0] is NSNull }
        }
    }

    var selectionLayerBorderWidth: CGFloat { selectionLayer.borderWidth }
    var selectionLayerBackgroundAlpha: CGFloat { selectionLayer.backgroundColor?.alpha ?? 0 }

    public func configure<ID: Hashable & Sendable>(
        presentation: MediaTableRowPresentation<ID>,
        state: MediaTableCellState,
        columns: [MediaTableColumn] = [],
        widths: MediaTableResolvedWidths = MediaTableResolvedWidths(
            title: 360,
            collection: 190,
            year: 64,
            duration: 64
        ),
        requestArtwork: (@MainActor (ID, String) -> Void)? = nil,
        onAction: (@MainActor (ID, NativeMediaTableAction) -> Void)? = nil
    ) {
        let next = Presentation(
            id: AnyHashable(presentation.id),
            title: presentation.title,
            creator: presentation.creator,
            collection: presentation.collection,
            year: presentation.year,
            duration: presentation.duration,
            isExplicit: presentation.isExplicit,
            isFavorite: presentation.isFavorite,
            isCurrent: presentation.isCurrent,
            isPlaying: presentation.isPlaying,
            isAvailable: presentation.isAvailable,
            artworkIdentity: presentation.artworkIdentity
        )
        let identityChanged = representedItemID != next.id
        let contentChanged = self.presentation != next
        let artworkVisibilityChanged = self.state.showsArtwork != state.showsArtwork
        let layoutChanged = self.columns != columns
            || self.widths != widths
            || self.state.density != state.density
            || artworkVisibilityChanged
        if identityChanged { resetPointerHover() }

        let previousArtwork = representedArtworkIdentity
        representedItemID = next.id
        representedArtworkIdentity = next.artworkIdentity
        self.presentation = next
        self.state = state
        self.columns = columns
        self.widths = widths
        actionHandler = onAction.map { callback in
            { action in callback(presentation.id, action) }
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if contentChanged { applyContent() }
        updateChrome()
        if identityChanged || previousArtwork != next.artworkIdentity || artworkVisibilityChanged {
            clearArtwork()
            if state.showsArtwork, let artworkIdentity = next.artworkIdentity {
                requestArtwork?(presentation.id, artworkIdentity)
            }
        }
        if contentChanged || layoutChanged { needsLayout = true }
        CATransaction.commit()
    }

    @discardableResult
    public func publishArtwork<ID: Hashable & Sendable>(
        _ image: CGImage,
        forItemID itemID: ID,
        artworkIdentity: String
    ) -> Bool {
        guard
            representedItemID == AnyHashable(itemID),
            representedArtworkIdentity == artworkIdentity
        else { return false }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        artworkLayer.contents = image
        artworkLayer.contentsGravity = .resizeAspectFill
        artworkLayer.contentsScale = window?.backingScaleFactor
            ?? NSScreen.main?.backingScaleFactor
            ?? 2
        publishedArtworkIdentity = artworkIdentity
        CATransaction.commit()
        return true
    }

    public func performAction(_ action: NativeMediaTableAction) {
        guard presentation?.isAvailable == true else { return }
        actionHandler?(action)
    }

    public func setPointerHovered(_ value: Bool) {
        guard isPointerHovered != value else { return }
        isPointerHovered = value
        updateChrome()
    }

    public func reconcilePointerHover(at windowPoint: NSPoint) {
        guard window != nil else {
            resetPointerHover()
            return
        }
        let local = convert(windowPoint, from: nil)
        setPointerHovered(bounds.contains(local) && visibleRect.contains(local))
    }

    public override func updateTrackingAreas() {
        if let hoverTrackingArea { removeTrackingArea(hoverTrackingArea) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeInActiveApp, .inVisibleRect, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        hoverTrackingArea = area
        super.updateTrackingAreas()
    }

    public override func mouseEntered(with _: NSEvent) { setPointerHovered(true) }
    public override func mouseExited(with _: NSEvent) { setPointerHovered(false) }

    public override func mouseDown(with event: NSEvent) {
        performAction(.select)
        super.mouseDown(with: event)
    }

    public override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layoutLayersAndSubviews()
        CATransaction.commit()
    }

    public override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateChrome()
    }

    public override func prepareForReuse() {
        resetPresentation()
        super.prepareForReuse()
    }

    public override func removeFromSuperview() {
        resetPresentation()
        super.removeFromSuperview()
    }

    private func configureSubviews() {
        configureButton(favoriteButton, identifier: "media-table.favorite", action: #selector(favoritePressed))
        configureButton(artworkButton, identifier: "media-table.artwork", action: #selector(playPressed))
        configureButton(actionButton, identifier: "media-table.actions", action: #selector(actionsPressed))
        configureMetadataControl(creatorButton, identifier: "media-table.creator", action: #selector(creatorPressed))
        configureMetadataControl(collectionButton, identifier: "media-table.collection", action: #selector(collectionPressed))
        configureLabel(titleLabel, identifier: "media-table.title", font: .systemFont(ofSize: 13))
        configureLabel(explicitLabel, identifier: "media-table.explicit", font: .systemFont(ofSize: 9, weight: .bold), alignment: .center)
        configureLabel(yearLabel, identifier: "media-table.year", alignment: .right)
        configureLabel(durationLabel, identifier: "media-table.duration", alignment: .right)
        durationLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)

        favoriteButton.imagePosition = .imageOnly
        artworkButton.imagePosition = .imageOnly
        actionButton.imagePosition = .imageOnly
        actionButton.image = NSImage(systemSymbolName: "ellipsis", accessibilityDescription: String(localized: "Media actions"))
        actionButton.toolTip = String(localized: "Media actions")

        creatorButton.hoverChanged = { [weak self] in self?.updateMetadataTones() }
        collectionButton.hoverChanged = { [weak self] in self?.updateMetadataTones() }

        for view in [
            favoriteButton, artworkButton, playbackIndicator, titleLabel, creatorButton,
            explicitLabel, collectionButton, yearLabel, durationLabel, actionButton,
        ] { addSubview(view) }
    }

    private func configureButton(_ button: NSButton, identifier: String, action: Selector) {
        button.identifier = NSUserInterfaceItemIdentifier(identifier)
        button.target = self
        button.action = action
        button.isBordered = false
        button.bezelStyle = .inline
        button.focusRingType = .none
        if let cell = button.cell as? NSButtonCell {
            cell.highlightsBy = []
            cell.showsStateBy = []
        }
    }

    private func configureMetadataControl(
        _ control: MediaTableMetadataControl,
        identifier: String,
        action: Selector
    ) {
        control.identifier = NSUserInterfaceItemIdentifier(identifier)
        control.target = self
        control.action = action
        control.alignment = .left
        control.lineBreakMode = .byTruncatingTail
        control.maximumNumberOfLines = 1
        control.isSelectable = false
        control.isEditable = false
        control.drawsBackground = false
        control.isBezeled = false
        control.focusRingType = .none
        control.setAccessibilityRole(.link)
    }

    private func configureLabel(
        _ label: NSTextField,
        identifier: String,
        font: NSFont = .systemFont(ofSize: 13),
        alignment: NSTextAlignment = .left
    ) {
        label.identifier = NSUserInterfaceItemIdentifier(identifier)
        label.font = font
        label.alignment = alignment
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1
        label.isSelectable = false
        label.isEditable = false
        label.drawsBackground = false
        label.isBezeled = false
    }

    private func applyContent() {
        guard let presentation else { return }
        titleLabel.stringValue = presentation.title
        titleLabel.toolTip = presentation.title
        creatorButton.stringValue = presentation.creator
        creatorButton.toolTip = presentation.creator
        collectionButton.stringValue = presentation.collection
        collectionButton.toolTip = presentation.collection
        yearLabel.stringValue = presentation.year
        durationLabel.stringValue = presentation.duration
        explicitLabel.isHidden = !presentation.isExplicit

        for control in interactiveSubviews { control.isEnabled = presentation.isAvailable }
        setAccessibilityEnabled(presentation.isAvailable)
        setAccessibilityLabel(
            [presentation.title, presentation.creator, presentation.collection, presentation.duration]
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
        )
        favoriteButton.setAccessibilityLabel(
            presentation.isFavorite
                ? String(localized: "Remove from favorites")
                : String(localized: "Add to favorites")
        )
        artworkButton.setAccessibilityLabel(String(localized: "Play \(presentation.title)"))
        artworkButton.toolTip = String(localized: "Play \(presentation.title)")
    }

    private func updateChrome() {
        guard let presentation else { return }
        let rowState = InteractiveRowState(
            isHovered: isPointerHovered,
            isFocused: state.isFocused,
            isSelected: state.isSelected,
            isUnavailable: !presentation.isAvailable,
            isIncreasedContrast: state.environment.isIncreasedContrast
        )
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        selectionLayer.backgroundColor = rowState.fill.map(NSColor.designToken)?.cgColor
            ?? NSColor.clear.cgColor
        selectionLayer.borderColor = rowState.border.map(NSColor.designToken)?.cgColor
            ?? NSColor.clear.cgColor
        selectionLayer.borderWidth = rowState.border == nil ? 0 : CGFloat(rowState.borderWidth)
        artworkLayer.backgroundColor = NSColor.controlBackgroundColor.cgColor
        artworkOverlayLayer.backgroundColor = presentation.isCurrent
            ? NSColor.black.withAlphaComponent(
                DesignTokens.Component.panelMediaCollectionPlaybackIndicatorScrimOpacity.value
            ).cgColor
            : NSColor.clear.cgColor
        CATransaction.commit()

        contentOpacity = rowState.contentOpacity
        for view in subviews { view.alphaValue = contentOpacity }
        setAccessibilitySelected(state.isSelected)

        favoriteButton.image = presentation.isFavorite ? Self.filledHeartImage : Self.emptyHeartImage
        favoriteButton.contentTintColor = presentation.isFavorite
            ? .designToken(DesignTokens.Color.actionPrimary)
            : .secondaryLabelColor
        favoriteButton.isHidden = !presentation.isFavorite && !isPointerHovered && !state.isFocused
        actionButton.contentTintColor = isPointerHovered || state.isFocused
            ? .labelColor
            : .tertiaryLabelColor

        let showsIndicator = state.showsArtwork && presentation.isCurrent && presentation.isPlaying
        artworkButton.image = showsIndicator ? nil : Self.playImage
        artworkButton.isHidden = !state.showsArtwork
            || showsIndicator
            || (!isPointerHovered && !presentation.isCurrent)
        playbackIndicator.isHidden = !showsIndicator
        playbackIndicator.setState(
            PlaybackIndicatorState(
                isPlaying: showsIndicator,
                reducesMotion: state.environment.reducesMotion || state.isLiveScrolling
            )
        )
        updateMetadataTones()
    }

    private func updateMetadataTones() {
        for control in [creatorButton, collectionButton] {
            let focused = window?.firstResponder === control
            control.textColor = !control.isEnabled
                ? .tertiaryLabelColor
                : control.isPointerHovered || focused ? .labelColor : .secondaryLabelColor
        }
    }

    private func layoutLayersAndSubviews() {
        let geometry = MediaTableGeometry(density: state.density)
        let rowHeight = bounds.height
        selectionLayer.frame = bounds.insetBy(
            dx: geometry.selectionHorizontalInset,
            dy: geometry.selectionVerticalInset
        )

        var x = geometry.horizontalInset
        favoriteButton.frame = CGRect(
            x: x,
            y: (rowHeight - geometry.favoriteControlWidth) / 2,
            width: geometry.favoriteControlWidth,
            height: geometry.favoriteControlWidth
        )
        x += geometry.favoriteControlWidth + geometry.columnSpacing

        let artworkFrame = CGRect(
            x: x,
            y: (rowHeight - geometry.artworkSize) / 2,
            width: geometry.artworkSize,
            height: geometry.artworkSize
        )
        for layer in [artworkLayer, artworkOverlayLayer] {
            layer.frame = artworkFrame
            layer.isHidden = !state.showsArtwork
        }
        artworkButton.frame = artworkFrame
        playbackIndicator.frame = artworkFrame
        if state.showsArtwork { x = artworkFrame.maxX + geometry.songContentSpacing }

        let stackHeight = geometry.lineHeight * 2 + geometry.lineGap
        let stackY = (rowHeight - stackHeight) / 2
        let titleY = stackY + geometry.lineHeight + geometry.lineGap
        let titleEnd = geometry.horizontalInset + CGFloat(widths.title)
        let titleAreaWidth = max(titleEnd - x, 1)
        let explicitReserve = presentation?.isExplicit == true
            ? geometry.explicitBadgeGap + geometry.explicitBadgeWidth
            : 0
        titleLabel.frame = CGRect(
            x: x,
            y: titleY,
            width: max(titleAreaWidth - explicitReserve, 1),
            height: geometry.lineHeight
        )
        explicitLabel.frame = CGRect(
            x: titleLabel.frame.maxX + geometry.explicitBadgeGap,
            y: titleY + 1,
            width: geometry.explicitBadgeWidth,
            height: geometry.explicitBadgeHeight
        )
        creatorButton.frame = CGRect(
            x: x,
            y: stackY,
            width: metadataWidth(creatorButton, maximum: titleAreaWidth),
            height: geometry.lineHeight
        )

        x = titleEnd + geometry.columnSpacing
        let singleLineY = (rowHeight - geometry.lineHeight) / 2
        for column in columns {
            let width = CGFloat(widths[column])
            switch column {
            case .collection:
                collectionButton.frame = CGRect(
                    x: x,
                    y: singleLineY,
                    width: metadataWidth(collectionButton, maximum: width),
                    height: geometry.lineHeight
                )
            case .year:
                yearLabel.frame = CGRect(x: x, y: singleLineY, width: width, height: geometry.lineHeight)
            case .duration:
                durationLabel.frame = CGRect(x: x, y: singleLineY, width: width, height: geometry.lineHeight)
            }
            x += width + geometry.columnSpacing
        }
        collectionButton.isHidden = !columns.contains(.collection)
        yearLabel.isHidden = !columns.contains(.year)
        durationLabel.isHidden = !columns.contains(.duration)
        actionButton.frame = CGRect(
            x: max(bounds.maxX - geometry.horizontalInset - geometry.actionWidth, x),
            y: (rowHeight - geometry.actionWidth) / 2,
            width: geometry.actionWidth,
            height: geometry.actionWidth
        )
    }

    private func metadataWidth(_ control: NSTextField, maximum: CGFloat) -> CGFloat {
        min(max(ceil(control.cell?.cellSize.width ?? control.intrinsicContentSize.width), 1), maximum)
    }

    private func resetPointerHover() {
        isPointerHovered = false
        creatorButton.resetPointerHover()
        collectionButton.resetPointerHover()
    }

    private func clearArtwork() {
        publishedArtworkIdentity = nil
        artworkLayer.contents = nil
        artworkLayer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    }

    private func resetPresentation() {
        resetPointerHover()
        representedItemID = nil
        representedArtworkIdentity = nil
        presentation = nil
        actionHandler = nil
        clearArtwork()
        playbackIndicator.prepareForReuse()
        playbackIndicator.isHidden = true
    }

    private var interactiveSubviews: [NSControl] {
        [favoriteButton, artworkButton, creatorButton, collectionButton, actionButton]
    }

    @objc private func favoritePressed() { performAction(.favorite) }
    @objc private func playPressed() { performAction(.play) }
    @objc private func creatorPressed() { performAction(.creator) }
    @objc private func collectionPressed() { performAction(.collection) }
    @objc private func actionsPressed() { performAction(.actions) }
}

private extension CGColor {
    var alpha: CGFloat {
        guard let components, !components.isEmpty else { return 0 }
        return components.count == 2 ? components[1] : components[components.count - 1]
    }
}
#endif
