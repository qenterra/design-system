# Design System

Universal foundations, reusable visual components, palettes, platform adapters, and engineering contracts for websites, native applications, and other interface-bearing projects.

> **Status:** private canonical source, version `5.0.0`. Installable public outputs are released separately through [`qenterra/packages`](https://github.com/qenterra/packages).

## Use it

Noetic is the mandatory router for design-related agent work. It resolves this repository and reads root [`SKILL.md`](SKILL.md), which selects one mode:

- `consume` applies existing packages and contracts in a project;
- `evolve` promotes a genuinely reusable improvement into canonical sources and delivery;
- `audit` checks compliance and evidence without changing a consumer unless fixes were requested.

Humans and tools read exact values from `tokens/*.json`, then use the relevant component, icon, and package registries. Product-specific differences belong in the consumer's `design-system-exceptions.json`, not in universal foundations.

## Install public packages

Web projects:

```sh
npm install @qenterra/design-tokens
```

Swift projects add:

```text
https://github.com/qenterra/packages
```

Available Swift products are `QenTerraDesignTokens` and `QenTerraComponents`. The latter contains the existing primary-button style, group container, and interactive-row surface. No new visual components were added in version 5.0.0.

Public files are staged only under `packages/`. That tree has Apache-2.0 licensing and a required NOTICE attribution to QenTerra and Nikita Melnychenko. Private docs, Nyx, agent instructions, consumer manifests, and private history never enter it.

## Canonical structure

```text
tokens/                 exact foundation and semantic values
registry/               components, icons, packages, delivery status
schemas/                machine-readable contracts
packages/           sole public export allowlist
assets/brand/nyx/       retained private Nyx assets
docs/                   bilingual guidance and governance
templates/              consumer and repository templates
scripts/                deterministic generation, audits, validation
tests/                  negative and integration contracts
```

The former static viewing website and the complete email-template subsystem are intentionally absent. Every previous non-Nyx brand asset is also removed while new logos are being developed.

## Evolve it

Reusable work is not copied out of a consumer. First define a product-independent contract, then add canonical source, accessibility and localization behavior, tests, registry status, package delivery, version classification, and changelog entry. `registry/packages.json` controls what can become public, while `packages/release-manifest.json` locks the exact paths and hashes.

See [`docs/governance/EVOLUTION.md`](docs/governance/EVOLUTION.md) and [`docs/governance/PUBLIC-DELIVERY.md`](docs/governance/PUBLIC-DELIVERY.md).

## Verify

```sh
npm ci --ignore-scripts
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements-visual.txt
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" \
DESIGN_SYSTEM_IMAGE_PYTHON=.venv/bin/python \
python3 scripts/verify.py
```

The complete gate checks generated adapters, registries, public boundaries, terminology, consumer contracts, Nyx manifests and profiles, npm contents, SwiftPM builds/tests, and Git whitespace. It does not pretend that static checks prove runtime rendering, VoiceOver, keyboard behavior, or visual acceptance in a consumer. Humanity survives another honest test report.

## License

The canonical repository remains private and proprietary under [`LICENSE`](LICENSE). Only the contents of `packages/` are licensed under Apache-2.0 with the bundled NOTICE requirement.
