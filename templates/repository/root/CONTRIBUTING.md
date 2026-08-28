# Contributing

{PROJECT_NAME} accepts {ACCEPTED_CONTRIBUTION_SCOPE}.

## Before opening an issue

- Search existing issues and releases.
- Reproduce the problem on {SUPPORTED_RELEASE_OR_MAIN}.
- Include {RELEVANT_ENVIRONMENT_DETAILS} and exact reproduction steps.
- Replace account data, filenames, paths, media, page content, and credentials
  with synthetic values.
- Report vulnerabilities through the private route in [SECURITY.md](SECURITY.md).

## Local setup

Follow [Building from source](docs/BUILDING.md):

```sh
{SETUP_COMMANDS}
```

## Source-of-truth rules

- `{CONFIGURATION_FILE}` defines {WHAT_IT_DEFINES}.
- {ARCHITECTURE_INVARIANT}
- {DATA_OR_FILESYSTEM_INVARIANT}
- {PRIVACY_OR_SECURITY_INVARIANT}
- Product UI, accessibility text, documentation, source comments, tests, and
  commits are English.

## Required checks

```sh
{CANONICAL_VALIDATION_COMMAND}
git diff --check
```

Automated checks cover {AUTOMATED_SCOPE}. Changes involving
{MANUAL_BOUNDARIES} require live or manual acceptance and must report any gap.

## Code quality

- Code must be understandable to a developer unfamiliar with the module: make the unit's role, dependencies, effects, failures, and verification path visible through names, boundaries, tests, or focused comments.
- Follow the adopted Design System language profile and existing local formatter; do not combine unrelated reformatting with behavioral changes.
- Keep UI, domain policy, storage, network, and platform effects at explicit boundaries.
- Record an exception with its rule, path, technical reason, owner, and review date.

## Dependency changes

A runtime dependency, model, browser script, or bundled asset update must also
update:

1. the canonical dependency manifest or lockfile;
2. [Dependencies](docs/DEPENDENCIES.md);
3. [Third-party notices](THIRD_PARTY_NOTICES.md) and local license texts;
4. privacy, security, or terms when behavior or data flow changes;
5. the relevant build, test, and live acceptance evidence.

## Pull requests

- Keep one coherent problem per pull request.
- Add regression coverage for behavior changes.
- Include before and after screenshots for visible UI changes.
- Update public documentation when behavior, requirements, dependencies,
  permissions, storage, distribution, or privacy changes.
- Explain user-visible behavior, risks, automated checks, live checks, and
  remaining manual gaps.
- Keep unrelated formatting and generated changes out of the patch.

## Commits

- Use `type(optional-scope): imperative outcome` with a Design System commit type.
- Keep one reviewable change per commit and include its tests and generated counterparts.
- Mark consumer migrations with `!` and a `BREAKING CHANGE:` footer.
- Inspect the staged diff and run the smallest complete gate before committing.

## License review

Before adding code, a package, model, font, icon, image, dataset, or downloaded artifact, record its source, version, SPDX identifier or exact terms, delivery form, attribution, and redistribution limits. Update `THIRD_PARTY_NOTICES.md` and any required license texts in the same change.

By contributing, you agree that your contribution can be distributed under
the project's [license](LICENSE).
