#!/usr/bin/env python3
"""Verify public release-manifest paths, sizes, and hashes."""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
IGNORED = {".build", ".git", ".swiftpm", "node_modules"}


def main() -> int:
    manifest_path = ROOT / "release-manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    declared = {record["path"]: record for record in manifest["files"]}
    actual = {
        path.relative_to(ROOT).as_posix(): path
        for path in ROOT.rglob("*")
        if path.is_file()
        and path != manifest_path
        and not IGNORED.intersection(path.relative_to(ROOT).parts)
    }
    errors: list[str] = []
    for relative in sorted(set(actual) - set(declared)):
        errors.append(f"undeclared file: {relative}")
    for relative in sorted(set(declared) - set(actual)):
        errors.append(f"missing file: {relative}")
    for relative in sorted(set(actual) & set(declared)):
        path = actual[relative]
        content = path.read_bytes()
        if len(content) != declared[relative]["bytes"]:
            errors.append(f"size mismatch: {relative}")
        if hashlib.sha256(content).hexdigest() != declared[relative]["sha256"]:
            errors.append(f"hash mismatch: {relative}")
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1
    print(f"Verified {len(actual)} public files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
