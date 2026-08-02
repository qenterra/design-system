#!/usr/bin/env python3
"""Build and validate the canonical QenTerra brand asset manifest."""

from __future__ import annotations

import argparse
import hashlib
import json
import mimetypes
import struct
import subprocess
import sys
from pathlib import Path, PurePosixPath
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
BRAND_ROOT = Path("assets/brand")
MANIFEST_PATH = BRAND_ROOT / "manifest.json"
LFS_RULE = "assets/brand/**/*.png filter=lfs diff=lfs merge=lfs -text"

MAPPINGS: tuple[tuple[tuple[str, ...], tuple[str, ...], str], ...] = (
    (("Баннеры (плоские)", "Raster"), ("qenterra", "banners", "raster"), "qenterra.banner.raster"),
    (("Баннеры (плоские)", "Vector"), ("qenterra", "banners", "vector"), "qenterra.banner.vector"),
    (("Логотипы (плоские)", "Raster"), ("qenterra", "logos", "raster"), "qenterra.logo.raster"),
    (("Логотипы (плоские)", "Vector"), ("qenterra", "logos", "vector"), "qenterra.logo.vector"),
    (("Маскот (Nyx)", "Assets", "Compositions"), ("nyx", "character-assets", "compositions"), "nyx.character.composition"),
    (("Маскот (Nyx)", "Assets", "Decorative"), ("nyx", "character-assets", "decorative"), "nyx.character.decorative"),
    (("Маскот (Nyx)", "Assets", "Full Body"), ("nyx", "character-assets", "full-body"), "nyx.character.full-body"),
    (("Маскот (Nyx)", "Assets", "Portraits"), ("nyx", "character-assets", "portraits"), "nyx.character.portrait"),
    (("Маскот (Nyx)", "ChatGPT Pet"), ("nyx", "chatgpt-pet"), "nyx.pet"),
    (("Маскот (Nyx)", "Telegram Stickers"), ("nyx", "telegram-stickers"), "nyx.telegram-sticker"),
    (("Маскот (Nyx)", "Wallpapers"), ("nyx", "wallpapers"), "nyx.wallpaper"),
)

