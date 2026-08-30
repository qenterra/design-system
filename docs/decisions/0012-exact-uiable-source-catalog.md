# 0012: Exact UIable source catalog

- Status: Accepted
- Date: 2026-08-30

## Context

The Design System needs the complete component source exposed by UIable without mirroring the website or silently changing upstream implementations. The official repository separates 684 showcase variants from 61 underlying UI primitives and publishes exact install payloads for both groups. Its public aggregate also contains 50 `registry:block` items, but those belong to the separate Blocks surface rather than the requested Components catalog.

Copying only the showcase files would produce attractive examples that are missing their required primitives and installation metadata. Copying the whole repository would publish unrelated site code, previews, media, and tooling. Both options are predictably bad in different costumes.

## Decision

Preserve the exact union of every `registry:ui` entry from `src/components/uiable/registry.json` and `src/components/ui/registry.json` at one full public upstream commit. Cross-check that union against the `registry:ui` entries in `public/r/registry.json`.

Store showcase sources under `packages/Sources/UIable/Components/`, primitives under `packages/Sources/UIable/Primitives/`, and the matching exact public registry payloads under `packages/Sources/UIable/Registry/Components/` and `Registry/Primitives/`. Record pinned paths, URLs, byte counts, SHA-256 hashes, item kind, categories, dependencies, and registry dependencies in private and public manifests.

Bundle the exact upstream MIT `LICENSE` as `LICENSE.md`, preserving `Copyright (c) 2026 CodedThemes`. Keep the catalog outside npm and SwiftPM targets. Exclude every `registry:block` entry, the website application, documentation prose, previews, media, examples outside the registries, and build tooling.

Originals are immutable. A tokenized or otherwise changed version becomes a separate QenTerra-owned component under `Sources/QenTerra/Components/` with derivation provenance, semantic-token integration, tests, registry coverage, delivery mapping, versioning, and changelog coverage.

## Consequences

- The public catalog contains 745 exact source files and 745 exact install payloads.
- Consumers can distinguish showcase implementations from the primitives they require.
- Offline checks prove stored-byte integrity and catalog closure; scheduled live checks prove currentness against the official repository.
- UIable code is not presented as QenTerra-authored and is not relicensed under QenTerra's Apache-2.0 terms.
- Blocks require a separate explicit decision if they are ever requested.
