import CoreGraphics
import Foundation
import ImageIO
import QenTerraFoundation
import Testing

struct FoundationUtilityTests {
    @Test func hashingPreservesDigestAcrossChunkSizesAndEmptyData() async throws {
        let data = Data((0 ..< 20000).map { UInt8($0 % 251) })
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(try await ContentHasher(chunkSize: 4096).sha256(of: url) == ContentHasher().sha256(of: data))
        #expect(ContentHasher(chunkSize: 0).chunkSize == 4096)
        #expect(ContentHasher().sha256(of: Data()) == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    }

    @Test func hashingChecksCancellationBeforeOpeningAFile() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await ContentHasher().sha256(of: URL(filePath: "/nonexistent/qenterra-hash"))
        }
        await #expect(throws: CancellationError.self) { try await task.value }
    }

    @Test func hashingPropagatesFileAccessErrors() async {
        await #expect(throws: (any Error).self) {
            try await ContentHasher().sha256(of: URL(filePath: "/nonexistent/qenterra-hash"))
        }
    }

    @Test func searchNormalizationIsStableAcrossUnicodeForms() {
        #expect(SearchNormalizer.normalize("  CAFÉ\nＮｏｉｒ  ") == "cafe noir")
        #expect(SearchNormalizer.normalize("Cafe\u{301}") == SearchNormalizer.normalize("Café"))
        #expect(SearchNormalizer.normalize(" \t\n") == "")
    }

    @Test func deterministicGeneratorKeepsItsKnownSequence() {
        var random = SplitMix64(seed: 0)
        #expect(random.next() == 0xE220_A839_7B1D_CDAF)
        #expect(random.next() == 0x6E78_9E6A_A1B9_65F4)
    }

    @Test func cacheEvictsByRecencyAndCost() {
        var cache = CostLimitedCache<String, String>(countLimit: 3, totalCostLimit: 8)
        cache.insert("a", forKey: "a", cost: 4)
        cache.insert("b", forKey: "b", cost: 4)
        #expect(cache.value(forKey: "a") == "a")
        cache.insert("c", forKey: "c", cost: 4)
        #expect(cache.value(forKey: "b") == nil)
        #expect(cache.totalCost == 8)
        cache.removeAll { $0 == "a" }
        #expect(cache.totalCost == 4)
        cache.removeAll()
        #expect(cache.isEmpty && cache.totalCost == 0)
    }

    @Test func cacheReplacementAndExtremeBudgetsStayBounded() {
        var cache = CostLimitedCache<Int, Int>(countLimit: 1, totalCostLimit: Int.max)
        cache.insert(1, forKey: 1, cost: Int.max)
        cache.insert(2, forKey: 2, cost: Int.max)
        #expect(cache.count == 1 && cache.totalCost == Int.max)
        #expect(cache.value(forKey: 1) == nil)
        var small = CostLimitedCache<Int, Int>(countLimit: 2, totalCostLimit: 3)
        small.insert(1, forKey: 1, cost: 1)
        small.insert(2, forKey: 1, cost: 4)
        #expect(small.isEmpty)
    }

    @Test func pagesRespectRecencyAndIdentityUpdates() {
        var pages = PageWindow<String>(pageCapacity: 2)
        pages.insert(["a", "b"], page: 0)
        pages.insert(["c"], page: 1)
        #expect(pages.item(at: 0, pageSize: 2) == "a")
        #expect(pages.insert(["e"], page: 2) == 1)
        #expect(pages.item(at: 2, pageSize: 2) == nil)
        let replaced = pages.replace(where: { $0 == "b" }, with: "updated")
        #expect(replaced)
        #expect(pages.index(where: { $0 == "updated" }, pageSize: 2) == 1)
        #expect(pages.item(at: -1, pageSize: 2) == nil)
        pages.removeAll()
        #expect(pages.cachedPageCount == 0)
    }

    @Test func pageRequestsAllowRetryAfterFailureAndEviction() {
        var requests = PageRequestTracker(pageSize: 2)
        #expect(requests.beginRequest(containing: -1) == nil)
        #expect(requests.beginRequest(containing: 3) == 1)
        #expect(requests.beginRequest(containing: 2) == nil)
        requests.failRequest(page: 1)
        #expect(requests.beginRequest(containing: 2) == 1)
        requests.finishRequest(page: 1)
        #expect(!requests.needsRequest(containing: 3))
        requests.forgetRequest(page: 1)
        #expect(requests.needsRequest(containing: 3))
        requests.invalidate()
    }

    @Test func prefetchStopsAtCatalogBoundaries() {
        #expect(PagePrefetchPolicy.pages(around: 1, pageCount: 3, prefetchPages: 5, direction: .before) == [0])
        #expect(PagePrefetchPolicy.pages(around: 1, pageCount: 3, prefetchPages: 5, direction: .after) == [2])
        #expect(PagePrefetchPolicy.range(visibleRows: 4 ... 9, totalCount: 11, pageSize: 5, prefetchPages: 2) == 0 ... 10)
        #expect(PagePrefetchPolicy.range(visibleRows: 0 ... 0, totalCount: 0, pageSize: 5, prefetchPages: 2) == nil)
    }

    @Test func pagingClipsExtremeInputsBeforeArithmetic() {
        #expect(PagePrefetchPolicy.pages(around: 1, pageCount: 3, prefetchPages: Int.max, direction: .after) == [2])
        #expect(PagePrefetchPolicy.pages(around: 1, pageCount: 3, prefetchPages: Int.max, direction: .before) == [0])
        #expect(PagePrefetchPolicy.range(visibleRows: 0 ... 0, totalCount: 3, pageSize: 2, prefetchPages: Int.max) == 0 ... 2)
        #expect(PagePrefetchPolicy.range(visibleRows: 0 ... Int.max, totalCount: Int.max, pageSize: Int.max, prefetchPages: Int.max) == 0 ... (Int.max - 1))
        #expect(PagePrefetchPolicy.range(visibleRows: Int.max ... Int.max, totalCount: 3, pageSize: 2, prefetchPages: 0) == 2 ... 2)
        var pages = PageWindow<String>(pageCapacity: 2)
        pages.insert(["x"], page: Int.max)
        #expect(pages.index(where: { $0 == "x" }, pageSize: 2) == nil)
        pages.insert(["a", "b", "c"], page: Int.max / 2)
        #expect(pages.index(where: { $0 == "c" }, pageSize: 2) == nil)
        #expect(pages.index(where: { $0 == "b" }, pageSize: 2) == Int.max)
    }

    @Test func imageDecodingAndThumbnailGenerationRespectBounds() throws {
        let context = try #require(CGContext(data: nil, width: 32, height: 16, bitsPerComponent: 8, bytesPerRow: 128, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        context.setFillColor(CGColor(gray: 0.5, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 32, height: 16))
        let image = try #require(context.makeImage())
        let data = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        let original = try #require(ImageDataDecoder.image(from: data as Data))
        #expect(original.width == 32 && original.height == 16)
        #expect(ImageDataDecoder.decodedByteCost(of: original) == 2048)
        let bounded = try #require(ImageDataDecoder.image(from: data as Data, maximumPixelDimension: 8))
        #expect(bounded.width == 8 && bounded.height == 4)
        let jpeg = try #require(ImageThumbnailGenerator.data(from: data as Data, maximumPixelDimension: 12))
        #expect(try #require(ImageDataDecoder.image(from: jpeg)).width == 12)
        #expect(ImageDataDecoder.image(from: Data([0, 1])) == nil)
        #expect(ImageDataDecoder.image(from: data as Data, maximumPixelDimension: 0) == nil)
        #expect(ImageThumbnailGenerator.data(from: data as Data, maximumPixelDimension: 0) == nil)
    }
}
