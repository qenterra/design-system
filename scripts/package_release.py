#!/usr/bin/env python3
"""Validate and describe private QDS package releases."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Literal

ROOT = Path(__file__).resolve().parents[1]
SEMVER = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")
SHA = re.compile(r"^[0-9a-f]{40}$")
LFS_HEADER = b"version https://git-lfs.github.com/spec/v1"
CSS_ALLOWED = {
    "LICENSE",
    "README.md",
    "icons.json",
    "package.json",
    "recipes.css",
    "tokens.css",
    "tokens.json",
}
SWIFT_ALLOWED_ROOTS = {"LICENSE", "Package.swift", "README.md", "Sources", "Tests"}
DENIED_PARTS = {".DS_Store", ".env", ".swiftpm", ".superpowers", "node_modules", "output"}


def canonical_version(root: Path) -> str:
    """Return the canonical release version or reject malformed input."""
    path = root / "VERSION"
    if not path.is_file():
        raise ValueError("VERSION is missing")
    version = path.read_text(encoding="utf-8").strip()
    if not SEMVER.fullmatch(version):
        raise ValueError(f"VERSION must be a stable semantic version, got {version!r}")
    return version


def _json(path: Path) -> object:
    return json.loads(path.read_text(encoding="utf-8"))


def validate_version_alignment(root: Path) -> list[str]:
    """Validate versions consumed by the two package distributions."""
    try:
        version = canonical_version(root)
    except (OSError, ValueError) as error:
        return [str(error)]

    errors: list[str] = []
    json_versions = {
        "package.json": ("version",),
        "packages/css/package.json": ("version",),
        "packages/css/icons.json": ("version",),
    }
    for relative_path, keys in json_versions.items():
        path = root / relative_path
        if not path.is_file():
            errors.append(f"{relative_path} is missing")
            continue
        try:
            value: object = _json(path)
            for key in keys:
                if not isinstance(value, dict):
                    raise KeyError(".".join(keys))
                value = value[key]
        except (OSError, json.JSONDecodeError, KeyError) as error:
            errors.append(f"{relative_path} version is unreadable: {error}")
            continue
        if value != version:
            errors.append(f"{relative_path} version {value} != {version}")

    tokens_path = root / "packages/css/tokens.json"
    if not tokens_path.is_file():
        errors.append("packages/css/tokens.json is missing")
    else:
        try:
            token_families = _json(tokens_path)
            if not isinstance(token_families, dict) or not token_families:
                raise ValueError("expected token family object")
            for family, data in sorted(token_families.items()):
                if not isinstance(data, dict):
                    raise ValueError(f"{family} is not an object")
                actual = data.get("meta", {}).get("version")
                if actual != version:
                    errors.append(
                        f"packages/css/tokens.json {family} version {actual} != {version}"
                    )
        except (OSError, json.JSONDecodeError, ValueError, AttributeError) as error:
            errors.append(f"packages/css/tokens.json version is unreadable: {error}")

    swift_path = (
        root
        / "packages/swift/Sources/QenTerraDesignTokens/QDSGeneratedTokens.swift"
    )
    if not swift_path.is_file():
        errors.append(f"{swift_path.relative_to(root)} is missing")
    else:
        match = re.search(
            r'(?:static\s+let|let)\s+version\s*=\s*"([^"]+)"',
            swift_path.read_text(encoding="utf-8"),
        )
        if match is None:
            errors.append(f"{swift_path.relative_to(root)} version is unreadable")
        elif match.group(1) != version:
            errors.append(
                f"{swift_path.relative_to(root)} version {match.group(1)} != {version}"
            )
    return errors


def _files(root: Path) -> list[Path]:
    return sorted(path for path in root.rglob("*") if path.is_file())


def _package_files(repository_root: Path, package_root: Path) -> list[Path]:
    """Return files eligible for Git publication, including staged new files."""
    if not (repository_root / ".git").exists():
        return _files(package_root)
    result = subprocess.run(
        [
            "git",
            "-C",
            str(repository_root),
            "ls-files",
            "--cached",
            "--others",
            "--exclude-standard",
            "--",
            package_root.relative_to(repository_root).as_posix(),
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    return sorted(
        repository_root / relative
        for relative in result.stdout.splitlines()
        if (repository_root / relative).is_file()
    )


def validate_package_payload(root: Path, package: str) -> list[str]:
    """Reject package files outside the reviewed allowlists."""
    if package not in {"css", "swift"}:
        return [f"unknown package {package!r}"]
    package_root = root / "packages" / package
    if not package_root.is_dir():
        return [f"packages/{package} is missing"]

    errors: list[str] = []
    files = _package_files(root, package_root)
    for path in files:
        relative = path.relative_to(package_root)
        if DENIED_PARTS.intersection(relative.parts):
            errors.append(f"packages/{package}/{relative}: denied path in package payload")
        if path.read_bytes().startswith(LFS_HEADER):
            errors.append(f"packages/{package}/{relative}: Git LFS pointer in package payload")

        if package == "css" and relative.as_posix() not in CSS_ALLOWED:
            errors.append(f"packages/css/{relative}: unexpected CSS package file")
        if package == "swift" and relative.parts[0] not in SWIFT_ALLOWED_ROOTS:
            errors.append(f"packages/swift/{relative}: unexpected Swift package root")

    required = CSS_ALLOWED if package == "css" else {"LICENSE", "Package.swift", "README.md", "Sources", "Tests"}
    present_roots = {path.relative_to(package_root).parts[0] for path in files}
    for name in sorted(required - present_roots):
        errors.append(f"packages/{package}/{name} is missing from package payload")
    return errors


def tree_digest(root: Path) -> str:
    """Hash a file tree including relative paths and contents."""
    digest = hashlib.sha256()
    for path in _files(root):
        relative = path.relative_to(root).as_posix().encode("utf-8")
        digest.update(len(relative).to_bytes(8, "big"))
        digest.update(relative)
        content = path.read_bytes()
        digest.update(len(content).to_bytes(8, "big"))
        digest.update(content)
    return digest.hexdigest()


def classify_remote_ref(
    existing_sha: str | None,
    expected_sha: str,
) -> Literal["missing", "matching", "conflict"]:
    if existing_sha is None:
        return "missing"
    return "matching" if existing_sha == expected_sha else "conflict"


def build_release_manifest(
    root: Path,
    source_sha: str,
    swift_tree_sha: str,
    npm_tarball: Path,
) -> dict[str, object]:
    """Build deterministic evidence for a package release candidate."""
    for name, value in (("source SHA", source_sha), ("Swift tree SHA", swift_tree_sha)):
        if not SHA.fullmatch(value):
            raise ValueError(f"{name} must be a 40-character lowercase Git SHA")
    tarball_bytes = npm_tarball.read_bytes()
    css_root = root / "packages/css"
    return {
        "version": canonical_version(root),
        "sourceSha": source_sha,
        "swift": {
            "treeSha": swift_tree_sha,
            "payloadSha256": tree_digest(root / "packages/swift"),
        },
        "npm": {
            "filename": npm_tarball.name,
            "payloadSha256": hashlib.sha256(tarball_bytes).hexdigest(),
            "files": [path.relative_to(css_root).as_posix() for path in _files(css_root)],
        },
        "status": "verified",
        "manualNotProven": [
            "consumer product runtime",
            "native rendering and accessibility",
        ],
    }


def validate(root: Path) -> list[str]:
    errors = validate_version_alignment(root)
    errors.extend(validate_package_payload(root, "css"))
    errors.extend(validate_package_payload(root, "swift"))
    return errors


def _inside(path: Path, root: Path) -> bool:
    resolved = path.resolve()
    repository = root.resolve()
    return resolved == repository or repository in resolved.parents


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    validate_parser = subparsers.add_parser("validate")
    validate_parser.add_argument("--root", type=Path, default=ROOT)

    manifest_parser = subparsers.add_parser("manifest")
    manifest_parser.add_argument("--root", type=Path, default=ROOT)
    manifest_parser.add_argument("--source-sha", required=True)
    manifest_parser.add_argument("--swift-tree-sha", required=True)
    manifest_parser.add_argument("--npm-tarball", type=Path, required=True)
    manifest_parser.add_argument("--output", type=Path, required=True)
    arguments = parser.parse_args(argv)

    if arguments.command == "validate":
        errors = validate(arguments.root)
        if errors:
            for error in errors:
                print(error, file=sys.stderr)
            return 1
        print(f"Private package contract passed for {canonical_version(arguments.root)}")
        return 0

    if _inside(arguments.output, arguments.root):
        print("Release manifest output must be outside the repository", file=sys.stderr)
        return 1
    manifest = build_release_manifest(
        arguments.root,
        arguments.source_sha,
        arguments.swift_tree_sha,
        arguments.npm_tarball,
    )
    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    arguments.output.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote release manifest to {arguments.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
