# 0014: Public canonical repository

Status: accepted

License clause superseded by [0016](0016-mit-license-for-qenterra-material.md); the repository topology and release-boundary decision remain accepted.

Date: 2026-08-31

## Context

Design System previously kept canonical source in a private repository and copied an allowlisted package snapshot into a second public `Packages` repository. The split duplicated repository metadata, documentation, automation, and release state. It also made the public package URL differ from the source of truth.

## Decision

Use `QenTerra/design-system` as the single public canonical repository. Expose SwiftPM products through the root `Package.swift`, publish `@qenterra/design-tokens` from `packages/npm/design-tokens/`, and retain `packages/` as a deterministic release boundary rather than a second repository. The original Apache-2.0 choice is retained here as historical context and replaced by [0016](0016-mit-license-for-qenterra-material.md).

Keep the existing Git history. Remove repository-local automation instructions, transient reports, and machine artifacts from the maintained tree, but do not rewrite historical commits merely to hide earlier project structure.

Third-party source catalogs retain their original ownership and license terms. The repository license covers only QenTerra-authored material and grants no trademark rights.

## Consequences

- Consumers use one GitHub URL for source, SwiftPM, issues, security reporting, and documentation.
- Package verification still closes an exact manifest and regenerates outputs independently.
- The separate `QenTerra/design-system` repository can be retired after replacement and consumer verification.
- Published versions and tags remain immutable; corrections use a new version.
