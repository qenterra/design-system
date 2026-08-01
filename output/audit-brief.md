# Cadence, Unspool, and Lilt — current-state UX/UI audit

Evidence snapshot: local repositories on 2026-08-01.

- Cadence: `3d96b5a`; current production-backed screenshots exist, but the screenshot root omits production tint.
- Unspool: `54b29f1`; current source is newer than published product screenshots.
- Lilt: `3d0ca81`; current rendered screenshots do not exist, and old output represents superseded concepts.

The audit combines current SwiftUI source, token files, specifications, documentation, screenshot evidence, and independent fresh-eyes review. It does not claim live native rendering, VoiceOver, network, audio, Telegram, permission, or real-device acceptance.

## Executive verdict

No application is a complete family reference alone.

- Cadence is the strongest visual and content-composition donor.
- Unspool is the strongest operational workflow and token-discipline donor.
- Lilt is the strongest state, motion, privacy, and localization donor.

The approved family core is Cadence visual identity + Unspool component/workflow discipline + Lilt state/motion/copy architecture.

## Comparative assessment

| Area | Cadence | Unspool | Lilt |
| --- | ---: | ---: | ---: |
| Visual identity | 5 | 4 | 4 |
| Adaptive appearance | 5 | 5 | 1 |
| Layout-token discipline | 2 | 5 | 2 |
| Typography system | 4 | 5 | 2 |
| Primary workflow | 4 | 5 | 4 |
| State and recovery | 4 | 5 | 5 |
| Motion | 2 | 4 | 5 |
| Microcopy | 3 | 4 | 5 |
| Localization | 1 | 2 | 5 |
| Keyboard/accessibility | 3 | 4 | 3 |
| Documentation currency | 3 | 2 | 2 |

Scores are relative evidence summaries, not absolute product ratings.

## Cross-product inconsistencies

### Appearance

- Cadence implements adaptive custom Soft Graphite with System/Light/Dark.
- Unspool implements adaptive system-semantic surfaces with System/Light/Dark.
- Lilt hard-forces Dark on all major surfaces.

Decision: keep Cadence's identifiable graphite values, use Unspool's semantic/adaptive implementation discipline, and remove Lilt's forced appearance.

### Navigation

- Cadence code starts collapsed although its approved spec requires expanded for new installations.
- Unspool code starts expanded although its approved spec requires a compact rail.
- Lilt uses a labeled Settings sidebar and should not inherit an application rail.

Decision: share navigation states and behavior, not a universal width or default.

### Typography

- Cadence uses semantic system styles but retains local display exceptions.
- Unspool has the clearest compact role scale.
- Lilt uses many 10.5–11.5 point local values and low-emphasis metadata.

Decision: shared semantic roles, system/dynamic platform mapping, no half-point sizes, and explicit minimum supporting text.

### Motion

- Cadence has good timings but they are feature-local.
- Unspool centralizes 80/100/150 ms utility motion.
- Lilt defines semantic motion events and accessibility fallbacks.

Decision: use Lilt's event architecture, Unspool's restraint, and preserve product-specific continuous physical motion only when measured.

### Localization and copy

- Cadence has no String Catalog and hundreds of direct literals.
- Unspool has a partial catalog but still many direct literals.
- Lilt has a comprehensive catalog and almost no direct UI strings.

Decision: String Catalog or platform i18n is mandatory, with typed/generated keys, plural rules, locale-aware formatting, and no generic recovery copy.

### Screenshot governance

- Cadence screenshots are current in structure but use the wrong tint path.
- Unspool screenshots are older than the current UI.
- Lilt screenshots are old concepts and cannot represent the current product.

Decision: every product needs a current privacy-safe fixture matrix across appearances, widths, states, and accessibility modes.

## Cadence

### Strengths

- Strong adaptive Soft Graphite palette and clear surface hierarchy.
- Mature three-pane Library, Track Table, Now Playing, Queue, and persistent player.
- Import uses a trustworthy Scan → Review → Import → Complete/Recover flow.
- Native macOS controls, toolbar search, menus, sheets, popovers, keyboard shortcuts, and Finder recovery.
- Guide is skippable, repeatable, honest, and does not perform automatic data actions.

### Major findings

- Smart Collections promise `Save` but definitions are not durable between launches. This is a trust defect.
- Screenshot harness bypasses production tint and shows system blue.
- New installations receive icon-only navigation, and Library/Playlists share one symbol.
- Shared row states exist but multiple screens manually suppress hover/focus.
- Radius, motion, typography exceptions, and layout constraints are scattered.
- User-facing strings are hardcoded without a String Catalog.
- Album and Artist surfaces remain less playback-first than the product direction requires.
- Import Review may clip at minimum width and requires live verification.

