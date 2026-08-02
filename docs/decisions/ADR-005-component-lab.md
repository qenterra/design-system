# ADR-005: Registry-backed Component Lab

- Status: accepted
- Date: 2026-08-02

## Context

A prose catalog names components but cannot prove their states, accessibility wiring, density behavior, or localization resilience. A separate framework would add another runtime and duplicate the static reference site's visual language.

## Decision

- Keep component contracts in `registry/components.json` with bilingual names, anatomy, states, stories, and accessibility requirements.
- Generate the Component Lab into the existing static site with stable component and story anchors.
- Persist density and text-stress choices in URL parameters so a failing view is shareable and reproducible.
- Generate deterministic pseudo-long and isolated pseudo-RTL content for layout stress.
- Add selected SwiftUI primitives without turning the package into a replacement for native controls.

## Consequences

Documentation, browser QA, and adapters now share one component inventory. Adding a component requires executable stories. Pseudo-locales and static ARIA checks improve coverage but do not claim human translation, VoiceOver, or native-product acceptance.
