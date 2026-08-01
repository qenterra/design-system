# Maintaining QenTerra Design System

## Sources of truth

- Behavioral rules: `docs/MASTER.md`.
- Exact values: `tokens/*.json`.
- Reference UI: `src/assets/` plus generated content from `docs/MASTER.md`.
- Reusable work products: `templates/`.
- Generated output: `generated/` and `dist/`.

Never edit generated files directly.

## Change workflow

1. Describe the user or engineering problem.
2. Identify affected platforms, components, patterns, and products.
3. Decide whether the change is foundation, semantic, platform, component, or product-specific.
4. Add an ADR for normative or breaking decisions.
5. Update sources.
6. Run `python3 scripts/build.py`.
7. Run `python3 scripts/verify.py`.
8. Inspect Light/Dark desktop and mobile renders.
9. Update `CHANGELOG.md` and `VERSION`.
10. Update Obsidian routing only when workflow or product contracts change.
11. Commit source and generated output together.

## Versioning

- Patch: clarification, typo, or non-breaking correction.
- Minor: additive token, component, platform rule, or template.
- Major: renamed or removed semantic token, changed behavior contract, or required migration.

All token files, generated files, the site, and `VERSION` must report the same version.

## Adding a token

Prefer an existing semantic token. Add a raw foundation token only if the current scale cannot express a reusable need. Add semantic meaning before exposing the value to a product. Document consumers and verify both appearances.

## Adding a component

Complete `templates/component-spec.md`. A component is incomplete without anatomy, content rules, all mandatory states, keyboard behavior, screen-reader semantics, responsive rules, localization expansion, reduced motion/transparency, increased contrast, and verification cases.

## Product exceptions

Add exceptions to the product profile, not foundation values. Record need, scope, accessibility impact, and review trigger. An exception requires a real product constraint, not visual preference.

## Visual verification

The site screenshots are generated into `output/screenshots/`. Inspect them at full size for clipping, contrast, hierarchy, focus, responsive navigation, and appearance parity. Automated screenshots do not prove screen-reader or native-app behavior.

## Obsidian synchronization

The Obsidian knowledge base routes agents to this repository and stores durable product contracts. It must not duplicate exact values from `tokens/`. Run its focused design-system reference validator and normal session gate after instruction changes.
