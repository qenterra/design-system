# Nyx asset catalog

The machine-readable catalog is [`../../assets/brand/manifest.json`](../../assets/brand/manifest.json). This page describes selection without duplicating every filename or hash.

## Current inventory

| Category | Count | Canonical directory | Primary use |
| --- | ---: | --- | --- |
| Compositions | 21 | `nyx/character-assets/compositions/` | content zones, cards, comparisons, framing |
| Decorative | 10 | `nyx/character-assets/decorative/` | expressive graphic treatments |
| Full body | 56 | `nyx/character-assets/full-body/` | actions, direction, props, daily scenarios |
| Portraits | 30 | `nyx/character-assets/portraits/` | emotional states and compact reactions |
| Pet | 2 | `nyx/chatgpt-pet/` | pet manifest and animation atlas |
| Telegram pack | 50 | `nyx/telegram-stickers/` | 49 reaction PNG files and one emoji map |
| Wallpapers | 4 | `nyx/wallpapers/` | selected phone and desktop backgrounds |

Total: **173 files**, **510,093,508 bytes**. PNG: **171**, all tracked with Git LFS. JSON/Markdown: **2**, tracked in normal Git.

## Selection

1. For a reaction, search portraits, then Telegram stickers when the outlined sticker profile is appropriate.
2. For direction, action, or props, search full-body assets.
3. For content space or framing, search compositions by placement.
4. For a graphic treatment, use decorative assets only when hierarchy remains clear.
5. For a background or pet animation, use its dedicated delivery profile.

New roles get semantic filenames. Replace an existing path only when intentionally superseding that exact role. Keep temporary backups outside the repository until validation passes, then update the manifest and run the full gate.
