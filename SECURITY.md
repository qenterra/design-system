# Security Policy

## Supported versions

Security fixes are applied to the current `main` branch and, when package
consumers are affected, released as a new immutable version.

| Version | Supported |
| --- | --- |
| Current `main` and latest package release | Yes |
| Older releases, forks, and unofficial distributions | No guarantee |

## Reporting a vulnerability

Do not disclose a suspected vulnerability in an issue. Use
[GitHub private vulnerability reporting](https://github.com/qenterra/design-system/security/advisories/new).
If that route is unavailable, do not move the report to a public issue or a
general support mailbox. Wait for the private route to recover or contact the
maintainer through an already established private channel without including
exploit details in the initial message.

Include, when available:

- the affected version, commit, package, workflow, or platform;
- reproduction steps and expected impact;
- the affected generation, package, credential, path, content, or dependency
  boundary;
- a minimal synthetic fixture.

Never include credentials, deploy keys, package tokens, private consumer source,
customer data, or production content. Reports are assessed privately before
coordinated disclosure when feasible. QenTerra does not currently operate a bug
bounty program.

## Security boundaries

The repository treats these as explicit security boundaries:

- repository and package-publication access;
- least-privilege release and consumer credentials;
- immutable version tags and fail-closed package payload allowlists;
- generated-output provenance and deterministic source generation;
- Git LFS coverage and manifest integrity for canonical brand assets;
- synthetic fixtures and redacted diagnostic evidence.

Verification reduces risk but does not make untrusted contributions, package
contents, images, HTML, or consumer input trustworthy. Review sources and
generated diffs before release.

## Dependency vulnerabilities

Report the Design System impact privately even when the root cause is in a platform,
browser, package manager, or development dependency. A fix may require an
upstream update, integration change, mitigation, or documentation change. See
[Dependencies](docs/DEPENDENCIES.md).
