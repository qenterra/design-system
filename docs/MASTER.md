# QenTerra Design System

Version 1.3.0 · Normative reference for humans and AI agents

## 0. How to use this file

This document defines the shared UX/UI grammar for current and future native applications, websites, and browser extensions.

Read in this order:

1. Determine the target platform and product profile.
2. Read the relevant pattern before selecting components.
3. Use semantic tokens from `tokens/*.json`; never copy values from screenshots.
4. Prefer native platform behavior over decorative sameness.
5. Verify every mandatory state, accessibility mode, and content boundary.

For logos, banners, mascot artwork, stickers, wallpapers, or pet animation, also read `docs/brand/MASTER.md`, the relevant brand profile, and `assets/brand/manifest.json`. Brand artwork is canonical content; it does not replace semantic interface tokens.

Normative words:

- **must**: required for compliance;
- **should**: default; deviations need a reason;
- **may**: optional;
- **must not**: prohibited;
- **product-specific**: deliberately outside the shared core.

When this prose and a token file disagree, exact values come from the token file and behavioral meaning comes from this document. Fix the contradiction in the same change.

## 1. Family thesis

QenTerra products share one interface grammar, not one application shell.

The system combines an adaptive Soft Graphite palette and content hierarchy with disciplined dense layouts, review-first flows, preflight, conflict safety, honest state language, short semantic motion, privacy copy, localization, transient surfaces, and explicit recovery.

Family resemblance is visible in:

- color roles;
- typography roles;
- spacing rhythm;
- corner hierarchy;
- button and row states;
- icon treatment;
- motion timing;
- language and error recovery;
- accessibility behavior;
- screenshot and QA evidence.

Family resemblance is not created by copying:

- the same rail width;
- the same Settings placement;
- the same row height for every density;
- the same app-icon metaphor;
- media-player components into utilities;
- menu-bar HUDs into document windows.

## 2. Principles

### 2.1 Content first

Chrome supports the task and does not compete with it. Original artwork and file content may keep color; surrounding UI remains predominantly graphite and monochrome.

### 2.2 Honest state

Show what the system actually knows. Never simulate audio level, progress, completion, connectivity, selection, or persistence.

### 2.3 Direct manipulation with recovery

Actions should operate on visible objects. Risky actions require review, confirmation, Undo, or a recoverable destination according to consequence.

### 2.4 Recognition before recall

Important destinations and actions have visible labels until the user deliberately chooses compact mode or space makes a responsive transformation necessary.

### 2.5 Native before custom

Use platform controls, menus, sheets, navigation, typography, accessibility, and keyboard conventions where they satisfy the contract. A custom control must match native semantics, not merely native appearance.

### 2.6 Calm, not inert

Motion confirms input and explains change. It is brief, interruptible, and absent when it adds no information.

### 2.7 Accessibility is a state, not an appendix

Reduced motion, reduced transparency, increased contrast, keyboard focus, screen readers, text expansion, zoom, and touch/pointer differences are part of the component definition.

### 2.8 One source for changing values

Exact colors, dimensions, durations, and token names live in `tokens/`. Documentation refers to semantic roles. Generated CSS and Swift are never edited directly.

## 3. Foundations

### 3.1 Appearance

All products must support:

- `System` as the default preference;
- `Light` as a complete appearance;
- `Dark` as the signature appearance.

Changing appearance must preserve information hierarchy, status meaning, focus visibility, and content contrast. A Light appearance is not produced by naïvely inverting Dark colors.

### 3.2 Color

The foundation graphite ramp is defined in `tokens/foundation.json`. Semantic application colors are defined per appearance in `tokens/semantic.json`.

Primary surfaces:

- `surface.content`: long-form content, tables, forms, browsers;
- `surface.secondary`: grouped content and side areas;
- `surface.raised`: cards, selected regions, inspectors;
- `surface.chrome`: title bars, rails, toolbars;
- `surface.overlay`: dialogs, command panels, HUD fallback;
- `surface.inverted`: rare inverse treatment.

Text roles:

- `text.primary`: titles, values, primary labels;
- `text.secondary`: descriptions and supporting information;
- `text.tertiary`: low-priority metadata that remains readable;
- `text.disabled`: unavailable content, never instructional content;
- `text.link`: navigational text with non-color affordance on focus/hover.

