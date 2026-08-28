#!/usr/bin/env python3
"""Read-only Design System consumer audit with machine-readable output."""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import date
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from lib.schema_tools import validate_schema  # noqa: E402
from lib.token_tools import load_json  # noqa: E402


SOURCE_SUFFIXES = {".swift", ".css", ".scss", ".js", ".jsx", ".ts", ".tsx", ".html"}
RAW_COLOR = re.compile(r"(?<![A-Za-z0-9])#[0-9A-Fa-f]{3}(?:[0-9A-Fa-f]{3})?\b")
RAW_SWIFT_COLOR = re.compile(
    r"\b(?:Color|NSColor)\s*\(\s*(?:red|calibratedRed|deviceRed)\s*:|"
    r"\b(?:calibratedRed|deviceRed)\s*:"
)
RAW_SWIFT_RADIUS = re.compile(r"\bcornerRadius\s*:\s*(?:\d+(?:\.\d+)?|\.\d+)")
RAW_SWIFT_DURATION = re.compile(
    r"(?:\bAnimation\.[A-Za-z0-9_]+|\.(?:easeIn|easeOut|easeInOut|linear|smooth))"
    r"\s*\([^)]*\bduration\s*:\s*(?:\d+(?:\.\d+)?|\.\d+)"
)


def schema_errors(data: dict[str, Any], name: str) -> list[str]:
    schema_path = ROOT / "schemas" / name
    return validate_schema(data, load_json(schema_path), schema_path)


def inside(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
        return True
    except ValueError:
        return False


def exception_review_errors(exceptions: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    today = date.today()
    for item in exceptions.get("exceptions", []):
        identifier = item.get("id", "unknown")
        review_by = item.get("reviewBy")
        if not isinstance(review_by, str):
            continue
        try:
            review_date = date.fromisoformat(review_by)
        except ValueError:
            errors.append(f"exception:{identifier} has an invalid reviewBy date")
            continue
        if review_date < today:
            errors.append(
                f"exception:{identifier} reviewBy {review_by} has expired"
            )
    return errors


def package_contract_errors(manifest: dict[str, Any]) -> list[str]:
    registry = load_json(ROOT / "registry/packages.json")
    registered = {item["id"]: item for item in registry.get("packages", [])}
    errors: list[str] = []
    capabilities: set[str] = set()
    for package in manifest.get("packages", []):
        identifier = package.get("id")
        if identifier not in registered:
            errors.append(f"unknown package id {identifier!r}")
            continue
        expected = registered[identifier]
        if package.get("version") != expected.get("version"):
            errors.append(
                f"package {identifier!r} version {package.get('version')!r} "
                f"!= {expected.get('version')!r}"
            )
        capabilities.update(expected.get("capabilities", []))
    unknown = sorted(set(manifest.get("adoptedCapabilities", [])) - capabilities)
    if unknown:
        errors.append(f"unavailable adopted capabilities: {unknown}")
    return errors


def audit_consumer(consumer_root: Path, manifest_path: Path | None = None) -> dict[str, Any]:
    consumer_root = consumer_root.resolve()
    explicit_manifest = manifest_path is not None
    manifest_path = (manifest_path or consumer_root / "design-system-consumer.json").resolve()
    errors: list[str] = []
    findings: list[dict[str, Any]] = []
    if not manifest_path.is_file() or (not explicit_manifest and not inside(manifest_path, consumer_root)):
        return {"status": "failed", "consumer": str(consumer_root), "errors": ["design-system-consumer.json is missing; pass an external manifest for read-only assessment"], "findings": []}
    manifest = load_json(manifest_path)
    errors.extend(f"manifest:{error}" for error in schema_errors(manifest, "design-system-consumer.schema.json"))
    errors.extend(f"manifest:{error}" for error in package_contract_errors(manifest))

    exceptions_path = (manifest_path.parent / manifest.get("exceptions", "design-system-exceptions.json")).resolve()
    exceptions: dict[str, Any] = {"schemaVersion": 2, "exceptions": []}
    allowed_exception_root = manifest_path.parent if explicit_manifest else consumer_root
    if not inside(exceptions_path, allowed_exception_root) or not exceptions_path.is_file():
        errors.append("exceptions file is missing beside the manifest")
    else:
        exceptions = load_json(exceptions_path)
        errors.extend(f"exceptions:{error}" for error in schema_errors(exceptions, "design-system-exceptions.schema.json"))
        errors.extend(exception_review_errors(exceptions))
    allowed = {(item.get("rule"), item.get("path")) for item in exceptions.get("exceptions", [])}

    files: list[Path] = []
    for source_root in manifest.get("sourceRoots", []):
        target = (consumer_root / source_root).resolve()
        if not inside(target, consumer_root) or not target.exists():
            errors.append(f"source root is missing or escapes consumer: {source_root}")
            continue
        files.extend(path for path in target.rglob("*") if path.is_file() and path.suffix.lower() in SOURCE_SUFFIXES)

    swift_adapter = False
    css_adapter = False
    for path in sorted(set(files)):
        relative = path.relative_to(consumer_root).as_posix()
        text = path.read_text(encoding="utf-8", errors="replace")
        swift_adapter = swift_adapter or "import QenTerraDesignTokens" in text
        css_adapter = css_adapter or "@qenterra/design-tokens" in text or "--design-system-" in text
        for line_number, line in enumerate(text.splitlines(), start=1):
            if (RAW_COLOR.search(line) or RAW_SWIFT_COLOR.search(line)) and ("raw-color", relative) not in allowed:
                findings.append({"rule": "raw-color", "path": relative, "line": line_number})
            if RAW_SWIFT_RADIUS.search(line) and ("raw-radius", relative) not in allowed:
                findings.append({"rule": "raw-radius", "path": relative, "line": line_number})
            if RAW_SWIFT_DURATION.search(line) and ("raw-duration", relative) not in allowed:
                findings.append({"rule": "raw-duration", "path": relative, "line": line_number})

    package_ids = {item.get("id") for item in manifest.get("packages", [])}
    if "swift-components" in package_ids and not swift_adapter and ("missing-swift-adapter", "*") not in allowed:
        findings.append({"rule": "missing-swift-adapter", "path": "*"})
    if "npm-design-tokens" in package_ids and not css_adapter and ("missing-css-adapter", "*") not in allowed:
        findings.append({"rule": "missing-css-adapter", "path": "*"})
    if any(item.get("source") == "local" for item in manifest.get("packages", [])) and ("local-package-source", "*") not in allowed:
        findings.append({"rule": "local-package-source", "path": "*"})

    status = "passed" if not errors and not findings else "failed"
    return {
        "status": status,
        "consumer": str(consumer_root),
        "consumerName": manifest.get("consumer"),
        "filesScanned": len(set(files)),
        "adapters": {"swiftDetected": swift_adapter, "cssDetected": css_adapter},
        "errors": errors,
        "findings": findings,
        "exceptionsApplied": len(allowed),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Read-only Design System consumer audit")
    parser.add_argument("consumer", type=Path)
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    consumer = args.consumer.resolve()
    report = audit_consumer(consumer, args.manifest)
    payload = json.dumps(report, indent=2, ensure_ascii=False) + "\n"
    if args.output:
        output = args.output.resolve()
        if inside(output, consumer):
            parser.error("--output must stay outside the consumer to preserve read-only auditing")
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(payload, encoding="utf-8")
    else:
        print(payload, end="")
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    raise SystemExit(main())
