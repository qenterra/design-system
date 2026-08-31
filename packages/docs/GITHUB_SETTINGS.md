# GitHub settings and verification

## Expected settings

- Repository: `https://github.com/QenTerra/design-system`; visibility: public; default branch: `main`.
- Issues enabled; Projects, Wiki, and Discussions disabled.
- Squash merge enabled; merge commits and rebase merge disabled; merged branches deleted automatically.
- Ruleset `Protect main` requires pull requests, the `repository-governance` and `verify` checks, conversation resolution, and linear history while rejecting deletion and non-fast-forward updates on the default branch.
- Ruleset `Protect release tags` rejects deletion and replacement of tags matching `v*`; neither ruleset has a bypass actor.
- Workflows have read-only default permissions, pinned actions, and no persistent checkout credentials.
- Dependabot alerts and security updates, secret scanning, push protection, and private vulnerability reporting are enabled.

## Verification record

| Checked at | Evidence source | Reviewer | Result | Remaining boundary |
| --- | --- | --- | --- | --- |
| 2026-08-31 | GitHub REST API read-back before public migration | Nikita Melnychenko (`@qenterra`) | Merge settings and repository features match the declared contract | Visibility, security features, main protection, and release-tag immutability require a fresh read-back after the public cutover. |

Recheck this record after a visibility, plan, ownership, default-branch, workflow, release, or repository-feature change. Repository files express intent; only live provider read-back proves current settings.
