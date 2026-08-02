# QenTerra Brand System

This directory is the canonical brand layer of QenTerra Design System. It governs identity assets, the Nyx mascot, asset selection, extension, validation, and release. Product interfaces inherit the design foundations in [`../MASTER.md`](../MASTER.md); brand artwork does not replace semantic UI tokens.

## Read in this order

1. [`QENTERRA.md`](QENTERRA.md) for logos and banners.
2. [`NYX.md`](NYX.md) before creating, editing, animating, or placing Nyx.
3. [`ASSET_CATALOG.md`](ASSET_CATALOG.md) to select an existing asset and understand its category.
4. [`../../assets/brand/manifest.json`](../../assets/brand/manifest.json) for exact paths, hashes, dimensions, formats, and LFS status.
5. [`../../templates/brand/`](../../templates/brand/) for briefs and release gates.

Russian reference: [`MASTER.ru.md`](MASTER.ru.md).

## Sources of truth

| Concern | Canonical source |
| --- | --- |
| UI colors, type, spacing, components, motion | `tokens/`, `docs/MASTER.md`, component catalog |
| Logo and banner artwork | `assets/brand/qenterra/` |
| Nyx artwork | `assets/brand/nyx/` |
| File identity and provenance | `assets/brand/manifest.json` |
| Brand rules | `docs/brand/` |
| Repeatable briefs | `templates/brand/` |
| Automated QA | `scripts/brand/` |

Never copy numeric UI values from a raster export. Never recreate a logo from memory. Never treat a prompt, contact sheet, cached generation, or old operational note as canonical artwork.

## Asset lifecycle

Every brand change follows the same sequence:

1. Inventory the target category and choose reuse, addition, replacement, or retirement.
2. Write a brief that names the function, placement, required states, constraints, and acceptance checks.
3. Work only in a unique system temporary directory. Preserve originals until the replacement passes.
4. Validate a representative pilot before producing a large batch unless the entire batch was explicitly approved.
5. Inspect at original size and at actual use size on light and dark backgrounds.
6. Install only approved final files under `assets/brand/`.
7. Update `manifest.json`; PNG files must remain Git LFS objects.
8. Run brand, Nyx, repository, and design-system verification.
9. Update both language references when a normative rule changes.

## Change classes

- **Editorial:** wording or navigation only; no asset or behavioral change.
- **Additive:** a new asset or template that obeys the existing canon.
- **Corrective:** a targeted technical repair that must preserve identity, composition, and role.
- **Normative:** a changed identity, palette, format, category, or release rule. Requires a version and changelog update.
- **Breaking:** removal, rename, path change, or visual change that invalidates consumers. Requires a migration note and explicit approval.

## Working-file boundary

The repository contains approved assets and durable specifications. Raw generations, prompt experiments, source backups, RGB/alpha intermediates, upscaler output, contact sheets, QA reports, and AI plans belong in `/private/tmp`, `/tmp`, or the platform temporary directory. A useful source format may enter the repository only after its ongoing role, ownership, naming, and validation are documented.

For browsing the canonical library, run `scripts/brand/build_asset_browser.py --output /private/tmp/...`. The searchable HTML is temporary evidence and the script rejects every output path inside this repository.

## Exceptions

A product may adapt placement, scale, crop, or density when its platform requires it. It may not silently recolor a mark, redesign Nyx, weaken accessibility, or create a parallel asset library. Record exceptions with scope, reason, owner, accessibility impact, and review trigger.
