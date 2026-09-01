#!/usr/bin/env python3
"""Validate canonical brand typography assets and their provenance manifest."""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = Path("assets/typography/manifest.json")
EXPECTED_FAMILIES = {"Onest", "Tektur"}
EXPECTED_ROLE_MAP = {
    "display": "Tektur",
    "featureHeading": "Tektur",
    "sectionHeading": "Onest",
    "navigation": "Onest",
    "body": "Onest",
    "metadata": "Onest",
}
REQUIRED_CODEPOINTS = {
    "latin": {0x0041},
    "cyrillic": {0x0410, 0x0451},
    "greek": {0x0391},
}


def read_u16(data: bytes, offset: int) -> int:
    return struct.unpack_from(">H", data, offset)[0]


def read_u32(data: bytes, offset: int) -> int:
    return struct.unpack_from(">I", data, offset)[0]


def read_fixed(data: bytes, offset: int) -> float:
    return struct.unpack_from(">i", data, offset)[0] / 65536.0


def sfnt_tables(data: bytes) -> dict[str, bytes]:
    if len(data) < 12 or data[:4] not in {b"\x00\x01\x00\x00", b"OTTO", b"true"}:
        raise ValueError("not a supported SFNT font")
    table_count = read_u16(data, 4)
    directory_end = 12 + table_count * 16
    if directory_end > len(data):
        raise ValueError("truncated SFNT table directory")

    tables: dict[str, bytes] = {}
    for index in range(table_count):
        record = 12 + index * 16
        tag = data[record : record + 4].decode("ascii", errors="replace")
        offset = read_u32(data, record + 8)
        length = read_u32(data, record + 12)
        if offset + length > len(data):
            raise ValueError(f"truncated SFNT table: {tag}")
        tables[tag] = data[offset : offset + length]
    return tables


def family_names(name_table: bytes) -> set[str]:
    if len(name_table) < 6:
        raise ValueError("truncated name table")
    count = read_u16(name_table, 2)
    storage_offset = read_u16(name_table, 4)
    names: dict[int, set[str]] = {1: set(), 16: set()}
    for index in range(count):
        record = 6 + index * 12
        if record + 12 > len(name_table):
            raise ValueError("truncated name record")
        platform = read_u16(name_table, record)
        name_id = read_u16(name_table, record + 6)
        if name_id not in names:
            continue
        length = read_u16(name_table, record + 8)
        offset = storage_offset + read_u16(name_table, record + 10)
        raw = name_table[offset : offset + length]
        if len(raw) != length:
            raise ValueError("truncated name string")
        encoding = "utf-16-be" if platform in {0, 3} else "mac_roman"
        try:
            value = raw.decode(encoding).strip()
        except UnicodeDecodeError:
            continue
        if value:
            names[name_id].add(value)
    return names[16] or names[1]


def variation_axes(fvar_table: bytes) -> dict[str, tuple[float, float, float]]:
    if len(fvar_table) < 16:
        raise ValueError("truncated fvar table")
    axes_offset = read_u16(fvar_table, 4)
    axis_count = read_u16(fvar_table, 8)
    axis_size = read_u16(fvar_table, 10)
    if axis_size < 20:
        raise ValueError("invalid fvar axis size")

    axes: dict[str, tuple[float, float, float]] = {}
    for index in range(axis_count):
        offset = axes_offset + index * axis_size
        if offset + 20 > len(fvar_table):
            raise ValueError("truncated fvar axis")
        tag = fvar_table[offset : offset + 4].decode("ascii", errors="replace")
        axes[tag] = (
            read_fixed(fvar_table, offset + 4),
            read_fixed(fvar_table, offset + 8),
            read_fixed(fvar_table, offset + 12),
        )
    return axes


def cmap_format_4_contains(table: bytes, codepoint: int) -> bool:
    if codepoint > 0xFFFF or len(table) < 16:
        return False
    length = read_u16(table, 2)
    if length > len(table):
        return False
    segment_count = read_u16(table, 6) // 2
    end_codes = 14
    start_codes = end_codes + segment_count * 2 + 2
    deltas = start_codes + segment_count * 2
    range_offsets = deltas + segment_count * 2
    if range_offsets + segment_count * 2 > length:
        return False

    for index in range(segment_count):
        end = read_u16(table, end_codes + index * 2)
        start = read_u16(table, start_codes + index * 2)
        if not start <= codepoint <= end:
            continue
        delta = read_u16(table, deltas + index * 2)
        range_offset_position = range_offsets + index * 2
        range_offset = read_u16(table, range_offset_position)
        if range_offset == 0:
            return ((codepoint + delta) & 0xFFFF) != 0
        glyph_position = range_offset_position + range_offset + (codepoint - start) * 2
        if glyph_position + 2 > length:
            return False
        glyph = read_u16(table, glyph_position)
        return glyph != 0 and ((glyph + delta) & 0xFFFF) != 0
    return False


