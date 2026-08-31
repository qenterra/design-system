# 0011: Exact Magic UI source catalog

Status: accepted

Date: 2026-08-30

## Context

The Design System needs the complete public Magic UI component layer without turning the public package repository into a mirror of the Magic UI website. The official Components page currently lists a different set from the repository's root `registry.json`: the root registry retains stale entries and omits newer public components. Treating that file as complete would produce a catalog that is confidently wrong, which is the least useful kind of confidence.

Several Magic UI components also require dependencies, CSS variables, or keyframes declared only by their shadcn-compatible registry payload. Copying only the `.tsx` file would preserve source text but lose part of the official installation contract.

## Decision

Use the official Components docs navigation and its matching docs files as the completeness boundary at one pinned public upstream commit. Preserve exactly one `.tsx` source and one official `public/r/<component>.json` registry payload for every listed component under `packages/Sources/MagicUI/Components/` and `packages/Sources/MagicUI/Registry/`. Verify that the registry payload embeds the exact same source bytes and record both upstream paths, pinned URLs, byte counts, and SHA-256 digests in the canonical and package manifests.

Bundle the exact upstream MIT `LICENSE.md` with `Copyright (c) Magic UI`. Keep the catalog outside npm and SwiftPM targets. Exclude templates, demos, examples, documentation prose, website application code, and registry sources not listed by the public Components page.

Live synchronization must close navigation against docs, source, registry payload, license, public allowlist, and current version. Offline verification must reject missing, extra, resized, hash-modified, unpinned, category-drifted, or source/registry-mismatched files. Scheduled CI runs the live currentness check.

A QenTerra adaptation is a new maintained component under `Sources/QenTerra/Components/` with semantic tokens, tests, registry and delivery metadata, versioning, changelog coverage, and explicit derivation provenance. Neither upstream original is edited in place.

## Consequences

- The public catalog contains all 76 components currently shown by Magic UI and all 76 exact install-registry payloads.
- Required registry-only CSS and dependency metadata remains available without pretending the catalog is a configured React application.
- The official public page, not a stale aggregate registry, controls completeness.
- MIT obligations and Magic UI authorship remain visible beside the sources and in third-party notices.
- Upstream changes are reviewed as a new versioned snapshot; they do not silently mutate QenTerra components.
