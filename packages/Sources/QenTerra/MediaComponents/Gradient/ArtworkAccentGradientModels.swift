#if os(macOS)
    import Foundation
    import QenTerraDesignTokens
    import simd

    /// Up to five ready display-sRGB artwork colours. Palette extraction remains consumer-owned.
    public struct ArtworkAccentPalette: Hashable, Sendable {
        public let colors: [ArtworkAccentColor]

        public init(colors: [ArtworkAccentColor]) {
            self.colors = Array(colors.prefix(5))
        }

        public static let fallback = ArtworkAccentPalette(colors: [
            ArtworkAccentColor(red: 0.43, green: 0.35, blue: 0.7),
            ArtworkAccentColor(red: 0.22, green: 0.52, blue: 0.58),
            ArtworkAccentColor(red: 0.65, green: 0.34, blue: 0.51),
        ])
    }

    public struct ArtworkAccentGradientVertex: Equatable, Sendable {
        public let position: SIMD3<Float>
        public let textureCoordinate: SIMD2<Float>
    }

    public struct ArtworkAccentGradientMesh: Sendable {
        public let vertices: [ArtworkAccentGradientVertex]
        public let indices: [UInt32]
    }

    public enum ArtworkAccentGradientReference {
        public static let planeSize: Float = 1.5
        public static let segmentCount = 200
        public static let noiseFrequency = SIMD2<Float>(3, 6)
        public static let noiseAmount: Float = 0.2
        public static let noiseSpeed: Float = 0.02
        public static let cameraFieldOfView: Float = 35
        public static let cameraNearPlane: Float = 0.1
        public static let cameraFarPlane: Float = 100
        public static let cameraPosition = SIMD3<Float>(0, 0.5, 0.4)

        public static var modelMatrix: simd_float4x4 {
            let angle = -Float.pi / 2
            let cosine = cos(angle)
            let sine = sin(angle)
            return simd_float4x4(columns: (
                SIMD4(1, 0, 0, 0),
                SIMD4(0, cosine, sine, 0),
                SIMD4(0, -sine, cosine, 0),
                SIMD4(0, 0, 0, 1)
            ))
        }

        public static func viewProjectionMatrix(aspectRatio: Float) -> simd_float4x4 {
            projectionMatrix(aspectRatio: aspectRatio) * viewMatrix
        }

        public static func makeMesh() -> ArtworkAccentGradientMesh {
            let verticesPerSide = segmentCount + 1
            let halfSize = planeSize / 2
            let step = planeSize / Float(segmentCount)
            var vertices: [ArtworkAccentGradientVertex] = []
            vertices.reserveCapacity(verticesPerSide * verticesPerSide)
            for row in 0 ... segmentCount {
                let rowOffset = Float(row) * step - halfSize
                for column in 0 ... segmentCount {
                    let columnOffset = Float(column) * step - halfSize
                    vertices.append(
                        ArtworkAccentGradientVertex(
                            position: SIMD3(columnOffset, -rowOffset, 0),
                            textureCoordinate: SIMD2(
                                Float(column) / Float(segmentCount),
                                1 - Float(row) / Float(segmentCount)
                            )
                        )
                    )
                }
            }

            var indices: [UInt32] = []
            indices.reserveCapacity(segmentCount * segmentCount * 6)
            for row in 0 ..< segmentCount {
                for column in 0 ..< segmentCount {
                    let topLeft = UInt32(column + verticesPerSide * row)
                    let bottomLeft = UInt32(column + verticesPerSide * (row + 1))
                    let bottomRight = bottomLeft + 1
                    let topRight = topLeft + 1
                    indices.append(contentsOf: [
                        topLeft, bottomLeft, topRight,
                        bottomLeft, bottomRight, topRight,
                    ])
                }
            }
            return ArtworkAccentGradientMesh(vertices: vertices, indices: indices)
        }

        public static func expandedColors(
            for palette: ArtworkAccentPalette
        ) -> [ArtworkAccentColor] {
            let colors = palette.colors.isEmpty
                ? ArtworkAccentPalette.fallback.colors
                : Array(palette.colors.prefix(5))
            switch colors.count {
            case 1:
                let color = colors[0]
                return [
                    color.scaled(by: 0.45),
                    color.scaled(by: 0.7),
                    color,
                    color.scaled(by: 1.12),
                    color.scaled(by: 0.58),
                ]
            case 2:
                return [
                    colors[0],
                    colors[0].mixed(with: colors[1], amount: 0.35),
                    colors[1],
                    colors[1].mixed(with: colors[0], amount: 0.35),
                    colors[0].scaled(by: 0.55),
                ]
            case 3:
                return [
                    colors[0],
                    colors[0].mixed(with: colors[1], amount: 0.5),
                    colors[1],
                    colors[1].mixed(with: colors[2], amount: 0.5),
                    colors[2],
                ]
            case 4:
                return colors + [colors[3].mixed(with: colors[0], amount: 0.5)]
            default:
                return colors
            }
        }

        public static func shaderColors(
            for palette: ArtworkAccentPalette
        ) -> [SIMD3<Float>] {
            expandedColors(for: palette).map { color in
                SIMD3(
                    linearComponent(color.red),
                    linearComponent(color.green),
                    linearComponent(color.blue)
                )
            }
        }

        private static func linearComponent(_ component: Double) -> Float {
            let clamped = min(max(component, 0), 1)
            if clamped <= 0.040_45 {
                return Float(clamped / 12.92)
            }
            return Float(pow((clamped + 0.055) / 1.055, 2.4))
        }

        private static var viewMatrix: simd_float4x4 {
            let target = SIMD3<Float>.zero
            let up = SIMD3<Float>(0, 1, 0)
            let backward = simd_normalize(cameraPosition - target)
            let right = simd_normalize(simd_cross(up, backward))
            let cameraUp = simd_cross(backward, right)
            return simd_float4x4(columns: (
                SIMD4(right.x, cameraUp.x, backward.x, 0),
                SIMD4(right.y, cameraUp.y, backward.y, 0),
                SIMD4(right.z, cameraUp.z, backward.z, 0),
                SIMD4(
                    -simd_dot(right, cameraPosition),
                    -simd_dot(cameraUp, cameraPosition),
                    -simd_dot(backward, cameraPosition),
                    1
                )
            ))
        }

        private static func projectionMatrix(aspectRatio: Float) -> simd_float4x4 {
            let safeAspectRatio = max(aspectRatio, 0.000_001)
            let radians = cameraFieldOfView * .pi / 180
            let verticalScale = 1 / tan(radians / 2)
            let horizontalScale = verticalScale / safeAspectRatio
            let depthScale = cameraFarPlane / (cameraNearPlane - cameraFarPlane)
            return simd_float4x4(columns: (
                SIMD4(horizontalScale, 0, 0, 0),
                SIMD4(0, verticalScale, 0, 0),
                SIMD4(0, 0, depthScale, -1),
                SIMD4(0, 0, cameraNearPlane * depthScale, 0)
            ))
        }
    }

    public struct ArtworkAccentGradientTint: Equatable, Sendable {
        public let color: ArtworkAccentColor
        public let amount: Double
        public let transitionDuration: TimeInterval

        public init(
            color: ArtworkAccentColor,
            amount: Double,
            transitionDuration: TimeInterval = 1.4
        ) {
            self.color = color
            self.amount = min(max(amount.isFinite ? amount : 0, 0), 1)
            self.transitionDuration = max(transitionDuration.isFinite ? transitionDuration : 0, 0)
        }

        public static func resolve(
            palette: ArtworkAccentPalette,
            isEffectActive: Bool,
            reducesMotion: Bool
        ) -> Self {
            let colors = palette.colors.isEmpty ? ArtworkAccentPalette.fallback.colors : palette.colors
            let darkest = colors.min { $0.relativeLuminance < $1.relativeLuminance }
                ?? ArtworkAccentColor(red: 0, green: 0, blue: 0)
            let idleOpacity = baseOpacity(for: palette)
            let activeAmount = (0.62 - idleOpacity) / (1 - idleOpacity)
            return Self(
                color: darkest.scaled(by: 0.28),
                amount: isEffectActive ? activeAmount : 0,
                transitionDuration: reducesMotion ? 0.1 : 1.4
            )
        }

        public static func baseOpacity(for palette: ArtworkAccentPalette) -> Double {
            let colors = palette.colors.isEmpty ? ArtworkAccentPalette.fallback.colors : palette.colors
            let peak = colors.map(\.relativeLuminance).max() ?? 0.15
            let progress = min(max((peak - 0.15) / (0.85 - 0.15), 0), 1)
            return 0.10 + (0.22 - 0.10) * progress
        }
    }

    public struct ArtworkAccentGradientAppearance: Equatable, Sendable {
        public let isAnimated: Bool
        public let maximumFramesPerSecond: Int
        public let tint: ArtworkAccentGradientTint

        public init(
            isAnimated: Bool,
            maximumFramesPerSecond: Int,
            tint: ArtworkAccentGradientTint
        ) {
            self.isAnimated = isAnimated
            self.maximumFramesPerSecond = max(maximumFramesPerSecond, 1)
            self.tint = tint
        }

        public static func resolve(
            palette: ArtworkAccentPalette,
            isEffectActive: Bool,
            environment: DesignNativeEnvironment
        ) -> Self {
            Self(
                isAnimated: !environment.reducesMotion,
                maximumFramesPerSecond: 60,
                tint: .resolve(
                    palette: palette,
                    isEffectActive: isEffectActive,
                    reducesMotion: environment.reducesMotion
                )
            )
        }
    }
#endif
