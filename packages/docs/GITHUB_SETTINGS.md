# GitHub settings and verification

## Expected settings

- Repository: `https://github.com/QenTerra/packages`; visibility: public; default branch: `main`.
- Issues enabled; Projects, Wiki, and Discussions disabled.
- Squash merge enabled; merge commits and rebase merge disabled; merged branches deleted automatically.
- Active ruleset `Protect main` (`21772885`) rejects deletion and non-fast-forward updates and requires linear history on the default branch.
- Workflows have read-only default permissions, pinned actions, and no persistent checkout credentials.
- Dependabot alerts and security updates, secret scanning, push protection, and private vulnerability reporting are enabled.

## Verification record

| Checked at | Evidence source | Reviewer | Result | Remaining boundary |
| --- | --- | --- | --- | --- |
| 2026-08-29 | GitHub REST API read-back | Nikita Melnychenko (`@qenterra`) | Metadata, features, merge settings, security features, private reporting, and ruleset `21772885` verified | Code scanning and release immutability remain release-specific checks when those surfaces are used. |

Recheck this record after a visibility, plan, ownership, default-branch, workflow, release, or repository-feature change. Repository files express intent; only live provider read-back proves current settings.
