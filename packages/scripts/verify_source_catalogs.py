#!/usr/bin/env python3
"""Verify public Explore SwiftUI, Magic UI, shadcn/ui, UIable, ReUI, and QenTerra catalogs."""

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


def _validate_uiable(
    root: Path,
    manifest_path: Path,
) -> tuple[list[str], dict[str, dict[str, object]]]:
    errors: list[str] = []
    try:
        manifest = _load(manifest_path)
    except (OSError, UnicodeError, json.JSONDecodeError, ValueError) as error:
        return [f"cannot verify UIable catalog: {error}"], {}
    commit = manifest.get("upstreamCommit")
    if (
        not isinstance(commit, str)
        or len(commit) != 40
        or any(character not in "0123456789abcdef" for character in commit)
    ):
        errors.append("UIable source catalog upstream commit is invalid")

    records = manifest.get("items")
    if not isinstance(records, list) or not records:
        return [*errors, f"{manifest_path}: items must be a non-empty array"], {}
    items: dict[str, dict[str, object]] = {}
    source_paths: set[str] = set()
    registry_paths: set[str] = set()
    category_counts: dict[str, int] = {}
    component_count = 0
    primitive_count = 0
    for index, record in enumerate(records):
        if not isinstance(record, dict):
            errors.append(f"UIable catalog: invalid item at index {index}")
            continue
        identifier = record.get("id")
        kind = record.get("kind")
        if not isinstance(identifier, str) or not identifier:
            errors.append(f"UIable catalog: invalid id at index {index}")
            continue
        if identifier in items:
            errors.append(f"UIable catalog: duplicate item {identifier}")
        items[identifier] = record
        if kind == "component":
            component_count += 1
            source_prefix = "Sources/UIable/Components/"
            registry_prefix = "Sources/UIable/Registry/Components/"
            upstream_prefix = "src/components/uiable/"
        elif kind == "primitive":
            primitive_count += 1
            source_prefix = "Sources/UIable/Primitives/"
            registry_prefix = "Sources/UIable/Registry/Primitives/"
            upstream_prefix = "src/components/ui/"
        else:
            errors.append(f"UIable item {identifier}: invalid kind")
            continue

        categories = record.get("categories")
        if not isinstance(categories, list) or not all(
            isinstance(category, str) for category in categories
        ):
            errors.append(f"UIable item {identifier}: invalid categories")
        else:
            for category in categories:
                category_counts[category] = category_counts.get(category, 0) + 1

        upstream_path = record.get("upstreamPath")
        if not isinstance(upstream_path, str) or not upstream_path.startswith(
            upstream_prefix
        ):
            errors.append(f"UIable item {identifier}: invalid upstream path")
            continue
        expected_source_url = (
            "https://raw.githubusercontent.com/codedthemes/uiable/"
            f"{commit}/{upstream_path}"
        )
        if record.get("sourceURL") != expected_source_url:
            errors.append(f"UIable item {identifier}: unpinned source URL")
        source_relative = record.get("sourcePath")
        if not isinstance(source_relative, str) or not source_relative.startswith(
            source_prefix
        ):
            errors.append(f"UIable item {identifier}: invalid source path")
            continue
        source_path = (root / source_relative).resolve()
        allowed_source = (root / source_prefix).resolve()
        if allowed_source not in source_path.parents:
            errors.append(f"UIable item {identifier}: source path escapes catalog")
            continue
        if source_relative in source_paths:
            errors.append(f"UIable item {identifier}: duplicate source path")
        source_paths.add(source_relative)
        if not source_path.is_file():
            errors.append(f"UIable item {identifier}: source is missing")
            continue
        source_bytes = source_path.read_bytes()
        if record.get("bytes") != len(source_bytes):
            errors.append(f"UIable item {identifier}: source byte-size mismatch")
        if record.get("sha256") != hashlib.sha256(source_bytes).hexdigest():
            errors.append(f"UIable item {identifier}: source hash mismatch")

        registry_record = record.get("registryItem")
        if not isinstance(registry_record, dict):
            errors.append(f"UIable item {identifier}: registry item is missing")
            continue
        registry_relative = registry_record.get("sourcePath")
        if not isinstance(registry_relative, str) or not registry_relative.startswith(
            registry_prefix
        ):
            errors.append(f"UIable item {identifier}: invalid registry path")
            continue
        registry_path = (root / registry_relative).resolve()
        allowed_registry = (root / registry_prefix).resolve()
        if allowed_registry not in registry_path.parents:
            errors.append(f"UIable item {identifier}: registry path escapes catalog")
            continue
        if registry_relative in registry_paths:
            errors.append(f"UIable item {identifier}: duplicate registry path")
        registry_paths.add(registry_relative)
        expected_registry_upstream_path = f"public/r/{identifier}.json"
        if registry_record.get("upstreamPath") != expected_registry_upstream_path:
            errors.append(f"UIable item {identifier}: invalid registry upstream path")
        expected_registry_url = (
            "https://raw.githubusercontent.com/codedthemes/uiable/"
            f"{commit}/{expected_registry_upstream_path}"
        )
        if registry_record.get("sourceURL") != expected_registry_url:
            errors.append(f"UIable item {identifier}: unpinned registry URL")
        if not registry_path.is_file():
            errors.append(f"UIable item {identifier}: registry item is missing")
            continue
        registry_bytes = registry_path.read_bytes()
        if registry_record.get("bytes") != len(registry_bytes):
            errors.append(f"UIable item {identifier}: registry byte-size mismatch")
        if registry_record.get("sha256") != hashlib.sha256(registry_bytes).hexdigest():
            errors.append(f"UIable item {identifier}: registry hash mismatch")
        try:
            registry_payload = json.loads(registry_bytes.decode("utf-8"))
            files = (
                registry_payload.get("files")
                if isinstance(registry_payload, dict)
                else None
            )
            if (
                not isinstance(registry_payload, dict)
                or registry_payload.get("name") != identifier
                or registry_payload.get("type") != "registry:ui"
                or not isinstance(files, list)
                or len(files) != 1
                or not isinstance(files[0], dict)
                or files[0].get("path") != upstream_path
                or files[0].get("content") != source_bytes.decode("utf-8")
            ):
                errors.append(f"UIable item {identifier}: registry content mismatch")
        except (UnicodeError, json.JSONDecodeError):
            errors.append(f"UIable item {identifier}: invalid registry item")

    actual_source_paths = {
        path.relative_to(root).as_posix()
        for source_root in (
            root / "Sources/UIable/Components",
            root / "Sources/UIable/Primitives",
        )
        if source_root.is_dir()
        for path in source_root.rglob("*.tsx")
        if path.is_file()
    }
    actual_registry_paths = {
        path.relative_to(root).as_posix()
        for registry_root in (
            root / "Sources/UIable/Registry/Components",
            root / "Sources/UIable/Registry/Primitives",
        )
        if registry_root.is_dir()
        for path in registry_root.rglob("*.json")
        if path.is_file()
    }
    for relative in sorted(source_paths - actual_source_paths):
        errors.append(f"UIable catalog: declared source is missing {relative}")
    for relative in sorted(actual_source_paths - source_paths):
        errors.append(f"UIable catalog: untracked source {relative}")
    for relative in sorted(registry_paths - actual_registry_paths):
        errors.append(f"UIable catalog: declared registry item is missing {relative}")
    for relative in sorted(actual_registry_paths - registry_paths):
        errors.append(f"UIable catalog: untracked registry item {relative}")

    count = len(items)
    if (
        manifest.get("count") != count
        or manifest.get("componentCount") != component_count
        or manifest.get("primitiveCount") != primitive_count
        or component_count + primitive_count != count
        or manifest.get("sourceFileCount") != count
        or manifest.get("registryItemCount") != count
        or manifest.get("fileCount") != count * 2
    ):
        errors.append("UIable source catalog file counts do not match")
    categories = manifest.get("categories")
    declared_category_counts = {
        str(category.get("identifier")): category.get("count")
        for category in categories
        if isinstance(category, dict)
    } if isinstance(categories, list) else {}
    if declared_category_counts != category_counts:
        errors.append("UIable source catalog category counts do not match")

    license_record = manifest.get("license")
    if not isinstance(license_record, dict):
        errors.append("UIable source catalog license record is missing")
    else:
        license_path = root / str(license_record.get("sourcePath", ""))
        if license_record.get("spdx") != "MIT":
            errors.append("UIable source catalog license is not MIT")
        if license_record.get("copyright") != "Copyright (c) 2026 CodedThemes":
            errors.append("UIable source catalog authorship is missing")
        if license_record.get("sourceURL") != (
            f"https://github.com/codedthemes/uiable/blob/{commit}/LICENSE"
        ):
            errors.append("UIable source catalog license URL is not pinned")
        if not license_path.is_file():
            errors.append("UIable source catalog license file is missing")
        else:
            payload = license_path.read_bytes()
            if license_record.get("bytes") != len(payload):
                errors.append("UIable source catalog license byte-size mismatch")
            if license_record.get("sha256") != hashlib.sha256(payload).hexdigest():
                errors.append("UIable source catalog license hash mismatch")
            if "Copyright (c) 2026 CodedThemes" not in payload.decode("utf-8"):
                errors.append("UIable source catalog license authorship mismatch")
    return errors, items


