#if os(macOS)
import AppKit
import QenTerraDesignTokens
import QuartzCore
import SwiftUI

public struct PlaybackIndicatorState: Equatable, Sendable {
    public let isPlaying: Bool
    public let reducesMotion: Bool

    public init(isPlaying: Bool, reducesMotion: Bool) {
        self.isPlaying = isPlaying
        self.reducesMotion = reducesMotion
    }

    public var animates: Bool { isPlaying && !reducesMotion }

    public var staticScales: [Double] {
        [
            DesignTokens.Component.panelMediaCollectionPlaybackIndicatorStaticFirstScale.value,
            DesignTokens.Component.panelMediaCollectionPlaybackIndicatorStaticSecondScale.value,
            DesignTokens.Component.panelMediaCollectionPlaybackIndicatorStaticThirdScale.value,
        ]
    }

    public func scale(forBar index: Int, elapsed: TimeInterval) -> Double {
        guard staticScales.indices.contains(index) else { return 0 }
        guard animates else { return staticScales[index] }
        let pattern = animationPatterns[index]
        let duration = animationDurations[index]
        guard duration > 0, elapsed.isFinite else { return pattern[0] }
        let phasedElapsed = max(elapsed - phaseOffset(forBar: index), 0)
        let normalized = phasedElapsed.truncatingRemainder(dividingBy: duration) / duration
        let keyTimes = animationKeyTimes
        guard normalized > 0 else { return pattern[0] }
        for upperIndex in 1 ..< keyTimes.count where normalized <= keyTimes[upperIndex] {
            let lowerIndex = upperIndex - 1
            let interval = keyTimes[upperIndex] - keyTimes[lowerIndex]
            let progress = interval > 0
                ? (normalized - keyTimes[lowerIndex]) / interval
                : 0
            return pattern[lowerIndex]
                + (pattern[upperIndex] - pattern[lowerIndex]) * progress
        }
        return pattern[pattern.count - 1]
    }

    var animationPatterns: [[Double]] {
        [
            [
                DesignTokens.Component.panelMediaCollectionPlaybackIndicatorFirstPatternFirstScale.value,
                DesignTokens.Component.panelMediaCollectionPlaybackIndicatorFirstPatternSecondScale.value,
                DesignTokens.Component.panelMediaCollectionPlaybackIndicatorFirstPatternThirdScale.value,
                DesignTokens.Component.panelMediaCollectionPlaybackIndicatorFirstPatternFourthScale.value,
                DesignTokens.Component.panelMediaCollectionPlaybackIndicatorFirstPatternFifthScale.value,
            ],
            [
                DesignTokens.Component.panelMediaCollectionPlaybackIndicatorSecondPatternFirstScale.value,
                DesignTokens.Component.panelMediaCollectionPlaybackIndicatorSecondPatternSecondScale.value,
                DesignTokens.Component.panelMediaCollectionPlaybackIndicatorSecondPatternThirdScale.value,
                DesignTokens.Component.panelMediaCollectionPlaybackIndicatorSecondPatternFourthScale.value,
                DesignTokens.Component.panelMediaCollectionPlaybackIndicatorSecondPatternFifthScale.value,
            ],
            [
                DesignTokens.Component.panelMediaCollectionPlaybackIndicatorThirdPatternFirstScale.value,
                DesignTokens.Component.panelMediaCollectionPlaybackIndicatorThirdPatternSecondScale.value,
                DesignTokens.Component.panelMediaCollectionPlaybackIndicatorThirdPatternThirdScale.value,
                DesignTokens.Component.panelMediaCollectionPlaybackIndicatorThirdPatternFourthScale.value,
                DesignTokens.Component.panelMediaCollectionPlaybackIndicatorThirdPatternFifthScale.value,
            ],
        ]
    }

    var animationDurations: [TimeInterval] {
        [
            DesignTokens.Component.panelMediaCollectionPlaybackIndicatorFirstDurationMs.milliseconds / 1_000,
            DesignTokens.Component.panelMediaCollectionPlaybackIndicatorSecondDurationMs.milliseconds / 1_000,
            DesignTokens.Component.panelMediaCollectionPlaybackIndicatorThirdDurationMs.milliseconds / 1_000,
        ]
    }

