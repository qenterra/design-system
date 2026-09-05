#if os(macOS)
import AppKit
import QuartzCore
import SwiftUI
import QenTerraDesignTokens

enum SnapshotFailure: Error, Equatable, CustomStringConvertible {
    case missingProfile(String)
    case missingReference(String)
    case dimensions(expectedWidth: Int, expectedHeight: Int, actualWidth: Int, actualHeight: Int)
    case pixels(x: Int, y: Int, channel: Int, expected: UInt8, actual: UInt8)
    case rendering(String)

    var description: String {
        switch self {
        case let .missingProfile(path):
            return "Missing native snapshot profile: \(path). Capture and visually review references on this OS/architecture; no other profile is substituted."
        case let .missingReference(path):
            return "Missing snapshot: \(path). Record explicitly with QDS_RECORD_SNAPSHOTS=1, then inspect the PNG."
        case let .dimensions(ew, eh, aw, ah):
            return "Snapshot dimensions differ: expected \(ew)×\(eh), actual \(aw)×\(ah)."
        case let .pixels(x, y, channel, expected, actual):
            return "Snapshot pixel (\(x), \(y)), RGBA channel \(channel): expected \(expected), actual \(actual); tolerance is 3/255."
        case let .rendering(message):
            return "Snapshot rendering failed: \(message)"
        }
    }
}

/// Canonical sRGB, 8-bit premultiplied RGBA; every channel, including alpha, is compared.
struct RGBAImage: Equatable {
    let width: Int
    let height: Int
    let pixels: [UInt8]

    init(width: Int, height: Int, pixels: [UInt8]) throws {
        guard width > 0, height > 0, pixels.count == width * height * 4 else {
            throw SnapshotFailure.rendering("Invalid RGBA dimensions or byte count")
        }
        self.width = width
        self.height = height
        self.pixels = pixels
    }

    init(cgImage: CGImage) throws {
        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        try pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { throw SnapshotFailure.rendering("Cannot allocate sRGB bitmap context") }
            context.setBlendMode(.copy)
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        try self.init(width: width, height: height, pixels: pixels)
    }

    init(png: Data) throws {
        guard let representation = NSBitmapImageRep(data: png), let image = representation.cgImage else {
            throw SnapshotFailure.rendering("Reference is not a decodable PNG")
        }
        try self.init(cgImage: image)
    }

    func pngData() throws -> Data {
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let image = CGImage(
                width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
              ),
              let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
            throw SnapshotFailure.rendering("Cannot encode RGBA PNG")
        }
        return data
    }

    func compare(_ actual: RGBAImage) throws {
        guard width == actual.width, height == actual.height else {
            throw SnapshotFailure.dimensions(expectedWidth: width, expectedHeight: height, actualWidth: actual.width, actualHeight: actual.height)
        }
        for index in pixels.indices where abs(Int(pixels[index]) - Int(actual.pixels[index])) > 3 {
            throw SnapshotFailure.pixels(
                x: (index / 4) % width, y: (index / 4) / width, channel: index % 4,
                expected: pixels[index], actual: actual.pixels[index]
            )
        }
    }
}

enum SnapshotReferenceStore {
    static func requireProfile(_ directory: URL, record: Bool) throws {
        var isDirectory: ObjCBool = false
        guard record || (FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory) && isDirectory.boolValue) else {
            throw SnapshotFailure.missingProfile(directory.path)
        }
    }

    static func check(_ actual: RGBAImage, reference: URL, record: Bool) throws {
        if record {
            try FileManager.default.createDirectory(at: reference.deletingLastPathComponent(), withIntermediateDirectories: true)
            try actual.pngData().write(to: reference, options: .atomic)
            return
        }
        guard FileManager.default.fileExists(atPath: reference.path) else {
            throw SnapshotFailure.missingReference(reference.path)
        }
        try RGBAImage(png: Data(contentsOf: reference)).compare(actual)
    }
}

/// A single fixed-size native host. Changing its appearance does not replace its root view or configuration.
struct SnapshotAccessibility {
    var increasedContrast = false
    var reducesMotion = false
    var reducesTransparency = false
}

private struct SnapshotAccessibilityModifier: ViewModifier {
    @Environment(\.designNativeEnvironment) private var environment
    let accessibility: SnapshotAccessibility?

    func body(content: Content) -> some View {
        if let accessibility {
            content.environment(\.designNativeEnvironment, DesignNativeEnvironment(
                appearance: environment.appearance,
                productProfile: environment.productProfile,
                density: environment.density,
                isIncreasedContrast: accessibility.increasedContrast,
                reducesMotion: accessibility.reducesMotion,
                reducesTransparency: accessibility.reducesTransparency
            ))
        } else {
            content
        }
    }
}

private struct SnapshotDesignSystemModifier: ViewModifier {
    let configuration: DesignSystemConfiguration?

    func body(content: Content) -> some View {
        if let configuration {
            content.designSystem(configuration)
        } else {
            content
        }
    }
}

@MainActor
final class NativeSnapshotHost<Content: View> {
    let view: NSHostingView<AnyView>
    private let window: NSWindow
    private let size: CGSize

