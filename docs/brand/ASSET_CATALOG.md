# Brand Asset Catalog

The machine-readable catalog is [`../../assets/brand/manifest.json`](../../assets/brand/manifest.json). This page explains selection; it does not duplicate every filename or hash.

## Current inventory

| Category | Count | Canonical directory | Primary use |
| --- | ---: | --- | --- |
| QenTerra banner raster | 24 | `qenterra/banners/raster/` | fixed-size publication and documentation art |
| QenTerra banner vector | 8 | `qenterra/banners/vector/` | responsive and scalable banner placement |
| QenTerra logo raster | 7 | `qenterra/logos/raster/` | fixed-size consumers and approved Dry/Wet treatments |
| QenTerra logo vector | 1 | `qenterra/logos/vector/` | preferred scalable mark source |
| Nyx compositions | 21 | `nyx/character-assets/compositions/` | copy, cards, comparisons, interface framing |
| Nyx decorative | 10 | `nyx/character-assets/decorative/` | expressive graphic accents |
| Nyx full body | 56 | `nyx/character-assets/full-body/` | actions, direction, work and daily scenarios |
| Nyx portraits | 30 | `nyx/character-assets/portraits/` | emotional states and compact reactions |
| Nyx pet | 2 | `nyx/chatgpt-pet/` | pet manifest and animation atlas |
| Nyx Telegram pack | 50 | `nyx/telegram-stickers/` | 49 reaction PNG plus emoji map |
| Nyx wallpapers | 4 | `nyx/wallpapers/` | selected phone and desktop backgrounds |

Total: **213 files**, **512,119,490 bytes**. PNG: **202**, tracked with Git LFS. SVG/JSON/Markdown: **11**, tracked as normal Git files.

## Selection rule

Search by function before creating anything:

1. Need a brand signature: choose a logo or banner variant by surface contrast, scale, and delivery format.
2. Need a character reaction: search portraits, then Telegram stickers when the white-outline delivery profile is appropriate.
3. Need a directional action or prop: search full-body assets.
4. Need room for content: search compositions by named placement or content zone.
5. Need a graphic accent: use decorative assets only when identity remains legible and content hierarchy stays intact.
6. Need a background or pet animation: use the dedicated delivery profile; do not repurpose a sticker or character cutout without a brief.

## Adding or replacing an asset

- Preserve the category's naming, format, dimensions, alpha/opacity, and outline profile.
- Use a new semantic filename for a new role. Replace an existing name only when intentionally superseding that exact role.
- Keep a temporary backup of replaced targets outside the repository until validation passes.
- Regenerate the manifest with:

```bash
python3 scripts/brand/validate_brand_assets.py \
  --source "/path/to/verified-source-tree" \
  --write-manifest
```

For normal future additions without a parallel source tree, update the manifest through the maintained generator workflow, then run:

```bash
python3 scripts/brand/validate_brand_assets.py --check-git-lfs
python3 scripts/verify.py
```

The source tree used during the one-time migration is provenance, not a permanent second authority.