PNG_MODES = {
    0: "grayscale",
    2: "rgb",
    3: "indexed",
    4: "grayscale-alpha",
    6: "rgba",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def png_metadata(path: Path) -> dict[str, int | str]:
    header = path.read_bytes()[:33]
    if len(header) < 33 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise ValueError("invalid PNG signature or IHDR")
    width, height, bit_depth, color_type, compression, filtering, interlace = struct.unpack(
        ">IIBBBBB", header[16:29]
    )
    if compression != 0 or filtering != 0 or interlace not in {0, 1}:
        raise ValueError("unsupported PNG header")
    mode = PNG_MODES.get(color_type)
    if mode is None:
        raise ValueError(f"unsupported PNG color type {color_type}")
    return {"width": width, "height": height, "mode": mode, "bitDepth": bit_depth}


def canonical_path_for(source_relative: str) -> tuple[str, str]:
    parts = PurePosixPath(source_relative).parts
    for source_prefix, target_prefix, category in MAPPINGS:
        if parts[: len(source_prefix)] == source_prefix:
            suffix = parts[len(source_prefix) :]
            if not suffix:
                break
            target = PurePosixPath(BRAND_ROOT.as_posix(), *target_prefix, *suffix)
            return target.as_posix(), category
    raise ValueError(f"unmapped brandbook path: {source_relative}")


def record_for(source: Path, source_relative: str, canonical: Path, canonical_relative: str, category: str) -> dict[str, Any]:
    source_hash = sha256(source)
    canonical_hash = sha256(canonical)
    if source_hash != canonical_hash:
        raise ValueError(f"copy hash mismatch: {source_relative} -> {canonical_relative}")
    extension = canonical.suffix.lower()
    record: dict[str, Any] = {
        "sourcePath": source_relative,
        "canonicalPath": canonical_relative,
        "category": category,
        "extension": extension,
        "mimeType": mimetypes.guess_type(canonical.name)[0] or "application/octet-stream",
        "bytes": canonical.stat().st_size,
        "sha256": canonical_hash,
        "lfs": extension == ".png",
    }
    if extension == ".png":
        record.update(png_metadata(canonical))
    return record


def build_manifest(source_root: Path, root: Path = ROOT) -> dict[str, Any]:
    assets: list[dict[str, Any]] = []
    for source in sorted(source_root.rglob("*")):
        if not source.is_file() or source.name == ".DS_Store":
            continue
        source_relative = source.relative_to(source_root).as_posix()
        canonical_relative, category = canonical_path_for(source_relative)
        canonical = root / canonical_relative
        if not canonical.is_file():
            raise ValueError(f"missing canonical copy: {canonical_relative}")
        assets.append(record_for(source, source_relative, canonical, canonical_relative, category))
    assets.sort(key=lambda item: item["canonicalPath"])
    return {
        "schemaVersion": 1,
        "sourceLabel": "Мой брендбук",
        "assetCount": len(assets),
        "totalBytes": sum(item["bytes"] for item in assets),
        "assets": assets,
    }


def lfs_paths(root: Path) -> set[str]:
    result = subprocess.run(
        ["git", "lfs", "ls-files", "--name-only"],
        cwd=root,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "git lfs ls-files failed")
    return {line.strip() for line in result.stdout.splitlines() if line.strip()}


def validate_brand_assets(root: Path = ROOT, *, check_git_lfs: bool = False) -> list[str]:
    errors: list[str] = []
    brand_root = root / BRAND_ROOT
    manifest_path = root / MANIFEST_PATH
    if not manifest_path.is_file():
        return [f"{MANIFEST_PATH}: missing brand manifest"]
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        return [f"{MANIFEST_PATH}: invalid JSON: {error}"]
    if manifest.get("schemaVersion") != 1:
        errors.append(f"{MANIFEST_PATH}: schemaVersion must be 1")
    records = manifest.get("assets")
    if not isinstance(records, list):
        return [*errors, f"{MANIFEST_PATH}: assets must be an array"]

    actual_paths: set[str] = set()
    for path in brand_root.rglob("*"):
        if not path.is_file() or path == manifest_path:
            continue
        relative = path.relative_to(root).as_posix()
        if path.name == ".DS_Store":
            errors.append(f"{relative}: forbidden file")
            continue
        actual_paths.add(relative)

    canonical_paths: list[str] = []
    source_paths: list[str] = []
    total_bytes = 0
    expected_lfs: set[str] = set()
    required = {"sourcePath", "canonicalPath", "category", "extension", "mimeType", "bytes", "sha256", "lfs"}
    for index, record in enumerate(records):
        label = f"{MANIFEST_PATH}:assets[{index}]"
        if not isinstance(record, dict):
            errors.append(f"{label}: record must be an object")
            continue
        missing = sorted(required - record.keys())
        if missing:
            errors.append(f"{label}: missing fields {missing}")
            continue
        source_paths.append(str(record["sourcePath"]))
        canonical_relative = str(record["canonicalPath"])
        canonical_paths.append(canonical_relative)
        path = root / canonical_relative
        if not canonical_relative.startswith(f"{BRAND_ROOT.as_posix()}/"):
            errors.append(f"{label}: canonicalPath must stay under {BRAND_ROOT}")
            continue
        if not path.is_file():
            errors.append(f"{canonical_relative}: missing canonical asset")
            continue
        actual_size = path.stat().st_size
        total_bytes += actual_size
        if record["bytes"] != actual_size:
            errors.append(f"{canonical_relative}: byte-size drift")
        actual_hash = sha256(path)
        if record["sha256"] != actual_hash:
            errors.append(f"{canonical_relative}: SHA-256 drift")
        extension = path.suffix.lower()
        if record["extension"] != extension:
            errors.append(f"{canonical_relative}: extension metadata drift")
        expects_lfs = extension == ".png"
        if record["lfs"] is not expects_lfs:
            errors.append(f"{canonical_relative}: lfs must be {expects_lfs}")
        if expects_lfs:
            expected_lfs.add(canonical_relative)
            try:
                metadata = png_metadata(path)
            except ValueError as error:
                errors.append(f"{canonical_relative}: {error}")
            else:
                for key, value in metadata.items():
                    if record.get(key) != value:
                        errors.append(f"{canonical_relative}: {key} metadata drift")

    duplicate_canonical = sorted({path for path in canonical_paths if canonical_paths.count(path) > 1})
    duplicate_source = sorted({path for path in source_paths if source_paths.count(path) > 1})
    if duplicate_canonical:
        errors.append(f"{MANIFEST_PATH}: duplicate canonicalPath values {duplicate_canonical}")
    if duplicate_source:
        errors.append(f"{MANIFEST_PATH}: duplicate sourcePath values {duplicate_source}")
    manifest_paths = set(canonical_paths)
    if actual_paths - manifest_paths:
        errors.append(f"{MANIFEST_PATH}: untracked canonical assets {sorted(actual_paths - manifest_paths)}")
    if manifest_paths - actual_paths:
        errors.append(f"{MANIFEST_PATH}: missing canonical assets {sorted(manifest_paths - actual_paths)}")
    if manifest.get("assetCount") != len(records):
        errors.append(f"{MANIFEST_PATH}: assetCount does not match records")
    if manifest.get("totalBytes") != total_bytes:
        errors.append(f"{MANIFEST_PATH}: totalBytes does not match canonical assets")

    attributes = root / ".gitattributes"
    rules = attributes.read_text(encoding="utf-8").splitlines() if attributes.is_file() else []
    if LFS_RULE not in rules:
        errors.append(f".gitattributes: missing Git LFS policy {LFS_RULE!r}")
    if check_git_lfs:
        try:
            tracked_lfs = lfs_paths(root)
        except RuntimeError as error:
            errors.append(str(error))
        else:
            if expected_lfs != tracked_lfs:
                errors.append(
                    "Git LFS index mismatch: "
                    f"missing={sorted(expected_lfs - tracked_lfs)}, extra={sorted(tracked_lfs - expected_lfs)}"
                )
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--source", type=Path)
    parser.add_argument("--write-manifest", action="store_true")
    parser.add_argument("--check-git-lfs", action="store_true")
    args = parser.parse_args()
    if args.write_manifest:
        if args.source is None:
            parser.error("--write-manifest requires --source")
        try:
            manifest = build_manifest(args.source, args.root)
        except (OSError, ValueError) as error:
            print(f"Brand manifest generation failed: {error}", file=sys.stderr)
            return 1
        output = args.root / MANIFEST_PATH
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"Wrote {manifest['assetCount']} brand records to {output.relative_to(args.root)}")
    errors = validate_brand_assets(args.root, check_git_lfs=args.check_git_lfs)
    if errors:
        print("Brand asset validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    manifest = json.loads((args.root / MANIFEST_PATH).read_text(encoding="utf-8"))
    print(f"Brand asset validation passed: {manifest['assetCount']} files, {manifest['totalBytes']} bytes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