def cmap_format_12_contains(table: bytes, codepoint: int) -> bool:
    if len(table) < 16:
        return False
    length = read_u32(table, 4)
    group_count = read_u32(table, 12)
    if length > len(table) or 16 + group_count * 12 > length:
        return False
    for index in range(group_count):
        offset = 16 + index * 12
        start = read_u32(table, offset)
        end = read_u32(table, offset + 4)
        if start <= codepoint <= end:
            return read_u32(table, offset + 8) + codepoint - start != 0
        if codepoint < start:
            break
    return False


def cmap_contains(cmap_table: bytes, codepoint: int) -> bool:
    if len(cmap_table) < 4:
        raise ValueError("truncated cmap table")
    subtable_count = read_u16(cmap_table, 2)
    for index in range(subtable_count):
        record = 4 + index * 8
        if record + 8 > len(cmap_table):
            raise ValueError("truncated cmap encoding record")
        platform = read_u16(cmap_table, record)
        encoding = read_u16(cmap_table, record + 2)
        if platform != 0 and not (platform == 3 and encoding in {1, 10}):
            continue
        offset = read_u32(cmap_table, record + 4)
        if offset + 2 > len(cmap_table):
            continue
        subtable = cmap_table[offset:]
        format_number = read_u16(subtable, 0)
        if format_number == 4 and cmap_format_4_contains(subtable, codepoint):
            return True
        if format_number == 12 and cmap_format_12_contains(subtable, codepoint):
            return True
    return False


def relative_catalog_path(root: Path, value: Any) -> tuple[Path | None, str | None]:
    if not isinstance(value, str) or not value.startswith("assets/typography/"):
        return None, f"invalid typography asset path: {value!r}"
    candidate = root / value
    try:
        candidate.resolve().relative_to(root.resolve())
    except ValueError:
        return None, f"typography asset escapes repository root: {value}"
    return candidate, None


