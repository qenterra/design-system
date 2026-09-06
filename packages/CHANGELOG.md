# Changelog

All notable public package changes are recorded here. Versions follow Semantic Versioning from the canonical `1.0.0` baseline.

## [Unreleased]

### Added

- Planned the reusable macOS AppKit media-table APIs for `2.0.0`: generic row presentation, deterministic density and column geometry, stable native cell reuse, identity-scoped ready-artwork publication, keyboard callbacks, and a SwiftUI placeholder. The package performs no table coordination, asynchronous loading, sorting, queue construction, drag/context-menu policy, or persistence; its current version remains `1.0.1`.
- Planned the macOS playback and Now Playing APIs for `2.0.0`: player and transport snapshots, consumer-timed progress, weak native AirPlay routing, mutation-free queue views, explicit-identity lyrics with Reduced Motion behavior, and consumer-supplied metadata. The package does not own playback clocks, queue persistence, lyric loading or editing, or product-specific empty copy; its current version remains `1.0.1`.
- Planned the macOS media-collection presentation family for `2.0.0`: item models, tiles, rows, adaptive grids, shelves, favorite controls, and SwiftUI/AppKit playback indicators. The package owns ready-state rendering and synchronous interaction forwarding only; consumers retain domain, data, playback, persistence, and accessibility-copy ownership.
- Planned the macOS artwork presentation family for `2.0.0`, including ready-content states, placeholders, clamped crop geometry, zero-to-four-slot mosaics, and Reduced Transparency-aware ready-palette haze. The public package performs no loading, caching, gesture coordination, or mutation; its current version remains `1.0.1`.

### Changed

- Tightened the planned `2.0.0` AppKit media-table APIs with domain-neutral typography, independent keyboard intents, request-scoped artwork publication, per-control action availability, hover-only chrome reveal, and complete reuse/accessibility cleanup; the package version remains `1.0.1`.
- Made optional shuffle, repeat, and favorite action availability explicit, added consumer-owned player metadata/status/route composition slots, canonicalized the protected queue/progress geometry metrics, and made the 34-point queue control fully hit-testable for the planned `2.0.0` playback APIs.
- Raised the Swift package's minimum macOS version from 13 to 26 and moved macOS verification to macOS 26. iOS remains at 16. This is a breaking change planned for `2.0.0`; macOS consumers must raise their deployment target or remain on a compatible immutable release. Existing releases and tags are unchanged.
- Planned macOS `QenTerraComponents` feedback and configurable About APIs. This is not a release and does not change the package version.
- Added deterministic native core-component snapshot tests with reviewed per-platform references, strict dimension/color comparison, and explicit recording.
- Corrected primary/destructive button state foreground contrast and native loading indicator appearance. Explicit design environments now override native accessibility inputs; standalone components keep live native fallback and scoped profile/density resolution.

## [1.0.1] - 2026-09-02

### Added

- Added the OFL-licensed Tektur + Onest typography catalog with exact font files, provenance, hashes, and validation.

### Changed

- Relicensed QenTerra-authored package material from Apache-2.0 to MIT while retaining every third-party license and notice.
- Removed obsolete first-party Apache `NOTICE` files and publication-permission wording from the Explore SwiftUI catalog documentation.

## [1.0.0] - 2026-09-01

### Added

- Added public CSS, JSON, icon, and component-recipe exports through `@qenterra/design-tokens`.
- Added `QenTerraDesignTokens` and `QenTerraComponents` through Swift Package Manager.
- Added complete release-manifest coverage, deterministic regeneration, exported verification, clean-consumer checks, and npm archive inspection.
- Added attributed reference catalogs for Explore SwiftUI, Magic UI, shadcn/ui, UIable, and ReUI without treating upstream originals as maintained package APIs.
- Added non-target source catalogs containing 19,005 exact SVG originals from Tabler Icons, Phosphor Icons, Iconoir, and Bootstrap Icons with closed manifests and exact upstream MIT licenses.

### Changed

- Reset the maintained package SemVer line to `1.0.0`; future package releases advance from this baseline.
- Made `QenTerra/design-system` the canonical source, support, issue, and release repository.
- Licensed QenTerra-authored package material under Apache-2.0 and retained all required notices and third-party licenses.

### Historical continuity

- Previous internal package snapshot identifiers remain in Git history rather than the active release line.
- npmjs retains immutable historical version `5.0.0` from the retired Packages repository. It is not replaced, deleted, or presented as part of the new `1.x` line.
- No tag, GitHub Release, or npm publication is implied by this changelog entry. Publication remains a separately authorised operation.

[Unreleased]: https://github.com/QenTerra/design-system/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/QenTerra/design-system/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/QenTerra/design-system/releases/tag/v1.0.0
