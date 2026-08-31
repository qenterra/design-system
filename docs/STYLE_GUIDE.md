# Style guide

## Language

Public code identifiers, repository documentation, issues, pull requests, commits, and release notes use English. Preserve exact product names, APIs, standards, and user-facing localisations where required.

## Names and layout

- Repository and general directories use lowercase `kebab-case`.
- GitHub community and legal root files use their canonical uppercase names.
- Source files and symbols follow the declared python-node-swift convention.
- New top-level paths require an architectural or tooling reason and a documentation update.

## Code

Python follows the repository's explicit, typed helper style and is syntax-checked by `scripts/verify.py`. JavaScript uses ESM where present. Swift follows Swift API Design Guidelines and the package's existing formatting. No formatter may rewrite generated output independently of its source generator.

## Documentation

Use descriptive headings, portable Markdown, runnable examples, meaningful link text, image alternative text, and one source of truth per durable subject. Do not publish placeholders or internal operational prose.

## Accessibility and inclusive language

Treat keyboard access, assistive technology, contrast, reduced motion, localisation, and clear error text as product requirements where the profile exposes an interface.
