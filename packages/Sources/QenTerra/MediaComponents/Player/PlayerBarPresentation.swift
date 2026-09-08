#if os(macOS)
import Foundation

public enum TransportRepeatMode: String, CaseIterable, Equatable, Sendable {
    case off
    case all
    case one
}

public struct PlayerBarPresentation: Equatable, Sendable {
    public let title: String?
    public let subtitle: String?
    public let isPlaying: Bool
    public let isShuffleEnabled: Bool
    public let repeatMode: TransportRepeatMode
    public let progress: PlaybackProgressPresentation
    public let volume: Double
    public let isMuted: Bool
    public let isQueuePresented: Bool
    public let favorite: FavoritePresentation?
    public let showNowPlayingAccessibilityLabel: String?
    public let emptyTitle: String?
    public let emptySymbolName: String?

    public init(
        title: String?,
        subtitle: String?,
        isPlaying: Bool,
        isShuffleEnabled: Bool,
        repeatMode: TransportRepeatMode,
        progress: PlaybackProgressPresentation,
        volume: Double,
        isMuted: Bool,
        isQueuePresented: Bool,
        favorite: FavoritePresentation?,
        showNowPlayingAccessibilityLabel: String? = nil,
        emptyTitle: String? = nil,
        emptySymbolName: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isPlaying = isPlaying
        self.isShuffleEnabled = isShuffleEnabled
        self.repeatMode = repeatMode
        self.progress = progress
        self.volume = volume
        self.isMuted = isMuted
        self.isQueuePresented = isQueuePresented
        self.favorite = favorite
        self.showNowPlayingAccessibilityLabel = showNowPlayingAccessibilityLabel
        self.emptyTitle = emptyTitle
        self.emptySymbolName = emptySymbolName
    }

    public var hasCurrentItem: Bool { title != nil }

    public var clampedVolume: Double {
        guard volume.isFinite else { return 0 }
        return min(max(volume, 0), 1)
    }

    public static func empty(
        progress: PlaybackProgressPresentation,
        title: String? = nil,
        symbolName: String? = nil
    ) -> Self {
        Self(
            title: nil,
            subtitle: nil,
            isPlaying: false,
            isShuffleEnabled: false,
            repeatMode: .off,
            progress: progress,
            volume: 0,
            isMuted: false,
            isQueuePresented: false,
            favorite: nil,
            emptyTitle: title,
            emptySymbolName: symbolName
        )
    }
}
#endif
