# Building from source

## Requirements

- Git with Git LFS
- Node.js matching `.nvmrc` and npm with lockfile support
- Python 3 with `venv`
- Swift 5.9 or newer with the supported macOS/iOS SDKs
- A Chromium runtime installed by Playwright

The repository is private. A clean checkout requires authorized GitHub access
and Git LFS object access.

## Clean-checkout setup

```sh
git lfs install
git lfs pull
npm ci
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements-visual.txt
npx playwright install chromium
```

Do not commit `.venv`, package caches, Swift build state, browser captures from
ad hoc runs, or machine-specific paths.

## Build the reference

```sh
python3 scripts/build.py
```

Generated output is written to `dist/`, `generated/`, and the generated parts of
`packages/`. Serve the static site locally:

```sh
python3 -m http.server 8000 --directory dist
```

## Verify

The canonical gate is:

```sh
DEVELOPER_DIR="$(xcode-select --print-path)" \
QDS_IMAGE_PYTHON=.venv/bin/python \
python3 scripts/verify.py
```

The gate fails when a required browser, image, package, asset, build, test, or
exact screenshot stage cannot run. After it passes, inspect the affected English
and Russian pages, Light and Dark appearance, desktop and constrained layouts,
and the relevant screenshots at full size.

Swift package tests use the `TestingMacros` plugin and therefore require the
full Xcode developer directory, not Command Line Tools alone. Confirm that
`xcode-select --print-path` ends in `Xcode.app/Contents/Developer`; otherwise
set `DEVELOPER_DIR` to the installed Xcode path for the command above.

## Source boundaries

Change maintained files in `tokens/`, `registry/`, `schemas/`, `src/`, `docs/`,
`templates/`, package manifests, and the hand-authored Swift facade. Do not edit
generated adapters or rendered HTML directly. See [Maintenance](MAINTENANCE.md)
for versioning, localization parity, package release, and brand-asset workflows.
