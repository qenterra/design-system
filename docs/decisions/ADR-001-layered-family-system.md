# ADR-001: Layered family system

## Status

Accepted

## Context

Applications can share a visual direction while serving different tasks, densities, shells, and interaction risks. Copying one layout across contexts damages native workflows, while sharing colors alone leaves behavior inconsistent.

## Decision

Use a layered system: foundation tokens → semantic roles → platform adapters → components → patterns → product profiles. Shared semantics and states are mandatory; product shells and domain components remain distinct.

## Consequences

- Products can remain recognizable members of one family without becoming clones.
- Exact values and behavioral rules have clear ownership.
- Platform-native conventions can override visual uniformity.
- Migration requires product profiles and cannot be completed by swapping a palette.
