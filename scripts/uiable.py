#!/usr/bin/env python3
"""Synchronize and verify the exact official UIable component catalog."""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path, PurePosixPath


ROOT = Path(__file__).resolve().parents[1]
UPSTREAM_REPOSITORY = "https://github.com/codedthemes/uiable"
UPSTREAM_GIT_URL = f"{UPSTREAM_REPOSITORY}.git"
UPSTREAM_BRANCH = "master"
UPSTREAM_REF = f"refs/heads/{UPSTREAM_BRANCH}"
UPSTREAM_LICENSE = Path("LICENSE")
COMPONENT_REGISTRY = Path("src/components/uiable/registry.json")
PRIMITIVE_REGISTRY = Path("src/components/ui/registry.json")
AGGREGATE_REGISTRY = Path("public/r/registry.json")
PUBLIC_REGISTRY_ROOT = Path("public/r")
COMPONENT_SOURCE_ROOT = Path("src/components/uiable")
PRIMITIVE_SOURCE_ROOT = Path("src/components/ui")
PUBLIC_ROOT = Path("packages/Sources/UIable")
PUBLIC_MANIFEST = PUBLIC_ROOT / "manifest.json"
PUBLIC_LICENSE = PUBLIC_ROOT / "LICENSE.md"
PUBLIC_README = PUBLIC_ROOT / "README.md"
COMPONENT_ROOT = PUBLIC_ROOT / "Components"
PRIMITIVE_ROOT = PUBLIC_ROOT / "Primitives"
REGISTRY_COMPONENT_ROOT = PUBLIC_ROOT / "Registry/Components"
REGISTRY_PRIMITIVE_ROOT = PUBLIC_ROOT / "Registry/Primitives"
PRIVATE_REGISTRY = Path("registry/uiable.json")
PRIVATE_SCHEMA = "../schemas/uiable-registry.schema.json"
COMMIT_PATTERN = re.compile(r"^[0-9a-f]{40}$")


@dataclasses.dataclass(frozen=True)
class Category:
    identifier: str
    count: int


@dataclasses.dataclass(frozen=True)
class UIableItem:
    identifier: str
    kind: str
    title: str
    description: str
    categories: tuple[str, ...]
    upstream_path: str
    source_url: str
    source_path: str
    source_bytes: bytes
    registry_upstream_path: str
    registry_url: str
    registry_source_path: str
    registry_bytes: bytes
    dependencies: tuple[str, ...]
    registry_dependencies: tuple[str, ...]

    @property
    def sha256(self) -> str:
        return hashlib.sha256(self.source_bytes).hexdigest()

    @property
    def registry_sha256(self) -> str:
        return hashlib.sha256(self.registry_bytes).hexdigest()

    def manifest_record(self) -> dict[str, object]:
        return {
            "id": self.identifier,
            "name": self.identifier,
            "kind": self.kind,
            "title": self.title,
            "description": self.description,
            "categories": list(self.categories),
            "language": "TypeScript TSX",
            "documentationURL": "https://uiable.com/components",
            "upstreamPath": self.upstream_path,
            "sourceURL": self.source_url,
            "sourcePath": self.source_path,
            "sha256": self.sha256,
            "bytes": len(self.source_bytes),
            "dependencies": list(self.dependencies),
            "registryDependencies": list(self.registry_dependencies),
            "registryItem": {
                "upstreamPath": self.registry_upstream_path,
                "sourceURL": self.registry_url,
                "sourcePath": self.registry_source_path,
                "sha256": self.registry_sha256,
                "bytes": len(self.registry_bytes),
            },
        }


@dataclasses.dataclass(frozen=True)
class UpstreamSnapshot:
    commit: str
    items: tuple[UIableItem, ...]
    categories: tuple[Category, ...]
    license_bytes: bytes
    license_copyright: str

    @property
    def component_count(self) -> int:
        return sum(item.kind == "component" for item in self.items)

    @property
    def primitive_count(self) -> int:
        return sum(item.kind == "primitive" for item in self.items)

    @property
    def license_sha256(self) -> str:
        return hashlib.sha256(self.license_bytes).hexdigest()


