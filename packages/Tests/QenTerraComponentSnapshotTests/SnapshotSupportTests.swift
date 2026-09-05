#if os(macOS)
import Foundation
import Testing

@Suite("Snapshot comparison contracts")
struct SnapshotSupportTests {
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
        for channel in 0..<4 {
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
