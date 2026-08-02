# ADR-007: Semantic icons and deterministic design-tool handoff

- Status: accepted
- Date: 2026-08-02

## Context

Hand-authored icon maps and informal design-tool exports let identifiers, meanings, and library state drift independently. The large brand library also needed searchable browsing without turning generated helper sites into permanent repository debris.

## Decision

- Store interface icon IDs, meanings, categories, and reviewed SVG fragments in one strict registry.
- Generate Swift identifiers, a site sprite, package metadata, and Figma icon data from that registry.
- Generate Figma variables, styles, and component payloads deterministically from tokens and registries.
- Keep the searchable brand browser temporary and reject every output path inside the repository.

## Consequences

Adapters share semantic icon names while native products may map them to appropriate system symbols. Figma payloads are reproducible but require a separate importer and explicit library-update approval. Brand browsing becomes practical without checking another generated mini-site into Git.
