# Reusable Swift utilities

Version 2.0.0 adds two independent products. Select only the products your application needs; neither depends on SwiftUI, Design System tokens, Cadence, its database, or its playback coordinator.

| Product | Import | Contents |
| --- | --- | --- |
| General utilities | `QenTerraFoundation` | Streaming SHA-256, normalized search text, deterministic random values, bounded LRU cache, page windows and request tracking, ImageIO decoding and JPEG thumbnails |
| Audio analysis | `QenTerraAudioAnalysis` | A media-time presentation clock; on macOS, PCM bass analysis, immutable envelopes and an atomic level meter |

## Add a dependency

Pin the source release in your `Package.swift`:

```swift
// Package dependencies
.package(url: "https://github.com/QenTerra/design-system", exact: "2.0.0")

// Dependencies of your application target
.product(name: "QenTerraFoundation", package: "design-system"),
.product(name: "QenTerraAudioAnalysis", package: "design-system")
```

In Xcode, use **Add Package Dependencies**, enter the repository URL, choose exact version **2.0.0**, and add the required products to your target. Version 1.0.1 does not contain these APIs.

The package supports macOS 26 and iOS 16 with a compatible current Swift toolchain. PCM bass APIs are macOS-only; the presentation clock remains available on both platforms.

## Hashing and search

```swift
import QenTerraFoundation

let digest = try await ContentHasher().sha256(of: fileURL)
let normalizedQuery = SearchNormalizer.normalize("  Café  ") // "cafe"
```

File hashing reads bounded chunks and checks task cancellation before opening and between reads. It returns lowercase hexadecimal SHA-256. File access errors propagate. Normalization uses a stable POSIX locale, canonical composition, case/diacritic/width folding and collapsed whitespace; persist a compatible normalization policy when using it in an index.

## Bounded caches and lists

```swift
var cache = CostLimitedCache<String, Data>(countLimit: 128, totalCostLimit: 64 * 1024 * 1024)
cache.insert(bytes, forKey: identity, cost: bytes.count)
let cached = cache.value(forKey: identity)

var pages = PageWindow<String>(pageCapacity: 4)
pages.insert(["first", "second"], page: 0)
let first = pages.item(at: 0, pageSize: 50)
```

Reads refresh recency. Cache replacement first removes the old value; a value larger than the budget is not retained. Identity, revision invalidation, synchronization and loading belong to the caller. `PageRequestTracker` coalesces requests, allows retries after failure and forgets evicted pages; `PagePrefetchPolicy` computes bounded neighboring pages. Keep page size stable while a window contains data, and invalidate it when the query changes. `SplitMix64(seed:)` gives repeatable sequences for simulations and fixtures; it is not cryptographic randomness.

## Images

```swift
let image = ImageDataDecoder.image(from: encodedBytes, maximumPixelDimension: 512)
let jpeg = ImageThumbnailGenerator.data(from: encodedBytes, maximumPixelDimension: 128)
```

A nil decoding limit selects the original image; positive limits select orientation-corrected thumbnails. Invalid data or nonpositive dimensions return nil. JPEG generation retains the extracted 0.86 compression policy. `decodedByteCost(of:)` estimates four bytes per pixel for cache admission and returns `Int.max` on overflow. These synchronous helpers perform no loading, caching or scheduling; call them off the UI thread when processing large images.

## Audio ownership

```swift
import QenTerraAudioAnalysis

var clock = PlaybackPresentationClock()
clock.update(PlaybackTimelineSample(mediaTime: 30, hostUptime: 100, rate: 1))
let visibleTime = clock.time(atHostUptime: 100.25, duration: 180)

#if os(macOS)
let meter = PCMBassLevelMeter()
let analyzer = PCMBassAnalyzer(meter: meter)
let tap = makePCMBassTap(analyzer: analyzer)
// Install the tap on a caller-owned AVAudioEngine node.
let level = meter.currentBassLevel()
#endif
```

The clock extrapolates a caller-supplied backend sample; it does not start playback or own a timer. Exactly one audio render callback owns `PCMBassAnalyzer.process`; control-thread resets cross through atomics. The caller owns engine/tap installation, removal, schedule generations and successor boundaries. `PlaybackBassEnvelopeAnalyzer.analyze(url:)` provides bounded offline analysis with cancellation. Unit and synthetic-buffer tests do not establish audible playback or hardware-route acceptance.

## Interface components

`QenTerraMediaComponents.MediaMetadataLink` accepts a visible title, required accessibility label, caller action and optional frozen highlights. `ArtworkHaze` consumes a prepared palette. Neither resolves library metadata, decodes files or navigates an application.
