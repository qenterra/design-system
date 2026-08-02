# ADR-003: Repository documentation as a QDS module

Status: Accepted
Date: 2026-08-02

## Context

Repository documentation rules and copy-ready templates existed in a separate non-Git folder while QDS already owned family interface rules, screenshot policy, governance, and Obsidian routing. The split created two canonical paths, duplicated instructions, and no shared version or validation boundary.

## Decision

- QDS is the sole canonical repository for universal UX/UI and repository-documentation rules.
- Repository documentation remains a separate normative source under `docs/repository/`; it is not appended to the UX/UI master source.
- Design and repository templates use distinct categorized directories.
- The generated site exposes a separate bilingual Repository destination.
- Swift and CSS token adapters are local packages generated from `tokens/*.json`.
- Product-specific prepared Wiki content is resolved in the owning product, not imported into the universal module.
- The old standalone folder is retired only after parity, package, site, browser, and Obsidian gates pass.

## Consequences

QDS has one version and one maintenance workflow across both modules. Template paths change and all internal references must be migrated together. The build and validators must understand multiple source modules. The local packages are deliberately private and require no registry or publication workflow.
