# Troubleshooting

## Git LFS files appear as pointer text

```sh
git lfs install
git lfs pull
python3 scripts/brand/validate_brand_assets.py --check-git-lfs
```

Do not replace pointers manually or weaken `.gitattributes`.

## Pillow or NumPy is unavailable

```sh
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements-visual.txt
DESIGN_SYSTEM_IMAGE_PYTHON=.venv/bin/python python3 scripts/verify.py
```

## Swift testing macros are unavailable

Select a full Xcode installation, not Command Line Tools alone:

```sh
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" python3 scripts/verify.py
```

## Generated files drift

Edit canonical tokens or registries, then run:

```sh
python3 scripts/generate.py write
python3 scripts/build_public_packages.py write
python3 scripts/verify.py
```

## Public boundary fails

Inspect `registry/packages.json` and `packages/release-manifest.json`. Remove undeclared or repository-only material, or register a legitimate package file. Never register brand assets, consumer manifests, secrets, or unrelated commit IDs merely to silence the gate.

## Package installation fails

Confirm `@qenterra/design-tokens` exists at the requested npm version and `https://github.com/qenterra/design-system` has the requested `v<version>` tag. Reproduce in a clean temporary consumer before changing package metadata.
