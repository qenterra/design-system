import Foundation

public struct PlaybackTimelineSample: Equatable, Sendable {
    public let mediaTime: TimeInterval
    public let hostUptime: TimeInterval
    public let rate: Double

    public init(mediaTime: TimeInterval, hostUptime: TimeInterval, rate: Double) {
        self.mediaTime = mediaTime
        self.hostUptime = hostUptime
        self.rate = rate
    }
}

public struct PlaybackPresentationClock: Sendable {
    private(set) var anchorMediaTime: TimeInterval = 0
    private(set) var anchorHostUptime: TimeInterval = 0
    private(set) var rate: Double = 0

    public init() {}

    public mutating func update(
        _ sample: PlaybackTimelineSample
    ) {
        anchorMediaTime = max(sample.mediaTime, 0)
        anchorHostUptime = sample.hostUptime
        rate = max(sample.rate, 0)
    }

    public func time(
        atHostUptime hostUptime: TimeInterval,
        duration: TimeInterval
    ) -> TimeInterval {
        let elapsed = max(hostUptime - anchorHostUptime, 0) * rate
        return min(
            max(anchorMediaTime + elapsed, 0),
            max(duration, 0)
        )
    }
}
