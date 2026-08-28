# Product release versions and installers

This reference defines the shared version grammar and macOS installer contract
for QenTerra products. Product repositories own their concrete values; Design System owns
their format, schema, template, and read-only audit.

## Canonical manifest

Every published product keeps one `product-release.json` at the repository root.
Start from `templates/release/product-release.json` and validate it against
`schemas/product-release.schema.json`. Do not duplicate independently editable
release values in shell scripts, Xcode settings, documentation, or workflow
files. Those surfaces consume the manifest or are checked against it.

Run the read-only auditor from Design System:

```sh
python3 path/to/design-system/scripts/audit_release_contract.py path/to/product
```

Write optional machine-readable reports only outside the product repository.
The auditor rejects an output path inside the product so verification does not
silently mutate the subject it claims to inspect.

## Version grammar

Use these forms everywhere:

| Surface | Stable | Prerelease example |
| --- | --- | --- |
| Marketing version | `1.0.0` | `0.2.0` |
| Build | positive decimal integer | `2` |
| Public version | `1.0.0` | `0.2.0-beta.1` |
| Git tag | `v1.0.0` | `v0.2.0-beta.1` |
| Human release name | `Cadence 1.0.0 (14)` | `Cadence 0.2.0 Beta 1 (2)` |

Channels are `stable`, `alpha`, `beta`, and `rc`. Stable releases omit the
iteration. Prereleases require a positive iteration and use lowercase
`alpha.N`, `beta.N`, or `rc.N` in machine-readable versions. Xcode
`MARKETING_VERSION` uses the marketing version; `CURRENT_PROJECT_VERSION` uses
the build. Neither contains the public prerelease suffix.

Artifact names are deterministic:

- `{ArtifactStem}-{PublicVersion}-{Architecture}.dmg`
- `{ArtifactStem}-{PublicVersion}-{Architecture}.zip`
- `{ArtifactStem}-{PublicVersion}-SHA256SUMS.txt`

Never publish mutable `latest` filenames as canonical release evidence.

## macOS installer contract

A direct macOS release uses a DMG with the product app and a visible
`Applications` alias. The Finder window may carry a restrained product-specific
background, but it must preserve the real app icon, obvious drag direction,
legible labels, native keyboard and pointer behavior, and sufficient contrast.
Decorative treatments do not replace installation instructions.

When the Finder background is an image, declare `installer.background` with
`kind: "image"` and `scaleFactors: [1, 2]`. The DMG must contain both real 72-DPI
and 144-DPI representations rather than an upscaled single-resolution bitmap.
Products may omit `background` when they use the native Finder canvas.

Record the target architecture and minimum macOS version in the manifest. The
DMG, update archive, and checksums file use exactly the declared names. Build
the update archive from the same app bundle as the DMG, then verify both
payloads before publication.

## Signing and distribution truth

Declare `ad-hoc`, `developer-id`, or `app-store` signing and state notarization
separately. An ad-hoc build must declare `notarized: false` and enable the
Gatekeeper disclosure. Any direct unnotarized download requires the same
disclosure near the download and installation instructions. Never imply Apple
review, notarization, or identity verification that did not occur.

Developer ID signing, notarization submission, stapling, and Gatekeeper
assessment are separate release gates. A successful build or attractive DMG
proves none of them. Store releases follow the store's signing and packaging
path rather than reusing the direct-download claim set.

## Release evidence

Before publishing, verify schema and semantic alignment, Xcode versions,
minimum OS, architecture, app bundle identifier, artifact filenames, signing
state, notarization state, archive payload equality, and SHA-256 checksums.
Create the Git tag and release title from the manifest. Read the published
release back and compare its assets and prerelease status with the same source.

Automated gates do not prove the Finder drag interaction, first launch on a
clean Mac, Gatekeeper wording, update installation, VoiceOver output, or the
real playback path. Record these as live checks or manual gaps instead of
compressing them into “tested.”
