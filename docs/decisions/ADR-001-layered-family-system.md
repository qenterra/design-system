# ADR-001: Layered family system

## Status

Accepted

## Context

Cadence, Unspool, and Lilt share a visual direction but have different tasks, densities, shells, and interaction risks. Copying one application's layout would damage the others, while sharing colors alone would leave behavior inconsistent.

## Decision

Use a layered system: foundation tokens → semantic roles → platform adapters → components → patterns → product profiles. Shared semantics and states are mandatory; product shells and domain components remain distinct.

## Consequences

- Products can remain recognizable members of one family without becoming clones.
- Exact values and behavioral rules have clear ownership.
- Platform-native conventions can override visual uniformity.
- Migration requires product profiles and cannot be completed by swapping a palette.
