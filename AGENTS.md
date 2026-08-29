# Design System

Read root `SKILL.md` first for any design, UI, UX, visual, component, or package work. Noetic is the router; this repository is the live domain authority. Read `docs/MASTER.md` or `docs/MASTER_RU.md` and the affected `tokens/*.json` before implementation. Generated files are outputs, never sources. The two language references must stay semantically complete and structurally aligned.

## Required workflow

1. Identify the affected foundation, component, pattern, platform, or product profile.
2. Read the relevant section of `docs/MASTER.md` and the referenced token file.
3. Change source files only: `tokens/`, `registry/`, `schemas/`, `docs/`, `templates/`, package manifests, or hand-authored package facades.
4. Run `python3 scripts/verify.py`.
5. Inspect generated package payloads and clean-consumer evidence before claiming delivery completion.
6. Update `CHANGELOG.md` and `VERSION` for every normative change.

## Boundaries

- Family consistency means shared semantics and behavior, not identical product shells.
- Native platform conventions override decorative sameness.
- Product-specific exceptions belong in `tokens/products.json` and the product profile, not in foundation tokens.
- Do not add raw colors, ad hoc motion durations, or one-off radii to product code when a semantic token exists.
- Do not claim live app, VoiceOver, native rendering, or browser acceptance from package/static checks.
- `packages/` is the sole public export allowlist. Keep the canonical repository private.
- Never place assets, `SKILL.md`, Noetic policy, AI instructions, private documentation, consumer manifests, or private commit identifiers in the public export.
- Noetic owns the QenTerra repository standard, renderer, and reusable repository templates. This repository owns only its adopted contract in `.github/qenterra-repository.json`, its portable checker, and project-specific documentation. Do not recreate a parallel standard here.
- Consume released adapters through public packages. Local paths are for coordinated development only.
- A reusable improvement must update its registry entry, implementation, tests, delivery mapping, version, and changelog. Do not copy consumer code into canonical packages automatically.
- Create AI working specs, plans, handoffs, scratch notes, and tool artifacts only in a unique system temporary directory. Never add `.superpowers/` or `docs/superpowers/` to the repository.
- Store canonical brand assets only under `assets/brand/`; every PNG there must use Git LFS and every asset must be covered by `assets/brand/manifest.json`.
- Nyx is the only retained brand asset family. Do not add or remove brand families without explicit user direction.
- Generate contact sheets, validation reports, asset-processing intermediates, backups, and prompt outputs outside the repository. The repository contains approved source assets and durable documentation, not the production mess that created them.