Action roles:

- `action.primary`: one dominant action per focused surface;
- `action.secondary`: safe alternative;
- `action.quiet`: low-emphasis contextual action;
- `state.destructive`: irreversible or difficult-to-recover action;
- `state.success`, `state.warning`, `state.informative`: status, always with text or symbol;
- `state.recording`: product-specific active capture role.

Rules:

- Do not use absolute black for owned surfaces.
- Do not use product artwork colors as persistent chrome.
- Do not rely on color alone for selection, error, success, warning, or recording.
- Do not introduce raw `.red`, `.green`, `.orange`, or new hex values in product UI.
- Contrast must be checked in Light and Dark independently.
- Increased Contrast may strengthen borders and selection without changing layout.

### 3.3 Typography

Use the system font. Exact roles are in `tokens/typography.json`.

Roles:

- `display`: rare hero or onboarding statement;
- `screenTitle`: primary page/window title;
- `modalTitle`: focused dialog or sheet title;
- `sectionTitle`: section and group title;
- `body` and `bodyEmphasized`: prose and form explanation;
- `row` and `rowEmphasized`: dense lists and tables;
- `supporting`: helper text and secondary descriptions;
- `metadata` and `compactMetadata`: operational metadata;
- `eyebrow`: rare compact category label;
- `keycap`: keyboard shortcut presentation;
- `monospacedData`: duration, size, codec, identifiers, diagnostics.

Rules:

- Prefer platform dynamic text styles over fixed point sizes.
- Do not create half-point sizes.
- Do not solve hierarchy by reducing important information below the supporting-text minimum.
- Use tabular numerals for changing values in aligned layouts.
- Keep reading lines near 45–76 characters.
- Uppercase eyebrow text must be short and must not carry essential instructions.
- Heading levels reflect document structure, not visual styling.

### 3.4 Spacing

The base rhythm is 4 points. Use semantic aliases rather than arbitrary values:

- `space.1` 4: optical micro-gap;
- `space.2` 8: icon-to-label and compact internal gap;
- `space.3` 12: row and control internal gap;
- `space.4` 16: standard group padding;
- `space.5` 20: panel rhythm;
- `space.6` 24: section separation;
- `space.8` 32: page-region separation;
- `space.10` 40 and `space.12` 48: onboarding and large canvas inset.

Choose component metrics before page padding. Avoid compensating for a broken component with local negative margins.

### 3.5 Size and density

Density profiles:

- `compact`: operational utilities, tables, menu panels;
- `standard`: content applications and mixed workflows;
- `comfortable`: onboarding, touch-first layouts, prominent settings.

Pointer targets may be visually smaller than touch targets but must remain focusable and easy to acquire. Platform values live in `tokens/platforms.json`.

Do not force one row height across products. Use the same density vocabulary and state behavior.

### 3.6 Radius

Corner hierarchy:

- `radius.control`: controls and interactive rows;
- `radius.group`: cards and settings groups;
- `radius.panel`: popovers, sheets, panels;
- `radius.hero`: prominent empty states and onboarding;
- `radius.floating`: HUD and command panels;
- `radius.pill`: chips, badges, and keycaps only when the shape communicates grouping.

Do not use maximum rounding as a substitute for hierarchy.

### 3.7 Borders and separators

- Hairlines divide dense content without creating card grids.
- Default borders define groups and controls.
- Strong borders indicate focus, selection, or increased contrast.
- Focus rings are not replaced by hover or selection fill.
- Table and split-view separators remain stable across hover and selection.

### 3.8 Materials and elevation

Opaque surfaces carry content. Adaptive translucent materials may be used for:

- title bars;
- navigation rails;
- toolbars;
- menus and popovers;
- media-player chrome;
- HUD and command/search panels.

Do not apply glass to tables, long settings forms, file lists, lyrics, or reading surfaces. Reduced Transparency replaces material with the named opaque fallback without changing geometry.

Elevation is communicated primarily by surface role, border, and occlusion. Shadows are subtle and reserved for floating layers.

### 3.9 Iconography

Apple platforms use SF Symbols first. Web surfaces use a consistent outline symbol set or project-owned SVGs with equivalent optical weight.

Rules:

