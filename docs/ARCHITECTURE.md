# Architecture

Design System separates canonical decisions from installable delivery.

## Private canonical source

1. `SKILL.md` defines the agent operating modes and routing contract.
2. `tokens/` owns exact foundation and semantic values.
3. `registry/` describes components, icons, packages, and truthful delivery status.
4. `schemas/` owns machine-readable contracts.
5. `docs/` and `templates/` own human guidance and reusable starting points.
6. `assets/brand/nyx/` and its manifest hold the retained private asset family.
7. `scripts/` and `tests/` generate and verify adapters, consumers, assets, and release boundaries.

Product-specific business logic and exceptions never enter universal foundations. Consumer repositories own `design-system-consumer.json`, `design-system-exceptions.json`, runtime code, fixtures, and acceptance evidence.

## Public delivery

`packages/` is the only exportable tree. `registry/packages.json` declares its packages, capabilities, paths, and tests. `packages/release-manifest.json` records the relative path, size, and SHA-256 of every public file except the manifest itself.

The public repository contains a Swift package at its root and the npm workspace under `npm/design-tokens/`. It has fresh public history and cannot contain Nyx, private docs, agent instructions, consumer manifests, or private commit identifiers.

## Evolution

Reusable candidates move from consumer evidence to a product-independent contract, then to canonical tokens/source, tests, registry status, delivery mapping, version, and changelog. Specification-only components remain explicit; a catalog entry does not magically become installable by believing in itself.
