# Building from source

This guide builds {PROJECT_NAME} from a clean checkout. {DISTRIBUTION_STATUS}

## Supported development environment

- {SUPPORTED_HARDWARE_OR_BROWSER}
- {OPERATING_SYSTEM_AND_MINIMUM_VERSION}
- {IDE_RUNTIME_AND_PACKAGE_MANAGER_VERSIONS}
- {OTHER_REQUIRED_TOOLS_OR_ACCOUNTS}

## 1. Clone

```sh
git clone https://github.com/{OWNER}/{REPOSITORY}.git
cd {REPOSITORY}
```

## 2. Install development tools

```sh
{DEPENDENCY_INSTALL_COMMAND}
```

{EXPLAIN_WHICH_VERSIONS_ARE_PINNED_AND_WHICH_ARE_ENVIRONMENT_RESOLVED}

## 3. Provide external runtime inputs

{MODELS_SDKS_FRAMEWORKS_BROWSER_BINARIES_OR_NONE}

Verify source, revision, checksum, architecture, and license metadata before
accepting a generated or downloaded artifact.

## 4. Generate or configure the project

```sh
{PROJECT_GENERATION_OR_CONFIGURATION_COMMAND}
```

`{CONFIGURATION_SOURCE}` is the source of truth. {GENERATED_PROJECT_POLICY}

## 5. Build and run

```sh
{DEVELOPMENT_BUILD_OR_OPEN_COMMAND}
```

{FIRST_RUN_SETUP_WITHOUT_SECRETS}

## Verification

```sh
{CANONICAL_VERIFICATION_COMMANDS}
```

The automated gate covers {AUTOMATED_SCOPE}. Live validation covers
{LIVE_SCOPE}. Manual acceptance remains for {MANUAL_GAPS}.

## Generated and local-only paths

Do not commit:

- `{GENERATED_PATH}`;
- `{CACHE_OR_BUILD_PATH}`;
- `{LOCAL_ACCOUNT_OR_DATABASE_PATH}`;
- credentials, certificates, private keys, profiles, sessions, or real user
  fixtures.

See the project's `.gitignore`, [Security](../SECURITY.md), and
[Dependencies](DEPENDENCIES.md).
