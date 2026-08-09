# Changelog

## 1.9.0

### Added

- Added deterministic SwiftUI interactive-row state and surface contracts for hover, focus, selection, disabled, unavailable, and Increased Contrast states.
- Added read-only consumer-doctor findings for Swift numeric colors, corner radii, and animation durations with exact exception support.

### Fixed

- Preserved channel values and alpha when SwiftUI adapters resolve semantic `rgba(...)` colors.
- Validated that both localized normative master headers match `VERSION`.

## 1.8.1

### Fixed

- Made every selected email template visibly and semantically current.
- Preserved filled values shared by the next template and made field clearing deterministic and announced.
- Removed partial automatic dark-mode overrides that made Light-email text unreadable on dark systems.

### Changed

- Added an email-language control independent from the reference-site language.
- Reworked all localized message openings into one greeting followed by outcome/action content, removing title-to-paragraph repetition.

## 1.8.0

### Added

- Human-operated English/Russian catalogue of 48 correspondence, support, account, operation, and payment email scenarios.
- Email-safe table renderer with inline styles, plain-text parity, HTTPS-only actions, escaped values, and explicit contact-channel ownership.
- Local stateless gallery/composer with search, filters, required-field validation, responsive Light/Dark previews, rich/plain/source copy, and clipboard fallback.
- Normative bilingual email guidance, decision record, schema, semantic validation, Node tests, and browser evidence.

### Security

- Email tooling is structurally prohibited from sending messages, persisting entered values, making external requests, or supporting marketing and newsletters.

## 1.7.0

### Added

- Semantic interface-icon registry with focused schema, generated Swift identifiers, site sprite, and CSS-package metadata.
- Deterministic Figma-ready variables, styles, components, and icon payloads with bilingual handoff guidance.
- Searchable temporary brand asset browser with a fail-closed repository-output guard.

## 1.6.0

### Added

- Strict consumer manifest and exception schemas with reusable templates.
- Read-only consumer doctor for source boundaries, declared local adapters, raw colors, and exact exceptions.
- Passing/failing synthetic fixtures, mutation guards, and a bilingual adoption page.

## 1.5.0

### Added

- Machine-readable bilingual component registry with validated state/story contracts.
- Component Lab page with stable story anchors, URL-backed density controls, and pseudo-long/pseudo-RTL modes.
- Browser gates for lab availability, accessible invalid-field wiring, pseudo-localization, and visible focus.
- SwiftUI primary-button and group-container primitives backed by typed tokens.

## 1.4.0

### Added

- Focused token schemas, reference-cycle/type checks, and documented raw component-metric exceptions.
- Typed Swift color, typography, motion, and component APIs while preserving the existing foundation facade.
- CSS component metrics and opt-in button, field, group, and interactive-row recipes.
- Exact screenshot manifest and pixel-comparison gate.
- Canonical `contact@qenterra.com` general channel and `support@qenterra.com` product-support channel with machine-readable roles.

### Fixed

- Standalone reference titles no longer inherit the last rendered repository-section heading.

## 1.3.0

### Added

- Canonical QenTerra logo/banner and Nyx library with 221 manifested assets.
- Git LFS policy and verification for 207 PNG files.
- Complete English/Russian brand governance, asset catalog, Nyx canon, and reusable production templates.
- Brand manifest, Telegram sticker, wallpaper, character-asset, contact-sheet, and local processing tools.

### Changed

- Renamed the local repository directory to `design-system` while preserving the visible system name and standalone artifact names.
- Made the design-system repository the sole reusable authority for brand, Nyx, design, and repository documentation foundations.
- Reconciled outdated wallpaper instructions with the four-file approved collection and recorded the intentional Duotone/Line Art silhouette pair.

## 1.2.0

### Added

- Complete English and Russian repository-documentation standard with stable site anchors.
- Categorized repository README, root-policy, technical-docs, GitHub, and Wiki templates.
- Connectable private local CSS/JSON package and local SwiftPM token package with tests.
- Repository locale-parity, package-drift, and negative validation gates.

### Changed

- Moved the language picker from the sidebar to the upper-right top bar.
- Moved interface work templates under `templates/design/` and made public guidance product-independent.
- Absorbed the former standalone repository-documentation standard into this repository as its sole maintained source.

## 1.1.0

### Added

- Complete English and Russian multipage and standalone references.
- Locale-aware entry page and an accessible language menu that preserves the current page and stable section fragment.
- Standalone scroll-spy navigation with `aria-current="location"`.

### Changed

- Unified navigation, search, menu, and language controls under one inline SVG icon family.
- Extended build output and search indexes for both locales.
- Kept AI working plans and scratch artifacts outside the repository boundary.

### Removed

- Tracked `docs/superpowers/` working files.

## 1.0.0

### Added

- Layered QenTerra family design system.
- Adaptive Soft Graphite foundation and semantic tokens.
- Typography, motion, component, platform, and product-profile tokens.
- AI/developer master reference.
- Multipage static reference and standalone HTML output.
- CSS and Swift token generators.
- Component, screen, pattern, copy, accessibility, screenshot, decision, and migration templates.
- Cross-product audit evidence and migration priorities.
- Build, link, token, contrast, and placeholder validation.
