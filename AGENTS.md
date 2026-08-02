# QenTerra Design System

Read `docs/MASTER.md` or `docs/MASTER.ru.md` first for any design or UI work. Exact values live in `tokens/*.json`; generated files are outputs, never sources. The two language references must stay semantically complete and structurally aligned.

## Required workflow

1. Identify the affected foundation, component, pattern, platform, or product profile.
2. Read the relevant section of `docs/MASTER.md` and the referenced token file.
3. Change source files only: `tokens/`, `src/`, `docs/`, or `templates/`.
4. Run `python3 scripts/verify.py`.
5. Inspect generated HTML and screenshots before claiming visual completion.
6. Update `CHANGELOG.md` and `VERSION` for any normative change.

## Boundaries

- Family consistency means shared semantics and behavior, not identical product shells.
- Native platform conventions override decorative sameness.
- Product-specific exceptions belong in `tokens/products.json` and the product profile, not in foundation tokens.
- Do not add raw colors, ad hoc motion durations, or one-off radii to product code when a semantic token exists.
- Do not claim live app, VoiceOver, or native rendering QA from static site checks.
- Keep the repository local until the user explicitly requests publication.
- Create AI working specs, plans, handoffs, scratch notes, and tool artifacts only in a unique system temporary directory. Never add `.superpowers/` or `docs/superpowers/` to the repository.
