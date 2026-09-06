#if os(macOS)
    import AppKit
    import Metal
    import QenTerraDesignTokens
    @testable import QenTerraMediaComponents
    import simd
    import Testing

    @Test func artworkAccentReferenceMeshKeepsApprovedTopologyAndWinding() {
        let mesh = ArtworkAccentGradientReference.makeMesh()

        #expect(mesh.vertices.count == 40401)
        #expect(mesh.indices.count == 240_000)
        #expect(mesh.vertices[0].position == SIMD3<Float>(-0.75, 0.75, 0))
        #expect(mesh.vertices[0].textureCoordinate == SIMD2<Float>(0, 1))
        #expect(mesh.vertices[200].position == SIMD3<Float>(0.75, 0.75, 0))
        #expect(mesh.vertices[40400].position == SIMD3<Float>(0.75, -0.75, 0))
        #expect(Array(mesh.indices.prefix(6)) == [0, 201, 1, 201, 202, 1])
    }

    @Test func oneThroughFiveArtworkColoursExpandToTheProtectedFiveShaderInputs() {
        let red = ArtworkAccentColor(red: 1, green: 0, blue: 0)
        let green = ArtworkAccentColor(red: 0, green: 1, blue: 0)
        let blue = ArtworkAccentColor(red: 0, green: 0, blue: 1)
        let white = ArtworkAccentColor(red: 1, green: 1, blue: 1)
        let black = ArtworkAccentColor(red: 0, green: 0, blue: 0)

        let one = ArtworkAccentGradientReference.expandedColors(
            for: ArtworkAccentPalette(colors: [red])
        )
        #expect(one == [
            ArtworkAccentColor(red: 0.45, green: 0, blue: 0),
            ArtworkAccentColor(red: 0.7, green: 0, blue: 0),
            red,
            ArtworkAccentColor(red: 1, green: 0, blue: 0),
            ArtworkAccentColor(red: 0.58, green: 0, blue: 0),
        ])

        let two = ArtworkAccentGradientReference.expandedColors(
            for: ArtworkAccentPalette(colors: [red, blue])
        )
        #expect(two == [
            red,
            ArtworkAccentColor(red: 0.65, green: 0, blue: 0.35),
            blue,
            ArtworkAccentColor(red: 0.35, green: 0, blue: 0.65),
            ArtworkAccentColor(red: 0.55, green: 0, blue: 0),
        ])

        let three = ArtworkAccentGradientReference.expandedColors(
            for: ArtworkAccentPalette(colors: [red, green, blue])
        )
        #expect(three == [
            red,
            ArtworkAccentColor(red: 0.5, green: 0.5, blue: 0),
            green,
            ArtworkAccentColor(red: 0, green: 0.5, blue: 0.5),
            blue,
        ])

        let four = ArtworkAccentGradientReference.expandedColors(
            for: ArtworkAccentPalette(colors: [red, green, blue, white])
        )
        #expect(four == [
            red, green, blue, white,
            ArtworkAccentColor(red: 1, green: 0.5, blue: 0.5),
        ])

        let five = ArtworkAccentGradientReference.expandedColors(
            for: ArtworkAccentPalette(colors: [red, green, blue, white, black])
        )
        #expect(five == [red, green, blue, white, black])
    }

    @Test func emptyPaletteUsesTheProtectedOpaqueFallbackPalette() {
        let empty = ArtworkAccentGradientReference.shaderColors(
            for: ArtworkAccentPalette(colors: [])
        )
        let fallback = ArtworkAccentGradientReference.shaderColors(for: .fallback)

        #expect(empty == fallback)
        #expect(empty.count == 5)
    }

    @Test func artworkAccentShaderInputsConvertSRGBToLinearExactly() {
        let colors = ArtworkAccentGradientReference.shaderColors(
            for: ArtworkAccentPalette(colors: [
                ArtworkAccentColor(red: 0.040_45, green: 0.5, blue: 1),
            ])
        )

        #expect(abs(colors[2].x - 0.003_130_805) <= 0.000_000_1)
        #expect(abs(colors[2].y - 0.214_041_14) <= 0.000_000_1)
        #expect(colors[2].z == 1)
    }

    @Test func artworkAccentCameraCentersAndOverscansWidescreenFrames() {
        let model = ArtworkAccentGradientReference.modelMatrix
        let projection = ArtworkAccentGradientReference.viewProjectionMatrix(
            aspectRatio: 16 / 9
        )
        let center = projection * model * SIMD4<Float>(0, 0, 0, 1)
        let corner = projection * model * SIMD4<Float>(-0.75, 0.75, 0, 1)
        let centerNDC = center / center.w
        let cornerNDC = corner / corner.w

        #expect(abs(centerNDC.x) <= 0.000_001)
        #expect(abs(centerNDC.y) <= 0.000_001)
        #expect(cornerNDC.x < -1)
        #expect(cornerNDC.y > 1)
    }

    @Test func paletteTransitionUsesEightTenthsSmoothstep() {
        let black = ArtworkAccentPalette(colors: [.black])
        let white = ArtworkAccentPalette(colors: [.white])
        var transition = ArtworkAccentGradientTransition(palette: black)

        transition.retarget(to: white, at: 10, reducesMotion: false)

        let target = ArtworkAccentGradientReference.shaderColors(for: white)
        #expect(ArtworkAccentGradientTransition.duration == 0.8)
        #expect(transition.colors(at: 10).allSatisfy { $0 == .zero })
        #expect(zip(transition.colors(at: 10.2), target).allSatisfy {
            approximatelyEqual($0, $1 * 0.15625)
        })
        #expect(zip(transition.colors(at: 10.4), target).allSatisfy {
            approximatelyEqual($0, $1 * 0.5)
        })
        #expect(zip(transition.colors(at: 10.8), target).allSatisfy {
            approximatelyEqual($0, $1)
        })
    }

    @Test func interruptedPaletteTransitionContinuesFromVisibleColours() {
        var transition = ArtworkAccentGradientTransition(
            palette: ArtworkAccentPalette(colors: [.black])
        )
        transition.retarget(
            to: ArtworkAccentPalette(colors: [.white]),
            at: 0,
            reducesMotion: false
        )
        let visible = transition.colors(at: 0.4)

        transition.retarget(
            to: ArtworkAccentPalette(colors: [.red]),
            at: 0.4,
            reducesMotion: false
        )

        #expect(zip(transition.colors(at: 0.4), visible).allSatisfy {
            approximatelyEqual($0, $1)
        })
    }

    @Test func reducedMotionReplacesPaletteImmediatelyAndFreezesTime() {
        var transition = ArtworkAccentGradientTransition(
            palette: ArtworkAccentPalette(colors: [.black])
        )
        let blue = ArtworkAccentPalette(colors: [.blue])
        transition.retarget(to: blue, at: 4, reducesMotion: true)

        #expect(transition.colors(at: 4) == ArtworkAccentGradientReference.shaderColors(for: blue))
        #expect(ArtworkAccentGradientTimeline.elapsedTime(startedAt: 10, currentTime: 14.5, isAnimated: true) == 4.5)
        #expect(ArtworkAccentGradientTimeline.elapsedTime(startedAt: 10, currentTime: 14.5, isAnimated: false) == 0)
    }

    @Test func tintResolutionPreservesIdleDarkeningAndSymmetricEffectTiming() {
        let black = ArtworkAccentPalette(colors: [.black])
        let gray = ArtworkAccentPalette(colors: [
            ArtworkAccentColor(red: 0.5, green: 0.5, blue: 0.5),
        ])
        let white = ArtworkAccentPalette(colors: [.white])

        #expect(ArtworkAccentGradientTint.baseOpacity(for: black) == 0.10)
        #expect(ArtworkAccentGradientTint.baseOpacity(for: gray) == 0.16)
        #expect(ArtworkAccentGradientTint.baseOpacity(for: white) == 0.22)

        let inactive = ArtworkAccentGradientTint.resolve(
            palette: gray,
            isEffectActive: false,
            reducesMotion: false
        )
        let active = ArtworkAccentGradientTint.resolve(
            palette: gray,
            isEffectActive: true,
            reducesMotion: false
        )
        let reduced = ArtworkAccentGradientTint.resolve(
            palette: gray,
            isEffectActive: true,
            reducesMotion: true
        )

        #expect(inactive.amount == 0)
        #expect(active.color == ArtworkAccentColor(red: 0.14, green: 0.14, blue: 0.14))
        #expect(abs(1 - (1 - 0.16) * (1 - active.amount) - 0.62) <= 0.000_001)
        #expect(inactive.transitionDuration == 1.4)
        #expect(active.transitionDuration == 1.4)
        #expect(reduced.transitionDuration == 0.1)
    }

    @Test func appearanceUsesEnvironmentMotionAndExactFrameLimit() {
        let palette = ArtworkAccentPalette(colors: [.white])
        let regular = ArtworkAccentGradientAppearance.resolve(
            palette: palette,
            isEffectActive: true,
            environment: environment(reducesMotion: false)
        )
        let reduced = ArtworkAccentGradientAppearance.resolve(
            palette: palette,
            isEffectActive: true,
            environment: environment(reducesMotion: true)
        )

        #expect(regular.isAnimated)
        #expect(regular.maximumFramesPerSecond == 60)
        #expect(regular.tint.amount > 0)
        #expect(!reduced.isAnimated)
        #expect(reduced.maximumFramesPerSecond == 60)
    }

    @Test func swiftUISurfaceAcceptsAnExplicitRendererAppearance() {
        let palette = ArtworkAccentPalette(colors: [.white])
        let appearance = ArtworkAccentGradientAppearance(
            isAnimated: false,
            maximumFramesPerSecond: 24,
            tint: ArtworkAccentGradientTint(
                color: .red,
                amount: 0.4,
                transitionDuration: 1.4
            )
        )

        _ = ArtworkAccentGradient(
            palette: palette,
            appearance: appearance,
            fallbackColor: .black
        )
    }

    @MainActor
    @Test func missingMetalDeviceProducesAnOpaqueStaticFallback() throws {
        let view = ArtworkAccentGradientView(
            frame: CGRect(x: 0, y: 0, width: 40, height: 30),
            device: nil
        )
        view.update(
            palette: ArtworkAccentPalette(colors: [.red]),
            appearance: ArtworkAccentGradientAppearance.resolve(
                palette: ArtworkAccentPalette(colors: [.red]),
                isEffectActive: false,
                environment: environment(reducesMotion: false)
            )
        )

        #expect(view.isOpaque)
        #expect(view.isPaused)
        #expect(view.delegate == nil)
        let image = try #require(ArtworkAccentGradientSnapshot.render(
            palette: ArtworkAccentPalette(colors: [.red]),
            size: CGSize(width: 40, height: 30),
            time: 0,
            device: nil
        ))
        #expect(image.width == 40)
        #expect(image.height == 30)
        #expect(opaqueBlackPixelCount(in: image) == 1200)
    }

    @Test func packagedRuntimeShaderResourceIsAvailableToThePublicTarget() {
        #expect(ArtworkAccentGradientResourceAvailability.hasPackagedShader)
    }

    @MainActor
    @Test(.enabled(if: MTLCreateSystemDefaultDevice() != nil))
    func missingShaderProducesTheConfiguredOpaqueFallback() throws {
        let device = try #require(MTLCreateSystemDefaultDevice())
        let fallback = ArtworkAccentColor(red: 0.25, green: 0.5, blue: 0.75)
        let view = ArtworkAccentGradientView(
            frame: CGRect(x: 0, y: 0, width: 40, height: 30),
            device: device,
            fallbackColor: fallback,
            shaderSource: nil
        )

        #expect(view.isPaused)
        #expect(view.delegate == nil)
        let image = try #require(
            view.makeSnapshot(size: CGSize(width: 40, height: 30), time: 0)
        )
        let pixel = try #require(firstRGBA8Pixel(in: image))
        #expect(abs(Int(pixel.0) - 64) <= 1)
        #expect(abs(Int(pixel.1) - 128) <= 1)
        #expect(abs(Int(pixel.2) - 191) <= 1)
        #expect(pixel.3 == 255)
    }

    @MainActor
    @Test(.enabled(if: MTLCreateSystemDefaultDevice() != nil))
    func packagedShaderBuildsTheExactSRGBMultisampledRenderer() throws {
        let device = try #require(MTLCreateSystemDefaultDevice())
        let view = ArtworkAccentGradientView(
            frame: CGRect(x: 0, y: 0, width: 320, height: 240),
            device: device
        )
        let palette = ArtworkAccentPalette.reference
        view.update(
            palette: palette,
            appearance: ArtworkAccentGradientAppearance.resolve(
                palette: palette,
                isEffectActive: false,
                environment: environment(reducesMotion: true)
            )
        )

        #expect(view.colorPixelFormat == .bgra8Unorm_srgb)
        #expect(view.depthStencilPixelFormat == .depth32Float)
        #expect(view.sampleCount == (device.supportsTextureSampleCount(4) ? 4 : 1))
        #expect(view.delegate != nil)
        let image = try #require(
            view.makeSnapshot(size: CGSize(width: 320, height: 240), time: 0)
        )
        #expect(image.width == 320)
        #expect(image.height == 240)
        #expect(distinctChromaticPixelCount(in: image) > 32)
    }

    private extension ArtworkAccentColor {
        static let black = ArtworkAccentColor(red: 0, green: 0, blue: 0)
        static let white = ArtworkAccentColor(red: 1, green: 1, blue: 1)
        static let red = ArtworkAccentColor(red: 1, green: 0, blue: 0)
        static let blue = ArtworkAccentColor(red: 0, green: 0, blue: 1)
    }

    private extension ArtworkAccentPalette {
        static let reference = ArtworkAccentPalette(colors: [
            ArtworkAccentColor(red: 0x8E / 255, green: 0xCA / 255, blue: 0xE6 / 255),
            ArtworkAccentColor(red: 0x21 / 255, green: 0x9E / 255, blue: 0xBC / 255),
            ArtworkAccentColor(red: 0x02 / 255, green: 0x30 / 255, blue: 0x47 / 255),
            ArtworkAccentColor(red: 0xFF / 255, green: 0xB7 / 255, blue: 0x03 / 255),
            ArtworkAccentColor(red: 0xFB / 255, green: 0x85 / 255, blue: 0),
        ])
    }

    private func environment(reducesMotion: Bool) -> DesignNativeEnvironment {
        DesignNativeEnvironment(
            appearance: .dark,
            productProfile: .standard,
            density: .standard,
            isIncreasedContrast: false,
            reducesMotion: reducesMotion,
            reducesTransparency: false
        )
    }

    private func approximatelyEqual(
        _ lhs: SIMD3<Float>,
        _ rhs: SIMD3<Float>,
        tolerance: Float = 0.000_01
    ) -> Bool {
        simd_distance(lhs, rhs) <= tolerance
    }

    private func opaqueBlackPixelCount(in image: CGImage) -> Int {
        let bitmap = NSBitmapImageRep(cgImage: image)
        var count = 0
        for y in 0 ..< bitmap.pixelsHigh {
            for x in 0 ..< bitmap.pixelsWide {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else {
                    continue
                }
                if color.alphaComponent > 0.999,
                   color.redComponent < 0.001,
                   color.greenComponent < 0.001,
                   color.blueComponent < 0.001
                {
                    count += 1
                }
            }
        }
        return count
    }

    private func firstRGBA8Pixel(in image: CGImage) -> (UInt8, UInt8, UInt8, UInt8)? {
        guard
            let data = image.dataProvider?.data,
            let bytes = CFDataGetBytePtr(data),
            CFDataGetLength(data) >= 4
        else {
            return nil
        }
        return (bytes[0], bytes[1], bytes[2], bytes[3])
    }

    private func distinctChromaticPixelCount(in image: CGImage) -> Int {
        let bitmap = NSBitmapImageRep(cgImage: image)
        var colors: Set<UInt32> = []
        for y in stride(from: 0, to: bitmap.pixelsHigh, by: 12) {
            for x in stride(from: 0, to: bitmap.pixelsWide, by: 12) {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else {
                    continue
                }
                let red = UInt32((color.redComponent * 255).rounded())
                let green = UInt32((color.greenComponent * 255).rounded())
                let blue = UInt32((color.blueComponent * 255).rounded())
                if max(red, green, blue) - min(red, green, blue) > 12 {
                    colors.insert((red << 16) | (green << 8) | blue)
                }
            }
        }
        return colors.count
    }
#endif
