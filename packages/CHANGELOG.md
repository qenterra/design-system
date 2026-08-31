# Changelog

## 5.5.1 - 2026-08-31

### Changed

- Licensed QenTerra-authored package material under Apache-2.0 and retained the required NOTICE files.
- Adopted QenTerra repository standard 2.0.0 and its product-repository artifact boundary.
- Moved the canonical Git and SwiftPM endpoint to `QenTerra/design-system`; npm continues as `@qenterra/design-tokens`.

## 5.5.0 - 2026-08-30

### Added

- Published the complete free dual-base ReUI catalog: 2,202 `c-*` examples, 150 public primitives, eight hooks, 2,360 exact install payloads, and 2,377 immutable source files.
- Published pinned repository and live-deployment provenance, both live registry-index hashes, per-item origins, dependencies, paths, URLs, byte counts, SHA-256 hashes, and the exact MIT license with Keenthemes authorship.
- Added independent exported verification and consumer documentation for selecting and copying ReUI items.

### Changed

- Advanced the unified public package version to 5.5.0 and expanded the release allowlist while keeping ReUI outside npm and SwiftPM targets.

### Security

- Excluded all 520 ReUI Pro blocks, paid icons, templates, site code, docs application, media, and build tooling. Modified implementations remain separate QenTerra-owned components.

## 5.4.0 - 2026-08-30

### Added

- Published all 745 official UIable `registry:ui` sources: 684 showcase components and 61 required UI primitives.
- Published the matching 745 exact public install-registry payloads, a pinned upstream commit, source and registry paths and URLs, byte counts, SHA-256 hashes, 69 category counts, and the exact upstream MIT license with CodedThemes authorship.
- Added independent exported catalog verification and public documentation for selection and installation.

### Changed

- Advanced the unified public package version to 5.4.0 and expanded the release allowlist for the UIable catalog.

### Fixed

- Reject missing, extra, resized, hash-modified, unpinned, category-drifted, license-drifted, source/registry-mismatched, or block-leaked UIable files.

### Security

- UIable remains a non-target reference catalog. Its originals are not tokenized, rewritten, or relicensed as QenTerra work.

All notable public package changes are recorded here. The format follows Keep a Changelog and versions follow Semantic Versioning.

## [Unreleased]

### Changed

- Adopted QenTerra repository standard 1.3.0 with complete governance, one exact family Contact block, contribution, security, ownership, release, maintenance, and support documentation.
- Added a portable repository audit that rejects caches, AI or agent operating files, skills, MCP configuration, undeclared content, and incomplete generated-artifact provenance.
- Added versioned public token and icon inputs plus a portable deterministic generator for npm and Swift outputs.

### Security

- Made release verification regenerate every declared output outside the checkout before checking the editable manifest, preventing synchronized artifact-and-hash tampering from passing CI.

## 5.3.0 - 2026-08-30

### Added

- Published all 76 components on the official Magic UI Components page as exact non-target TypeScript source.
- Preserved all 76 exact official install-registry payloads, including component dependencies, CSS variables, and keyframes that do not live in every `.tsx` file.
- Added a pinned public upstream commit, eight categories, original paths and URLs, byte counts, SHA-256 hashes, the exact MIT license, `Copyright (c) Magic UI`, and closed public manifest coverage.

### Changed

- Kept Magic UI originals outside npm and SwiftPM targets; modified implementations remain separate QenTerra-owned components.

### Security

- Reject missing, undeclared, resized, hash-modified, unpinned, category-drifted, license-drifted, or source/registry-mismatched Magic UI catalog files in the exported release gate.

## 5.2.0 - 2026-08-30

### Added

- Published all 182 official shadcn/ui `registry:ui` source files across the React Aria, Base UI, and Radix UI bases as an exact non-target reference catalog.
- Added a pinned public upstream commit, original paths and URLs, byte counts, SHA-256 hashes, and closed public manifest coverage for every source.
- Bundled the exact upstream MIT license and preserved `Copyright (c) 2023 shadcn` in the catalog and third-party notices.

### Changed

- Kept shadcn/ui originals outside npm and SwiftPM targets; modified implementations remain separate QenTerra-owned components.

### Security

- Reject missing, undeclared, resized, hash-modified, or license-drifted shadcn/ui catalog files in the exported release gate.

## 5.1.0 - 2026-08-30

### Added

- Published 221 exact Explore SwiftUI source examples across 34 categories as an attributed, non-target reference catalog with page, Apple documentation, date, tag, platform, byte-count, and SHA-256 metadata.
- Added closed public manifests for the Explore SwiftUI originals and maintained QenTerra components.
- Added a self-contained source-catalog verifier to the public release gate.

### Changed

- Grouped installable Swift sources under `Sources/QenTerra/Components` and `Sources/QenTerra/DesignTokens` without changing the `QenTerraComponents` or `QenTerraDesignTokens` products.
- Split every maintained QenTerra component into its own Swift file.

### Security

- Reject direct edits, missing files, undeclared files, size drift, hash drift, and invalid QenTerra derivation provenance in the native source catalogs.

## 5.0.0 - 2026-08-28

### Added

- Published `@qenterra/design-tokens` with CSS, JSON, icon, and component-recipe exports.
- Published `QenTerraDesignTokens` and `QenTerraComponents` through Swift Package Manager.
- Added a complete SHA-256 release manifest and self-contained verifier.

### Changed

- Established `packages/` as the sole public export from the canonical Design System repository.

### Removed

- Excluded private assets, canonical design documentation, consumer manifests, internal history, and repository-local agent material from public delivery.
