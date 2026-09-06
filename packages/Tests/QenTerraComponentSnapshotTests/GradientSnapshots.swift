#if os(macOS)
import AppKit
import Metal
import QenTerraDesignTokens
import QenTerraMediaComponents
import SwiftUI
import Testing

@MainActor
@Suite("Artwork accent gradient snapshots", .serialized)
struct GradientSnapshots {
    @Test(arguments: [DesignAppearancePreference.light, .dark])
    func appearance(appearance: DesignAppearancePreference) throws {
        try hostedSnapshot(
            name: "gradient-appearance-\(appearance.rawValue)",
            size: CGSize(width: 720, height: 420),
            appearance: appearance,
            reducesMotion: true
        ) {
            ArtworkAccentGradient(palette: .primary)
        }
    }

    @Test
    func paletteEndpointsAndInterruption() throws {
        var transition = ArtworkAccentGradientTransition(palette: .primary)
        transition.retarget(to: .secondary, at: 10, reducesMotion: false)
        let interrupted = transition.colors(at: 10.4)
        transition.retarget(to: .tertiary, at: 10.4, reducesMotion: false)

        try hostedSnapshot(name: "gradient-palette-start", size: .init(width: 560, height: 320)) {
            ArtworkAccentGradient(palette: .primary, appearance: staticAppearance(for: .primary))
        }
        try hostedSnapshot(name: "gradient-palette-interruption", size: .init(width: 560, height: 320)) {
            let palette = ArtworkAccentPalette(colors: interrupted.map(sRGBColor(fromLinear:)))
            ArtworkAccentGradient(palette: palette, appearance: staticAppearance(for: palette))
        }
        try hostedSnapshot(name: "gradient-palette-end", size: .init(width: 560, height: 320)) {
            ArtworkAccentGradient(palette: .tertiary, appearance: staticAppearance(for: .tertiary))
        }
    }

    @Test(arguments: [false, true])
    func tint(isActive: Bool) throws {
        try hostedSnapshot(name: "gradient-tint-\(isActive ? "active" : "idle")", size: .init(width: 720, height: 420)) {
            ArtworkAccentGradient(
                palette: .primary,
                appearance: ArtworkAccentGradientAppearance(
                    isAnimated: false,
                    maximumFramesPerSecond: 60,
                    tint: .resolve(palette: .primary, isEffectActive: isActive, reducesMotion: true)
                )
            )
        }
    }

    @Test
    func reducedMotion() throws {
        try hostedSnapshot(
            name: "gradient-reduced-motion",
            size: .init(width: 720, height: 420),
            reducesMotion: true
        ) {
            ArtworkAccentGradient(palette: .secondary, isEffectActive: true)
        }
    }

    @Test
    func opaqueFallback() throws {
        let fallback = ArtworkAccentColor(red: 0.08, green: 0.11, blue: 0.17)
        guard let image = ArtworkAccentGradientSnapshot.render(
            palette: .primary,
            size: CGSize(width: 720, height: 420),
            time: 4.25,
            device: nil,
            fallbackColor: fallback
        ) else {
            throw SnapshotFailure.rendering("Gradient fallback did not produce an image")
        }
        try assertSnapshotImage(RGBAImage(cgImage: image), name: "gradient-opaque-fallback")
    }

    @Test(arguments: [
        GradientBoundary(name: "320x240", width: 320, height: 240),
        GradientBoundary(name: "720x720", width: 720, height: 720),
        GradientBoundary(name: "2560x1400", width: 2_560, height: 1_400),
    ])
    func fixedTimeRenderBoundary(boundary: GradientBoundary) throws {
        guard let image = ArtworkAccentGradientSnapshot.render(
            palette: .primary,
            size: boundary.size,
            time: 4.25
        ) else {
            throw SnapshotFailure.rendering("Gradient boundary \(boundary.name) did not produce an image")
        }
        try assertSnapshotImage(
            RGBAImage(cgImage: image),
            name: "gradient-boundary-\(boundary.name)"
        )
    }

    private func hostedSnapshot<Content: View>(
        name: String,
        size: CGSize,
        appearance: DesignAppearancePreference = .dark,
        reducesMotion: Bool = true,
        @ViewBuilder content: () -> Content
    ) throws {
        let host = try NativeSnapshotHost(
            size: size,
            configuration: DesignSystemConfiguration(
                appearance: appearance,
                productProfile: .cadence,
                density: .standard
            ),
            accessibility: .init(reducesMotion: reducesMotion),
            content: content
        )
        try assertSnapshotImage(host.render(), name: name)
    }

    private func staticAppearance(for palette: ArtworkAccentPalette) -> ArtworkAccentGradientAppearance {
        ArtworkAccentGradientAppearance(
            isAnimated: false,
            maximumFramesPerSecond: 60,
            tint: .resolve(palette: palette, isEffectActive: false, reducesMotion: true)
        )
    }

    private func sRGBColor(fromLinear color: SIMD3<Float>) -> ArtworkAccentColor {
        func component(_ value: Float) -> Double {
            let linear = Double(min(max(value, 0), 1))
            return linear <= 0.003_130_8
                ? linear * 12.92
                : 1.055 * pow(linear, 1 / 2.4) - 0.055
        }
        return ArtworkAccentColor(red: component(color.x), green: component(color.y), blue: component(color.z))
    }
}

struct GradientBoundary: CustomTestStringConvertible, Sendable {
    let name: String
    let width: Int
    let height: Int

    var size: CGSize { CGSize(width: width, height: height) }
    var testDescription: String { name }
}

private extension ArtworkAccentPalette {
    static let primary = ArtworkAccentPalette(colors: [
        ArtworkAccentColor(red: 0.08, green: 0.20, blue: 0.58),
        ArtworkAccentColor(red: 0.16, green: 0.64, blue: 0.88),
        ArtworkAccentColor(red: 0.80, green: 0.22, blue: 0.50),
        ArtworkAccentColor(red: 0.96, green: 0.56, blue: 0.18),
        ArtworkAccentColor(red: 0.28, green: 0.10, blue: 0.46),
    ])

    static let secondary = ArtworkAccentPalette(colors: [
        ArtworkAccentColor(red: 0.05, green: 0.44, blue: 0.36),
        ArtworkAccentColor(red: 0.28, green: 0.78, blue: 0.60),
        ArtworkAccentColor(red: 0.95, green: 0.72, blue: 0.18),
    ])

    static let tertiary = ArtworkAccentPalette(colors: [
        ArtworkAccentColor(red: 0.32, green: 0.08, blue: 0.52),
        ArtworkAccentColor(red: 0.80, green: 0.16, blue: 0.60),
        ArtworkAccentColor(red: 0.98, green: 0.42, blue: 0.32),
        ArtworkAccentColor(red: 0.22, green: 0.46, blue: 0.90),
    ])
}
#endif
