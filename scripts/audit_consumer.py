#!/usr/bin/env python3
"""Read-only QDS consumer doctor with machine-readable output."""

from __future__ import annotations

import argparse
import json
import re
import sys
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
    r"(?:\bAnimation\.[A-Za-z0-9_]+|\.(?:easeIn|easeOut|easeInOut|linear))"
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


def audit_consumer(consumer_root: Path, manifest_path: Path | None = None) -> dict[str, Any]:
    consumer_root = consumer_root.resolve()
    explicit_manifest = manifest_path is not None
    manifest_path = (manifest_path or consumer_root / "qds-consumer.json").resolve()
    errors: list[str] = []
    findings: list[dict[str, Any]] = []
    if not manifest_path.is_file() or (not explicit_manifest and not inside(manifest_path, consumer_root)):
        return {"status": "failed", "consumer": str(consumer_root), "errors": ["qds-consumer.json is missing; pass an external manifest for read-only assessment"], "findings": []}
    manifest = load_json(manifest_path)
    errors.extend(f"manifest:{error}" for error in schema_errors(manifest, "consumer-manifest.schema.json"))

    exceptions_path = (manifest_path.parent / manifest.get("exceptions", "qds-exceptions.json")).resolve()
    exceptions: dict[str, Any] = {"schemaVersion": 1, "exceptions": []}
    allowed_exception_root = manifest_path.parent if explicit_manifest else consumer_root
    if not inside(exceptions_path, allowed_exception_root) or not exceptions_path.is_file():
        errors.append("exceptions file is missing beside the manifest")
    else:
        exceptions = load_json(exceptions_path)
        errors.extend(f"exceptions:{error}" for error in schema_errors(exceptions, "consumer-exceptions.schema.json"))
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
        css_adapter = css_adapter or "@qenterra/design-tokens" in text or "qds-tokens.css" in text
        for line_number, line in enumerate(text.splitlines(), start=1):
            if (RAW_COLOR.search(line) or RAW_SWIFT_COLOR.search(line)) and ("raw-color", relative) not in allowed:
                findings.append({"rule": "raw-color", "path": relative, "line": line_number})
            if RAW_SWIFT_RADIUS.search(line) and ("raw-radius", relative) not in allowed:
                findings.append({"rule": "raw-radius", "path": relative, "line": line_number})
            if RAW_SWIFT_DURATION.search(line) and ("raw-duration", relative) not in allowed:
                findings.append({"rule": "raw-duration", "path": relative, "line": line_number})

    expected = manifest.get("adapters", {})
    if expected.get("swift") and not swift_adapter and ("missing-swift-adapter", "*") not in allowed:
        findings.append({"rule": "missing-swift-adapter", "path": "*"})
    if expected.get("css") and not css_adapter and ("missing-css-adapter", "*") not in allowed:
        findings.append({"rule": "missing-css-adapter", "path": "*"})

    status = "passed" if not errors and not findings else "failed"
    return {
        "status": status,
        "consumer": str(consumer_root),
        "product": manifest.get("product"),
        "filesScanned": len(set(files)),
        "adapters": {"swiftDetected": swift_adapter, "cssDetected": css_adapter},
        "errors": errors,
        "findings": findings,
        "exceptionsApplied": len(allowed),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Read-only QDS consumer doctor")
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
