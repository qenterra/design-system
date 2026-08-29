# Troubleshooting

| Symptom | Check | Likely boundary | Recovery |
| --- | --- | --- | --- |
| `undeclared file` | Run `python3 scripts/verify_release.py` | Extra file or stale projection | Remove unintended material or regenerate the complete manifest from canonical source |
| Hash or size mismatch | Inspect the named file and manifest record | Hand edit or stale generated output | Regenerate the public projection; never patch only the hash |
| Repository-hygiene failure | Read the exact audit path and rule | Cache, build output, AI/agent file, skill, MCP config, secret, or local path | Move temporary work outside the repository and remove the residue |
| Swift build writes `.build/` | Check the command | Missing external scratch path | Re-run with `--scratch-path` pointing to a unique temporary directory outside the checkout |
| npm creates local state | Check npm cache and destination options | Default local package-manager behavior | Use external `--cache` and `--pack-destination` paths; remove unintended residue |
| Consumer cannot resolve a version | Compare tag and package metadata | Requested version was not published or tags differ | Use an existing immutable `v<version>` and verify the remote tag before changing manifests |

Do not weaken a verifier, ignore a forbidden path, rewrite a released tag, or copy private source into this repository as a workaround. If the published snapshot is wrong, correct canonical source and release a new version.
