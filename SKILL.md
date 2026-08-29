---
name: design-system
description: Route and govern interface design, UI, UX, visual foundations, reusable components, and design-package work through the universal Design System. Use for consuming, evolving, or auditing design work; do not activate for work with no interface or visual-system impact.
---

# Design System

Design System is the universal source for interface foundations, reusable visual components, platform adapters, and their engineering contracts. Noetic routes applicable work here; this file is the live authority and must be read from the resolved repository root rather than copied into another project.

## Select a mode

- `consume`: apply existing tokens, components, patterns, palettes, icons, or packages in a consumer project.
- `evolve`: add or improve a reusable capability in Design System and its installable delivery.
- `audit`: inspect compliance, drift, package health, or design quality. Audit is read-only unless the task explicitly requests fixes.

Use `evolve` when a task creates or materially improves something reusable across unrelated products, even if the request began in a consumer. Consumer-specific behavior remains in that consumer and does not become a universal primitive merely because it looks tidy in one screenshot.

## Start every applicable task

1. Identify the consumer, platform, interface surface, and mode.
2. Read the relevant section of `docs/MASTER.md` or `docs/MASTER_RU.md` and the exact source token under `tokens/`.
3. Inspect `registry/components.json`, `registry/icons.json`, and `registry/packages.json` before inventing a replacement.
4. For `consume`, read `design-system-consumer.json` and `design-system-exceptions.json` when present. Validate them before implementation.
5. Prefer the public package declared in the package registry. Do not paste generated values or fork a package into the consumer.
6. Follow native platform conventions and accessibility requirements when they are stricter than shared presentation.

If the repository, this file, or required registries cannot be resolved, stop and report the missing authority. Never reconstruct Design System rules from memory.

## Consume

- Use semantic tokens instead of raw colors, radii, spacing, typography, shadows, or motion durations when a matching semantic role exists.
- Use an existing delivered component before building a local visual duplicate.
- Keep product shells native to their platform. Shared semantics and behavior matter; decorative sameness does not.
- Record intentional divergence in `design-system-exceptions.json` with an owner, reason, scope, and review date. An exception is debt with a clock, not a magic invisibility cloak.
- Pin released package versions for production. Local paths are allowed only for coordinated development and must not survive a release manifest.
- Run the consumer audit and the consumer's own tests. Static compliance does not prove live rendering, keyboard behavior, VoiceOver, or other assistive technology.

## Evolve

A reusable candidate enters Design System only when all of the following are true:

1. Its contract is independent of one product's content, navigation model, brand campaign, or business logic.
2. The affected foundation/component/pattern and supported platforms are explicit.
3. Tokens use semantic roles and do not encode a product exception in universal foundations.
4. The implementation, states, accessibility behavior, localization constraints, tests, and delivery surface are complete.
5. The relevant component/icon/package registry entry names its source, evidence, and public delivery status truthfully.
6. `packages/` contains the installable result or the registry explicitly marks the capability as specification-only.
7. `VERSION` and `CHANGELOG.md` classify the change. Breaking API/token changes require a major version; additive compatible delivery requires a minor version; compatible fixes require a patch version.
8. `python3 scripts/verify.py` passes from a clean generated state.

Never copy consumer code into the canonical packages automatically. Promote the contract deliberately, remove product assumptions, then implement it against canonical tokens. New packages must be registered, licensed, tested in a clean consumer, and added to the deterministic release manifest before publication.

## Audit

Check, in order:

1. authority and mode selection;
2. consumer manifest and exception validity;
3. token and component reuse;
4. platform and accessibility behavior;
5. registry/source/delivery consistency;
6. version and changelog alignment;
7. public export boundary and package installation;
8. evidence quality.

Separate automated evidence from manual evidence. Package builds and static scans do not establish visual acceptance, native rendering, interaction quality, or accessibility in a running product.

## Public delivery boundary

`packages/` is the only exportable tree. It may contain public package code, manifests, tests, README, Apache-2.0 license, NOTICE, and public CI. It must not contain:

- `SKILL.md`, Noetic policy, agent instructions, or consumer manifests;
- private documentation, private commit identifiers, secrets, or release credentials;
- Nyx or any other private asset;
- email tooling, static Design System viewing pages, screenshots, or generation debris;
- undeclared files outside `packages/release-manifest.json`.

Read `docs/governance/PUBLIC_DELIVERY.md` before preparing or publishing a release. External publication still requires the user's explicit authority and exact destination verification.

## Completion

Run `python3 scripts/verify.py`. For a public change, also inspect `npm pack --dry-run`, run Swift tests, build clean npm and SwiftPM consumers, and verify the exact release-manifest hashes. Report what was checked and what remains manual.
