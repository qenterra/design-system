#!/usr/bin/env python3
"""Import and verify immutable upstream icon source catalogs."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path, PurePosixPath


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from lib.path_tools import kebab_posix_path  # noqa: E402


class StyleConfig:
    def __init__(self, identifier: str, upstream_root: str) -> None:
        self.identifier = identifier
        self.upstream_root = Path(upstream_root)


class CatalogConfig:
    def __init__(
        self,
        identifier: str,
        name: str,
        public_directory: str,
        site_url: str,
        repository: str,
        git_url: str,
        branch: str,
        package_version: str,
        copyright_notice: str,
        styles: tuple[StyleConfig, ...],
    ) -> None:
        self.identifier = identifier
        self.name = name
        self.public_directory = public_directory
        self.site_url = site_url
        self.repository = repository
        self.git_url = git_url
        self.branch = branch
        self.package_version = package_version
        self.copyright_notice = copyright_notice
        self.styles = styles
        self.license_path = Path("LICENSE")
        self.license_output_name = "LICENSE"


class IconSource:
    def __init__(
        self,
        identifier: str,
        style: str,
        upstream_path: str,
        source_path: str,
        source_url: str,
        source_bytes: bytes,
    ) -> None:
        self.identifier = identifier
        self.style = style
        self.upstream_path = upstream_path
        self.source_path = source_path
        self.source_url = source_url
        self.source_bytes = source_bytes

    @property
    def sha256(self) -> str:
        return hashlib.sha256(self.source_bytes).hexdigest()


class CatalogSnapshot:
    def __init__(
        self,
        config: CatalogConfig,
        commit: str,
        icons: tuple[IconSource, ...],
        license_bytes: bytes,
    ) -> None:
        self.config = config
        self.commit = commit
        self.icons = icons
        self.license_bytes = license_bytes

    @property
    def file_count(self) -> int:
        return len(self.icons)


CATALOGS = {
    config.identifier: config
    for config in (
        CatalogConfig(
            "tabler-icons",
            "Tabler Icons",
            "TablerIcons",
            "https://tabler.io/icons",
            "https://github.com/tabler/tabler-icons",
            "https://github.com/tabler/tabler-icons.git",
            "main",
            "3.46.0",
            "Copyright (c) 2020-2026 Paweł Kuna",
            (StyleConfig("outline", "icons/outline"), StyleConfig("filled", "icons/filled")),
        ),
        CatalogConfig(
            "phosphor-icons",
            "Phosphor Icons",
            "PhosphorIcons",
            "https://phosphoricons.com/",
            "https://github.com/phosphor-icons/core",
            "https://github.com/phosphor-icons/core.git",
            "main",
            "2.1.1",
            "Copyright (c) 2023 Phosphor Icons",
            tuple(
                StyleConfig(style, f"assets/{style}")
                for style in ("regular", "bold", "duotone", "fill", "light", "thin")
            ),
        ),
        CatalogConfig(
            "iconoir",
            "Iconoir",
            "Iconoir",
            "https://iconoir.com/",
            "https://github.com/iconoir-icons/iconoir",
            "https://github.com/iconoir-icons/iconoir.git",
            "main",
            "7.12.1",
            "Copyright (c) 2021 Luca Burgio",
            (StyleConfig("regular", "icons/regular"), StyleConfig("solid", "icons/solid")),
        ),
        CatalogConfig(
            "bootstrap-icons",
            "Bootstrap Icons",
            "BootstrapIcons",
            "https://icons.getbootstrap.com/",
            "https://github.com/twbs/icons",
            "https://github.com/twbs/icons.git",
            "main",
            "1.13.1",
            "Copyright (c) 2019-2024 The Bootstrap Authors",
            (StyleConfig("default", "icons"),),
        ),
    )
}


def _json_bytes(value: object) -> bytes:
    return (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def _version(root: Path) -> str:
    return (root / "VERSION").read_text(encoding="utf-8").strip()


def _safe_relative(path: str) -> None:
    pure = PurePosixPath(path)
    if pure.is_absolute() or ".." in pure.parts:
        raise ValueError(f"unsafe catalog path: {path}")


def _snapshot(config: CatalogConfig, checkout: Path, commit: str) -> CatalogSnapshot:
    if len(commit) != 40 or any(character not in "0123456789abcdef" for character in commit.lower()):
        raise ValueError(f"{config.identifier}: commit must be a full 40-character SHA")
    license_path = checkout / config.license_path
    license_bytes = license_path.read_bytes()
    if config.copyright_notice.encode("utf-8") not in license_bytes:
        raise ValueError(f"{config.identifier}: expected copyright notice is missing")

    icons: list[IconSource] = []
    seen: set[str] = set()
    multiple_styles = len(config.styles) > 1
    for style in config.styles:
        upstream_root = checkout / style.upstream_root
        if not upstream_root.is_dir():
            raise ValueError(f"{config.identifier}: missing SVG root {style.upstream_root}")
        for path in sorted(upstream_root.rglob("*.svg")):
            if path.is_symlink() or not path.is_file():
                raise ValueError(f"{config.identifier}: unsafe SVG source {path}")
            relative = path.relative_to(upstream_root).as_posix()
            identifier = f"{style.identifier}/{relative[:-4]}" if multiple_styles else relative[:-4]
            if identifier in seen:
                raise ValueError(f"{config.identifier}: duplicate icon identifier {identifier}")
            seen.add(identifier)
            destination = PurePosixPath("Sources", config.public_directory, "Icons")
            if multiple_styles:
                destination /= style.identifier
            destination /= kebab_posix_path(relative)
            upstream_path = path.relative_to(checkout).as_posix()
            source_bytes = path.read_bytes()
            if b"<svg" not in source_bytes[:4096].lower():
                raise ValueError(f"{config.identifier}: {upstream_path} is not an SVG document")
            icons.append(
                IconSource(
                    identifier,
                    style.identifier,
                    upstream_path,
                    destination.as_posix(),
                    f"{config.repository}/raw/{commit}/{upstream_path}",
                    source_bytes,
                )
            )
    if not icons:
        raise ValueError(f"{config.identifier}: published SVG catalog is empty")
    icons.sort(key=lambda item: item.identifier)
    return CatalogSnapshot(config, commit, tuple(icons), license_bytes)


def snapshots_from_checkouts(
    checkouts: dict[str, Path], commits: dict[str, str]
) -> dict[str, CatalogSnapshot]:
    if set(checkouts) != set(CATALOGS) or set(commits) != set(CATALOGS):
        raise ValueError("checkouts and commits must cover every configured icon catalog")
    return {
        identifier: _snapshot(config, Path(checkouts[identifier]), commits[identifier])
        for identifier, config in CATALOGS.items()
    }


def _manifest(snapshot: CatalogSnapshot, version: str) -> dict[str, object]:
    config = snapshot.config
    style_counts = {
        style.identifier: sum(icon.style == style.identifier for icon in snapshot.icons)
        for style in config.styles
    }
    return {
        "version": version,
        "id": config.identifier,
        "name": config.name,
        "source": config.site_url,
        "upstreamRepository": config.repository,
        "upstreamBranch": config.branch,
        "upstreamCommit": snapshot.commit,
        "upstreamPackageVersion": config.package_version,
        "scope": "Exact, unmodified SVG icon sources from the configured published upstream roots.",
        "fileCount": snapshot.file_count,
        "styles": [
            {
                "id": style.identifier,
                "upstreamRoot": style.upstream_root.as_posix(),
                "count": style_counts[style.identifier],
            }
            for style in config.styles
        ],
        "license": {
            "name": "MIT",
            "path": config.license_output_name,
            "upstreamPath": config.license_path.as_posix(),
            "upstreamUrl": f"{config.repository}/blob/{snapshot.commit}/{config.license_path.as_posix()}",
            "sha256": hashlib.sha256(snapshot.license_bytes).hexdigest(),
            "copyright": config.copyright_notice,
        },
        "icons": [
            {
                "id": icon.identifier,
                "style": icon.style,
                "upstreamPath": icon.upstream_path,
                "sourcePath": icon.source_path,
                "sourceUrl": icon.source_url,
                "bytes": len(icon.source_bytes),
                "sha256": icon.sha256,
            }
            for icon in snapshot.icons
        ],
    }


def _readme(snapshot: CatalogSnapshot) -> bytes:
    config = snapshot.config
    styles = ", ".join(f"`{style.identifier}`" for style in config.styles)
    text = f"""# {config.name}