def _read_required(path: Path) -> bytes:
    if not path.is_file():
        raise ValueError(f"required upstream file is missing: {path}")
    return path.read_bytes()


def _read_object(path: Path) -> dict[str, object]:
    try:
        payload = json.loads(_read_required(path).decode("utf-8"))
    except (UnicodeError, json.JSONDecodeError) as error:
        raise ValueError(f"{path}: invalid JSON: {error}") from error
    if not isinstance(payload, dict):
        raise ValueError(f"{path}: expected an object")
    return payload


def _string_list(value: object, *, field: str, item: str) -> tuple[str, ...]:
    if value is None:
        return ()
    if not isinstance(value, list) or not all(isinstance(entry, str) for entry in value):
        raise ValueError(f"{item}: {field} must be an array of strings")
    return tuple(value)


def _safe_relative_path(value: object, *, item: str) -> PurePosixPath:
    if not isinstance(value, str) or not value:
        raise ValueError(f"{item}: source path must be a non-empty string")
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts or "." in path.parts:
        raise ValueError(f"{item}: unsafe source path: {value}")
    return path


def _registry_items(path: Path, *, label: str) -> list[dict[str, object]]:
    payload = _read_object(path)
    items = payload.get("items")
    if not isinstance(items, list) or not items:
        raise ValueError(f"{path}: items must be a non-empty array")
    if not all(isinstance(item, dict) for item in items):
        raise ValueError(f"{path}: every item must be an object")
    typed_items = [item for item in items if isinstance(item, dict)]
    if any(item.get("type") != "registry:ui" for item in typed_items):
        raise ValueError(f"{label} must contain only registry:ui items")
    return typed_items


def _item_identity(item: dict[str, object], *, label: str) -> str:
    identifier = item.get("name")
    if not isinstance(identifier, str) or not identifier:
        raise ValueError(f"{label}: item name must be a non-empty string")
    return identifier


def _single_source_file(
    item: dict[str, object],
    *,
    identifier: str,
) -> dict[str, object]:
    files = item.get("files")
    if not isinstance(files, list) or len(files) != 1 or not isinstance(files[0], dict):
        raise ValueError(f"{identifier}: expected exactly one source file")
    return files[0]


def _license_copyright(payload: bytes) -> str:
    text = payload.decode("utf-8")
    if not text.startswith("MIT License"):
        raise ValueError("upstream LICENSE is not the expected MIT license")
    match = re.search(r"^Copyright \(c\) .+$", text, re.MULTILINE)
    if match is None:
        raise ValueError("upstream LICENSE does not identify its copyright holder")
    return match.group(0)


def _public_registry_names(upstream_root: Path) -> set[str]:
    payload = _read_object(upstream_root / AGGREGATE_REGISTRY)
    items = payload.get("items")
    if not isinstance(items, list):
        raise ValueError(f"{AGGREGATE_REGISTRY}: items must be an array")
    names: list[str] = []
    for index, item in enumerate(items):
        if not isinstance(item, dict):
            raise ValueError(f"{AGGREGATE_REGISTRY}: invalid item at index {index}")
        item_type = item.get("type")
        if item_type not in {"registry:ui", "registry:block"}:
            raise ValueError(f"{AGGREGATE_REGISTRY}: unsupported registry type: {item_type}")
        if item_type == "registry:ui":
            names.append(_item_identity(item, label=AGGREGATE_REGISTRY.as_posix()))
    if len(names) != len(set(names)):
        raise ValueError(f"{AGGREGATE_REGISTRY}: duplicate registry:ui item")
    return set(names)


