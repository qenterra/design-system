# Public dependency delivery

The canonical Design System repository is private. Only the deterministic contents of `packages/` may be released to `https://github.com/qenterra/packages`.

## Public contents

The release manifest allowlists package manifests, safe public generation inputs, the portable generator, generated npm and Swift outputs, the exact Explore SwiftUI, shadcn/ui, Magic UI, UIable, and ReUI reference catalogs, public tests, README, CI, license, and notices. Every file has a SHA-256 digest. The exported verifier regenerates declared outputs outside the checkout and independently closes all source catalogs before it checks release digests; a changed artifact and matching edited hash do not pass. A path absent from the manifest does not ship.

Explore SwiftUI originals are published under direct permission, stored byte-for-byte from the detail-page source field, and excluded from SwiftPM targets. They are never tokenized or edited in place. An adaptation is a new QenTerra component file with derivation provenance, semantic tokens, tests, delivery registration, versioning, and changelog coverage.

shadcn/ui originals are stored byte-for-byte from every official upstream `registry:ui` base at one pinned public commit, retain the exact upstream MIT license and shadcn copyright notice, and are excluded from package targets. They are never tokenized or edited in place. The catalog intentionally excludes the upstream site, CLI, tests, examples, blocks, generated styles, and internal application code.

Magic UI originals are stored byte-for-byte for every entry on the official public Components page at one pinned public commit. Each `.tsx` source is paired with its exact shadcn-compatible registry payload so required dependencies, CSS variables, and keyframes are not silently lost. The catalog retains the exact upstream MIT license and `Copyright (c) Magic UI`, remains outside package targets, and excludes templates, demos, documentation prose, site internals, and registry sources not listed on the public page.

UIable originals are stored byte-for-byte for the complete official `registry:ui` union of showcase components and required UI primitives at one pinned public commit. Every source is paired with its exact public registry payload; the catalog retains the exact upstream MIT license and `Copyright (c) 2026 CodedThemes`, remains outside package targets, and excludes every `registry:block` item, the website, documentation application, previews, media, and build tooling.

ReUI originals are stored byte-for-byte for the complete free union declared by the Base UI Nova and Radix UI Nova live indexes: every `c-*` example, public primitive, and hook. Unchanged published payloads use one pinned official Git commit; newer or changed payloads use the immutable live deployment shared by the index hashes. The catalog retains the exact upstream MIT license and `Copyright (c) 2025 Keenthemes Inc`, remains outside package targets, and excludes every ReUI Pro block, paid icon, template, website or docs implementation file, media asset, and build tool.

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
