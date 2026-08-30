# ReUI exact source catalog

This directory preserves the exact official source bytes for the free [ReUI Components](https://reui.io/components) registry at immutable live deployment `dpl_5RSqE4Z9JEuyKop4GstmsVpc15No`. The bundled MIT license is pinned to repository commit [`0daf79dff3ebe0ede7fa05bedcaefeaac93a8949`](https://github.com/keenthemes/reui/commit/0daf79dff3ebe0ede7fa05bedcaefeaac93a8949). The catalog contains both supported implementations: Base UI and Radix UI. Each base includes 1101 public examples plus the ReUI primitives and hooks required by the registry.

`Base/` and `Radix/` preserve the authored component, primitive, and hook sources. `Shared/SVGs/` contains exact shared logo components referenced by public examples. `Registry/BaseNova/` and `Registry/RadixNova/` preserve the matching install-ready shadcn registry payloads. ReUI produces these payloads with style/import transformations; they remain exact upstream bytes and are not QenTerra rewrites.

Provenance is explicit rather than cosmetically uniform: 2296 unchanged payloads are pinned to the official Git repository commit, while 64 additions or changes absent from that commit are pinned to the immutable live deployment. The two live aggregate-index hashes close the current free item boundary.

The boundary is the complete free item union declared by the live `base-nova/registry.json` and `radix-nova/registry.json` indexes: every `c-*` block plus every public `registry:ui` primitive and `registry:hook`. The two index payloads and every install payload are hash-pinned to the same deployment. ReUI Pro blocks, paid icons, templates, the website, documentation application, screenshots, videos, and build tooling are excluded. They are not part of the free open-source component registry, and pretending otherwise would be both technically wrong and legally sloppy.

The originals under this directory are immutable and are not adapted to QenTerra design tokens. Do not edit them directly. A modified or tokenized implementation must become a separate maintained component under `Sources/QenTerra/Components/`, with derivation provenance, token usage, tests, registry entry, delivery mapping, version, and changelog coverage. The ReUI original remains unchanged.

This catalog is reference source, not an npm or SwiftPM target. ReUI follows the copy-and-own shadcn model rather than publishing an npm component package. Install a selected registry item with the compatible shadcn workflow after reviewing its dependencies and target paths.

The bundled [`LICENSE.md`](LICENSE.md) is the exact upstream MIT license and identifies the original copyright holder as `Copyright (c) 2025 Keenthemes Inc`. QenTerra does not claim authorship of these files and does not relicense them under the Apache-2.0 terms that apply to QenTerra-authored public package material.
