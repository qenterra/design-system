#!/usr/bin/env python3
"""Synchronize and verify the exact official free ReUI source catalog."""

from __future__ import annotations

import argparse
import concurrent.futures
import dataclasses
import hashlib
import json
import re
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path, PurePosixPath


ROOT = Path(__file__).resolve().parents[1]
UPSTREAM_REPOSITORY = "https://github.com/keenthemes/reui"
UPSTREAM_GIT_URL = f"{UPSTREAM_REPOSITORY}.git"
UPSTREAM_BRANCH = "main"
UPSTREAM_REF = f"refs/heads/{UPSTREAM_BRANCH}"
UPSTREAM_LICENSE = Path("LICENSE.md")
BASES = ("base", "radix")
STYLE_BY_BASE = {"base": "base-nova", "radix": "radix-nova"}
LIVE_REGISTRY_ROOT = "https://reui.io/r/styles"
CAPTURE_METADATA = Path(".reui-capture.json")
CACHE_ROOT = Path(tempfile.gettempdir()) / "design-system-reui-cache"
PUBLIC_ROOT = Path("packages/Sources/ReUI")
PUBLIC_MANIFEST = PUBLIC_ROOT / "manifest.json"
PUBLIC_LICENSE = PUBLIC_ROOT / "LICENSE.md"
PUBLIC_README = PUBLIC_ROOT / "README.md"
PRIVATE_REGISTRY = Path("registry/reui.json")
PRIVATE_SCHEMA = "../schemas/reui-registry.schema.json"
COMMIT_PATTERN = re.compile(r"^[0-9a-f]{40}$")
ALLOWED_TYPES = {
    "registry:block": "example",
    "registry:ui": "primitive",
    "registry:hook": "hook",
}
REVISION_PATTERN = re.compile(r"^dpl_[A-Za-z0-9_]+$")


@dataclasses.dataclass(frozen=True)
class Category:
    identifier: str
    count: int


@dataclasses.dataclass(frozen=True)
class RegistryIndex:
    base: str
    style: str
    upstream_path: str
    source_url: str
    payload: bytes

    @property
    def sha256(self) -> str:
        return hashlib.sha256(self.payload).hexdigest()

    def manifest_record(self) -> dict[str, object]:
        return {
            "base": self.base,
            "style": self.style,
            "upstreamPath": self.upstream_path,
            "sourceURL": self.source_url,
            "sha256": self.sha256,
            "bytes": len(self.payload),
        }


@dataclasses.dataclass(frozen=True)
class SourceFile:
    origin: str
    upstream_path: str
    source_url: str
    source_path: str
    payload: bytes

    @property
    def sha256(self) -> str:
        return hashlib.sha256(self.payload).hexdigest()

    def manifest_record(self) -> dict[str, object]:
        return {
            "origin": self.origin,
            "upstreamPath": self.upstream_path,
            "sourceURL": self.source_url,
            "sourcePath": self.source_path,
            "sha256": self.sha256,
            "bytes": len(self.payload),
        }


