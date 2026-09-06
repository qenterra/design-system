#if os(macOS)
    import AppKit
    import MetalKit
    import QenTerraDesignTokens
    import QuartzCore
    import SwiftUI

    /// A reusable artwork-colour terrain. The consumer retains palette extraction and effect state.
    public struct ArtworkAccentGradient: View {
        public let palette: ArtworkAccentPalette
        public let isEffectActive: Bool
        public let fallbackColor: ArtworkAccentColor
        private let explicitAppearance: ArtworkAccentGradientAppearance?

        @Environment(\.designNativeEnvironment) private var environment

        public init(
            palette: ArtworkAccentPalette,
            isEffectActive: Bool = false,
            fallbackColor: ArtworkAccentColor = ArtworkAccentColor(red: 0, green: 0, blue: 0)
        ) {
            self.palette = palette
            self.isEffectActive = isEffectActive
            self.fallbackColor = fallbackColor
            explicitAppearance = nil
        }

        public init(
            palette: ArtworkAccentPalette,
            appearance: ArtworkAccentGradientAppearance,
            fallbackColor: ArtworkAccentColor = ArtworkAccentColor(red: 0, green: 0, blue: 0)
        ) {
            self.palette = palette
            isEffectActive = appearance.tint.amount > 0
            self.fallbackColor = fallbackColor
            explicitAppearance = appearance
        }

        public var body: some View {
            let appearance = explicitAppearance
                ?? ArtworkAccentGradientAppearance.resolve(
                    palette: palette,
                    isEffectActive: isEffectActive,
                    environment: environment
                )
            ArtworkAccentGradientSurface(
                palette: palette,
                appearance: appearance,
                fallbackColor: fallbackColor
            )
            .overlay {
                Color.black
                    .opacity(ArtworkAccentGradientTint.baseOpacity(for: palette))
                    .animation(
                        appearance.isAnimated
                            ? .easeInOut(duration: ArtworkAccentGradientTransition.duration)
                            : nil,
                        value: palette
                    )
            }
            .overlay {
                Color(
                    red: appearance.tint.color.red,
                    green: appearance.tint.color.green,
                    blue: appearance.tint.color.blue
                )
                .blendMode(.multiply)
                .opacity(appearance.tint.amount)
                .animation(
                    appearance.isAnimated
                        ? .easeInOut(duration: appearance.tint.transitionDuration)
                        : nil,
                    value: appearance.tint.amount
                )
                .animation(
                    appearance.isAnimated
                        ? .easeInOut(duration: ArtworkAccentGradientTransition.duration)
                        : nil,
                    value: palette
                )
            }
            .background(
                Color(
                    red: fallbackColor.red,
                    green: fallbackColor.green,
                    blue: fallbackColor.blue
                )
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private struct ArtworkAccentGradientSurface: NSViewRepresentable {
        let palette: ArtworkAccentPalette
        let appearance: ArtworkAccentGradientAppearance
        let fallbackColor: ArtworkAccentColor

        func makeNSView(context _: Context) -> ArtworkAccentGradientView {
            ArtworkAccentGradientView(
                frame: .zero,
                device: MTLCreateSystemDefaultDevice(),
                fallbackColor: fallbackColor
            )
        }

        func updateNSView(_ view: ArtworkAccentGradientView, context _: Context) {
            view.update(palette: palette, appearance: appearance)
        }
    }

    @MainActor
    public final class ArtworkAccentGradientView: MTKView {
        private var gradientRenderer: ArtworkAccentGradientRenderer?
        private let fallbackColor: ArtworkAccentColor

        public init(
            frame frameRect: NSRect,
            device: MTLDevice?,
            fallbackColor: ArtworkAccentColor = ArtworkAccentColor(red: 0, green: 0, blue: 0)
        ) {
            self.fallbackColor = fallbackColor
            super.init(frame: frameRect, device: device)
            configureRenderer(shaderSource: ArtworkAccentGradientShader.source)
        }

        init(
            frame frameRect: NSRect,
            device: MTLDevice?,
            fallbackColor: ArtworkAccentColor,
            shaderSource: String?
        ) {
            self.fallbackColor = fallbackColor
            super.init(frame: frameRect, device: device)
            configureRenderer(shaderSource: shaderSource)
        }

        public required init(coder: NSCoder) {
            fallbackColor = ArtworkAccentColor(red: 0, green: 0, blue: 0)
            super.init(coder: coder)
            device = MTLCreateSystemDefaultDevice()
            configureRenderer(shaderSource: ArtworkAccentGradientShader.source)
        }

        override public var isOpaque: Bool {
            true
        }

        public func update(
            palette: ArtworkAccentPalette,
            appearance: ArtworkAccentGradientAppearance
        ) {
            gradientRenderer?.update(palette: palette, appearance: appearance)
            preferredFramesPerSecond = appearance.maximumFramesPerSecond
            isPaused = !appearance.isAnimated || gradientRenderer == nil
            enableSetNeedsDisplay = !appearance.isAnimated
            if isPaused {
                setNeedsDisplay(bounds)
            }
        }

        public func makeSnapshot(size: CGSize, time: Float) -> CGImage? {
            gradientRenderer?.makeSnapshot(size: size, time: time)
                ?? ArtworkAccentGradientSnapshot.opaqueFallback(
                    size: size,
                    color: fallbackColor
                )
        }

        private func configureRenderer(shaderSource: String?) {
            wantsLayer = true
            clearColor = MTLClearColorMake(
                fallbackColor.red,
                fallbackColor.green,
                fallbackColor.blue,
                1
            )
            guard let device else {
                isPaused = true
                enableSetNeedsDisplay = true
                return
            }

            framebufferOnly = true
            autoResizeDrawable = true
            colorPixelFormat = .bgra8Unorm_srgb
            depthStencilPixelFormat = .depth32Float
            sampleCount = device.supportsTextureSampleCount(4) ? 4 : 1
            preferredFramesPerSecond = 60
            enableSetNeedsDisplay = false
            isPaused = false
            if let metalLayer = layer as? CAMetalLayer {
                metalLayer.colorspace = CGColorSpace(name: CGColorSpace.sRGB)
            }

            guard let renderer = ArtworkAccentGradientRenderer(
                device: device,
                colorPixelFormat: colorPixelFormat,
                depthStencilPixelFormat: depthStencilPixelFormat,
                sampleCount: sampleCount,
                shaderSource: shaderSource
            ) else {
                isPaused = true
                enableSetNeedsDisplay = true
                return
            }
            gradientRenderer = renderer
            delegate = renderer
        }
    }

    final class ArtworkAccentGradientRenderer: NSObject, MTKViewDelegate {
        let device: MTLDevice
        let commandQueue: MTLCommandQueue
        private let pipelineState: MTLRenderPipelineState
        let snapshotPipelineState: MTLRenderPipelineState
        private let depthStencilState: MTLDepthStencilState
        private let vertexBuffer: MTLBuffer
        private let indexBuffer: MTLBuffer
        private let indexCount: Int

        private var colors: [SIMD4<Float>]
        private var paletteTransition: ArtworkAccentGradientTransition
        private var hasReceivedPalette = false
        private var isAnimated = true
        private var startedAt = CACurrentMediaTime()

        init?(
            device: MTLDevice,
            colorPixelFormat: MTLPixelFormat,
            depthStencilPixelFormat: MTLPixelFormat,
            sampleCount: Int,
            shaderSource: String?
        ) {
            guard
                let commandQueue = device.makeCommandQueue(),
                let pipelineStates = ArtworkAccentGradientResources.pipelineStates(
                    device: device,
                    colorPixelFormat: colorPixelFormat,
                    depthStencilPixelFormat: depthStencilPixelFormat,
                    sampleCount: sampleCount,
                    shaderSource: shaderSource
                ),
                let depthStencilState = ArtworkAccentGradientResources.depthStencilState(device: device),
                let buffers = ArtworkAccentGradientResources.buffers(device: device)
            else {
                return nil
            }

            self.device = device
            self.commandQueue = commandQueue
            pipelineState = pipelineStates.onscreen
            snapshotPipelineState = pipelineStates.snapshot
            self.depthStencilState = depthStencilState
            vertexBuffer = buffers.vertices
            indexBuffer = buffers.indices
            indexCount = buffers.indexCount
            colors = Self.metalColors(for: .fallback)
            paletteTransition = ArtworkAccentGradientTransition(palette: .fallback)
            super.init()
        }

        func update(
            palette: ArtworkAccentPalette,
            appearance: ArtworkAccentGradientAppearance
        ) {
            let currentTime = CACurrentMediaTime()
            paletteTransition.retarget(
                to: palette,
                at: currentTime,
                reducesMotion: !hasReceivedPalette || !appearance.isAnimated
            )
            colors = Self.metalColors(paletteTransition.colors(at: currentTime))
            hasReceivedPalette = true
            if appearance.isAnimated, !isAnimated {
                startedAt = currentTime
            }
            isAnimated = appearance.isAnimated
        }

        func mtkView(_: MTKView, drawableSizeWillChange _: CGSize) {}

        func draw(in view: MTKView) {
            let currentTime = CACurrentMediaTime()
            guard
                view.drawableSize.width > 0,
                view.drawableSize.height > 0,
                let renderPassDescriptor = view.currentRenderPassDescriptor,
                let drawable = view.currentDrawable,
                let commandBuffer = commandQueue.makeCommandBuffer(),
                let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            else {
                return
            }
            colors = Self.metalColors(paletteTransition.colors(at: currentTime))
            encode(
                encoder: encoder,
                pipelineState: pipelineState,
                aspectRatio: Float(view.drawableSize.width / view.drawableSize.height),
                time: ArtworkAccentGradientTimeline.elapsedTime(
                    startedAt: startedAt,
                    currentTime: currentTime,
                    isAnimated: isAnimated
                )
            )
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }

        func encode(
            encoder: MTLRenderCommandEncoder,
            pipelineState: MTLRenderPipelineState,
            aspectRatio: Float,
            time: Float
        ) {
            var uniforms = ArtworkAccentGradientUniforms(
                modelMatrix: ArtworkAccentGradientReference.modelMatrix,
                viewProjectionMatrix: ArtworkAccentGradientReference.viewProjectionMatrix(
                    aspectRatio: aspectRatio
                ),
                noiseFrequency: ArtworkAccentGradientReference.noiseFrequency,
                time: time,
                noiseAmount: ArtworkAccentGradientReference.noiseAmount,
                noiseSpeed: ArtworkAccentGradientReference.noiseSpeed
            )
            encoder.setRenderPipelineState(pipelineState)
            encoder.setDepthStencilState(depthStencilState)
            encoder.setFrontFacing(.counterClockwise)
            encoder.setCullMode(.back)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(
                &uniforms,
                length: MemoryLayout<ArtworkAccentGradientUniforms>.stride,
                index: 1
            )
            colors.withUnsafeBytes { bytes in
                guard let baseAddress = bytes.baseAddress else {
                    return
                }
                encoder.setVertexBytes(baseAddress, length: bytes.count, index: 2)
            }
            encoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: indexCount,
                indexType: .uint32,
                indexBuffer: indexBuffer,
                indexBufferOffset: 0
            )
        }

        private static func metalColors(for palette: ArtworkAccentPalette) -> [SIMD4<Float>] {
            metalColors(ArtworkAccentGradientReference.shaderColors(for: palette))
        }

        private static func metalColors(_ colors: [SIMD3<Float>]) -> [SIMD4<Float>] {
            colors.map { SIMD4($0.x, $0.y, $0.z, 1) }
        }
    }
#endif
