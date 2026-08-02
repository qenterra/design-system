# Nyx sticker — {Reaction}

## Intent

- Emoji: {one representative emoji}
- Primary reaction: {one instantly readable emotion/action}
- Scene and prop: {only what strengthens the reaction}

## Direction

- Pose, gaze, expression, both hands, and crop: {exact direction}
- Canon: medium white hair, dark makeup, light neutral-warm skin, black outfit.
- Keep one visual gag; no text, watermark, alternate character, or background scene.

## Delivery

- `assets/brand/nyx/telegram-stickers/{Reaction}.png`
- Static 512×512 8-bit RGBA.
- Transparent perimeter on all four edges.
- One continuous hand-drawn white outline around the visible silhouette, including an intentional lower crop.
- Add or update exactly one `{Reaction} - {emoji}` line in `Sticker Emojis.md`.

## QA

- [ ] Emotion reads at chat size and differs from neighboring reactions.
- [ ] Face, fingers, skin, hair, clothing, prop, crop, and outline pass 100% inspection.
- [ ] Light/dark backgrounds reveal no magenta, blue cast, holes, halo, or double outline.
- [ ] Sticker validator, manifest validator, LFS check, and full verify pass.
- [ ] Live Telegram upload/rendering is recorded separately if actually performed.
