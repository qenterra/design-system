# Architecture

Design System separates canonical decisions from installable delivery.

## Canonical source

1. `tokens/` owns exact foundation and semantic values.
2. `registry/` describes components, icons, packages, and truthful delivery status.
3. `schemas/` owns machine-readable contracts.
4. `docs/` and `templates/` own human guidance and reusable starting points.
5. `assets/brand/nyx/` and its manifest hold the retained Nyx asset family.
6. `scripts/` and `tests/` generate and verify adapters, consumers, assets, and release boundaries.

Product-specific business logic and exceptions never enter universal foundations. Consumer repositories own `design-system-consumer.json`, `design-system-exceptions.json`, runtime code, fixtures, and acceptance evidence.

## Package delivery

`packages/` is the package-delivery boundary. `registry/packages.json` declares its packages, capabilities, paths, and tests. `packages/release-manifest.json` records the relative path, size, and SHA-256 of every package-snapshot file except the manifest itself. The boundary also includes versioned token and icon inputs plus a portable generator; its verifier rebuilds all declared npm and Swift outputs outside the checkout before accepting manifest closure.

The public repository exposes SwiftPM from its root `Package.swift` and the npm workspace under `packages/npm/design-tokens/`. The package snapshot excludes Nyx, repository-only documentation, consumer manifests, and unrelated history.

## Evolution

Reusable candidates move from consumer evidence to a product-independent contract, then to canonical tokens/source, tests, registry status, delivery mapping, version, and changelog. Specification-only components remain explicit; a catalog entry does not magically become installable by believing in itself.
