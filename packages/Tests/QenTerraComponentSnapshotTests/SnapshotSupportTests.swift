#if os(macOS)
import AppKit
import Foundation
import QenTerraComponents
import QenTerraDesignTokens
import QenTerraMediaComponents
import SwiftUI
import Testing

@Suite("Snapshot comparison contracts")
struct SnapshotSupportTests {
    @Test @MainActor func firstNativeGradientFrameIncludesItsEffectTint() throws {
        func render(_ active: Bool) throws -> RGBAImage {
            let host = try NativeSnapshotHost(size: CGSize(width: 320, height: 240), configuration: .init(appearance: .dark)) {
                ArtworkAccentGradient(palette: .fallback, appearance: .init(
                    isAnimated: false, maximumFramesPerSecond: 60,
                    tint: .resolve(palette: .fallback, isEffectActive: active, reducesMotion: true)
                ))
            }
            return try host.render()
        }
        let idle = try render(false)
        let active = try render(true)
        let tintChangesPixels = active.pixels != idle.pixels
        #expect(tintChangesPixels)
        #expect(active.pixels[0] < idle.pixels[0])
    }

    @Test @MainActor func recoveryRetainsSecondaryPresentationAndResourceRowsInheritTypography() throws {
        func render<V: View>(@ViewBuilder _ content: () -> V) throws -> RGBAImage {
            try NativeSnapshotHost(size: CGSize(width: 360, height: 240), configuration: .init(appearance: .light), content: content).render()
        }
        let recovery = try render {
            ContentStateView(state: .error(title: "Error", message: "Try again"), recovery: .init(title: "Retry", handler: {}))!
        }
        let original = try render {
            VStack(spacing: DesignTokens.Space.value3) {
                Image(systemName: "xmark.octagon").font(.title2)
                Text("Error").font(.system(size: DesignTokens.Typography.sectionTitle.size, weight: DesignTokens.Typography.sectionTitle.swiftUIWeight))
                    .foregroundStyle(Color(designToken: DesignTokens.Color.textPrimary)).multilineTextAlignment(.center)
                Text("Try again").font(.system(size: DesignTokens.Typography.supporting.size, weight: DesignTokens.Typography.supporting.swiftUIWeight))
                    .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary)).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                Button("Retry") {}.buttonStyle(DesignButtonStyle(role: .secondary))
            }.padding(DesignTokens.Space.value6).frame(maxWidth: .infinity)
        }
        #expect(throws: Never.self) { try original.compare(recovery) }

        let resource = try AboutResource(id: "source", title: "Source", subtitle: "Project source", symbol: "doc.text", destination: #require(URL(string: "https://example.com")), accessibilityHint: "Open source")
        let row = try render { AboutResourceRow(resource: resource).font(.system(size: 19)) }
        let reference = try render {
            Button {} label: {
                HStack(spacing: DesignTokens.Space.value3) {
                    Image(systemName: "doc.text").foregroundStyle(Color(designToken: DesignTokens.Color.textLink))
                    VStack(alignment: .leading, spacing: DesignTokens.Space.value1) {
                        Text("Source").foregroundStyle(Color(designToken: DesignTokens.Color.textLink))
                        Text("Project source").font(.system(size: DesignTokens.Typography.supporting.size, weight: DesignTokens.Typography.supporting.swiftUIWeight))
                            .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right").foregroundStyle(Color(designToken: DesignTokens.Color.textLink))
                }.padding(DesignTokens.Space.value4).frame(maxWidth: .infinity, alignment: .leading)
            }.buttonStyle(DesignButtonStyle(role: .link)).font(.system(size: 19))
        }
        #expect(throws: Never.self) { try reference.compare(row) }
    }

    @Test func missingPlatformProfileFailsWithoutCreatingOrSubstitutingIt() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("macos-unavailable-arm64")
        #expect(throws: SnapshotFailure.missingProfile(directory.path)) {
            try SnapshotReferenceStore.requireProfile(directory, record: false)
        }
        #expect(!FileManager.default.fileExists(atPath: directory.path))
        try SnapshotReferenceStore.requireProfile(directory, record: true)
        #expect(!FileManager.default.fileExists(atPath: directory.path))
    }

    @Test func missingReferenceFailsWithoutRecording() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let reference = directory.appendingPathComponent("missing.png")
        let image = try RGBAImage(width: 1, height: 1, pixels: [100, 110, 120, 255])
        #expect(throws: SnapshotFailure.missingReference(reference.path)) {
            try SnapshotReferenceStore.check(image, reference: reference, record: false)
        }
        #expect(!FileManager.default.fileExists(atPath: directory.path))
    }

    @Test func dimensionMismatchFailsEvenWithEqualByteCounts() throws {
        let expected = try RGBAImage(width: 2, height: 1, pixels: [UInt8](repeating: 255, count: 8))
        let actual = try RGBAImage(width: 1, height: 2, pixels: expected.pixels)
        #expect(throws: SnapshotFailure.dimensions(expectedWidth: 2, expectedHeight: 1, actualWidth: 1, actualHeight: 2)) {
            try expected.compare(actual)
        }
    }

    @Test func toleranceIncludesThreeButRejectsFourInEveryChannel() throws {
        let expected = try RGBAImage(width: 1, height: 1, pixels: [100, 110, 120, 200])
        for channel in 0 ..< 4 {
            for direction in [-1, 1] {
                var boundary = expected.pixels
                boundary[channel] = UInt8(Int(boundary[channel]) + direction * 3)
                try expected.compare(RGBAImage(width: 1, height: 1, pixels: boundary))
                boundary[channel] = UInt8(Int(expected.pixels[channel]) + direction * 4)
                #expect(throws: SnapshotFailure.pixels(x: 0, y: 0, channel: channel, expected: expected.pixels[channel], actual: boundary[channel])) {
                    try expected.compare(RGBAImage(width: 1, height: 1, pixels: boundary))
                }
            }
        }
    }

    @Test func explicitRecordingRoundTripsRGBAAndLockedCheckDoesNotRewrite() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let reference = directory.appendingPathComponent("record.png")
        let expected = try RGBAImage(width: 2, height: 1, pixels: [24, 80, 180, 255, 64, 32, 16, 128])
        try SnapshotReferenceStore.check(expected, reference: reference, record: true)
        let before = try Data(contentsOf: reference)
        let date = try reference.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
        try SnapshotReferenceStore.check(expected, reference: reference, record: false)
        #expect(try Data(contentsOf: reference) == before)
        #expect(try reference.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate == date)
        #expect(try RGBAImage(png: before) == expected)
    }
}
#endif