- One meaning uses one symbol across the family.
- Do not reuse one symbol for sibling destinations.
- Icon-only controls require an accessible name and tooltip/help.
- Use familiar direct metaphors before clever composite symbols.
- Match symbol weight to adjacent text and control size.
- Selected state may change fill or rendering mode without changing geometry.
- Status icons are paired with text or another non-color indicator.

App icons share construction rules, not metaphors: safe zone, silhouette density, material, lighting, appearance specialization, and small-size testing. Every product keeps a distinct, task-relevant mark.

### 3.10 Imagery and media

- Preserve original artwork color and aspect ratio.
- Never crop away information to hide a layout problem.
- Use privacy-safe synthetic data in documentation.
- Extension/file thumbnails remain neutral unless the media itself is the task.
- Decorative imagery must not displace primary controls at constrained sizes.

### 3.11 Layout

Start with task hierarchy:

1. primary object or result;
2. primary action;
3. context and filters;
4. supporting metadata;
5. diagnostics and infrequent actions.

Use split views for simultaneous related contexts, sidebars for navigation or sources, inspectors for details, and sheets for focused tasks. Responsive behavior must be specified before local alignment polish.

Every layout defines:

- minimum and ideal size;
- what compresses;
- what wraps;
- what collapses into a menu;
- what becomes a separate screen/sheet;
- scroll ownership;
- focus order;
- behavior under 30% string expansion and 200% web zoom.

## 4. Interaction states

Every interactive component must define:

1. default;
2. hover where a pointer exists;
3. pressed;
4. keyboard focused;
5. selected where meaningful;
6. disabled;
7. loading where meaningful;
8. unavailable/error where meaningful;
9. increased contrast;
10. reduced motion/transparency behavior.

Focus, selection, and hover are different states:

- focus: where keyboard input will go;
- selection: which object is chosen;
- hover: temporary pointer preview.

Do not merge them into one visual boolean.

## 5. Controls

### 5.1 Buttons

Roles:

- `primary`: completes or advances the current focused task;
- `secondary`: safe alternative or cancellation-adjacent action;
- `quiet`: low-priority contextual action;
- `destructive`: destructive outcome with explicit label;
- `icon`: familiar compact action with help text;
- `menuRow`: action inside a custom menu-like list;
- `link`: navigation to documentation, policy, or related content.

Rules:

- Use one primary action per surface.
- Button labels begin with a verb and name the result.
- Use an ellipsis only when more input is required before completion.
- Loading keeps the button width stable and exposes progress/state text.
- Disabled controls explain why when the reason is not obvious.
- Destructive buttons do not become primary through placement or accidental emphasis.

### 5.2 Icon buttons

Icon buttons must have a stable hit target, accessible label, visible focus, hover help, and no geometry change between states. Use text buttons when the symbol is not immediately recognizable.

### 5.3 Fields

Field states are `pristine`, `editing`, `valid`, `invalid`, `disabled`, and `readOnly`.

- Do not show an error before interaction.
- Validate on blur, meaningful pause, or submit according to cost.
- Keep helper text stable where possible to avoid layout jumps.
- Error copy states the specific requirement and next action.
- Labels remain visible; placeholders are examples, not labels.
- Secure fields do not expose secrets in logs, screenshots, or accessibility hints.

### 5.4 Search

Search defines scope, clear action, shortcut, empty query behavior, result count, no-results state, and whether the query persists between surfaces.

Do not share query state between separate search contexts unless transfer is explicit and visible.

### 5.5 Selection controls

Checkboxes represent independent options. Radio groups represent exactly one choice. Switches change an immediate persistent setting. Segmented controls switch peer views or modes and must not hide destructive actions.

### 5.6 Pickers, sliders, steppers

Use pickers for discrete values, sliders for ranges where approximate manipulation is useful, and steppers where exact increments matter. Always expose the current value textually.

### 5.7 Chips, tokens, badges, keycaps

- Filter tokens are removable and name their scope.
- Status badges include text, not color alone.
- Count badges use localized plurals.
- Keycaps use one notation across the family, with spaces between modifier and key in prose: `⌥ Space`.
- Chips must not become tiny buttons with ambiguous behavior.

## 6. Containers and data display

### 6.1 Group and card

