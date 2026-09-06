#if os(macOS)
    import Foundation
    import simd

    public struct ArtworkAccentGradientTransition: Sendable {
        public static let duration: TimeInterval = 0.8

        private var sourceColors: [SIMD3<Float>]
        private var targetColors: [SIMD3<Float>]
        private var startedAt: TimeInterval
        private var transitionDuration: TimeInterval

        public init(palette: ArtworkAccentPalette) {
            let colors = ArtworkAccentGradientReference.shaderColors(for: palette)
            sourceColors = colors
            targetColors = colors
            startedAt = 0
            transitionDuration = 0
        }

        public mutating func retarget(
            to palette: ArtworkAccentPalette,
            at timestamp: TimeInterval,
            reducesMotion: Bool
        ) {
            let nextColors = ArtworkAccentGradientReference.shaderColors(for: palette)
            if nextColors == targetColors {
                if reducesMotion {
                    sourceColors = nextColors
                    startedAt = timestamp
                    transitionDuration = 0
                }
                return
            }
            let visibleColors = colors(at: timestamp)
            sourceColors = reducesMotion ? nextColors : visibleColors
            targetColors = nextColors
            startedAt = timestamp
            transitionDuration = reducesMotion ? 0 : Self.duration
        }

        public func colors(at timestamp: TimeInterval) -> [SIMD3<Float>] {
            guard transitionDuration > 0 else {
                return targetColors
            }
            let progress = Float(min(max((timestamp - startedAt) / transitionDuration, 0), 1))
            let easedProgress = progress * progress * (3 - 2 * progress)
            return zip(sourceColors, targetColors).map { source, target in
                source + (target - source) * easedProgress
            }
        }
    }

    public enum ArtworkAccentGradientTimeline {
        public static func elapsedTime(
            startedAt: TimeInterval,
            currentTime: TimeInterval,
            isAnimated: Bool
        ) -> Float {
            guard isAnimated else {
                return 0
            }
            return Float(max(currentTime - startedAt, 0))
        }
    }
#endif
