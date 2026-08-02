#!/usr/bin/env python3
"""Validate the selected Nyx wallpaper exports without modifying them.

Run with a Python environment that provides Pillow:
    python3 scripts/brand/validate_nyx_wallpapers.py
    python3 scripts/brand/validate_nyx_wallpapers.py --dir /path/to/wallpapers
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


EXPECTED_SIZES = {
    "iPhone": (1284, 2778),
    "MacBook": (3024, 1964),
    "Chrome": (3024, 1964),
}
NAME_RE = re.compile(r"^(?P<label>[A-Z][A-Za-z0-9' -]+) \((?P<device>iPhone|MacBook|Chrome)\)\.png$")


def load_runtime() -> None:
    global Image
    try:
        from PIL import Image
    except ModuleNotFoundError as error:
        print(f"ERROR: Pillow is required ({error}).", file=sys.stderr)
        raise SystemExit(2)


def repository_root() -> Path:
    return Path(__file__).resolve().parents[2]


def default_wallpaper_dir() -> Path:
    return repository_root() / "assets" / "brand" / "nyx" / "wallpapers"


def validate_png(path: Path) -> tuple[str | None, list[str]]:
    match = NAME_RE.fullmatch(path.name)
    errors: list[str] = []
    if match is None:
        return None, [f"{path.name}: use 'Name (iPhone|MacBook|Chrome).png'"]
    device = match.group("device")
    try:
        image = Image.open(path)
        image.load()
    except (OSError, ValueError) as error:
        return device, [f"{path.name}: unreadable PNG: {error}"]
    if image.format != "PNG":
        errors.append(f"{path.name}: format is {image.format}, expected PNG")
    if image.mode != "RGBA":
        errors.append(f"{path.name}: mode is {image.mode}, expected RGBA")
    expected_size = EXPECTED_SIZES[device]
    if image.size != expected_size:
        errors.append(
            f"{path.name}: size is {image.width}×{image.height}, "
            f"expected {expected_size[0]}×{expected_size[1]}"
        )
        return device, errors

    rgba = image.convert("RGBA")
    alpha_range = rgba.getchannel("A").getextrema()
    if alpha_range != (255, 255):
        errors.append(f"{path.name}: wallpaper must be fully opaque, alpha range is {alpha_range}")
    width, height = rgba.size
    points = (
        (0, 0),
        (width - 1, 0),
        (0, height - 1),
        (width - 1, height - 1),
        (width // 2, 0),
        (0, height // 2),
        (width - 1, height // 2),
    )
    invalid = []
    for point in points:
        red, green, blue, alpha = rgba.getpixel(point)
        if alpha != 255 or max(red, green, blue) > 64 or max(red, green, blue) - min(red, green, blue) > 4:
            invalid.append((point, (red, green, blue, alpha)))
    if invalid:
        details = ", ".join(f"{point}={pixel}" for point, pixel in invalid)
        errors.append(f"{path.name}: edge samples must remain opaque dark neutral graphite; {details}")
    return device, errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dir", type=Path, default=default_wallpaper_dir())
    args = parser.parse_args()
    load_runtime()
    target = args.dir.expanduser().resolve()
    if not target.is_dir():
        print(f"ERROR: wallpaper directory not found: {target}", file=sys.stderr)
        return 1
    unexpected = sorted(path.name for path in target.iterdir() if not path.is_file() or path.suffix.lower() != ".png")
    wallpapers = sorted(target.glob("*.png"))
    errors = [f"unexpected wallpaper entry: {name}" for name in unexpected]
    counts = {device: 0 for device in EXPECTED_SIZES}
    if not wallpapers:
        errors.append("no PNG wallpapers found")
    for wallpaper in wallpapers:
        device, file_errors = validate_png(wallpaper)
        if device is not None:
            counts[device] += 1
        errors.extend(file_errors)
    if errors:
        print("Nyx wallpaper validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print(
        f"Nyx wallpaper validation passed: {len(wallpapers)} PNG "
        + ", ".join(f"{device}={count}" for device, count in counts.items())
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
