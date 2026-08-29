# Style guide

## Language and names

- Repository documentation, issue forms, pull requests, commit subjects, and release notes use English.
- Root community and legal files use canonical uppercase names; general directories use lowercase `kebab-case`.
- Swift source follows Swift API Design Guidelines. npm paths and exports use lowercase kebab-case. Python verification code uses descriptive snake_case.
- Public names remain `QenTerraDesignTokens`, `QenTerraComponents`, and `@qenterra/design-tokens` unless a versioned migration changes them.

## Code and generated files

Prefer explicit interfaces, bounded responsibilities, deterministic output, and comments that explain invariants instead of syntax. Edit maintained source, never `npm/design-tokens/dist/` in isolation. A generated-file change includes its source change and verification evidence.

## Documentation

Use sentence-case headings, portable Markdown, runnable commands, meaningful links, and exact evidence language. Remove placeholders and internal work prose. Separate automated checks from live consumer and manual platform acceptance.

## Accessibility

SwiftUI components preserve semantic roles, focus behavior, Dynamic Type, contrast, reduced motion, localization, and native platform conventions. Static package checks do not replace current VoiceOver or rendered-product acceptance.
