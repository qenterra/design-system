# Nyx Character Canon

Nyx is QenTerra's character mascot: an alternative/goth anime woman with medium-length white hair, expressive dark makeup, a light neutral-warm skin tone, and an all-black wardrobe. The baseline outfit is an oversized black hoodie, black skirt, ripped tights, and chunky black footwear. Recognition outranks the beauty of an isolated frame.

## Identity invariants

- Keep the same facial proportions, medium white hair, dark eye and lip treatment, and strong light-hair/dark-clothing contrast.
- Preserve a light neutral-warm skin base. Blush, tears, shadows, makeup, and motivated colored light may vary; an unrelated blue-gray skin cast may not.
- Do not turn Nyx into a chibi, pixel character, photoreal person, child, generic white-haired heroine, or another anime character wearing black.
- Dark garments need readable folds and separation. Sleeves, torso, legs, props, and hair may not collapse into one black mass.
- Anatomy, hands, fingers, gaze, and prop contact must remain plausible at 100% zoom and readable at use size.
- Do not add text, watermarks, signatures, or an unrelated product logo to character artwork.

## Direction and composition

One asset communicates one primary function or emotion. Direct the body, gaze, hands, props, crop, and negative space toward that purpose.

- **Full body:** vary height, support, profile, movement, and gesture. Preserve a readable silhouette and complete critical anatomy.
- **Portrait:** prioritize distinct emotional states. Avoid accidental cuts through hair, chin, hands, or the meaningful gesture.
- **Composition:** reserve deliberate clean space for copy, cards, comparisons, or interface content. Nyx supports the hierarchy and does not fight it.
- **Decorative:** style may change, but identity and pose must still be recognizable. A filter over a repeated silhouette is not a new composition.
- **Props:** include only when they strengthen the action. The object must be held or contacted correctly and may not become the main character.

The approved library retains one explicit matched-pose style comparison: `Decorative/Duotone.png` and `Decorative/Line Art.png`. The exception is machine-recorded in `nyx_assets_spec.json`; do not infer permission for other duplicate silhouettes or place both variants in the same composition.

## Character assets

Canonical location: `assets/brand/nyx/character-assets/`.

- 4096×4096 RGBA PNG.
- Transparent background and fully transparent outer perimeter.
- No Telegram white outline.
- English Title Case filename describing action, reaction, or layout function.
- No dates, attempt numbers, `final`, `fixed`, `upscaled`, `generated`, or version suffixes.
- Fully transparent pixels use zeroed RGB to avoid colored resampling fringe.
- Inspect white hair, eyelashes, skin, hands, fingers, sleeves, tights, footwear, props, alpha edges, and interior colored lines on light and dark backgrounds.

## Telegram stickers

Canonical location: `assets/brand/nyx/telegram-stickers/`.

- Static 512×512 8-bit RGBA PNG is the only current delivery format.
- The hand-drawn white outline is part of the illustration. Do not synthesize a second global outline.
- Neither artwork nor outline touches any canvas edge. A flat portrait cut still needs a closed white lower line and transparent space below it.
- Use one immediately readable reaction and no text.
- Keep `Sticker Emojis.md` in exact one-to-one parity with PNG stems; one representative emoji per sticker.
- Raw generations, alpha masters, contact sheets, animated experiments, SVG, TGS, WEBM, and GIF do not belong in the delivery directory.
- Animation requires a separate approved brief naming targets, delivery format, cycle length, rest state, motion purpose, and QA. Meaningless shake, bounce, scale, or infinite looping is not character animation.

## Wallpapers

Canonical location: `assets/brand/nyx/wallpapers/`.

The current selected set is source truth: two 1284×2778 iPhone exports and two 3024×1964 desktop exports: `Shy (MacBook).png` and `Thinking (Chrome).png`. Older notes that prescribe seven differently named 5K files or a single exact `#3C3E43` background are superseded by the actual approved collection.

- Wallpapers are opaque RGBA PNG with a dark neutral graphite edge field.
- Use a deliberate wide or vertical composition; do not mechanically crop one device export into another.
- Preserve useful negative space and keep hair, hands, knees, and footwear away from accidental cuts.
- Backgrounds stay dark and subordinate. A quiet neutral field is the default; restrained monochrome structural texture is allowed when it has a deliberate device/profile relationship and preserves clear hierarchy. `Shy (MacBook).png` is the approved reference for this exception. Avoid random synthetic scenery, text, logos, decorative gradients, or irrelevant objects.
- Upscaling cannot repair broken anatomy or invented hair detail. Correct the source first, then restore detail without global oversharpening or colored fringe.

## ChatGPT pet

Canonical location: `assets/brand/nyx/chatgpt-pet/`.

`pet.json` identifies Nyx and the `spritesheet.png` atlas. Changes must preserve manifest/schema compatibility, grid geometry, transparent cells, and the installed animation's character identity. A pet motion is its own delivery profile; Telegram sticker rules do not automatically apply.

## Generation and processing

1. Inventory the category and name the real product or communication gap.
2. Propose distinct directions and approve a matrix before a large batch.
3. Write pose, torso direction, gaze, expression, both hands, fingers, prop contact, crop, and negative space explicitly.
4. Generate and process only in a system temporary directory.
5. A drawn checkerboard is not transparency. Treat it as an RGB source until a real alpha channel exists.
6. Remove only the connected technical key/background. Do not globally delete warm or magenta pixels that may belong to skin, makeup, or artwork.
7. For restoration, upscale RGB on a neutral backing and alpha separately, then reconstruct RGBA and neutralize only contaminated edge hues.
8. A tool cannot repair wrong identity, anatomy, gaze, or gesture. Regenerate or make a targeted art correction.
9. Validate the installed canonical file and compare checksums; a clean cache output proves nothing about the repository copy.

## Release gate

- identity, emotion, pose, anatomy, crop, negative space, and category role reviewed;
- format, dimensions, mode, alpha/opacity profile, naming, manifest, and LFS status validated;
- light/dark or actual-background visual inspection completed at 100% and use size;
- no colored key fringe, checkerboard, halo, accidental interior line, watermark, or duplicate outline;
- replacements compared with their originals so a local fix did not drift face, clothing, skin, or composition;
- temporary outputs remain outside the repository;
- live platform validation is reported separately from static validation.

Use `scripts/brand/validate_brand_assets.py`, the focused Nyx validators, and the templates in `templates/brand/`.
