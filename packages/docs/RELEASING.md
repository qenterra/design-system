# Releasing

## Authority and source

- Release owner: Nikita Melnychenko (QenTerra)
- Version scheme: Semantic Versioning
- Version source: `release-manifest.json`
- Current version: `1.0.1`
- Tag format: `v<version>`

The maintained package line starts at `1.0.0`. npmjs retains immutable historical `@qenterra/design-tokens@5.0.0` from the retired Packages repository; release verification must treat it as registry history rather than the predecessor of the new `1.x` line.

The public tree is generated from the canonical Design System release and must not be assembled by copying an arbitrary working directory.

## Prepare

- Confirm the exact clean source commit and complete package snapshot.
- Align package metadata, manifest version, changelog, support table, migrations, and deprecations.
- Regenerate every declared npm and Swift output from the public inputs, then run the release verifier, governance audit, Swift tests, and npm archive inspection with all temporary state outside the checkout.
- Inspect license, notices, dependency inventory, workflow permissions, and generated-artifact provenance.

## Publish

1. Update `main` with the verified projection using an ordinary fast-forward.
2. Create an annotated `v<version>` tag at that exact commit.
3. Publish the npm package only when its version is absent; if present, verify integrity instead of replacing it.
4. Create a GitHub Release only when separately authorised and include exact notes and checksums for any assets.

## Verify and recover

Read back the remote branch, tag target, release target, npm version, npm integrity, and provider metadata. If any target differs, stop propagation and preserve evidence. Fix canonical source and publish a new version; never rewrite a released tag or package.
