import Foundation
import QenTerraFoundation
import QenTerraAudioAnalysis

precondition(SearchNormalizer.normalize(" CAFÉ ") == "cafe")
precondition(ContentHasher().sha256(of: Data("abc".utf8)) == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
var cache = CostLimitedCache<Int, String>(countLimit: 1, totalCostLimit: 8)
cache.insert("first", forKey: 1, cost: 4)
cache.insert("second", forKey: 2, cost: 4)
precondition(cache.value(forKey: 1) == nil)
var pages = PageWindow<String>(pageCapacity: 1)
pages.insert(["row"], page: 0)
precondition(pages.item(at: 0, pageSize: 1) == "row")
var requests = PageRequestTracker(pageSize: 20)
precondition(requests.beginRequest(containing: 21) == 1)
precondition(PagePrefetchPolicy.pages(around: 0, pageCount: 2, prefetchPages: 1, direction: .after) == [1])
var random = SplitMix64(seed: 0)
precondition(random.next() == 0xe220a8397b1dcdaf)
precondition(ImageDataDecoder.image(from: Data()) == nil)
precondition(ImageThumbnailGenerator.data(from: Data(), maximumPixelDimension: 10) == nil)
var clock = PlaybackPresentationClock()
clock.update(PlaybackTimelineSample(mediaTime: 2, hostUptime: 10, rate: 1))
precondition(clock.time(atHostUptime: 11, duration: 20) == 3)
#if os(macOS)
let meter = PCMBassLevelMeter()
let analyzer = PCMBassAnalyzer(meter: meter)
let tap = makePCMBassTap(analyzer: analyzer)
_ = tap
analyzer.reset()
precondition(meter.currentBassLevel() == 0)
let envelope = PlaybackBassEnvelope(samplesPerSecond: 10, levels: [0, 0.5])
precondition(envelope.level(at: 0.1) == 0.5)
#endif
print("PUBLIC_UTILITIES_OK")
