# Public dependency delivery

The canonical Design System repository is private. Only the deterministic contents of `packages/` may be released to `https://github.com/qenterra/packages`.

## Public contents

The release manifest allowlists package manifests, safe public generation inputs, the portable generator, generated npm and Swift outputs, the exact Explore SwiftUI reference catalog, public tests, README, CI, license, and notices. Every file has a SHA-256 digest. The exported verifier regenerates declared outputs outside the checkout and independently closes both Swift source catalogs before it checks release digests; a changed artifact and matching edited hash do not pass. A path absent from the manifest does not ship.

Explore SwiftUI originals are published under direct permission, stored byte-for-byte from the detail-page source field, and excluded from SwiftPM targets. They are never tokenized or edited in place. An adaptation is a new QenTerra component file with derivation provenance, semantic tokens, tests, delivery registration, versioning, and changelog coverage.

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