Use a group when content belongs together. Do not wrap every section in a card. A card needs a distinct semantic boundary, independent action, or elevated lifecycle.

### 6.2 Settings section and row

A Settings row is one accessible unit containing label, optional description, and trailing control. Its API must prevent an unnamed control.

Descriptions explain consequence, not restate the label. Section headers group related decisions; they do not become marketing copy.

### 6.3 Interactive row

The shared row owns hover, press, focus, selection, disabled, and unavailable presentation. Features must not pass hardcoded `false` values to suppress states.

Rows with multiple actions distinguish row activation from embedded links or controls. Double click and Return have the same primary meaning where desktop conventions expect it.

### 6.4 Lists, tables, grids, and trees

Use:

- list for one-dimensional peer items;
- table for aligned comparable attributes;
- grid for visual scanning where position is not a data relationship;
- tree for hierarchical disclosure.

Tables require:

- a dominant first column;
- visible sort direction;
- keyboard selection;
- column resize behavior where relevant;
- long-value handling;
- empty/no-results/loading/error states;
- accessible row and column semantics.

Selection must survive sorting only when the underlying object remains the same. Hidden selected items must be reported before bulk action.

### 6.5 Extension and file tiles

Use a neutral extension tile when filename recognition is primary. Do not replace filenames with generated media titles. Thumbnails are used only when visual content materially improves selection.

### 6.6 Media rows

Artwork may lead a media row. Title is primary, creator is secondary, and codec/quality is compact metadata. Embedded links must not trigger playback or break multi-selection.

## 7. Navigation

Shared navigation defines states, icon treatment, label behavior, keyboard movement, focus, persistence, and responsive transformation. It does not define one universal shell.

### 7.1 Rail

- Use for a small stable set of top-level destinations.
- Expanded mode prioritizes recognition; compact mode prioritizes space.
- Each destination needs a unique symbol.
- Expansion keeps icon anchors stable and animates width/label opacity only.
- Compact mode must not hide the current location entirely.

Archetype defaults:

- content libraries: expanded when recognition is more important than density;
- operational workspaces: compact or responsive based on width;
- transient utilities: no application rail outside full-window settings or history.

### 7.2 Sidebar

Use for labeled sources, categories, or settings sections. It supports keyboard movement, selection, scrolling, and a visible current item. Do not build a custom sidebar that loses arrow navigation or screen-reader semantics.

### 7.3 Toolbar

Toolbars contain frequent contextual actions. Search uses platform placement where available. Overflow is explicit through a labeled More menu; critical actions do not disappear into invisible horizontal scrolling.

### 7.4 Tabs and segmented navigation

Use for a small number of peer views. Preserve state when switching if users reasonably expect it. Active tabs are not clickable animations with no state effect.

### 7.5 Breadcrumb and contextual back

Use breadcrumbs for deep web/document hierarchy. Native apps use a labeled contextual Back when the destination depends on entry source. An unexplained chevron is insufficient where history is not obvious.

## 8. Overlays and transient surfaces

### 8.1 Menu

Menus contain immediate commands. Group related actions, show shortcuts, separate destructive actions, and disable with explanation where possible.

### 8.2 Popover

Use for a short contextual choice or inspector that can be dismissed without losing work. It must remain within the viewport and return focus to its initiator.

### 8.3 Sheet

Use for a focused task requiring input, review, or multiple decisions. Preserve unsaved work when an accidental dismissal would be costly.

### 8.4 Dialog and alert

Use alerts for interruption, permission, destructive confirmation, or failure requiring a decision. Titles state the situation; body explains consequence; actions name outcomes.

Do not use generic `OK` when a result verb is available. Do not confirm harmless reversible actions.

### 8.5 Toast and banner

Toast: transient completion that requires no decision. Banner: persistent surface- or app-scoped status. Neither replaces inline field errors or row failures.

### 8.6 HUD and command panel

HUDs communicate transient status without stealing keyboard focus. Command/search panels may take focus, but must preserve and restore the originating target before executing an action in another application.

Floating surfaces define multi-display placement from the active target window, not merely current mouse position.

## 9. Feedback and progress

### 9.1 Loading

Use a skeleton when content shape is known, an indeterminate indicator when duration is unknown, and determinate progress only when measured. Never fabricate progress from a timer.

