# Changelog

All notable public package changes are recorded here. Versions follow Semantic Versioning from the canonical `1.0.0` baseline.

## [Unreleased]

No package changes have been classified after the new baseline yet.

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

[Unreleased]: https://github.com/QenTerra/design-system/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/QenTerra/design-system/releases/tag/v1.0.0
