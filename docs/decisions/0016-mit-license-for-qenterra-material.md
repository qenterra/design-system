# 0016: MIT license for QenTerra material

Status: accepted

Date: 2026-09-02

## Context

The public canonical repository and its `1.0.0` packages were released under Apache-2.0. The project now needs a shorter, broadly recognized permissive license while keeping third-party catalogs under their original terms and preserving the immutable `1.0.0` record.

## Decision

License QenTerra-authored repository and package material under the MIT License from version `1.0.1` onward. Remove first-party Apache `NOTICE` files, declare the SPDX identifier `MIT` in package and repository metadata, and keep third-party licenses, notices, authorship, and provenance unchanged.

Do not rewrite the `v1.0.0` tag, its GitHub Release, its npm artifact, or the changelog statement that records Apache-2.0 as the license used for that release.

## Consequences

- Consumers of `1.0.1` and later receive the MIT License for QenTerra-authored material.
- Third-party source catalogs remain outside the QenTerra license and retain their original terms.
- Existing Apache-2.0 releases remain immutable historical artifacts.
- QenTerra names, marks, and product identities are not licensed by the software license.
