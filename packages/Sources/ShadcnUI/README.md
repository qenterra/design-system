# shadcn/ui exact source catalog

This directory preserves the exact authored source bytes for every official `registry:ui` component declared by [shadcn/ui](https://github.com/shadcn-ui/ui) at commit [`b4a618b97e35f5dadf3a00d51f410c84a2567d4d`](https://github.com/shadcn-ui/ui/commit/b4a618b97e35f5dadf3a00d51f410c84a2567d4d). The catalog contains 182 component source files across React Aria (59), Base UI (62), Radix UI (61). Each source has its pinned upstream path, URL, byte count, and SHA-256 digest in `manifest.json`.

The scope is deliberately the public component layer under the upstream base registries. It does not copy the shadcn/ui documentation website, CLI, tests, examples, blocks, generated style outputs, or internal application code. Those files are not component originals and would turn a useful catalog into a stale monorepo mirror.

The original files under `Components/` are immutable and are not adapted to QenTerra design tokens. Do not edit them directly. A changed implementation must be created as a separate QenTerra-owned component under `Sources/QenTerra/Components/`, with its own token usage, tests, registry entry, delivery mapping, version, changelog entry, and derivation provenance. The upstream original remains unchanged.

This catalog is reference source, not an npm or SwiftPM target. shadcn/ui components are source-distributed React components and can require the dependencies, aliases, CSS variables, Tailwind configuration, and framework setup declared by the upstream project. Use the official shadcn tooling or copy a selected component into a web project after reviewing its manifest record.

The bundled [`LICENSE.md`](LICENSE.md) is the exact upstream MIT license and identifies the original copyright holder as `Copyright (c) 2023 shadcn`. QenTerra does not claim authorship of these files and does not relicense them under the Apache-2.0 terms that apply to QenTerra-authored public package material.
