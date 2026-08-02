#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Строит светлые и тёмные QA-контакт-листы бренд-ассетов Nyx.

Вывод разрешён только вне репозитория:
    python3 "scripts/brand/build_nyx_asset_contacts.py" \
      --dir "/путь/к/character-assets" \
      --manifest "/private/tmp/nyx-batch.json" \
      --out "/private/tmp/nyx-contacts"

Скрипт не меняет исходные PNG. Код выхода: 0 — листы созданы, 1 — ошибка,
2 — в активном Python нет Pillow.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path, PurePosixPath
from typing import Any


def load_runtime() -> None:
    global Image, ImageDraw, ImageFont, LABEL_FONT
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ModuleNotFoundError as error:
        print(
            "ОШИБКА: нужен Python с Pillow; используйте настроенное окружение "
            f"или установите зависимость ({error}).",
            file=sys.stderr,
        )
        raise SystemExit(2)
    LABEL_FONT = load_font(17)

def repository_root() -> Path:
    return Path(__file__).resolve().parents[2]


def default_asset_dir() -> Path:
    return repository_root() / "assets" / "brand" / "nyx" / "character-assets"


def default_spec_path() -> Path:
    return Path(__file__).resolve().with_name("nyx_assets_spec.json")


def is_inside(path: Path, parent: Path) -> bool:
    try:
        path.resolve().relative_to(parent.resolve())
        return True
    except ValueError:
        return False


def parse_hex(value: str) -> tuple[int, int, int]:
    raw = value.lstrip("#")
    if len(raw) != 6:
        raise ValueError(f"некорректный HEX: {value}")
    return tuple(int(raw[index : index + 2], 16) for index in (0, 2, 4))


