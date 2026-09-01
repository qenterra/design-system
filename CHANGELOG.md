# Changelog

All notable maintained Design System changes are recorded here. Versions follow Semantic Versioning from the canonical `1.0.0` baseline.

## [Unreleased]

No changes have been classified after the new baseline yet.

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

[Unreleased]: https://github.com/QenTerra/design-system/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/QenTerra/design-system/releases/tag/v1.0.0
