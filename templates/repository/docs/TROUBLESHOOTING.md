# Troubleshooting

Start with the canonical verification command:

```sh
{CANONICAL_VERIFICATION_COMMAND}
```

It checks {AUTOMATED_SCOPE}.

## {SYMPTOM_OR_EXACT_ERROR}

{LIKELY_CAUSE_IN_PLAIN_LANGUAGE}

```sh
{SAFE_DIAGNOSTIC_OR_RECOVERY_COMMAND}
```

{WHAT_THE_COMMAND_CHANGES_AND_WHAT_IT_DOES_NOT_CHANGE}

## {DEPENDENCY_OR_GENERATED_ARTIFACT_IS_MISSING}

{REBUILD_OR_INSTALL_FROM_THE_CANONICAL_SOURCE}. Do not bypass source, revision,
checksum, architecture, signature, or license validation.

## {PERMISSION_OR_ACCOUNT_PROBLEM}

- {SAFE_RECOVERY_STEP}
- {SAFE_RECOVERY_STEP}
- {PRIVATE_DATA_WARNING}

Do not weaken sandbox, host permissions, path containment, content isolation,
credential storage, or integrity checks as a troubleshooting shortcut.

## {DATA_FILE_OR_CONFLICT_PROBLEM}

{EXPLAIN_SAFE_DEFAULT_RECOVERY_AND_BACKUP_BOUNDARY}

## Reporting a problem

Use [CONTRIBUTING.md](../CONTRIBUTING.md) for the issue checklist and
[SECURITY.md](../SECURITY.md) for private vulnerability reports. Replace real
accounts, content, filenames, paths, credentials, and logs with synthetic data.
