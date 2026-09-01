# Third-party notices

The repository does not redistribute a runtime application. Its npm and Swift products declare no third-party runtime dependencies and bundle no third-party assets. The source-reference catalogs under `packages/Sources/` retain their own ownership and license terms as documented in `packages/THIRD_PARTY_NOTICES.md`.

Development and verification use Python, Node.js, npm, Swift, full Xcode, Git LFS, Pillow `12.3.0`, and NumPy `2.3.5`. These tools are obtained independently and are not copied into package payloads. Exact Python versions are pinned in `requirements-visual.txt`; npm resolution is recorded in `package-lock.json`; workflow actions are pinned by commit in `.github/workflows/`.

If a future package bundles or redistributes third-party code, data, fonts, or media, add its exact version, source, SPDX identifier, and required notices here before release. Tool availability is not a license audit of a shipped artifact, so release review inspects the exported tree separately.