### 9.2 Operation lifecycle

Long operations distinguish:

- preparing;
- waiting;
- running;
- paused;
- verifying;
- completing;
- completed;
- failed;
- cancelling;
- cancelled;
- interrupted and recoverable.

Actions must match the current lifecycle. Completed results are not removed when cancelling remaining work unless explicitly stated.

### 9.3 Empty and no-results

Empty means the underlying collection has no content. No-results means filters or search exclude existing content. They require different copy and recovery.

### 9.4 Errors

Error placement follows scope:

- field error: attached to one input;
- row error: attached to one object;
- section notice: affects a workflow region;
- banner: affects the current surface or app;
- alert: blocks continuation or requires a decision.

Errors state:

1. what happened;
2. what remains safe or saved;
3. the next action.

Preserve technical details in an optional disclosure or diagnostic export.

## 10. Core patterns

### 10.1 Select → Review → Execute → Complete/Recover

Use for imports, downloads, destructive batches, exports, and migrations.

Select shows scope. Review shows count, size, destination, conflicts, and exclusions. Execute exposes progress and cancellation semantics. Complete shows outcomes and recovery.

### 10.2 Destructive action

Classify consequence:

- reversible immediately: execute with Undo;
- recoverable later: explain destination and restore;
- destructive but scoped: confirmation with exact object/count;
- irreversible and broad: additional friction and explicit consequence.

### 10.3 Permission request

Explain the user benefit before the system prompt. Distinguish required from optional permissions. A fallback mode is presented as a mode, not an error.

### 10.4 Onboarding

Onboarding is short, skippable, truthful, and does not perform actions automatically. Required and optional steps are visually distinct. Trials use isolated destinations and do not pollute history or external applications.

### 10.5 Search and filters

Show scope, active filters, removable tokens, clear-all, result count, and no-results recovery. Critical filters remain discoverable at constrained widths.

### 10.6 Multi-selection

Support platform conventions. Bulk action summaries show visible and hidden selected counts. Changing filters must not silently operate on hidden objects without disclosure.

### 10.7 Offline and stale data

Name whether data is current, cached, partial, or unavailable. Preserve usable cached content. Retry is scoped and does not erase current state.

### 10.8 Focus restoration

Before opening a focus-taking floating surface, capture the target context. On action:

1. validate target still exists;
2. dismiss or deactivate the surface;
3. restore target focus;
4. perform the action;
5. report fallback honestly.

### 10.9 Privacy-safe export

Preview what is included and excluded. Default to minimum necessary data. Never include transcripts, private chat content, credentials, local home paths, or session data without explicit scope and warning.

### 10.10 Settings

Settings describe durable user choices, not transient commands. Use a native Settings window/scene when configuration is substantial and not part of the primary workflow. Embedded Settings may remain when operational status and configuration must be observed together, but it still uses the shared Settings grammar.

## 11. Motion

Exact durations and curves live in `tokens/motion.json`.

Motion classes:

- immediate feedback;
- state replacement;
- disclosure;
- floating presentation;
- spatial navigation;
- measured continuous progress.

Rules:

- Motion never changes the meaning of selection.
- State changes are interruptible and settle at the current input.
- Repeating decorative animation is prohibited.
- Springs are allowed only for a platform-native physical interaction with bounded displacement; routine UI uses semantic curves.
- Progress follows real work.
- Auto-scroll must be stoppable and removed under Reduced Motion.
- Reduced Motion retains short opacity or instant replacement and removes scale, translation, parallax, and stagger.

## 12. UX writing and localization

### 12.1 Voice

Calm, direct, specific, and honest. Avoid marketing language inside operational UI. Do not anthropomorphize errors when precision is needed.

### 12.2 Labels

- Start with a verb for actions.
- Name the result: `Download 2 Files`, `Reveal in Finder`, `Retry Verification`.
- Use sentence case by default for descriptions and messages.
- Use platform-standard capitalization for short native control titles when required.
- Use one term per concept across products and documentation.

### 12.3 Status

Report the actual outcome:

- `Copied to Clipboard` is not `Inserted`;
- `Saved for this session` is not `Saved`;
- `Cached results` are not `Up to date`;
- `No speech detected` is better than an internal recognition code.

