#!/usr/bin/env python3
"""Synchronize and verify the exact official shadcn/ui component sources."""

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
from typing import Iterable


ROOT = Path(__file__).resolve().parents[1]
UPSTREAM_REPOSITORY = "https://github.com/shadcn-ui/ui"
UPSTREAM_GIT_URL = f"{UPSTREAM_REPOSITORY}.git"
UPSTREAM_BRANCH = "main"
UPSTREAM_REF = f"refs/heads/{UPSTREAM_BRANCH}"
BASES_DEFINITION = Path("apps/v4/registry/bases.ts")
BASES_ROOT = Path("apps/v4/registry/bases")
UPSTREAM_LICENSE = Path("LICENSE.md")
PUBLIC_ROOT = Path("packages/Sources/ShadcnUI")
PUBLIC_MANIFEST = PUBLIC_ROOT / "manifest.json"
PUBLIC_LICENSE = PUBLIC_ROOT / "LICENSE.md"
PUBLIC_README = PUBLIC_ROOT / "README.md"
COMPONENT_ROOT = PUBLIC_ROOT / "Components"
PRIVATE_REGISTRY = Path("registry/shadcn-ui.json")
PRIVATE_SCHEMA = "../schemas/shadcn-ui-registry.schema.json"
COMMIT_PATTERN = re.compile(r"^[0-9a-f]{40}$")
VARIANT_PATTERN = re.compile(
    r'^\s{4}name: "(?P<name>[a-z0-9-]+)",\n'
    r'^\s{4}type: "registry:style",\n'
    r'^\s{4}title: "(?P<title>[^"]+)",',
    re.MULTILINE,
)
REGISTRY_PATH_PATTERN = re.compile(r'path:\s*"(?P<path>ui/[^"]+)"')


@dataclasses.dataclass(frozen=True)
class Variant:
    identifier: str
    title: str

    @property
    def directory_name(self) -> str:
        return "".join(
            part[:1].upper() + part[1:]
            for part in re.split(r"[^A-Za-z0-9]+", self.identifier)
            if part
        )


@dataclasses.dataclass(frozen=True)
class ComponentSource:
    identifier: str
    name: str
    variant: Variant
    upstream_path: str
    source_url: str
    source_path: str
    language: str
    source_bytes: bytes

    @property
    def sha256(self) -> str:
        return hashlib.sha256(self.source_bytes).hexdigest()

    def manifest_record(self) -> dict[str, object]:
        return {
            "id": self.identifier,
            "name": self.name,
            "variant": self.variant.identifier,
            "variantTitle": self.variant.title,
            "language": self.language,
            "upstreamPath": self.upstream_path,
            "sourceURL": self.source_url,
            "sourcePath": self.source_path,
            "sha256": self.sha256,
            "bytes": len(self.source_bytes),
        }


@dataclasses.dataclass(frozen=True)
class UpstreamSnapshot:
    commit: str
    variants: tuple[Variant, ...]
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


def discover_variants(upstream_root: Path) -> list[Variant]:
    definition_path = upstream_root / BASES_DEFINITION
    definition = _read_required(definition_path).decode("utf-8")
    variants = [
        Variant(identifier=match.group("name"), title=match.group("title"))
        for match in VARIANT_PATTERN.finditer(definition)
    ]
    if not variants:
        raise ValueError(f"no official variants found in {BASES_DEFINITION}")
    identifiers = [variant.identifier for variant in variants]
    if len(identifiers) != len(set(identifiers)):
        raise ValueError(f"duplicate official variant in {BASES_DEFINITION}")
    return sorted(variants, key=lambda variant: variant.identifier)


def _language_for(path: Path) -> str:
    return {
        ".css": "CSS",
        ".js": "JavaScript",
        ".jsx": "JavaScript JSX",
        ".ts": "TypeScript",
        ".tsx": "TypeScript TSX",
    }.get(path.suffix.lower(), path.suffix.removeprefix(".").upper())


