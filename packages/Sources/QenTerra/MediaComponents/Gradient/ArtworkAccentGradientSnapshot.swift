#if os(macOS)
    import AppKit
    import Metal
    import QenTerraDesignTokens

    @MainActor
    public enum ArtworkAccentGradientSnapshot {
        public static func render(
            palette: ArtworkAccentPalette,
            size: CGSize,
            time: Float,
            device: MTLDevice? = MTLCreateSystemDefaultDevice(),
            fallbackColor: ArtworkAccentColor = ArtworkAccentColor(red: 0, green: 0, blue: 0)
        ) -> CGImage? {
            guard let device else {
                return opaqueFallback(size: size, color: fallbackColor)
            }
            let view = ArtworkAccentGradientView(
                frame: CGRect(origin: .zero, size: size),
                device: device,
                fallbackColor: fallbackColor
            )
            let environment = DesignNativeEnvironment(
                appearance: .dark,
                productProfile: .standard,
                density: .standard,
                isIncreasedContrast: false,
                reducesMotion: true,
                reducesTransparency: false
            )
            view.update(
                palette: palette,
                appearance: .resolve(
                    palette: palette,
                    isEffectActive: false,
                    environment: environment
                )
            )
            return view.makeSnapshot(size: size, time: time)
        }

        static func opaqueFallback(
            size: CGSize,
            color: ArtworkAccentColor
        ) -> CGImage? {
            let width = max(Int(size.width.rounded()), 1)
            let height = max(Int(size.height.rounded()), 1)
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
                ?? CGColorSpaceCreateDeviceRGB()
            guard let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return nil
            }
            context.setFillColor(
                red: color.red,
                green: color.green,
                blue: color.blue,
                alpha: 1
            )
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            return context.makeImage()
        }
    }

    extension ArtworkAccentGradientRenderer {
        func makeSnapshot(size: CGSize, time: Float) -> CGImage? {
            let width = max(Int(size.width.rounded()), 1)
            let height = max(Int(size.height.rounded()), 1)
            guard
                let targets = makeSnapshotTargets(width: width, height: height),
                let commandBuffer = commandQueue.makeCommandBuffer(),
                let encoder = commandBuffer.makeRenderCommandEncoder(
                    descriptor: Self.renderPassDescriptor(for: targets)
                )
            else {
                return nil
            }
            encode(
                encoder: encoder,
                pipelineState: snapshotPipelineState,
                aspectRatio: Float(width) / Float(height),
                time: time
            )
            encoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            guard commandBuffer.status == .completed else {
                return nil
            }
            return Self.makeImage(from: targets.color, width: width, height: height)
        }
    }

    private extension ArtworkAccentGradientRenderer {
        struct SnapshotTargets {
            let color: MTLTexture
            let depth: MTLTexture
        }

        func makeSnapshotTargets(width: Int, height: Int) -> SnapshotTargets? {
            let colorDescriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .bgra8Unorm_srgb,
                width: width,
                height: height,
                mipmapped: false
            )
            colorDescriptor.storageMode = .shared
            colorDescriptor.usage = [.renderTarget]

            let depthDescriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .depth32Float,
                width: width,
                height: height,
                mipmapped: false
            )
            depthDescriptor.storageMode = .private
            depthDescriptor.usage = [.renderTarget]
            guard
                let color = device.makeTexture(descriptor: colorDescriptor),
                let depth = device.makeTexture(descriptor: depthDescriptor)
            else {
                return nil
            }
            return SnapshotTargets(color: color, depth: depth)
        }

        static func renderPassDescriptor(for targets: SnapshotTargets) -> MTLRenderPassDescriptor {
            let descriptor = MTLRenderPassDescriptor()
            descriptor.colorAttachments[0].texture = targets.color
            descriptor.colorAttachments[0].loadAction = .clear
            descriptor.colorAttachments[0].storeAction = .store
            descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
            descriptor.depthAttachment.texture = targets.depth
            descriptor.depthAttachment.loadAction = .clear
            descriptor.depthAttachment.storeAction = .dontCare
            descriptor.depthAttachment.clearDepth = 1
            return descriptor
        }

        static func makeImage(from texture: MTLTexture, width: Int, height: Int) -> CGImage? {
            let bytesPerRow = width * 4
            var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)
            pixels.withUnsafeMutableBytes { bytes in
                guard let baseAddress = bytes.baseAddress else {
                    return
                }
                texture.getBytes(
                    baseAddress,
                    bytesPerRow: bytesPerRow,
                    from: MTLRegionMake2D(0, 0, width, height),
                    mipmapLevel: 0
                )
            }
            guard let provider = CGDataProvider(data: Data(pixels) as CFData) else {
                return nil
            }
            let bitmapInfo = CGBitmapInfo.byteOrder32Little.union(
                CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
            )
            return CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: bitmapInfo,
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
            )
        }
    }
#endif
