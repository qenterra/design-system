# Contributing

Focused bug fixes, tests, documentation corrections, and well-scoped improvements are welcome.

## Before opening an issue

1. Search existing issues and documentation.
2. Reproduce the problem on a supported version.
3. Remove credentials, personal paths, private data, copyrighted fixtures, and unrelated logs.
4. Use the issue form that matches the request. Report vulnerabilities through `SECURITY.md`, never a public issue.

## Development setup

```sh
git clone https://github.com/QenTerra/packages.git
cd packages
python3 scripts/verify_release.py
```

Requirements: Swift 5.9 or later for native packages and Node.js 22 or later for npm package verification.

## Required checks

```sh
python3 scripts/verify_release.py
python3 scripts/qenterra_repository_check.py audit --root . --format markdown
npm pack --workspace @qenterra/design-tokens --dry-run --json --cache /tmp/qenterra-packages-npm
swift test --scratch-path /tmp/qenterra-packages-swift --disable-sandbox
git diff --check
```

State any hardware, accessibility, performance, security, deployment, or provider behaviour these checks do not prove.

Create every cache, build tree, report, or package-staging directory outside the checkout. The repository audit inspects tracked, untracked, and ignored files, so hiding machine output in `.gitignore` does not make it acceptable.

## Branches and commits

- Create `qenterra/<short-kebab-purpose>` from the current `main`.
- Use Conventional Commit subjects with an allowed type and optional lowercase scope.
- Keep one coherent outcome per commit and pull request.
- Remove fixup, squash, WIP, and checkpoint commits before review.

## Pull requests

- Explain purpose, scope, verification, risk, migration, documentation, privacy/security, and release impact.
- Add a regression test when behaviour can be checked deterministically.
- Include screenshots or recordings for visible changes and identify the exact build and fixture.
- Update public documentation and changelog when users, consumers, or operators are affected.
- Do not add caches, build output, credentials, signing material, personal data, AI or agent operating files, skills, MCP configuration, private planning, or unreviewed artifacts anywhere in the public checkout.

By contributing, you agree that your contribution is licensed under the repository’s declared Apache-2.0 terms.
