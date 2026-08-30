# Magic UI exact source catalog

This directory preserves the exact authored source bytes for every component listed on the official [Magic UI Components page](https://magicui.design/docs/components) at commit [`2d671cc6c0e0f40e28682c9cbddd16694dcfe627`](https://github.com/magicuidesign/magicui/commit/2d671cc6c0e0f40e28682c9cbddd16694dcfe627). The catalog contains 76 TypeScript component files across Components (16), Special Effects (9), Animations (1), Text Animations (18), Device Mocks (3), Buttons (3), Backgrounds (11), Community (15). Each component has its pinned upstream path, URL, byte count, and SHA-256 digest in `manifest.json`.

`Registry/` also preserves the exact official shadcn-compatible registry item for every component. Those payloads retain required dependencies, CSS variables, and keyframes that are not always present in the `.tsx` source. They are provenance and installation metadata, not QenTerra-authored rewrites.

The scope follows the public Components page and its docs navigation. It excludes templates, demos, examples, documentation prose, the website application, internal-only registry sources, and unrelated monorepo code. The root upstream registry is not used as the completeness boundary because its current checkout contains stale entries that do not match the public page.

The originals under `Components/` and `Registry/` are immutable and are not adapted to QenTerra design tokens. Do not edit them directly. A changed implementation must be created as a separate QenTerra-owned component under `Sources/QenTerra/Components/`, with its own token usage, tests, registry entry, delivery mapping, version, changelog entry, and derivation provenance. The upstream original remains unchanged.

This catalog is reference source, not an npm or SwiftPM target. Magic UI components are source-distributed React components and can require the dependencies, aliases, CSS variables, Tailwind configuration, and framework setup declared by their official registry items. Install a selected item through the official Magic UI/shadcn workflow or copy it into a compatible web project after reviewing its manifest record.

The bundled [`LICENSE.md`](LICENSE.md) is the exact upstream MIT license and identifies the original copyright holder as `Copyright (c) Magic UI`. QenTerra does not claim authorship of these files and does not relicense them under the Apache-2.0 terms that apply to QenTerra-authored public package material.
