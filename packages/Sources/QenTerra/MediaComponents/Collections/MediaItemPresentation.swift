#if os(macOS)
import Foundation

public struct MediaItemPresentation<ID: Hashable & Sendable>: Identifiable, Equatable, Sendable {
    public let id: ID
    public let title: String
    public let subtitle: String
    public let metadata: String?
    public let isSelected: Bool
    public let isCurrent: Bool
    public let isPlaying: Bool
    public let isAvailable: Bool

    public init(
        id: ID,
        title: String,
        subtitle: String,
        metadata: String?,
        isSelected: Bool,
        isCurrent: Bool,
        isPlaying: Bool,
        isAvailable: Bool
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.metadata = metadata
        self.isSelected = isSelected
        self.isCurrent = isCurrent
        self.isPlaying = isPlaying
        self.isAvailable = isAvailable
    }
}

struct MediaItemVisualPresentation: Equatable, Sendable {
    let isSelected: Bool
    let isCurrent: Bool
    let isAvailable: Bool
    let showsPlaybackIndicator: Bool
    let showsPausedCurrentAffordance: Bool

    init<ID>(_ item: MediaItemPresentation<ID>) {
        isSelected = item.isSelected
        isCurrent = item.isCurrent
        isAvailable = item.isAvailable
        showsPlaybackIndicator = item.isCurrent && item.isPlaying
        showsPausedCurrentAffordance = item.isCurrent && !item.isPlaying
    }
}

enum MediaInteractionRegion: Equatable, Sendable {
    case primaryContent
    case embeddedControl
}

@MainActor
struct MediaActivation {
    private let action: @MainActor () -> Void

    init(action: @escaping @MainActor () -> Void) {
        self.action = action
    }

    func perform(from region: MediaInteractionRegion, isAvailable: Bool) {
        guard region == .primaryContent, isAvailable else { return }
        action()
    }
}
#endif
