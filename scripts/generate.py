#!/usr/bin/env python3
"""Generate package adapters and design-tool handoff data from canonical sources."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from lib.figma_export import generate_figma_exports  # noqa: E402
from lib.token_tools import (  # noqa: E402
    generate_css,
    generate_swift,
    generate_swift_icons,
    generate_token_reference,
    load_json,
)


TOKEN_NAMES = ("foundation", "semantic", "typography", "motion", "components", "platforms", "products")
PUBLISHED_SOURCE_PATHS = (
    "tokens",
    "registry/icons.json",
    "packages/npm/design-tokens/src",
    "packages/Sources/ReUI/Base",
)
PUBLISHED_ARTIFACT_PATHS = ("packages/Sources/ReUI/Registry",)


def json_text(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, indent=2, sort_keys=False) + "\n"


def load_sources(root: Path) -> tuple[dict[str, dict[str, Any]], dict[str, Any], dict[str, Any]]:
    tokens = {name: load_json(root / "tokens" / f"{name}.json") for name in TOKEN_NAMES}
    components = load_json(root / "registry/components.json")
    icons = load_json(root / "registry/icons.json")
    return tokens, components, icons


def published_artifact_manifest(root: Path, outputs: dict[str, str], version: str) -> dict[str, Any]:
    paths: set[str] = set()
    for relative in PUBLISHED_SOURCE_PATHS:
        candidate = root / relative
        if candidate.is_file():
            paths.add(relative)
        else:
            paths.update(
                path.relative_to(root).as_posix()
                for path in candidate.rglob("*")
                if path.is_file()
            )
    paths.update(relative for relative in outputs if relative.startswith("generated/"))
    for relative in PUBLISHED_ARTIFACT_PATHS:
        paths.update(
            path.relative_to(root).as_posix()
            for path in (root / relative).rglob("*")
            if path.is_file()
        )
    paths.update(
        relative
        for relative in outputs
        if relative.startswith("packages/npm/design-tokens/dist/")
        or relative
        in {
            "packages/Sources/QenTerra/DesignTokens/GeneratedIcons.swift",
            "packages/Sources/QenTerra/DesignTokens/GeneratedTokens.swift",
        }
    )

    records: list[dict[str, Any]] = []
    for relative in sorted(paths):
        payload = (
            outputs[relative].encode("utf-8")
            if relative in outputs
            else (root / relative).read_bytes()
        )
        records.append(
            {
                "path": relative,
                "sha256": hashlib.sha256(payload).hexdigest(),
                "bytes": len(payload),
            }
        )
    return {
        "schemaVersion": 1,
        "version": version,
        "repository": "https://github.com/qenterra/design-system",
        "files": records,
    }


def build_qenterra_component_manifest(root: Path, version: str) -> dict[str, Any]:
    registry = load_json(root / "registry/qenterra-components.json")
    if registry.get("version") != version:
        raise ValueError("registry/qenterra-components.json version does not match VERSION")
    records: list[dict[str, Any]] = []
    for component in registry.get("components", []):
        source_path = component.get("sourcePath")
        if not isinstance(source_path, str):
            raise ValueError("QenTerra component sourcePath must be a string")
        source = root / source_path
        if not source.is_file():
            raise ValueError(f"QenTerra component source is missing: {source_path}")
        payload = source.read_bytes()
        public_record = {
            key: value
            for key, value in component.items()
            if key != "sourcePath"
        }
        public_record["sourcePath"] = source.relative_to(root / "packages").as_posix()
        public_record["sha256"] = hashlib.sha256(payload).hexdigest()
        public_record["bytes"] = len(payload)
        records.append(public_record)
    return {
        "version": version,
        "sourceRegistry": "registry/qenterra-components.json",
        "components": records,
    }


def build_outputs(root: Path = ROOT) -> dict[str, str]:
    tokens, components, icons = load_sources(root)
    foundation = tokens["foundation"]
    version = (root / "VERSION").read_text(encoding="utf-8").strip()
    for name, data in tokens.items():
        if data.get("meta", {}).get("version") != version:
            raise ValueError(f"tokens/{name}.json version does not match VERSION")
    if components.get("version") != version or icons.get("version") != version:
        raise ValueError("registry version does not match VERSION")

    outputs: dict[str, str] = {
        "packages/npm/design-tokens/src/tokens.json": json_text(tokens),
        "packages/npm/design-tokens/src/icons.json": json_text(icons),
        "packages/npm/design-tokens/dist/tokens.css": generate_css(
            foundation,
            tokens["semantic"],
            tokens["typography"],
            tokens["motion"],
            tokens["components"],
        ),
        "packages/npm/design-tokens/dist/tokens.json": json_text(tokens),
        "packages/npm/design-tokens/dist/icons.json": json_text(
            {
                "version": version,
                "platform": icons["platform"],
                "icons": icons["icons"],
            }
        ),
        "packages/npm/design-tokens/dist/recipes.css": (
            root / "packages/npm/design-tokens/src/recipes.css"
        ).read_text(encoding="utf-8"),
        "packages/Sources/QenTerra/DesignTokens/GeneratedTokens.swift": generate_swift(
            foundation,
            tokens["semantic"],
            tokens["typography"],
            tokens["motion"],
            tokens["components"],
        ),
        "packages/Sources/QenTerra/DesignTokens/GeneratedIcons.swift": generate_swift_icons(icons),
        "packages/Sources/QenTerra/manifest.json": json_text(
            build_qenterra_component_manifest(root, version)
        ),
        "generated/TOKEN_REFERENCE.md": generate_token_reference(
            [(f"{name}.json", tokens[name]) for name in TOKEN_NAMES]
        ),
    }
    for filename, payload in generate_figma_exports(tokens, components, icons).items():
        outputs[f"generated/figma/{filename}"] = json_text(payload)
    outputs["registry/published-artifacts.json"] = json_text(
        published_artifact_manifest(root, outputs, version)
    )
    return outputs


def write_outputs(root: Path = ROOT) -> int:
    outputs = build_outputs(root)
    changed = 0
    for relative, content in outputs.items():
        path = root / relative
        previous = path.read_text(encoding="utf-8") if path.is_file() else None
        if previous == content:
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        changed += 1
    return changed


def check_outputs(root: Path = ROOT) -> list[str]:
    errors: list[str] = []
    for relative, expected in build_outputs(root).items():
        path = root / relative
        if not path.is_file():
            errors.append(f"missing generated output: {relative}")
        elif path.read_text(encoding="utf-8") != expected:
            errors.append(f"stale generated output: {relative}")
    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", nargs="?", choices=["write", "check"], default="check")
    parser.add_argument("--root", type=Path, default=ROOT)
    arguments = parser.parse_args(argv)
    try:
        if arguments.command == "write":
            changed = write_outputs(arguments.root)
            print(f"Generated Design System outputs ({changed} changed)")
            return 0
        errors = check_outputs(arguments.root)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        errors = [str(error)]
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1
    print("Generated Design System outputs are current")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