### 12.4 Error copy

Avoid:

- `Something went wrong`;
- `Unknown error`;
- `The app needs help`;
- generic `Configure`;
- internal API terminology without user consequence.

Prefer specific cause, preserved state, and scoped action.

### 12.5 Confirmation copy

The title asks or states the consequence. The body explains what changes and what remains. Destructive action labels repeat the concrete verb.

### 12.6 Localization

- All user-facing strings live in the platform localization source.
- Use plural rules, not string concatenation.
- Date, time, byte size, decimal, and list formatting use locale-aware formatters.
- Key parity is validated automatically.
- Layout is tested with at least 30% expansion and long unbreakable values.
- HTML is not injected through untranslated strings.
- Typed/generated localization keys are preferred over duplicated default values.

### 12.7 Human-operated email

Email templates are production writing tools for a person, not autonomous messages. `registry/email-templates.json` owns the bilingual scenarios and variable contracts; `docs/EMAIL.md` owns the complete authoring, copying, safety, and QA rules.

- `contact@qenterra.com` handles general, partnership, press, and other non-product correspondence. `support@qenterra.com` handles product support, accounts, operations, security, and payments.
- English and Russian copies have semantic parity. A locale may sound natural rather than literal, but may not add or remove a promise, warning, action, deadline, or recovery route.
- The local composer sends nothing, stores no entered values, makes no external requests, and contains no marketing or newsletter capability.
- Fill only verified facts. Never invent a completion result, cause, deadline, account event, payment state, or security conclusion.
- The message language is chosen independently from the reference-site language. Changing it preserves current field values and updates template names, fields, preview, subject, and copied output together.
- Switching templates retains only values used by both scenarios; unrelated values leave the active in-memory state. Clear fields removes every current value and preview.
- Every output has a specific subject, hidden preheader, one clear title, a canonical greeting that does not repeat the outcome, short action-oriented paragraphs, optional structured details, at most one primary action, a plain-text equivalent, the responsible address, and a receipt explanation.
- Action URLs must be absolute HTTPS URLs. Passwords, recovery secrets, full payment-card data, telemetry pixels, remote imagery, scripts, forms, and attachments are prohibited.
- Copying rich content is not proof that a message was sent or rendered correctly. The human operator reviews subject, recipients, names, dates, links, amounts, claims, and the final message in the destination email client before sending.

## 13. Accessibility

### 13.1 Keyboard

- Every action is reachable.
- Focus order follows reading/task order.
- Focus is visible independently of selection.
- Escape closes reversible overlays.
- Return activates the primary selected object where conventional.
- Arrow keys navigate composite widgets according to platform conventions.
- Shortcuts appear in menus and help where discoverability matters.

### 13.2 Screen readers

Controls have names, values, roles, state, and available actions. Related visual fragments are grouped into meaningful accessible units. Progress and result counts announce without excessive chatter.

### 13.3 Contrast and color

Normal text targets WCAG AA on web. Native UI uses platform semantic colors and is verified under Increased Contrast. Status never relies on hue alone.

### 13.4 Text size and zoom

Web supports 200% zoom without loss of controls or horizontal page scrolling. Native layouts survive platform text-size and localization expansion. Fixed row heights must be tested or made adaptive.

### 13.5 Motion and transparency

Reduced Motion and Reduced Transparency preserve comprehension and interaction. Increased Contrast strengthens boundaries without changing hierarchy.

### 13.6 Touch and pointer

Touch targets meet platform minimums. Pointer interfaces may use denser visuals but maintain usable hit regions. Hover-only information also appears on focus or tap.

## 14. Platform layers

### 14.1 macOS

- Use native menus, commands, toolbar placement, split views, settings scenes, file panels, Quick Look, and Finder integration.
- Windows are resizable and define minimum/ideal states.
- Keyboard and pointer are first-class.
- Avoid unnecessary modality.
- Custom rails and tables must reproduce native focus, selection, and accessibility semantics.

### 14.2 iOS

- Use touch-first targets, Dynamic Type, safe areas, native navigation stacks, sheets, and tab bars.
- Do not shrink macOS density into a phone.
- Primary actions remain reachable and do not hide behind hover or context menus.

### 14.3 iPadOS

