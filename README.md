# QenTerra Design System

Universal foundations, reusable visual components, palettes, platform adapters, and engineering contracts for websites, native applications, and other interface-bearing projects.

> **Status:** public canonical source, version `1.0.0`, licensed under Apache-2.0.

## Use it

Exact values come from `tokens/*.json`, together with the relevant component, icon, and package registries. Product-specific differences belong in the consumer's `design-system-exceptions.json`, not in universal foundations.

## Workspace

This repository owns the canonical tokens, schemas, registries, documentation, Nyx source assets, deterministic generators, and package sources. The `packages/` subtree is the package-delivery boundary; `registry/packages.json` declares its contents and `packages/release-manifest.json` records the exact paths and hashes. See the [repository map](docs/REPOSITORY_STRUCTURE.md).

## Install public packages

Web projects:

```sh
npm install @qenterra/design-tokens
```

Swift projects add:

```text
https://github.com/qenterra/design-system
```

Available Swift products are `QenTerraDesignTokens` and `QenTerraComponents`. The latter contains the primary-button style, group container, and interactive-row surface, each in its own source file. The public tree also includes five non-target reference catalogs: all 221 current Explore SwiftUI detail-page sources across 34 categories; all 182 official shadcn/ui `registry:ui` source files across React Aria, Base UI, and Radix UI; all 76 components on the official Magic UI Components page with their 76 exact install-registry payloads; all 745 official UIable `registry:ui` items, split into 684 showcase components and 61 required UI primitives; and the complete free ReUI registry for Base UI Nova and Radix UI Nova, containing 2,202 examples, 150 primitives, eight hooks, and 2,360 exact install payloads. Every catalog retains exact bytes and manifest-backed provenance; shadcn/ui, Magic UI, UIable, and ReUI additionally carry their exact upstream MIT licenses and copyright notices.

QenTerra-authored material uses Apache-2.0. Explore SwiftUI examples retain their original ownership and direct-publication permission; shadcn/ui, Magic UI, UIable, and ReUI sources retain their upstream MIT licenses and authorship. The reference catalogs are not SwiftPM or npm targets.

## Canonical structure

```text
tokens/                 exact foundation and semantic values
registry/               components, icons, packages, delivery status
schemas/                machine-readable contracts
packages/               package sources and release boundary
assets/brand/nyx/       canonical Nyx assets
docs/                   bilingual guidance and governance
templates/              consumer and repository templates
scripts/                deterministic generation, audits, validation
tests/                  negative and integration contracts
```

The former static viewing website and the complete email-template subsystem are intentionally absent. Every previous non-Nyx brand asset is also removed while new logos are being developed.

## Evolve it

Reusable work is not copied out of a consumer. First define a product-independent contract, then add canonical source, accessibility and localization behavior, tests, registry status, package delivery, version classification, and changelog entry. `registry/packages.json` controls the package snapshot, while `packages/release-manifest.json` locks its exact paths and hashes.

See [`docs/governance/EVOLUTION.md`](docs/governance/EVOLUTION.md) and [`docs/governance/PUBLIC_DELIVERY.md`](docs/governance/PUBLIC_DELIVERY.md).

## Ownership and boundaries

Nikita Melnychenko (`@qenterra`) owns the canonical system and release decisions. Working notes, transient reports, caches, credentials, and machine-local artifacts stay outside the repository. Detailed ownership is recorded in [OWNERSHIP.md](docs/OWNERSHIP.md) and enforced by [CODEOWNERS](.github/CODEOWNERS).

## Version and release model

`VERSION`, token metadata, registries, package manifests, generated adapters, and the release manifest move in lockstep under Semantic Versioning. Releases use immutable `v<version>` tags from a verified commit on this repository. See [RELEASING.md](docs/RELEASING.md) and [PACKAGE_RELEASE.md](docs/PACKAGE_RELEASE.md).

The maintained public line starts at `1.0.0`. Earlier internal snapshot identifiers remain visible in Git history but do not define the active release line. npmjs also retains the immutable historical `@qenterra/design-tokens@5.0.0` artifact from the retired Packages repository; it is not rewritten by the new baseline.

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

QenTerra-authored contents are licensed under the [Apache License 2.0](LICENSE); required attribution is in [NOTICE](NOTICE). Preserved Explore SwiftUI, shadcn/ui, Magic UI, UIable, and ReUI sources retain their separate ownership and terms and are not relicensed as QenTerra work. Apache-2.0 does not grant rights to QenTerra names, marks, or product identities.

## Contact

- Product support, product help, and technical questions: [support@qenterra.com](mailto:support@qenterra.com).
- Proposals, general enquiries, and commercial matters: [contact@qenterra.com](mailto:contact@qenterra.com).
- Vulnerabilities: follow the private reporting process in [SECURITY.md](SECURITY.md).
