import AppKit
import Foundation

struct IconRegistry: Decodable {
    let icons: [Icon]
}

struct Icon: Decodable {
    let id: String
    let sfSymbol: String
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

guard CommandLine.arguments.count == 3 else {
    fail("Usage: swift scripts/render_sf_symbols.swift registry/icons.json OUTPUT_DIRECTORY")
}

let registryURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
let decoder = JSONDecoder()
let registry: IconRegistry

do {
    registry = try decoder.decode(IconRegistry.self, from: Data(contentsOf: registryURL))
    try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
} catch {
    fail("SF Symbols input error: \(error)")
}

let canvasPixels = 64
let symbolExtent = CGFloat(48)
let configuration = NSImage.SymbolConfiguration(pointSize: symbolExtent, weight: .regular)
for icon in registry.icons {
    guard let source = NSImage(systemSymbolName: icon.sfSymbol, accessibilityDescription: nil) else {
        fail("Unknown SF Symbol '\(icon.sfSymbol)' for semantic icon '\(icon.id)'")
    }
    let image = source.withSymbolConfiguration(configuration) ?? source
    guard image.size.width > 0, image.size.height > 0 else {
        fail("SF Symbol '\(icon.sfSymbol)' has no drawable size")
    }
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: canvasPixels,
        pixelsHigh: canvasPixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: [],
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        fail("Could not render SF Symbol '\(icon.sfSymbol)'")
    }
    let canvas = NSRect(x: 0, y: 0, width: canvasPixels, height: canvasPixels)
    let drawRect = NSRect(
        x: (canvas.width - symbolExtent) / 2,
        y: (canvas.height - symbolExtent) / 2,
        width: symbolExtent,
        height: symbolExtent
    )
    bitmap.size = canvas.size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.shouldAntialias = true
    context.imageInterpolation = .high
    NSColor.clear.setFill()
    canvas.fill()
    image.draw(
        in: drawRect,
        from: NSRect(origin: .zero, size: image.size),
        operation: .sourceOver,
        fraction: 1,
        respectFlipped: true,
        hints: [.interpolation: NSImageInterpolation.high]
    )
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        fail("Could not encode SF Symbol '\(icon.sfSymbol)'")
    }
    do {
        try png.write(to: outputURL.appendingPathComponent("\(icon.id).png"), options: .atomic)
    } catch {
        fail("Could not write SF Symbol '\(icon.id)': \(error)")
    }
}

print("Rendered \(registry.icons.count) SF Symbols from macOS system assets.")
