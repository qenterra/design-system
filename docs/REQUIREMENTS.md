# Design System completion requirements

## Universal source

- [x] Human-facing name is Design System; machine paths use `design-system`.
- [x] Foundations cover color, typography, spacing, sizing, radius, borders, materials, iconography, layout, density, elevation, and motion.
- [x] Component contracts define anatomy, states, keyboard, accessibility, localization, lifecycle, evidence, and delivery status.
- [x] Native platform conventions and accessibility requirements override decorative sameness.
- [x] Product-specific differences stay in consumer profiles and expiring exceptions.
- [x] Root `SKILL.md` defines `consume`, `evolve`, and `audit` modes for Noetic.

## Installable delivery

- [x] Public npm package exposes CSS tokens, JSON tokens, reusable icon metadata, and the four existing CSS recipes.
- [x] Public Swift package exposes typed tokens plus the existing primary-button, group-container, and interactive-row primitives.
- [x] Public files are restricted to `packages/` and declared by path/hash.
- [x] Apache-2.0 and NOTICE attribution name QenTerra and Nikita Melnychenko.
- [x] New/improved reusable work must update source, registry, tests, package mapping, release manifest, version, and changelog.

## Removed scope

- [x] No static Design System viewing website or generated viewing output remains.
- [x] No email-template registry, composer, renderer, documentation, tests, or generated evidence remains.
- [x] Nyx is retained; every previous non-Nyx brand asset is removed.

## Evidence

- [x] Generation, schemas, registries, consumer audits, public boundary, terminology, npm contents, Swift tests, and Nyx manifest/profile checks are automated.
- [ ] Running consumer rendering, keyboard behavior, VoiceOver/screen readers, localization, and visual acceptance remain consumer-specific manual or runtime evidence.