def validate_ttf(path: Path, family: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    family_name = family.get("family", "<unknown>")
    try:
        tables = sfnt_tables(path.read_bytes())
        names = family_names(tables["name"])
        axes = variation_axes(tables["fvar"])
        revision = read_fixed(tables["head"], 4)
        cmap = tables["cmap"]
    except (KeyError, OSError, ValueError, struct.error) as error:
        return [f"invalid TTF for {family_name}: {path}: {error}"]

    if family_name not in names:
        errors.append(f"family-name mismatch for {family_name}: found {sorted(names)}")

    try:
        declared_revision = float(family["version"])
    except (KeyError, TypeError, ValueError):
        errors.append(f"invalid version for {family_name}")
    else:
        if abs(revision - declared_revision) > 0.001:
            errors.append(
                f"font-version mismatch for {family_name}: declared {declared_revision}, found {revision:.4f}"
            )

    declared_axes = family.get("axes")
    if not isinstance(declared_axes, list):
        errors.append(f"invalid axes declaration for {family_name}")
    else:
        declared_tags: set[str] = set()
        for axis in declared_axes:
            if not isinstance(axis, dict) or not isinstance(axis.get("tag"), str):
                errors.append(f"invalid axis declaration for {family_name}")
                continue
            tag = axis["tag"]
            declared_tags.add(tag)
            actual = axes.get(tag)
            expected = (axis.get("min"), axis.get("default"), axis.get("max"))
            if actual is None or any(
                not isinstance(value, (int, float)) or abs(float(value) - found) > 0.001
                for value, found in zip(expected, actual)
            ):
                errors.append(
                    f"axis mismatch for {family_name} {tag}: declared {expected}, found {actual}"
                )
        extra_axes = sorted(set(axes) - declared_tags)
        if extra_axes:
            errors.append(f"undeclared axes for {family_name}: {', '.join(extra_axes)}")

    scripts = family.get("scripts", [])
    if not isinstance(scripts, list):
        errors.append(f"invalid script coverage for {family_name}")
    else:
        for script, codepoints in REQUIRED_CODEPOINTS.items():
            if script not in scripts:
                continue
            missing = sorted(codepoint for codepoint in codepoints if not cmap_contains(cmap, codepoint))
            if missing:
                formatted = ", ".join(f"U+{codepoint:04X}" for codepoint in missing)
                errors.append(f"missing {script} glyphs for {family_name}: {formatted}")
    return errors


def validate_typography_assets(root: Path) -> list[str]:
    errors: list[str] = []
    manifest_path = root / CATALOG_PATH
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read {CATALOG_PATH}: {error}"]

    if manifest.get("schemaVersion") != 1:
        errors.append("typography manifest schemaVersion must be 1")
    if manifest.get("catalog") != "qenterra.brand.typography":
        errors.append("typography manifest catalog must be qenterra.brand.typography")
    if manifest.get("scope") != "brand-and-portfolio":
        errors.append("typography manifest scope must be brand-and-portfolio")
    if manifest.get("universalUiDefaultsChanged") is not False:
        errors.append("brand typography must not change universal UI defaults")
    if manifest.get("roleMap") != EXPECTED_ROLE_MAP:
        errors.append("typography roleMap does not match the approved portfolio pairing")

    families = manifest.get("families")
    if not isinstance(families, list):
        return errors + ["typography manifest families must be an array"]
    family_names_in_manifest = {
        family.get("family") for family in families if isinstance(family, dict)
    }
    if family_names_in_manifest != EXPECTED_FAMILIES:
        errors.append(
            "typography families must be exactly: " + ", ".join(sorted(EXPECTED_FAMILIES))
        )

    declared_paths: set[str] = set()
    ttf_paths: dict[str, Path] = {}
    for family in families:
        if not isinstance(family, dict):
            errors.append("typography family entries must be objects")
            continue
        family_name = family.get("family", "<unknown>")
        if family.get("license") != "OFL-1.1":
            errors.append(f"license for {family_name} must be OFL-1.1")
        if not family.get("upstream") or not isinstance(family.get("upstream"), dict):
            errors.append(f"missing upstream provenance for {family_name}")
        assets = family.get("assets")
        if not isinstance(assets, list):
            errors.append(f"assets for {family_name} must be an array")
            continue

        formats: set[str] = set()
        for asset in assets:
            if not isinstance(asset, dict):
                errors.append(f"asset entries for {family_name} must be objects")
                continue
            relative = asset.get("path")
            path, path_error = relative_catalog_path(root, relative)
            if path_error:
                errors.append(path_error)
                continue
            assert path is not None and isinstance(relative, str)
            if relative in declared_paths:
                errors.append(f"duplicate typography asset path: {relative}")
                continue
            declared_paths.add(relative)
            asset_format = asset.get("format")
            if isinstance(asset_format, str):
                formats.add(asset_format)
            if not path.is_file():
                errors.append(f"missing typography asset: {relative}")
                continue
            data = path.read_bytes()
            if len(data) != asset.get("bytes"):
                errors.append(
                    f"byte-size drift for {relative}: declared {asset.get('bytes')}, found {len(data)}"
                )
            digest = hashlib.sha256(data).hexdigest()
            if digest != asset.get("sha256"):
                errors.append(f"SHA-256 drift for {relative}: found {digest}")
            if asset_format == "ttf-variable":
                ttf_paths[str(family_name)] = path
            elif asset_format == "woff2-variable" and data[:4] != b"wOF2":
                errors.append(f"invalid WOFF2 signature for {relative}")
            elif asset_format == "license":
                text = data.decode("utf-8", errors="replace")
                if "SIL OPEN FONT LICENSE Version 1.1" not in text:
                    errors.append(f"license text for {family_name} is not OFL 1.1")

        expected_formats = {"license", "ttf-variable", "woff2-variable"}
        if formats != expected_formats:
            errors.append(
                f"asset formats for {family_name} must be exactly: "
                + ", ".join(sorted(expected_formats))
            )

    typography_root = root / "assets" / "typography"
    actual_paths = {
        path.relative_to(root).as_posix()
        for path in typography_root.rglob("*")
        if path.is_file() and path != manifest_path
    }
    untracked = sorted(actual_paths - declared_paths)
    missing_from_tree = sorted(declared_paths - actual_paths)
    if untracked:
        errors.append("untracked typography assets: " + ", ".join(untracked))
    if missing_from_tree:
        errors.append("manifest assets missing from tree: " + ", ".join(missing_from_tree))

    for family in families:
        if not isinstance(family, dict):
            continue
        family_name = str(family.get("family", "<unknown>"))
        ttf_path = ttf_paths.get(family_name)
        if ttf_path is None:
            errors.append(f"missing variable TTF for {family_name}")
            continue
        errors.extend(validate_ttf(ttf_path, family))

    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    arguments = parser.parse_args(argv)
    root = arguments.root.resolve()
    errors = validate_typography_assets(root)
    if errors:
        for error in errors:
            print(f"Typography asset validation failed: {error}", file=sys.stderr)
        return 1

    manifest = json.loads((root / CATALOG_PATH).read_text(encoding="utf-8"))
    asset_count = sum(len(family["assets"]) for family in manifest["families"])
    print(
        f"Typography asset validation passed: {len(manifest['families'])} families, "
        f"{asset_count} assets."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