- Use split views, sidebars, inspectors, pointer and keyboard support.
- Define compact, half-width, and full-width behavior.
- Support multitasking and Stage Manager size changes without recreating state.

### 14.4 Web

- Use semantic HTML before ARIA.
- Support keyboard, focus-visible, reduced motion, forced colors, touch, 200% zoom, print, and responsive navigation.
- Do not imitate macOS controls pixel-for-pixel when browser conventions are clearer.
- Use CSS custom properties generated from semantic tokens.

### 14.5 Browser extensions

- Popup, side panel, overlay dock, bottom sheet, and options page are separate layout modes.
- Overlays remain within viewport and outside clipped host-page containers.
- Host-page styles and scripts are isolated.
- Selection and hover are distinct; leaving the overlay does not mutate a locked selection.
- Critical controls remain visible at narrow widths and with localization expansion.

## 15. Product archetypes

Exact profile arrays live in `tokens/products.json`. Choose an archetype by interaction model, not by branding; a product may combine them when boundaries remain explicit.

### 15.1 Immersive content

Use for libraries and browsers where persistent content hierarchy, rich media, selection, queues, and long-lived state dominate. Keep adaptive surfaces, review-first imports, persistent task controls, stable tables, and recoverable removal. Adapt density and navigation to the platform. Replace duplicate symbols, scattered visual constants, suppressed interaction states, and persistence claims that exceed reality.

### 15.2 Dense operations

Use for file, transfer, batch, and administration workflows. Keep filename-first or object-first hierarchy, selection summaries, preflight, conflict resolution, scoped progress, operation history, and system integration. Adapt rail density, toolbar wrapping, issue placement, localization, and motion. Replace invisible overflow, pristine-field errors, unnamed toggles, silent session discard, and global untyped errors.

### 15.3 Transient capability

Use for menu-bar utilities, HUDs, capture tools, quick history, and background capabilities surfaced briefly. Keep honest state vocabulary, real-signal-only feedback, semantic motion, privacy language, keycaps, target restoration, and diagnostics. Adapt palette, typography, settings, onboarding requirements, and lifecycle cards. Replace forced appearance, undersized type, generic recovery, fake trials, broken focus restoration, and stale visual sources.

## 16. App icons

App icons form a family through:

- shared optical weight;
- controlled biomorphic or faceted construction;
- restrained graphite/monochrome material;
- appearance-aware foreground/background contrast;
- consistent safe zones and silhouette density;
- matching lighting, translucency, and depth rules;
- validation at 16, 32, 64, 128, 256, 512, and 1024 pixels where supported.

They must remain semantically distinct. Do not turn every icon into a letter tile or force one product's geometry onto unrelated concepts.

## 17. Documentation and screenshots

Every product maintains a reproducible screenshot harness with synthetic data.

Required matrix:

- System, Light, Dark;
- minimum and wide window;
- primary workflow;
- empty;
- no results;
- loading/progress;
- error and recovery;
- hover/focus/selection where useful;
- Reduced Motion/Transparency and Increased Contrast evidence;
- privacy scan and visual inspection.

Screenshots prove geometry and appearance only. They do not prove keyboard, screen-reader, persistence, networking, or recovery behavior.

## 18. Governance

### 18.1 Change types

- patch: clarification or non-breaking correction;
- minor: additive token, component, pattern, or platform guidance;
- major: renamed/removed semantic token, behavior contract change, or product migration requirement.

### 18.2 Token lifecycle

1. State the problem and affected consumers.
2. Reuse an existing semantic role if meaning matches.
3. Add a foundation value only when the scale cannot express the requirement.
4. Add or change semantic mapping.
5. Update component/pattern documentation.
6. Regenerate CSS and Swift.
7. Run validation and visual comparison.
8. Add migration notes and changelog entry.

### 18.3 Exceptions

An exception records:

- product and platform;
- user need;
- why the shared rule fails;
- exact scope;
- accessibility impact;
- expiry or review trigger;
- owner/source file.

Exceptions do not modify family foundations silently.

### 18.4 New component gate

Before creating a component, confirm:

- no existing component can compose the result;
- anatomy and content roles are named;
- every mandatory state is defined;
- keyboard and screen-reader behavior is defined;
- responsive and localization behavior is defined;
- reduced motion/transparency and increased contrast are defined;
- platform-native alternatives were evaluated;
- test and screenshot cases exist.

