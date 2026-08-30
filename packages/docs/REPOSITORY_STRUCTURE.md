# Repository structure

| Path | Kind | Owner | Public surface | Verification |
| --- | --- | --- | --- | --- |
| `Package.swift` | Swift package manifest | `@qenterra` | Two library products | Swift package tests |
| `Sources/QenTerra/` | Maintained Swift source | `@qenterra` | Swift APIs and component manifest | Swift package tests and source-catalog verification |
| `Sources/ExploreSwiftUI/` | Exact attributed reference source | Explore SwiftUI; published by permission | No SwiftPM product or target | Sitemap synchronization, closed manifest, byte count, and SHA-256 |
| `Sources/MagicUI/` | Exact MIT-licensed component and install-registry source | Magic UI | No npm or SwiftPM product or target | Public docs closure, pinned commit, registry content, license, byte count, and SHA-256 |
| `Sources/ShadcnUI/` | Exact MIT-licensed component reference source | shadcn | No npm or SwiftPM product or target | Pinned upstream commit, registry closure, license, byte count, and SHA-256 |
| `Sources/UIable/` | Exact MIT-licensed showcase, primitive, and install-registry source | CodedThemes | No npm or SwiftPM product or target | Pinned upstream commit, registry:ui closure, source/payload equality, license, byte count, and SHA-256 |
| `Tests/` | Swift regression tests | `@qenterra` | None | Swift package tests |
| `npm/design-tokens/src/` | Versioned public generation inputs | `@qenterra` | Token, icon, and CSS sources | Deterministic regeneration and release manifest |
| `npm/design-tokens/schemas/` | Schemas for public token and icon inputs | `@qenterra` | Editor and maintainer validation | Release manifest |
| `npm/design-tokens/dist/` | Generated npm distribution | `@qenterra` | CSS and JSON exports | External regeneration, byte comparison, manifest, and npm inspection |
| `Sources/QenTerra/DesignTokens/Generated*.swift` | Generated native adapters | `@qenterra` | Typed tokens and symbols | External regeneration, byte comparison, manifest, and Swift tests |
| `docs/` | Consumer and maintainer documentation | `@qenterra` | GitHub documentation | Repository audit |
| `scripts/` | Self-contained verification | `@qenterra` | Local and CI gates | Python execution and manifest self-check |
| `release-manifest.json` | Release file closure | `@qenterra` | Paths, sizes, SHA-256 hashes | `python3 scripts/verify_release.py` |

Swift and npm packages are peers under one version. `QenTerraComponents` may depend on `QenTerraDesignTokens`; the tokens target does not depend on the component target. `Sources/ExploreSwiftUI/`, `Sources/MagicUI/`, `Sources/ShadcnUI/`, and `Sources/UIable/` are intentionally outside package target paths, so reference sources do not become build dependencies. Generated npm and Swift outputs depend only on `npm/design-tokens/src/` and the versioned public generator. All five source catalogs verify their own closure and hashes before `release-manifest.json` records the complete public closure; changing one editable manifest cannot make stale output valid.

No cache, build, report, package-staging, or AI tooling path belongs under the repository root. Use a unique external temporary directory for each run.
