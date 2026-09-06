#if os(macOS)
import QenTerraComponents
import QenTerraDesignTokens
import SwiftUI

enum PlaybackQueueAccessibilityAction: Equatable, Sendable {
    case play
    case remove

    static func available(acceptsPlayback: Bool, canRemove: Bool) -> [Self] {
        var actions: [Self] = []
        if acceptsPlayback { actions.append(.play) }
        if canRemove { actions.append(.remove) }
        return actions
    }
}

enum PlaybackQueueTapAction: Equatable, Sendable {
    case none
    case select
    case play

    static func resolve(tapCount: Int, acceptsPlayback: Bool) -> Self {
        switch tapCount {
        case 1:
            .select
        case 2 where acceptsPlayback:
            .play
        default:
            .none
        }
    }
}

public struct PlaybackQueueRowPresentation<ID: Hashable & Sendable>: Identifiable, Equatable, Sendable {
    public let id: ID
    public let title: String
    public let subtitle: String
    public let durationText: String?
    public let isCurrent: Bool
    public let isSelected: Bool
    public let isAvailable: Bool
    public let isDraggable: Bool
    public let isPlaying: Bool
    public let accessibilityLabel: String

    public init(
        id: ID,
        title: String,
        subtitle: String,
        durationText: String?,
        isCurrent: Bool,
        isSelected: Bool,
        isAvailable: Bool,
        isDraggable: Bool,
        isPlaying: Bool = false,
        accessibilityLabel: String
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.durationText = durationText
        self.isCurrent = isCurrent
        self.isSelected = isSelected
        self.isAvailable = isAvailable
        self.isDraggable = isDraggable
        self.isPlaying = isPlaying
        self.accessibilityLabel = accessibilityLabel
    }

    public var acceptsPlayback: Bool { isAvailable }

    public var trailingSymbolName: String? {
        if isCurrent { return isPlaying ? "waveform" : "speaker.fill" }
        return isDraggable ? "line.3.horizontal" : nil
    }

    public var trailingAccessibilityLabel: String? {
        guard isCurrent else { return nil }
        return isPlaying ? String(localized: "Playing") : String(localized: "Paused")
    }

    public var accessibilityValue: String {
        var states: [String] = []
        if isCurrent { states.append(String(localized: "Current track")) }
        if isSelected { states.append(String(localized: "Selected")) }
        if !isAvailable { states.append(String(localized: "Unavailable")) }
        guard let first = states.first else { return "" }
        return ([first] + states.dropFirst().map { $0.lowercased() }).joined(separator: ", ")
    }
}

public struct PlaybackQueueRow<
    ID: Hashable & Sendable,
    Artwork: View,
    Metadata: View,
    ContextMenu: View,
    DragPreview: View
