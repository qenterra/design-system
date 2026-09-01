# Third-party notices

QenTerra Packages 1.0.0 declares no third-party runtime dependencies. It bundles exact source-reference catalogs from [Explore SwiftUI](https://exploreswiftui.com/), [Magic UI](https://magicui.design/docs/components), [shadcn/ui](https://github.com/shadcn-ui/ui), [UIable](https://uiable.com/components), and [ReUI](https://reui.io/components).

- The preserved examples remain attributed to Explore SwiftUI and are not presented as QenTerra-authored or relicensed as QenTerra work.
- `Sources/ExploreSwiftUI/manifest.json` records the originating page, Apple documentation link, dates, tags, platforms, byte count, and SHA-256 hash for every example.
- The reference catalog is not a SwiftPM product or target. It adds no runtime dependency to either QenTerra Swift product.

shadcn/ui source catalog:

- Copyright (c) 2023 shadcn.
- Licensed under the MIT License. The exact upstream text is bundled at [`Sources/ShadcnUI/LICENSE.md`](Sources/ShadcnUI/LICENSE.md).
- `Sources/ShadcnUI/manifest.json` pins the public upstream commit and records the original path, URL, byte count, and SHA-256 hash for every component source.
- The catalog covers every official `registry:ui` source declared by the React Aria, Base UI, and Radix UI bases. It is reference source, not a package target, and adds no runtime dependency to QenTerra packages.

Magic UI source catalog:

- Copyright (c) Magic UI.
- Licensed under the MIT License. The exact upstream text is bundled at [`Sources/MagicUI/LICENSE.md`](Sources/MagicUI/LICENSE.md).
- `Sources/MagicUI/manifest.json` pins the public upstream commit and records the original path, URL, byte count, and SHA-256 hash for every component source and official registry payload.
- The catalog covers all 76 entries on the official public Components page. It is reference source, not a package target, and adds no runtime dependency to QenTerra packages.

UIable source catalog:

- Copyright (c) 2026 CodedThemes.
- Licensed under the MIT License. The exact upstream text is bundled at [`Sources/UIable/LICENSE.md`](Sources/UIable/LICENSE.md).
- `Sources/UIable/manifest.json` pins the public upstream commit and records the original path, URL, byte count, and SHA-256 hash for all 745 sources and their 745 exact public registry payloads.
- The catalog covers the complete official `registry:ui` union of 684 showcase components and 61 required UI primitives. It excludes `registry:block` entries, is not a package target, and adds no runtime dependency to QenTerra packages.

ReUI source catalog:

- Copyright (c) 2025 Keenthemes Inc.
- Licensed under the MIT License. The exact upstream text is bundled at [`Sources/ReUI/LICENSE.md`](Sources/ReUI/LICENSE.md).
- `Sources/ReUI/manifest.json` pins the official repository commit, immutable live deployment, both live registry-index hashes, origin URL, byte count, and SHA-256 hash for every source and install payload.
- The catalog covers 1,101 free `c-*` examples, 75 public primitives, and four hooks in each of Base UI Nova and Radix UI Nova. The resulting 2,360 install items are reference source, not package targets. ReUI Pro blocks, paid icons, templates, the website, docs application, media, and build tooling are excluded.

- The Swift products use the Swift standard library and SwiftUI supplied by the consumer's Apple platform toolchain; those platform components are not redistributed here.
- The npm package ships only QenTerra-authored CSS and JSON and has no npm dependencies.
- Python, Node.js, npm, Swift, Xcode, and GitHub Actions are development or distribution tools obtained separately; they are not part of the package payload.

If a future release adds a bundled or runtime dependency, this file must record its exact version, purpose, source, SPDX license identifier, distribution status, and required notice text before publication.
