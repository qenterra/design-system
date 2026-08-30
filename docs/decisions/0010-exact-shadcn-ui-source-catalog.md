# 0010: Exact shadcn/ui source catalog

Status: accepted

Date: 2026-08-30

## Context

The Design System needs reusable web component references without coupling its universal tokens or maintained QenTerra components to one React primitive library. shadcn/ui publishes source-distributed components, currently in parallel React Aria, Base UI, and Radix UI bases. Copying one rendered website style would hide that choice; mirroring the whole upstream monorepo would mix components with documentation, CLI, tests, examples, blocks, generated files, and internal application code.

Vendored source must retain its upstream license and authorship, remain distinguishable from QenTerra-authored work, and be refreshable without silently editing originals or bypassing the public export boundary.

## Decision

Preserve every source file declared by every official upstream `registry:ui` base under `packages/Sources/ShadcnUI/Components/<Variant>/`. Pin each snapshot to a full public upstream commit and record the original path, immutable URL, byte count, and SHA-256 digest in both private and public manifests. Bundle the exact upstream MIT `LICENSE.md`, including `Copyright (c) 2023 shadcn`, and verify its bytes and authorship independently.

The catalog is reference source, not an npm or SwiftPM target. It excludes the upstream website, CLI, tests, examples, blocks, generated style outputs, and internal application files. Live synchronization discovers bases from the official repository, closes each `_registry.ts` file against the corresponding source directory, and updates the public allowlist deterministically. Offline verification rejects missing, extra, resized, or hash-modified sources and license drift.

A QenTerra adaptation is a new file under `Sources/QenTerra/Components/` with semantic tokens, tests, registry and delivery metadata, versioning, changelog coverage, and explicit derivation provenance. The upstream original is never edited in place.

## Consequences

- Consumers can inspect all official primitive-library variants without importing private Design System material.
- QenTerra tokens and component APIs remain independent of shadcn/ui implementation choices.
- Scheduled currentness checks detect upstream additions and changes; maintainers review and regenerate a versioned snapshot before release.
- The catalog does not claim to be a configured React application. Selected sources can still require dependencies, aliases, CSS variables, Tailwind configuration, and framework setup.
- MIT obligations and shadcn authorship remain visible in the distributed subtree and third-party notices.
