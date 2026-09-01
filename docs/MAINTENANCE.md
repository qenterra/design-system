# Maintaining Design System

## Sources of truth

- normative product references: `docs/MASTER.md`, `docs/MASTER_RU.md`;
- bilingual rules: `docs/MASTER.md`, `docs/MASTER_RU.md`;
- exact values: `tokens/*.json`;
- reusable contracts and delivery: `registry/`, `schemas/`;
- public staging tree: `packages/`;
- retained brand assets: `assets/brand/nyx/`, `assets/brand/manifest.json`;
- deterministic generators and gates: `scripts/`, `tests/`.

## Change workflow

1. Select `consume`, `evolve`, or `audit` and identify affected platforms/surfaces.
2. Read the relevant master section, source token, and registry entry.
3. For reusable work, define a universal contract before copying no consumer implementation at all.
4. Change canonical sources and add a negative test first for new behavior.
5. Synchronize changed source catalogs with their dedicated importer; use `python3 scripts/icon_catalogs.py sync --write` for the four external icon families.
6. Run `python3 scripts/generate.py write` and `python3 scripts/build_public_packages.py write` when public outputs change.
7. Update English/Russian normative guidance, `VERSION`, and `CHANGELOG.md` for normative work.
8. Run `python3 scripts/verify.py` and inspect npm/Swift package contents.

## Versioning

- patch: compatible correction;
- minor: compatible addition to tokens, components, adapters, or packages;
- major: renamed/removed token, package/API break, or required consumer migration.

All token metadata, registries, package manifests, generated outputs, and release manifest must equal `VERSION`.

## Components and packages

Every component registry item declares `delivered` or `specification-only`. Delivered items reference registered packages and unit evidence. New QenTerra packages require a distinct release boundary, versioned API, tests, clean-consumer proof, MIT metadata, and release-manifest paths. Third-party reference source requires precise provenance and attribution, a separate manifest, immutable originals, and explicit exclusion from the QenTerra license and installable targets unless its terms permit otherwise.

Public releases are prepared only from the allowlisted snapshot. Existing public tags and npm versions are immutable. See `docs/governance/EVOLUTION.md` and `docs/governance/PUBLIC_DELIVERY.md`.

## Nyx

Nyx is the only retained brand asset family. Every PNG remains in Git LFS and every file has one exact manifest record. Use temporary directories for processing/contact sheets and run the focused validators named by `scripts/verify.py`. Asset validation does not replace human inspection at original and use size.
