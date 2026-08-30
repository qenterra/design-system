# UIable exact source catalog

This directory preserves the exact authored source bytes for all 745 `registry:ui` items published by the official [UIable Components](https://uiable.com/components) catalog at commit [`155aea5012cbb4f84e314ea51fe03db311dd7768`](https://github.com/codedthemes/uiable/commit/155aea5012cbb4f84e314ea51fe03db311dd7768): 684 showcase components under `Components/` and 61 required UI primitives under `Primitives/`.

`Registry/Components/` and `Registry/Primitives/` preserve the matching exact public shadcn-compatible registry payload for every source. The payloads are install and provenance metadata, not QenTerra-authored rewrites.

The boundary is the union of `src/components/uiable/registry.json` and `src/components/ui/registry.json`, cross-checked against every `registry:ui` item in `public/r/registry.json`. The 50 `registry:block` items are deliberately excluded because the requested upstream surface is Components, not Blocks. The website, documentation application, previews, examples, media, build tools, and unrelated repository files are also excluded.

The originals under `Components/`, `Primitives/`, and `Registry/` are immutable and are not adapted to QenTerra design tokens. Do not edit them directly. A changed implementation must become a separate QenTerra-owned component under `Sources/QenTerra/Components/`, with its own token usage, tests, registry entry, delivery mapping, version, changelog entry, and derivation provenance. The upstream original remains unchanged.

This catalog is reference source, not an npm or SwiftPM target. UIable components are source-distributed React components and may require the dependencies, aliases, CSS variables, Tailwind configuration, and framework setup declared by their official registry items.

The bundled [`LICENSE.md`](LICENSE.md) is the exact upstream MIT license and identifies the original copyright holder as `Copyright (c) 2026 CodedThemes`. QenTerra does not claim authorship of these files and does not relicense them under the Apache-2.0 terms that apply to QenTerra-authored public package material.