def _registered_component_paths(upstream_root: Path, variant: Variant) -> list[Path]:
    variant_root = upstream_root / BASES_ROOT / variant.identifier
    ui_root = variant_root / "ui"
    registry_path = ui_root / "_registry.ts"
    registry = _read_required(registry_path).decode("utf-8")
    declared_strings = [
        match.group("path") for match in REGISTRY_PATH_PATTERN.finditer(registry)
    ]
    if not declared_strings:
        raise ValueError(f"{registry_path}: no registry:ui source paths found")
    if len(declared_strings) != len(set(declared_strings)):
        raise ValueError(f"{registry_path}: duplicate component source path")

    declared: set[Path] = set()
    for relative_string in declared_strings:
        relative = Path(relative_string)
        if (
            relative.is_absolute()
            or relative.parts[:1] != ("ui",)
            or any(part in {"", ".", ".."} for part in relative.parts)
        ):
            raise ValueError(f"{registry_path}: unsafe component path {relative_string}")
        source = (variant_root / relative).resolve()
        resolved_ui_root = ui_root.resolve()
        if resolved_ui_root not in source.parents:
            raise ValueError(f"{registry_path}: component path escapes ui root")
        if not source.is_file():
            raise ValueError(f"{registry_path}: registered component source is missing: {relative}")
        declared.add(source)

    actual = {
        path.resolve()
        for path in ui_root.rglob("*")
        if path.is_file() and path.name != "_registry.ts"
    }
    missing_registration = sorted(actual - declared)
    if missing_registration:
        relative = missing_registration[0].relative_to(variant_root.resolve())
        raise ValueError(
            f"{variant.identifier}: unregistered component source: {relative.as_posix()}"
        )
    missing_file = sorted(declared - actual)
    if missing_file:
        relative = missing_file[0].relative_to(variant_root.resolve())
        raise ValueError(
            f"{variant.identifier}: registered component source is missing: {relative.as_posix()}"
        )
    return sorted(declared)


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
    variants = discover_variants(upstream_root)
    components: list[ComponentSource] = []
    identifiers: set[str] = set()
    source_paths: set[str] = set()
    for variant in variants:
        variant_root = upstream_root / BASES_ROOT / variant.identifier
        for source in _registered_component_paths(upstream_root, variant):
            relative = source.relative_to(variant_root).as_posix()
            relative_without_ui = source.relative_to(variant_root / "ui")
            logical_path = relative_without_ui.with_suffix("").as_posix()
            identifier = f"{variant.identifier}/{logical_path}"
            public_relative = (
                Path("Sources/ShadcnUI/Components")
                / variant.directory_name
                / relative_without_ui
            ).as_posix()
            upstream_path = (BASES_ROOT / variant.identifier / relative).as_posix()
            component = ComponentSource(
                identifier=identifier,
                name=source.stem,
                variant=variant,
                upstream_path=upstream_path,
                source_url=(
                    "https://raw.githubusercontent.com/shadcn-ui/ui/"
                    f"{commit}/{upstream_path}"
                ),
                source_path=public_relative,
                language=_language_for(source),
                source_bytes=source.read_bytes(),
            )
            if component.identifier in identifiers:
                raise ValueError(f"duplicate component id: {component.identifier}")
            if component.source_path in source_paths:
                raise ValueError(f"duplicate public source path: {component.source_path}")
            identifiers.add(component.identifier)
            source_paths.add(component.source_path)
            components.append(component)
    if not components:
        raise ValueError("official shadcn/ui component catalog is empty")
    license_bytes = _read_required(upstream_root / UPSTREAM_LICENSE)
    return UpstreamSnapshot(
        commit=commit,
        variants=tuple(variants),
        components=tuple(sorted(components, key=lambda component: component.identifier)),
        license_bytes=license_bytes,
        license_copyright=_license_copyright(license_bytes),
    )


