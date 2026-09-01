# 0015: Exact external icon source catalogs

- Status: Accepted
- Date: 2026-09-01
- Owners: @qenterra

## Context

Designers and consumers need a broad, searchable icon supply before drawing a new glyph. Tabler Icons, Phosphor Icons, Iconoir, and Bootstrap Icons publish complementary MIT-licensed SVG families. Mixing their visual grammars inside one product creates an incoherent interface, while rewriting originals destroys provenance without improving their geometry.

## Decision

Preserve every SVG in the official published source roots of all four repositories at one full pinned commit per repository. Keep variant and weight boundaries, exact source bytes, the exact upstream MIT license, author notice, original path and URL, byte count, and SHA-256 in separate public catalogs under `packages/Sources/<Family>/Icons/`.

Keep these catalogs outside npm and SwiftPM targets. Search semantic icons, native platform symbols, and the external catalogs before drawing a new glyph. Use one external icon family per project; mix only for brand marks, platform-native symbols, or a documented missing-glyph exception. An approved modification becomes a separate QenTerra-owned icon and never changes an upstream original.

## Alternatives

- Copy only a curated subset — rejected because omitted common glyphs would be recreated and completeness could not be proven.
- Convert or optimize SVGs during import — rejected because byte identity and upstream comparison would be lost.
- Merge all files into one directory — rejected because weights, styles, authorship, and visual-family consistency would become ambiguous.

## Consequences

- The public projection gains 19,005 reference SVGs and four exact licenses but no runtime dependency.
- Manifests and the exported verifier reject missing, extra, modified, resized, or undeclared SVGs.
- Live synchronization detects upstream additions, removals, license changes, and byte drift.
- Project-level family selection remains a design decision rather than accidental per-icon shopping.

## Verification

- `python3 scripts/icon_catalogs.py verify`
- `python3 scripts/icon_catalogs.py sync --check`
- `python3 packages/scripts/verify_source_catalogs.py`
- `python3 scripts/verify.py`

## Review trigger

Reopen this decision if any upstream changes its published SVG roots, licensing, repository ownership, file format, or distribution model.
