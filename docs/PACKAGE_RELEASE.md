# Package release

## Registry contract

- npm registry: `@qenterra/design-tokens`, Node.js 22 for verification, metadata in `packages/npm/design-tokens/package.json`.
- Swift Package Manager: repository `https://github.com/QenTerra/design-system`, products `QenTerraDesignTokens` and `QenTerraComponents`, Swift tools 5.9, macOS 13+, and iOS 16+.
- Owner: Nikita Melnychenko (`@qenterra`). Publication credentials exist only in the protected release workflow and are never stored in source.
- Provenance: `registry/packages.json` is the export allowlist; safe public token and icon inputs plus `packages/scripts/generate.py` reproduce all declared outputs; `packages/release-manifest.json` then records every public file, byte size, and SHA-256 digest.

## Gate

- Verify version, package manifest, lockfiles, public API, generated documentation, examples, license, notices, and consumer migration.
- Build and test the package from a clean checkout at the exact tag.
- Inspect the archive contents before publication.
- Publish with least-privilege credentials and verify the registry digest and metadata afterward.

Package publication is separate from GitHub Release publication and requires its own authority.

## Procedure

1. Update `VERSION`, registry versions, npm and Swift metadata, generated adapters, and `CHANGELOG.md` together.
2. Run `python3 scripts/generate.py write` and `python3 scripts/build_public_packages.py write`.
3. Run `python3 scripts/verify.py` from a clean checkout and export to an empty system temporary directory.
4. Run `python3 scripts/verify_release.py` inside the exported tree; confirm it regenerates and byte-compares npm and Swift outputs before manifest closure, then inspect `npm pack --dry-run --json` plus Swift tests.
5. Publish a new immutable version through `.github/workflows/release-packages.yml`; verify the remote tag, repository commit, npm integrity, and metadata after publication.
