# Package release

## Registry contract

- npm: `@qenterra/design-tokens`, public access, metadata in `npm/design-tokens/package.json`.
- Swift Package Manager: `https://github.com/QenTerra/packages`, products `QenTerraDesignTokens` and `QenTerraComponents`, metadata in `Package.swift`.
- Version authority: `release-manifest.json`; all package versions and the `v<version>` tag match it.
- Release owner: Nikita Melnychenko (`@qenterra`). Credentials exist only in protected provider settings and never in the repository.

## Gate

1. Run `python3 scripts/generate.py check`; the release verifier repeats regeneration in an external temporary directory and byte-compares all declared outputs.
2. Verify every file, byte size, and SHA-256 value with `python3 scripts/verify_release.py`; never accept a changed output merely because its manifest hash also changed.
3. Run the repository-governance audit against the complete working tree.
4. Run Swift tests with an external scratch path.
5. Inspect `npm pack --dry-run --json` using an external npm cache.
6. Confirm license, NOTICE, changelog, supported versions, deprecations, and migration notes.
7. Publish only from the exact verified tag, then read back the remote branch, tag, package version, metadata, and npm integrity.

GitHub repository update, Git tag, GitHub Release, and npm publication are separate operations. Existing versions are immutable; a correction receives a new version.
