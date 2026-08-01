# Lilt migration brief

## Baseline

Lilt is the state, motion, privacy, and localization donor. Its current UI is Dark-only, typographically over-compressed, and lacks current rendered evidence. Two context bugs must be fixed before visual migration.

## Blocking context work

1. Menu-panel Insert must capture, validate, restore, and act on the original target application.
2. Trial Dictation must use an isolated sink that does not insert externally or enter normal History.

## Ordered slices

1. Fix both blocking context flows with regression and live target-app tests.
2. Replace fixed dark colors and forced appearance with generated adaptive semantic roles.
3. Map LiltMotion events to generated family motion while retaining floating-surface semantics.
4. Replace half-point and low-contrast supporting text with shared typography roles.
5. Normalize buttons, settings groups/rows, keycaps, status colors, and focus/selection behavior.
6. Separate required model/microphone setup from optional Accessibility permission.
7. Map HUD errors to specific cause and recovery; remove generic `Configure`.
8. Make interactive model/application rows match their actual hit target and keyboard behavior.
9. Wire the Icon Composer source into the target and verify compiled small-size output.
10. Generate current privacy-safe visual evidence for Settings, onboarding, menu panel, HUD, and Quick History.

## Acceptance

- System/Light/Dark supported without losing recording-state clarity.
- Insert and trial act only in the promised context.
- HUD visible bounds do not intercept pointer outside the card.
- Active-window display placement works across multiple displays.
- Settings arrows, Quick History focus/selection, search announcements, localization expansion, VoiceOver, permissions, clipboard restoration, model lifecycle, and recording limits receive separate live evidence.

## Product-specific boundaries

Recording red, real signal bars, timer, hold/release model, local model lifecycle, clipboard/direct insertion distinction, and menu-bar-only shell remain Lilt-owned.
