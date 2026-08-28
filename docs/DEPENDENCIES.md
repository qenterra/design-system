# Dependencies

The private repository keeps its dependency surface intentionally small.

| Dependency | Purpose | Authority |
| --- | --- | --- |
| Full Xcode toolchain | Build and test Swift packages | selected `DEVELOPER_DIR` |
| Node.js 22 and npm | Inspect and smoke-test the npm package | `.nvmrc`, `package-lock.json` |
| Python 3 | Generation, schema checks, audits, and orchestration | repository scripts |
| Pillow and NumPy | Nyx wallpaper and focused image checks | `requirements-visual.txt` |
| Git LFS | Retained Nyx PNG storage and verification | `.gitattributes`, asset manifest |

Public npm and Swift packages are dependency-free foundations. Their manifests, exact files, and versions are governed by `registry/packages.json` and `packages/release-manifest.json`.

Lockfiles prove resolution metadata, not license compatibility, runtime quality, or consumer acceptance. Review dependency changes explicitly and keep credentials outside manifests, logs, and source control.
