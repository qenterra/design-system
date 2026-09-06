#!/usr/bin/env python3
"""Align the local Design System version and regenerate delivery metadata."""

from __future__ import annotations

import argparse
import importlib.util
import json
import os
import re
import shutil
import tempfile
import uuid
from pathlib import Path
from types import ModuleType


ROOT = Path(__file__).resolve().parents[1]
PLAIN_SEMVER = re.compile(r"(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\Z")
TOKEN_NAMES = ("components", "foundation", "motion", "platforms", "products", "semantic", "typography")
REGISTRY_NAMES = (
    "components",
    "icon-sources",
    "icons",
    "magic-ui",
    "native-patterns",
    "packages",
    "qenterra-components",
    "reui",
    "shadcn-ui",
    "uiable",
)
PACKAGE_JSON_PATHS = (
    Path("package.json"),
    Path("packages/package.json"),
    Path("packages/npm/design-tokens/package.json"),
)


def load_module(path: Path, name: str) -> ModuleType:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load required writer: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


generate_module = load_module(ROOT / "scripts/generate.py", "qenterra_generate")
public_module = load_module(ROOT / "scripts/build_public_packages.py", "qenterra_public_packages")


def json_bytes(value: object) -> bytes:
    return (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def read_json(path: Path) -> dict[str, object]:
    if not path.is_file():
        raise ValueError(f"required canonical version surface is missing: {path}")
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"cannot read canonical version surface {path}: {error}") from error
    if not isinstance(value, dict):
        raise ValueError(f"canonical version surface must be an object: {path}")
    return value


def require_version(value: object, expected: str, relative: Path) -> None:
    if value != expected:
        raise ValueError(
            f"{relative.as_posix()} version must match VERSION {expected!r}; found {value!r}"
        )


def canonical_payloads(root: Path, version: str) -> dict[Path, bytes]:
    version_path = root / "VERSION"
    if not version_path.is_file():
        raise ValueError("required canonical version surface is missing: VERSION")
    current = version_path.read_text(encoding="utf-8").strip()
    if PLAIN_SEMVER.fullmatch(current) is None:
        raise ValueError(f"VERSION does not contain plain SemVer: {current!r}")

    payloads: dict[Path, bytes] = {Path("VERSION"): f"{version}\n".encode()}
    for name in TOKEN_NAMES:
        relative = Path("tokens") / f"{name}.json"
        data = read_json(root / relative)
        metadata = data.get("meta")
        if not isinstance(metadata, dict) or "version" not in metadata:
            raise ValueError(f"{relative.as_posix()} is missing meta.version")
        require_version(metadata["version"], current, relative)
        metadata["version"] = version
        payloads[relative] = json_bytes(data)

    for name in REGISTRY_NAMES:
        relative = Path("registry") / f"{name}.json"
        data = read_json(root / relative)
        if "version" not in data:
            raise ValueError(f"{relative.as_posix()} is missing version")
        require_version(data["version"], current, relative)
        data["version"] = version
        if name == "packages":
            packages = data.get("packages")
            if not isinstance(packages, list) or not packages:
                raise ValueError("registry/packages.json packages must be a non-empty array")
            for index, package in enumerate(packages):
                if not isinstance(package, dict) or "version" not in package:
                    raise ValueError(f"registry/packages.json packages[{index}] is missing version")
                require_version(package["version"], current, relative)
                package["version"] = version
        payloads[relative] = json_bytes(data)

    for relative in PACKAGE_JSON_PATHS:
        data = read_json(root / relative)
        if "version" not in data:
            raise ValueError(f"{relative.as_posix()} is missing version")
        require_version(data["version"], current, relative)
        data["version"] = version
        payloads[relative] = json_bytes(data)
    return payloads


def atomic_write(path: Path, payload: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.set-version-{uuid.uuid4().hex}")
    try:
        temporary.write_bytes(payload)
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def apply_payloads(root: Path, payloads: dict[Path, bytes]) -> list[Path]:
    changed = [relative for relative, payload in payloads.items() if (root / relative).read_bytes() != payload]
    previous = {relative: (root / relative).read_bytes() for relative in changed}
    applied: list[Path] = []
    try:
        for relative in changed:
            atomic_write(root / relative, payloads[relative])
            applied.append(relative)
    except OSError:
        for relative in reversed(applied):
            atomic_write(root / relative, previous[relative])
        raise
    return [root / relative for relative in changed]


def set_version(root: Path, version: str) -> list[Path]:
    """Update validated version sources and deterministic outputs without Git or publication."""
    if PLAIN_SEMVER.fullmatch(version) is None:
        raise ValueError(f"version must be plain SemVer MAJOR.MINOR.PATCH: {version!r}")
    root = root.resolve()
    canonical = canonical_payloads(root, version)

    with tempfile.TemporaryDirectory(prefix="qenterra-version-stage-", dir=root.parent) as directory:
        stage = Path(directory) / "repository"
        shutil.copytree(
            root,
            stage,
            copy_function=os.link,
            ignore=shutil.ignore_patterns(".git", ".build", ".swiftpm", "__pycache__"),
        )
        for relative, payload in canonical.items():
            atomic_write(stage / relative, payload)

        generated = {
            Path(relative): content.encode("utf-8")
            for relative, content in generate_module.build_outputs(stage).items()
        }
        for relative, payload in generated.items():
            atomic_write(stage / relative, payload)

        public_manifest = public_module.build_manifest(stage)
        delivery = {Path("packages/release-manifest.json"): json_bytes(public_manifest)}
        for relative, payload in delivery.items():
            atomic_write(stage / relative, payload)
        complete = {**canonical, **generated, **delivery}

        if generate_module.check_outputs(stage):
            raise RuntimeError("generated output writer did not converge in the transaction stage")
        if public_module.check_manifest(stage):
            raise RuntimeError("public package writer did not converge in the transaction stage")

    return apply_payloads(root, complete)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version")
    parser.add_argument("--root", type=Path, default=ROOT)
    arguments = parser.parse_args()
    try:
        changed = set_version(arguments.root, arguments.version)
    except (OSError, RuntimeError, ValueError) as error:
        parser.exit(1, f"set-version failed: {error}\n")
    for path in changed:
        print(path.relative_to(arguments.root.resolve()).as_posix())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
