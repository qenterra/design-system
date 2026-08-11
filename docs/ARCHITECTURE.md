# Architecture

## System layers

QDS separates maintained definitions from generated delivery surfaces:

1. `tokens/` stores exact foundation, semantic, component, platform, and product
   values.
2. `registry/` and `schemas/` define machine-readable components, icons, email
   scenarios, and validation contracts.
3. `docs/` holds normative human rules, maintenance guidance, and decisions.
4. `src/` implements the local reference interface and browser interactions.
5. `scripts/build.py` validates and generates `dist/`, `generated/`, and package
   adapters.
6. `scripts/verify.py` checks deterministic generation, contracts, packages,
   assets, browser behavior, and exact visual evidence.

## Distribution boundaries

The canonical repository owns all definitions and generated adapter sources.
The private `design-system-swift` repository is a filtered `packages/swift/`
distribution. The restricted `@qenterra/design-tokens` GitHub package is built
from `packages/css/`. Neither distribution becomes an independent source of
truth.

Release tags are immutable. Version, payload allowlists, generated metadata,
package manifests, and remote refs must agree before publication. Consumers use
read-only credentials; only release automation receives narrowly scoped write
access.

## Browser reference

The generated site is static. It loads local assets and performs no application
backend work. Language, appearance, navigation, component stories, search, and
email composition are implemented in the browser. Email tooling is deliberately
unable to send messages, access accounts, persist entered values, or fetch
remote assets.

## Change ownership

Foundation and semantic changes begin in tokens and normative bilingual docs.
Product exceptions stay in `tokens/products.json` and the relevant product
profile. Brand files are accepted only under `assets/brand/`, with PNGs in Git
LFS and every approved asset represented by `assets/brand/manifest.json`.

## Verification boundary

Automated repository evidence does not prove native product rendering,
VoiceOver or other assistive output, real credentials, hardware behavior,
production migration, or external-service acceptance. Those remain live or
manual checks in the affected consumer.
