# Component catalog

This catalog defines the expected interface vocabulary. It does not require every product to implement every component. A product implements only components justified by its tasks, using the shared contract and platform adapter.

## Actions

| Component | Use | Required contract |
| --- | --- | --- |
| Primary button | Dominant completion/advance | One per focused surface; loading, disabled reason, focus |
| Secondary button | Safe alternative | Stable hierarchy beside primary |
| Quiet button | Contextual low-priority action | Hover/focus background; visible label when icon is unclear |
| Destructive button | Difficult-to-recover result | Exact verb, consequence, confirmation/Undo according to risk |
| Icon button | Familiar compact action | Accessible name, tooltip/help, stable hit target |
| Split button | One default plus related alternatives | Default is safe and frequent; menu has keyboard semantics |
| Link | Navigation or documentation | Distinguishable on hover/focus without color alone |
| Menu row | Command in custom command surface | Role, shortcut, disabled reason, destructive separation |

## Text and form input

| Component | Use | Required contract |
| --- | --- | --- |
| Text field | Short single-line value | Persistent label, pristine/editing/valid/invalid |
| Secure field | Secret | No logging/screenshot leakage; reveal behavior explicit |
| Text area/editor | Multi-line content | Resize/scroll ownership, undo, selection, long text |
| Search field | Query within named scope | Clear, shortcut, result count, no-results, persistence |
| Token field | Multiple discrete values | Keyboard removal, overflow, duplicate prevention |
| Number field | Exact numeric value | Locale, min/max, units, invalid partial editing |
| Date/time picker | Calendar or time value | Locale, timezone, keyboard, invalid/unavailable ranges |
| File/folder picker | User-controlled path | Security scope, recent state, inaccessible-path recovery |
| Drop zone | Direct file/data input | Keyboard alternative, accepted types, review before mutation |

## Selection and adjustment

| Component | Use | Required contract |
| --- | --- | --- |
| Checkbox | Independent Boolean choice | Label is part of control; mixed state where meaningful |
| Radio group | One of several choices | Arrow navigation, group label, one selected |
| Switch | Immediate durable setting | Consequence clear; no separate Apply unless deferred by design |
| Segmented control | Small peer mode/view set | Selection visible by shape; no hidden destructive action |
| Picker/select | Discrete value list | Current value, menu keyboard behavior, long labels |
| Slider | Approximate range | Textual value, keyboard increments, min/max |
| Stepper | Exact increments | Textual value, boundaries, press-repeat behavior |
| Rating | Ordered preference | Non-color value and keyboard access; use rarely |

## Compact metadata

| Component | Use | Required contract |
| --- | --- | --- |
| Badge | Count or compact status | Plural/localization, not color-only |
| Filter token | Active removable filter | Scope name, remove action, keyboard overflow |
| Chip | Compact category/action | Behavior is explicit; not decorative ambiguity |
| Keycap | Shortcut notation | One notation, screen-reader expansion, platform mapping |
| Extension tile | File type recognition | Neutral visual, filename remains primary |
| Avatar/artwork | Identity or media recognition | Fallback, privacy, alt/accessibility treatment |

## Navigation

| Component | Use | Required contract |
| --- | --- | --- |
| Rail | Small stable top-level destinations | Compact/expanded, unique symbols, current-location cue |
| Sidebar | Labeled sources or sections | Arrow navigation, selection, resize/scroll behavior |
| Toolbar | Frequent contextual actions | Overflow priority, keyboard/menu parity, adaptive wrapping |
| Tab bar | Peer destinations/views | Current state, touch targets, preserved state |
| Breadcrumb | Deep web/document hierarchy | Current item, truncation, keyboard links |
| Contextual Back | Return to entry source | Visible label when history is not obvious |
| Pagination | Discrete large result sets | Current/total, disabled bounds, URL/shareable state on web |
| Step indicator | Ordered setup/task | Required vs optional, current/completed/error semantics |

## Containers

