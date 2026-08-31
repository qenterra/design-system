# Dependencies

The repository keeps its dependency surface intentionally small.

| Dependency | Purpose | Authority |
| --- | --- | --- |
| Full Xcode toolchain | Build and test Swift packages | selected `DEVELOPER_DIR` |
| Node.js 22 and npm | Inspect and smoke-test the npm package | `.nvmrc`, `package-lock.json` |
| Python 3 | Generation, schema checks, audits, and orchestration | repository scripts |
| Pillow and NumPy | Nyx wallpaper and focused image checks | `requirements-visual.txt` |
| Git LFS | Retained Nyx PNG storage and verification | `.gitattributes`, asset manifest |

Public npm and Swift packages are dependency-free foundations. Their manifests, exact files, and versions are governed by `registry/packages.json` and `packages/release-manifest.json`.

The shadcn/ui catalog is vendored reference source, not an installed runtime dependency. Its component files retain the upstream MIT license, public commit provenance, and exact hashes. Consumers choose and install the dependencies required by a selected component through the official shadcn workflow; the Design System does not pretend that copying an entire source catalog creates a configured React application.

The Magic UI catalog is also vendored reference source rather than a runtime dependency. Its manifest pairs every public-page `.tsx` component with the exact official registry payload that declares dependencies, registry dependencies, CSS variables, and keyframes. Consumers install only selected components through the official Magic UI/shadcn workflow and remain responsible for React, Tailwind CSS, Motion, aliases, and framework integration.

The UIable catalog is vendored reference source rather than a runtime dependency. It preserves the complete official `registry:ui` union from UIable's showcase-component and primitive registries, together with the exact public install payload for every item. Consumers select only the sources they need and remain responsible for React, Tailwind CSS, aliases, registry dependencies, and application integration. The catalog deliberately excludes `registry:block` entries and does not convert upstream code to QenTerra tokens in place.

The ReUI catalog is vendored reference source rather than a runtime dependency. It preserves the complete free live registry for Base UI Nova and Radix UI Nova, including exact source and install payloads. Consumers select one base and only the items they need, then satisfy the dependencies, registry dependencies, aliases, CSS variables, Tailwind configuration, and framework integration declared by those payloads. ReUI Pro blocks, paid icons, and templates are deliberately excluded, and originals are never converted to QenTerra tokens in place.

Lockfiles prove resolution metadata, not license compatibility, runtime quality, or consumer acceptance. Review dependency changes explicitly and keep credentials outside manifests, logs, and source control.
