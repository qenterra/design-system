# License standard

## Scope

Review licenses for source, binaries, packages, models, fonts, icons, images, audio, video, datasets, documentation, generated output, and downloaded runtime content. A package-manager manifest covers only the package fields it declares.

This guide supports engineering review and does not replace legal advice.

## Choose the project license

Select a license before public distribution. Record the exact SPDX identifier, copyright holder, year policy, patent terms, source-disclosure duties, and compatibility with bundled dependencies. `UNLICENSED` or a proprietary notice must state that no redistribution permission is granted.

Do not copy a license from another repository because its product looks similar. Public source availability does not grant an open-source license.

## Dependency review

For each direct runtime and build dependency, record name, pinned or resolved version, source, SPDX identifier, copyright notice, use, delivery form, and update owner. Inspect transitive dependencies when the artifact bundles them or their license imposes notice or source duties.

Block packages with missing terms, incompatible copyleft obligations, non-commercial restrictions that conflict with distribution, or an unverifiable source.

## Assets, models, and data

Record creator, source, license, modifications, attribution text, territory or platform restrictions, and whether the artifact may be redistributed. Separate a tool license from the output license.

System-provided SF Symbols remain Apple assets. Use system APIs in Apple-platform software. Do not use SF Symbols in app icons, logos, trademarks, or a general web icon package. Generated QDS previews belong to the local macOS application prototype and are not reusable source artwork.

## SPDX and file metadata

Use standard SPDX identifiers in manifests. Add `SPDX-License-Identifier` headers only when repository policy or the selected license calls for per-file headers. Do not change third-party copyright or license text.

Generated files name their generator and inherit the license of the source and generator unless another binding term applies. Vendored files keep upstream notices and a source URL.

## Notices and source offers

`THIRD_PARTY_NOTICES.md` lists shipped or fetched third-party material and reproduces required notices. Include full license texts when terms require them. Provide a source offer, modification notice, relinking material, or attribution UI when the applicable license requires it.

Keep notices reachable in the distributed artifact. A repository file that never ships does not satisfy an in-app or installer notice duty.

## Compatibility decisions

Review compatibility between the project license and each combined, linked, bundled, or modified work. Treat plugins, dynamic libraries, models, and datasets according to their terms and delivery. Record uncertain or high-impact decisions in an ADR and obtain qualified review before release.

## Release gate

Before release:

1. Generate or audit the dependency inventory from the resolved graph.
2. Compare the shipped artifact with the notice inventory.
3. Verify license files, SPDX metadata, attribution, source offers, and asset restrictions.
4. Scan archives for untracked fonts, media, models, and vendored code.
5. Record reviewer, date, command, artifact digest, and unresolved legal questions.

## Removal and updates

Removing a dependency also removes unused code, binaries, notices, source offers, and cached downloadable artifacts where policy permits. An update repeats compatibility and notice review; a familiar package can change license between versions.
