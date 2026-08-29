# Repository structure

## Workspace map

| Path | Kind | Owner | Public artifact | Verification |
| --- | --- | --- | --- | --- |
| `tokens/` | Canonical design values | `@qenterra` | npm and Swift adapters | `python3 scripts/generate.py check` |
| `schemas/` | Machine-readable contracts | `@qenterra` | None directly | `python3 scripts/verify.py` |
| `registry/` | Components, icons, packages, and delivery allowlist | `@qenterra` | `packages/release-manifest.json` | `python3 scripts/build_public_packages.py check` |
| `packages/` | Sole public repository projection | `@qenterra` | `qenterra/packages` and `@qenterra/design-tokens` | `python3 scripts/verify_public_boundary.py` |
| `assets/brand/nyx/` | Private canonical Nyx assets | `@qenterra` | None | `python3 scripts/brand/validate_brand_assets.py --check-git-lfs` |
| `docs/` | Human references and project governance | `@qenterra` | Selected package docs only | `python3 scripts/verify.py` |
| `scripts/`, `tests/` | Deterministic generation and verification | `@qenterra` | Public verifier only | `python3 scripts/verify.py` |

## Dependency direction

Tokens feed generators; generators write `generated/` and package adapters; registries decide what may leave `packages/`; tests consume the resulting public interfaces. Public package code never imports private assets, Noetic policy, consumer manifests, or repository-local agent instructions.

## Commands and caches

`package-lock.json` belongs to the private root. Swift scratch space, Python bytecode, npm cache, image-processing output, and exported snapshots are created under unique system temporary directories. The repository never treats a cache as source or release evidence.
