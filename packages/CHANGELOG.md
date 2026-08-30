# Changelog

All notable public package changes are recorded here. The format follows Keep a Changelog and versions follow Semantic Versioning.

## [Unreleased]

### Changed

- Adopted QenTerra repository standard 1.3.0 with complete governance, one exact family Contact block, contribution, security, ownership, release, maintenance, and support documentation.
- Added a portable repository audit that rejects caches, AI or agent operating files, skills, MCP configuration, undeclared content, and incomplete generated-artifact provenance.
- Added versioned public token and icon inputs plus a portable deterministic generator for npm and Swift outputs.

### Security

- Made release verification regenerate every declared output outside the checkout before checking the editable manifest, preventing synchronized artifact-and-hash tampering from passing CI.

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