def _read_public_payload(
    upstream_root: Path,
    *,
    identifier: str,
    expected_upstream_path: str,
    expected_source_bytes: bytes,
) -> tuple[
    bytes,
    tuple[str, ...],
    tuple[str, ...],
    tuple[str, ...],
    str,
    str,
]:
    registry_path = upstream_root / PUBLIC_REGISTRY_ROOT / f"{identifier}.json"
    registry_bytes = _read_required(registry_path)
    try:
        payload = json.loads(registry_bytes.decode("utf-8"))
    except (UnicodeError, json.JSONDecodeError) as error:
        raise ValueError(f"{registry_path}: invalid public registry item: {error}") from error
    if not isinstance(payload, dict):
        raise ValueError(f"{registry_path}: public registry item must be an object")
    if payload.get("name") != identifier or payload.get("type") != "registry:ui":
        raise ValueError(f"{registry_path}: public registry identity mismatch")
    source_record = _single_source_file(payload, identifier=identifier)
    if source_record.get("path") != expected_upstream_path:
        raise ValueError(f"{registry_path}: public registry source path mismatch")
    content = source_record.get("content")
    if not isinstance(content, str) or content.encode("utf-8") != expected_source_bytes:
        raise ValueError(f"{registry_path}: public registry content mismatch")
    title = payload.get("title")
    description = payload.get("description")
    return (
        registry_bytes,
        _string_list(payload.get("dependencies"), field="dependencies", item=identifier),
        _string_list(
            payload.get("registryDependencies"),
            field="registryDependencies",
            item=identifier,
        ),
        _string_list(payload.get("categories"), field="categories", item=identifier),
        title if isinstance(title, str) else identifier,
        description if isinstance(description, str) else "",
    )


def _read_source_registry(
    upstream_root: Path,
    commit: str,
    *,
    registry_path: Path,
    source_root: Path,
    kind: str,
) -> list[UIableItem]:
    public_source_root = "Components" if kind == "component" else "Primitives"
    public_registry_root = "Components" if kind == "component" else "Primitives"
    result: list[UIableItem] = []
    for item in _registry_items(upstream_root / registry_path, label=registry_path.as_posix()):
        identifier = _item_identity(item, label=registry_path.as_posix())
        source_record = _single_source_file(item, identifier=identifier)
        relative_path = _safe_relative_path(source_record.get("path"), item=identifier)
        upstream_relative = source_root.joinpath(*relative_path.parts)
        source_bytes = _read_required(upstream_root / upstream_relative)
        expected_payload_path = upstream_relative.as_posix()
        (
            registry_bytes,
            dependencies,
            registry_dependencies,
            categories,
            title,
            description,
        ) = _read_public_payload(
            upstream_root,
            identifier=identifier,
            expected_upstream_path=expected_payload_path,
            expected_source_bytes=source_bytes,
        )
        registry_relative = PUBLIC_REGISTRY_ROOT / f"{identifier}.json"
        result.append(
            UIableItem(
                identifier=identifier,
                kind=kind,
                title=title,
                description=description,
                categories=categories,
                upstream_path=upstream_relative.as_posix(),
                source_url=(
                    "https://raw.githubusercontent.com/codedthemes/uiable/"
                    f"{commit}/{upstream_relative.as_posix()}"
                ),
                source_path=(
                    f"Sources/UIable/{public_source_root}/{relative_path.as_posix()}"
                ),
                source_bytes=source_bytes,
                registry_upstream_path=registry_relative.as_posix(),
                registry_url=(
                    "https://raw.githubusercontent.com/codedthemes/uiable/"
                    f"{commit}/{registry_relative.as_posix()}"
                ),
                registry_source_path=(
                    f"Sources/UIable/Registry/{public_registry_root}/{identifier}.json"
                ),
                registry_bytes=registry_bytes,
                dependencies=dependencies,
                registry_dependencies=registry_dependencies,
            )
        )
    return result


