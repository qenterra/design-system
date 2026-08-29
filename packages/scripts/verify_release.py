#!/usr/bin/env python3
"""Verify public release-manifest paths, sizes, and hashes."""

from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path


sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
IGNORED = {".git"}
sys.path.insert(0, str(ROOT / "scripts"))

import generate as public_generator  # noqa: E402


def generated_output_errors() -> list[str]:
    errors: list[str] = []
    with tempfile.TemporaryDirectory(prefix="qenterra-packages-generated-") as directory:
        destination = Path(directory)
        public_generator.write_outputs(destination, ROOT)
        for relative in sorted(public_generator.build_outputs(ROOT)):
            current = ROOT / relative
            regenerated = destination / relative
            if not current.is_file():
                errors.append(f"generated output missing: {relative}")
            elif current.read_bytes() != regenerated.read_bytes():
                errors.append(f"generated output mismatch: {relative}")
    return errors


def declared_files(manifest_path: Path) -> tuple[dict[str, dict[str, object]], list[str]]:
    errors: list[str] = []
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        package = json.loads(
            (ROOT / "npm/design-tokens/package.json").read_text(encoding="utf-8")
        )
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        return {}, [f"invalid release metadata: {error}"]
    if not isinstance(manifest, dict) or manifest.get("schemaVersion") != 1:
        return {}, ["release-manifest.json must use schemaVersion 1"]
    if manifest.get("repository") != "https://github.com/qenterra/packages":
        errors.append("release-manifest.json has an unexpected repository")
    if manifest.get("version") != package.get("version"):
        errors.append("release-manifest.json version does not match the npm package")
    records = manifest.get("files")
    if not isinstance(records, list):
        return {}, [*errors, "release-manifest.json files must be an array"]

    declared: dict[str, dict[str, object]] = {}
    for index, record in enumerate(records):
        if not isinstance(record, dict):
            errors.append(f"invalid manifest record at index {index}")
            continue
        relative = record.get("path")
        digest = record.get("sha256")
        byte_count = record.get("bytes")
        if (
            not isinstance(relative, str)
            or not relative
            or relative.startswith("/")
            or "\\" in relative
            or any(part in {"", ".", ".."} for part in relative.split("/"))
            or not isinstance(digest, str)
            or len(digest) != 64
            or any(character not in "0123456789abcdef" for character in digest)
            or type(byte_count) is not int
            or byte_count < 0
        ):
            errors.append(f"invalid manifest record at index {index}")
            continue
        if relative in declared:
            errors.append(f"duplicate manifest path: {relative}")
            continue
        declared[relative] = record
    return declared, errors


def main() -> int:
    try:
        errors = generated_output_errors()
    except (OSError, ValueError, json.JSONDecodeError, KeyError) as error:
        errors = [f"generated output verification failed: {error}"]
    manifest_path = ROOT / "release-manifest.json"
    declared, manifest_errors = declared_files(manifest_path)
    errors.extend(manifest_errors)
    actual: dict[str, Path] = {}
    for path in ROOT.rglob("*"):
        relative_path = path.relative_to(ROOT)
        if path == manifest_path or IGNORED.intersection(relative_path.parts):
            continue
        if path.is_symlink():
            errors.append(f"unsafe symlink: {relative_path.as_posix()}")
        elif path.is_file():
            actual[relative_path.as_posix()] = path
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
    environment = os.environ.copy()
    environment["PYTHONDONTWRITEBYTECODE"] = "1"
    governance = subprocess.run(
        [
            sys.executable,
            "scripts/qenterra_repository_check.py",
            "audit",
            "--root",
            ".",
            "--format",
            "markdown",
        ],
        cwd=ROOT,
        env=environment,
        check=False,
    )
    if governance.returncode != 0:
        return governance.returncode
    print(f"Verified {len(actual)} public files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
