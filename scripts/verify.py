#!/usr/bin/env python3
"""Run the complete private Design System verification gate."""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TESTING_MACROS_RELATIVE_PATH = Path(
    "Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib"
)


def run(
    command: list[str],
    *,
    env: dict[str, str] | None = None,
    cwd: Path = ROOT,
) -> None:
    print("+", " ".join(command))
    subprocess.run(command, cwd=cwd, env=env, check=True)


def require_swift_testing_macros(developer_dir: Path) -> None:
    """Fail before SwiftPM work when the selected developer directory is incomplete."""
    macro = developer_dir / TESTING_MACROS_RELATIVE_PATH
    if not macro.is_file():
        raise RuntimeError(
            "Swift package tests require full Xcode with TestingMacros; "
            "set DEVELOPER_DIR to Xcode.app/Contents/Developer "
            f"(current: {developer_dir})"
        )


def python_sources() -> list[str]:
    paths: list[str] = []
    for parent in (ROOT / "scripts", ROOT / "tests"):
        for path in parent.rglob("*.py"):
            if {".build", ".swiftpm", "__pycache__"}.intersection(path.parts):
                continue
            paths.append(path.relative_to(ROOT).as_posix())
    return sorted(paths)


def main() -> int:
    python = sys.executable
    environment = os.environ.copy()
    developer_dir_value = environment.get("DEVELOPER_DIR")
    if not developer_dir_value:
        developer_dir_value = subprocess.run(
            ["xcode-select", "--print-path"],
            capture_output=True,
            text=True,
            check=True,
        ).stdout.strip()
    require_swift_testing_macros(Path(developer_dir_value))

    with tempfile.TemporaryDirectory(prefix="design-system-pycache-") as cache:
        environment["PYTHONPYCACHEPREFIX"] = cache
        run([python, "-m", "py_compile", *python_sources()], env=environment)

    run([python, "scripts/generate.py", "check"])
    run([python, "scripts/build_public_packages.py", "check"])
    run([python, "scripts/verify_public_boundary.py"])
    run([python, "scripts/verify_terminology.py"])
    run([python, "-m", "unittest", "discover", "-s", "tests", "-v"])
    run([python, "scripts/audit_consumer.py", "tests/fixtures/consumer-pass"])
    run([python, "scripts/audit_release_contract.py", "tests/fixtures/release-contract-pass"])
    run([python, "scripts/brand/validate_brand_assets.py", "--check-git-lfs"])
    run([python, "scripts/brand/validate_telegram_stickers.py"])

    image_python = environment.get("DESIGN_SYSTEM_IMAGE_PYTHON") or python
    run([image_python, "-c", "import PIL, numpy"])
    run([image_python, "scripts/brand/validate_nyx_wallpapers.py"])

    with tempfile.TemporaryDirectory(prefix="design-system-swift-") as swift_cache:
        swift_environment = environment.copy()
        swift_environment["CLANG_MODULE_CACHE_PATH"] = str(Path(swift_cache) / "clang-modules")
        swift_environment["SWIFTPM_MODULECACHE_OVERRIDE"] = str(Path(swift_cache) / "swift-modules")
        run(
            [
                "swift",
                "test",
                "--package-path",
                "packages",
                "--scratch-path",
                str(Path(swift_cache) / "build"),
                "--disable-sandbox",
            ],
            env=swift_environment,
        )

    node = environment.get("DESIGN_SYSTEM_NODE") or shutil.which("node")
    if not node:
        raise RuntimeError("Node.js is required for npm package validation")
    run([node, "tests/package-css-smoke.mjs", "packages/npm/design-tokens"])
    with tempfile.TemporaryDirectory(prefix="design-system-npm-pack-") as npm_cache:
        run(
            [
                "npm",
                "pack",
                "--workspace",
                "@qenterra/design-tokens",
                "--dry-run",
                "--json",
                "--cache",
                npm_cache,
            ]
        )

    run(["git", "diff", "--check"])
    run(["git", "diff", "--cached", "--check"])
    version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
    print(f"Verification passed for Design System {version}")
    print("Manual runtime, native rendering, VoiceOver, and visual acceptance remain unproven.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f"Verification failed: {error}", file=sys.stderr)
        raise SystemExit(1)
