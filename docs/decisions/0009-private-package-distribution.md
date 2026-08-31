# 0009: Private package distribution

Status: superseded by [0014](0014-public-canonical-repository.md)

Date: 2026-08-11

## Context

QDS adapters existed only as directories inside the canonical design-system
repository. That worked for adjacent local checkouts but made product builds
depend on filesystem layout, bundled a large unrelated brand library with Swift
resolution, and provided no immutable release boundary for consumers.

The canonical repository must remain private and retain ownership of tokens,
registries, generated adapters, documentation, and verification. Consumers need
small, versioned packages without gaining broader credentials or turning
generated output into a second source of truth.

## Decision

Publish two private SemVer distributions from `qenterra/design-system`:

- filter `packages/swift/` into the dedicated private repository
  `qenterra/design-system-swift` using deterministic subtree history;
- publish `packages/css/` as private GitHub package
  `@qenterra/design-tokens`.

`VERSION` is canonical. Publication requires aligned adapter metadata, explicit
payload allowlists, the full verification gate, immutable tag checks, and clean
remote consumers. The npm job alone receives `packages: write`. Cross-repository
Swift publication uses one write-enabled deploy key scoped only to the
distribution repository; consumer credentials are read-only. Existing
conflicting versions or refs fail instead of being overwritten.

## Consequences

- Product dependencies are stable and independent of local directory layout.
- Swift consumers no longer clone the canonical brand-asset history to resolve
  a small token package.
- Local paths remain available for coordinated QDS development but are not the
  production contract.
- Package success proves payload resolution and representative API availability,
  not application rendering, accessibility, permissions, persistence, or
  recovery.
- A faulty published version is corrected with a newer patch release. Release
  history is not rewritten to make the mistake look prettier after the fact.
