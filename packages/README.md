# QenTerra Packages

Public Swift and npm packages for QenTerra design tokens and reusable interface components.

This repository is the complete, verified public projection of the private QenTerra Design System. It contains installable source, generated distribution files, tests, release metadata, and human documentation—no private assets, agent instructions, skills, caches, or internal work records.

[Architecture](docs/ARCHITECTURE.md) · [Development](docs/DEVELOPMENT.md) · [Testing](docs/TESTING.md) · [Releasing](docs/RELEASING.md)

## Workspace

- `Sources/` and `Tests/` contain the Swift package and its tests.
- `npm/design-tokens/src/` contains the public token, icon, and CSS generation inputs.
- `npm/design-tokens/dist/` contains the published CSS and JSON artifacts.
- `release-manifest.json` closes the public file set with byte sizes and SHA-256 hashes; it is not trusted as proof of generated-output freshness by itself.
- `scripts/` contains the deterministic public generator and self-contained release and repository-governance checks.

See the complete [repository structure](docs/REPOSITORY_STRUCTURE.md).

## Requirements and setup

- Swift 5.9 or later for native packages.
- macOS 13 or iOS 16 or later for supported Swift consumers.
- Node.js 22 or later for npm package inspection.
- Python 3.11 or later for repository verification.

No dependency installation is required to verify this checkout.

## Install

For web projects:

```sh
npm install @qenterra/design-tokens
```

For Swift Package Manager, add `https://github.com/QenTerra/packages` and select one or both products:

- `QenTerraDesignTokens` for typed foundations and SwiftUI adapters;
- `QenTerraComponents` for the maintained primary-button, group-container, and interactive-row primitives.

## Common commands

```sh
python3 scripts/generate.py check
python3 scripts/verify_release.py
python3 scripts/qenterra_repository_check.py audit --root . --format markdown
npm pack --workspace @qenterra/design-tokens --dry-run --json --cache /tmp/qenterra-packages-npm
swift test --scratch-path /tmp/qenterra-packages-swift --disable-sandbox
```

Use a unique temporary path outside the repository for every cache, build, report, or package-staging run. Remove it when the run is complete.

## Ownership and boundaries

Nikita Melnychenko (`@qenterra`) owns package APIs, release decisions, security coordination, and repository governance. Public source changes must regenerate every declared npm and Swift output byte-for-byte from `npm/design-tokens/src/` in an external temporary directory and keep the release manifest complete. See [Ownership](docs/OWNERSHIP.md) and [CODEOWNERS](.github/CODEOWNERS).

## Version and release model

All packages use one Semantic Versioning value. The current release is `5.0.0`; npm metadata, Swift source compatibility, release tags, changelog, and `release-manifest.json` move together. Tags use `v<version>` and published versions are immutable.

## Documentation

The [documentation index](docs/README.md) covers architecture, development, dependencies, testing, maintenance, deprecation, support, and releases. Public bugs and feature requests belong in [GitHub Issues](https://github.com/QenTerra/packages/issues).

## Contributing and security

Read [CONTRIBUTING.md](CONTRIBUTING.md) before proposing a change. Report vulnerabilities only through [GitHub private vulnerability reporting](https://github.com/QenTerra/packages/security/advisories/new); never include exploit details in a public issue.

## Contact

- Product support, product help, and technical questions: [support@qenterra.com](mailto:support@qenterra.com).
- Proposals, general enquiries, and commercial matters: [contact@qenterra.com](mailto:contact@qenterra.com).

## License

Copyright 2026 Nikita Melnychenko (QenTerra). Licensed under [Apache-2.0](LICENSE); preserve [NOTICE](NOTICE) when redistribution requires it.
