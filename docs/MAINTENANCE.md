# Maintaining Design System

## Sources of truth

- root agent contract: `SKILL.md`;
- bilingual rules: `docs/MASTER.md`, `docs/MASTER.ru.md`;
- exact values: `tokens/*.json`;
- reusable contracts and delivery: `registry/`, `schemas/`;
- public staging tree: `packages/`;
- retained private brand assets: `assets/brand/nyx/`, `assets/brand/manifest.json`;
- deterministic generators and gates: `scripts/`, `tests/`.

## Change workflow

1. Select `consume`, `evolve`, or `audit` and identify affected platforms/surfaces.
2. Read the relevant master section, source token, and registry entry.
3. For reusable work, define a universal contract before copying no consumer implementation at all.
4. Change canonical sources and add a negative test first for new behavior.
5. Run `python3 scripts/generate.py write` and `python3 scripts/build_public_packages.py write` when public outputs change.
6. Update English/Russian normative guidance, `VERSION`, and `CHANGELOG.md` for normative work.
7. Run `python3 scripts/verify.py` and inspect npm/Swift package contents.

## Versioning

- patch: compatible correction;
- minor: compatible addition to tokens, components, adapters, or packages;
- major: renamed/removed token, package/API break, or required consumer migration.

All token metadata, registries, package manifests, generated outputs, and release manifest must equal `VERSION`.

## Components and packages

Every component registry item declares `delivered` or `specification-only`. Delivered items reference registered packages and unit evidence. New packages require a distinct public boundary, versioned API, tests, clean-consumer proof, Apache-2.0 metadata, NOTICE, and release-manifest paths.

Public releases are prepared only from the allowlisted snapshot. Existing public tags and npm versions are immutable. See `docs/governance/EVOLUTION.md` and `docs/governance/PUBLIC-DELIVERY.md`.

## Nyx

Nyx is the only retained brand asset family. Every PNG remains in Git LFS and every file has one exact manifest record. Use temporary directories for processing/contact sheets and run the focused validators named by `scripts/verify.py`. Asset validation does not replace human inspection at original and use size.
