# Dependencies

## Runtime and distribution

The generated static reference has no backend service dependency. The Swift
package has no external package dependencies. The CSS/JSON package ships
generated tokens, icons, and opt-in recipes without runtime JavaScript.

QDS consumers still depend on their host platform, browser, SwiftUI, or CSS
runtime. Those platform contracts are not vendored by this repository.

## Development dependencies

| Dependency | Purpose | Version source |
| --- | --- | --- |
| Node.js | JavaScript tests and browser tooling | `.nvmrc` |
| Playwright | Chromium interaction and screenshot evidence | `package-lock.json` |
| Python | generation, schemas, tests, and asset tooling | supported local Python 3 |
| Pillow | image inspection and comparison | `requirements-visual.txt` |
| NumPy | image and asset analysis | `requirements-visual.txt` |
| Swift toolchain | package build, contract check, and tests | `Package.swift` minimum plus supported Xcode |
| Git LFS | canonical PNG asset storage and integrity | local Git LFS client |

Use `npm ci` rather than resolving new JavaScript versions during verification.
Install Python image dependencies into a local virtual environment and point
`QDS_IMAGE_PYTHON` to that interpreter.

## Update policy

1. Update the canonical manifest and lockfile together.
2. Review upstream release notes, platform requirements, license, and security
   impact.
3. Run the full verifier, including browser and exact screenshot stages.
4. Inspect generated and lockfile diffs; reject unexpected transitive changes.
5. Update this guide and security or release documentation when boundaries
   change.

Development tools are not automatically licensed for redistribution merely
because they appear in a lockfile. Canonical QenTerra brand assets and the
repository itself remain proprietary under [the repository license](../LICENSE).
