# GitHub settings and verification

## Expected settings

- Repository: `https://github.com/QenTerra/design-system`; visibility: public; default branch: `main`.
- Issues enabled; Projects, Wiki, and Discussions disabled.
- Squash merge enabled; merge commits and rebase merge disabled; merged branches deleted automatically.
- Active ruleset `Protect main` (`21957951`) requires pull requests, the `repository-governance` and `verify` checks, conversation resolution, and linear history while rejecting deletion and non-fast-forward updates on the default branch.
- Active ruleset `Protect release tags` (`21957952`) rejects deletion and replacement of tags matching `v*`; neither ruleset has a bypass actor.
- Workflows have read-only default permissions, pinned actions, and no persistent checkout credentials.
- Dependabot alerts and security updates, secret scanning, push protection, and private vulnerability reporting are enabled.

## Verification record

| Checked at | Evidence source | Reviewer | Result | Remaining boundary |
| --- | --- | --- | --- | --- |
| 2026-08-31T21:00:23Z | GitHub REST API plus unauthenticated Git read-back | Nikita Melnychenko (`@qenterra`) | Public visibility, Apache-2.0 license detection, metadata, repository features, merge settings, read-only workflow permissions, security features, private vulnerability reporting, main protection, release-tag immutability, and anonymous access verified | Code scanning and registry publication remain release-specific checks when those surfaces are used. |

Recheck this record after a visibility, plan, ownership, default-branch, workflow, release, or repository-feature change. Repository files express intent; only live provider read-back proves current settings.
