# Repository Documentation Standard

## Principles

1. **One spine, product-specific facts.** Every README follows the same order,
   but distribution and permission sections use the appropriate product
   profile.
2. **User path before implementation detail.** Explain what the product does,
   its current status, and how to use or install it before architecture.
3. **Verified claims only.** Read manifests, entitlements, network clients,
   storage code, dependency metadata, and release artifacts before writing
   privacy or compatibility claims.
4. **Public documentation is not an attic.** Completed plans, agent output,
   remediation briefs, private runbooks, and historical implementation notes do
   not belong in the public tree.
5. **Honest gaps are part of the product status.** Separate automated checks,
   live validation, and remaining manual acceptance.
6. **Templates are disposable scaffolding.** Remove unused sections instead of
   leaving empty headings or generic filler.

## Canonical root files

| File | Policy |
| --- | --- |
| `README.md` | Required. Product overview, status, interface, setup, development, limitations, and document index. |
| `LICENSE` | Required for a public source repository. Publish only an explicitly selected license with the correct copyright holder. |
| `CHANGELOG.md` | Required for versioned or release-oriented products. Use Keep a Changelog and Semantic Versioning where they actually apply. |
| `CONTRIBUTING.md` | Recommended. Keep setup, checks, privacy rules, and pull-request expectations project-specific. |
| `PRIVACY.md` | Required when the product handles user data, external services, broad permissions, accounts, media, history, or local persistence. |
| `SECURITY.md` | Required. Define supported versions, a private report route, sanitization rules, and security boundaries. |
| `TERMS_OF_USE.md` | Recommended for end-user products; required when external services, user content, downloads, or potentially sensitive capabilities are involved. |
| `THIRD_PARTY_NOTICES.md` | Required when runtime code, models, fonts, media, downloaded assets, or other licensed components are included or fetched. |
| `.github/FUNDING.yml` | Required for public QenTerra products. Contains only the approved Buy Me a Coffee custom URL. |

`CODE_OF_CONDUCT.md`, `SUPPORT.md`, and additional funding-provider files are
optional. Add them only when the project has a real policy or support route to
document.

## README information architecture

Use this order for both README profiles:

1. Hero: icon, product name, one-line description, truthful badges, short links.
2. Product summary and distribution/status notice.
3. Interface: real built UI using isolated synthetic fixtures.
4. Capabilities: user outcomes, grouped by task.
5. Get started: download/install for published products, build from source for
   source-only products.
6. How it works: only when the data flow helps the user understand safety,
   privacy, or limitations.
7. Permissions and privacy: capability-to-purpose mapping and links to full
   policy documents.
8. Development: reproducible setup and one canonical verification command.
9. Architecture or project structure: compact summary plus a link to details.
10. Current limitations and verification gaps.
11. Documentation index.
12. Contributing, support, and license.

The README is a map, not a second copy of every guide. Detailed build steps,
dependency update procedures, troubleshooting, and release runbooks belong in
their dedicated documents.

## Code quality

Every repository adopts the applicable QDS Code System language profile and names one canonical verification command. Code must remain understandable to a developer new to the module: its role, dependencies, effects, failures, and verification path are visible through boundaries, names, tests, or focused comments. Keep UI, domain policy, storage, network, and platform effects at explicit boundaries. Do not mix unrelated formatting churn with behavioral changes.

Follow the QDS development lifecycle from a sourced problem through operation and retirement. Use the QDS commit standard for atomic history and breaking-change notes. A repository may narrow allowed scopes, but it must not redefine commit types with conflicting meanings.

Record a rule exception with its exact rule and path, technical reason, owner, and review date. Pull requests separate automated checks, live checks, and manual gaps; a green static check never substitutes for a real platform boundary.

## Technical documentation

Non-trivial repositories should provide:

| File | Purpose |
| --- | --- |
| `docs/README.md` | Public documentation index and audience map. |
| `docs/BUILDING.md` | Clean-checkout setup, source of truth, build, verification, and local-only paths. |
| `docs/ARCHITECTURE.md` | Runtime flow, component boundaries, persistence, concurrency, security, and generation rules. |
| `docs/DEPENDENCIES.md` | Runtime versus development dependencies, version policy, licenses, sources, and update procedure. |
| `docs/TROUBLESHOOTING.md` | Symptom-first recovery steps that do not weaken security or integrity checks. |

Product design or brand documents are optional public contributor documents.
Implementation plans and completed remediation specifications stay in the
private work knowledge base.