def read_upstream_snapshot(upstream_root: Path, commit: str) -> UpstreamSnapshot:
    if COMMIT_PATTERN.fullmatch(commit) is None:
        raise ValueError("upstream commit must be a full lowercase Git SHA")
    components = _read_source_registry(
        upstream_root,
        commit,
        registry_path=COMPONENT_REGISTRY,
        source_root=COMPONENT_SOURCE_ROOT,
        kind="component",
    )
    primitives = _read_source_registry(
        upstream_root,
        commit,
        registry_path=PRIMITIVE_REGISTRY,
        source_root=PRIMITIVE_SOURCE_ROOT,
        kind="primitive",
    )
    items = sorted([*components, *primitives], key=lambda item: item.identifier)
    identifiers = [item.identifier for item in items]
    if len(identifiers) != len(set(identifiers)):
        raise ValueError("component and primitive registries contain duplicate item names")
    if set(identifiers) != _public_registry_names(upstream_root):
        raise ValueError("public registry:ui boundary mismatch")
    source_paths = [item.source_path for item in items]
    registry_paths = [item.registry_source_path for item in items]
    if len(source_paths) != len(set(source_paths)) or len(registry_paths) != len(
        set(registry_paths)
    ):
        raise ValueError("duplicate public catalog path")
    category_counts: dict[str, int] = {}
    for item in items:
        for category in item.categories:
            category_counts[category] = category_counts.get(category, 0) + 1
    license_bytes = _read_required(upstream_root / UPSTREAM_LICENSE)
    return UpstreamSnapshot(
        commit=commit,
        items=tuple(items),
        categories=tuple(
            Category(identifier=identifier, count=count)
            for identifier, count in sorted(category_counts.items())
        ),
        license_bytes=license_bytes,
        license_copyright=_license_copyright(license_bytes),
    )


def build_catalog(snapshot: UpstreamSnapshot, version: str) -> dict[str, object]:
    return {
        "version": version,
        "source": "https://uiable.com/components",
        "upstreamRepository": UPSTREAM_REPOSITORY,
        "upstreamRef": UPSTREAM_REF,
        "upstreamCommit": snapshot.commit,
        "scope": (
            "every registry:ui item in the official component and primitive "
            "registries; registry:block items are excluded"
        ),
        "count": len(snapshot.items),
        "componentCount": snapshot.component_count,
        "primitiveCount": snapshot.primitive_count,
        "sourceFileCount": len(snapshot.items),
        "registryItemCount": len(snapshot.items),
        "fileCount": len(snapshot.items) * 2,
        "categories": [dataclasses.asdict(category) for category in snapshot.categories],
        "license": {
            "spdx": "MIT",
            "copyright": snapshot.license_copyright,
            "upstreamPath": UPSTREAM_LICENSE.as_posix(),
            "sourceURL": f"{UPSTREAM_REPOSITORY}/blob/{snapshot.commit}/LICENSE",
            "sourcePath": "Sources/UIable/LICENSE.md",
            "sha256": snapshot.license_sha256,
            "bytes": len(snapshot.license_bytes),
        },
        "items": [item.manifest_record() for item in snapshot.items],
    }


