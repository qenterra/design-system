# Troubleshooting

## Git LFS files appear as pointer text

Install Git LFS, then fetch the repository objects:

```sh
git lfs install
git lfs pull
python3 scripts/brand/validate_brand_assets.py --check-git-lfs
```

Do not replace pointer files manually or remove LFS rules to make a local check
quiet.

## Playwright or Chromium is missing

Install locked JavaScript dependencies and the required browser:

```sh
npm ci
npx playwright install chromium
```

Then run the full verifier again. A syntax-only JavaScript pass is not browser
evidence.

## Pillow or NumPy cannot be imported

Use the isolated image environment:

```sh
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements-visual.txt
QDS_IMAGE_PYTHON=.venv/bin/python python3 scripts/verify.py
```

## Screenshot comparison differs

Confirm the selected renderer profile and inspect `output/tmp/` at full size.
Do not update baselines until the source change and every changed pixel are
understood. Platform font differences require a declared profile; silently
falling back to another machine's baseline is prohibited.

## Swift package authentication fails

Confirm that the developer or CI identity has read access to the private
`qenterra/design-system-swift` repository. Keep credentials out of
`Package.swift`, source control, logs, and package mirrors. Test the exact tagged
version in a clean consumer before blaming SwiftPM's mood swings.

## Generated files drift

Edit the maintained token, registry, schema, source, or documentation input,
then run:

```sh
python3 scripts/build.py
python3 scripts/verify.py
```

Do not patch rendered HTML or generated adapters directly.

## Reporting a problem

Follow [CONTRIBUTING.md](../CONTRIBUTING.md). Replace accounts, content,
filenames, paths, credentials, and logs with synthetic values. Report security
issues privately through [SECURITY.md](../SECURITY.md).
