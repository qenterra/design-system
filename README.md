# QenTerra Design System

Shared UX/UI grammar for QenTerra native applications, websites, browser extensions, and future products.

The system combines an adaptive Soft Graphite foundation with disciplined components, honest state, short motion, privacy-aware copy, localization, and explicit recovery.

## Quick start

```bash
python3 scripts/build.py
python3 scripts/verify.py
python3 -m http.server 8000 --directory dist
```

Open `http://localhost:8000/` for automatic language selection, choose `dist/en/` or `dist/ru/`, or open either localized standalone reference directly.

## Core files

- `docs/MASTER.md` and `docs/MASTER.ru.md` — normative English and Russian AI/developer references.
- `tokens/` and focused `schemas/` — exact machine-readable values, product profiles, and fail-closed contracts.
- `registry/` — canonical semantic registries, including contact-channel roles and the bilingual email catalogue.
- `generated/figma/` — deterministic design-tool handoff payloads, never a parallel source.
- `generated/` — compatibility copies of generated CSS and Swift adapters.
- `packages/swift/` and `packages/css/` — canonical sources for private versioned SwiftPM and GitHub npm distributions.
- `dist/` — multipage reference and standalone HTML.
- `templates/design/` — interface design and review templates.
- `templates/repository/` — repository documentation, policy, GitHub, and Wiki templates.
- `docs/repository/` — normative bilingual repository documentation standard.
- `assets/brand/` — canonical QenTerra marks, Nyx library, and machine-readable asset manifest.
- `docs/brand/`, `templates/brand/`, and `scripts/brand/` — bilingual brand canon, reusable briefs, processing tools, and QA.
- `output/` — audit evidence, validation reports, and rendered screenshots.
- `docs/MAINTENANCE.md` — update and release workflow.
- `docs/EMAIL.md` and `docs/EMAIL.ru.md` — human-operated email rules, catalogue, authoring, copying, and QA.

## Principles

- Shared semantics and behavior; product-specific shells.
- System typography and adaptive Soft Graphite.
- Opaque content, translucent functional chrome.
- Honest state, review before risk, and explicit recovery.
- Short interruptible motion.
- Accessibility and localization as component states.
- Exact values live once in tokens and are generated into platform adapters.

## Status

Version 1.11.0 is the current canonical release. The next private distribution
publishes typed Swift tokens through `qenterra/design-system-swift` and CSS,
JSON, icons, and opt-in recipes through `@qenterra/design-tokens`. Product
migrations remain explicit consumer work.

## Repository boundary

This repository and its package distributions are private. It contains no
production user data, credentials, private application fixtures, or AI working
directories. Temporary AI plans and scratch artifacts belong in a unique system
temporary directory, never in the repository.
