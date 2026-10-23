#if os(macOS)
import AppKit
import QenTerraDesignTokens
import QenTerraMediaComponents
import SwiftUI
import Testing

@MainActor
struct MediaMetadataContrastTests {
    @Test(arguments: [false, true], Layout.allCases)
    func informativeMetadataUsesReadableSemanticColor(dark: Bool, layout: Layout) throws {
        let expected: [Int] = layout.selected
            ? (dark ? [185, 185, 192] : [86, 86, 94])
            : (dark ? [148, 148, 157] : [106, 106, 115])
        let token = layout.selected ? DesignTokens.Color.textSecondary : DesignTokens.Color.textTertiary
        let appearance = try #require(NSAppearance(named: dark ? .darkAqua : .aqua))
        var control: CGImage?
        var actual: CGImage?
        appearance.performAsCurrentDrawingAppearance {
            control = render(Text("MMMM MMMM").font(.caption)
                .foregroundStyle(Color(designToken: token)), dark: dark)
            actual = render(component(row: layout.row, selected: layout.selected), dark: dark)
        }
        let controlCount = try pixelCount(in: #require(control), matching: expected)
        #expect(controlCount >= 4, "The native semantic-color positive control must render first")
        let actualCount = try pixelCount(in: #require(actual), matching: expected)
        #expect(actualCount >= 4, "Informative metadata must use the readable semantic text role")
    }

    @Test(arguments: [false, true], [false, true])
    func creatorUsesReadableSemanticColor(dark: Bool, row: Bool) throws {
        let expected: [Int] = dark ? [185, 185, 192] : [86, 86, 94]
        let appearance = try #require(NSAppearance(named: dark ? .darkAqua : .aqua))
        var control: CGImage?
        var actual: CGImage?
        appearance.performAsCurrentDrawingAppearance {
            control = render(Text("Creator").font(.caption)
                .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary)), dark: dark)
            actual = render(component(row: row, showCreator: true), dark: dark)
        }
        #expect(try pixelCount(in: #require(control), matching: expected) >= 4)
        #expect(try pixelCount(in: #require(actual), matching: expected) >= 4)
    }

    @ViewBuilder
    private func component(row: Bool, selected: Bool = false, showCreator: Bool = false) -> some View {
        let item = MediaItemPresentation(
            id: "metadata", title: "Title", subtitle: showCreator ? "Creator" : "",
            metadata: showCreator ? nil : "MMMM MMMM",
            isSelected: selected, isCurrent: false, isPlaying: false, isAvailable: true
        )
        if row {
            MediaRow(item: item, accessibilityLabel: "Metadata") {
                Color.clear
            } trailingAccessory: { EmptyView() } action: {}
        } else {
            MediaTile(item: item, accessibilityLabel: "Metadata") {
                Color.clear.frame(width: 100, height: 100)
            } trailingAccessory: { EmptyView() } action: {}
        }
    }

    enum Layout: CaseIterable {
        case tile, row, selectedTile, selectedRow

        var row: Bool { self == .row || self == .selectedRow }
        var selected: Bool { self == .selectedTile || self == .selectedRow }
    }

    private func render(_ content: some View, dark: Bool) -> CGImage? {
        let view = content
            .environment(\.colorScheme, dark ? .dark : .light)
            .frame(width: 320, height: 240)
            .background(Color(designToken: DesignTokens.Color.surfaceContent, appearance: dark ? .dark : .light))
        let renderer = ImageRenderer(content: view)
        renderer.scale = 4
        return renderer.cgImage
    }

    private func pixelCount(in image: CGImage, matching channels: [Int]) throws -> Int {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        try bytes.withUnsafeMutableBytes { buffer in
            let context = try #require(CGContext(
                data: buffer.baseAddress, width: image.width, height: image.height,
                bitsPerComponent: 8, bytesPerRow: image.width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
            ))
            context.setBlendMode(.copy)
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        var matches = 0
        for offset in stride(from: 0, to: bytes.count, by: 4) {
            if Int(bytes[offset]) == channels[0], Int(bytes[offset + 1]) == channels[1],
               Int(bytes[offset + 2]) == channels[2], bytes[offset + 3] == 255 {
                matches += 1
            }
        }
        return matches
    }
}
#endif
