# Security Policy

## Supported versions

{RELEASE_OR_SOURCE_ONLY_SUPPORT_STATEMENT}

| Version | Supported |
| --- | --- |
| {CURRENT_RELEASE_RANGE_OR_MAIN} | Yes |
| {OLDER_RELEASES_FORKS_OR_UNOFFICIAL_BUILDS} | {NO_OR_NO_GUARANTEE} |

## Reporting a vulnerability

Do not disclose a suspected vulnerability in a public issue. Use
[GitHub private vulnerability reporting](https://github.com/{OWNER}/{REPOSITORY}/security/advisories/new).
If that route is unavailable, use {PRIVATE_FALLBACK_CONTACT_ROUTE}.

Include, when available:

- the affected version, commit, build, browser, or operating system;
- reproduction steps and expected impact;
- the affected permission, storage, network, file, account, or protocol boundary;
- a minimal synthetic fixture.

Never include {PROJECT_SPECIFIC_SECRET_AND_PRIVATE_DATA_LIST}.

Reports will be assessed privately before coordinated disclosure when feasible.
{BUG_BOUNTY_STATEMENT_IF_NEEDED}

## Security boundaries

{PROJECT_NAME}'s security boundaries include:

- {CREDENTIAL_OR_ACCOUNT_BOUNDARY};
- {SANDBOX_PERMISSION_OR_HOST_ACCESS_BOUNDARY};
- {PATH_PROTOCOL_MESSAGE_OR_INPUT_VALIDATION_BOUNDARY};
- {PERSISTENCE_IMPORT_EXPORT_OR_CONFLICT_BOUNDARY};
- {DEPENDENCY_PINNING_OR_REMOTE_CODE_BOUNDARY};
- {TEST_FIXTURE_ISOLATION_OR_LOG_REDACTION_BOUNDARY}.

These controls reduce risk but do not make {UNTRUSTED_CONTENT_OR_EXTERNAL_INPUT}
trustworthy. {SAFE_USER_GUIDANCE}

## Dependency vulnerabilities

If a report originates in {RUNTIME_DEPENDENCIES_OR_PLATFORM_FRAMEWORKS}, report
the {PROJECT_NAME} impact privately. A fix may require an upstream update,
integration change, mitigation, or documentation change.

See [Dependencies](docs/DEPENDENCIES.md) and
[Third-party notices](THIRD_PARTY_NOTICES.md).
