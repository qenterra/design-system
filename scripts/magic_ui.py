#!/usr/bin/env python3
"""Synchronize and verify the exact official Magic UI component catalog."""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
UPSTREAM_REPOSITORY = "https://github.com/magicuidesign/magicui"
UPSTREAM_GIT_URL = f"{UPSTREAM_REPOSITORY}.git"
UPSTREAM_BRANCH = "main"
UPSTREAM_REF = f"refs/heads/{UPSTREAM_BRANCH}"
UPSTREAM_LICENSE = Path("LICENSE.md")
DOCS_CONFIG = Path("apps/www/config/docs.ts")
DOCS_COMPONENT_ROOT = Path("apps/www/content/docs/components")
UPSTREAM_COMPONENT_ROOT = Path("apps/www/registry/magicui")
UPSTREAM_REGISTRY_ROOT = Path("apps/www/public/r")
PUBLIC_ROOT = Path("packages/Sources/MagicUI")
PUBLIC_MANIFEST = PUBLIC_ROOT / "manifest.json"
PUBLIC_LICENSE = PUBLIC_ROOT / "LICENSE.md"
PUBLIC_README = PUBLIC_ROOT / "README.md"
COMPONENT_ROOT = PUBLIC_ROOT / "Components"
REGISTRY_ITEM_ROOT = PUBLIC_ROOT / "Registry"
PRIVATE_REGISTRY = Path("registry/magic-ui.json")
PRIVATE_SCHEMA = "../schemas/magic-ui-registry.schema.json"
COMMIT_PATTERN = re.compile(r"^[0-9a-f]{40}$")
SECTION_PATTERN = re.compile(
    r'^    \{\n'
    r'^      title: "(?P<title>[^"]+)",\n'
    r'^      items: \[\n'
    r'(?P<body>.*?)'
    r'^      \],\n'
    r'^    \},',
    re.MULTILINE | re.DOTALL,
)
ITEM_PATTERN = re.compile(
    r'^        \{\n'
    r'^          title: "(?P<title>[^"]+)",\n'
    r'^          href: [`"](?P<href>/docs/components/(?P<id>[a-z0-9-]+))[`"],',
    re.MULTILINE,
)


@dataclasses.dataclass(frozen=True)
class Category:
    identifier: str
    title: str
    count: int


@dataclasses.dataclass(frozen=True)
class NavigationComponent:
    identifier: str
    title: str
    category_identifier: str
    category_title: str


@dataclasses.dataclass(frozen=True)
class ComponentSource:
    identifier: str
    title: str
    category_identifier: str
    category_title: str
    documentation_url: str
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
            "title": self.title,
            "category": self.category_identifier,
            "categoryTitle": self.category_title,
            "language": "TypeScript TSX",
            "documentationURL": self.documentation_url,
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
    categories: tuple[Category, ...]
    components: tuple[ComponentSource, ...]
    license_bytes: bytes
    license_copyright: str

    @property
    def license_sha256(self) -> str:
        return hashlib.sha256(self.license_bytes).hexdigest()


def _read_required(path: Path) -> bytes:
    if not path.is_file():
        raise ValueError(f"required upstream file is missing: {path}")
    return path.read_bytes()