@dataclasses.dataclass(frozen=True)
class ReUIItem:
    base: str
    style: str
    identifier: str
    kind: str
    title: str
    description: str
    categories: tuple[str, ...]
    dependencies: tuple[str, ...]
    registry_dependencies: tuple[str, ...]
    sources: tuple[SourceFile, ...]
    registry_origin: str
    registry_upstream_path: str
    registry_url: str
    registry_source_path: str
    registry_bytes: bytes

    @property
    def registry_sha256(self) -> str:
        return hashlib.sha256(self.registry_bytes).hexdigest()

    def manifest_record(self) -> dict[str, object]:
        return {
            "id": f"{self.base}:{self.identifier}",
            "name": self.identifier,
            "base": self.base,
            "style": self.style,
            "kind": self.kind,
            "title": self.title,
            "description": self.description,
            "categories": list(self.categories),
            "language": "TypeScript",
            "documentationURL": "https://reui.io/components",
            "dependencies": list(self.dependencies),
            "registryDependencies": list(self.registry_dependencies),
            "sourcePaths": [source.source_path for source in self.sources],
            "registryItem": {
                "origin": self.registry_origin,
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
    registry_revision: str
    registry_indexes: tuple[RegistryIndex, ...]
    items: tuple[ReUIItem, ...]
    categories: tuple[Category, ...]
    license_bytes: bytes
    license_copyright: str

    @property
    def example_count(self) -> int:
        return sum(item.kind == "example" for item in self.items)

    @property
    def primitive_count(self) -> int:
        return sum(item.kind == "primitive" for item in self.items)

    @property
    def hook_count(self) -> int:
        return sum(item.kind == "hook" for item in self.items)

    @property
    def repository_item_count(self) -> int:
        return sum(item.registry_origin == "repository" for item in self.items)

    @property
    def live_registry_item_count(self) -> int:
        return sum(item.registry_origin == "live-registry" for item in self.items)

    @property
    def source_files(self) -> tuple[SourceFile, ...]:
        by_path: dict[str, SourceFile] = {}
        for item in self.items:
            for source in item.sources:
                previous = by_path.get(source.source_path)
                if previous is not None and previous.payload != source.payload:
                    raise ValueError(
                        f"conflicting source bytes for {source.source_path}"
                    )
                by_path[source.source_path] = source
        return tuple(by_path[path] for path in sorted(by_path))

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


def _safe_path(value: object, *, label: str) -> PurePosixPath:
    if not isinstance(value, str) or not value:
        raise ValueError(f"{label} must be a non-empty string")
    path = PurePosixPath(value)
    if path.is_absolute() or "." in path.parts or ".." in path.parts:
        raise ValueError(f"unsafe {label}: {value}")
    return path


def _license_copyright(payload: bytes) -> str:
    text = payload.decode("utf-8")
    if not text.startswith("MIT License"):
        raise ValueError("upstream LICENSE.md is not the expected MIT license")
    match = re.search(r"^Copyright \(c\) .+$", text, re.MULTILINE)
    if match is None or "Keenthemes" not in match.group(0):
        raise ValueError("upstream LICENSE.md does not identify Keenthemes")
    return match.group(0)


def _manifest_items(path: Path) -> list[dict[str, object]]:
    payload = _read_object(path)
    if payload.get("name") != "reui" or payload.get("homepage") != "https://reui.io":
        raise ValueError(f"{path}: invalid ReUI registry identity")
    items = payload.get("items")
    if not isinstance(items, list) or not items or not all(
        isinstance(item, dict) for item in items
    ):
        raise ValueError(f"{path}: items must be a non-empty object array")
    typed_items = [item for item in items if isinstance(item, dict)]
    identities = [(item.get("name"), item.get("type")) for item in typed_items]
    if any(
        not isinstance(name, str) or not name or item_type not in ALLOWED_TYPES
        for name, item_type in identities
    ):
        raise ValueError(f"{path}: unsupported or invalid registry item")
    if len(identities) != len(set(identities)):
        raise ValueError(f"{path}: duplicate registry item")
    return typed_items


def _registry_revision(upstream_root: Path) -> str:
    metadata = _read_object(upstream_root / CAPTURE_METADATA)
    revision = metadata.get("registryRevision")
    if not isinstance(revision, str) or REVISION_PATTERN.fullmatch(revision) is None:
        raise ValueError("live registry capture has an invalid deployment revision")
    return revision


def _payload_origins(upstream_root: Path) -> dict[str, dict[str, str]]:
    metadata = _read_object(upstream_root / CAPTURE_METADATA)
    payload = metadata.get("payloadOrigins", {})
    if not isinstance(payload, dict):
        raise ValueError("live registry capture has invalid payload origins")
    result: dict[str, dict[str, str]] = {}
    for style, records in payload.items():
        if style not in STYLE_BY_BASE.values() or not isinstance(records, dict):
            raise ValueError("live registry capture has invalid payload origins")
        typed: dict[str, str] = {}
        for identifier, origin in records.items():
            if (
                not isinstance(identifier, str)
                or origin not in {"repository", "live-registry"}
            ):
                raise ValueError("live registry capture has invalid payload origins")
            typed[identifier] = origin
        result[str(style)] = typed
    return result


def _live_registry_url(style: str, name: str, revision: str) -> str:
    return f"{LIVE_REGISTRY_ROOT}/{style}/{name}.json?v={revision}"


def _registry_payload_url(
    *,
    origin: str,
    commit: str,
    style: str,
    identifier: str,
    registry_revision: str,
) -> str:
    if origin == "repository":
        return (
            "https://raw.githubusercontent.com/keenthemes/reui/"
            f"{commit}/public/r/styles/{style}/{identifier}.json"
        )
    if origin == "live-registry":
        return _live_registry_url(style, identifier, registry_revision)
    raise ValueError(f"{identifier}: invalid registry payload origin")


def _source_for_file(
    *,
    base: str,
    style: str,
    identifier: str,
    kind: str,
    registry_path: str,
    registry_revision: str,
    registry_origin: str,
    commit: str,
    file_record: dict[str, object],
) -> SourceFile:
    target = _safe_path(file_record.get("target"), label="registry target")
    target_string = target.as_posix()
    public_base = base.title()
    if target_string.startswith("components/examples/"):
        match = re.fullmatch(r"c-(.+)-([0-9]+)", identifier)
        if kind != "example" or match is None:
            raise ValueError(f"{target_string}: free example identity mismatch")
        relative = PurePosixPath(match.group(1)) / target.name
        public = PurePosixPath("Sources/ReUI") / public_base / "Components" / relative
    elif target_string.startswith("components/reui/"):
        if kind != "primitive":
            raise ValueError(f"{target_string}: primitive type mismatch")
        relative = target.relative_to("components/reui")
        public = PurePosixPath("Sources/ReUI") / public_base / "Primitives" / relative
    elif target_string.startswith("hooks/"):
        if kind != "hook":
            raise ValueError(f"{target_string}: hook type mismatch")
        relative = target.relative_to("hooks")
        public = PurePosixPath("Sources/ReUI") / public_base / "Hooks" / relative
    elif target_string.startswith("components/ui/svgs/"):
        if kind != "example":
            raise ValueError(f"{target_string}: shared SVG type mismatch")
        relative = target.relative_to("components/ui/svgs")
        public = PurePosixPath("Sources/ReUI/Shared/SVGs") / relative
    else:
        raise ValueError(f"unsupported public registry target: {target_string}")
    content = file_record.get("content")
    if not isinstance(content, str) or not content:
        raise ValueError(f"{identifier}: registry source content is missing")
    payload = content.encode("utf-8")
    source_url = _registry_payload_url(
        origin=registry_origin,
        commit=commit,
        style=style,
        identifier=identifier,
        registry_revision=registry_revision,
    )
    return SourceFile(
        origin=registry_origin,
        upstream_path=f"{registry_path}#target={target_string}",
        source_url=source_url,
        source_path=public.as_posix(),
        payload=payload,
    )


def _read_base_items(
    upstream_root: Path,
    commit: str,
    *,
    base: str,
    registry_revision: str,
    payload_origins: dict[str, dict[str, str]],
) -> list[ReUIItem]:
    style = STYLE_BY_BASE[base]
    registry_root = Path("public/r/styles") / style
    manifest_path = upstream_root / registry_root / "registry.json"
    all_manifest_items = _manifest_items(manifest_path)
    manifest_items = [
        item
        for item in all_manifest_items
        if item["type"] != "registry:block"
        or str(item["name"]).startswith("c-")
    ]
    expected = {(str(item["name"]), str(item["type"])) for item in manifest_items}
    payload_paths = {
        path.stem: path
        for path in (upstream_root / registry_root).glob("*.json")
        if path.name not in {"registry.json", "index.json"}
    }
    if set(payload_paths) != {name for name, _ in expected}:
        raise ValueError(f"{style}: public registry boundary mismatch")
    result: list[ReUIItem] = []
    for manifest_item in manifest_items:
        identifier = str(manifest_item["name"])
        item_type = str(manifest_item["type"])
        registry_origin = payload_origins.get(style, {}).get(
            identifier, "live-registry"
        )
        payload_path = payload_paths[identifier]
        registry_bytes = _read_required(payload_path)
        payload = _read_object(payload_path)
        if payload.get("name") != identifier or payload.get("type") != item_type:
            raise ValueError(f"{payload_path}: public registry boundary mismatch")
        kind = ALLOWED_TYPES[item_type]
        categories = (
            (re.fullmatch(r"c-(.+)-[0-9]+", identifier).group(1),)
            if kind == "example" and re.fullmatch(r"c-(.+)-[0-9]+", identifier)
            else _string_list(
                payload.get("categories", manifest_item.get("categories")),
                field="categories",
                item=identifier,
            )
        )
        files = payload.get("files")
        if not isinstance(files, list) or not files or not all(
            isinstance(file, dict) for file in files
        ):
            raise ValueError(f"{payload_path}: files must be a non-empty object array")
        sources = tuple(
            _source_for_file(
                base=base,
                style=style,
                identifier=identifier,
                kind=kind,
                registry_path=(registry_root / f"{identifier}.json").as_posix(),
                registry_revision=registry_revision,
                registry_origin=registry_origin,
                commit=commit,
                file_record=file,
            )
            for file in files
            if isinstance(file, dict)
        )
        title = payload.get("title")
        description = payload.get("description")
        registry_relative = registry_root / f"{identifier}.json"
        result.append(
            ReUIItem(
                base=base,
                style=style,
                identifier=identifier,
                kind=kind,
                title=title if isinstance(title, str) and title else identifier,
                description=description if isinstance(description, str) else "",
                categories=categories,
                dependencies=_string_list(
                    payload.get("dependencies"),
                    field="dependencies",
                    item=identifier,
                ),
                registry_dependencies=_string_list(
                    payload.get("registryDependencies"),
                    field="registryDependencies",
                    item=identifier,
                ),
                sources=sources,
                registry_origin=registry_origin,
                registry_upstream_path=registry_relative.as_posix(),
                registry_url=_registry_payload_url(
                    origin=registry_origin,
                    commit=commit,
                    style=style,
                    identifier=identifier,
                    registry_revision=registry_revision,
                ),
                registry_source_path=(
                    f"Sources/ReUI/Registry/{style.replace('-', ' ').title().replace(' ', '')}/"
                    f"{identifier}.json"
                ),
                registry_bytes=registry_bytes,
            )
        )
    kind_order = {"example": 0, "primitive": 1, "hook": 2}
    return sorted(result, key=lambda item: (kind_order[item.kind], item.identifier))


def read_upstream_snapshot(upstream_root: Path, commit: str) -> UpstreamSnapshot:
    if COMMIT_PATTERN.fullmatch(commit) is None:
        raise ValueError("upstream commit must be a full lowercase Git SHA")
    registry_revision = _registry_revision(upstream_root)
    payload_origins = _payload_origins(upstream_root)
    items_by_base = {
        base: _read_base_items(
            upstream_root,
            commit,
            base=base,
            registry_revision=registry_revision,
            payload_origins=payload_origins,
        )
        for base in BASES
    }
    identity_sets = {
        base: {(item.identifier, item.kind) for item in items}
        for base, items in items_by_base.items()
    }
    if identity_sets["base"] != identity_sets["radix"]:
        raise ValueError("Base UI and Radix UI public registry boundary mismatch")

    observed_by_base: dict[str, dict[str, int]] = {}
    for base, items in items_by_base.items():
        observed: dict[str, int] = {}
        for item in items:
            if item.kind == "example":
                for category in item.categories:
                    observed[category] = observed.get(category, 0) + 1
        observed_by_base[base] = observed
    if observed_by_base["base"] != observed_by_base["radix"]:
        raise ValueError("Base UI and Radix UI category boundary mismatch")
    declared = observed_by_base["base"]

    all_items = tuple(
        item for base in BASES for item in items_by_base[base]
    )
    license_bytes = _read_required(upstream_root / UPSTREAM_LICENSE)
    registry_indexes = tuple(
        RegistryIndex(
            base=base,
            style=STYLE_BY_BASE[base],
            upstream_path=(
                Path("public/r/styles") / STYLE_BY_BASE[base] / "registry.json"
            ).as_posix(),
            source_url=_live_registry_url(
                STYLE_BY_BASE[base], "registry", registry_revision
            ),
            payload=_read_required(
                upstream_root
                / "public/r/styles"
                / STYLE_BY_BASE[base]
                / "registry.json"
            ),
        )
        for base in BASES
    )
    return UpstreamSnapshot(
        commit=commit,
        registry_revision=registry_revision,
        registry_indexes=registry_indexes,
        items=all_items,
        categories=tuple(
            Category(identifier=name, count=count * len(BASES))
            for name, count in sorted(declared.items())
        ),
        license_bytes=license_bytes,
        license_copyright=_license_copyright(license_bytes),
    )


def build_catalog(snapshot: UpstreamSnapshot, version: str) -> dict[str, object]:
    return {
        "version": version,
        "source": "https://reui.io/components",
        "upstreamRepository": UPSTREAM_REPOSITORY,
        "upstreamRef": UPSTREAM_REF,
        "upstreamCommit": snapshot.commit,
        "registryOrigin": LIVE_REGISTRY_ROOT,
        "registryRevision": snapshot.registry_revision,
        "registryIndexes": [
            index.manifest_record() for index in snapshot.registry_indexes
        ],
        "scope": (
            "all free public ReUI registry items for Base UI Nova and Radix UI Nova; "
            "commercial blocks, icons, templates, the site, docs, media, and build tooling are excluded"
        ),
        "bases": list(BASES),
        "count": len(snapshot.items),
        "exampleCount": snapshot.example_count,
        "primitiveCount": snapshot.primitive_count,
        "hookCount": snapshot.hook_count,
        "repositoryItemCount": snapshot.repository_item_count,
        "liveRegistryItemCount": snapshot.live_registry_item_count,
        "sourceFileCount": len(snapshot.source_files),
        "registryItemCount": len(snapshot.items),
        "fileCount": len(snapshot.source_files) + len(snapshot.items),
        "categories": [dataclasses.asdict(category) for category in snapshot.categories],
        "license": {
            "spdx": "MIT",
            "copyright": snapshot.license_copyright,
            "upstreamPath": UPSTREAM_LICENSE.as_posix(),
            "sourceURL": f"{UPSTREAM_REPOSITORY}/blob/{snapshot.commit}/LICENSE.md",
            "sourcePath": "Sources/ReUI/LICENSE.md",
            "sha256": snapshot.license_sha256,
            "bytes": len(snapshot.license_bytes),
        },
        "sources": [source.manifest_record() for source in snapshot.source_files],
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
    registry = _read_object(root / "registry/packages.json")
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
        if isinstance(path, str) and not path.startswith("packages/Sources/ReUI/")
    ]
    paths = [
        "packages/Sources/ReUI/LICENSE.md",
        "packages/Sources/ReUI/README.md",
        "packages/Sources/ReUI/manifest.json",
        *[f"packages/{source.source_path}" for source in snapshot.source_files],
        *[f"packages/{item.registry_source_path}" for item in snapshot.items],
    ]
    metadata["publicPaths"] = sorted([*retained, *paths])
    return (json.dumps(registry, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def _readme_bytes(snapshot: UpstreamSnapshot) -> bytes:
    per_base_examples = snapshot.example_count // len(BASES)
    return f"""# ReUI exact source catalog

This directory preserves the exact official source bytes for the free [ReUI Components](https://reui.io/components) registry at immutable live deployment `{snapshot.registry_revision}`. The bundled MIT license is pinned to repository commit [`{snapshot.commit}`]({UPSTREAM_REPOSITORY}/commit/{snapshot.commit}). The catalog contains both supported implementations: Base UI and Radix UI. Each base includes {per_base_examples} public examples plus the ReUI primitives and hooks required by the registry.

`Base/` and `Radix/` preserve the authored component, primitive, and hook sources. `Shared/SVGs/` contains exact shared logo components referenced by public examples. `Registry/BaseNova/` and `Registry/RadixNova/` preserve the matching install-ready shadcn registry payloads. ReUI produces these payloads with style/import transformations; they remain exact upstream bytes and are not QenTerra rewrites.

Provenance is explicit rather than cosmetically uniform: {snapshot.repository_item_count} unchanged payloads are pinned to the official Git repository commit, while {snapshot.live_registry_item_count} additions or changes absent from that commit are pinned to the immutable live deployment. The two live aggregate-index hashes close the current free item boundary.

The boundary is the complete free item union declared by the live `base-nova/registry.json` and `radix-nova/registry.json` indexes: every `c-*` block plus every public `registry:ui` primitive and `registry:hook`. The two index payloads and every install payload are hash-pinned to the same deployment. ReUI Pro blocks, paid icons, templates, the website, documentation application, screenshots, videos, and build tooling are excluded. They are not part of the free open-source component registry, and pretending otherwise would be both technically wrong and legally sloppy.

The originals under this directory are immutable and are not adapted to QenTerra design tokens. Do not edit them directly. A modified or tokenized implementation must become a separate maintained component under `Sources/QenTerra/Components/`, with derivation provenance, token usage, tests, registry entry, delivery mapping, version, and changelog coverage. The ReUI original remains unchanged.

This catalog is reference source, not an npm or SwiftPM target. ReUI follows the copy-and-own shadcn model rather than publishing an npm component package. Install a selected registry item with the compatible shadcn workflow after reviewing its dependencies and target paths.

The bundled [`LICENSE.md`](LICENSE.md) is the exact upstream MIT license and identifies the original copyright holder as `{snapshot.license_copyright}`. QenTerra does not claim authorship of these files and does not relicense them under the Apache-2.0 terms that apply to QenTerra-authored public package material.
""".encode("utf-8")


def _expected_files(
    root: Path,
    snapshot: UpstreamSnapshot,
    version: str,
) -> dict[Path, bytes]:
    expected = {
        root / PUBLIC_MANIFEST: _catalog_bytes(snapshot, version),
        root / PRIVATE_REGISTRY: _catalog_bytes(
            snapshot,
            version,
            schema=PRIVATE_SCHEMA,
        ),
        root / PUBLIC_LICENSE: snapshot.license_bytes,
        root / PUBLIC_README: _readme_bytes(snapshot),
        root / "registry/packages.json": _package_registry_bytes(root, snapshot),
    }
    for source in snapshot.source_files:
        expected[root / "packages" / source.source_path] = source.payload
    for item in snapshot.items:
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
    catalog_root = root / PUBLIC_ROOT
    actual = {
        path for path in catalog_root.rglob("*") if path.is_file()
    } if catalog_root.is_dir() else set()
    retained = {
        root / PUBLIC_MANIFEST,
        root / PUBLIC_LICENSE,
        root / PUBLIC_README,
    }
    expected_catalog = {
        path for path in expected if catalog_root in path.parents or path in retained
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
                for path in actual - expected_catalog
            ),
        }
    )
    if write:
        for path in sorted(actual - expected_catalog, reverse=True):
            path.unlink()
        for path, payload in expected.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(payload)
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
    registry_revision = manifest.get("registryRevision")
    if (
        not isinstance(registry_revision, str)
        or REVISION_PATTERN.fullmatch(registry_revision) is None
    ):
        raise ValueError(f"{manifest_path}: invalid registry deployment revision")
    if manifest.get("registryOrigin") != LIVE_REGISTRY_ROOT:
        raise ValueError(f"{manifest_path}: invalid registry origin")
    registry_indexes = manifest.get("registryIndexes")
    if not isinstance(registry_indexes, list) or len(registry_indexes) != len(BASES):
        raise ValueError(f"{manifest_path}: registry indexes are missing")
    for base, record in zip(BASES, registry_indexes):
        style = STYLE_BY_BASE[base]
        if not isinstance(record, dict):
            raise ValueError(f"{manifest_path}: invalid {base} registry index")
        if (
            record.get("base") != base
            or record.get("style") != style
            or record.get("upstreamPath")
            != f"public/r/styles/{style}/registry.json"
            or record.get("sourceURL")
            != _live_registry_url(style, "registry", registry_revision)
            or not isinstance(record.get("sha256"), str)
            or not isinstance(record.get("bytes"), int)
        ):
            raise ValueError(f"{manifest_path}: invalid {base} registry index")
    sources = manifest.get("sources")
    items = manifest.get("items")
    if not isinstance(sources, list) or not sources or not isinstance(items, list) or not items:
        raise ValueError(f"{manifest_path}: sources and items must be non-empty arrays")
    source_paths: set[str] = set()
    source_payloads: dict[str, bytes] = {}
    for index, record in enumerate(sources):
        if not isinstance(record, dict):
            raise ValueError(f"{manifest_path}: invalid source at index {index}")
        relative, payload = _validate_recorded_file(
            package_root,
            record,
            prefix="Sources/ReUI/",
            label="original source",
        )
        if relative in source_paths:
            raise ValueError(f"{manifest_path}: duplicate source path {relative}")
        source_paths.add(relative)
        source_payloads[relative] = payload
        upstream = record.get("upstreamPath")
        if not isinstance(upstream, str):
            raise ValueError(f"{manifest_path}: invalid source origin for {relative}")
        registry_origin = upstream.split("#", 1)[0]
        origin = record.get("origin")
        style_and_name = PurePosixPath(registry_origin).parts[-2:]
        if len(style_and_name) != 2:
            raise ValueError(f"{manifest_path}: invalid source origin for {relative}")
        style, filename = style_and_name
        expected_url = _registry_payload_url(
            origin=str(origin),
            commit=commit,
            style=style,
            identifier=PurePosixPath(filename).stem,
            registry_revision=registry_revision,
        )
        if record.get("sourceURL") != expected_url:
            raise ValueError(f"{manifest_path}: invalid source URL for {relative}")

    item_ids: set[str] = set()
    registry_paths: set[str] = set()
    kind_counts = {"example": 0, "primitive": 0, "hook": 0}
    origin_counts = {"repository": 0, "live-registry": 0}
    for index, item in enumerate(items):
        if not isinstance(item, dict):
            raise ValueError(f"{manifest_path}: invalid item at index {index}")
        identifier = item.get("id")
        kind = item.get("kind")
        if not isinstance(identifier, str) or identifier in item_ids:
            raise ValueError(f"{manifest_path}: invalid or duplicate item id")
        if kind not in kind_counts:
            raise ValueError(f"{manifest_path}: invalid kind for {identifier}")
        item_ids.add(identifier)
        kind_counts[str(kind)] += 1
        references = item.get("sourcePaths")
        if not isinstance(references, list) or not references or not all(
            isinstance(reference, str) and reference in source_paths
            for reference in references
        ):
            raise ValueError(f"{manifest_path}: invalid source references for {identifier}")
        registry = item.get("registryItem")
        if not isinstance(registry, dict):
            raise ValueError(f"{manifest_path}: missing registry item for {identifier}")
        origin = registry.get("origin")
        if origin not in origin_counts:
            raise ValueError(f"{manifest_path}: invalid registry origin for {identifier}")
        origin_counts[str(origin)] += 1
        relative, payload_bytes = _validate_recorded_file(
            package_root,
            registry,
            prefix="Sources/ReUI/Registry/",
            label="registry item",
        )
        if relative in registry_paths:
            raise ValueError(f"{manifest_path}: duplicate registry path {relative}")
        registry_paths.add(relative)
        payload = json.loads(payload_bytes.decode("utf-8"))
        expected_type = {
            "example": "registry:block",
            "primitive": "registry:ui",
            "hook": "registry:hook",
        }[str(kind)]
        if (
            not isinstance(payload, dict)
            or payload.get("name") != item.get("name")
            or payload.get("type") != expected_type
        ):
            raise ValueError(f"{manifest_path}: registry identity mismatch for {identifier}")
        files = payload.get("files")
        if not isinstance(files, list) or not all(
            isinstance(file, dict) and isinstance(file.get("content"), str)
            for file in files
        ):
            raise ValueError(f"{manifest_path}: invalid registry files for {identifier}")
        registry_content_hashes = sorted(
            hashlib.sha256(str(file["content"]).encode("utf-8")).hexdigest()
            for file in files
            if isinstance(file, dict)
        )
        source_content_hashes = sorted(
            hashlib.sha256(source_payloads[str(reference)]).hexdigest()
            for reference in references
        )
        if registry_content_hashes != source_content_hashes:
            raise ValueError(
                f"{manifest_path}: registry content mismatch for {identifier}"
            )
        upstream_path = registry.get("upstreamPath")
        if not isinstance(upstream_path, str):
            raise ValueError(f"{manifest_path}: invalid registry origin for {identifier}")
        expected_url = _registry_payload_url(
            origin=str(registry.get("origin")),
            commit=commit,
            style=str(item.get("style")),
            identifier=str(item.get("name")),
            registry_revision=registry_revision,
        )
        if registry.get("sourceURL") != expected_url:
            raise ValueError(f"{manifest_path}: invalid registry URL for {identifier}")

    if (
        manifest.get("count") != len(items)
        or manifest.get("exampleCount") != kind_counts["example"]
        or manifest.get("primitiveCount") != kind_counts["primitive"]
        or manifest.get("hookCount") != kind_counts["hook"]
        or manifest.get("repositoryItemCount") != origin_counts["repository"]
        or manifest.get("liveRegistryItemCount") != origin_counts["live-registry"]
        or manifest.get("sourceFileCount") != len(sources)
        or manifest.get("registryItemCount") != len(items)
        or manifest.get("fileCount") != len(sources) + len(items)
    ):
        raise ValueError(f"{manifest_path}: item or file count mismatch")

    actual_sources = {
        path.relative_to(package_root).as_posix()
        for root_name in ("Base", "Radix", "Shared")
        for path in (package_root / f"Sources/ReUI/{root_name}").rglob("*")
        if path.is_file()
    }
    actual_registry = {
        path.relative_to(package_root).as_posix()
        for path in (package_root / "Sources/ReUI/Registry").rglob("*")
        if path.is_file()
    }
    if source_paths != actual_sources:
        raise ValueError(f"{manifest_path}: source catalog is not closed")
    if registry_paths != actual_registry:
        raise ValueError(f"{manifest_path}: registry catalog is not closed")

    license_record = manifest.get("license")
    if not isinstance(license_record, dict) or license_record.get("spdx") != "MIT":
        raise ValueError(f"{manifest_path}: upstream MIT license is missing")
    _, license_bytes = _validate_recorded_file(
        package_root,
        license_record,
        prefix="Sources/ReUI/",
        label="upstream license",
    )
    copyright_line = license_record.get("copyright")
    if _license_copyright(license_bytes) != copyright_line:
        raise ValueError(f"{manifest_path}: license authorship mismatch")
    if license_record.get("sourceURL") != (
        f"{UPSTREAM_REPOSITORY}/blob/{commit}/LICENSE.md"
    ):
        raise ValueError(f"{manifest_path}: unpinned upstream license URL")


def _checkout_upstream() -> tuple[tempfile.TemporaryDirectory[str], Path, str]:
    temporary = tempfile.TemporaryDirectory(prefix="design-system-reui-")
    checkout = Path(temporary.name) / "reui"
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


def _fetch(url: str) -> tuple[bytes, str]:
    headers = {
        "Accept": "application/json",
        "Referer": "https://reui.io/components",
        "User-Agent": (
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            "AppleWebKit/537.36 Chrome/140.0 Safari/537.36"
        ),
    }
    for attempt in range(6):
        request = urllib.request.Request(url, headers=headers)
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                return response.read(), response.geturl()
        except urllib.error.HTTPError as error:
            if error.code not in {403, 408, 429, 500, 502, 503, 504} or attempt == 5:
                raise ValueError(f"cannot fetch {url}: {error}") from error
        except urllib.error.URLError as error:
            if attempt == 5:
                raise ValueError(f"cannot fetch {url}: {error}") from error
        time.sleep(2**attempt)
    raise AssertionError("unreachable retry loop")


def _revision_from_url(url: str) -> str:
    revision = urllib.parse.parse_qs(urllib.parse.urlparse(url).query).get("v", [])
    if len(revision) != 1 or REVISION_PATTERN.fullmatch(revision[0]) is None:
        raise ValueError(f"live registry did not return a pinned deployment URL: {url}")
    return revision[0]


def _validate_cached_payload(
    path: Path,
    *,
    identifier: str,
    item_type: str,
) -> bytes | None:
    if not path.is_file():
        return None
    try:
        payload = path.read_bytes()
        record = json.loads(payload.decode("utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        return None
    if (
        not isinstance(record, dict)
        or record.get("name") != identifier
        or record.get("type") != item_type
    ):
        return None
    return payload


def _capture_live_registry(
    destination: Path,
    license_source: Path,
    *,
    download_payloads: bool,
) -> None:
    destination.mkdir(parents=True, exist_ok=True)
    (destination / UPSTREAM_LICENSE).write_bytes(_read_required(license_source))
    payload_jobs: list[tuple[str, str, str, Path]] = []
    payload_origins: dict[str, dict[str, str]] = {}
    registry_revision: str | None = None
    repository_root = license_source.parent
    for base in BASES:
        style = STYLE_BY_BASE[base]
        relative_root = Path("public/r/styles") / style
        manifest_url = f"{LIVE_REGISTRY_ROOT}/{style}/registry.json"
        manifest_bytes, final_url = _fetch(manifest_url)
        observed_revision = _revision_from_url(final_url)
        if registry_revision is None:
            registry_revision = observed_revision
        elif registry_revision != observed_revision:
            raise ValueError("Base UI and Radix UI indexes use different deployments")
        manifest_path = destination / relative_root / "registry.json"
        manifest_path.parent.mkdir(parents=True, exist_ok=True)
        manifest_path.write_bytes(manifest_bytes)
        manifest = _read_object(manifest_path)
        items = manifest.get("items")
        if not isinstance(items, list):
            raise ValueError(f"{manifest_url}: items must be an array")
        repository_manifest_path = repository_root / relative_root / "registry.json"
        repository_items: dict[str, dict[str, object]] = {}
        if repository_manifest_path.is_file():
            for repository_item in _manifest_items(repository_manifest_path):
                repository_items[str(repository_item["name"])] = repository_item
        style_origins: dict[str, str] = {}
        payload_origins[style] = style_origins
        for item in items:
            if not isinstance(item, dict):
                raise ValueError(f"{manifest_url}: invalid item")
            identifier = item.get("name")
            item_type = item.get("type")
            if not isinstance(identifier, str) or item_type not in ALLOWED_TYPES:
                raise ValueError(f"{manifest_url}: invalid item identity")
            if item_type == "registry:block" and not identifier.startswith("c-"):
                continue
            repository_payload = repository_root / relative_root / f"{identifier}.json"
            if (
                repository_items.get(identifier) == item
                and repository_payload.is_file()
            ):
                destination_payload = destination / relative_root / f"{identifier}.json"
                destination_payload.parent.mkdir(parents=True, exist_ok=True)
                destination_payload.write_bytes(repository_payload.read_bytes())
                style_origins[identifier] = "repository"
                continue
            style_origins[identifier] = "live-registry"
            payload_jobs.append(
                (
                    style,
                    identifier,
                    str(item_type),
                    destination / relative_root / f"{identifier}.json",
                )
            )
    if registry_revision is None:
        raise ValueError("live registry deployment revision is missing")
    (destination / CAPTURE_METADATA).write_text(
        json.dumps(
            {
                "registryRevision": registry_revision,
                "payloadOrigins": payload_origins,
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )
    if not download_payloads:
        return

    def download(job: tuple[str, str, str, Path]) -> tuple[Path, bytes]:
        style, identifier, item_type, path = job
        cache = CACHE_ROOT / registry_revision / style / f"{identifier}.json"
        cached = _validate_cached_payload(
            cache,
            identifier=identifier,
            item_type=item_type,
        )
        if cached is not None:
            return path, cached
        url = _live_registry_url(style, identifier, registry_revision)
        payload, final_url = _fetch(url)
        if _revision_from_url(final_url) != registry_revision:
            raise ValueError(f"{identifier}: registry deployment changed during capture")
        temporary = cache.with_suffix(".download")
        temporary.parent.mkdir(parents=True, exist_ok=True)
        temporary.write_bytes(payload)
        validated = _validate_cached_payload(
            temporary,
            identifier=identifier,
            item_type=item_type,
        )
        if validated is None:
            temporary.unlink(missing_ok=True)
            raise ValueError(f"{identifier}: live registry returned an invalid payload")
        temporary.replace(cache)
        return path, payload

    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
        for path, payload in executor.map(download, payload_jobs):
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(payload)


def _captured_identity_matches(root: Path, capture: Path, commit: str) -> bool:
    manifest_path = root / PUBLIC_MANIFEST
    if not manifest_path.is_file():
        return False
    try:
        manifest = _read_object(manifest_path)
        revision = _registry_revision(capture)
        indexes = [
            RegistryIndex(
                base=base,
                style=STYLE_BY_BASE[base],
                upstream_path=(
                    Path("public/r/styles") / STYLE_BY_BASE[base] / "registry.json"
                ).as_posix(),
                source_url=_live_registry_url(
                    STYLE_BY_BASE[base], "registry", revision
                ),
                payload=_read_required(
                    capture
                    / "public/r/styles"
                    / STYLE_BY_BASE[base]
                    / "registry.json"
                ),
            ).manifest_record()
            for base in BASES
        ]
        license_record = manifest.get("license")
        return bool(
            manifest.get("upstreamCommit") == commit
            and manifest.get("registryRevision") == revision
            and manifest.get("registryIndexes") == indexes
            and isinstance(license_record, dict)
            and license_record.get("sha256")
            == hashlib.sha256(_read_required(capture / UPSTREAM_LICENSE)).hexdigest()
        )
    except (OSError, UnicodeError, ValueError, json.JSONDecodeError):
        return False


def sync_catalog(*, write: bool, root: Path = ROOT) -> list[str]:
    temporary, checkout, commit = _checkout_upstream()
    try:
        snapshot_root = Path(temporary.name) / "live-registry"
        _capture_live_registry(
            snapshot_root,
            checkout / UPSTREAM_LICENSE,
            download_payloads=write,
        )
        if not write and _captured_identity_matches(root, snapshot_root, commit):
            verify_catalog(root / "packages", root / PUBLIC_MANIFEST)
            return []
        if not write:
            _capture_live_registry(
                snapshot_root,
                checkout / UPSTREAM_LICENSE,
                download_payloads=True,
            )
        return sync_from_checkout(snapshot_root, commit, write=write, root=root)
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
                print("ReUI source catalog is stale:", file=sys.stderr)
                for change in changes:
                    print(f"- {change}", file=sys.stderr)
                return 1
            manifest = _read_object(ROOT / PUBLIC_MANIFEST)
            action = "Updated" if arguments.write else "Verified"
            print(
                f"{action} {manifest['count']} exact ReUI registry items "
                f"across Base UI and Radix UI ({manifest['sourceFileCount']} unique sources)"
            )
            return 0
        verify_catalog(ROOT / "packages", ROOT / PUBLIC_MANIFEST)
        manifest = _read_object(ROOT / PUBLIC_MANIFEST)
        print(
            f"Verified {manifest['sourceFileCount']} immutable ReUI sources "
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
        print(f"ReUI operation failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
