# Public dependency delivery

The canonical Design System repository is private. Only the deterministic contents of `packages/` may be released to `https://github.com/qenterra/packages`.

## Public contents

The release manifest allowlists package manifests, public source, generated token outputs, public tests, README, CI, Apache-2.0 license, and NOTICE. Every file has a SHA-256 digest. A path absent from the manifest does not ship.

The public tree must never contain brand assets, `SKILL.md`, Noetic files, agent instructions, private documentation, consumer manifests, secrets, absolute local paths, or private commit identifiers.

## Release sequence

1. Align `VERSION`, package versions, registry data, and `CHANGELOG.md`.
2. Generate public outputs from canonical tokens.
3. Run the full private verifier and clean npm/SwiftPM consumer tests.
4. Rebuild a clean public snapshot only from the release manifest.
5. Inspect the filesystem and `git ls-files` boundary.
6. Verify the exact GitHub owner, repository visibility, tag, and npm identity.
7. Publish explicitly; read back repository visibility, CI, tag target, npm metadata, and installation.

Published Git and npm history is immutable. A bad release is superseded or deprecated; it is not rewritten to make the evidence prettier.
