# Repository documentation migration record

This record explains how the former local `repository-documentation-standard` tree was absorbed into QenTerra Design System 1.2.0. It is provenance evidence, not a second source of truth.

## Canonical destinations

| Former source | Current destination | Disposition |
| --- | --- | --- |
| `STANDARD.md` | `docs/repository/STANDARD.md` | Preserved, extended with template application, rendered in the reference site. |
| Russian standard | `docs/repository/STANDARD.ru.md` | Added as a complete structural peer with stable shared anchors. |
| `AUDIT.md` | `output/repository-documentation-audit.md` | Preserved as audit evidence. |
| `README.md` | `templates/repository/README.md`, root `README.md`, and `docs/MAINTENANCE.md` | Its selection, copy, verification, and legal-boundary workflow is now operational documentation. |
| `DESIGN.md` | `docs/decisions/ADR-003-repository-documentation-module.md`, repository standards/templates, and this record | Approved family decisions retained; obsolete rollout status is not normative. |
| `templates/` | `templates/repository/` | All README profiles, root policies, contributor docs, GitHub metadata, and Wiki templates categorized without flattening hidden paths. |
| `prepared-wikis/lilt/` | Lilt `docs/WIKI.md` and `docs/wiki/` | Preserved locally as future Wiki source; not published and no remote was invented. |

## Retained design decisions

- One family information architecture with distinct native-macOS and browser-extension README profiles.
- A consistent hero, truthful badge order, early distribution status, stable section order, synthetic screenshots, documentation map, support boundary, and license boundary.
- README as product map, `docs/` as contributor reference, root policy files as legal/security sources, Wiki as user guidance, and private knowledge base as internal workflow.
- Wiki core of Home, Sidebar, Getting Started, Feature Overview, Privacy and Security, and Troubleshooting; internal links omit `.md`, sidebar covers every user page, and images come from canonical main-branch assets.
- Funding limited to the approved Buy Me a Coffee URL in README and `.github/FUNDING.yml`, not product UI, Wiki, legal text, or contributor instructions.
- Product facts always verified against current source, manifest, entitlements, storage, dependencies, releases, repository settings, and Wiki remote.
- Static, rendered, live, and manual evidence reported separately; publication requires remote SHA/read-back and is never inferred from local files.

## Retirement rule

The former directory may be moved to the macOS Trash only after QDS, Lilt Wiki, and Obsidian gates pass, local commits exist, every former source has a recorded destination, and a hash read-back proves the recoverable Trash copy matches the pre-migration manifest. It must not be permanently deleted or recreated as a parallel canonical source.
