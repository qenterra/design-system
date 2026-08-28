# Building and verification

## Requirements

- macOS with full Xcode and Swift Package Manager;
- Python 3;
- Node.js 22 and npm;
- Git LFS;
- Pillow and NumPy for Nyx profile checks.

Install local dependencies:

```sh
npm ci --ignore-scripts
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements-visual.txt
```

Generate adapters and the release manifest after changing canonical tokens or registries:

```sh
python3 scripts/generate.py write
python3 scripts/build_public_packages.py write
```

Run the complete gate:

```sh
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" \
DESIGN_SYSTEM_IMAGE_PYTHON=.venv/bin/python \
python3 scripts/verify.py
```

Generated public adapters and private Figma handoff files are outputs. Edit their canonical token/registry inputs, then regenerate. The verifier does not create a viewing website or screenshot baseline.
