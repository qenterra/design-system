# Brand release — {Name}

## Scope and authority

- Canonical paths: {exact paths}
- Change class: {editorial / additive / corrective / normative / breaking}
- Approved brief: {reference}
- Replacements and rollback copies: {temporary paths or none}

## Asset checks

- [ ] Category, filename, format, dimensions, mode, alpha/opacity, and visual role are correct.
- [ ] No `.DS_Store`, cache, source backup, AI plan, raw generation, prompt output, report, or contact sheet entered the repository.
- [ ] `assets/brand/manifest.json` covers every canonical file exactly once and hashes match.
- [ ] Every PNG is a Git LFS object; no SVG, JSON, or Markdown file is in LFS.
- [ ] Representative files were inspected at original and use size on required backgrounds.

## Documentation and compatibility

- [ ] English and Russian brand references remain semantically aligned.
- [ ] Consumer paths and migration notes were updated for rename/removal.
- [ ] Product exceptions remain explicit and scoped.
- [ ] Changelog and version reflect normative impact.

## Verification

- [ ] Focused brand/Nyx validators pass.
- [ ] `python3 scripts/verify.py` passes.
- [ ] Git diff, staged LFS pointers, large blobs, links, and repository hygiene pass.
- [ ] Live platform checks are distinguished from static and visual checks.

## Result

- Commit: {local commit SHA}
- Automated checks: {evidence}
- Visual checks: {evidence}
- Manual/live gaps: {exact gaps or none}
