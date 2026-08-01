# QenTerra Design System — completion requirements

This checklist is the completion contract for the initial local release.

## Canonical system

- [ ] The approved family thesis is explicit: Cadence visual foundation, Unspool component discipline, Lilt state/motion/copy architecture.
- [ ] Shared rules do not force identical product shells.
- [ ] System, Light, and Dark appearances are defined.
- [ ] Foundations cover color, typography, spacing, sizing, radius, borders, materials, iconography, imagery, layout, density, and motion.
- [ ] Components cover controls, forms, navigation, containers, data display, feedback, overlays, progress, settings, onboarding, search, tables, and product archetypes.
- [ ] Patterns cover permissions, destructive actions, imports/downloads, long operations, errors, recovery, offline behavior, selection, focus restoration, privacy, and responsive adaptation.
- [ ] Platform layers cover macOS, iOS, iPadOS, web, and browser extensions.
- [ ] Product profiles cover Cadence, Unspool, and Lilt with keep/adapt/replace/app-specific decisions.
- [ ] Accessibility, localization, UX copy, screenshot QA, governance, exceptions, versioning, and maintenance are operationally defined.

## Files and site

- [ ] `docs/MASTER.md` is the AI/developer reference.
- [ ] `tokens/*.json` are machine-readable and validated.
- [ ] Generated CSS and Swift token adapters exist.
- [ ] A responsive multipage static reference is generated in `dist/`.
- [ ] A fully standalone `dist/qenterra-design-system.html` contains the complete human reference with inline CSS and JavaScript.
- [ ] The site itself uses the design system and supports System, Light, and Dark.
- [ ] The site supports keyboard navigation, visible focus, reduced motion, increased contrast, print, mobile widths, and search.
- [ ] Templates cover components, screens, product profiles, decisions, copy, accessibility, screenshots, motion, and migrations.
- [ ] Update and contribution instructions explain how to change tokens, prose, generated files, and versioning.

## Evidence and governance

- [ ] The cross-app audit and evidence confidence are preserved under `output/`.
- [ ] Current known UX blockers and major findings are not hidden by the visual system.
- [ ] Build, validation, negative tests, HTML link checks, and contrast checks pass.
- [ ] Rendered desktop and mobile screenshots are inspected.
- [ ] The repository is local-only, has no remote, and has a clean committed `main` branch.
- [ ] Relevant Obsidian app/extension instructions are audited and synchronized with the canonical repository.
- [ ] Obsidian templates, routing maps, README, changelog, and a focused validator are updated and pass their gates.