def _validate_reui(
    root: Path,
    manifest_path: Path,
) -> tuple[list[str], dict[str, dict[str, object]]]:
    errors: list[str] = []
    try:
        manifest = _load(manifest_path)
    except (OSError, UnicodeError, json.JSONDecodeError, ValueError) as error:
        return [f"cannot verify ReUI catalog: {error}"], {}
    commit = manifest.get("upstreamCommit")
    if (
        not isinstance(commit, str)
        or len(commit) != 40
        or any(character not in "0123456789abcdef" for character in commit)
    ):
        errors.append("ReUI source catalog upstream commit is invalid")
    registry_revision = manifest.get("registryRevision")
    if (
        not isinstance(registry_revision, str)
        or not registry_revision.startswith("dpl_")
    ):
        errors.append("ReUI source catalog registry revision is invalid")
    if manifest.get("registryOrigin") != "https://reui.io/r/styles":
        errors.append("ReUI source catalog registry origin is invalid")
    indexes = manifest.get("registryIndexes")
    if not isinstance(indexes, list) or len(indexes) != 2:
        errors.append("ReUI source catalog registry indexes are missing")
    else:
        expected_bases = (("base", "base-nova"), ("radix", "radix-nova"))
        for record, (base, style) in zip(indexes, expected_bases):
            expected_url = (
                f"https://reui.io/r/styles/{style}/registry.json"
                f"?v={registry_revision}"
            )
            if (
                not isinstance(record, dict)
                or record.get("base") != base
                or record.get("style") != style
                or record.get("upstreamPath")
                != f"public/r/styles/{style}/registry.json"
                or record.get("sourceURL") != expected_url
                or not isinstance(record.get("sha256"), str)
                or len(str(record.get("sha256"))) != 64
                or not isinstance(record.get("bytes"), int)
                or int(record.get("bytes", 0)) < 1
            ):
                errors.append(f"ReUI source catalog {base} registry index is invalid")

    source_records = manifest.get("sources")
    if not isinstance(source_records, list) or not source_records:
        return [*errors, "ReUI source catalog sources must be non-empty"], {}
    source_paths: set[str] = set()
    sources: dict[str, dict[str, object]] = {}
    source_payloads: dict[str, bytes] = {}
    allowed_source_root = (root / "Sources/ReUI").resolve()
    for index, record in enumerate(source_records):
        if not isinstance(record, dict):
            errors.append(f"ReUI source catalog: invalid source at index {index}")
            continue
        relative = record.get("sourcePath")
        upstream = record.get("upstreamPath")
        if (
            not isinstance(relative, str)
            or not relative.startswith(
                ("Sources/ReUI/Base/", "Sources/ReUI/Radix/", "Sources/ReUI/Shared/")
            )
        ):
            errors.append(f"ReUI source catalog: invalid source path at index {index}")
            continue
        path = (root / relative).resolve()
        if allowed_source_root not in path.parents:
            errors.append(f"ReUI source catalog: source path escapes catalog {relative}")
            continue
        if relative in source_paths:
            errors.append(f"ReUI source catalog: duplicate source path {relative}")
        source_paths.add(relative)
        sources[relative] = record
        if not path.is_file():
            errors.append(f"ReUI source catalog: missing source {relative}")
            continue
        payload = path.read_bytes()
        source_payloads[relative] = payload
        if record.get("bytes") != len(payload):
            errors.append(f"ReUI source catalog: byte-size mismatch {relative}")
        if record.get("sha256") != hashlib.sha256(payload).hexdigest():
            errors.append(f"ReUI source catalog: hash mismatch {relative}")
        origin = record.get("origin")
        registry_path = upstream.split("#", 1)[0] if isinstance(upstream, str) else ""
        if origin == "repository":
            expected_url = (
                "https://raw.githubusercontent.com/keenthemes/reui/"
                f"{commit}/{registry_path}"
            )
        elif origin == "live-registry":
            expected_url = (
                f"https://reui.io/{registry_path.removeprefix('public/')}"
                f"?v={registry_revision}"
            )
        else:
            expected_url = ""
        if not registry_path or record.get("sourceURL") != expected_url:
            errors.append(f"ReUI source catalog: invalid source origin {relative}")

    item_records = manifest.get("items")
    if not isinstance(item_records, list) or not item_records:
        return [*errors, "ReUI source catalog items must be non-empty"], sources
    item_ids: set[str] = set()
    registry_paths: set[str] = set()
    counts = {"example": 0, "primitive": 0, "hook": 0}
    origin_counts = {"repository": 0, "live-registry": 0}
    expected_types = {
        "example": "registry:block",
        "primitive": "registry:ui",
        "hook": "registry:hook",
    }
    for index, item in enumerate(item_records):
        if not isinstance(item, dict):
            errors.append(f"ReUI source catalog: invalid item at index {index}")
            continue
        identifier = item.get("id")
        kind = item.get("kind")
        base = item.get("base")
        name = item.get("name")
        if not isinstance(identifier, str) or identifier in item_ids:
            errors.append("ReUI source catalog: invalid or duplicate item id")
            continue
        item_ids.add(identifier)
        if kind not in counts or base not in {"base", "radix"}:
            errors.append(f"ReUI source catalog: invalid item kind/base {identifier}")
            continue
        counts[str(kind)] += 1
        references = item.get("sourcePaths")
        if not isinstance(references, list) or not references or not all(
            isinstance(reference, str) and reference in source_paths
            for reference in references
        ):
            errors.append(f"ReUI source catalog: invalid source references {identifier}")

        registry = item.get("registryItem")
        if not isinstance(registry, dict):
            errors.append(f"ReUI source catalog: missing registry item {identifier}")
            continue
        relative = registry.get("sourcePath")
        upstream = registry.get("upstreamPath")
        expected_prefix = f"Sources/ReUI/Registry/{str(base).title()}Nova/"
        if not isinstance(relative, str) or not relative.startswith(expected_prefix):
            errors.append(f"ReUI source catalog: invalid registry path {identifier}")
            continue
        if relative in registry_paths:
            errors.append(f"ReUI source catalog: duplicate registry path {relative}")
        registry_paths.add(relative)
        path = (root / relative).resolve()
        if allowed_source_root not in path.parents or not path.is_file():
            errors.append(f"ReUI source catalog: missing registry item {relative}")
            continue
        payload_bytes = path.read_bytes()
        if registry.get("bytes") != len(payload_bytes):
            errors.append(f"ReUI source catalog: registry byte-size mismatch {relative}")
        if registry.get("sha256") != hashlib.sha256(payload_bytes).hexdigest():
            errors.append(f"ReUI source catalog: registry hash mismatch {relative}")
        origin = registry.get("origin")
        if origin in origin_counts:
            origin_counts[str(origin)] += 1
        if origin == "repository":
            expected_url = (
                "https://raw.githubusercontent.com/keenthemes/reui/"
                f"{commit}/{upstream}"
            )
        elif origin == "live-registry":
            expected_url = (
                f"https://reui.io/{str(upstream).removeprefix('public/')}"
                f"?v={registry_revision}"
            )
        else:
            expected_url = ""
        if not isinstance(upstream, str) or registry.get("sourceURL") != expected_url:
            errors.append(f"ReUI source catalog: invalid registry origin {identifier}")
        try:
            payload = json.loads(payload_bytes.decode("utf-8"))
            if (
                not isinstance(payload, dict)
                or payload.get("name") != name
                or payload.get("type") != expected_types[str(kind)]
            ):
                errors.append(f"ReUI source catalog: registry identity mismatch {identifier}")
            files = payload.get("files") if isinstance(payload, dict) else None
            if not isinstance(files, list) or not all(
                isinstance(file, dict) and isinstance(file.get("content"), str)
                for file in files
            ):
                errors.append(f"ReUI source catalog: invalid registry files {identifier}")
            else:
                registry_hashes = sorted(
                    hashlib.sha256(str(file["content"]).encode("utf-8")).hexdigest()
                    for file in files
                    if isinstance(file, dict)
                )
                source_hashes = sorted(
                    hashlib.sha256(source_payloads[str(reference)]).hexdigest()
                    for reference in references
                    if str(reference) in source_payloads
                )
                if registry_hashes != source_hashes:
                    errors.append(
                        f"ReUI source catalog: registry content mismatch {identifier}"
                    )
        except (UnicodeError, json.JSONDecodeError):
            errors.append(f"ReUI source catalog: invalid registry JSON {identifier}")

    actual_sources = {
        path.relative_to(root).as_posix()
        for directory in ("Base", "Radix", "Shared")
        for path in (root / f"Sources/ReUI/{directory}").rglob("*")
        if path.is_file()
    }
    actual_registry = {
        path.relative_to(root).as_posix()
        for path in (root / "Sources/ReUI/Registry").rglob("*")
        if path.is_file()
    }
    if source_paths != actual_sources:
        errors.append("ReUI source catalog is not closed")
    if registry_paths != actual_registry:
        errors.append("ReUI registry catalog is not closed")
    if (
        manifest.get("count") != len(item_records)
        or manifest.get("exampleCount") != counts["example"]
        or manifest.get("primitiveCount") != counts["primitive"]
        or manifest.get("hookCount") != counts["hook"]
        or manifest.get("repositoryItemCount") != origin_counts["repository"]
        or manifest.get("liveRegistryItemCount") != origin_counts["live-registry"]
        or manifest.get("sourceFileCount") != len(source_records)
        or manifest.get("registryItemCount") != len(item_records)
        or manifest.get("fileCount") != len(source_records) + len(item_records)
    ):
        errors.append("ReUI source catalog file counts do not match")

    license_record = manifest.get("license")
    if not isinstance(license_record, dict):
        errors.append("ReUI source catalog license record is missing")
    else:
        license_path = root / str(license_record.get("sourcePath", ""))
        if license_record.get("spdx") != "MIT":
            errors.append("ReUI source catalog license is not MIT")
        if license_record.get("copyright") != "Copyright (c) 2025 Keenthemes Inc":
            errors.append("ReUI source catalog authorship is missing")
        if license_record.get("sourceURL") != (
            f"https://github.com/keenthemes/reui/blob/{commit}/LICENSE.md"
        ):
            errors.append("ReUI source catalog license URL is not pinned")
        if not license_path.is_file():
            errors.append("ReUI source catalog license file is missing")
        else:
            payload = license_path.read_bytes()
            if license_record.get("bytes") != len(payload):
                errors.append("ReUI source catalog license byte-size mismatch")
            if license_record.get("sha256") != hashlib.sha256(payload).hexdigest():
                errors.append("ReUI source catalog license hash mismatch")
            if "Copyright (c) 2025 Keenthemes Inc" not in payload.decode("utf-8"):
                errors.append("ReUI source catalog license authorship mismatch")
    return errors, sources


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
    uiable_manifest = root / "Sources/UIable/manifest.json"
    uiable_errors, uiable = _validate_uiable(root, uiable_manifest)
    reui_manifest = root / "Sources/ReUI/manifest.json"
    reui_errors, reui = _validate_reui(root, reui_manifest)
    errors = [
        *explore_errors,
        *qenterra_errors,
        *shadcn_errors,
        *magic_errors,
        *uiable_errors,
        *reui_errors,
    ]

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
        uiable_version = _load(uiable_manifest).get("version")
        reui_version = _load(reui_manifest).get("version")
        if (
            explore_version != package_version
            or qenterra_version != package_version
            or shadcn_version != package_version
            or magic_version != package_version
            or uiable_version != package_version
            or reui_version != package_version
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
    uiable = _load(ROOT / "Sources/UIable/manifest.json")
    reui = _load(ROOT / "Sources/ReUI/manifest.json")
    print(
        f"Verified {len(explore['components'])} Explore SwiftUI originals and "
        f"{len(magic['components'])} Magic UI originals and "
        f"{len(shadcn['components'])} shadcn/ui originals and "
        f"{len(uiable['items'])} UIable originals and "
        f"{len(reui['sources'])} ReUI originals and "
        f"{len(qenterra['components'])} QenTerra components"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
