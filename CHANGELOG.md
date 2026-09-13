# Changelog

All notable maintained Design System changes are recorded here. Versions follow Semantic Versioning from the canonical `1.0.0` baseline.

## [Unreleased]

## [1.0.2] - 2026-09-13

### Reusable application code

- Added independent `QenTerraFoundation` and `QenTerraAudioAnalysis` Swift products. Cadence now consumes shared hashing, text normalization, deterministic random values, cache storage, page policies, ImageIO processing, PCM analysis and presentation-clock algorithms.
- Added a native `MediaMetadataLink` with consumer-owned actions and accessibility copy, plus a standalone consumer that builds and runs without UI product dependencies.
- Aligned the Swift source and package metadata to 1.0.2. npm publication is managed separately.


### Fixed

- Keep About resource links transparent at rest, with hover feedback inside grouped content.
- Use selection fill without an outline for Cadence media rows and align numeric table columns centrally.
- Remove the decorative current-track queue symbol while retaining spoken playback state and Up Next drag handles.

### Added

- Added an opt-in, normalized whole-viewport alpha mask to `LyricsEdgeFade`, with clamped and ordered consumer-supplied opaque stops. The zero-argument initializer retains its original destination-out edge overlay.
- Added the complete deterministic macOS native snapshot catalog for artwork, collections, playback, queue, lyrics, metadata, native tables, and fixed-time Metal gradients; clean copied-public consumers exercise every media family, and a fail-closed plain-SemVer command aligns canonical and generated version surfaces without performing Git or publication actions.
- Added the reusable macOS artwork-accent Metal gradient for `1.0.2`: the protected indexed terrain, camera and simplex-noise shader, five-colour linear palette expansion, interruptible 0.8-second palette transitions, symmetric effect tint, Reduced Motion static rendering, SwiftUI and AppKit surfaces, deterministic fixed-time rendering, and opaque resource/device fallback. Consumers retain artwork extraction and domain behavior.
- Added the reusable macOS AppKit media-table presentation for `1.0.2`: generic row snapshots, stable cell hierarchy and geometry, identity-scoped ready-artwork publication, explicit hover/focus/selection/current/unavailable states, first-responder keyboard dispatch, and a density-aware SwiftUI placeholder. Consumers retain table data/delegate coordination, async loading, sorting, selection resolution, queue, drag, context-menu, and persistence policy.
- Added the macOS playback and Now Playing component family for `1.0.2`: player and transport presentation, consumer-timed progress, weak native AirPlay routing, mutation-free queue visuals, explicit-identity lyrics with Reduced Motion behavior, and consumer-supplied audio metadata. Playback clocks, queue persistence, lyric loading and editing, and product-specific empty copy remain outside the Design System.
- Added the macOS reusable media-collection family for `1.0.2`: domain-neutral item presentation, tile/row/grid/shelf composition, favorite controls, and shared SwiftUI/AppKit playback indicators. Selection and current playback remain independent, embedded controls do not activate their row, Reduced Motion uses fixed bars, and consumers retain identity, data, playback, persistence, and accessibility-copy ownership.
- Added the macOS `QenTerraMediaComponents` artwork family for `1.0.2`: ready-content states, semantic placeholders and borders, clamped crop presentation, zero-to-four-slot mosaics, and Reduced Transparency-aware ready-palette haze. Consumers retain decoding, cache, request, gesture, and mutation ownership.

### Changed

- Standardised commit messages, pull request reviews, changelogs, and release notes with shared contributor templates.

