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
- `registry/` — canonical semantic registries, including contact-channel roles.
- `generated/` — compatibility copies of generated CSS and Swift adapters.
- `packages/swift/` and `packages/css/` — connectable local typed tokens and opt-in component recipes.
- `dist/` — multipage reference and standalone HTML.
- `templates/design/` — interface design and review templates.
- `templates/repository/` — repository documentation, policy, GitHub, and Wiki templates.
- `docs/repository/` — normative bilingual repository documentation standard.
- `assets/brand/` — canonical QenTerra marks, Nyx library, and machine-readable asset manifest.
- `docs/brand/`, `templates/brand/`, and `scripts/brand/` — bilingual brand canon, reusable briefs, processing tools, and QA.
- `output/` — audit evidence, validation reports, and rendered screenshots.
- `docs/MAINTENANCE.md` — update and release workflow.

## Principles

- Shared semantics and behavior; product-specific shells.
- System typography and adaptive Soft Graphite.
- Opaque content, translucent functional chrome.
- Honest state, review before risk, and explicit recovery.
- Short interruptible motion.
- Accessibility and localization as component states.
- Exact values live once in tokens and are generated into platform adapters.

## Status

Version 1.5.0 adds the machine-readable component registry, bilingual Component Lab with stable story URLs, density and pseudo-locale stress modes, expanded browser accessibility checks, and selected SwiftUI primitives. Product migrations remain separate from this repository.

## Repository boundary

This repository is local-only until publication is explicitly approved. It contains no production user data, credentials, private application fixtures, or AI working directories. Temporary AI plans and scratch artifacts belong in a unique system temporary directory, never in the repository.
