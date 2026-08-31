# Security

## Supported versions

| Release line | Supported | End of support | Evidence |
| --- | --- | --- | --- |
| `5.x` | Yes | Until `6.0.0` is published | Current tags, package metadata, and release manifest |
| `< 5.0.0` | No | 2026-08-28 | Changelog and release history |

Only the latest patch release in a supported line receives fixes unless a security advisory states otherwise.

## Report a vulnerability

Report vulnerabilities through [GitHub private vulnerability reporting](https://github.com/QenTerra/design-system/security/advisories/new). Do not open a public issue with exploit details, secrets, personal data, signing material, private source, or vulnerable production information.

Include the affected version or commit, environment, expected impact, reproduction steps, and the smallest safe proof of concept. Redact credentials, personal paths, user content, and unrelated logs.

## Response targets

| Stage | Target | Starts when | Evidence |
| --- | --- | --- | --- |
| Acknowledgement | Three business days | A complete report reaches the private route | Private acknowledgement |
| Initial assessment | Seven business days | Safe reproduction material is available | Severity and affected-version record |
| Coordination update | Every fourteen calendar days | A fix or disclosure remains open | Private status update |

These are good-faith operational targets, not a bounty, warranty, or disclosure deadline. Complex upstream or ecosystem coordination can take longer; delays are communicated through the private report.

## Security boundaries

- The public tree is closed by `release-manifest.json`; undeclared files fail verification.
- Published distribution artifacts and generated Swift adapters have complete maintained-source and output hashes and must byte-match regeneration in an external temporary directory.
- Caches, build trees, credentials, personal data, and repository-internal operational material are forbidden.
- GitHub Actions run with read-only default permissions and pinned action commits.
- Published versions and tags are immutable; repairs use a new version.

Local verification reduces risk but does not prove registry integrity, consumer behavior, platform rendering, or the absence of vulnerabilities in external toolchains.