def build_catalog(snapshot: UpstreamSnapshot, version: str) -> dict[str, object]:
    variant_counts = {
        variant.identifier: sum(
            component.variant.identifier == variant.identifier
            for component in snapshot.components
        )
        for variant in snapshot.variants
    }
    return {
        "version": version,
        "source": "https://ui.shadcn.com/",
        "upstreamRepository": UPSTREAM_REPOSITORY,
        "upstreamRef": UPSTREAM_REF,
        "upstreamCommit": snapshot.commit,
        "scope": "official registry:ui component sources for every declared base",
        "count": len(snapshot.components),
        "fileCount": len(snapshot.components),
        "variants": [
            {
                "id": variant.identifier,
                "title": variant.title,
                "count": variant_counts[variant.identifier],
            }
            for variant in snapshot.variants
        ],
        "license": {
            "spdx": "MIT",
            "copyright": snapshot.license_copyright,
            "upstreamPath": UPSTREAM_LICENSE.as_posix(),
            "sourceURL": f"{UPSTREAM_REPOSITORY}/blob/{snapshot.commit}/LICENSE.md",
            "sourcePath": "Sources/ShadcnUI/LICENSE.md",
            "sha256": snapshot.license_sha256,
            "bytes": len(snapshot.license_bytes),
        },
        "components": [
            component.manifest_record() for component in snapshot.components
        ],
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
        if isinstance(path, str)
        and not path.startswith("packages/Sources/ShadcnUI/")
    ]
    shadcn_paths = [
        "packages/Sources/ShadcnUI/LICENSE.md",
        "packages/Sources/ShadcnUI/README.md",
        "packages/Sources/ShadcnUI/manifest.json",
        *[
            f"packages/{component.source_path}"
            for component in snapshot.components
        ],
    ]
    metadata["publicPaths"] = sorted([*retained, *shadcn_paths])
    return (json.dumps(registry, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def _readme_bytes(snapshot: UpstreamSnapshot) -> bytes:
    variant_summary = ", ".join(
        f"{variant.title} ({sum(component.variant == variant for component in snapshot.components)})"
        for variant in snapshot.variants
    )
    return f"""# shadcn/ui exact source catalog

This directory preserves the exact authored source bytes for every official `registry:ui` component declared by [shadcn/ui]({UPSTREAM_REPOSITORY}) at commit [`{snapshot.commit}`]({UPSTREAM_REPOSITORY}/commit/{snapshot.commit}). The catalog contains {len(snapshot.components)} component source files across {variant_summary}. Each source has its pinned upstream path, URL, byte count, and SHA-256 digest in `manifest.json`.

The scope is deliberately the public component layer under the upstream base registries. It does not copy the shadcn/ui documentation website, CLI, tests, examples, blocks, generated style outputs, or internal application code. Those files are not component originals and would turn a useful catalog into a stale monorepo mirror.

The original files under `Components/` are immutable and are not adapted to QenTerra design tokens. Do not edit them directly. A changed implementation must be created as a separate QenTerra-owned component under `Sources/QenTerra/Components/`, with its own token usage, tests, registry entry, delivery mapping, version, changelog entry, and derivation provenance. The upstream original remains unchanged.

This catalog is reference source, not an npm or SwiftPM target. shadcn/ui components are source-distributed React components and can require the dependencies, aliases, CSS variables, Tailwind configuration, and framework setup declared by the upstream project. Use the official shadcn tooling or copy a selected component into a web project after reviewing its manifest record.

The bundled [`LICENSE.md`](LICENSE.md) is the exact upstream MIT license and identifies the original copyright holder as `{snapshot.license_copyright}`. QenTerra does not claim authorship of these files or relicense them as QenTerra-owned package material.
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
    for component in snapshot.components:
        expected[root / "packages" / component.source_path] = component.source_bytes
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
    component_root = root / COMPONENT_ROOT
    actual_sources = {
        path for path in component_root.rglob("*") if path.is_file()
    } if component_root.is_dir() else set()
    expected_sources = {
        path for path in expected if component_root in path.parents
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
                for path in actual_sources - expected_sources
            ),
        }
    )
    if write:
        for path in sorted(actual_sources - expected_sources, reverse=True):
            path.unlink()
        for path, payload in expected.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(payload)
        if component_root.is_dir():
            for directory in sorted(
                (path for path in component_root.rglob("*") if path.is_dir()),
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


def verify_catalog(package_root: Path, manifest_path: Path) -> None:
    manifest = _read_json(manifest_path)
    commit = manifest.get("upstreamCommit")
    if not isinstance(commit, str) or COMMIT_PATTERN.fullmatch(commit) is None:
        raise ValueError(f"{manifest_path}: invalid upstream commit")
    records = manifest.get("components")
    if not isinstance(records, list) or not records:
        raise ValueError(f"{manifest_path}: components must be a non-empty array")
    if manifest.get("count") != len(records) or manifest.get("fileCount") != len(records):
        raise ValueError(f"{manifest_path}: component count mismatch")

    expected_paths: set[str] = set()
    identifiers: set[str] = set()
    actual_variant_counts: dict[str, int] = {}
    for index, record in enumerate(records):
        if not isinstance(record, dict):
            raise ValueError(f"{manifest_path}: invalid component at index {index}")
        identifier = record.get("id")
        relative = record.get("sourcePath")
        if not isinstance(identifier, str) or not identifier:
            raise ValueError(f"{manifest_path}: invalid component id at index {index}")
        if identifier in identifiers:
            raise ValueError(f"{manifest_path}: duplicate component id: {identifier}")
        identifiers.add(identifier)
        variant = record.get("variant")
        upstream_path = record.get("upstreamPath")
        source_url = record.get("sourceURL")
        if not isinstance(variant, str) or not variant:
            raise ValueError(f"{manifest_path}: invalid variant for {identifier}")
        if not isinstance(upstream_path, str) or not upstream_path.startswith(
            f"apps/v4/registry/bases/{variant}/ui/"
        ):
            raise ValueError(f"{manifest_path}: invalid upstream path for {identifier}")
        expected_url = (
            "https://raw.githubusercontent.com/shadcn-ui/ui/"
            f"{commit}/{upstream_path}"
        )
        if source_url != expected_url:
            raise ValueError(f"{manifest_path}: unpinned source URL for {identifier}")
        actual_variant_counts[variant] = actual_variant_counts.get(variant, 0) + 1
        if not isinstance(relative, str):
            raise ValueError(f"{manifest_path}: invalid source path for {identifier}")
        if relative in expected_paths:
            raise ValueError(f"{manifest_path}: duplicate source path: {relative}")
        expected_paths.add(relative)
        source = _safe_catalog_file(
            package_root,
            relative,
            "Sources/ShadcnUI/Components/",
        )
        if not source.is_file():
            raise ValueError(f"missing original source: {relative}")
        payload = source.read_bytes()
        if record.get("bytes") != len(payload):
            raise ValueError(f"byte-size mismatch: {relative}")
        if record.get("sha256") != hashlib.sha256(payload).hexdigest():
            raise ValueError(f"hash mismatch: {relative}")

    component_root = package_root / "Sources/ShadcnUI/Components"
    actual_paths = {
        path.relative_to(package_root).as_posix()
        for path in component_root.rglob("*")
        if path.is_file()
    } if component_root.is_dir() else set()
    missing = sorted(expected_paths - actual_paths)
    unexpected = sorted(actual_paths - expected_paths)
    if missing:
        raise ValueError(f"manifest sources are missing: {', '.join(missing)}")
    if unexpected:
        raise ValueError(f"untracked original sources: {', '.join(unexpected)}")

    variants = manifest.get("variants")
    if not isinstance(variants, list) or not variants:
        raise ValueError(f"{manifest_path}: variants must be a non-empty array")
    declared_variant_counts: dict[str, int] = {}
    for index, variant_record in enumerate(variants):
        if not isinstance(variant_record, dict):
            raise ValueError(f"{manifest_path}: invalid variant at index {index}")
        identifier = variant_record.get("id")
        count = variant_record.get("count")
        if not isinstance(identifier, str) or not identifier or type(count) is not int:
            raise ValueError(f"{manifest_path}: invalid variant at index {index}")
        if identifier in declared_variant_counts:
            raise ValueError(f"{manifest_path}: duplicate variant: {identifier}")
        declared_variant_counts[identifier] = count
    if declared_variant_counts != actual_variant_counts:
        raise ValueError(f"{manifest_path}: variant counts do not match components")

    license_record = manifest.get("license")
    if not isinstance(license_record, dict):
        raise ValueError(f"{manifest_path}: license record is missing")
    if license_record.get("spdx") != "MIT":
        raise ValueError(f"{manifest_path}: upstream license must be MIT")
    copyright_line = license_record.get("copyright")
    if not isinstance(copyright_line, str) or "shadcn" not in copyright_line:
        raise ValueError(f"{manifest_path}: upstream authorship is missing")
    license_relative = license_record.get("sourcePath")
    if not isinstance(license_relative, str):
        raise ValueError(f"{manifest_path}: invalid license source path")
    license_path = _safe_catalog_file(
        package_root,
        license_relative,
        "Sources/ShadcnUI/",
    )
    if not license_path.is_file():
        raise ValueError(f"missing upstream license: {license_relative}")
    license_bytes = license_path.read_bytes()
    if license_record.get("bytes") != len(license_bytes):
        raise ValueError(f"license byte-size mismatch: {license_relative}")
    if license_record.get("sha256") != hashlib.sha256(license_bytes).hexdigest():
        raise ValueError(f"license hash mismatch: {license_relative}")
    if _license_copyright(license_bytes) != copyright_line:
        raise ValueError(f"license authorship mismatch: {license_relative}")
    expected_license_url = f"{UPSTREAM_REPOSITORY}/blob/{commit}/LICENSE.md"
    if license_record.get("sourceURL") != expected_license_url:
        raise ValueError(f"{manifest_path}: unpinned upstream license URL")


def _checkout_upstream() -> tuple[tempfile.TemporaryDirectory[str], Path, str]:
    temporary = tempfile.TemporaryDirectory(prefix="design-system-shadcn-ui-")
    checkout = Path(temporary.name) / "ui"
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
                print("shadcn/ui source catalog is stale:", file=sys.stderr)
                for change in changes:
                    print(f"- {change}", file=sys.stderr)
                return 1
            manifest = _read_json(ROOT / PUBLIC_MANIFEST)
            action = "Updated" if arguments.write else "Verified"
            print(
                f"{action} {manifest['count']} exact shadcn/ui component sources "
                f"from {len(manifest['variants'])} variants"
            )
            return 0
        verify_catalog(ROOT / "packages", ROOT / PUBLIC_MANIFEST)
        manifest = _read_json(ROOT / PUBLIC_MANIFEST)
        print(
            f"Verified {manifest['count']} immutable shadcn/ui component sources "
            f"from {len(manifest['variants'])} variants"
        )
        return 0
    except (
        OSError,
        UnicodeError,
        ValueError,
        json.JSONDecodeError,
        subprocess.CalledProcessError,
    ) as error:
        print(f"shadcn/ui operation failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
