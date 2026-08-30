#!/usr/bin/env python3
"""Verify public Explore SwiftUI, Magic UI, shadcn/ui, and QenTerra catalogs."""

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
    source_extensions: tuple[str, ...] = (".swift",),
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
        for path in source_root.rglob("*")
        if path.is_file() and path.suffix in source_extensions
    } if source_root.is_dir() else set()
    for source_path in sorted(expected_paths - actual_paths):
        errors.append(f"{manifest_path}: declared source is missing {source_path}")
    for source_path in sorted(actual_paths - expected_paths):
        errors.append(f"{manifest_path}: untracked source {source_path}")
    return errors, by_id


def _validate_magic_ui(
    root: Path,
    manifest_path: Path,
) -> tuple[list[str], dict[str, dict[str, object]]]:
    errors, components = _validate_manifest(
        root,
        manifest_path,
        "Sources/MagicUI/Components/",
        (".tsx",),
    )
    try:
        manifest = _load(manifest_path)
    except (OSError, UnicodeError, json.JSONDecodeError, ValueError) as error:
        return [*errors, f"cannot verify Magic UI catalog: {error}"], components
    commit = manifest.get("upstreamCommit")
    if (
        not isinstance(commit, str)
        or len(commit) != 40
        or any(character not in "0123456789abcdef" for character in commit)
    ):
        errors.append("Magic UI source catalog upstream commit is invalid")

    registry_paths: set[str] = set()
    category_counts: dict[str, int] = {}
    for identifier, record in components.items():
        upstream_path = f"apps/www/registry/magicui/{identifier}.tsx"
        if record.get("upstreamPath") != upstream_path:
            errors.append(f"Magic UI component {identifier}: invalid upstream path")
        expected_source_url = (
            "https://raw.githubusercontent.com/magicuidesign/magicui/"
            f"{commit}/{upstream_path}"
        )
        if record.get("sourceURL") != expected_source_url:
            errors.append(f"Magic UI component {identifier}: unpinned source URL")
        if record.get("documentationURL") != (
            f"https://magicui.design/docs/components/{identifier}"
        ):
            errors.append(f"Magic UI component {identifier}: invalid documentation URL")
        category = record.get("category")
        if isinstance(category, str) and category:
            category_counts[category] = category_counts.get(category, 0) + 1
        else:
            errors.append(f"Magic UI component {identifier}: invalid category")

        registry_record = record.get("registryItem")
        if not isinstance(registry_record, dict):
            errors.append(f"Magic UI component {identifier}: registry item is missing")
            continue
        relative = registry_record.get("sourcePath")
        if not isinstance(relative, str) or not relative.startswith(
            "Sources/MagicUI/Registry/"
        ):
            errors.append(f"Magic UI component {identifier}: invalid registry path")
            continue
        if relative in registry_paths:
            errors.append(f"Magic UI component {identifier}: duplicate registry path")
        registry_paths.add(relative)
        expected_upstream_path = f"apps/www/public/r/{identifier}.json"
        if registry_record.get("upstreamPath") != expected_upstream_path:
            errors.append(f"Magic UI component {identifier}: invalid registry upstream path")
        expected_registry_url = (
            "https://raw.githubusercontent.com/magicuidesign/magicui/"
            f"{commit}/{expected_upstream_path}"
        )
        if registry_record.get("sourceURL") != expected_registry_url:
            errors.append(f"Magic UI component {identifier}: unpinned registry URL")
        registry_path = (root / relative).resolve()
        allowed = (root / "Sources/MagicUI/Registry").resolve()
        if allowed not in registry_path.parents:
            errors.append(f"Magic UI component {identifier}: registry path escapes catalog")
            continue
        if not registry_path.is_file():
            errors.append(f"Magic UI component {identifier}: registry item is missing")
            continue
        registry_bytes = registry_path.read_bytes()
        if registry_record.get("bytes") != len(registry_bytes):
            errors.append(f"Magic UI component {identifier}: registry byte-size mismatch")
        if registry_record.get("sha256") != hashlib.sha256(registry_bytes).hexdigest():
            errors.append(f"Magic UI component {identifier}: registry hash mismatch")
        try:
            registry_payload = json.loads(registry_bytes.decode("utf-8"))
            files = registry_payload.get("files") if isinstance(registry_payload, dict) else None
            source_path = root / str(record.get("sourcePath", ""))
            if (
                not isinstance(registry_payload, dict)
                or registry_payload.get("name") != identifier
                or registry_payload.get("type") != "registry:ui"
                or not isinstance(files, list)
                or len(files) != 1
                or not isinstance(files[0], dict)
                or files[0].get("path") != f"registry/magicui/{identifier}.tsx"
                or files[0].get("content") != source_path.read_text(encoding="utf-8")
            ):
                errors.append(f"Magic UI component {identifier}: registry content mismatch")
        except (OSError, UnicodeError, json.JSONDecodeError):
            errors.append(f"Magic UI component {identifier}: invalid registry item")

    registry_root = root / "Sources/MagicUI/Registry"
    actual_registry_paths = {
        path.relative_to(root).as_posix()
        for path in registry_root.rglob("*.json")
        if path.is_file()
    } if registry_root.is_dir() else set()
    for relative in sorted(registry_paths - actual_registry_paths):
        errors.append(f"Magic UI catalog: declared registry item is missing {relative}")
    for relative in sorted(actual_registry_paths - registry_paths):
        errors.append(f"Magic UI catalog: untracked registry item {relative}")

    count = len(components)
    if (
        manifest.get("count") != count
        or manifest.get("sourceFileCount") != count
        or manifest.get("registryItemCount") != count
        or manifest.get("fileCount") != count * 2
    ):
        errors.append("Magic UI source catalog file counts do not match")
    categories = manifest.get("categories")
    declared_category_counts = {
        str(category.get("identifier")): category.get("count")
        for category in categories
        if isinstance(category, dict)
    } if isinstance(categories, list) else {}
    if declared_category_counts != category_counts:
        errors.append("Magic UI source catalog category counts do not match")

    license_record = manifest.get("license")
    if not isinstance(license_record, dict):
        errors.append("Magic UI source catalog license record is missing")
    else:
        license_path = root / str(license_record.get("sourcePath", ""))
        if license_record.get("spdx") != "MIT":
            errors.append("Magic UI source catalog license is not MIT")
        if license_record.get("copyright") != "Copyright (c) Magic UI":
            errors.append("Magic UI source catalog authorship is missing")
        if license_record.get("sourceURL") != (
            f"https://github.com/magicuidesign/magicui/blob/{commit}/LICENSE.md"
        ):
            errors.append("Magic UI source catalog license URL is not pinned")
        if not license_path.is_file():
            errors.append("Magic UI source catalog license file is missing")
        else:
            payload = license_path.read_bytes()
            if license_record.get("bytes") != len(payload):
                errors.append("Magic UI source catalog license byte-size mismatch")
            if license_record.get("sha256") != hashlib.sha256(payload).hexdigest():
                errors.append("Magic UI source catalog license hash mismatch")
    return errors, components


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
    shadcn_manifest = root / "Sources/ShadcnUI/manifest.json"
    shadcn_errors, shadcn = _validate_manifest(
        root,
        shadcn_manifest,
        "Sources/ShadcnUI/Components/",
        (".css", ".js", ".jsx", ".ts", ".tsx"),
    )
    magic_manifest = root / "Sources/MagicUI/manifest.json"
    magic_errors, magic = _validate_magic_ui(root, magic_manifest)
    errors = [*explore_errors, *qenterra_errors, *shadcn_errors, *magic_errors]

    try:
        shadcn_manifest_payload = _load(shadcn_manifest)
        commit = shadcn_manifest_payload.get("upstreamCommit")
        if (
            not isinstance(commit, str)
            or len(commit) != 40
            or any(character not in "0123456789abcdef" for character in commit)
        ):
            errors.append("shadcn/ui source catalog upstream commit is invalid")
        for identifier, record in shadcn.items():
            upstream_path = record.get("upstreamPath")
            variant = record.get("variant")
            if (
                not isinstance(upstream_path, str)
                or not isinstance(variant, str)
                or not upstream_path.startswith(
                    f"apps/v4/registry/bases/{variant}/ui/"
                )
            ):
                errors.append(f"shadcn/ui component {identifier}: invalid upstream path")
                continue
            expected_url = (
                "https://raw.githubusercontent.com/shadcn-ui/ui/"
                f"{commit}/{upstream_path}"
            )
            if record.get("sourceURL") != expected_url:
                errors.append(f"shadcn/ui component {identifier}: unpinned source URL")

        license_record = shadcn_manifest_payload.get("license")
        if not isinstance(license_record, dict):
            errors.append("shadcn/ui source catalog license record is missing")
        else:
            license_path = root / str(license_record.get("sourcePath", ""))
            if license_record.get("spdx") != "MIT":
                errors.append("shadcn/ui source catalog license is not MIT")
            if "shadcn" not in str(license_record.get("copyright", "")):
                errors.append("shadcn/ui source catalog authorship is missing")
            if license_record.get("sourceURL") != (
                f"https://github.com/shadcn-ui/ui/blob/{commit}/LICENSE.md"
            ):
                errors.append("shadcn/ui source catalog license URL is not pinned")
            if not license_path.is_file():
                errors.append("shadcn/ui source catalog license file is missing")
            else:
                payload = license_path.read_bytes()
                if license_record.get("bytes") != len(payload):
                    errors.append("shadcn/ui source catalog license byte-size mismatch")
                if license_record.get("sha256") != hashlib.sha256(payload).hexdigest():
                    errors.append("shadcn/ui source catalog license hash mismatch")
    except (OSError, UnicodeError, json.JSONDecodeError, ValueError) as error:
        errors.append(f"cannot verify shadcn/ui license: {error}")

    try:
        package_version = _load(root / "npm/design-tokens/package.json").get("version")
        explore_version = _load(explore_manifest).get("version")
        qenterra_version = _load(qenterra_manifest).get("version")
        shadcn_version = _load(shadcn_manifest).get("version")
        magic_version = _load(magic_manifest).get("version")
        if (
            explore_version != package_version
            or qenterra_version != package_version
            or shadcn_version != package_version
            or magic_version != package_version
        ):
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
    shadcn = _load(ROOT / "Sources/ShadcnUI/manifest.json")
    magic = _load(ROOT / "Sources/MagicUI/manifest.json")
    print(
        f"Verified {len(explore['components'])} Explore SwiftUI originals and "
        f"{len(magic['components'])} Magic UI originals and "
        f"{len(shadcn['components'])} shadcn/ui originals and "
        f"{len(qenterra['components'])} QenTerra components"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