| Component | Use | Required contract |
| --- | --- | --- |
| Group | Semantically related content | Heading/label, spacing, no unnecessary elevation |
| Card | Independent object/action lifecycle | Clear boundary and action ownership |
| Settings section | Related durable choices | Title, optional description, stable rows |
| Settings row | Label + consequence + control | One accessible unit; unnamed control impossible |
| Inspector | Contextual detail/editing | Selection relationship, resize, focus return |
| Split view | Simultaneous related contexts | Minimums, divider keyboard/accessibility, persistence |
| Scroll region | Content overflow owner | Visible affordance, focus, nested-scroll avoidance |
| Disclosure/accordion | Optional detail | Expanded state, keyboard, reduced motion, no hidden critical action |

## Collections and data

| Component | Use | Required contract |
| --- | --- | --- |
| List | One-dimensional peers | Selection/action semantics, empty/loading/error |
| Table | Comparable aligned fields | Sort direction, resize, keyboard, accessible headers |
| Grid | Visual scanning | Reading order, adaptive columns, selected/focus distinction |
| Tree | Hierarchy | Disclosure, levels, arrow navigation, partial loading |
| Timeline/history | Ordered operations | Time/order, current/interrupted/completed distinctions |
| Activity row | Ongoing operation | Progress, pause/resume/cancel, retained completed items |
| Media row | Artwork + media metadata | Playback action separated from embedded links |
| File row | Filename + operational metadata | Original name primary, conflict/status explicit |
| Chart | Quantitative relationship | Text/table alternative, scale/units, color-independent series |

## Feedback and status

| Component | Use | Required contract |
| --- | --- | --- |
| Inline help | Input or local explanation | Not a substitute for label; remains available on focus |
| Field error | One invalid input | Trigger after interaction; requirement + recovery |
| Row error | One object failure | Object remains identifiable; retry/details where possible |
| Inline notice | Local non-blocking state | Scope and next action |
| Banner | Surface/app-wide persistent state | Severity, scope, dismiss/recovery semantics |
| Toast | Transient completion | No required decision; screen-reader announcement |
| Status badge | Compact lifecycle state | Symbol/shape + words |
| Empty state | Underlying collection empty | Cause/context and primary next action |
| No-results state | Query excludes content | Clear filters/query and retain context |
| Skeleton | Known content shape loading | `aria-busy`, reduced motion, no false structure |
| Spinner | Unknown short wait | Label when duration matters; never fake progress |
| Progress bar | Measured completion | Numeric/value semantics, lifecycle actions |

## Overlays

| Component | Use | Required contract |
| --- | --- | --- |
| Tooltip/help | Supplemental explanation | Hover and focus, delay, dismiss, not critical-only content |
| Menu/context menu | Immediate commands | Keyboard, shortcuts, grouping, disabled/destructive rules |
| Popover | Short contextual choice/detail | Viewport clamp, dismissal, focus return |
| Sheet | Focused input/review task | Unsaved work, primary/cancel hierarchy, focus trap where required |
| Alert | Blocking situation/decision | Specific title, consequence, concrete actions |
| Confirmation dialog | Risky outcome | Exact scope/count and what remains |
| HUD | Non-focus transient status | Real signal, no pointer interception outside visible bounds |
| Command/search panel | Focus-taking fast action | Target capture/restore, Escape, result count, keyboard-first |

## Product archetypes

| Archetype | Shared contract | Typical context |
| --- | --- | --- |
| Persistent player | Stable transport/status layer | Media library |
| Playback queue | Ordered selection, reorder, undo, unavailable state | Ordered content |
| Preflight summary | Scope/count/size/destination/conflicts | Batch operation |
| Conflict resolver | Safe default and explicit alternatives | File or data transfer |
| Recording HUD | Real signal, timer, state, non-focus | Active capture |
| Quick history | Search, selection, insert/copy, recovery | Transient utility |
| Model lifecycle card | Download/verify/install/load/recovery/license | Local capability |

## Component acceptance

A component is accepted only when its purpose, anatomy, content rules, semantic tokens, mandatory states, interaction, keyboard, screen-reader behavior, responsive transformation, localization expansion, reduced settings, and verification cases are documented and implemented for the target platform.