>: View {
    @State private var metadataOwnsCurrentTap = false

    private let presentation: PlaybackQueueRowPresentation<ID>
    private let dragPayload: String?
    private let select: (@MainActor () -> Void)?
    private let play: @MainActor () -> Void
    private let remove: (@MainActor () -> Void)?
    private let artwork: Artwork
    private let metadata: Metadata
    private let contextMenu: ContextMenu
    private let dragPreview: DragPreview

    public init(
        presentation: PlaybackQueueRowPresentation<ID>,
        dragPayload: String? = nil,
        select: (@MainActor () -> Void)?,
        play: @escaping @MainActor () -> Void,
        remove: (@MainActor () -> Void)?,
        @ViewBuilder artwork: () -> Artwork,
        @ViewBuilder metadata: () -> Metadata,
        @ViewBuilder contextMenu: () -> ContextMenu,
        @ViewBuilder dragPreview: () -> DragPreview
    ) {
        self.presentation = presentation
        self.dragPayload = dragPayload
        self.select = select
        self.play = play
        self.remove = remove
        self.artwork = artwork()
        self.metadata = metadata()
        self.contextMenu = contextMenu()
        self.dragPreview = dragPreview()
    }

    public var body: some View {
        Group {
            if presentation.isDraggable, let dragPayload {
                row.draggable(dragPayload) { dragPreview }
            } else {
                row
            }
        }
    }

    private var row: some View {
        HStack(spacing: DesignTokens.Component.panelQueueRowGap.points) {
            artwork
                .frame(
                    width: DesignTokens.Component.panelQueueArtworkSide.points,
                    height: DesignTokens.Component.panelQueueArtworkSide.points
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: DesignTokens.Radius.control,
                        style: .continuous
                    )
                )

            VStack(alignment: .leading, spacing: DesignProductMetrics.cadence.textStack) {
                Text(verbatim: presentation.title)
                    .font(.callout.weight(presentation.isCurrent ? .semibold : .medium))
                    .lineLimit(1)
                metadata
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .simultaneousGesture(
                        TapGesture().onEnded { metadataOwnsCurrentTap = true }
                    )
            }

            Spacer(minLength: DesignTokens.Component.panelQueueRowGap.points)
            if let trailingSymbolName = presentation.trailingSymbolName {
                Image(systemName: trailingSymbolName)
                    .font(.caption)
                    .foregroundStyle(presentation.isCurrent ? .primary : .tertiary)
                    .accessibilityLabel(
                        Text(verbatim: presentation.trailingAccessibilityLabel ?? "")
                    )
                    .accessibilityHidden(presentation.trailingAccessibilityLabel == nil)
            }
            if let durationText = presentation.durationText {
                Text(verbatim: durationText)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, DesignTokens.Component.panelQueueRowHorizontalPadding.points)
        .padding(.vertical, DesignTokens.Component.panelQueueRowVerticalPadding.points)
        .frame(minHeight: DesignTokens.Component.panelQueueRowHeight.points)
        .background {
            InteractiveRowSurface(
                state: InteractiveRowState(
                    isSelected: presentation.isSelected,
                    isDisabled: !presentation.isAvailable,
                    isUnavailable: !presentation.isAvailable
                )
            ) { Color.clear }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture(count: 2).exclusively(before: TapGesture()).onEnded { value in
                if metadataOwnsCurrentTap {
                    metadataOwnsCurrentTap = false
                    return
                }
                switch value {
                case .first:
                    if PlaybackQueueTapAction.resolve(
                        tapCount: 2,
                        acceptsPlayback: presentation.acceptsPlayback
                    ) == .play {
                        play()
                    }
                case .second:
                    if PlaybackQueueTapAction.resolve(
                        tapCount: 1,
                        acceptsPlayback: presentation.acceptsPlayback
                    ) == .select {
                        select?()
                    }
                }
            }
        )
        .contextMenu { contextMenu }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(verbatim: presentation.accessibilityLabel))
        .accessibilityValue(Text(verbatim: presentation.accessibilityValue))
        .accessibilityAddTraits(presentation.isSelected ? .isSelected : [])
        .modifier(
            PlaybackQueueAccessibilityModifier(
                actions: PlaybackQueueAccessibilityAction.available(
                    acceptsPlayback: presentation.acceptsPlayback,
                    canRemove: remove != nil
                ),
                play: play,
                remove: remove
            )
        )
    }
}

public extension PlaybackQueueRow where Metadata == Text {
    init(
        presentation: PlaybackQueueRowPresentation<ID>,
        dragPayload: String? = nil,
        select: (@MainActor () -> Void)? = nil,
        play: @escaping @MainActor () -> Void,
        remove: (@MainActor () -> Void)?,
        @ViewBuilder artwork: () -> Artwork,
        @ViewBuilder contextMenu: () -> ContextMenu,
        @ViewBuilder dragPreview: () -> DragPreview
    ) {
        self.init(
            presentation: presentation,
            dragPayload: dragPayload,
            select: select,
            play: play,
            remove: remove,
            artwork: artwork,
            metadata: { Text(verbatim: presentation.subtitle) },
            contextMenu: contextMenu,
            dragPreview: dragPreview
        )
    }
}

private struct PlaybackQueueAccessibilityModifier: ViewModifier {
    let actions: [PlaybackQueueAccessibilityAction]
    let play: @MainActor () -> Void
    let remove: (@MainActor () -> Void)?

    @ViewBuilder
    func body(content: Content) -> some View {
        switch actions {
        case [.play, .remove]:
            content
                .accessibilityAction(named: Text("Play Now"), play)
                .accessibilityAction(named: Text("Remove from Queue")) { remove?() }
        case [.play]:
            content.accessibilityAction(named: Text("Play Now"), play)
        case [.remove]:
            content.accessibilityAction(named: Text("Remove from Queue")) { remove?() }
        default:
            content
        }
    }
}
#endif
