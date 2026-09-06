#if os(macOS)
    import Foundation
    import Metal
    import simd

    struct ArtworkAccentGradientUniforms {
        var modelMatrix: simd_float4x4
        var viewProjectionMatrix: simd_float4x4
        var noiseFrequency: SIMD2<Float>
        var time: Float
        var noiseAmount: Float
        var noiseSpeed: Float
        var padding0: Float = 0
        var padding1: Float = 0
        var padding2: Float = 0
    }

    struct ArtworkAccentGradientPipelineStates {
        let onscreen: MTLRenderPipelineState
        let snapshot: MTLRenderPipelineState
    }

    struct ArtworkAccentGradientBuffers {
        let vertices: MTLBuffer
        let indices: MTLBuffer
        let indexCount: Int
    }

    enum ArtworkAccentGradientShader {
        static let source: String? = Bundle.module.url(
            forResource: "ArtworkAccentGradientShader",
            withExtension: "metal.txt"
        ).flatMap { try? String(contentsOf: $0, encoding: .utf8) }
    }

    /// Read-only package-resource availability for hosts that expose diagnostics.
    public enum ArtworkAccentGradientResourceAvailability {
        public static var hasPackagedShader: Bool {
            ArtworkAccentGradientShader.source != nil
        }
    }

    /// Starts optional shader compilation off the UI thread. The renderer reuses the same library.
    public enum ArtworkAccentGradientPrewarmer {
        public static func prepare() {
            Task.detached(priority: .utility) {
                _ = ArtworkAccentGradientResources.preparedDefaultLibrary
            }
        }
    }

    enum ArtworkAccentGradientResources {
        static func pipelineStates(
            device: MTLDevice,
            colorPixelFormat: MTLPixelFormat,
            depthStencilPixelFormat: MTLPixelFormat,
            sampleCount: Int,
            shaderSource: String? = ArtworkAccentGradientShader.source
        ) -> ArtworkAccentGradientPipelineStates? {
            guard
                let library = library(device: device, shaderSource: shaderSource),
                let vertexFunction = library.makeFunction(name: "artworkAccentGradientVertex"),
                let fragmentFunction = library.makeFunction(name: "artworkAccentGradientFragment")
            else {
                return nil
            }

            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertexFunction
            descriptor.fragmentFunction = fragmentFunction
            descriptor.colorAttachments[0].pixelFormat = colorPixelFormat
            descriptor.depthAttachmentPixelFormat = depthStencilPixelFormat
            descriptor.rasterSampleCount = sampleCount
            guard let onscreen = try? device.makeRenderPipelineState(descriptor: descriptor) else {
                return nil
            }
            descriptor.rasterSampleCount = 1
            guard let snapshot = try? device.makeRenderPipelineState(descriptor: descriptor) else {
                return nil
            }
            return ArtworkAccentGradientPipelineStates(onscreen: onscreen, snapshot: snapshot)
        }

        static func library(device: MTLDevice, shaderSource: String?) -> MTLLibrary? {
            guard let shaderSource else { return nil }
            if shaderSource == ArtworkAccentGradientShader.source,
               let preparedDefaultLibrary,
               preparedDefaultLibrary.registryID == device.registryID
            {
                return preparedDefaultLibrary.library
            }
            return try? device.makeLibrary(source: shaderSource, options: nil)
        }

        static let preparedDefaultLibrary: PreparedArtworkAccentLibrary? = {
            guard let device = MTLCreateSystemDefaultDevice(),
                  let source = ArtworkAccentGradientShader.source,
                  let library = try? device.makeLibrary(source: source, options: nil) else { return nil }
            return PreparedArtworkAccentLibrary(registryID: device.registryID, library: library)
        }()

        static func depthStencilState(device: MTLDevice) -> MTLDepthStencilState? {
            let descriptor = MTLDepthStencilDescriptor()
            descriptor.depthCompareFunction = .less
            descriptor.isDepthWriteEnabled = true
            return device.makeDepthStencilState(descriptor: descriptor)
        }

        static func buffers(device: MTLDevice) -> ArtworkAccentGradientBuffers? {
            let mesh = ArtworkAccentGradientReference.makeMesh()
            let vertices: MTLBuffer? = mesh.vertices.withUnsafeBytes { bytes in
                guard let baseAddress = bytes.baseAddress else {
                    return nil
                }
                return device.makeBuffer(
                    bytes: baseAddress,
                    length: bytes.count,
                    options: .storageModeShared
                )
            }
            let indices: MTLBuffer? = mesh.indices.withUnsafeBytes { bytes in
                guard let baseAddress = bytes.baseAddress else {
                    return nil
                }
                return device.makeBuffer(
                    bytes: baseAddress,
                    length: bytes.count,
                    options: .storageModeShared
                )
            }
            guard let vertices, let indices else {
                return nil
            }
            return ArtworkAccentGradientBuffers(
                vertices: vertices,
                indices: indices,
                indexCount: mesh.indices.count
            )
        }
    }

    /// Immutable Metal library; Swift static initialization serializes the single compilation.
    final class PreparedArtworkAccentLibrary: @unchecked Sendable {
        let registryID: UInt64
        let library: MTLLibrary

        init(registryID: UInt64, library: MTLLibrary) {
            self.registryID = registryID
            self.library = library
        }
    }
#endif
