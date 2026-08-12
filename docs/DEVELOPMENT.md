# Development lifecycle

## Working contract

Every change has an owner, a source of truth, a risk level, and evidence. Start with the smallest user or system outcome worth shipping. Keep plans and tool output outside the repository. Store durable requirements, decisions, source, tests, and release records in their canonical locations.

Use the lifecycle as a set of gates. A small copy correction may pass several gates in one review. A permission, migration, payment, security, or destructive change needs separate evidence at each relevant gate.

## Lifecycle map

| Stage | Required input | Output | Exit evidence |
| --- | --- | --- | --- |
| Discover | Observed problem or opportunity | Problem statement and affected users | Source links, observation, or support evidence |
| Define | Problem statement | Scope, acceptance criteria, risks, non-goals | Reviewed requirement |
| Design | Approved scope | Flow, states, content, accessibility, platform behavior | Prototype or component contract |
| Architect | Design and constraints | Boundaries, data flow, effects, failure and migration plan | ADR when the decision is durable or breaking |
| Implement | Approved design and architecture | Readable source and focused tests | Format, lint, typecheck or build, unit tests |
| Review | Complete change | Corrected code and evidence record | Peer review and resolved findings |
| Release | Approved change | Versioned, licensed, documented artifact | Release checklist and reproducible build |
| Operate | Released artifact | Health, incident, support, and feedback records | Measured service or app evidence |
| Retire | Deprecation decision | Migration path and removal | Announced window, archived data plan, final release note |

## Discovery and definition

Name the person, task, environment, and failure cost. Separate observed facts from assumptions. Record privacy, accessibility, security, legal, data-loss, and compatibility risks before proposing a feature.

Acceptance criteria describe visible behavior and evidence. Non-goals protect the change from expanding during implementation. A requirement does not prescribe a component or technology unless the constraint comes from the platform or an existing contract.

## Design and architecture

Design the primary flow plus empty, loading, error, cancellation, recovery, permission, offline, and destructive states that apply. Define keyboard order, focus restoration, screen-reader semantics, text expansion, reduced motion, contrast, and minimum width.

Architecture assigns ownership for state, policy, persistence, network, security, and rendering. Use an ADR for a new dependency, public API, storage format, cross-module boundary, platform exception, or migration. The ADR states context, decision, consequences, and reversal or migration path.

## Implementation and verification

Read `CODE.md` and the platform profile before editing source. Add a failing regression test for a reproducible defect. Keep generated files derived from source. Review dependency metadata and license terms before adding a package, model, font, image, or dataset.

The canonical verification command must cover mechanical checks. Browser, native runtime, permissions, assistive technology, hardware, external services, and visual judgment remain separate evidence when automation does not exercise them.

## Review, commits, and release

Review behavior, boundaries, failure handling, privacy, accessibility, tests, documentation, and generated drift. For a material visual change, review an unarranged first-load render and a trace of the primary task; use a reviewer who did not build the change where one is available. Record that review as rendered evidence and name its absence as a manual gap. Use `COMMITS.md` for atomic history. Each commit keeps source, tests, and generated counterparts coherent.

Before release, update version, changelog, support range, migration notes, notices, screenshots, and distribution metadata. Build from a clean checkout. Sign, notarize, package, publish, or deploy only through the repository's documented release path.

## Operation, incidents, and retirement

Define logs and metrics that answer a support question without collecting unrelated personal data. Document backup, recovery, retention, deletion, and incident ownership. Treat crash-free launch, service health, latency, and failed operations as product evidence when they apply.

Deprecation names the replacement, warning channel, migration window, data effect, support end, and removal version. Retirement removes credentials, jobs, packages, documentation, and stored data under a reviewed plan. Preserve required legal and security records.

## Evidence record

Report four classes separately:

- **Automated:** format, lint, schema, build, unit, integration, browser, link, and generated-drift checks.
- **Rendered:** screenshots, snapshots, and pixel comparison for declared fixtures.
- **Live:** the built artifact using the real operating-system, device, permission, account, network, or service boundary.
- **Manual gap:** a required check that has not run.

Name the command, environment, result, and remaining gaps. A green command proves only the behavior that command exercised.
