#!/usr/bin/env python3
"""Regenerate public npm and Swift adapters from versioned public inputs."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from lib.token_tools import (  # noqa: E402
    generate_css,
    generate_swift,
    generate_swift_icons,
    generate_swift_product_profiles,
    load_json,
)


TOKEN_NAMES = (
    "foundation",
    "semantic",
    "typography",
    "motion",
    "components",
    "platforms",
    "products",
)


def json_text(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, indent=2, sort_keys=False) + "\n"


def load_sources(root: Path = ROOT) -> tuple[dict[str, dict[str, Any]], dict[str, Any]]:
    source_root = root / "npm/design-tokens/src"
    tokens = load_json(source_root / "tokens.json")
    icons = load_json(source_root / "icons.json")
    if set(tokens) != set(TOKEN_NAMES):
        raise ValueError("src/tokens.json must contain the complete declared token set")
    package = load_json(root / "npm/design-tokens/package.json")
    version = package.get("version")
    if not isinstance(version, str) or not version:
        raise ValueError("npm/design-tokens/package.json has no valid version")
    for name in TOKEN_NAMES:
        token_file = tokens.get(name)
        if not isinstance(token_file, dict):
            raise ValueError(f"src/tokens.json entry {name!r} must be an object")
        if token_file.get("meta", {}).get("version") != version:
            raise ValueError(f"src/tokens.json entry {name!r} does not match package version")
    if not isinstance(icons, dict) or icons.get("version") != version:
        raise ValueError("src/icons.json does not match package version")
    return tokens, icons


def build_outputs(root: Path = ROOT) -> dict[str, str]:
    tokens, icons = load_sources(root)
    foundation = tokens["foundation"]
    return {
        "npm/design-tokens/dist/tokens.css": generate_css(
            foundation,
            tokens["semantic"],
            tokens["typography"],
            tokens["motion"],
            tokens["components"],
        ),
        "npm/design-tokens/dist/tokens.json": json_text(tokens),
        "npm/design-tokens/dist/icons.json": json_text(
            {
                "version": icons["version"],
                "platform": icons["platform"],
                "icons": icons["icons"],
            }
        ),
        "npm/design-tokens/dist/recipes.css": (
            root / "npm/design-tokens/src/recipes.css"
        ).read_text(encoding="utf-8"),
        "Sources/QenTerra/DesignTokens/GeneratedTokens.swift": generate_swift(
            foundation,
            tokens["semantic"],
            tokens["typography"],
            tokens["motion"],
            tokens["components"],
        ),
        "Sources/QenTerra/DesignTokens/GeneratedProductProfiles.swift": generate_swift_product_profiles(
            tokens["products"],
            tokens["platforms"],
            tokens["components"],
        ),
        "Sources/QenTerra/DesignTokens/GeneratedIcons.swift": generate_swift_icons(icons),
    }


def write_outputs(destination: Path, root: Path = ROOT) -> int:
    destination = destination.resolve()
    repository = root.resolve()
    if destination != repository and repository in destination.parents:
        raise ValueError("generated output destination must be the repository or outside it")
    changed = 0
    for relative, content in build_outputs(root).items():
        output = destination / relative
        previous = output.read_text(encoding="utf-8") if output.is_file() else None
        if previous == content:
            continue
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(content, encoding="utf-8")
        changed += 1
    return changed


def check_outputs(root: Path = ROOT) -> list[str]:
    errors: list[str] = []
    for relative, expected in build_outputs(root).items():
        output = root / relative
        if not output.is_file():
            errors.append(f"missing generated output: {relative}")
        elif output.read_text(encoding="utf-8") != expected:
            errors.append(f"stale generated output: {relative}")
    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", nargs="?", choices=("check", "write", "export"), default="check")
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--destination", type=Path)
    arguments = parser.parse_args(argv)
    try:
        if arguments.command == "write":
            changed = write_outputs(arguments.root, arguments.root)
            print(f"Generated public package outputs ({changed} changed)")
            return 0
        if arguments.command == "export":
            if arguments.destination is None:
                parser.error("export requires --destination")
            destination = arguments.destination.resolve()
            repository = arguments.root.resolve()
            if destination == repository or repository in destination.parents:
                raise ValueError("export destination must be outside the repository")
            if destination.exists() and any(destination.iterdir()):
                raise ValueError("export destination must be empty")
            destination.mkdir(parents=True, exist_ok=True)
            changed = write_outputs(destination, arguments.root)
            print(f"Exported {changed} generated outputs to {destination}")
            return 0
        errors = check_outputs(arguments.root)
    except (OSError, ValueError, json.JSONDecodeError, KeyError) as error:
        errors = [str(error)]
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1
    print("Public package generated outputs are current")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
