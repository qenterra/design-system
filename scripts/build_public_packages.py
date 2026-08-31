#!/usr/bin/env python3
"""Build and export the deterministic public Design System package tree."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PUBLIC_ROOT = ROOT / "packages"
MANIFEST = PUBLIC_ROOT / "release-manifest.json"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def registered_paths(root: Path) -> list[Path]:
    registry_path = root / "registry/packages.json"
    registry = json.loads(registry_path.read_text(encoding="utf-8"))
    version = (root / "VERSION").read_text(encoding="utf-8").strip()
    if registry.get("version") != version:
        raise ValueError("registry/packages.json version does not match VERSION")

    relative_paths: list[str] = []
    for package in registry.get("packages", []):
        if package.get("version") != version:
            raise ValueError(f"package {package.get('id')!r} version does not match VERSION")
        relative_paths.extend(package.get("publicPaths", []))

    if len(relative_paths) != len(set(relative_paths)):
        raise ValueError("registry/packages.json contains duplicate public paths")

    paths: list[Path] = []
    public_root = (root / "packages").resolve()
    for relative in sorted(relative_paths):
        path = (root / relative).resolve()
        if public_root not in path.parents:
            raise ValueError(f"public path escapes packages/: {relative}")
        if not path.is_file():
            raise ValueError(f"registered public file is missing: {relative}")
        paths.append(path)
    return paths


def build_manifest(root: Path = ROOT) -> dict[str, object]:
    public_root = root / "packages"
    version = (root / "VERSION").read_text(encoding="utf-8").strip()
    files = []
    for path in registered_paths(root):
        files.append(
            {
                "path": path.relative_to(public_root).as_posix(),
                "sha256": sha256(path),
                "bytes": path.stat().st_size,
            }
        )
    return {
        "schemaVersion": 1,
        "version": version,
        "repository": "https://github.com/qenterra/design-system",
        "files": files,
    }


def write_manifest(root: Path = ROOT) -> dict[str, object]:
    manifest = build_manifest(root)
    path = root / "packages/release-manifest.json"
    path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return manifest


def check_manifest(root: Path = ROOT) -> list[str]:
    path = root / "packages/release-manifest.json"
    if not path.is_file():
        return ["packages/release-manifest.json is missing"]
    try:
        actual = json.loads(path.read_text(encoding="utf-8"))
        expected = build_manifest(root)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        return [str(error)]
    return [] if actual == expected else ["packages/release-manifest.json is stale"]


def export_public_tree(destination: Path, root: Path = ROOT) -> None:
    destination = destination.resolve()
    repository = root.resolve()
    if destination == repository or repository in destination.parents:
        raise ValueError("package export destination must be outside the repository")
    if destination.exists() and any(destination.iterdir()):
        raise ValueError("public export destination must be empty")
    destination.mkdir(parents=True, exist_ok=True)

    manifest_path = root / "packages/release-manifest.json"
    errors = check_manifest(root)
    if errors:
        raise ValueError("; ".join(errors))

    for source in registered_paths(root):
        relative = source.relative_to(root / "packages")
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    shutil.copy2(manifest_path, destination / "release-manifest.json")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["write", "check", "export"])
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--destination", type=Path)
    arguments = parser.parse_args(argv)

    try:
        if arguments.command == "write":
            manifest = write_manifest(arguments.root)
            print(f"Wrote public manifest for {len(manifest['files'])} files")
            return 0
        if arguments.command == "check":
            errors = check_manifest(arguments.root)
            if errors:
                for error in errors:
                    print(error, file=sys.stderr)
                return 1
            print("Public release manifest is current")
            return 0
        if arguments.destination is None:
            parser.error("export requires --destination")
        export_public_tree(arguments.destination, arguments.root)
        print(f"Exported public packages to {arguments.destination.resolve()}")
        return 0
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"Public package build failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
