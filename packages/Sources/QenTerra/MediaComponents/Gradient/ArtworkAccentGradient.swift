#if os(macOS)
    import AppKit
    import MetalKit
    import QenTerraDesignTokens
    import QuartzCore
    import SwiftUI

    /// A reusable artwork-colour terrain. The consumer retains palette extraction and effect state.
    /// `ArtworkAccentGradientView` is the single composition boundary for terrain, idle
    /// darkening, effect tint, and the opaque failure fallback used by both public surfaces.
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

    /// The AppKit composition surface shared by direct AppKit and SwiftUI consumers.
    /// It owns the Metal terrain, appearance overlays, and opaque failure presentation.
    @MainActor
    public final class ArtworkAccentGradientView: NSView {
        private var gradientRenderer: ArtworkAccentGradientRenderer?
        private let fallbackColor: ArtworkAccentColor
        private let metalView: MTKView
        private let fallbackOverlay = ArtworkAccentGradientOverlayView()
        private let idleOverlay = ArtworkAccentGradientOverlayView()
        private let tintOverlay = ArtworkAccentGradientOverlayView()
        private var hasAppliedComposition = false

        public init(
            frame frameRect: NSRect,
            device: MTLDevice?,
            fallbackColor: ArtworkAccentColor = ArtworkAccentColor(red: 0, green: 0, blue: 0)
        ) {
            self.fallbackColor = fallbackColor
            metalView = MTKView(frame: frameRect, device: device)
            super.init(frame: frameRect)
            configureComposition()
            configureRenderer(shaderSource: ArtworkAccentGradientShader.source)
        }

        init(
            frame frameRect: NSRect,
            device: MTLDevice?,
            fallbackColor: ArtworkAccentColor,
            shaderSource: String?
        ) {
            self.fallbackColor = fallbackColor
            metalView = MTKView(frame: frameRect, device: device)
            super.init(frame: frameRect)
            configureComposition()
            configureRenderer(shaderSource: shaderSource)
        }

        public required init?(coder: NSCoder) {
            fallbackColor = ArtworkAccentColor(red: 0, green: 0, blue: 0)
            metalView = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
            super.init(coder: coder)
            configureComposition()
            configureRenderer(shaderSource: ArtworkAccentGradientShader.source)
        }

        override public var isOpaque: Bool {
            true
        }

        override public func layout() {
            super.layout()
            metalView.frame = bounds
            fallbackOverlay.frame = bounds
            idleOverlay.frame = bounds
            tintOverlay.frame = bounds
        }

        override public func draw(_ dirtyRect: NSRect) {
            if let image = gradientRenderer?.makeSnapshot(size: bounds.size, time: 0),
               let context = NSGraphicsContext.current?.cgContext
            {
                context.saveGState()
                context.interpolationQuality = .high
                context.draw(image, in: bounds)
                context.restoreGState()
                return
            }
            NSColor(
                srgbRed: fallbackColor.red,
                green: fallbackColor.green,
                blue: fallbackColor.blue,
                alpha: 1
            ).setFill()
            dirtyRect.fill()
        }

        public var colorPixelFormat: MTLPixelFormat {
            metalView.colorPixelFormat
        }

        public var depthStencilPixelFormat: MTLPixelFormat {
            metalView.depthStencilPixelFormat
        }

        public var sampleCount: Int {
            metalView.sampleCount
        }

        public var delegate: MTKViewDelegate? {
            metalView.delegate
        }

        public var preferredFramesPerSecond: Int {
            get { metalView.preferredFramesPerSecond }
            set { metalView.preferredFramesPerSecond = newValue }
        }

        public var isPaused: Bool {
            get { metalView.isPaused }
            set { metalView.isPaused = newValue }
        }

        public var enableSetNeedsDisplay: Bool {
            get { metalView.enableSetNeedsDisplay }
            set { metalView.enableSetNeedsDisplay = newValue }
        }

        public func update(
            palette: ArtworkAccentPalette,
            appearance: ArtworkAccentGradientAppearance
        ) {
            gradientRenderer?.update(palette: palette, appearance: appearance)
            updateComposition(palette: palette, appearance: appearance)
            preferredFramesPerSecond = appearance.maximumFramesPerSecond
            isPaused = !appearance.isAnimated || gradientRenderer == nil
            enableSetNeedsDisplay = !appearance.isAnimated
            if isPaused {
                setNeedsDisplay(bounds)
                metalView.setNeedsDisplay(metalView.bounds)
            }
        }

        /// Renders the raw terrain for deterministic reference comparison.
        /// Capture the hosted view when validating appearance tint or fallback presentation.
        public func makeSnapshot(size: CGSize, time: Float) -> CGImage? {
            gradientRenderer?.makeSnapshot(size: size, time: time)
                ?? ArtworkAccentGradientSnapshot.opaqueFallback(
                    size: size,
                    color: fallbackColor
                )
        }

        private func configureRenderer(shaderSource: String?) {
            wantsLayer = true
            layer?.backgroundColor = fallbackColor.cgColor
            metalView.clearColor = MTLClearColorMake(
                fallbackColor.red,
                fallbackColor.green,
                fallbackColor.blue,
                1
            )
            metalView.isHidden = true
            guard let device = metalView.device else {
                isPaused = true
                enableSetNeedsDisplay = true
                return
            }

            metalView.framebufferOnly = true
            metalView.autoResizeDrawable = true
            metalView.colorPixelFormat = .bgra8Unorm_srgb
            metalView.depthStencilPixelFormat = .depth32Float
            metalView.sampleCount = device.supportsTextureSampleCount(4) ? 4 : 1
            preferredFramesPerSecond = 60
            enableSetNeedsDisplay = false
            isPaused = false
            if let metalLayer = metalView.layer as? CAMetalLayer {
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
            metalView.delegate = renderer
            metalView.isHidden = false
            fallbackOverlay.isHidden = true
        }

        private func configureComposition() {
            wantsLayer = true
            layer?.backgroundColor = fallbackColor.cgColor
            metalView.frame = bounds
            metalView.autoresizingMask = [.width, .height]
            addSubview(metalView)
            fallbackOverlay.frame = bounds
            fallbackOverlay.autoresizingMask = [.width, .height]
            fallbackOverlay.overlayColor = fallbackColor
            addSubview(fallbackOverlay)
            idleOverlay.frame = bounds
            idleOverlay.autoresizingMask = [.width, .height]
            idleOverlay.overlayColor = ArtworkAccentColor(red: 0, green: 0, blue: 0)
            idleOverlay.apply(
                color: ArtworkAccentColor(red: 0, green: 0, blue: 0),
                opacity: 0,
                duration: 0,
                animated: false
            )
            addSubview(idleOverlay)
            tintOverlay.frame = bounds
            tintOverlay.autoresizingMask = [.width, .height]
            tintOverlay.usesMultiplyBlend = true
            tintOverlay.apply(color: fallbackColor, opacity: 0, duration: 0, animated: false)
            addSubview(tintOverlay)
        }

        private func updateComposition(
            palette: ArtworkAccentPalette,
            appearance: ArtworkAccentGradientAppearance
        ) {
            guard gradientRenderer != nil else {
                idleOverlay.apply(color: fallbackColor, opacity: 0, duration: 0, animated: false)
                tintOverlay.apply(color: fallbackColor, opacity: 0, duration: 0, animated: false)
                hasAppliedComposition = true
                return
            }
            let animates = hasAppliedComposition && appearance.isAnimated
            idleOverlay.apply(
                color: ArtworkAccentColor(red: 0, green: 0, blue: 0),
                opacity: ArtworkAccentGradientTint.baseOpacity(for: palette),
                duration: ArtworkAccentGradientTransition.duration,
                animated: animates
            )
            tintOverlay.apply(
                color: appearance.tint.color,
                opacity: appearance.tint.amount,
                duration: appearance.tint.transitionDuration,
                animated: animates
            )
            hasAppliedComposition = true
        }
    }

    @MainActor
    private final class ArtworkAccentGradientOverlayView: NSView {
        var usesMultiplyBlend = false {
            didSet {
                wantsLayer = true
                layer?.compositingFilter = usesMultiplyBlend ? "multiplyBlendMode" : nil
            }
        }

        var overlayColor = ArtworkAccentColor(red: 0, green: 0, blue: 0)

        override var isOpaque: Bool {
            false
        }

        override func hitTest(_: NSPoint) -> NSView? {
            nil
        }

        override func draw(_ dirtyRect: NSRect) {
            guard let context = NSGraphicsContext.current?.cgContext else {
                return
            }
            context.saveGState()
            NSColor(
                srgbRed: overlayColor.red,
                green: overlayColor.green,
                blue: overlayColor.blue,
                alpha: 1
            ).setFill()
            dirtyRect.fill()
            context.restoreGState()
        }

        func apply(
            color: ArtworkAccentColor,
            opacity: Double,
            duration: TimeInterval,
            animated: Bool
        ) {
            wantsLayer = true
            let oldOpacity = layer?.presentation()?.opacity ?? layer?.opacity ?? 0
            overlayColor = color
            needsDisplay = true
            layer?.opacity = Float(opacity)
            layer?.removeAllAnimations()
            guard animated, duration > 0, abs(oldOpacity - Float(opacity)) > 0.000_001 else {
                return
            }
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = oldOpacity
            animation.toValue = Float(opacity)
            animation.duration = duration
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            layer?.add(animation, forKey: "artworkAccentOpacity")
        }
    }

    private extension ArtworkAccentColor {
        var cgColor: CGColor {
            CGColor(
                colorSpace: CGColorSpace(name: CGColorSpace.sRGB)
                    ?? CGColorSpaceCreateDeviceRGB(),
                components: [red, green, blue, 1]
            ) ?? CGColor(gray: 0, alpha: 1)
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
