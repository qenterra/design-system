# Nyx asset governance

Nyx is the only retained brand asset family in Design System. New QenTerra logos are being developed separately and are not canonical here yet. Product interfaces inherit foundations from [`../MASTER.md`](../MASTER.md); Nyx artwork never replaces semantic interface tokens.

## Read in this order

1. [`NYX.md`](NYX.md) before creating, editing, animating, or placing Nyx.
2. [`ASSET_CATALOG.md`](ASSET_CATALOG.md) to select an existing category.
3. [`../../assets/brand/manifest.json`](../../assets/brand/manifest.json) for exact paths, hashes, dimensions, formats, and LFS status.
4. [`../../templates/brand/`](../../templates/brand/) for briefs and release checks.

Russian reference: [`MASTER.ru.md`](MASTER.ru.md).

## Sources of truth

| Concern | Canonical source |
| --- | --- |
| Interface foundations | `tokens/`, `docs/MASTER.md` |
| Nyx artwork | `assets/brand/nyx/` |
| File identity and provenance | `assets/brand/manifest.json` |
| Nyx rules | `docs/brand/NYX.md` |
| Repeatable briefs | `templates/brand/` |
| Automated checks | `scripts/brand/` |

## Asset lifecycle

1. Search the current catalog before creating anything.
2. Name the function, placement, states, constraints, and acceptance checks.
3. Work only in a unique system temporary directory and preserve originals until acceptance.
4. Validate a representative pilot before a large batch unless the whole batch is explicitly approved.
5. Inspect original size and actual use size on light and dark backgrounds.
6. Install only approved final files under `assets/brand/nyx/`.
7. Update `manifest.json`; every PNG remains a Git LFS object.
8. Run focused Nyx, asset-manifest, and complete repository gates.

Identity, palette, format, category, path, or naming changes are normative. Removal, rename, or visual replacement is breaking and requires explicit approval, versioning, changelog, and migration guidance.

Raw generations, prompt experiments, backups, image intermediates, contact sheets, and QA reports stay in a system temporary directory. The temporary asset browser may also write only outside the repository.