def _slug(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")


def discover_public_navigation(
    upstream_root: Path,
) -> tuple[list[Category], list[NavigationComponent]]:
    config = _read_required(upstream_root / DOCS_CONFIG).decode("utf-8")
    categories: list[Category] = []
    components: list[NavigationComponent] = []
    for section_match in SECTION_PATTERN.finditer(config):
        title = section_match.group("title")
        item_matches = list(ITEM_PATTERN.finditer(section_match.group("body")))
        if not item_matches:
            continue
        category_identifier = _slug(title)
        categories.append(
            Category(
                identifier=category_identifier,
                title=title,
                count=len(item_matches),
            )
        )
        components.extend(
            NavigationComponent(
                identifier=item.group("id"),
                title=item.group("title"),
                category_identifier=category_identifier,
                category_title=title,
            )
            for item in item_matches
        )
    if not categories or not components:
        raise ValueError(f"no public Magic UI components found in {DOCS_CONFIG}")
    identifiers = [component.identifier for component in components]
    if len(identifiers) != len(set(identifiers)):
        raise ValueError(f"duplicate public component in {DOCS_CONFIG}")

    docs_root = upstream_root / DOCS_COMPONENT_ROOT
    docs_identifiers = {
        path.stem
        for path in docs_root.glob("*.mdx")
        if path.is_file() and path.stem != "index"
    }
    navigation_identifiers = set(identifiers)
    missing_navigation = sorted(docs_identifiers - navigation_identifiers)
    missing_docs = sorted(navigation_identifiers - docs_identifiers)
    if missing_navigation:
        raise ValueError(
            "public component documentation is absent from navigation: "
            + ", ".join(missing_navigation)
        )
    if missing_docs:
        raise ValueError(
            "public component navigation has no documentation source: "
            + ", ".join(missing_docs)
        )
    return categories, components


def _string_list(value: object, *, field: str, component: str) -> tuple[str, ...]:
    if value is None:
        return ()
    if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
        raise ValueError(f"{component}: {field} must be an array of strings")
    return tuple(value)


def _read_registry_item(
    upstream_root: Path,
    identifier: str,
    expected_source_path: str,
    expected_source_bytes: bytes,
) -> tuple[bytes, tuple[str, ...], tuple[str, ...]]:
    registry_path = upstream_root / UPSTREAM_REGISTRY_ROOT / f"{identifier}.json"
    registry_bytes = _read_required(registry_path)
    try:
        payload = json.loads(registry_bytes.decode("utf-8"))
    except (UnicodeError, json.JSONDecodeError) as error:
        raise ValueError(f"{registry_path}: invalid public registry item: {error}") from error
    if not isinstance(payload, dict):
        raise ValueError(f"{registry_path}: public registry item must be an object")
    if payload.get("name") != identifier or payload.get("type") != "registry:ui":
        raise ValueError(f"{registry_path}: public registry identity mismatch")
    files = payload.get("files")
    if not isinstance(files, list) or len(files) != 1 or not isinstance(files[0], dict):
        raise ValueError(f"{registry_path}: expected exactly one component source file")
    source_record = files[0]
    if source_record.get("path") != expected_source_path:
        raise ValueError(f"{registry_path}: public registry source path mismatch")
    content = source_record.get("content")
    if not isinstance(content, str) or content.encode("utf-8") != expected_source_bytes:
        raise ValueError(f"{registry_path}: public registry content mismatch")
    return (
        registry_bytes,
        _string_list(payload.get("dependencies"), field="dependencies", component=identifier),
        _string_list(
            payload.get("registryDependencies"),
            field="registryDependencies",
            component=identifier,
        ),
    )


def _license_copyright(payload: bytes) -> str:
    text = payload.decode("utf-8")
    if not text.startswith("MIT License"):
        raise ValueError("upstream LICENSE.md is not the expected MIT license")
    match = re.search(r"^Copyright \(c\) .+$", text, re.MULTILINE)
    if match is None:
        raise ValueError("upstream LICENSE.md does not identify its copyright holder")
    return match.group(0)


def read_upstream_snapshot(upstream_root: Path, commit: str) -> UpstreamSnapshot:
    if COMMIT_PATTERN.fullmatch(commit) is None:
        raise ValueError("upstream commit must be a full lowercase Git SHA")
    categories, navigation = discover_public_navigation(upstream_root)
    components: list[ComponentSource] = []
    source_paths: set[str] = set()
    registry_paths: set[str] = set()
    for item in navigation:
        upstream_relative = UPSTREAM_COMPONENT_ROOT / f"{item.identifier}.tsx"
        source_bytes = _read_required(upstream_root / upstream_relative)
        registry_relative = UPSTREAM_REGISTRY_ROOT / f"{item.identifier}.json"
        registry_bytes, dependencies, registry_dependencies = _read_registry_item(
            upstream_root,
            item.identifier,
            f"registry/magicui/{item.identifier}.tsx",
            source_bytes,
        )
        source_path = f"Sources/MagicUI/Components/{item.identifier}.tsx"
        registry_source_path = f"Sources/MagicUI/Registry/{item.identifier}.json"
        if source_path in source_paths or registry_source_path in registry_paths:
            raise ValueError(f"duplicate public catalog path for {item.identifier}")
        source_paths.add(source_path)
        registry_paths.add(registry_source_path)
        components.append(
            ComponentSource(
                identifier=item.identifier,
                title=item.title,
                category_identifier=item.category_identifier,
                category_title=item.category_title,
                documentation_url=f"https://magicui.design/docs/components/{item.identifier}",
                upstream_path=upstream_relative.as_posix(),
                source_url=(
                    "https://raw.githubusercontent.com/magicuidesign/magicui/"
                    f"{commit}/{upstream_relative.as_posix()}"
                ),
                source_path=source_path,
                source_bytes=source_bytes,
                registry_upstream_path=registry_relative.as_posix(),
                registry_url=(
                    "https://raw.githubusercontent.com/magicuidesign/magicui/"
                    f"{commit}/{registry_relative.as_posix()}"
                ),
                registry_source_path=registry_source_path,
                registry_bytes=registry_bytes,
                dependencies=dependencies,
                registry_dependencies=registry_dependencies,
            )
        )
    license_bytes = _read_required(upstream_root / UPSTREAM_LICENSE)
    return UpstreamSnapshot(
        commit=commit,
        categories=tuple(categories),
        components=tuple(sorted(components, key=lambda component: component.identifier)),
        license_bytes=license_bytes,
        license_copyright=_license_copyright(license_bytes),
    )


def build_catalog(snapshot: UpstreamSnapshot, version: str) -> dict[str, object]:
    return {
        "version": version,
        "source": "https://magicui.design/docs/components",
        "upstreamRepository": UPSTREAM_REPOSITORY,
        "upstreamRef": UPSTREAM_REF,
        "upstreamCommit": snapshot.commit,
        "scope": "every component listed on the official public Components page",
        "count": len(snapshot.components),
        "sourceFileCount": len(snapshot.components),
        "registryItemCount": len(snapshot.components),
        "fileCount": len(snapshot.components) * 2,
        "categories": [dataclasses.asdict(category) for category in snapshot.categories],
        "license": {
            "spdx": "MIT",
            "copyright": snapshot.license_copyright,
            "upstreamPath": UPSTREAM_LICENSE.as_posix(),
            "sourceURL": f"{UPSTREAM_REPOSITORY}/blob/{snapshot.commit}/LICENSE.md",
            "sourcePath": "Sources/MagicUI/LICENSE.md",
            "sha256": snapshot.license_sha256,
            "bytes": len(snapshot.license_bytes),
        },
        "components": [component.manifest_record() for component in snapshot.components],
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


def _read_json(path: Path) -> dict[str, object]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{path}: expected an object")
    return payload


def _package_registry_bytes(root: Path, snapshot: UpstreamSnapshot) -> bytes:
    registry_path = root / "registry/packages.json"
    registry = _read_json(registry_path)
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
        if isinstance(path, str) and not path.startswith("packages/Sources/MagicUI/")
    ]
    magic_ui_paths = [
        "packages/Sources/MagicUI/LICENSE.md",
        "packages/Sources/MagicUI/README.md",
        "packages/Sources/MagicUI/manifest.json",
        *[f"packages/{component.source_path}" for component in snapshot.components],
        *[
            f"packages/{component.registry_source_path}"
            for component in snapshot.components
        ],
    ]
    metadata["publicPaths"] = sorted([*retained, *magic_ui_paths])
    return (json.dumps(registry, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def _readme_bytes(snapshot: UpstreamSnapshot) -> bytes:
    category_summary = ", ".join(
        f"{category.title} ({category.count})" for category in snapshot.categories
    )
    return f"""# Magic UI exact source catalog

This directory preserves the exact authored source bytes for every component listed on the official [Magic UI Components page](https://magicui.design/docs/components) at commit [`{snapshot.commit}`]({UPSTREAM_REPOSITORY}/commit/{snapshot.commit}). The catalog contains {len(snapshot.components)} TypeScript component files across {category_summary}. Each component has its pinned upstream path, URL, byte count, and SHA-256 digest in `manifest.json`.

`Registry/` also preserves the exact official shadcn-compatible registry item for every component. Those payloads retain required dependencies, CSS variables, and keyframes that are not always present in the `.tsx` source. They are provenance and installation metadata, not QenTerra-authored rewrites.

The scope follows the public Components page and its docs navigation. It excludes templates, demos, examples, documentation prose, the website application, internal-only registry sources, and unrelated monorepo code. The root upstream registry is not used as the completeness boundary because its current checkout contains stale entries that do not match the public page.

The originals under `Components/` and `Registry/` are immutable and are not adapted to QenTerra design tokens. Do not edit them directly. A changed implementation must be created as a separate QenTerra-owned component under `Sources/QenTerra/Components/`, with its own token usage, tests, registry entry, delivery mapping, version, changelog entry, and derivation provenance. The upstream original remains unchanged.

This catalog is reference source, not an npm or SwiftPM target. Magic UI components are source-distributed React components and can require the dependencies, aliases, CSS variables, Tailwind configuration, and framework setup declared by their official registry items. Install a selected item through the official Magic UI/shadcn workflow or copy it into a compatible web project after reviewing its manifest record.

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
    for component in snapshot.components:
        expected[root / "packages" / component.source_path] = component.source_bytes
        expected[root / "packages" / component.registry_source_path] = component.registry_bytes
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
    catalog_roots = [root / COMPONENT_ROOT, root / REGISTRY_ITEM_ROOT]
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
    manifest = _read_json(manifest_path)
    commit = manifest.get("upstreamCommit")
    if not isinstance(commit, str) or COMMIT_PATTERN.fullmatch(commit) is None:
        raise ValueError(f"{manifest_path}: invalid upstream commit")
    records = manifest.get("components")
    if not isinstance(records, list) or not records:
        raise ValueError(f"{manifest_path}: components must be a non-empty array")
    count = len(records)
    if (
        manifest.get("count") != count
        or manifest.get("sourceFileCount") != count
        or manifest.get("registryItemCount") != count
        or manifest.get("fileCount") != count * 2
    ):
        raise ValueError(f"{manifest_path}: component or file count mismatch")

    identifiers: set[str] = set()
    source_paths: set[str] = set()
    registry_paths: set[str] = set()
    category_counts: dict[str, int] = {}
    for index, record in enumerate(records):
        if not isinstance(record, dict):
            raise ValueError(f"{manifest_path}: invalid component at index {index}")
        identifier = record.get("id")
        if not isinstance(identifier, str) or not identifier:
            raise ValueError(f"{manifest_path}: invalid component id at index {index}")
        if identifier in identifiers:
            raise ValueError(f"{manifest_path}: duplicate component id: {identifier}")
        identifiers.add(identifier)
        category = record.get("category")
        if not isinstance(category, str) or not category:
            raise ValueError(f"{manifest_path}: invalid category for {identifier}")
        category_counts[category] = category_counts.get(category, 0) + 1
        upstream_path = f"apps/www/registry/magicui/{identifier}.tsx"
        if record.get("upstreamPath") != upstream_path:
            raise ValueError(f"{manifest_path}: invalid upstream path for {identifier}")
        expected_source_url = (
            "https://raw.githubusercontent.com/magicuidesign/magicui/"
            f"{commit}/{upstream_path}"
        )
        if record.get("sourceURL") != expected_source_url:
            raise ValueError(f"{manifest_path}: unpinned source URL for {identifier}")
        expected_docs_url = f"https://magicui.design/docs/components/{identifier}"
        if record.get("documentationURL") != expected_docs_url:
            raise ValueError(f"{manifest_path}: invalid documentation URL for {identifier}")
        source_relative, source_bytes = _validate_recorded_file(
            package_root,
            record,
            prefix="Sources/MagicUI/Components/",
            label="original source",
        )
        if source_relative in source_paths:
            raise ValueError(f"{manifest_path}: duplicate source path: {source_relative}")
        source_paths.add(source_relative)

        registry_record = record.get("registryItem")
        if not isinstance(registry_record, dict):
            raise ValueError(f"{manifest_path}: registry item missing for {identifier}")
        registry_upstream_path = f"apps/www/public/r/{identifier}.json"
        if registry_record.get("upstreamPath") != registry_upstream_path:
            raise ValueError(f"{manifest_path}: invalid registry path for {identifier}")
        expected_registry_url = (
            "https://raw.githubusercontent.com/magicuidesign/magicui/"
            f"{commit}/{registry_upstream_path}"
        )
        if registry_record.get("sourceURL") != expected_registry_url:
            raise ValueError(f"{manifest_path}: unpinned registry URL for {identifier}")
        registry_relative, registry_bytes = _validate_recorded_file(
            package_root,
            registry_record,
            prefix="Sources/MagicUI/Registry/",
            label="registry item",
        )
        if registry_relative in registry_paths:
            raise ValueError(f"{manifest_path}: duplicate registry path: {registry_relative}")
        registry_paths.add(registry_relative)
        registry_payload = json.loads(registry_bytes.decode("utf-8"))
        if (
            not isinstance(registry_payload, dict)
            or registry_payload.get("name") != identifier
            or registry_payload.get("type") != "registry:ui"
        ):
            raise ValueError(f"{manifest_path}: registry identity mismatch for {identifier}")
        files = registry_payload.get("files")
        if not isinstance(files, list) or len(files) != 1 or not isinstance(files[0], dict):
            raise ValueError(f"{manifest_path}: invalid registry files for {identifier}")
        if files[0].get("path") != f"registry/magicui/{identifier}.tsx":
            raise ValueError(f"{manifest_path}: registry source path mismatch for {identifier}")
        content = files[0].get("content")
        if not isinstance(content, str) or content.encode("utf-8") != source_bytes:
            raise ValueError(f"{manifest_path}: registry content mismatch for {identifier}")

    actual_source_paths = {
        path.relative_to(package_root).as_posix()
        for path in (package_root / "Sources/MagicUI/Components").rglob("*")
        if path.is_file()
    }
    actual_registry_paths = {
        path.relative_to(package_root).as_posix()
        for path in (package_root / "Sources/MagicUI/Registry").rglob("*")
        if path.is_file()
    }
    if source_paths != actual_source_paths:
        raise ValueError(f"{manifest_path}: source catalog is not closed")
    if registry_paths != actual_registry_paths:
        raise ValueError(f"{manifest_path}: registry catalog is not closed")

    categories = manifest.get("categories")
    if not isinstance(categories, list) or not categories:
        raise ValueError(f"{manifest_path}: categories must be a non-empty array")
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
        raise ValueError(f"{manifest_path}: category counts do not match components")

    license_record = manifest.get("license")
    if not isinstance(license_record, dict):
        raise ValueError(f"{manifest_path}: license record is missing")
    if license_record.get("spdx") != "MIT":
        raise ValueError(f"{manifest_path}: upstream license must be MIT")
    copyright_line = license_record.get("copyright")
    if not isinstance(copyright_line, str) or "Magic UI" not in copyright_line:
        raise ValueError(f"{manifest_path}: upstream authorship is missing")
    _, license_bytes = _validate_recorded_file(
        package_root,
        license_record,
        prefix="Sources/MagicUI/",
        label="upstream license",
    )
    if _license_copyright(license_bytes) != copyright_line:
        raise ValueError(f"{manifest_path}: license authorship mismatch")
    expected_license_url = f"{UPSTREAM_REPOSITORY}/blob/{commit}/LICENSE.md"
    if license_record.get("sourceURL") != expected_license_url:
        raise ValueError(f"{manifest_path}: unpinned upstream license URL")


def _checkout_upstream() -> tuple[tempfile.TemporaryDirectory[str], Path, str]:
    temporary = tempfile.TemporaryDirectory(prefix="design-system-magic-ui-")
    checkout = Path(temporary.name) / "magicui"
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
                print("Magic UI source catalog is stale:", file=sys.stderr)
                for change in changes:
                    print(f"- {change}", file=sys.stderr)
                return 1
            manifest = _read_json(ROOT / PUBLIC_MANIFEST)
            action = "Updated" if arguments.write else "Verified"
            print(
                f"{action} {manifest['count']} exact Magic UI components "
                f"from {len(manifest['categories'])} public categories"
            )
            return 0
        verify_catalog(ROOT / "packages", ROOT / PUBLIC_MANIFEST)
        manifest = _read_json(ROOT / PUBLIC_MANIFEST)
        print(
            f"Verified {manifest['count']} immutable Magic UI component sources "
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
        print(f"Magic UI operation failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
