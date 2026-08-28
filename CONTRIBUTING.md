# Contributing

Design System accepts contributions from authorized QenTerra
collaborators. The repository is private and proprietary.

## Before opening an issue

- Search existing issues and the changelog.
- Reproduce the problem on the current `main` branch or latest package release.
- Include relevant operating-system, browser, Swift, Node.js, Python, and
  package-manager versions.
- Replace accounts, filenames, paths, product content, credentials, and logs
  with synthetic values.
- Report vulnerabilities through the private route in [SECURITY.md](SECURITY.md).

## Local setup

Follow [Building from source](docs/BUILDING.md):

```sh
npm ci
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements-visual.txt
DESIGN_SYSTEM_IMAGE_PYTHON=.venv/bin/python python3 scripts/verify.py
```

## Source-of-truth rules

- `tokens/*.json`, focused registries and schemas, and the bilingual normative
  documents define the system.
- Generated files under `generated/` and `packages/` package adapters
  are outputs; change their maintained inputs instead.
- English and Russian normative references stay structurally aligned and
  semantically complete.
- Product-specific exceptions belong in product profiles, not foundation
  tokens.
- AI plans, handoffs, scratch notes, reports, and intermediates belong in a
  unique system temporary directory, never in the repository.
- Repository-authored code, UI copy, documentation, tests, and commits are
  English.

## Required checks

```sh
DESIGN_SYSTEM_IMAGE_PYTHON=.venv/bin/python python3 scripts/verify.py
git diff --check
```

Automated checks cover generation, schemas, unit and negative tests, public
package boundaries, npm contents, Swift build/tests, and Nyx asset manifests.
Native rendering, VoiceOver, real consumer migration,
live service boundaries, and other relevant platform acceptance remain explicit
manual gaps.

## Pull requests

- Keep one coherent problem per pull request.
- Add regression coverage for behavior changes.
- Include before and after screenshots for visible interface changes.
- Update both reference languages and generated output when normative content
  changes.
- Explain risks, automated checks, live checks, and remaining manual gaps.
- Keep unrelated formatting and generated churn out of the patch.

By contributing, you agree that your contribution may be used under this
repository's [proprietary license](LICENSE).
