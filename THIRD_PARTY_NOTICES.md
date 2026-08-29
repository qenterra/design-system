# Third-party notices

The private canonical repository does not redistribute a runtime application. Its public npm and Swift products declare no third-party runtime dependencies and bundle no third-party assets.

Development and verification use Python, Node.js, npm, Swift, full Xcode, Git LFS, Pillow `12.2.0`, and NumPy `2.3.5`. These tools are obtained independently and are not copied into the public package projection. Exact Python versions are pinned in `requirements-visual.txt`; npm resolution is recorded in `package-lock.json`; workflow actions are pinned by commit in `.github/workflows/`.

If a future package bundles or redistributes third-party code, data, fonts, or media, add its exact version, source, SPDX identifier, and required notices here before release. Tool availability is not a license audit of a shipped artifact, so release review inspects the exported tree separately.