    init(
        size: CGSize,
        configuration: DesignSystemConfiguration?,
        accessibility: SnapshotAccessibility? = .init(),
        @ViewBuilder content: () -> Content
    ) throws {
        guard size.width > 0, size.height > 0,
              size.width.rounded() == size.width, size.height.rounded() == size.height else {
            throw SnapshotFailure.rendering("Snapshot size must use positive integral pixels")
        }
        self.size = size
        _ = NSApplication.shared
        view = NSHostingView(rootView: AnyView(
            content()
                .frame(width: size.width, height: size.height, alignment: .topLeading)
                .background(Color(designToken: DesignTokens.Color.surfaceContent))
                .foregroundStyle(Color(designToken: DesignTokens.Color.textPrimary))
                .modifier(SnapshotAccessibilityModifier(accessibility: accessibility))
                .modifier(SnapshotDesignSystemModifier(configuration: configuration))
                .environment(\.locale, Locale(identifier: "en_US_POSIX"))
                .environment(\.calendar, Calendar(identifier: .gregorian))
                .environment(\.timeZone, TimeZone(secondsFromGMT: 0)!)
                .environment(\.layoutDirection, .leftToRight)
                .environment(\.dynamicTypeSize, .large)
                .environment(\.displayScale, 1)
                .environment(\.controlActiveState, .active)
                .accentColor(Color.blue)
                .transaction { transaction in
                    transaction.animation = nil
                    transaction.disablesAnimations = true
                }
        ))
        window = NSWindow(
            contentRect: NSRect(origin: CGPoint(x: -10000, y: -10000), size: size),
            styleMask: .borderless, backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = view
        view.frame = NSRect(origin: .zero, size: size)
        view.wantsLayer = true
        setAppearance(configuration?.appearance == .dark ? .darkAqua : .aqua)
    }

    func setAppearance(_ name: NSAppearance.Name) {
        view.appearance = NSAppearance(named: name)
        window.appearance = view.appearance
        view.needsLayout = true
        view.needsDisplay = true
        view.layoutSubtreeIfNeeded()
    }

    func render() throws -> RGBAImage {
        view.layoutSubtreeIfNeeded()
        // Keep real native progress indicators at one presentation instant. Nothing is hidden or substituted.
        freezeTiming(view)
        CATransaction.flush()
        guard view.bitmapImageRepForCachingDisplay(in: view.bounds) != nil,
              let bitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height),
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                colorSpaceName: .deviceRGB, bytesPerRow: Int(size.width) * 4, bitsPerPixel: 32
              ) else { throw SnapshotFailure.rendering("Native view cannot cache its display") }
        // An explicit 1× destination avoids depending on the attached screen's Retina scale; no image is resized.
        bitmap.size = size
        view.effectiveAppearance.performAsCurrentDrawingAppearance {
            view.cacheDisplay(in: view.bounds, to: bitmap)
        }
        guard let image = bitmap.cgImage else { throw SnapshotFailure.rendering("Native cache has no CGImage") }
        return try RGBAImage(cgImage: image)
    }

    private func freezeTiming(_ view: NSView) {
        if let layer = view.layer { freezeTiming(layer) }
        if let progress = view as? NSProgressIndicator {
            progress.usesThreadedAnimation = false
        }
        view.subviews.forEach(freezeTiming)
    }

    private func freezeTiming(_ layer: CALayer) {
        layer.speed = 0
        layer.beginTime = 0
        layer.timeOffset = 1
        for key in layer.animationKeys() ?? [] {
            if let animation = layer.animation(forKey: key) {
                animation.beginTime = 0
                layer.add(animation, forKey: key)
            }
        }
        layer.sublayers?.forEach(freezeTiming)
    }
}

@MainActor
func assertSnapshot<Content: View>(
    name: String,
    size: CGSize,
    configuration: DesignSystemConfiguration,
    @ViewBuilder content: () -> Content
) throws {
    let host = try NativeSnapshotHost(size: size, configuration: configuration, content: content)
    try assertSnapshotImage(host.render(), name: name)
}

func assertSnapshotImage(_ image: RGBAImage, name: String) throws {
    guard name.range(of: "^[a-z0-9-]+$", options: .regularExpression) != nil else {
        throw SnapshotFailure.rendering("Snapshot name must contain lowercase ASCII letters, numbers, or hyphens")
    }
    let record = ProcessInfo.processInfo.environment["QDS_RECORD_SNAPSHOTS"] == "1"
    #if arch(arm64)
    let architecture = "arm64"
    #elseif arch(x86_64)
    let architecture = "x86_64"
    #else
    throw SnapshotFailure.rendering("No snapshot profile for this architecture")
    #endif
    let profile = "macos-\(ProcessInfo.processInfo.operatingSystemVersion.majorVersion)-\(architecture)"
    let sourceDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("__Snapshots__")
    let rootDirectory = record ? sourceDirectory : Bundle.module.resourceURL!.appendingPathComponent("__Snapshots__")
    let directory = rootDirectory.appendingPathComponent(profile)
    let reference = directory.appendingPathComponent(name + ".png")
    do {
        try SnapshotReferenceStore.requireProfile(directory, record: record)
        try SnapshotReferenceStore.check(image, reference: reference, record: record)
    } catch {
        let artifacts = FileManager.default.temporaryDirectory.appendingPathComponent("qenterra-component-snapshot-failures")
        try FileManager.default.createDirectory(at: artifacts, withIntermediateDirectories: true)
        let actual = artifacts.appendingPathComponent(name + ".actual.png")
        try image.pngData().write(to: actual, options: .atomic)
        print("Snapshot actual: \(actual.path)")
        throw error
    }
}
#endif