    var animationKeyTimes: [Double] {
        [
            0,
            DesignTokens.Component.panelMediaCollectionPlaybackIndicatorSecondKeyTimeRatio.value,
            DesignTokens.Component.panelMediaCollectionPlaybackIndicatorThirdKeyTimeRatio.value,
            DesignTokens.Component.panelMediaCollectionPlaybackIndicatorFourthKeyTimeRatio.value,
            1,
        ]
    }

    var animationStagger: TimeInterval {
        DesignTokens.Component.panelMediaCollectionPlaybackIndicatorStaggerMs.milliseconds / 1_000
    }

    func phaseOffset(forBar index: Int) -> TimeInterval {
        guard staticScales.indices.contains(index) else { return 0 }
        return Double(index) * animationStagger
    }
}

public struct PlaybackIndicatorGeometry: Equatable, Sendable {
    public let barCount: Int
    public let barWidth: CGFloat
    public let gap: CGFloat
    public let maximumHeight: CGFloat
    public let verticalInset: CGFloat
    public let cornerRadius: CGFloat

    public init() {
        barCount = 3
        barWidth = CGFloat(
            DesignTokens.Component.panelMediaCollectionPlaybackIndicatorBarWidth.points
        )
        gap = CGFloat(DesignTokens.Component.panelMediaCollectionPlaybackIndicatorGap.points)
        maximumHeight = CGFloat(
            DesignTokens.Component.panelMediaCollectionPlaybackIndicatorMaximumHeight.points
        )
        verticalInset = CGFloat(
            DesignTokens.Component.panelMediaCollectionPlaybackIndicatorVerticalInset.points
        )
        cornerRadius = CGFloat(
            DesignTokens.Component.panelMediaCollectionPlaybackIndicatorCornerRadius.points
        )
    }

    public func frames(in bounds: CGRect) -> [CGRect] {
        let height = min(maximumHeight, max(bounds.height - verticalInset, 1))
        let totalWidth = CGFloat(barCount) * barWidth
            + CGFloat(max(barCount - 1, 0)) * gap
        let originX = bounds.minX + (bounds.width - totalWidth) / 2
        let originY = bounds.minY + (bounds.height - height) / 2
        return (0 ..< barCount).map { index in
            CGRect(
                x: originX + CGFloat(index) * (barWidth + gap),
                y: originY,
                width: barWidth,
                height: height
            )
        }
    }
}

public struct PlaybackIndicator: View {
    @Environment(\.designNativeEnvironment) private var environment
    private let isPlaying: Bool
    private let color: Color
    private let geometry = PlaybackIndicatorGeometry()

    public init(isPlaying: Bool, color: Color = .white) {
        self.isPlaying = isPlaying
        self.color = color
    }

