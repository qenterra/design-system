# Figma handoff exports

`generated/figma/` is a deterministic bridge from canonical Design System sources into design-tool automation. It is not a second source of truth and does not claim that a Figma library was published.

## Payloads

- `variables.json`: Foundation and Semantic collections with Default, Light, and Dark modes.
- `styles.json`: semantic text-style records derived from typography roles.
- `components.json`: component names, states, stories, and accessibility contracts.
- `icons.json`: semantic icon identifiers, categories, meanings, viewBox, and SVG fragments.

An importer must preserve names and modes, map color and float types explicitly, and report unsupported fields instead of dropping them silently. Re-import into a scratch file first, compare counts and names, then update a maintained Figma library only with separate approval.

Never edit generated exports. Change tokens or registries, run `python3 scripts/generate.py write`, inspect the JSON diff, and verify deterministic output.