def _catalog_bytes(
    snapshot: UpstreamSnapshot,
    version: str,
    *,
    schema: str | None = None,
) -> bytes:
    catalog = build_catalog(snapshot, version)
    if schema is not None:
        catalog = {"$schema": schema, **catalog}
    return (json.dumps(catalog, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def _package_registry_bytes(root: Path, snapshot: UpstreamSnapshot) -> bytes:
    registry_path = root / "registry/packages.json"
    registry = _read_object(registry_path)
    packages = registry.get("packages")
    if not isinstance(packages, list):
        raise ValueError("registry/packages.json: packages must be an array")
    metadata = next(
        (
            package
            for package in packages
            if isinstance(package, dict) and package.get("id") == "repository-metadata"
        ),
        None,
    )
    if metadata is None or not isinstance(metadata.get("publicPaths"), list):
        raise ValueError("registry/packages.json: repository-metadata package is missing")
    retained = [
        path
        for path in metadata["publicPaths"]
        if isinstance(path, str) and not path.startswith("packages/Sources/UIable/")
    ]
    catalog_paths = [
        "packages/Sources/UIable/LICENSE.md",
        "packages/Sources/UIable/README.md",
        "packages/Sources/UIable/manifest.json",
        *[f"packages/{item.source_path}" for item in snapshot.items],
        *[f"packages/{item.registry_source_path}" for item in snapshot.items],
    ]
    metadata["publicPaths"] = sorted([*retained, *catalog_paths])
    return (json.dumps(registry, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def _readme_bytes(snapshot: UpstreamSnapshot) -> bytes:
    return f"""# UIable exact source catalog

This directory preserves the exact authored source bytes for all {len(snapshot.items)} `registry:ui` items published by the official [UIable Components](https://uiable.com/components) catalog at commit [`{snapshot.commit}`]({UPSTREAM_REPOSITORY}/commit/{snapshot.commit}): {snapshot.component_count} showcase components under `Components/` and {snapshot.primitive_count} required UI primitives under `Primitives/`.

`Registry/Components/` and `Registry/Primitives/` preserve the matching exact public shadcn-compatible registry payload for every source. The payloads are install and provenance metadata, not QenTerra-authored rewrites.

The boundary is the union of `src/components/uiable/registry.json` and `src/components/ui/registry.json`, cross-checked against every `registry:ui` item in `public/r/registry.json`. The 50 `registry:block` items are deliberately excluded because the requested upstream surface is Components, not Blocks. The website, documentation application, previews, examples, media, build tools, and unrelated repository files are also excluded.

The originals under `Components/`, `Primitives/`, and `Registry/` are immutable and are not adapted to QenTerra design tokens. Do not edit them directly. A changed implementation must become a separate QenTerra-owned component under `Sources/QenTerra/Components/`, with its own token usage, tests, registry entry, delivery mapping, version, changelog entry, and derivation provenance. The upstream original remains unchanged.

This catalog is reference source, not an npm or SwiftPM target. UIable components are source-distributed React components and may require the dependencies, aliases, CSS variables, Tailwind configuration, and framework setup declared by their official registry items.

The bundled [`LICENSE.md`](LICENSE.md) is the exact upstream MIT license and identifies the original copyright holder as `{snapshot.license_copyright}`. QenTerra does not claim authorship of these files and does not relicense them under the Apache-2.0 terms that apply to QenTerra-authored public package material.
""".encode("utf-8")


def _expected_files(
    root: Path,
    snapshot: UpstreamSnapshot,
    version: str,
) -> dict[Path, bytes]:
    expected = {
        root / PUBLIC_MANIFEST: _catalog_bytes(snapshot, version),
        root / PRIVATE_REGISTRY: _catalog_bytes(snapshot, version, schema=PRIVATE_SCHEMA),
        root / PUBLIC_LICENSE: snapshot.license_bytes,
        root / PUBLIC_README: _readme_bytes(snapshot),
        root / "registry/packages.json": _package_registry_bytes(root, snapshot),
    }
    for item in snapshot.items:
        expected[root / "packages" / item.source_path] = item.source_bytes
        expected[root / "packages" / item.registry_source_path] = item.registry_bytes
    return expected


def sync_from_checkout(
    upstream_root: Path,
    commit: str,
    *,
    write: bool,
    root: Path = ROOT,
) -> list[str]:
    root = root.resolve()
    snapshot = read_upstream_snapshot(upstream_root.resolve(), commit)
    version = (root / "VERSION").read_text(encoding="utf-8").strip()
    expected = _expected_files(root, snapshot, version)
    catalog_roots = [
        root / COMPONENT_ROOT,
        root / PRIMITIVE_ROOT,
        root / REGISTRY_COMPONENT_ROOT,
        root / REGISTRY_PRIMITIVE_ROOT,
    ]
    actual_catalog_files = {
        path
        for catalog_root in catalog_roots
        if catalog_root.is_dir()
        for path in catalog_root.rglob("*")
        if path.is_file()
    }
    expected_catalog_files = {
        path
        for path in expected
        if any(catalog_root in path.parents for catalog_root in catalog_roots)
    }
    changes = sorted(
        {
            *(
                path.relative_to(root).as_posix()
                for path, payload in expected.items()
                if not path.is_file() or path.read_bytes() != payload
            ),
            *(
                path.relative_to(root).as_posix()
                for path in actual_catalog_files - expected_catalog_files
            ),
        }
    )
    if write:
        for path in sorted(actual_catalog_files - expected_catalog_files, reverse=True):
            path.unlink()
        for path, payload in expected.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(payload)
        for catalog_root in catalog_roots:
            if catalog_root.is_dir():
                for directory in sorted(
                    (path for path in catalog_root.rglob("*") if path.is_dir()),
                    reverse=True,
                ):
                    if not any(directory.iterdir()):
                        directory.rmdir()
    return changes


def _safe_catalog_file(package_root: Path, relative: str, prefix: str) -> Path:
    if not relative.startswith(prefix):
        raise ValueError(f"invalid catalog path: {relative}")
    path = (package_root / relative).resolve()
    allowed = (package_root / prefix).resolve()
    if allowed != path and allowed not in path.parents:
        raise ValueError(f"catalog path escapes its root: {relative}")
    return path


def _validate_recorded_file(
    package_root: Path,
    record: dict[str, object],
    *,
    prefix: str,
    label: str,
) -> tuple[str, bytes]:
    relative = record.get("sourcePath")
    if not isinstance(relative, str):
        raise ValueError(f"invalid {label} source path")
    path = _safe_catalog_file(package_root, relative, prefix)
    if not path.is_file():
        raise ValueError(f"missing {label}: {relative}")
    payload = path.read_bytes()
    if record.get("bytes") != len(payload):
        raise ValueError(f"{label} byte-size mismatch: {relative}")
    if record.get("sha256") != hashlib.sha256(payload).hexdigest():
        raise ValueError(f"{label} hash mismatch: {relative}")
    return relative, payload


def verify_catalog(package_root: Path, manifest_path: Path) -> None:
    manifest = _read_object(manifest_path)
    commit = manifest.get("upstreamCommit")
    if not isinstance(commit, str) or COMMIT_PATTERN.fullmatch(commit) is None:
        raise ValueError(f"{manifest_path}: invalid upstream commit")
    records = manifest.get("items")
    if not isinstance(records, list) or not records:
        raise ValueError(f"{manifest_path}: items must be a non-empty array")
    component_count = sum(
        isinstance(record, dict) and record.get("kind") == "component"
        for record in records
    )
    primitive_count = sum(
        isinstance(record, dict) and record.get("kind") == "primitive"
        for record in records
    )
    count = len(records)
    if (
        manifest.get("count") != count
        or manifest.get("componentCount") != component_count
        or manifest.get("primitiveCount") != primitive_count
        or component_count + primitive_count != count
        or manifest.get("sourceFileCount") != count
        or manifest.get("registryItemCount") != count
        or manifest.get("fileCount") != count * 2
    ):
        raise ValueError(f"{manifest_path}: item or file count mismatch")

    identifiers: set[str] = set()
    source_paths: set[str] = set()
    registry_paths: set[str] = set()
    category_counts: dict[str, int] = {}
    for index, record in enumerate(records):
        if not isinstance(record, dict):
            raise ValueError(f"{manifest_path}: invalid item at index {index}")
        identifier = record.get("id")
        kind = record.get("kind")
        if not isinstance(identifier, str) or not identifier:
            raise ValueError(f"{manifest_path}: invalid item id at index {index}")
        if identifier in identifiers:
            raise ValueError(f"{manifest_path}: duplicate item id: {identifier}")
        if kind not in {"component", "primitive"}:
            raise ValueError(f"{manifest_path}: invalid item kind for {identifier}")
        identifiers.add(identifier)
        categories = record.get("categories")
        if not isinstance(categories, list) or not all(
            isinstance(category, str) for category in categories
        ):
            raise ValueError(f"{manifest_path}: invalid categories for {identifier}")
        for category in categories:
            category_counts[category] = category_counts.get(category, 0) + 1

        source_prefix = (
            "Sources/UIable/Components/"
            if kind == "component"
            else "Sources/UIable/Primitives/"
        )
        upstream_prefix = (
            "src/components/uiable/" if kind == "component" else "src/components/ui/"
        )
        upstream_path = record.get("upstreamPath")
        if not isinstance(upstream_path, str) or not upstream_path.startswith(upstream_prefix):
            raise ValueError(f"{manifest_path}: invalid upstream path for {identifier}")
        expected_source_url = (
            "https://raw.githubusercontent.com/codedthemes/uiable/"
            f"{commit}/{upstream_path}"
        )
        if record.get("sourceURL") != expected_source_url:
            raise ValueError(f"{manifest_path}: unpinned source URL for {identifier}")
        source_relative, source_bytes = _validate_recorded_file(
            package_root,
            record,
            prefix=source_prefix,
            label="original source",
        )
        if source_relative in source_paths:
            raise ValueError(f"{manifest_path}: duplicate source path: {source_relative}")
        source_paths.add(source_relative)

        registry_record = record.get("registryItem")
        if not isinstance(registry_record, dict):
            raise ValueError(f"{manifest_path}: registry item missing for {identifier}")
        registry_upstream_path = f"public/r/{identifier}.json"
        if registry_record.get("upstreamPath") != registry_upstream_path:
            raise ValueError(f"{manifest_path}: invalid registry path for {identifier}")
        expected_registry_url = (
            "https://raw.githubusercontent.com/codedthemes/uiable/"
            f"{commit}/{registry_upstream_path}"
        )
        if registry_record.get("sourceURL") != expected_registry_url:
            raise ValueError(f"{manifest_path}: unpinned registry URL for {identifier}")
        registry_prefix = (
            "Sources/UIable/Registry/Components/"
            if kind == "component"
            else "Sources/UIable/Registry/Primitives/"
        )
        registry_relative, registry_bytes = _validate_recorded_file(
            package_root,
            registry_record,
            prefix=registry_prefix,
            label="registry item",
        )
        if registry_relative in registry_paths:
            raise ValueError(f"{manifest_path}: duplicate registry path: {registry_relative}")
        registry_paths.add(registry_relative)
        try:
            registry_payload = json.loads(registry_bytes.decode("utf-8"))
        except (UnicodeError, json.JSONDecodeError) as error:
            raise ValueError(
                f"{manifest_path}: invalid registry payload for {identifier}: {error}"
            ) from error
        if (
            not isinstance(registry_payload, dict)
            or registry_payload.get("name") != identifier
            or registry_payload.get("type") != "registry:ui"
        ):
            raise ValueError(f"{manifest_path}: registry identity mismatch for {identifier}")
        files = registry_payload.get("files")
        if not isinstance(files, list) or len(files) != 1 or not isinstance(files[0], dict):
            raise ValueError(f"{manifest_path}: invalid registry files for {identifier}")
        if files[0].get("path") != upstream_path:
            raise ValueError(f"{manifest_path}: registry source path mismatch for {identifier}")
        content = files[0].get("content")
        if not isinstance(content, str) or content.encode("utf-8") != source_bytes:
            raise ValueError(f"{manifest_path}: registry content mismatch for {identifier}")

    expected_actual_roots = [
        package_root / "Sources/UIable/Components",
        package_root / "Sources/UIable/Primitives",
    ]
    actual_source_paths = {
        path.relative_to(package_root).as_posix()
        for root in expected_actual_roots
        if root.is_dir()
        for path in root.rglob("*")
        if path.is_file()
    }
    expected_registry_roots = [
        package_root / "Sources/UIable/Registry/Components",
        package_root / "Sources/UIable/Registry/Primitives",
    ]
    actual_registry_paths = {
        path.relative_to(package_root).as_posix()
        for root in expected_registry_roots
        if root.is_dir()
        for path in root.rglob("*")
        if path.is_file()
    }
    if source_paths != actual_source_paths:
        raise ValueError(f"{manifest_path}: source catalog is not closed")
    if registry_paths != actual_registry_paths:
        raise ValueError(f"{manifest_path}: registry catalog is not closed")

    categories = manifest.get("categories")
    if not isinstance(categories, list):
        raise ValueError(f"{manifest_path}: categories must be an array")
    declared_category_counts: dict[str, int] = {}
    for index, category_record in enumerate(categories):
        if not isinstance(category_record, dict):
            raise ValueError(f"{manifest_path}: invalid category at index {index}")
        identifier = category_record.get("identifier")
        count_value = category_record.get("count")
        if not isinstance(identifier, str) or not identifier or type(count_value) is not int:
            raise ValueError(f"{manifest_path}: invalid category at index {index}")
        if identifier in declared_category_counts:
            raise ValueError(f"{manifest_path}: duplicate category: {identifier}")
        declared_category_counts[identifier] = count_value
    if declared_category_counts != category_counts:
        raise ValueError(f"{manifest_path}: category counts do not match items")

    license_record = manifest.get("license")
    if not isinstance(license_record, dict) or license_record.get("spdx") != "MIT":
        raise ValueError(f"{manifest_path}: upstream MIT license is missing")
    copyright_line = license_record.get("copyright")
    if not isinstance(copyright_line, str) or "CodedThemes" not in copyright_line:
        raise ValueError(f"{manifest_path}: upstream authorship is missing")
    _, license_bytes = _validate_recorded_file(
        package_root,
        license_record,
        prefix="Sources/UIable/",
        label="upstream license",
    )
    if _license_copyright(license_bytes) != copyright_line:
        raise ValueError(f"{manifest_path}: license authorship mismatch")
    expected_license_url = f"{UPSTREAM_REPOSITORY}/blob/{commit}/LICENSE"
    if license_record.get("sourceURL") != expected_license_url:
        raise ValueError(f"{manifest_path}: unpinned upstream license URL")


def _checkout_upstream() -> tuple[tempfile.TemporaryDirectory[str], Path, str]:
    temporary = tempfile.TemporaryDirectory(prefix="design-system-uiable-")
    checkout = Path(temporary.name) / "uiable"
    try:
        subprocess.run(
            [
                "git",
                "clone",
                "--depth",
                "1",
                "--branch",
                UPSTREAM_BRANCH,
                "--single-branch",
                "--filter=blob:none",
                UPSTREAM_GIT_URL,
                str(checkout),
            ],
            check=True,
        )
        commit = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            cwd=checkout,
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        if COMMIT_PATTERN.fullmatch(commit) is None:
            raise ValueError("upstream checkout returned an invalid commit")
        return temporary, checkout, commit
    except Exception:
        temporary.cleanup()
        raise


def sync_catalog(*, write: bool, root: Path = ROOT) -> list[str]:
    temporary, checkout, commit = _checkout_upstream()
    try:
        return sync_from_checkout(checkout, commit, write=write, root=root)
    finally:
        temporary.cleanup()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    sync = subparsers.add_parser("sync", help="compare with or write the live catalog")
    mode = sync.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--write", action="store_true")
    subparsers.add_parser("verify", help="verify the stored catalog without network access")
    arguments = parser.parse_args(argv)

    try:
        if arguments.command == "sync":
            changes = sync_catalog(write=arguments.write)
            if changes and arguments.check:
                print("UIable source catalog is stale:", file=sys.stderr)
                for change in changes:
                    print(f"- {change}", file=sys.stderr)
                return 1
            manifest = _read_object(ROOT / PUBLIC_MANIFEST)
            action = "Updated" if arguments.write else "Verified"
            print(
                f"{action} {manifest['count']} exact UIable registry:ui items "
                f"({manifest['componentCount']} components, "
                f"{manifest['primitiveCount']} primitives)"
            )
            return 0
        verify_catalog(ROOT / "packages", ROOT / PUBLIC_MANIFEST)
        manifest = _read_object(ROOT / PUBLIC_MANIFEST)
        print(
            f"Verified {manifest['count']} immutable UIable sources "
            f"and {manifest['registryItemCount']} registry items"
        )
        return 0
    except (
        OSError,
        UnicodeError,
        ValueError,
        json.JSONDecodeError,
        subprocess.CalledProcessError,
    ) as error:
        print(f"UIable operation failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
