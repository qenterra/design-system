#!/usr/bin/env python3
"""Verify public Explore SwiftUI and QenTerra source catalogs."""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _load(path: Path) -> dict[str, object]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{path}: expected an object")
    return payload


def _validate_manifest(
    root: Path,
    manifest_path: Path,
    source_prefix: str,
) -> tuple[list[str], dict[str, dict[str, object]]]:
    errors: list[str] = []
    try:
        manifest = _load(manifest_path)
    except (OSError, UnicodeError, json.JSONDecodeError, ValueError) as error:
        return [f"invalid source manifest {manifest_path}: {error}"], {}
    records = manifest.get("components")
    if not isinstance(records, list) or not records:
        return [f"{manifest_path}: components must be a non-empty array"], {}
    if "count" in manifest and manifest.get("count") != len(records):
        errors.append(f"{manifest_path}: count mismatch")

    expected_paths: set[str] = set()
    by_id: dict[str, dict[str, object]] = {}
    for index, record in enumerate(records):
        if not isinstance(record, dict):
            errors.append(f"{manifest_path}: invalid record at index {index}")
            continue
        identifier = record.get("id")
        source_path = record.get("sourcePath")
        if not isinstance(identifier, str) or not identifier:
            errors.append(f"{manifest_path}: invalid id at index {index}")
            continue
        if identifier in by_id:
            errors.append(f"{manifest_path}: duplicate id {identifier}")
        by_id[identifier] = record
        if not isinstance(source_path, str) or not source_path.startswith(source_prefix):
            errors.append(f"{manifest_path}: invalid source path for {identifier}")
            continue
        if source_path in expected_paths:
            errors.append(f"{manifest_path}: duplicate source path {source_path}")
        expected_paths.add(source_path)
        source = (root / source_path).resolve()
        source_root = (root / source_prefix).resolve()
        if source_root != source and source_root not in source.parents:
            errors.append(f"{manifest_path}: source path escapes its catalog")
            continue
        if not source.is_file():
            errors.append(f"{manifest_path}: missing source {source_path}")
            continue
        payload = source.read_bytes()
        if record.get("bytes") != len(payload):
            errors.append(f"{manifest_path}: byte-size mismatch for {source_path}")
        if record.get("sha256") != hashlib.sha256(payload).hexdigest():
            errors.append(f"{manifest_path}: hash mismatch for {source_path}")

    source_root = root / source_prefix
    actual_paths = {
        path.relative_to(root).as_posix()
        for path in source_root.rglob("*.swift")
        if path.is_file()
    } if source_root.is_dir() else set()
    for source_path in sorted(expected_paths - actual_paths):
        errors.append(f"{manifest_path}: declared source is missing {source_path}")
    for source_path in sorted(actual_paths - expected_paths):
        errors.append(f"{manifest_path}: untracked source {source_path}")
    return errors, by_id


def validate_catalogs(root: Path = ROOT) -> list[str]:
    explore_manifest = root / "Sources/ExploreSwiftUI/manifest.json"
    qenterra_manifest = root / "Sources/QenTerra/manifest.json"
    explore_errors, explore = _validate_manifest(
        root,
        explore_manifest,
        "Sources/ExploreSwiftUI/Components/",
    )
    qenterra_errors, qenterra = _validate_manifest(
        root,
        qenterra_manifest,
        "Sources/QenTerra/Components/",
    )
    errors = [*explore_errors, *qenterra_errors]

    try:
        package_version = _load(root / "npm/design-tokens/package.json").get("version")
        explore_version = _load(explore_manifest).get("version")
        qenterra_version = _load(qenterra_manifest).get("version")
        if explore_version != package_version or qenterra_version != package_version:
            errors.append("source catalog versions do not match the package version")
    except (OSError, UnicodeError, json.JSONDecodeError, ValueError) as error:
        errors.append(f"cannot compare source catalog versions: {error}")

    for identifier, record in qenterra.items():
        derived = record.get("derivedFrom")
        if derived is None:
            continue
        if not isinstance(derived, dict):
            errors.append(f"QenTerra component {identifier}: invalid derivedFrom")
            continue
        original_id = derived.get("componentId")
        original = explore.get(str(original_id))
        if original is None:
            errors.append(f"QenTerra component {identifier}: unknown Explore SwiftUI source")
        elif derived.get("sourceSha256") != original.get("sha256"):
            errors.append(f"QenTerra component {identifier}: original hash drift")
    return errors


def main() -> int:
    errors = validate_catalogs(ROOT)
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1
    explore = _load(ROOT / "Sources/ExploreSwiftUI/manifest.json")
    qenterra = _load(ROOT / "Sources/QenTerra/manifest.json")
    print(
        f"Verified {len(explore['components'])} Explore SwiftUI originals and "
        f"{len(qenterra['components'])} QenTerra components"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
