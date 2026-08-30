# Testing

## Required checks

```sh
python3 scripts/generate.py check
python3 scripts/verify_source_catalogs.py
python3 scripts/verify_release.py
python3 scripts/qenterra_repository_check.py audit --root . --format markdown
```

Run package checks with external temporary paths:

```sh
npm pack --workspace @qenterra/design-tokens --dry-run --json --cache /tmp/qenterra-packages-npm
swift test --scratch-path /tmp/qenterra-packages-swift --disable-sandbox
```

## Test layers

| Layer | Purpose | Evidence limit |
| --- | --- | --- |
| Deterministic regeneration | Rebuilds six npm and Swift outputs in an external temporary directory and byte-compares them | Proves consistency with versioned public inputs, not private-source parity |
| Release manifest | Exact file, size, and SHA-256 closure after regeneration | The manifest is editable metadata, not an independent source of truth |
| Repository governance | Documentation, naming, legal identity, workflow, hygiene, and artifact provenance | Does not prove live GitHub settings |
| Swift tests | Typed values and component behavior in the package test host | Does not prove a consuming app, VoiceOver, or rendered visual quality |
| npm archive inspection | Exact files that npm would publish | Does not prove registry publication or browser integration |
| Manual consumer acceptance | Native/browser rendering, accessibility, localization, and migration | Requires current product-specific evidence |

## Fixtures and failures

Use synthetic deterministic fixtures. Never read personal data, user libraries, production credentials, or mutable live services for a normal package gate. Reproduce a failure before repair; do not remove assertions, allowlist a cache, or register private material merely to make the gate pass.
