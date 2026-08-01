# QenTerra Design System — completion requirements

This checklist is the completion contract for the initial local release.

## Canonical system

- [x] The approved family thesis is explicit: Cadence visual foundation, Unspool component discipline, Lilt state/motion/copy architecture.
- [x] Shared rules do not force identical product shells.
- [x] System, Light, and Dark appearances are defined.
- [x] Foundations cover color, typography, spacing, sizing, radius, borders, materials, iconography, imagery, layout, density, and motion.
- [x] Components cover controls, forms, navigation, containers, data display, feedback, overlays, progress, settings, onboarding, search, tables, and product archetypes.
- [x] Patterns cover permissions, destructive actions, imports/downloads, long operations, errors, recovery, offline behavior, selection, focus restoration, privacy, and responsive adaptation.
- [x] Platform layers cover macOS, iOS, iPadOS, web, and browser extensions.
- [x] Product profiles cover Cadence, Unspool, and Lilt with keep/adapt/replace/app-specific decisions.
- [x] Accessibility, localization, UX copy, screenshot QA, governance, exceptions, versioning, and maintenance are operationally defined.

## Files and site

- [x] `docs/MASTER.md` is the AI/developer reference.
- [x] `tokens/*.json` are machine-readable and validated.
- [x] Generated CSS and Swift token adapters exist.
- [x] A responsive multipage static reference is generated in `dist/`.
- [x] A fully standalone `dist/qenterra-design-system.html` contains the complete human reference with inline CSS and JavaScript.
- [x] The site itself uses the design system and supports System, Light, and Dark.
- [x] The site supports keyboard navigation, visible focus, reduced motion, increased contrast, print, mobile widths, and search.
- [x] Templates cover components, screens, product profiles, decisions, copy, accessibility, screenshots, motion, and migrations.
- [x] Update and contribution instructions explain how to change tokens, prose, generated files, and versioning.

## Evidence and governance

- [x] The cross-app audit and evidence confidence are preserved under `output/`.
- [x] Current known UX blockers and major findings are not hidden by the visual system.
- [x] Build, validation, negative tests, HTML link checks, and contrast checks pass.
- [x] Rendered desktop and mobile screenshots are inspected.
- [x] The repository is local-only, has no remote, and has a clean committed `main` branch.
- [x] Relevant Obsidian app/extension instructions are audited and synchronized with the canonical repository.
- [x] Obsidian templates, routing maps, README, changelog, and a focused validator are updated and pass their gates.
