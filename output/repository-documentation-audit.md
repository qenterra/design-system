# Documentation Audit: Cadence, Lilt, Elements, and Unspool

Audit date: 2026-08-01

This review records the baseline local checkouts before the family migration.
Its weaknesses intentionally describe the pre-migration state, not the files
after implementation. GitHub settings and Wikis were audited separately during
the approved rollout.

## Coverage matrix

| Area | Cadence | Lilt | Elements | Unspool |
| --- | --- | --- | --- | --- |
| User-first README | Strong | Partial | Strong | Strong |
| Real/synthetic product screenshots | Yes, clearly disclosed | None | Yes | Yes, clearly disclosed |
| Distribution status | Clear source-only notice | Indirect and implementation-heavy | Clear release/download path | Clear source-only notice |
| Build and verification | README plus build guide | Verification command only | Detailed README and scripts | README plus build guide |
| Architecture guide | Dedicated | Product/design specs instead | Inline README summary | Dedicated with runtime diagram |
| Dependency guide | Dedicated | Notices only | Notices plus lockfile | Dedicated with pin policy |
| Privacy, terms, security | Complete set | Missing | Complete set | Complete and service-aware set |
| License | MIT | Missing | MIT | MIT |
| Changelog and contributing | Both | Missing | Both | Both |
| Documentation drift checks | No repository-local link/legal gate found | English-only guard, no doc suite gate | Strong `verify:docs` gate | No repository-local link/legal gate found |
| Public/private separation | One internal remediation spec remains public | Many plans and remediation specs remain public | Strongest separation | One internal remediation spec remains public |

## Cadence

### Strengths

- Best concise native-app README: polished hero, explicit source-only status,
  synthetic screenshot disclosure, user-oriented capabilities, and a compact
  project map.
- Complete public root suite: license, changelog, contributing, privacy, terms,
  security, and third-party notices.
- Separate architecture, building, dependencies, troubleshooting, and UI
  system documents make the README useful without forcing it to become the
  entire manual.
- Privacy and security claims are specific to the managed local library,
  sandbox, imported media, and recoverable Trash behavior.

### Weaknesses

- Version, toolchain, and CI limitations are repeated across README,
  contributing, and build docs without a repository-local consistency check.
- Legal headings and dates do not match the newer Elements/Unspool conventions.
- `docs/superpowers/specs/` exposes an internal remediation design in the
  public tree.
- The repository has CI for generation and lint, but no local-link,
  placeholder, legal-file, or dependency-notice validation.

## Lilt

### Strengths

- The documentation is unusually honest about automated checks, live checks,
  and remaining acceptance gaps.
- Product decisions, accessibility states, benchmarks, and model licensing are
  documented with more evidence than the other projects.
- Third-party notices correctly distinguish FluidAudio from the explicitly
  downloaded Parakeet model and explain that model assets are not bundled.
- The English-only repository guard has negative tests, so at least one
  documentation policy is actually enforced.

### Weaknesses

- The public root suite is incomplete: `LICENSE`, `CHANGELOG.md`,
  `CONTRIBUTING.md`, `PRIVACY.md`, `SECURITY.md`, and `TERMS_OF_USE.md` are
  absent.
- The README is an implementation/status memo rather than a durable product
  entry point: no hero, screenshots, installation path, permission map,
  architecture summary, contribution route, support route, or license.
- Snapshot wording such as “automated checks pass” becomes stale immediately;
  the latest commits already describe capabilities beyond the README summary.
- Public `docs/plans/`, `docs/superpowers/specs/`, and mock-output references
  mix current user/contributor documentation with internal delivery history.
- There is no canonical marketing/build version in `project.yml`, which makes
  release documentation harder to validate from one source.

## Elements

### Strengths

- Best user/release README: clear screenshots, download/install steps,
  permission explanations, browser scope, architecture, and release commands.
- Strongest repository-local documentation automation. `verify:docs` checks
  local links, the current release archive, supported security version, and
  direct dependency notices.
- Complete legal suite with a detailed browser-storage and sync boundary.
- Third-party notices distinguish runtime, development, and GitHub Pages
  dependencies with versions, licenses, attribution, and sources.
- Public/internal separation is the cleanest of the four repositories.

### Weaknesses

- Build, architecture, troubleshooting, and dependency policy are concentrated
  in README or notices rather than discoverable dedicated guides.
- `SECURITY.md` is too thin for an extension with broad host access, scripting,
  custom CSS, storage, import/export, and a runtime message protocol.
- Versioned archive links and support tables are intentionally duplicated; the
  validator controls the drift, but each release still requires synchronized
  edits.
- The shared public-repository validator misclassifies the 128 px product icon
  as an invalid screenshot, so the common gate needs an icon allowlist.

## Unspool

### Strengths

- Most complete native-app documentation system: strong README, full legal
  suite, architecture diagram, build guide, dependency pinning, troubleshooting,
  brand/interface guide, and a Wiki entry point.
- Best privacy document. It names Telegram as a required external service,
  inventories handled data, maps storage and retention, explains account
  actions, and separates downloaded files from application data.
- Best dependency/notices pairing: exact TDLib revision, OpenSSL version and
  checksum, local license texts, bundled versus development components, and a
  coordinated update procedure.
- README screenshots explicitly use isolated synthetic Telegram fixtures and
  explain that no personal session is opened.
- Contributor rules preserve the core product contract instead of merely
  listing formatting commands.

### Weaknesses

- The 287-line README duplicates substantial build, architecture, privacy, and
  troubleshooting detail that already has dedicated documents.
- `docs/superpowers/specs/` still contains an internal remediation document,
  despite the public tree otherwise being carefully cleaned.
- There is no repository-local documentation/link validation or GitHub issue
  and pull-request template set.
- The MIT copyright line omits `(QenTerra)`, unlike Cadence and Elements.
- The shared public-repository validator flags `/Users/example` in a synthetic
  test fixture; the gate needs an explicit fixture-path allowlist.

## Recommended baseline

Use Unspool's privacy, dependency, and security depth; Cadence's shorter native
README; Elements' release/install flow and documentation automation; and Lilt's
explicit separation of automated, live, and not-yet-verified evidence.

Do not copy any one repository wholesale. Each one is excellent at a different
part and mildly cursed at another.

## Migration outcome

The approved rollout addressed the shared presentation and documentation gaps:

- all four READMEs now use the family hero, navigation, section order, support,
  and funding treatment;
- all four repositories have the canonical Funding file;
- Lilt gained the missing root policy suite and contributor-facing technical
  documentation under the family-default MIT license;
- Elements gained dedicated technical guides and stronger security boundaries;
- Cadence, Unspool, and Elements Wikis use the common core and sidebar groups,
  were published without rewriting history, and were read back from GitHub;
- Lilt's Wiki core is prepared but remains unpublished because the local
  repository has no canonical public remote.

Remaining structural work includes moving internal plans out of public trees
before future publication passes and adding scoped fixture/icon allowlists to
the shared validator.
