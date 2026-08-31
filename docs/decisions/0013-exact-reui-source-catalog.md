# 0013: Exact ReUI source catalog

- Status: Accepted
- Date: 2026-08-30
- Owners: @qenterra

## Context

ReUI publishes free shadcn-compatible examples, primitives, and hooks for both Base UI Nova and Radix UI Nova. Its live registry is ahead of the public GitHub branch, while the same aggregate indexes also advertise commercial ReUI Pro blocks. Copying only GitHub would omit current free code; mirroring the whole live registry would publish paid material. Neither failure becomes respectable merely because it is automated.

## Decision

Use the two live aggregate indexes as the catalog boundary. Include every free `registry:block` whose name begins with `c-`, every public `registry:ui` primitive, and every `registry:hook` for both supported bases. Exclude all other blocks and paid surfaces.

Preserve exact repository payloads at one full official Git commit when their live index metadata is unchanged. Preserve additions or changed payloads absent from that commit from the immutable live Vercel deployment shared by both indexes. Store exact extracted source under `Sources/ReUI/Base/`, `Sources/ReUI/Radix/`, and `Sources/ReUI/Shared/`; store exact install payloads under `Sources/ReUI/Registry/BaseNova/` and `Sources/ReUI/Registry/RadixNova/`.

The public manifest records the repository commit, deployment revision, both index hashes, per-file origin, paths, URLs, byte counts, SHA-256 hashes, dependencies, and item kinds. Bundle the exact upstream MIT license and preserve `Copyright (c) 2025 Keenthemes Inc`. Keep the complete catalog outside npm and SwiftPM targets.

Originals are immutable. A modified or tokenized implementation becomes a separate QenTerra-owned component under `Sources/QenTerra/Components/` with derivation provenance, semantic-token integration, tests, registry coverage, delivery mapping, versioning, and changelog coverage.

## Alternatives

- Mirror the GitHub branch only — rejected because it is behind the live free registry.
- Mirror every live registry block — rejected because that includes 520 commercial Pro blocks.
- Rewrite imported code to Design System tokens — rejected because it destroys exact-source provenance and native upstream behavior.

## Consequences

- The public catalog contains 2,360 install items and 2,377 unique sources across both bases.
- Offline checks prove stored-byte integrity and catalog closure; live checks prove the registry indexes and deployment are still current.
- ReUI code is not presented as QenTerra-authored or relicensed as QenTerra-owned code; its exact upstream MIT license and attribution remain authoritative.
- Consumers copy selected items and satisfy their declared dependencies; the catalog itself adds no runtime package dependency.

## Verification

- `python3 scripts/reui.py verify`
- `python3 scripts/reui.py sync --check`
- `python3 packages/scripts/verify_source_catalogs.py`
- `python3 scripts/verify.py`

## Review trigger

Reopen this decision if ReUI changes its free/commercial boundary, licensing, registry styles, deployment pinning, item types, or distribution model.
