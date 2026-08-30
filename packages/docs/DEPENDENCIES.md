# Dependencies

## Runtime inventory

| Surface | Dependency source | Runtime dependency | Purpose | License effect | Owner |
| --- | --- | --- | --- | --- | --- |
| Swift packages | `Package.swift` | None declared | Typed tokens and SwiftUI components | Repository Apache-2.0 only | `@qenterra` |
| npm package | `npm/design-tokens/package.json` | None declared | CSS and JSON design-token delivery | Repository Apache-2.0 only | `@qenterra` |
| Explore SwiftUI reference catalog | `Sources/ExploreSwiftUI/manifest.json` | None; not a package target | Copyable native source reference | Original ownership; direct publication permission, not Apache-2.0 relicensing | Explore SwiftUI / `@qenterra` |
| Magic UI reference catalog | `Sources/MagicUI/manifest.json` | None; not a package target | Copyable web component source and install registry | Upstream MIT license and Magic UI copyright; not Apache-2.0 relicensing | Magic UI / `@qenterra` |
| shadcn/ui reference catalog | `Sources/ShadcnUI/manifest.json` | None; not a package target | Copyable web component source reference | Upstream MIT license and shadcn copyright; not Apache-2.0 relicensing | shadcn / `@qenterra` |

SwiftUI and the Swift standard library are supplied by the consumer's Apple toolchain and are not redistributed by this repository.

Individual shadcn/ui component sources can declare React ecosystem dependencies and expect aliases, CSS variables, Tailwind configuration, and framework setup. Those are consumer-selected requirements of copied source, not runtime dependencies of QenTerra packages. Use the official shadcn workflow for installation and review the selected component before adoption.

Individual Magic UI registry payloads preserve the dependencies, registry dependencies, CSS variables, and keyframes required by each copied source. Use the official Magic UI/shadcn installation command for the selected component; the catalog itself does not install React, Tailwind CSS, Motion, or framework integration.

## Development tools

Python 3.11+, Node.js 22+, npm, Swift 5.9+, and full Xcode are external verification tools. They must use caches and build directories outside the repository. GitHub Actions are pinned to exact commits in workflow files.

## Updates

Review source, maintainer status, compatibility, transitive impact, license, vulnerabilities, and generated payload changes before adding any dependency. Run focused tests and the complete release and governance gates. A security alert is evidence to investigate, not permission for an unreviewed upgrade.

## Removal

Remove unused source, manifest entries, notices, tests, workflow configuration, and documentation together. Verify the exported package no longer contains the dependency or its generated residue.
