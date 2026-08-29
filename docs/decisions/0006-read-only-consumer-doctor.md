# 0006: Read-only consumer doctor

- Status: accepted
- Date: 2026-08-02

## Context

Family adoption needs consistent evidence, but automatically rewriting live products would cross repository boundaries, erase deliberate exceptions, and turn a design-system audit into a surprisingly ambitious demolition crew.

## Decision

- Products declare platforms, source roots, expected adapters, and an exception file in a strict manifest.
- The doctor reads only declared source roots and writes reports only outside the consumer tree.
- Initial rules cover local Swift/CSS adapter detection and raw colors.
- Exceptions match exact rule/path pairs and require a reason plus review trigger.
- Passing and failing synthetic fixtures prove detection and non-mutation before real product audits.

## Consequences

Audits are reproducible and safe to run on current products. Findings remain migration inputs, not automatic edits. Coverage is intentionally smaller than product compliance and will expand only with tested, low-noise rules.
