#if os(macOS)
public struct PlayerBarActions: Sendable {
    public let showNowPlaying: @MainActor @Sendable () -> Void
    public let togglePlayback: @MainActor @Sendable () -> Void
    public let previous: @MainActor @Sendable () -> Void
    public let next: @MainActor @Sendable () -> Void
    public let seek: @MainActor @Sendable (Double) -> Void
    public let setVolume: @MainActor @Sendable (Double) -> Void
    public let toggleMute: @MainActor @Sendable () -> Void
    public let showQueue: @MainActor @Sendable () -> Void
    public let toggleShuffle: (@MainActor @Sendable () -> Void)?
    public let cycleRepeatMode: (@MainActor @Sendable () -> Void)?
    public let setFavorite: (@MainActor @Sendable (Bool) -> Void)?

    public init(
        showNowPlaying: @escaping @MainActor @Sendable () -> Void,
        togglePlayback: @escaping @MainActor @Sendable () -> Void,
        previous: @escaping @MainActor @Sendable () -> Void,
        next: @escaping @MainActor @Sendable () -> Void,
        seek: @escaping @MainActor @Sendable (Double) -> Void,
        setVolume: @escaping @MainActor @Sendable (Double) -> Void,
        toggleMute: @escaping @MainActor @Sendable () -> Void,
        showQueue: @escaping @MainActor @Sendable () -> Void,
        toggleShuffle: (@MainActor @Sendable () -> Void)? = nil,
        cycleRepeatMode: (@MainActor @Sendable () -> Void)? = nil,
        setFavorite: (@MainActor @Sendable (Bool) -> Void)? = nil
    ) {
        self.showNowPlaying = showNowPlaying
        self.togglePlayback = togglePlayback
        self.previous = previous
        self.next = next
        self.seek = seek
        self.setVolume = setVolume
        self.toggleMute = toggleMute
        self.showQueue = showQueue
        self.toggleShuffle = toggleShuffle
        self.cycleRepeatMode = cycleRepeatMode
        self.setFavorite = setFavorite
    }
}
#endif
