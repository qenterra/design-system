# Dependencies

This document separates components that ship with {PROJECT_NAME}, assets that
are downloaded after installation, platform components, and development tools.

## Version policy

- {RUNTIME_PIN_POLICY}
- {LOCKFILE_OR_REVISION_POLICY}
- {GENERATED_ARTIFACT_POLICY}
- {PLATFORM_SDK_POLICY}
- {DEVELOPMENT_TOOL_POLICY}

State plainly which parts are reproducible and which are environment-resolved.

## Runtime and included components

| Component | Version or revision | Role | License | Source |
| --- | --- | --- | --- | --- |
| `{COMPONENT}` | `{PIN}` | {ROLE} | `{SPDX_IDENTIFIER}` | [{SOURCE_LABEL}]({SOURCE_URL}) |

## Downloaded models or assets

| Asset | Immutable revision | Integrity | License | Source |
| --- | --- | --- | --- | --- |
| `{ASSET}` | `{PIN}` | `{SIZE_AND_SHA256_OR_EQUIVALENT}` | `{LICENSE}` | [{SOURCE_LABEL}]({SOURCE_URL}) |

Remove this section when the product never downloads licensed runtime assets.

## Platform components

| Component | Version policy | Role | Terms |
| --- | --- | --- | --- |
| `{SDK_FRAMEWORK_OR_BROWSER_API}` | {PLATFORM_POLICY} | {ROLE} | {PLATFORM_TERMS} |

## Development and build tools

| Tool | Version policy | Role | License | Source |
| --- | --- | --- | --- | --- |
| `{TOOL}` | {PINNED_OR_RESOLVED} | {ROLE} | `{SPDX_IDENTIFIER}` | [{SOURCE_LABEL}]({SOURCE_URL}) |

## Updating dependencies

Do not change a version string in isolation.

1. Review the upstream release or source revision.
2. Update the canonical manifest, lockfile, or pin metadata.
3. Review and update the matching local license text and attribution.
4. Rebuild or redownload artifacts from the reviewed source and verify
   checksums, architectures, and package contents.
5. Update this document and [Third-party notices](../THIRD_PARTY_NOTICES.md).
6. Review privacy, security, terms, and permissions for behavior changes.
7. Run the full automated gate and relevant live acceptance.
