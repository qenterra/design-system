# Development

## Source boundary

This directory is the package-release boundary within the public Design System repository. Package changes originate from canonical tokens, registries, schemas, and generators, then arrive here as one reviewed, manifest-complete snapshot. The portable source under `npm/design-tokens/src/` reproduces the npm distribution and generated Swift adapters. Do not hand-edit those outputs or patch only their manifest hashes.

External contributors can open an issue or focused pull request with a reproducible defect, test, or documentation correction. Maintainers update canonical source and package outputs together before release.

## Local verification

No dependency installation is required:

```sh
python3 scripts/generate.py check
python3 scripts/verify_release.py
python3 scripts/qenterra_repository_check.py audit --root . --format markdown
```

For package checks, create unique temporary directories outside the checkout:

```sh
npm pack --workspace @qenterra/design-tokens --dry-run --json --cache /tmp/qenterra-packages-npm
swift test --scratch-path /tmp/qenterra-packages-swift --disable-sandbox
```

## Change rules

- Change public token, icon, or recipe inputs first; run `python3 scripts/generate.py write`, review every output, then rebuild the manifest from the canonical projection.
- Keep maintained source, generated output, tests, manifests, docs, version, and changelog coherent.
- Use synthetic deterministic fixtures and redact personal or production data.
- Do not add credentials, caches, build output, local paths, private operational records, or internal history.
- Record automated, live, and manual evidence separately.

## Review

Review API compatibility, accessibility, localization, generated drift, package contents, release-manifest closure, licensing, and consumer migration. A local green check does not prove registry publication, an application integration, native rendering, or assistive-technology behavior.
