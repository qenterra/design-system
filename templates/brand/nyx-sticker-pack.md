# Nyx Telegram sticker pack — {Release}

## Scope

- Added: {exact PNG names}
- Replaced: {exact PNG names}
- Retired: {exact PNG names and map lines}
- Canonical directory: `assets/brand/nyx/telegram-stickers/`

## Inventory

- [ ] PNG stems and `Sticker Emojis.md` keys have exact one-to-one parity.
- [ ] Every name is short English Title Case without technical suffixes.
- [ ] Every sticker has one representative emoji.
- [ ] No SVG, GIF, TGS, WEBM, source, backup, contact sheet, or generated working file is present.

## Visual and technical gate

- [ ] Each PNG is static 512×512 8-bit RGBA with a transparent perimeter.
- [ ] The single illustrated white outline closes the full visible silhouette.
- [ ] Reactions remain distinct at chat size.
- [ ] Face, hands, hair, skin, clothing, crop, colored fringe, and props pass light/dark review.
- [ ] `python3 scripts/brand/validate_telegram_stickers.py` passes.
- [ ] Brand manifest, Git LFS, and full design-system verification pass.

## Result

- Automated evidence: {commands and results}
- Visual evidence: {temporary contact-sheet review}
- Live Telegram evidence: {verified result or explicitly not performed}
