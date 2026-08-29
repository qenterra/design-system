# Changelog

All notable public package changes are recorded here. The format follows Keep a Changelog and versions follow Semantic Versioning.

## [Unreleased]

### Changed

- Adopted QenTerra repository standard 1.2.0 with complete governance, contribution, security, ownership, release, maintenance, and support documentation.
- Added a portable repository audit that rejects caches, AI or agent operating files, skills, MCP configuration, undeclared content, and incomplete generated-artifact provenance.

## 5.0.0 - 2026-08-28

### Added

- Published `@qenterra/design-tokens` with CSS, JSON, icon, and component-recipe exports.
- Published `QenTerraDesignTokens` and `QenTerraComponents` through Swift Package Manager.
- Added a complete SHA-256 release manifest and self-contained verifier.

### Changed

- Established `packages/` as the sole public export from the canonical Design System repository.

### Removed

- Excluded private assets, canonical design documentation, consumer manifests, internal history, and repository-local agent material from public delivery.