This directory preserves {snapshot.file_count} exact, unmodified SVG sources from [{config.name}]({config.site_url}) at upstream commit [`{snapshot.commit}`]({config.repository}/commit/{snapshot.commit}). Available styles: {styles}.

The upstream MIT license is reproduced in `{config.license_output_name}`. File-level provenance, byte sizes, and SHA-256 digests are recorded in `manifest.json`.

## Usage boundary

- Search this catalog before drawing a new icon.
- Use one external icon family consistently within a project.
- Do not edit these upstream originals. Store an approved derivative separately and document its provenance.
- These files are reference assets, not an npm or SwiftPM target.
"""
    return text.encode("utf-8")


def _catalog_public_paths(snapshot: CatalogSnapshot) -> list[str]:
    prefix = f"packages/Sources/{snapshot.config.public_directory}"
    return sorted(
        [
            f"{prefix}/{snapshot.config.license_output_name}",
            f"{prefix}/README.md",
            f"{prefix}/manifest.json",
        ]
        + [f"packages/{icon.source_path}" for icon in snapshot.icons]
    )


def _write_catalog(root: Path, snapshot: CatalogSnapshot, version: str) -> None:
    public_root = root / "packages/Sources" / snapshot.config.public_directory
    if public_root.exists():
        shutil.rmtree(public_root)
    public_root.mkdir(parents=True)
    (public_root / snapshot.config.license_output_name).write_bytes(snapshot.license_bytes)
    (public_root / "README.md").write_bytes(_readme(snapshot))
    (public_root / "manifest.json").write_bytes(_json_bytes(_manifest(snapshot, version)))
    for icon in snapshot.icons:
        destination = root / "packages" / icon.source_path
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(icon.source_bytes)


def _write_registries(root: Path, snapshots: dict[str, CatalogSnapshot], version: str) -> None:
    registry = {
        "$schema": "../schemas/icon-source-registry.schema.json",
        "version": version,
        "selectionPolicy": {"projectFamilyLimit": 1, "searchBeforeCreate": True},
        "catalogs": [
            {
                "id": identifier,
                "name": snapshot.config.name,
                "source": snapshot.config.site_url,
                "upstreamRepository": snapshot.config.repository,
                "upstreamCommit": snapshot.commit,
                "upstreamPackageVersion": snapshot.config.package_version,
                "publicRoot": f"packages/Sources/{snapshot.config.public_directory}",
                "manifest": f"packages/Sources/{snapshot.config.public_directory}/manifest.json",
                "fileCount": snapshot.file_count,
                "license": "MIT",
            }
            for identifier, snapshot in sorted(snapshots.items())
        ],
    }
    (root / "registry").mkdir(parents=True, exist_ok=True)
    (root / "registry/icon-sources.json").write_bytes(_json_bytes(registry))

    packages_path = root / "registry/packages.json"
    packages = json.loads(packages_path.read_text(encoding="utf-8"))
    metadata = next(item for item in packages["packages"] if item["id"] == "repository-metadata")
    prefixes = tuple(
        f"packages/Sources/{config.public_directory}/" for config in CATALOGS.values()
    )
    retained = [path for path in metadata["publicPaths"] if not path.startswith(prefixes)]
    additions = [path for snapshot in snapshots.values() for path in _catalog_public_paths(snapshot)]
    metadata["publicPaths"] = sorted(set(retained + additions))
    packages_path.write_bytes(_json_bytes(packages))


def sync_from_checkouts(
    checkouts: dict[str, Path],
    commits: dict[str, str],
    *,
    write: bool,
    root: Path = ROOT,
) -> dict[str, CatalogSnapshot]:
    snapshots = snapshots_from_checkouts(checkouts, commits)
    if write:
        version = _version(root)
        for snapshot in snapshots.values():
            _write_catalog(root, snapshot, version)
        _write_registries(root, snapshots, version)
    return snapshots


def verify_catalog(packages_root: Path, manifest_path: Path) -> None:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    config = CATALOGS.get(str(manifest.get("id")))
    if config is None or manifest_path.parent.name != config.public_directory:
        raise ValueError(f"{manifest_path}: unknown or misplaced icon catalog")
    commit = manifest.get("upstreamCommit")
    if not isinstance(commit, str) or len(commit) != 40:
        raise ValueError(f"{config.identifier}: invalid upstream commit")
    style_counts = {
        style.identifier: sum(
            isinstance(item, dict) and item.get("style") == style.identifier
            for item in manifest.get("icons", [])
        )
        for style in config.styles
    }
    expected_styles = [
        {
            "id": style.identifier,
            "upstreamRoot": style.upstream_root.as_posix(),
            "count": style_counts[style.identifier],
        }
        for style in config.styles
    ]
    if manifest.get("styles") != expected_styles:
        raise ValueError(f"{config.identifier}: style metadata mismatch")
    if (
        manifest.get("source") != config.site_url
        or manifest.get("upstreamRepository") != config.repository
        or manifest.get("upstreamBranch") != config.branch
    ):
        raise ValueError(f"{config.identifier}: upstream catalog metadata mismatch")
    public_root = manifest_path.parent
    declared: set[Path] = set()
    identifiers: list[str] = []
    for item in manifest["icons"]:
        style_by_id = {style.identifier: style for style in config.styles}
        style = style_by_id.get(str(item.get("style")))
        if style is None:
            raise ValueError(f"{manifest['id']}: style metadata mismatch for {item.get('id')}")
        upstream_path = PurePosixPath(str(item.get("upstreamPath", "")))
        upstream_root = PurePosixPath(style.upstream_root.as_posix())
        try:
            relative = upstream_path.relative_to(upstream_root)
        except ValueError as error:
            raise ValueError(f"{manifest['id']}: upstream path mismatch for {item.get('id')}") from error
        if relative.suffix != ".svg" or not relative.parts or ".." in relative.parts:
            raise ValueError(f"{manifest['id']}: upstream path mismatch for {item.get('id')}")
        multiple_styles = len(config.styles) > 1
        expected_id = (
            f"{style.identifier}/{relative.with_suffix('').as_posix()}"
            if multiple_styles
            else relative.with_suffix("").as_posix()
        )
        expected_source = PurePosixPath("Sources", config.public_directory, "Icons")
        if multiple_styles:
            expected_source /= style.identifier
        expected_source /= kebab_posix_path(relative)
        if item.get("id") != expected_id:
            raise ValueError(f"{manifest['id']}: icon identifier mismatch for {item.get('id')}")
        if item.get("sourcePath") != expected_source.as_posix():
            raise ValueError(f"{manifest['id']}: destination path mismatch for {item.get('id')}")
        _safe_relative(item["sourcePath"])
        path = packages_root / item["sourcePath"]
        try:
            path.relative_to(public_root)
        except ValueError as error:
            raise ValueError(f"{manifest['id']}: source path escapes catalog") from error
        if not path.is_file() or path.is_symlink():
            raise ValueError(f"{manifest['id']}: missing source {item['sourcePath']}")
        source_bytes = path.read_bytes()
        if hashlib.sha256(source_bytes).hexdigest() != item["sha256"]:
            raise ValueError(f"{manifest['id']}: hash mismatch for {item['sourcePath']}")
        if len(source_bytes) != item["bytes"]:
            raise ValueError(f"{manifest['id']}: byte count mismatch for {item['sourcePath']}")
        expected_url = f"{config.repository}/raw/{commit}/{item['upstreamPath']}"
        if item.get("sourceUrl") != expected_url:
            raise ValueError(f"{manifest['id']}: unpinned source URL for {item['id']}")
        declared.add(path.resolve())
        identifiers.append(item["id"])
    if identifiers != sorted(identifiers) or len(identifiers) != len(set(identifiers)):
        raise ValueError(f"{manifest['id']}: icon identifiers are not sorted and unique")
    actual = {path.resolve() for path in (public_root / "Icons").rglob("*.svg") if path.is_file()}
    extras = actual - declared
    if extras:
        raise ValueError(
            f"{manifest['id']}: untracked source "
            f"{min(extras).relative_to(public_root.resolve())}"
        )
    missing = declared - actual
    if missing:
        raise ValueError(f"{manifest['id']}: declared source is outside icons")
    if len(declared) != manifest["fileCount"]:
        raise ValueError(f"{manifest['id']}: file count mismatch")
    license_path = public_root / manifest["license"]["path"]
    license_bytes = license_path.read_bytes()
    if hashlib.sha256(license_bytes).hexdigest() != manifest["license"]["sha256"]:
        raise ValueError(f"{manifest['id']}: license hash mismatch")
    if (
        manifest["license"].get("name") != "MIT"
        or manifest["license"].get("copyright") != config.copyright_notice
        or config.copyright_notice.encode("utf-8") not in license_bytes
    ):
        raise ValueError(f"{manifest['id']}: license authorship mismatch")


def verify_all(root: Path = ROOT) -> None:
    registry = json.loads((root / "registry/icon-sources.json").read_text(encoding="utf-8"))
    expected = sorted(CATALOGS)
    if [item["id"] for item in registry["catalogs"]] != expected:
        raise ValueError("icon source registry catalog set is incomplete or unsorted")
    registry_by_id = {item["id"]: item for item in registry["catalogs"]}
    for config in CATALOGS.values():
        manifest_path = root / "packages/Sources" / config.public_directory / "manifest.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        expected_registry = {
            "id": config.identifier,
            "name": manifest["name"],
            "source": manifest["source"],
            "upstreamRepository": manifest["upstreamRepository"],
            "upstreamCommit": manifest["upstreamCommit"],
            "upstreamPackageVersion": manifest["upstreamPackageVersion"],
            "publicRoot": f"packages/Sources/{config.public_directory}",
            "manifest": f"packages/Sources/{config.public_directory}/manifest.json",
            "fileCount": manifest["fileCount"],
            "license": manifest["license"]["name"],
        }
        if registry_by_id.get(config.identifier) != expected_registry:
            raise ValueError(f"{config.identifier}: registry does not match public manifest")
        verify_catalog(
            root / "packages",
            manifest_path,
        )


def _git_commit(checkout: Path) -> str:
    return subprocess.run(
        ["git", "rev-parse", "HEAD"], cwd=checkout, check=True, text=True, capture_output=True
    ).stdout.strip()


def _clone_snapshots() -> tuple[dict[str, Path], dict[str, str], tempfile.TemporaryDirectory[str]]:
    temporary = tempfile.TemporaryDirectory(prefix="design-system-icon-sync-")
    base = Path(temporary.name)
    checkouts: dict[str, Path] = {}
    commits: dict[str, str] = {}
    for identifier, config in CATALOGS.items():
        checkout = base / identifier
        subprocess.run(
            ["git", "clone", "--depth", "1", "--branch", config.branch, config.git_url, str(checkout)],
            check=True,
        )
        checkouts[identifier] = checkout
        commits[identifier] = _git_commit(checkout)
    return checkouts, commits, temporary


def _matches_current(root: Path, snapshots: dict[str, CatalogSnapshot]) -> bool:
    for snapshot in snapshots.values():
        manifest_path = root / "packages/Sources" / snapshot.config.public_directory / "manifest.json"
        if not manifest_path.is_file():
            return False
        if json.loads(manifest_path.read_text(encoding="utf-8")) != _manifest(snapshot, _version(root)):
            return False
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("verify")
    sync = subparsers.add_parser("sync")
    sync.add_argument("--write", action="store_true")
    sync.add_argument("--check", action="store_true")
    local = subparsers.add_parser("from-checkouts")
    for identifier in CATALOGS:
        local.add_argument(f"--{identifier}", type=Path, required=True)
    local.add_argument("--write", action="store_true")
    args = parser.parse_args()

    if args.command == "verify":
        verify_all()
        print("Icon source catalogs verified.")
        return 0
    if args.command == "from-checkouts":
        checkouts = {identifier: getattr(args, identifier.replace("-", "_")) for identifier in CATALOGS}
        commits = {identifier: _git_commit(path) for identifier, path in checkouts.items()}
        snapshots = sync_from_checkouts(checkouts, commits, write=args.write)
    else:
        checkouts, commits, temporary = _clone_snapshots()
        try:
            snapshots = sync_from_checkouts(checkouts, commits, write=args.write)
            if args.check and not _matches_current(ROOT, snapshots):
                raise SystemExit("Stored icon catalogs are not current with upstream default branches.")
        finally:
            temporary.cleanup()
    print(", ".join(f"{identifier}: {snapshot.file_count}" for identifier, snapshot in snapshots.items()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
