# Commit standard

## Unit of history

A commit records one reviewable change. Keep implementation, regression coverage, generated counterparts, and the documentation required to understand that change together. Split unrelated formatting, dependency updates, refactors, and behavior.

The repository must build or pass its documented intermediate gate at each commit unless the commit belongs to a clearly marked, private reconstruction branch.

## Subject

Use Conventional Commits:

```text
type(optional-scope): imperative outcome
```

Allowed types are `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`, and `revert`. Use a scope when it helps a reviewer locate ownership, such as `icons`, `swift`, `web`, `brand`, or `release`. Keep the subject specific, lower-case after the colon, and free of a trailing period.

## Body

Add a body when the diff cannot explain the reason, constraint, data effect, or rejected alternative. Write paragraphs in active voice. Describe the current behavior and the change. Do not paste test logs, meeting notes, prompts, or a file-by-file inventory.

```text
fix(search): restore focus after dismissing results

Return focus to the search field after Escape closes the result list. This keeps keyboard navigation in the active task.
```

## Breaking changes

Add `!` after the type or scope and a `BREAKING CHANGE:` footer when a consumer must migrate.

```text
feat(icons)!: use SF Symbol names as icon values

BREAKING CHANGE: QDSIcon raw values now contain SF Symbol system names. Remove code that treats them as asset identifiers.
```

Name the old contract, replacement, required consumer action, and first compatible version.

## References and trailers

Use issue or decision references only when they resolve to a durable record. Put machine-readable trailers after the body:

```text
Refs: #184
ADR: docs/decisions/0004-symbol-registry.md
Co-authored-by: Name <address>
```

Never invent an author, reviewer, issue, or verification claim. Do not add AI attribution unless repository policy requires it.

## Generated files and assets

Commit generated output with the source that produced it when the repository tracks generated output. A generated-only commit must state the source revision or command. Asset changes include manifest metadata, license records, and use-size validation.

## Review before commit

Inspect the staged diff, not only the working tree. Check for secrets, personal data, tool artifacts, temporary paths, unrelated changes, stale generated files, and missing notices. Run the smallest complete verification command for the staged unit.

## Reverts and history repair

Use `revert: <original subject>` and preserve the generated `This reverts commit …` body. Explain partial reverts. Before rewriting shared history, create a verified backup, identify exact remote state, and use `--force-with-lease`. Publishing or rewriting history requires explicit authorization.
