# QenTerra Design System

Shared UX/UI grammar for Cadence, Unspool, Lilt, and future QenTerra products.

The system combines Cadence's adaptive Soft Graphite visual foundation, Unspool's component and workflow discipline, and Lilt's state, motion, privacy, and localization architecture.

## Quick start

```bash
python3 scripts/build.py
python3 scripts/verify.py
python3 -m http.server 8000 --directory dist
```

Open `http://localhost:8000/` for automatic language selection, choose `dist/en/` or `dist/ru/`, or open either localized standalone reference directly.

## Core files

- `docs/MASTER.md` and `docs/MASTER.ru.md` — normative English and Russian AI/developer references.
- `tokens/` — exact machine-readable values and product profiles.
- `generated/` — generated CSS and Swift adapters.
- `dist/` — multipage reference and standalone HTML.
- `templates/` — component, screen, copy, accessibility, screenshot, and migration templates.
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

Version 1.1.0 adds a complete Russian reference, locale-aware navigation, standalone scroll tracking, and one consistent SVG icon family. Production migration of Cadence, Unspool, and Lilt is intentionally separate from this repository.

## Repository boundary

This repository is local-only until publication is explicitly approved. It contains no production user data, credentials, private application fixtures, or AI working directories. Temporary AI plans and scratch artifacts belong in a unique system temporary directory, never in the repository.
