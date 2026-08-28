#!/usr/bin/env python3
"""Reject legacy active names while preserving explicit historical records."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TEXT_SUFFIXES = {".css", ".html", ".js", ".json", ".md", ".mjs", ".py", ".swift", ".toml", ".txt", ".yml", ".yaml"}
IGNORED_PARTS = {".build", ".git", ".swiftpm", ".venv", "node_modules"}
EXPLICIT_ALLOW = {
    "CHANGELOG.md",
    "scripts/verify_public_boundary.py",
    "scripts/verify_terminology.py",
}
PATTERNS = (
    (re.compile(r"\bQDS\b"), "QDS"),
    (re.compile(r"\bqds(?=[-_.])"), "qds"),
    (re.compile(r"\bDesignSystem\b"), "DesignSystem"),
)


def is_allowed(relative: Path) -> bool:
    value = relative.as_posix()
    if value in EXPLICIT_ALLOW:
        return True
    if relative.parts[:2] == ("docs", "decisions"):
        return True
    if relative.parts and relative.parts[0] == "tests" and len(relative.parts) == 2:
        return True
    return False


def validate_terminology(root: Path = ROOT) -> list[str]:
    errors: list[str] = []
    for path in sorted(root.rglob("*")):
        if not path.is_file() or path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        relative = path.relative_to(root)
        if IGNORED_PARTS.intersection(relative.parts) or is_allowed(relative):
            continue
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except UnicodeDecodeError:
            continue
        for line_number, line in enumerate(lines, start=1):
            for pattern, label in PATTERNS:
                if pattern.search(line):
                    errors.append(f"{relative.as_posix()}:{line_number}: legacy term {label!r}")
    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    arguments = parser.parse_args(argv)
    errors = validate_terminology(arguments.root)
    if errors:
        print("Terminology validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print("Terminology validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
