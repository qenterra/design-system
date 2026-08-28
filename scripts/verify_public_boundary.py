#!/usr/bin/env python3
"""Verify that the public package tree contains only declared safe files."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PUBLIC_ROOT = ROOT / "packages"
IGNORED_PARTS = {".build", ".git", ".swiftpm", "node_modules"}
FORBIDDEN_PARTS = {"assets", "docs", "templates", ".agents", ".codex", "noetic"}
FORBIDDEN_NAMES = {
    "AGENTS.md",
    "SKILL.md",
    "design-system-consumer.json",
    "design-system-exceptions.json",
}
SECRET_PATTERNS = (
    re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    re.compile(r"\bgh[opurs]_[A-Za-z0-9_]{20,}\b"),
    re.compile(r"\bnpm_[A-Za-z0-9]{20,}\b"),
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def actual_files(public_root: Path) -> dict[str, Path]:
    files: dict[str, Path] = {}
    for path in public_root.rglob("*"):
        if not path.is_file():
            continue
        relative = path.relative_to(public_root)
        if IGNORED_PARTS.intersection(relative.parts):
            continue
        if relative.as_posix() == "release-manifest.json":
            continue
        files[relative.as_posix()] = path
    return files


def validate_public_tree(public_root: Path = PUBLIC_ROOT) -> list[str]:
    errors: list[str] = []
    manifest_path = public_root / "release-manifest.json"
    if not manifest_path.is_file():
        return ["release-manifest.json is missing"]
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"release-manifest.json is invalid: {error}"]

    if manifest.get("schemaVersion") != 1:
        errors.append("release-manifest.json: schemaVersion must be 1")
    if manifest.get("repository") != "https://github.com/qenterra/packages":
        errors.append("release-manifest.json: unexpected repository")
    if any(key.lower() in {"sourcesha", "commit", "commitsha"} for key in manifest):
        errors.append("release-manifest.json: private commit identifiers are forbidden")

    records = manifest.get("files")
    if not isinstance(records, list):
        return [*errors, "release-manifest.json: files must be an array"]
    declared: dict[str, dict[str, object]] = {}
    for record in records:
        if not isinstance(record, dict) or not isinstance(record.get("path"), str):
            errors.append("release-manifest.json: invalid file record")
            continue
        path = str(record["path"])
        if path in declared:
            errors.append(f"release-manifest.json: duplicate path: {path}")
        declared[path] = record

    actual = actual_files(public_root)
    for relative in sorted(set(actual) - set(declared)):
        errors.append(f"undeclared public file: {relative}")
    for relative in sorted(set(declared) - set(actual)):
        errors.append(f"declared public file is missing: {relative}")

    for relative, path in sorted(actual.items()):
        parts = Path(relative).parts
        if FORBIDDEN_PARTS.intersection(parts):
            errors.append(f"{relative}: forbidden private path")
        if path.name in FORBIDDEN_NAMES:
            errors.append(f"{relative}: forbidden private file")

        record = declared.get(relative)
        if record is not None:
            if record.get("bytes") != path.stat().st_size:
                errors.append(f"{relative}: byte-size mismatch")
            if record.get("sha256") != sha256(path):
                errors.append(f"{relative}: SHA-256 mismatch")

        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        if re.search(r"/(?:Users|home)/[^\s'\"`]+", text):
            errors.append(f"{relative}: contains an absolute local path")
        if re.search(r"\bQDS\b|\bqds[-_.]|\bDesignSystem\b", text):
            errors.append(f"{relative}: contains legacy active terminology")
        if any(pattern.search(text) for pattern in SECRET_PATTERNS):
            errors.append(f"{relative}: contains a credential-like value")
    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=PUBLIC_ROOT)
    arguments = parser.parse_args(argv)
    errors = validate_public_tree(arguments.root)
    if errors:
        print("Public boundary validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print(f"Public boundary validation passed: {len(actual_files(arguments.root))} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
