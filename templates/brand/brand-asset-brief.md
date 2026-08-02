# {Asset or batch name}

## Function

- Audience and placement: {where it appears}
- Job: {what the asset must communicate or enable}
- Existing candidates reviewed: {canonical paths and why they do not fit}
- Change class: {additive / corrective / normative / breaking}

## Direction

- Selected direction: {visual idea and reason}
- Required brand invariants: {mark or character rules}
- Composition and negative space: {layout role}
- Light/dark and responsive behavior: {required contexts}
- Forbidden drift: {specific failures}

## Delivery

- Canonical category: `{assets/brand/...}`
- Filename and format: `{exact name.ext}`
- Pixel/vector requirements: {dimensions, mode, alpha, safe area}
- LFS expectation: {PNG yes; other formats no}
- Replaced targets: {exact canonical paths or none}

## Verification

- [ ] Source and alternatives remained in a unique system temporary directory.
- [ ] Original and use-size visual inspection passed on required backgrounds.
- [ ] Naming, format, dimensions, alpha/opacity, and category rules passed.
- [ ] `assets/brand/manifest.json` was updated and hashes match.
- [ ] Git LFS includes every new or changed PNG.
- [ ] Bilingual normative documentation and changelog were updated when required.
- [ ] `python3 scripts/verify.py` passed; manual/live gaps are recorded.
