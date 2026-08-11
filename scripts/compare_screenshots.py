#!/usr/bin/env python3
"""Compare current browser captures to the exact committed screenshot manifest."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def pixel_changed(baseline: tuple[int, ...], current: tuple[int, ...], tolerance: int) -> bool:
    return any(abs(before - after) > tolerance for before, after in zip(baseline, current))


def main() -> int:
    from PIL import Image, ImageChops

    manifest = json.loads((ROOT / "evidence" / "screenshots.json").read_text(encoding="utf-8"))
    threshold = int(manifest.get("pixelThreshold", 0))
    channel_tolerance = int(manifest.get("channelTolerance", 0))
    current_root = ROOT / "output" / "tmp" / "screenshots-current"
    baseline_root = ROOT / "output" / "screenshots"
    results = []
    failures = []
    for capture in manifest["captures"]:
        name = capture["name"]
        baseline_path = baseline_root / f"{name}.png"
        current_path = current_root / f"{name}.png"
        if not baseline_path.is_file() or not current_path.is_file():
            failures.append(f"{name}: missing baseline or current capture")
            continue
        with Image.open(baseline_path).convert("RGBA") as baseline, Image.open(current_path).convert("RGBA") as current:
            if baseline.size != current.size:
                failures.append(f"{name}: size changed from {baseline.size} to {current.size}")
                continue
            difference = ImageChops.difference(baseline, current).convert("RGB")
            lookup = [0 if value <= channel_tolerance else 255 for value in range(256)]
            changed_mask = difference.point(lookup * 3).convert("L")
            histogram = changed_mask.histogram()
            changed = baseline.width * baseline.height - histogram[0]
            results.append({"name": name, "changedPixels": changed, "totalPixels": baseline.width * baseline.height})
            if changed > threshold:
                failures.append(f"{name}: {changed} changed pixels exceeds threshold {threshold}")
    report = {
        "version": (ROOT / "VERSION").read_text(encoding="utf-8").strip(),
        "status": "failed" if failures else "passed",
        "pixelThreshold": threshold,
        "channelTolerance": channel_tolerance,
        "captures": results,
        "errors": failures,
    }
    report_path = ROOT / "output" / "reports" / "visual-diff.json"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    if failures:
        print("Visual regression failed:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1
    print(f"Exact visual regression passed for {len(results)} captures")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