- Restored secondary recovery actions and inherited standard About-resource typography, keeping consumer styles opt-in. Artwork gradients now retain one native surface and resolve terrain availability before their first SwiftUI frame, so initial idle/tint overlays are never deferred.
- Extended the `1.0.2` playback family with consumer-composed favorite/import controls, custom queue metadata and selection without double dispatch, reset-aware lyrics with blank stanzas and reusable labels, and an explicit public AirPlay routing policy seam. Playback clocks, async mutations, queue ownership, and lyric document lifecycle remain consumer-owned.
- Preserved native SwiftUI multiply blending for artwork-gradient idle/tint overlays over raw Metal terrain, while direct AppKit consumers retain layer composition and both surfaces retain opaque fallback. Table favorite-control width and primary action tint are explicit opt-ins with unchanged defaults.
- Added native table placeholder configuration, normalized ready-artwork crop publication, original-event context menus and native action-button anchors, consumer accessibility copy, a compact explicit-media badge typography role, plus configure-work observations and reusable off-main shader prewarming for the `1.0.2` consumer boundary.
- Tightened the `1.0.2` AppKit media-table contract with domain-neutral table typography, independent keyboard intents, request-scoped artwork publication, per-control action availability, hover-only chrome reveal, and complete reuse/accessibility cleanup.
- Made optional shuffle, repeat, and favorite action availability explicit, added consumer-owned player metadata/status/route composition slots, canonicalized the protected queue/progress geometry metrics, and made the 34-point queue control fully hit-testable for the `1.0.2` playback family.
- Raised the maintained Swift packages' minimum macOS version from 13 to 26 and moved macOS verification and package-release jobs to macOS 26. iOS remains at 16. Despite the patch version number, this is a breaking compatibility change from `1.0.1`; macOS consumers must raise their deployment target or remain on a compatible immutable release. Existing releases and tags are unchanged.
- Added macOS feedback and configurable About components, including validated measured progress, consumer-owned recovery and URL handling, and explicit unavailable presentation.
- Added deterministic native core-component snapshot tests to the root and public Swift packages, with reviewed per-platform references and strict dimension/color comparison. The host materializes native display before freezing layer clocks so first-frame SF Symbols remain visible.
- Corrected primary/destructive button state foreground contrast and native loading indicator appearance. Explicit design environments now take precedence over native accessibility inputs; standalone components retain live native fallback and scoped profile/density resolution.

## [1.0.1] - 2026-09-02

### Added

- Added the OFL-licensed Tektur + Onest brand and portfolio typography catalog with design-tool TTFs, web WOFF2s, pinned provenance, byte hashes, role guidance, and repository validation.

### Changed

- Relicensed QenTerra-authored repository and package material from Apache-2.0 to MIT while preserving third-party licenses, provenance, and historical release records.
- Updated the verification environment from Pillow `12.2.0` to `12.3.0`.
- Removed obsolete first-party Apache `NOTICE` files and publication-permission wording from the Explore SwiftUI catalog documentation.
- Required manual package publication to resolve an existing immutable tag instead of accepting a same-named branch or other Git reference.

## [1.0.0] - 2026-09-01

### Added

- Established the public canonical Design System for QenTerra foundations, semantic tokens, components, platform adapters, product profiles, accessibility contracts, and human documentation.
- Added deterministic CSS, JSON, Swift, and Figma-oriented generated outputs from canonical token and registry sources.
- Added the public `@qenterra/design-tokens`, `QenTerraDesignTokens`, and `QenTerraComponents` package surfaces with a manifest-closed delivery boundary.
- Added complete attributed reference catalogs for Explore SwiftUI, Magic UI, shadcn/ui, UIable, and ReUI while keeping upstream originals immutable and outside maintained package targets where required.
- Added 19,005 exact SVG originals from Tabler Icons, Phosphor Icons, Iconoir, and Bootstrap Icons with pinned commits, byte hashes, complete manifests, and exact upstream MIT licenses.
- Added the Nyx brand asset family with manifest, Git LFS, license, provenance, and validation coverage.
- Added repository governance, contribution, security, maintenance, deprecation, release, consumer-adoption, and clean-consumer verification contracts.

### Changed

- Reset the maintained canonical SemVer line to `1.0.0`; future source and release changes advance from this baseline.
- Opened the canonical repository under Apache-2.0 while preserving every third-party license, copyright notice, provenance record, and permission boundary.
- Consolidated package source, SwiftPM delivery, npm metadata, issues, security reporting, and release automation under `QenTerra/design-system`.
- Retired the separate Packages repository after verified replacement and recoverable backup.

### Historical continuity

- Earlier internal snapshot identifiers through `5.5.1` remain preserved in Git history. They are development history, not the active public release line.
- npmjs still retains the immutable historical `@qenterra/design-tokens@5.0.0` artifact whose metadata points to the retired Packages repository. Resetting source versioning does not erase or rewrite that registry fact.
- No tag, GitHub Release, or npm publication is implied by this changelog entry. Publication remains a separately authorised operation.

[Unreleased]: https://github.com/QenTerra/design-system/compare/v1.0.2...HEAD
[1.0.2]: https://github.com/QenTerra/design-system/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/QenTerra/design-system/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/QenTerra/design-system/releases/tag/v1.0.0
