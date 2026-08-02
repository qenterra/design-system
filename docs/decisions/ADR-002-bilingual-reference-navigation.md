# ADR-002: Bilingual reference and location-aware navigation

Status: Accepted
Date: 2026-08-02

## Context

The reference site needs complete Russian and English content, not a translated navigation shell around one English document. The standalone document also needs to show the reader's current top-level topic while a long page is scrolled. Interface icons previously mixed unrelated glyph styles.

## Decision

- Generate parallel `dist/en/` and `dist/ru/` trees from complete locale-specific Markdown sources.
- Keep numbered sections 0–21 and stable top-level fragment IDs aligned across locales.
- Use a locale-aware root entry and a keyboard-accessible globe menu that preserves the equivalent page and stable fragment.
- Generate independent localized search indexes.
- On standalone references, derive the active navigation item from the visible section and expose it with `aria-current="location"`.
- Render navigation, search, menu, and language symbols from one 16×16, 1.5-stroke, round-cap inline SVG family.
- Keep the prior root standalone path as an English compatibility artifact.

## Consequences

Every normative prose change must be applied to both master documents. Build and validation fail when locale structure diverges. Product application names and audit evidence remain valid source material; this decision does not rewrite or remove them. AI working directories are outside the repository boundary and are not design documentation.
