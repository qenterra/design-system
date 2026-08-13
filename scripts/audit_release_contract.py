#!/usr/bin/env python3
"""Read-only validator for product release versions and macOS artifacts."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from lib.schema_tools import validate_schema  # noqa: E402
from lib.token_tools import load_json  # noqa: E402


def inside(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
        return True
    except ValueError:
        return False


def expected_version(release: dict[str, Any]) -> str | None:
    marketing = release.get("marketingVersion")
    channel = release.get("channel")
    iteration = release.get("iteration")
    if not isinstance(marketing, str) or not isinstance(channel, str):
        return None
    if channel == "stable":
        return marketing
    if not isinstance(iteration, int) or isinstance(iteration, bool) or iteration < 1:
        return None
    return f"{marketing}-{channel}.{iteration}"


def expected_human_name(product: dict[str, Any], release: dict[str, Any]) -> str | None:
    name = product.get("name")
    marketing = release.get("marketingVersion")
    build = release.get("build")
    channel = release.get("channel")
    iteration = release.get("iteration")
    if not isinstance(name, str) or not isinstance(marketing, str) or not isinstance(build, int):
        return None
    if channel == "stable":
        return f"{name} {marketing} ({build})"
    labels = {"alpha": "Alpha", "beta": "Beta", "rc": "RC"}
    label = labels.get(channel)
    if label is None or not isinstance(iteration, int):
        return None
    return f"{name} {marketing} {label} {iteration} ({build})"


def semantic_errors(data: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    product = data.get("product", {})
    release = data.get("release", {})
    platform = data.get("platform", {})
    distribution = data.get("distribution", {})
    installer = data.get("installer", {})
    artifacts = data.get("artifacts", {})

    build = release.get("build")
    if not isinstance(build, int) or isinstance(build, bool) or build < 1:
        errors.append("release.build must be a positive decimal integer")

    channel = release.get("channel")
    iteration = release.get("iteration")
    if channel == "stable" and "iteration" in release:
        errors.append("release.iteration must be absent for stable releases")
    if channel in {"alpha", "beta", "rc"} and (
        not isinstance(iteration, int) or isinstance(iteration, bool) or iteration < 1
    ):
        errors.append("release.iteration must be positive for prereleases")

    version = expected_version(release)
    if version is not None and release.get("version") != version:
        errors.append(f"release.version must be {version!r}")
    if version is not None and release.get("tag") != f"v{version}":
        errors.append(f"release.tag must be {f'v{version}'!r}")

    human_name = expected_human_name(product, release)
    if human_name is not None and product.get("humanReleaseName") != human_name:
        errors.append(f"product.humanReleaseName must be {human_name!r}")

    if version is not None:
        stem = product.get("artifactStem")
        architecture = platform.get("architecture")
        if isinstance(stem, str) and isinstance(architecture, str):
            expected_artifacts = {
                "installer": f"{stem}-{version}-{architecture}.dmg",
                "update": f"{stem}-{version}-{architecture}.zip",
                "checksums": f"{stem}-{version}-SHA256SUMS.txt",
            }
            for key, expected in expected_artifacts.items():
                if artifacts.get(key) != expected:
                    errors.append(f"artifacts.{key} must be {expected!r}")

    if installer.get("format") == "dmg" and installer.get("applicationsAlias") is not True:
        errors.append("installer.applicationsAlias must be true for DMG releases")

    if distribution.get("signing") == "ad-hoc":
        if distribution.get("notarized") is not False:
            errors.append("ad-hoc signing cannot claim notarization")
        if distribution.get("gatekeeperDisclosure") is not True:
            errors.append("ad-hoc signing requires Gatekeeper disclosure")
    elif distribution.get("notarized") is False and distribution.get("gatekeeperDisclosure") is not True:
        errors.append("unnotarized direct distribution requires Gatekeeper disclosure")

    return errors


def audit_release_contract(product_root: Path, manifest_path: Path | None = None) -> dict[str, Any]:
    product_root = product_root.resolve()
    explicit_manifest = manifest_path is not None
    manifest_path = (manifest_path or product_root / "qds-release.json").resolve()
    if not manifest_path.is_file() or (not explicit_manifest and not inside(manifest_path, product_root)):
        return {
            "status": "failed",
            "productRoot": str(product_root),
            "errors": ["qds-release.json is missing; pass an external manifest for read-only assessment"],
        }

    data = load_json(manifest_path)
    schema_path = ROOT / "schemas" / "product-release.schema.json"
    schema = load_json(schema_path)
    errors = [f"manifest:{error}" for error in validate_schema(data, schema, schema_path)]
    errors.extend(semantic_errors(data))
    release = data.get("release", {})
    return {
        "status": "passed" if not errors else "failed",
        "productRoot": str(product_root),
        "product": data.get("product", {}).get("name"),
        "version": release.get("version"),
        "tag": release.get("tag"),
        "errors": errors,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Read-only QDS product release contract auditor")
    parser.add_argument("product", type=Path)
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    product = args.product.resolve()
    report = audit_release_contract(product, args.manifest)
    payload = json.dumps(report, indent=2, ensure_ascii=False) + "\n"
    if args.output:
        output = args.output.resolve()
        if inside(output, product):
            parser.error("--output must stay outside the product to preserve read-only auditing")
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(payload, encoding="utf-8")
    else:
        print(payload, end="")
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    raise SystemExit(main())