    public var body: some View {
        let state = PlaybackIndicatorState(
            isPlaying: isPlaying,
            reducesMotion: environment.reducesMotion
        )
        TimelineView(.animation(paused: !state.animates)) { timeline in
            GeometryReader { proxy in
                let frames = geometry.frames(in: CGRect(origin: .zero, size: proxy.size))
                ZStack(alignment: .topLeading) {
                    ForEach(frames.indices, id: \.self) { index in
                        let frame = frames[index]
                        RoundedRectangle(cornerRadius: geometry.cornerRadius, style: .continuous)
                            .fill(color)
                            .frame(width: frame.width, height: frame.height)
                            .scaleEffect(
                                y: state.scale(
                                    forBar: index,
                                    elapsed: timeline.date.timeIntervalSinceReferenceDate
                                ),
                                anchor: .bottom
                            )
                            .position(x: frame.midX, y: frame.midY)
                    }
                }
            }
        }
        .frame(
            width: CGFloat(DesignTokens.Size.iconXL),
            height: CGFloat(DesignTokens.Size.iconXL)
        )
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

@MainActor
public final class NativePlaybackIndicatorView: NSView {
    private static let animationKey = "qenterra.playback.level"
    private static let disabledLayerActions: [String: any CAAction] = [
        "anchorPoint": NSNull(),
        "backgroundColor": NSNull(),
        "bounds": NSNull(),
        "cornerRadius": NSNull(),
        "position": NSNull(),
        "sublayers": NSNull(),
        "transform": NSNull(),
    ]

    private let geometry = PlaybackIndicatorGeometry()
    private let bars: [CALayer]
    public private(set) var isAnimating = false

    public var barCount: Int { bars.count }

    public override init(frame frameRect: NSRect) {
        bars = (0 ..< PlaybackIndicatorGeometry().barCount).map { _ in CALayer() }
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.actions = Self.disabledLayerActions
        for bar in bars {
            bar.anchorPoint = CGPoint(x: 0.5, y: 0)
            bar.backgroundColor = NSColor.white.cgColor
            bar.cornerRadius = geometry.cornerRadius
            bar.actions = Self.disabledLayerActions
            layer?.addSublayer(bar)
        }
        applyStaticBars(
            PlaybackIndicatorState(isPlaying: false, reducesMotion: true).staticScales
        )
        setAccessibilityElement(false)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        nil
    }

    public override func hitTest(_: NSPoint) -> NSView? {
        nil
    }

    public override func layout() {
        super.layout()
        let frames = geometry.frames(in: bounds)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for (bar, frame) in zip(bars, frames) {
            bar.bounds = CGRect(origin: .zero, size: frame.size)
            bar.position = CGPoint(x: frame.midX, y: frame.minY)
        }
        CATransaction.commit()
    }

    public func setState(_ state: PlaybackIndicatorState, color: NSColor = .white) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for bar in bars { bar.backgroundColor = color.cgColor }
        CATransaction.commit()

        if state.animates, !isAnimating {
            startAnimating(state)
        } else if !state.animates {
            stopAnimating(staticScales: state.staticScales)
        }
    }

    public func setPlaying(_ isPlaying: Bool, reduceMotion: Bool) {
        setState(
            PlaybackIndicatorState(
                isPlaying: isPlaying,
                reducesMotion: reduceMotion
            )
        )
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        isAnimating = false
        for bar in bars { bar.removeAllAnimations() }
        applyStaticBars(
            PlaybackIndicatorState(isPlaying: false, reducesMotion: true).staticScales
        )
    }

    public override func removeFromSuperview() {
        prepareForReuse()
        super.removeFromSuperview()
    }

    var animationCount: Int {
        bars.reduce(0) { $0 + ($1.animationKeys()?.count ?? 0) }
    }

    var hasDisabledImplicitLayerActions: Bool {
        let keys = ["anchorPoint", "backgroundColor", "bounds", "cornerRadius", "position", "sublayers", "transform"]
        guard keys.allSatisfy({ layer?.actions?[$0] is NSNull }) else { return false }
        return bars.allSatisfy { bar in
            keys.allSatisfy { bar.actions?[$0] is NSNull }
        }
    }

    private func startAnimating(_ state: PlaybackIndicatorState) {
        isAnimating = true
        let now = CACurrentMediaTime()
        for (index, bar) in bars.enumerated() {
            bar.removeAllAnimations()
            let animation = CAKeyframeAnimation(keyPath: "transform.scale.y")
            animation.values = state.animationPatterns[index]
            animation.keyTimes = state.animationKeyTimes.map(NSNumber.init(value:))
            animation.duration = state.animationDurations[index]
            animation.beginTime = now + state.phaseOffset(forBar: index)
            animation.repeatCount = .infinity
            animation.isRemovedOnCompletion = true
            bar.add(animation, forKey: Self.animationKey)
        }
    }

    private func stopAnimating(staticScales: [Double]) {
        isAnimating = false
        for bar in bars { bar.removeAllAnimations() }
        applyStaticBars(staticScales)
    }

    private func applyStaticBars(_ scales: [Double]) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for (index, bar) in bars.enumerated() {
            bar.transform = CATransform3DMakeScale(1, scales[index], 1)
        }
        CATransaction.commit()
    }
}
#endif
