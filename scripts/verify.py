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
    ROOT / "generated" / "QDSGeneratedIcons.swift",
    ROOT / "generated" / "qds-icons.svg",
    ROOT / "generated" / "figma" / "variables.json",
    ROOT / "generated" / "figma" / "styles.json",
    ROOT / "generated" / "figma" / "components.json",
    ROOT / "generated" / "figma" / "icons.json",
    ROOT / "generated" / "TOKEN_REFERENCE.md",
    ROOT / "packages" / "swift" / "Sources" / "QenTerraDesignTokens" / "QDSGeneratedTokens.swift",
    ROOT / "packages" / "swift" / "Sources" / "QenTerraDesignTokens" / "QDSGeneratedIcons.swift",
    ROOT / "packages" / "css" / "tokens.css",
    ROOT / "packages" / "css" / "tokens.json",
    ROOT / "packages" / "css" / "icons.json",
    ROOT / "packages" / "css" / "recipes.css",
    ROOT / "dist" / "index.html",
    ROOT / "dist" / "qenterra-design-system.html",
    ROOT / "dist" / "en" / "index.html",
    ROOT / "dist" / "ru" / "index.html",
    ROOT / "dist" / "en" / "pages" / "brand.html",
    ROOT / "dist" / "ru" / "pages" / "brand.html",
    ROOT / "dist" / "en" / "pages" / "email.html",
    ROOT / "dist" / "ru" / "pages" / "email.html",
    ROOT / "dist" / "pages" / "email.html",
    ROOT / "dist" / "en" / "qenterra-design-system.html",
    ROOT / "dist" / "ru" / "qenterra-design-system.html",
    ROOT / "dist" / "assets" / "search-index-en.json",
    ROOT / "dist" / "assets" / "search-index-ru.json",
    ROOT / "dist" / "assets" / "qds-recipes.css",
    ROOT / "dist" / "assets" / "qds-icons.svg",
    ROOT / "dist" / "assets" / "email-renderer.js",
    ROOT / "dist" / "assets" / "email-composer.js",
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
                "scripts/lib/schema_tools.py",
                "scripts/lib/pseudo_locales.py",
                "scripts/lib/figma_export.py",
                "scripts/lib/email_templates.py",
                "scripts/compare_screenshots.py",
                "scripts/audit_consumer.py",
                "scripts/brand/validate_brand_assets.py",
                "scripts/brand/validate_nyx_assets.py",
                "scripts/brand/validate_nyx_wallpapers.py",
                "scripts/brand/validate_telegram_stickers.py",
                "scripts/brand/build_nyx_asset_contacts.py",
                "scripts/brand/process_nyx_asset.py",
                "scripts/brand/build_asset_browser.py",
                "tests/test_brand_assets.py",
                "tests/test_validator.py",
                "tests/test_consumer_doctor.py",
                "tests/test_brand_browser.py",
                "tests/test_email_templates.py",
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
    run([python, "scripts/audit_consumer.py", "tests/fixtures/consumer-pass"])
    run([python, "scripts/validate.py"])
    run([python, "scripts/brand/validate_brand_assets.py", "--check-git-lfs"])
    run([python, "scripts/brand/validate_telegram_stickers.py"])
    image_python = os.environ.get("QDS_IMAGE_PYTHON") or python
    run([image_python, "-c", "import PIL, numpy"])
    run([image_python, "scripts/brand/validate_nyx_wallpapers.py"])
    with tempfile.TemporaryDirectory(prefix="qds-swift-") as swift_cache:
        swift_environment = environment.copy()
        swift_environment["CLANG_MODULE_CACHE_PATH"] = str(Path(swift_cache) / "clang-modules")
        swift_environment["SWIFTPM_MODULECACHE_OVERRIDE"] = str(Path(swift_cache) / "swift-modules")
        swift_base = [
            "--package-path",
            "packages/swift",
            "--scratch-path",
            str(Path(swift_cache) / "build"),
            "--disable-sandbox",
        ]
        run(["swift", "build", *swift_base], env=swift_environment)
        run(["swift", "run", *swift_base, "QDSContractCheck"], env=swift_environment)

    node = os.environ.get("QDS_NODE") or shutil.which("node")
    if not node:
        raise RuntimeError("Node.js is required for JavaScript and browser validation; set QDS_NODE")
    run([node, "-e", 'require("playwright")'])
    run([node, "--check", "src/assets/app.js"])
    run([node, "--check", "src/assets/email-renderer.js"])
    run([node, "--check", "src/assets/email-composer.js"])
    run([node, "tests/email_renderer.test.js"])
    run([node, "--check", "scripts/render_screenshots.js"])
    run([node, "scripts/render_screenshots.js"])
    run([image_python, "scripts/compare_screenshots.py"])
    run([python, "scripts/validate.py"])
    run(["git", "diff", "--check"])
    run(["git", "diff", "--cached", "--check"])

    report = {
        "version": version,
        "status": "passed",
        "checks": {
            "pythonSyntax": "passed",
            "deterministicBuild": "passed",
            "negativeTests": "passed",
            "brandManifestAndLfs": "passed",
            "telegramStickerPack": "passed",
            "wallpaperProfile": "passed",
            "tokensLinksContrastPlaceholders": "passed",
            "swiftPackageBuildAndContract": "passed",
            "javascriptSyntax": "passed",
            "browserInteractionAndRendering": "passed",
            "exactPixelComparison": "passed",
            "gitWhitespace": "passed"
        },
        "generatedSha256": second,
        "manualNotProven": [
            "Swift package test-target execution without a complete Xcode test runtime",
            "native application rendering",
            "VoiceOver and screen-reader output",
            "production app migration",
            "live Obsidian rendering",
            "deep Nyx pixel/silhouette QA unless run separately with validate_nyx_assets.py",
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
