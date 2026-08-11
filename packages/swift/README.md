<p align="center">
  <img src="https://raw.githubusercontent.com/qenterra/design-system/main/assets/brand/qenterra/logos/vector/Dark%20Logo%20-%20Filled.svg" width="128" alt="QenTerra logo">
</p>

<h1 align="center">QenTerraDesignTokens</h1>

<p align="center">Private SwiftPM distribution of QenTerra design tokens, semantic icons, and focused SwiftUI adapters.</p>

<p align="center">
  <a href="https://github.com/qenterra/design-system-swift/wiki">Wiki</a> ·
  <a href="https://github.com/qenterra/design-system">Canonical repository</a> ·
  <a href="https://github.com/qenterra/design-system/blob/main/CHANGELOG.md">Changelog</a>
</p>

> **Status:** private, proprietary distribution mirror. Release `1.12.0` is
> generated and filtered from `packages/swift/` in the canonical private
> `qenterra/design-system` repository. Do not edit generated token or icon files
> in this repository.

## Capabilities

- `QDS` exposes generated color, typography, spacing, motion, and component
  metrics through typed Swift APIs.
- `QDSIcon` exposes reviewed semantic icon identifiers.
- `QDSPrimaryButtonStyle` and `QDSGroupContainer` provide small SwiftUI recipes.
- `QDSInteractiveRowSurface` and `QDSInteractiveRowState` preserve shared
  selection, focus, disabled, and Increased Contrast priorities.
- `QDSContractCheck` verifies representative public API behavior in a package
  build.

The package supports macOS 13+ and iOS 16+ and has no external package
dependencies.

## Get started

Add the private distribution from an authorized consumer:

```swift
.package(
    url: "https://github.com/qenterra/design-system-swift.git",
    from: "1.12.0"
)
```

Select the `QenTerraDesignTokens` product, then import it:

```swift
import QenTerraDesignTokens

let spacing = QDS.Space.value4
let duration = QDS.MotionSeconds.disclosure
```

Private GitHub access must be configured by the developer or CI environment.
Use read-only credentials scoped to this repository. Never place credentials in
`Package.swift`, source control, logs, or package mirrors.

## How it works

The canonical QDS build reads `tokens/*.json` and the semantic icon registry,
then generates the package's token and icon sources. The hand-authored facade
and SwiftUI adapters provide stable typed boundaries. Release automation checks
the exact payload, builds and tests the package, creates an immutable SemVer tag,
and reads the remote ref back before consumers can rely on it.

## Privacy and security

This package is source code and does not add a network client, analytics,
persistence, account access, or runtime data collection. Consumer applications
remain responsible for their own permissions, storage, network, privacy, and
accessibility boundaries.

Report suspected package or release vulnerabilities through the canonical
[Security Policy](https://github.com/qenterra/design-system/blob/main/SECURITY.md).
Do not post credentials, private product source, or production data in an issue.

## Development

For coordinated QDS work, add the local package at `packages/swift` from the
canonical repository. Verify it there:

```sh
swift build --package-path packages/swift
swift run --package-path packages/swift QDSContractCheck
swift test --package-path packages/swift
python3 scripts/package_release.py validate
```

`QDSGeneratedTokens.swift` and `QDSGeneratedIcons.swift` are generated. Change
canonical tokens or registries instead of editing those files.

## Architecture and ownership

This repository is a filtered distribution surface, not a second design-system
authority. Package definitions, source generation, release rules, documentation,
and changelog ownership remain in
[`qenterra/design-system`](https://github.com/qenterra/design-system).

## Current limitations

- Package build and tests do not prove rendering, VoiceOver output, or
  accessibility behavior in a consumer application.
- Platform-native presentation still overrides decorative sameness.
- Product migration and product-specific exceptions remain explicit consumer
  work.
- Main-branch documentation may move ahead of the latest immutable release tag;
  production consumers should use a tagged version.

## Support and license

Use the canonical repository's Issues for reproducible non-security problems or
email `support@qenterra.com` when access prevents issue reporting. The package is
proprietary and may be consumed only by QenTerra-authorized repositories and
products. Redistribution requires owner approval. See [LICENSE](LICENSE).
