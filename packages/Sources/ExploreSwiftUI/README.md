# Explore SwiftUI source catalog

This directory preserves the exact Swift source text published on every component detail page in the [Explore SwiftUI](https://exploreswiftui.com/) sitemap. Each example is stored in its own file under `Components/<Category>/`; `manifest.json` records its page URL, Apple documentation link, publication and update dates, tags, platform minimums, byte count, and SHA-256 hash.

QenTerra has permission from the resource owner to publish these examples in this repository. The source is attributed to Explore SwiftUI and remains subject to the rights and terms of its original owner; it is not presented as QenTerra-authored code or silently relicensed as QenTerra work.

These files are an immutable reference catalog, not a SwiftPM target. Individual examples can require a particular Apple SDK, platform availability, surrounding model types, entitlements, or app setup and are not claimed to compile as one module.

Do not edit files in `Components/` directly. The canonical synchronization command rewrites them from the live source and the offline verifier rejects any byte that differs from `manifest.json`. A QenTerra adaptation starts as a separate copy under `Sources/QenTerra/Components/`; the original remains unchanged and derivation metadata belongs in the QenTerra component manifest.