## GitHub Wiki

Published QenTerra products use a native GitHub Wiki as the user-guide layer.
The common core is `Home.md`, `_Sidebar.md`, `Getting-Started.md`,
`Feature-Overview.md`, `Privacy-and-Security.md`, and `Troubleshooting.md`.
Sidebar groups appear in the order `Use`, `Understand`, `Build`, and `Policies`.

Wiki does not duplicate root legal files or complete contributor guides. It
links to their canonical versions in the main repository. Images remain under
main `docs/images/` and are embedded with absolute raw GitHub URLs. Buy Me a
Coffee remains limited to README and `.github/FUNDING.yml`.

## Naming and style

- Repository-authored documentation is English.
- Use sentence case for headings.
- Use `# Privacy Policy`, `# Security Policy`, `# Terms of Use`, and
  `# Third-party notices` consistently.
- Use ISO dates: `**Effective date:** YYYY-MM-DD`.
- Use `THIRD_PARTY_NOTICES.md` and `TERMS_OF_USE.md` across all repositories.
- Use relative links for repository files and meaningful alt text for images.
- Use `sh` for portable shell snippets unless Bash-specific syntax is required.
- Use direct, factual copy. Avoid unverified superlatives, roadmap promises,
  fake metrics, and badges that do not resolve to a real source.
- State source-only, unsigned, unnotarized, prerelease, or store-review status
  near the top of the README.
- Render the canonical product icon at 128 px and place the Buy Me a Coffee
  badge last in the hero badge row.

## Privacy and legal source-of-truth checks

Before changing legal documents, inspect:

- application entitlements or extension permissions;
- network clients, external services, and explicit browser-opening actions;
- local storage paths, retention bounds, deletion behavior, and account actions;
- runtime, downloaded, bundled, and build-only dependencies;
- model, media, font, and website-script licenses;
- release archives, not just source manifests.

Apply the QDS license standard to the resolved dependency graph and the shipped artifact. Record SPDX identifiers, required notices, source offers, asset restrictions, and license compatibility. System-provided platform artwork is not a reusable project asset.

Do not state that data “never leaves the device” when an operating-system sync
provider or required external service can process it. Name that boundary.

## Drift protection

Every repository validation command should check, at minimum:

- all local Markdown and HTML links resolve;
- no unresolved template marker remains outside the template tree;
- README version, supported security range, archive names, and changelog agree
  with the canonical version source;
- every direct runtime dependency appears in `THIRD_PARTY_NOTICES.md`;
- declared permissions or entitlements appear in the privacy documentation;
- referenced screenshots exist under `docs/images/`;
- internal plan directories and machine-specific paths are absent from the
  public tree.
- Funding YAML contains only `https://buymeacoffee.com/qenterra`;
- every Wiki page is covered by `_Sidebar.md`, internal links omit `.md`, and
  raw screenshot URLs resolve.

Allow explicit synthetic test paths and small product icons. A validator that
reports known fixtures as privacy leaks or icons as screenshots needs scoped
allowlists; otherwise people learn to ignore it, which is how useful gates die.

## Change synchronization

| Change | Documents to review |
| --- | --- |
| User-visible behavior | README, changelog, screenshots, troubleshooting |
| Permission, entitlement, network, storage, or retention | README, privacy, security, terms |
| Dependency or model | dependency guide, notices, license texts, build guide |
| Supported OS, browser, IDE, or toolchain | README, building, contributing, CI |
| Distribution or release status | README, changelog, security support table, release links |
| Architecture or persistence boundary | architecture, security, contributing source-of-truth rules |
| New external service | README, privacy, terms, security, notices when applicable |

## Verification vocabulary

Use these labels consistently:

- **Automated:** lint, format, unit tests, builds, link checks, manifest checks.
- **Live:** exercised in the built product with the real operating-system or
  service boundary.
- **Manual gap:** still requires hardware, account, permission, accessibility,
  visual, store, or external-service acceptance.

Never compress all three into “tested.” That word has buried enough context.

## Applying templates

The files under `templates/repository/` are starting points, not blind copy targets. Select the smallest set that matches the repository type, replace every placeholder, remove irrelevant sections, and verify every claim against the current implementation before committing.

Use `templates/repository/readme/` for the repository class, `root/` for canonical policy and legal files, `docs/` for technical documentation, `github/` for repository-hosting metadata, and `wiki/` for optional long-form product guidance. The standard remains authoritative when a template and the rules appear to disagree.
