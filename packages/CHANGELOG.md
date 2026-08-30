# Changelog

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
