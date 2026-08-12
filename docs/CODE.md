# QenTerra Code System

## Purpose and scope

This reference defines family-wide engineering semantics for native applications, websites, browser extensions, and tooling. It complements `MASTER.md`; platform conventions and product architecture remain authoritative for their own scope. Read this guide, the language profile, the product architecture, and source-of-truth configuration before implementing or reviewing code.

Code quality is a product property: code that runs but cannot be safely changed by a developer new to the module has only deferred its cost.

## Code Core

### Ownership and boundaries

- Each changing value has one declared source of truth; generated output is never hand-edited.
- A module owns one domain responsibility and a narrow public interface. Catch-all `Manager`, `Helpers`, `Common`, or `Utils` modules need a precise domain role.
- Presentation does not own persistence, network I/O, or business policy; infrastructure does not know screen rendering details.
- Keep dependency direction explicit. Promote code to a shared family layer only after two genuine consumers demonstrate the same semantic need.

### Naming and public APIs

- Types and values use precise nouns; operations use outcome-oriented verbs. Prefer `saveProfileChanges` to `handleSubmit` and `ArtworkCache` to `DataManager`.
- A public API makes result, effects, preconditions, failure behavior, and lifecycle clear at the call site or in focused documentation.
- Replace Boolean parameters that change meaning with a named option, state type, or separate operation. Use abbreviations only when standard in the platform or domain.

### State, effects, and errors

- Model domain state with explicit variants and valid transitions, not unbounded combinations of Boolean flags.
- Network, filesystem, storage, destructive actions, permissions, telemetry, and user-visible notifications are visible at a system boundary.
- Errors preserve actionable context. User-facing errors state what happened, what remains safe, and the next safe action without exposing diagnostics or secrets.
- Model cancellation, retry, partial completion, and recovery when an operation has those states.

### Readability and local structure

- Start a file with its public scenario and purpose; place implementation details below it.
- Keep one abstraction level in a block. Do not mix orchestration, policy, parsing, persistence, and rendering merely because they are nearby.
- Keep the success path legible; use guard clauses when they reduce nesting without hiding cleanup.
- Name complex predicates, transformations, and effects. Compactness never outranks clarity.
- Formatters own syntactic spacing and wrapping; empty lines separate logical steps only.
- Comments explain intent, constraints, trade-offs, or external contracts, never obvious statements or obsolete history.
- Extract repetition only after it has a real shared concept.

### Verification, privacy, and AI-assisted changes

- A behavior change adds credible regression coverage or explicitly reports required live/manual acceptance.
- Tests describe behavior and outcome, not a private implementation sequence.
- Changes to permissions, storage, network, retention, dependencies, generated sources, public APIs, or destructive behavior update relevant documentation and evidence.
- AI-assisted code has no lower standard: its author understands the behavior and boundaries, removes dead branches and unused dependencies, and supplies ordinary verification evidence.

## Human-readable code

Code is readable when a developer who did not author the module can change it safely. From a file and its immediate contracts, a reviewer can identify its responsibility, use and result, dependencies and effects, states and failures, and verification path.

Review prompt: **Could a developer opening this module for the first time make the requested change safely without a tour through the whole repository?** If not, improve the boundary, name, documentation, local structure, or test before expanding the feature.

## File and module design

- Put one public responsibility in a file or a small directory. Split a file when independent reasons to change have accumulated, not at an arbitrary line count.
- Keep constructors and public entry points close to the types they create. Keep private parsing, mapping, persistence, and rendering helpers near their owner.
- Import only direct dependencies. A facade may expose a stable public surface, but it must not hide cycles or global mutable state.
- Delete dead code, commented-out implementations, unused flags, and compatibility branches after their supported window ends.

## Formatting code and examples

- Let the repository formatter decide whitespace. Do not align code by hand in a way that collapses on the next rename.
- Wrap expressions at semantic boundaries: arguments, collection entries, chained stages, and Boolean clauses.
- A code example includes imports, input, expected result, failure behavior, and the command that runs it when those details affect use.
- Prefer a complete small example over a large excerpt with missing types. Mark illustrative pseudocode as pseudocode.
- Logs, IDs, paths, commands, and machine output use monospace formatting. UI labels and prose do not.

## Generated, vendored, and migrated code

- Generated files name the generator and reject manual drift in the canonical verification command.
- Vendored code keeps its upstream source, version, license, local modifications, and update procedure.
- A migration separates mechanical transformation from behavior changes. Verify the transform is repeatable before applying it across the repository.
- Compatibility code names its removal condition. A permanent `legacy` folder is an unlabeled product decision, not a migration plan.

## Language profiles

### Swift and native Apple platforms

- Follow Swift API Design Guidelines: clarity at the call site, meaningful argument labels, and documentation that exposes API flaws.
- Use the adopted formatter and linter; a compatible migration formatter is allowed only when its output is idempotent and verified.
- Make concurrency isolation explicit with `@MainActor`, actors, `Sendable`, and ownership at API boundaries.
- SwiftUI views present state and delegate policy, persistence, network, and long operations to bounded collaborators.
- Blocking: formatter, lint, build, unit tests. Native rendering, VoiceOver, permissions, audio, filesystem, and hardware are live/manual evidence.

### TypeScript, web, and browser extensions

- Use strict TypeScript. Isolate and immediately narrow or validate any external `any` boundary.
- Use discriminated unions or equivalent explicit state types.
- Put DOM, extension messaging, storage, and network APIs behind focused adapters.
- Blocking: Prettier, ESLint, strict type checking, unit tests, and product-appropriate browser/E2E evidence.

### Python and Bash tooling

- Python uses Ruff, public-boundary type hints, and pytest.
- Bash is repeat-safe, quotes Unicode and spaced paths, handles failures explicitly, and never uses unresolved globs or broad paths for destructive work.
- Ruff/pytest and ShellCheck/shfmt are advisory until a product completes scoped adoption; they then become blocking in that product.

## Enforcement and evidence

| Class | Examples | Enforcement |
| --- | --- | --- |
| Mechanical | Format, lint, typecheck/build, unit tests, generated drift, raw-token guard | Blocking in an adopted profile |
| High-impact | Public API, dependency, storage/network boundary, migration, exception | PR record; ADR for normative or cross-product decisions |
| Architectural risk | Complexity, duplication, file growth, dependency cycle | Report with owner and review date |
| Live boundary | Native rendering, VoiceOver, browser runtime, permissions, hardware, service | Live evidence or manual gap |

Every repository documents one canonical verification command that covers its adopted blocking checks.

## Repository contributor contract

Each repository keeps concise product-specific guidance in `CONTRIBUTING.md`, a module/side-effect map in `docs/ARCHITECTURE.md`, and evidence prompts in its pull-request template. The QDS Code System is canonical; repositories do not copy it and let it drift.

## Exceptions

An exception records the exact rule and path, technical reason, owner, review condition, and review date. It never silently changes a foundation, platform, or product contract, and never waives security, privacy, accessibility, or destructive-operation evidence.

## Adoption sequence

1. Add the relevant profile and canonical command to one product.
2. Audit current conventions and record only real exceptions.
3. Make mechanical checks blocking after a clean scoped migration.
4. Keep behavior, architecture, live, and manual evidence separate.
5. Adopt other products in separate tasks; do not mix mass formatting with functional work.
