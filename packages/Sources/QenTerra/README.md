# QenTerra Swift sources

`DesignTokens/` is the implementation of the `QenTerraDesignTokens` SwiftPM product. `Components/` is the implementation of `QenTerraComponents`. `MediaComponents/` contains the macOS-only reusable media presentation product, including artwork states, placeholders, crop geometry, mosaics, and ready-palette haze. Product and module names stay stable even though the source tree is grouped under the `QenTerra` namespace.

Every reusable component lives in its own Swift file and uses semantic Design System tokens for owned visual decisions. `manifest.json` records public symbols, source paths, token-adoption state, delivery product, byte counts, and SHA-256 hashes. Media presentation accepts ready values and view-builder content; loading, decoding, persistence, gestures, and feature actions remain in consumers.

When an Explore SwiftUI example inspires a QenTerra component, copy it into `Components/` before changing it. Never edit the preserved original. The QenTerra registry and generated manifest record the source component and original hash so later work can distinguish an exact reference from an adapted, supported component.
