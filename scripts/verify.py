#!/usr/bin/env python3
"""Run the full local verification gate and write deterministic evidence."""

from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GENERATED_TARGETS = [
    ROOT / "generated" / "qds-tokens.css",
    ROOT / "generated" / "QDSGeneratedTokens.swift",
    ROOT / "generated" / "TOKEN_REFERENCE.md",
    ROOT / "dist" / "index.html",
    ROOT / "dist" / "qenterra-design-system.html",
    ROOT / "dist" / "en" / "index.html",
    ROOT / "dist" / "ru" / "index.html",
    ROOT / "dist" / "en" / "qenterra-design-system.html",
    ROOT / "dist" / "ru" / "qenterra-design-system.html",
    ROOT / "dist" / "assets" / "search-index-en.json",
    ROOT / "dist" / "assets" / "search-index-ru.json",
]


def run(command: list[str], *, env: dict[str, str] | None = None) -> None:
    print("+", " ".join(command))
    subprocess.run(command, cwd=ROOT, env=env, check=True)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    python = sys.executable
    version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
    environment = os.environ.copy()
    with tempfile.TemporaryDirectory(prefix="qds-pycache-") as cache:
        environment["PYTHONPYCACHEPREFIX"] = cache
        run(
            [
                python,
                "-m",
                "py_compile",
                "scripts/build.py",
                "scripts/validate.py",
                "scripts/verify.py",
                "scripts/lib/markdown_renderer.py",
                "scripts/lib/site_locales.py",
                "scripts/lib/token_tools.py",
                "tests/test_validator.py",
            ],
            env=environment,
        )

    run([python, "scripts/build.py"])
    first = {str(path.relative_to(ROOT)): digest(path) for path in GENERATED_TARGETS}
    run([python, "scripts/build.py"])
    second = {str(path.relative_to(ROOT)): digest(path) for path in GENERATED_TARGETS}
    if first != second:
        raise RuntimeError("Build is not deterministic")

    run([python, "-m", "unittest", "discover", "-s", "tests", "-v"])
    run([python, "scripts/validate.py"])

    node = os.environ.get("QDS_NODE") or shutil.which("node")
    if not node:
        raise RuntimeError("Node.js is required for JavaScript syntax validation; set QDS_NODE")
    run([node, "--check", "src/assets/app.js"])
    run([node, "--check", "scripts/render_screenshots.js"])
    run(["git", "diff", "--check"])
    run(["git", "diff", "--cached", "--check"])

    report = {
        "version": version,
        "status": "passed",
        "checks": {
            "pythonSyntax": "passed",
            "deterministicBuild": "passed",
            "negativeTests": "passed",
            "tokensLinksContrastPlaceholders": "passed",
            "javascriptSyntax": "passed",
            "gitWhitespace": "passed"
        },
        "generatedSha256": second,
        "manualNotProven": [
            "native application rendering",
            "VoiceOver and screen-reader output",
            "production app migration",
            "live Obsidian rendering"
        ]
    }
    report_path = ROOT / "output" / "reports" / "verification.json"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Verification passed for QenTerra Design System {version}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f"Verification failed: {error}", file=sys.stderr)
        raise SystemExit(1)
