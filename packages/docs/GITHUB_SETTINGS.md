# GitHub settings and verification

## Expected settings

- Repository: `https://github.com/QenTerra/packages`; visibility: public; default branch: `main`.
- Issues enabled; Projects, Wiki, and Discussions disabled.
- Squash merge enabled; merge commits and rebase merge disabled; merged branches deleted automatically.
- Active ruleset `Protect main` (`21772885`) requires pull requests, the `repository-governance` and `verify` checks, conversation resolution, and linear history while rejecting deletion and non-fast-forward updates on the default branch.
- Active ruleset `Protect release tags` (`21775839`) rejects deletion and replacement of tags matching `v*`; neither ruleset has a bypass actor.
- Workflows have read-only default permissions, pinned actions, and no persistent checkout credentials.
- Dependabot alerts and security updates, secret scanning, push protection, and private vulnerability reporting are enabled.

## Verification record

| Checked at | Evidence source | Reviewer | Result | Remaining boundary |
| --- | --- | --- | --- | --- |
| 2026-08-29T01:21:33Z | GitHub REST API read-back | Nikita Melnychenko (`@qenterra`) | Metadata, features, merge settings, security features, private reporting, main protection, and release-tag immutability verified | Code scanning and registry publication remain release-specific checks when those surfaces are used. |

Recheck this record after a visibility, plan, ownership, default-branch, workflow, release, or repository-feature change. Repository files express intent; only live provider read-back proves current settings.