### Family disposition

Keep: palette, Library, tables, import review, player, Now Playing, queue, Guide, Trash recovery.

Adapt: rail, settings containers, buttons, row states, page headers, search, state components, localization.

Replace: non-durable save promise, duplicate symbols, scattered values, hardcoded copy, manual state suppression, screenshot root.

Product-specific: artwork haze, playback transport, audio path, lyrics, music metadata, queue semantics.

## Unspool

### Strengths

- Best continuous primary flow: Chat → Range → Filters → Selection → Destination → Preflight → Download → Recovery.
- Count, size, destination, conflict policy, and cancellation consequences remain visible.
- Filename-first file table is dense and scannable.
- Safe default `Skip`, explicit `Replace` and `Save a Copy`.
- Strong lifecycle coverage for scanning, partial data, offline, downloads, interruptions, history, and export.
- Best existing spacing, radius, type, button, focus, and motion token foundation.
- Privacy-safe synthetic fixtures are isolated from real Telegram data.

### Major findings

- Current screenshots are stale relative to source.
- Expanded rail contradicts the approved compact rail and reduces dense workspace width.
- Critical category filters disappear into an indicator-free horizontal scroll.
- Setup shows validation guidance on untouched empty fields.
- Some Settings toggles are created without their own accessible label.
- Interrupted session can be discarded without confirmation.
- Typed issues collapse back into a single global string banner.
- History failures lack consistent recovery actions.
- String Catalog coverage and plural rules are incomplete.

### Family disposition

Keep: token discipline, file table, selection summary, preflight, conflict resolver, filename hierarchy, operation history, fixtures, Quick Look/Finder.

Adapt: responsive rail, toolbar, buttons, Settings Row, issue placement, localization, semantic palette mapping.

Replace: invisible overflow, pristine errors, unnamed toggles, unconfirmed discard, global string errors, stale screenshots.

Product-specific: Telegram chats, ranges, sender filters, attachment taxonomy, filename contract, queue and conflict vocabulary.

## Lilt

### Strengths

- Best distinction among Ready, Recording, Transcribing, Inserted, and Copied outcomes.
- Real RMS/peak signals and no fabricated partial capability.
- Best semantic motion model with Reduced Motion fallbacks.
- Best localization architecture and privacy-specific microcopy.
- Strong HUD, Quick History, keycaps, model lifecycle, and diagnostics preview-before-export.
- Correct menu-bar utility mental model and local/offline product framing.

### Blockers and major findings

- Menu-panel `Insert` bypasses target-app preservation/restoration and can act in the wrong context or fall back unexpectedly.
- Trial Dictation is not isolated; it can use ordinary insertion and history behavior despite the onboarding promise.
- Every major surface forces Dark appearance.
- Typography uses many small half-point sizes and low-emphasis tertiary text.
- HUD maps unrelated failures to generic `Lilt needs help` and `Configure`.
- Optional Accessibility is presented as one of three required onboarding actions.
- Some interactive cards look clickable while only a nested button acts.
- Settings arrow navigation promised by documentation is absent.
- Current visual sources and multiple specs are stale or contradictory.
- Icon Composer source exists but is not wired into the current target/bundle.

### Family disposition

Keep: state vocabulary, motion, localization, privacy copy, HUD, Quick History, keycaps, real-signal-only behavior, diagnostics preview.

Adapt: adaptive palette, typography, settings groups, buttons, onboarding semantics, model cards, status colors.

Replace: forced Dark, generic recovery, broken target restoration, fake trial, raw local values, stale sources, unwired icon pipeline.

Product-specific: recording red, signal bars, timer, hold/release, models, clipboard/insertion distinction, menu-bar shell.

## System-level priorities

1. Fix trust and context blockers before visual migration: Cadence persistence language, Lilt insertion target, Lilt trial isolation.
2. Establish semantic tokens and generated adapters.
3. Centralize mandatory interactive states.
4. Make appearance adaptive across all products.
5. Standardize issue scope and recovery.
6. Move all strings to localization sources.
7. Rebuild current screenshot harnesses.
8. Migrate product surfaces in independently verifiable slices.

## Explicit live gaps

- Current Lilt render, multi-display placement, pointer interception, permissions, insertion, model lifecycle, and VoiceOver.
- Current Unspool rendered minimum/wide layout, Telegram login/data/network/disk/conflict behavior, and VoiceOver.
- Cadence production tint, minimum-width Import Review, drag/drop, playback/listening, route changes, and VoiceOver.
- All products under live Reduced Motion, Reduced Transparency, Increased Contrast, long localization, and keyboard-only end-to-end use.