### 18.5 Deprecation

Deprecated tokens/components remain documented for one migration window with replacement guidance. Validators may warn first and fail after the announced major version.

## 19. AI implementation protocol

When an AI builds or reviews UI:

1. Read this file, the platform layer, and product profile.
2. Identify the primary user task and consequence of failure.
3. Choose a pattern before choosing components.
4. Resolve exact tokens from JSON or generated adapters.
5. Enumerate states and accessibility behavior before code.
6. Use realistic localized content, not lorem ipsum.
7. Implement the smallest coherent component set.
8. Run project-specific verification.
9. Render all required appearances and constrained sizes.
10. Report automated, visual, live, and unverified evidence separately.

The AI must not:

- infer current UI from stale screenshots;
- introduce a new raw color, duration, radius, or string source casually;
- call static compilation visual QA;
- call screenshots accessibility QA;
- claim a fallback outcome as the requested outcome;
- copy a product-specific component into the family core without a second valid consumer.

Focused schemas are contracts, not editor decoration. A token change must preserve reference acyclicity and type compatibility. Component metrics use foundation references unless `components.extensions.rawMetricExceptions` contains a narrow, justified exception. Consumers should prefer typed `QDS.Color`, `QDS.Typography`, `QDS.Motion`, and `QDS.Component` APIs or CSS tokens; CSS recipes remain opt-in because native and product-specific shells are allowed to differ.

`registry/components.json` is the executable component inventory. Its stories must cover representative states and expose stable Component Lab anchors. Review System/Light/Dark, compact/standard density, constrained widths, pseudo-long, and pseudo-RTL before adoption. Pseudo-locales reveal wrapping and bidirectional bugs; they are not substitutes for human localization. SwiftUI consumers may start with the provided button and group primitives, but platform behavior and product context still override decorative sameness.

## 20. Maintenance procedure

To update the design system:

1. Read `AGENTS.md`, this file, affected token files, and relevant product evidence.
2. Add or update an ADR in `docs/decisions/` for a normative change.
3. Change source tokens/docs/templates/site fragments.
4. Run `python3 scripts/build.py`.
5. Run `python3 scripts/verify.py`.
6. Render the exact `evidence/screenshots.json` matrix, compare current pixels to committed baselines, and inspect desktop and mobile captures in both appearances.
7. Update `CHANGELOG.md` and version according to change type.
8. Update Obsidian routing instructions only when workflow or product contract changes; do not duplicate token values.
9. For brand changes, update the asset manifest, preserve Git LFS coverage, run focused Nyx QA, and inspect original/use-size artwork on required backgrounds.
10. Commit source and generated artifacts together after verification.

## 21. Definition of done for product adoption

A product is compliant only when:

- semantic tokens replace local duplicates;
- required component states are implemented;
- product-specific exceptions are documented;
- user-facing strings use the localization source;
- keyboard and accessibility behaviors are verified;
- appearance and constrained-layout screenshots are current;
- empty/loading/error/recovery states are exercised;
- raw token and stale-doc validators pass;
- remaining live gaps are explicit.

Visual similarity alone is not adoption.

Begin adoption with the consumer manifest and read-only doctor. A product declares platforms, source roots, expected local adapters, and a separate exception file. Doctor output distinguishes schema/boundary errors from actionable findings and never writes inside the consumer. Exceptions match an exact rule and path, explain the real constraint, and carry a review trigger. A passing static report is evidence for covered source rules only; it does not prove native rendering, accessibility APIs, permissions, persistence, or recovery.

Interface icons come from `registry/icons.json`: one semantic ID, category, meaning, and reviewed 16-point SVG fragment. Web/site consumers use generated metadata or sprite output; native products prefer a platform symbol when its meaning and optical weight match, otherwise the registry asset. A symbol never replaces a visible label when the action or outcome is ambiguous.

Design-tool handoff comes only from deterministic `generated/figma/` payloads. Importers preserve collection names, modes, and types, surface unsupported fields, and start in a scratch file. Generated JSON is not proof of a published Figma library. The temporary brand browser is a search aid and is prohibited from writing into the repository.
