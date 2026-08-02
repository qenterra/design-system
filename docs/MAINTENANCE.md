# Maintaining QenTerra Design System

## Sources of truth

- Behavioral rules: `docs/MASTER.md` and its complete Russian counterpart `docs/MASTER.ru.md`.
- Exact values: `tokens/*.json`.
- Reference UI: `src/assets/` plus generated content from both master files and both component catalogs.
- Reusable work products: `templates/design/` and `templates/repository/`.
- Brand rules and approved artwork: `docs/brand/`, `assets/brand/manifest.json`, and `assets/brand/`.
- Brand briefs and QA: `templates/brand/` and `scripts/brand/`.
- Generated output: `generated/`, `packages/*` generated adapters, and `dist/`.
- Semantic registries: `registry/`; each registry has a focused schema and a validator-owned invariant.

Never edit generated files directly.

AI working specs, implementation plans, handoffs, scratch notes, and tool-only artifacts are not project sources. Create them in a unique system temporary directory and never stage them. Durable product documentation, ADRs, requirements, and maintenance instructions remain normal repository content.

## Change workflow

1. Describe the user or engineering problem.
2. Identify affected platforms, components, patterns, and products.
3. Decide whether the change is foundation, semantic, platform, component, or product-specific.
4. Add an ADR for normative or breaking decisions.
5. Update sources.
6. Apply every normative content change to both `docs/MASTER.md` and `docs/MASTER.ru.md`; keep section numbers and stable anchors identical.
7. Update both component catalogs and localized audit evidence when the affected material appears there.
8. Run `python3 scripts/build.py`.
9. Run `python3 scripts/verify.py`.
10. Inspect English/Russian, Light/Dark, desktop/mobile, and standalone renders.
11. Update `CHANGELOG.md` and `VERSION`.
12. Update Obsidian routing only when workflow or product contracts change.
13. Commit source and generated output together.

## Brand assets

Brand PNG files live under `assets/brand/` and must be Git LFS objects. SVG, JSON, and Markdown stay in normal Git. Every asset has exactly one record in `assets/brand/manifest.json` with canonical/source paths, category, format, bytes, SHA-256, and image metadata.

Before adding or replacing artwork, read `docs/brand/MASTER.md` or `MASTER.ru.md`, the relevant profile, neighboring assets, and a matching template. Work in a unique system temporary directory. Install only approved final files, update the manifest, and run:

```bash
python3 scripts/brand/validate_brand_assets.py --check-git-lfs
python3 scripts/brand/validate_telegram_stickers.py
QDS_IMAGE_PYTHON=/path/to/python-with-pillow python3 scripts/verify.py
```

When character assets change, also run `validate_nyx_assets.py` with Python containing Pillow and NumPy and write its report to a system temporary directory. Generate contact sheets outside the repository and inspect them on light and dark backgrounds. Processing tools never download models and require their working directory to remain under the system temporary directory.

Changing identity, palette, category, delivery format, validation rule, canonical path, or asset name is normative. Update both language documents, `CHANGELOG.md`, and `VERSION`; add migration guidance for renamed or removed consumer paths.

## Versioning

- Patch: clarification, typo, or non-breaking correction.
- Minor: additive token, component, platform rule, or template.
- Major: renamed or removed semantic token, changed behavior contract, or required migration.

All token files, generated files, the site, and `VERSION` must report the same version.

## Localization parity

English and Russian are equally complete reference locales. Do not ship a language selector that translates only navigation chrome. Both masters must contain numbered sections 0–21 in the same order; shared stable fragment IDs must continue to resolve in both locale trees. Search indexes are generated independently from localized content. When localized terminology cannot be translated literally, preserve the semantic contract and record the wording decision in the relevant source document.

## Adding a token

Prefer an existing semantic token. Add a raw foundation token only if the current scale cannot express a reusable need. Add semantic meaning before exposing the value to a product. Document consumers and verify both appearances.

## Adding a component

Complete `templates/design/component-spec.md`, then add the executable contract and stories to `registry/components.json`. A component is incomplete without anatomy, content rules, all mandatory states, keyboard behavior, screen-reader semantics, responsive rules, localization expansion, reduced motion/transparency, increased contrast, and verification cases. Every registry story has a stable `pages/lab.html#story-{component}-{story}` route; pseudo-long and pseudo-RTL are stress tools, never production translations.

## Repository documentation

Use `docs/repository/STANDARD.md` or `STANDARD.ru.md` for the normative repository contract and select starting files from `templates/repository/`. Templates are never copied blindly: remove irrelevant sections, replace every placeholder, and verify product, privacy, legal, dependency, release, and screenshot claims against the current repository. Keep the design system as the single source; do not recreate a standalone documentation-standard folder.

## Local token packages

Add `packages/swift/` as a local Swift Package Manager dependency or reference `packages/css/` through a local JavaScript package dependency. Swift exposes typed `QDS.Color`, `QDS.Typography`, `QDS.Motion`, and `QDS.Component` APIs while preserving foundation aliases. CSS exports generated tokens by default and opt-in recipes through `recipes.css`. `scripts/build.py` generates adapter payloads from `tokens/*.json`; package manifests, recipes, and the hand-authored Swift facade are maintained sources. Package publication requires separate approval.

## Product exceptions

Add exceptions to the product profile, not foundation values. Record need, scope, accessibility impact, and review trigger. An exception requires a real product constraint, not visual preference.

## Consumer doctor

Start product adoption from `templates/design/qds-consumer.json` and `qds-exceptions.json`. Run `scripts/audit_consumer.py` against the product and write reports to `/private/tmp` or another path outside the consumer. The doctor is read-only and deliberately narrow: it validates declarations, detects local adapter usage, reports raw colors, and applies exact rule/path exceptions. Extend a rule only with a negative test and proof that pass and fail fixtures remain unchanged. Product-native build, rendering, accessibility, permissions, data, and recovery checks remain mandatory.

## Visual verification

`evidence/screenshots.json` is the exact capture matrix. Committed baselines live in `output/screenshots/`; current renders live only under ignored `output/tmp/`. Update baselines intentionally with `QDS_UPDATE_SCREENSHOTS=1`, then run `scripts/compare_screenshots.py` with the configured image Python. Inspect them at full size for clipping, contrast, hierarchy, focus, responsive navigation, and appearance parity. Automated screenshots do not prove screen-reader or native-app behavior.

## Obsidian synchronization

The Obsidian knowledge base routes agents to this repository and stores durable product contracts. It must not duplicate exact values from `tokens/`. Run its focused design-system reference validator and normal session gate after instruction changes.
