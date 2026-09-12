<!-- Follow CONTRIBUTING.md and docs/RELEASE_WRITING.md. Complete required fields and remove optional empty sections. -->

## Purpose

Describe the problem, trigger, and observable outcome in plain English unless the project selects another language. Use sentence case, concrete facts, and no decorative headings. Rewrite this description to match the final diff before review.

## Scope

- Included:
- Excluded:
- Affected design or code boundary and why it remains understandable:
- Exceptions: rule, path, technical reason, owner, and review date; or none.

## Verification

List the exact commands and manual checks run on this head commit. State what they do not prove.

- [ ] `DESIGN_SYSTEM_IMAGE_PYTHON=.venv/bin/python python3 scripts/verify.py`
- [ ] Relevant npm and SwiftPM consumer surfaces inspected
- [ ] Applicable live platform, service, permission, and consumer checks completed
- [ ] Remaining manual gaps named explicitly

## Evidence

Attach screenshots, recordings, benchmark data, logs, or provider links only when they are safe and relevant. Name the build, fixture, and environment.

For interface changes, include before and after screenshots from isolated synthetic fixtures.

## Risk and recovery

- Failure modes:
- Data or migration impact:
- Security or privacy impact:
- Rollback or recovery:

## Documentation and release

- Documentation changed:
- Changelog entry:
- Version or release impact:
- Dependency or license impact:
- Bilingual normative references, generated documentation, and version alignment:

## Checklist

- [ ] The title follows the repository’s Conventional Commit grammar.
- [ ] The diff contains one coherent outcome and no unrelated changes.
- [ ] Tests or checks cover mechanically observable behaviour.
- [ ] User-visible, API, operational, privacy, and security changes are documented.
- [ ] No credentials, personal data, private paths, signing material, or unreviewed generated artifacts are included.
- [ ] External or manual checks that remain unverified are named explicitly.
