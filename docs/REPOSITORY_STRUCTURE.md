# Repository structure

## Workspace map

| Path | Kind | Owner | Public artifact | Verification |
| --- | --- | --- | --- | --- |
| `tokens/` | Canonical design values | `@qenterra` | npm and Swift adapters | `python3 scripts/generate.py check` |
| `schemas/` | Machine-readable contracts | `@qenterra` | None directly | `python3 scripts/verify.py` |
| `registry/` | Components, icons, packages, and delivery allowlist | `@qenterra` | `packages/release-manifest.json` | `python3 scripts/build_public_packages.py check` |
| `packages/` | Package sources and release snapshot | `@qenterra` | `qenterra/design-system` and `@qenterra/design-tokens` | `python3 scripts/verify_public_boundary.py` |
| `packages/Sources/MagicUI/` | Exact MIT-licensed public-page components and registry payloads | Magic UI; catalog maintained by `@qenterra` | Non-target source catalog | `python3 scripts/magic_ui.py verify` |
| `packages/Sources/ShadcnUI/` | Exact MIT-licensed web component references | shadcn; catalog maintained by `@qenterra` | Non-target source catalog | `python3 scripts/shadcn_ui.py verify` |
| `packages/Sources/UIable/` | Exact MIT-licensed component, primitive, and registry sources | CodedThemes; catalog maintained by `@qenterra` | Non-target source catalog | `python3 scripts/uiable.py verify` |
| `packages/Sources/ReUI/` | Exact MIT-licensed Base UI Nova and Radix UI Nova source and registry payloads | Keenthemes; catalog maintained by `@qenterra` | Non-target source catalog | `python3 scripts/reui.py verify` |
| `packages/Sources/{TablerIcons,PhosphorIcons,Iconoir,BootstrapIcons}/` | 19,005 exact MIT-licensed SVG originals | Respective upstream authors; catalogs maintained by `@qenterra` | Non-target source catalogs | `python3 scripts/icon_catalogs.py verify` |
| `assets/brand/nyx/` | Canonical Nyx assets | `@qenterra` | Public repository source, excluded from package payloads | `python3 scripts/brand/validate_brand_assets.py --check-git-lfs` |
| `docs/` | Human references and project governance | `@qenterra` | Selected package docs only | `python3 scripts/verify.py` |
| `scripts/`, `tests/` | Deterministic generation and verification | `@qenterra` | Public verifier only | `python3 scripts/verify.py` |

## Dependency direction

Tokens feed generators; generators write `generated/` and package adapters; registries define the package snapshot; tests consume the resulting public interfaces. Installable package code never imports brand assets, consumer manifests, or repository-only material.

## Commands and caches

`package-lock.json` belongs to the repository root. Swift scratch space, Python bytecode, npm cache, image-processing output, and exported snapshots are created under unique system temporary directories. The repository never treats a cache as source or release evidence.
