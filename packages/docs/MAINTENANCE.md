# Maintenance

## Routine cadence

- Every change: run the release verifier, repository audit, affected package tests, and Git whitespace checks.
- Dependency or workflow update: inspect upstream release notes, licenses, action commits, permissions, and package payload changes.
- Release: verify the exact clean commit, manifest closure, Swift tests, npm archive, remote tag, repository branch, and published npm integrity.
- Quarterly: read back GitHub metadata, features, rules, security settings, ownership, support routes, and stale documentation.

## Repository hygiene

The public repository must remain human-authored and consumer-facing. Caches, build trees, coverage, reports, personal paths, AI or agent operating files, skills, MCP configuration, generated working plans, and tool state belong in unique temporary directories outside the checkout. The audit scans tracked, untracked, and ignored files; `.gitignore` is not a hiding place.

## Current record

| Date | Scope | Evidence | Result | Next review |
| --- | --- | --- | --- | --- |
| 2026-08-29 | Repository standard 1.2.0 adoption and public projection | Release verifier, governance audit, package tests, GitHub API read-back | Passed locally; provider-specific settings recorded in `GITHUB_SETTINGS.md` | Next release or 2026-11-29, whichever comes first |

If maintenance stops, update the README and repository description with status, final supported version, replacement, security boundary, and archival date. Archival, transfer, visibility change, or deletion requires explicit owner approval.
