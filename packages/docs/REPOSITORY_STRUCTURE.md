# Repository structure

| Path | Kind | Owner | Public surface | Verification |
| --- | --- | --- | --- | --- |
| `Package.swift` | Swift package manifest | `@qenterra` | Two library products | Swift package tests |
| `Sources/` | Maintained Swift source | `@qenterra` | Swift APIs | Swift package tests |
| `Tests/` | Swift regression tests | `@qenterra` | None | Swift package tests |
| `npm/design-tokens/src/` | Maintained npm source | `@qenterra` | CSS entry points | Release manifest and npm inspection |
| `npm/design-tokens/dist/` | Generated npm distribution | `@qenterra` | CSS and JSON exports | Source/output hash closure and npm inspection |
| `docs/` | Consumer and maintainer documentation | `@qenterra` | GitHub documentation | Repository audit |
| `scripts/` | Self-contained verification | `@qenterra` | Local and CI gates | Python execution and manifest self-check |
| `release-manifest.json` | Release file closure | `@qenterra` | Paths, sizes, SHA-256 hashes | `python3 scripts/verify_release.py` |

Swift and npm packages are peers under one version. `QenTerraComponents` may depend on `QenTerraDesignTokens`; the tokens target does not depend on the component target. Generated npm distribution depends only on its declared maintained source.

No cache, build, report, package-staging, or AI tooling path belongs under the repository root. Use a unique external temporary directory for each run.
