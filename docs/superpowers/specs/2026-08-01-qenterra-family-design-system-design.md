# QenTerra Family Design System

Status: approved for implementation

Version target: 1.0.0

## Objective

Create a durable family design system for Cadence, Unspool, Lilt, future native apps, websites, and browser extensions. The system must be specific enough that a person or an AI can build consistent interfaces without inventing local styling, while leaving each product free to use the shell and domain components its job requires.

The deliverable is both a normative engineering reference and a polished human reference. It must be locally reproducible, dependency-light, inspectable, and enforceable through machine-readable tokens and validators.

## Approved family thesis

The shared core combines:

- Cadence's adaptive Soft Graphite visual identity and content hierarchy;
- Unspool's token discipline, operational density, preflight, and recovery patterns;
- Lilt's state vocabulary, motion model, privacy language, and localization discipline.

Family resemblance comes from grammar, not cloned layouts. Cadence remains a playback-first library, Unspool remains a dense file utility, and Lilt remains a menu-bar capability with transient HUDs.

## Considered approaches

### One universal application shell

Rejected. A single rail, settings layout, row height, and window composition would waste space in Unspool, weaken recognition in Cadence, and make Lilt pretend to be a document app.

### Visual tokens only

Rejected. Shared colors and radii without state, recovery, accessibility, copy, and governance rules reproduce the current failure mode: similar screenshots with inconsistent behavior.

### Layered system with product profiles

Selected. A common foundation defines meaning and behavior; platform layers translate it into native conventions; product profiles define deliberate exceptions and domain components.

## Architecture

```text
Foundation tokens
    -> Semantic roles
        -> Platform adapters
            -> Components
                -> Interaction patterns
                    -> Product profiles
```

### Foundation

Raw values: graphite ramps, spacing steps, duration steps, radius steps, type metrics, border widths, and opacity levels. Product code must not depend on raw foundation names when a semantic role exists.

### Semantic roles

Meaning-oriented tokens such as `surface.content`, `text.secondary`, `action.primary`, `state.destructive`, `motion.feedback`, and `radius.group`. These remain stable when a raw value changes.

### Platform adapters

macOS, iOS/iPadOS, web, and browser extensions map semantic meaning to platform primitives. Platform conventions win over decorative sameness.

### Components

Components define anatomy, states, keyboard behavior, accessibility, content rules, responsive behavior, and allowed variants. A component is not complete if it only defines appearance.

### Patterns

Patterns coordinate components across a task: Select → Review → Execute → Complete/Recover; focus restoration from floating surfaces; permission requests; destructive confirmation; empty versus no-results; offline and stale data; privacy-safe export.

### Product profiles

Each product records what it inherits, what it adapts, what it replaces, and what remains domain-specific. Product-specific values cannot silently leak into the family foundation.

## Visual direction

The visual character is adaptive Soft Graphite: neutral, content-first, compact, and calm. Dark is the signature appearance; System is the default preference; Light is a fully designed peer rather than an inverted afterthought.

Opaque surfaces carry content. Translucent materials are reserved for functional chrome and transient layers. Original media may retain color; application chrome remains predominantly monochrome. Semantic color communicates status together with text or iconography.

The site uses the same principles: system typography, opaque reading surfaces, sparse translucent navigation, a restrained graphite ramp, exact spacing, short motion, and no decorative gradient theatre.

## Site information architecture

The generated reference contains:

1. Overview and principles.
2. Foundations.
3. Components.
4. Patterns and states.
5. Motion.
6. UX writing and localization.
7. Accessibility.
8. Platform layers.
9. Product profiles and migration priorities.
10. Audit evidence.
11. Governance and maintenance.

Every page has global search, section navigation, appearance controls, print support, and direct anchors. The standalone HTML concatenates the full content into one navigable document and embeds all required CSS and JavaScript.

## Source and generated artifacts

Authoritative sources:

- `docs/MASTER.md` for normative prose;
- `tokens/*.json` for exact values;
- `src/pages/*.html` for human reference content;
- `src/assets/styles.css` and `src/assets/app.js` for the reference UI;
- `templates/` for reusable work products.

Generated artifacts:

- `dist/index.html` and `dist/pages/*.html`;
- `dist/assets/*`;
- `dist/qenterra-design-system.html`;
- `generated/qds-tokens.css`;
- `generated/QDSGeneratedTokens.swift`;
- `output/reports/*` and rendered screenshots.

Generated files carry a header and are never edited directly.

## Interaction and accessibility

The reference must work without a pointer. Navigation, search, appearance controls, disclosure, copy actions, and mobile menu are keyboard reachable. Focus is always visible. Landmark and heading order is valid. Motion honors `prefers-reduced-motion`; transparency honors `prefers-reduced-transparency` where supported and has an explicit opaque fallback class.

The design system requires equivalent platform checks for VoiceOver or screen readers, keyboard traversal, high contrast, color independence, text expansion, minimum and wide layouts, and reduced motion/transparency.

## Error handling

Build and validation commands fail closed. Invalid tokens, duplicate keys, unresolved links, missing generated artifacts, stale version markers, insufficient contrast, or placeholders return a non-zero exit code with a concrete fix.

The validator has negative tests proving that malformed input fails before generated artifacts are replaced.

## Obsidian integration

The Obsidian knowledge base remains the routing and working-instruction layer. It must not duplicate changing token values. A focused instruction points agents to this repository as the canonical design source, explains the read order, and defines the update workflow.

Existing Cadence, Lilt, Unspool, repository-family, and browser-extension instructions are audited for duplicated values, contradictions, obsolete inheritance, and stale references. Reusable product contracts remain in Obsidian; exact design values move to this repository.

Obsidian receives:

- a family design-system routing instruction;
- product-profile and component-review templates;
- a read-only reference validator;
- synchronized index, README, and changelog entries.

## Verification

Automated gates:

- JSON parsing and token schema checks;
- semantic reference resolution;
- generated CSS/Swift parity;
- duplicate IDs and broken local links;
- placeholder and stale-version scans;
- WCAG contrast checks for required text pairs;
- Python syntax and unit tests;
- clean `git diff --check`.

Visual gates:

- desktop wide;
- desktop constrained;
- tablet;
- mobile;
- Light and Dark;
- reduced motion;
- print/standalone document.

Manual gaps are reported separately from automated evidence.

## Out of scope

- Migrating production SwiftUI code in Cadence, Unspool, or Lilt.
- Publishing a remote repository or public website.
- Replacing current product app icons.
- Claiming live VoiceOver or native-app QA without actually performing it.

## Acceptance

The release is accepted only when every item in `docs/REQUIREMENTS.md` has direct current-state evidence, all automated gates pass, rendered artifacts are visually inspected, Obsidian synchronization passes its own validators, and the local Git repository is clean with no configured remote.