def load_spec(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def manifest_paths(path: Path, categories: set[str]) -> list[str]:
    data = json.loads(path.read_text(encoding="utf-8"))
    assets = data.get("assets") if isinstance(data, dict) else None
    if not isinstance(assets, list) or not assets:
        raise ValueError("манифест должен содержать непустой массив assets")
    result: list[str] = []
    for index, entry in enumerate(assets, 1):
        raw = entry if isinstance(entry, str) else entry.get("path") if isinstance(entry, dict) else None
        if not isinstance(raw, str):
            raise ValueError(f"assets[{index}]: нет строкового path")
        normalized = PurePosixPath(raw)
        if (
            normalized.is_absolute()
            or ".." in normalized.parts
            or len(normalized.parts) != 2
            or normalized.parts[0] not in categories
            or normalized.suffix.lower() != ".png"
        ):
            raise ValueError(f"assets[{index}]: неверный путь {raw!r}")
        result.append(normalized.as_posix())
    if len(result) != len(set(result)):
        raise ValueError("в манифесте есть дубли путей")
    return result


def load_font(size: int) -> ImageFont.ImageFont:
    candidates = (
        Path("/System/Library/Fonts/Supplemental/Arial.ttf"),
        Path("/System/Library/Fonts/SFNS.ttf"),
    )
    for path in candidates:
        if path.is_file():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


LABEL_FONT: Any = None


def composite(image: Image.Image, background: tuple[int, int, int]) -> Image.Image:
    canvas = Image.new("RGBA", image.size, (*background, 255))
    canvas.alpha_composite(image.convert("RGBA"))
    return canvas.convert("RGB")


def fit(
    image: Image.Image,
    size: tuple[int, int],
    background: tuple[int, int, int],
) -> Image.Image:
    copy = image.copy()
    copy.thumbnail(size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGB", size, background)
    canvas.paste(copy, ((size[0] - copy.width) // 2, (size[1] - copy.height) // 2))
    return canvas


def contact_sheet(
    entries: list[tuple[str, Path]],
    background: tuple[int, int, int],
    output: Path,
    columns: int,
) -> None:
    cell = (420, 420)
    label_height = 58
    rows = (len(entries) + columns - 1) // columns
    sheet = Image.new(
        "RGB",
        (cell[0] * columns, (cell[1] + label_height) * rows),
        (28, 28, 31),
    )
    draw = ImageDraw.Draw(sheet)
    for index, (label, path) in enumerate(entries):
        row, column = divmod(index, columns)
        x = column * cell[0]
        y = row * (cell[1] + label_height)
        draw.text((x + 10, y + 8), label, font=LABEL_FONT, fill=(240, 240, 240))
        with Image.open(path) as source:
            rendered = composite(source, background)
        sheet.paste(fit(rendered, cell, background), (x, y + label_height))
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, "PNG", compress_level=8)


def detail_sheet(
    entries: list[tuple[str, Path]],
    category: str,
    background: tuple[int, int, int],
    output: Path,
) -> None:
    tile = (480, 420)
    label_height = 52
    columns = 4
    panels: list[tuple[str, Image.Image]] = []
    for label, path in entries:
        with Image.open(path) as source:
            image = source.convert("RGBA")
        bbox = image.getchannel("A").getbbox()
        if bbox is None:
            continue
        left, top, right, bottom = bbox
        height = bottom - top
        if category == "full-body":
            crops = (
                ("head/hands", (left, top, right, min(bottom, top + round(height * 0.40)))),
                ("feet/props", (left, max(top, bottom - round(height * 0.34)), right, bottom)),
            )
        elif category == "portraits":
            crops = (("face/hair", (left, top, right, min(bottom, top + round(height * 0.68)))),)
        elif category == "compositions":
            crops = (("prop/edges", bbox),)
        else:
            crops = (("silhouette", bbox),)
        rendered = composite(image, background)
        for suffix, crop_box in crops:
            panels.append((f"{label} — {suffix}", rendered.crop(crop_box)))

    rows = (len(panels) + columns - 1) // columns
    sheet = Image.new(
        "RGB",
        (tile[0] * columns, (tile[1] + label_height) * rows),
        (28, 28, 31),
    )
    draw = ImageDraw.Draw(sheet)
    for index, (label, crop) in enumerate(panels):
        row, column = divmod(index, columns)
        x = column * tile[0]
        y = row * (tile[1] + label_height)
        draw.text((x + 8, y + 8), label, font=LABEL_FONT, fill=(240, 240, 240))
        sheet.paste(fit(crop, tile, background), (x, y + label_height))
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, "PNG", compress_level=8)


def main() -> int:
    parser = argparse.ArgumentParser(description="QA-контакт-листы бренд-ассетов Nyx.")
    parser.add_argument("--dir", type=Path, default=default_asset_dir(), help="корень character-assets")
    parser.add_argument("--manifest", type=Path, help="JSON-манифест пачки")
    parser.add_argument("--out", type=Path, required=True, help="временная папка вывода")
    parser.add_argument("--columns", type=int, default=5, help="колонок на общем листе")
    parser.add_argument("--spec", type=Path, default=default_spec_path(), help="технический spec")
    args = parser.parse_args()
    load_runtime()

    target = args.dir.expanduser().resolve()
    output = args.out.expanduser().resolve()
    if not target.is_dir():
        print(f"ОШИБКА: папка не найдена: {target}")
        return 1
    if is_inside(output, repository_root()):
        print("ОШИБКА: контакт-листы нельзя записывать внутрь design-system")
        return 1
    if args.columns < 1 or args.columns > 10:
        print("ОШИБКА: columns должен быть от 1 до 10")
        return 1

    try:
        spec = load_spec(args.spec.expanduser().resolve())
        categories = list(spec["categories"])
        if args.manifest:
            paths = manifest_paths(args.manifest.expanduser().resolve(), set(categories))
        else:
            paths = []
            for category in categories:
                paths.extend(
                    item.relative_to(target).as_posix()
                    for item in sorted((target / category).glob("*.png"))
                )
        if not paths:
            raise ValueError("нет PNG для контакт-листа")
        missing = [relative for relative in paths if not (target / relative).is_file()]
        if missing:
            raise ValueError("не найдены файлы: " + ", ".join(missing))
        light = parse_hex(spec["backgrounds"]["light"])
        dark = parse_hex(spec["backgrounds"]["dark"])
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as error:
        print(f"ОШИБКА: {error}")
        return 1

    entries_by_category: dict[str, list[tuple[str, Path]]] = {key: [] for key in categories}
    for relative in paths:
        category, filename = PurePosixPath(relative).parts
        entries_by_category[category].append((Path(filename).stem, target / relative))
    all_entries = [
        (f"{category} / {label}", path)
        for category in categories
        for label, path in entries_by_category[category]
    ]

    output.mkdir(parents=True, exist_ok=True)
    contact_sheet(all_entries, light, output / "all-light.png", args.columns)
    contact_sheet(all_entries, dark, output / "all-dark.png", args.columns)
    for category, entries in entries_by_category.items():
        if not entries:
            continue
        slug = category.lower().replace(" ", "-")
        detail_sheet(entries, category, light, output / f"{slug}-details-light.png")
        detail_sheet(entries, category, dark, output / f"{slug}-details-dark.png")

    print(f"OK — создано контакт-листов для {len(all_entries)} PNG: {output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
