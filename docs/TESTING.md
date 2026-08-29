# Testing

## Complete gate

```sh
python3 scripts/verify.py
```

The command compiles Python into an external bytecode cache; checks deterministic generation, the public projection, terminology, schemas, consumer and release contracts, asset manifests, wallpaper inputs, Swift packages, npm contents, and Git whitespace; and runs the Python and JavaScript test suites.

## Test layers

| Layer | Purpose | Command | Evidence limit |
| --- | --- | --- | --- |
| Unit | Python generators, schemas, registries, terminology, and negative contracts | `python3 -m unittest discover -s tests -v` | Does not prove a consuming app or platform renderer |
| Integration | Public projection, Swift packages, npm payload, consumer and release contracts | `python3 scripts/verify.py` | Does not prove a published registry or real product integration |
| Clean export | Exact allowlist and release-manifest closure | `python3 scripts/build_public_packages.py export --destination <empty-external-directory>` then exported `python3 scripts/verify_release.py` | Proves only the exported file set and declared local checks |
| Manual | Native rendering, VoiceOver, keyboard behavior, visual quality, and consumer migration | Project-specific acceptance checklist | Requires current human, device, or application evidence |

## Fixtures

Use synthetic, deterministic fixtures. Do not read personal data, live user libraries, production credentials, or mutable external resources unless a separately authorised acceptance test requires them.

## Failures and flaky tests

Reproduce before repair, preserve the failing evidence, identify whether the environment or product failed, and never weaken assertions to make a gate green.
