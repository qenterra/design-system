# 0003: Repository documentation as a QDS module

Status: Superseded by the Noetic QenTerra repository standard 1.2.0
Date: 2026-08-02

## Context

Repository documentation rules and copy-ready templates existed in a separate non-Git folder while QDS already owned family interface rules, screenshot policy, governance, and Obsidian routing. The split created two canonical paths, duplicated instructions, and no shared version or validation boundary.

## Decision

- Design System remains the sole canonical repository for universal UI, UX, visual, component, and package rules.
- Noetic owns repository governance policy, reusable repository templates, rendering, and adoption audits.
- Design System retains only its local adoption contract, portable checker, and project-specific documentation.
- The generated site exposes a separate bilingual Repository destination.
- Swift and CSS token adapters are local packages generated from `tokens/*.json`.
- Product-specific prepared Wiki content is resolved in the owning product, not imported into the universal module.
- The old standalone folder is retired only after parity, package, site, browser, and Obsidian gates pass.

## Consequences

The historical in-repository standard and template tree were removed after Noetic supplied a stricter, versioned replacement. Repository-governance changes now originate in Noetic and are adopted here through an explicit contract, avoiding a second source of truth. Design System package and visual rules remain locally authoritative.
