# Third-party notices

{PROJECT_NAME} is distributed under the [{FIRST_PARTY_LICENSE}](LICENSE). The
following third-party components retain their own copyright, license,
trademark, and attribution requirements.

## Components included in the product

| Component | Version or revision | Role | License | Copyright / attribution | Source | Local license text |
| --- | --- | --- | --- | --- | --- | --- |
| `{RUNTIME_COMPONENT}` | `{PIN}` | {ROLE} | `{SPDX_IDENTIFIER}` | {ATTRIBUTION} | [{SOURCE_LABEL}]({SOURCE_URL}) | [`{LICENSE_PATH}`]({LICENSE_PATH}) |

Explain whether each component is linked, bundled, compiled into an artifact,
loaded at runtime, or otherwise distributed with the product.

## Downloaded models or assets

| Asset | Immutable revision | Role | License | Attribution | Source | License text |
| --- | --- | --- | --- | --- | --- | --- |
| `{MODEL_OR_ASSET}` | `{PIN}` | {ROLE} | `{SPDX_OR_LICENSE_NAME}` | {ATTRIBUTION} | [{SOURCE_LABEL}]({SOURCE_URL}) | [{LICENSE_LABEL}]({LICENSE_URL_OR_LOCAL_PATH}) |

State who initiates the download, whether the asset is bundled, how integrity
is verified, and whether its license restricts commercial use or redistribution.

## Platform components

{APPLE_FRAMEWORKS_BROWSER_APIS_SYSTEM_LIBRARIES_OR_OTHER_PLATFORM_COMPONENTS}
are provided under the terms of their respective platforms and are not
relicensed by {PROJECT_NAME}.

## Development and build tools

| Tool | Version policy | Role | License | Source |
| --- | --- | --- | --- | --- |
| `{BUILD_TOOL}` | {PINNED_OR_RESOLVED_POLICY} | {ROLE} | `{SPDX_IDENTIFIER}` | [{SOURCE_LABEL}]({SOURCE_URL}) |

Development tools are not included in the published runtime artifact unless
explicitly listed above as included components.

## Website and documentation dependencies

| Component | Version | Role | License | Source |
| --- | --- | --- | --- | --- |
| `{SITE_SCRIPT_FONT_OR_MEDIA}` | `{PIN}` | {ROLE} | `{LICENSE}` | [{SOURCE_LABEL}]({SOURCE_URL}) |

Remove this section when the project has no separate public website runtime or
licensed documentation asset.

## Reproducibility and updates

The authoritative dependency inputs are {MANIFESTS_LOCKFILES_PIN_METADATA_AND_LOCAL_LICENSE_PATHS}.

When a dependency changes, review its source, version, checksum when available,
license text, notices, generated artifact, runtime contents, privacy/security
impact, and verification evidence together.
