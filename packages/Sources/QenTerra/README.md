# QenTerra Swift sources

`DesignTokens/` is the implementation of the `QenTerraDesignTokens` SwiftPM product. `Components/` is the implementation of `QenTerraComponents`. Product and module names stay stable even though the source tree is grouped under the `QenTerra` namespace.

Every reusable component lives in its own Swift file and uses semantic Design System tokens for owned visual decisions. Current components are `PrimaryButtonStyle`, `GroupContainer`, and `InteractiveRowSurface`; `manifest.json` records their public symbols, source paths, token-adoption state, byte counts, and SHA-256 hashes.

When an Explore SwiftUI example inspires a QenTerra component, copy it into `Components/` before changing it. Never edit the preserved original. The QenTerra registry and generated manifest record the source component and original hash so later work can distinguish an exact reference from an adapted, supported component.
