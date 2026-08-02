#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Проверяет финальный Telegram-стикерпак Nyx без изменения файлов.

Запуск из корня design-system:
    python3 "scripts/brand/validate_telegram_stickers.py"
    python3 "scripts/brand/validate_telegram_stickers.py" --dir "/путь/к/telegram-stickers"

Проверяются: PNG 512×512 RGBA, прозрачный периметр холста, отсутствие
мадженты от хромакея, синего засвета в Doomscroll.png, отсутствие SVG и
соответствие файлу Sticker Emojis.md. Код выхода: 0 — чисто, 1 — есть ошибки.
"""
from __future__ import annotations

import argparse
import struct
import sys
import zlib
from pathlib import Path


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
EMOJI_MAP_NAME = "Sticker Emojis.md"


def repository_root() -> Path:
    return Path(__file__).resolve().parents[2]


def default_sticker_dir() -> Path:
    return repository_root() / "assets" / "brand" / "nyx" / "telegram-stickers"


def paeth(left: int, up: int, up_left: int) -> int:
    candidate = left + up - up_left
    distances = (abs(candidate - left), abs(candidate - up), abs(candidate - up_left))
    return (left, up, up_left)[distances.index(min(distances))]


def decode_rgba_png(path: Path) -> tuple[int, int, list[bytes]]:
    data = path.read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError("не PNG-сигнатура")

    cursor = len(PNG_SIGNATURE)
    header = None
    idat = []
    while cursor < len(data):
        if cursor + 12 > len(data):
            raise ValueError("обрезанный PNG-chunk")
        length = struct.unpack(">I", data[cursor : cursor + 4])[0]
        chunk_type = data[cursor + 4 : cursor + 8]
        start, end = cursor + 8, cursor + 8 + length
        if end + 4 > len(data):
            raise ValueError("обрезанный PNG-chunk")
        payload = data[start:end]
        if chunk_type == b"IHDR":
            if header is not None or length != 13:
                raise ValueError("некорректный IHDR")
            header = struct.unpack(">IIBBBBB", payload)
        elif chunk_type == b"IDAT":
            idat.append(payload)
        elif chunk_type == b"IEND":
            break
        cursor = end + 4

    if header is None:
        raise ValueError("нет IHDR")
    width, height, bit_depth, color_type, compression, filtering, interlace = header
    if (bit_depth, color_type, compression, filtering, interlace) != (8, 6, 0, 0, 0):
        raise ValueError("ожидался нечересстрочный 8-битный RGBA PNG")
    if not idat:
        raise ValueError("нет IDAT")

    raw = zlib.decompress(b"".join(idat))
    stride = width * 4
    expected = (stride + 1) * height
    if len(raw) != expected:
        raise ValueError("неверная длина распакованных пикселей")

    rows = []
    offset = 0
    previous = bytearray(stride)
    for _ in range(height):
        filter_type = raw[offset]
        encoded = raw[offset + 1 : offset + 1 + stride]
        offset += stride + 1
        row = bytearray(stride)
        for index, value in enumerate(encoded):
            left = row[index - 4] if index >= 4 else 0
            up = previous[index]
            up_left = previous[index - 4] if index >= 4 else 0
            if filter_type == 0:
                row[index] = value
            elif filter_type == 1:
                row[index] = (value + left) & 255
            elif filter_type == 2:
                row[index] = (value + up) & 255
            elif filter_type == 3:
                row[index] = (value + ((left + up) // 2)) & 255
            elif filter_type == 4:
                row[index] = (value + paeth(left, up, up_left)) & 255
            else:
                raise ValueError(f"неизвестный PNG-фильтр {filter_type}")
        rows.append(bytes(row))
        previous = row
    return width, height, rows


def parse_emoji_map(path: Path) -> tuple[dict[str, str], list[str]]:
    entries: dict[str, str] = {}
    errors: list[str] = []
    for number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw_line.strip()
        if not line:
            continue
        if " - " not in line:
            errors.append(f"{path.name}:{number}: ожидается «Название стикера - эмодзи»")
            continue
        name, emoji = (part.strip() for part in line.rsplit(" - ", 1))
        if not name or not emoji:
            errors.append(f"{path.name}:{number}: пустое имя или эмодзи")
        elif name in entries:
            errors.append(f"{path.name}:{number}: дублируется «{name}»")
        else:
            entries[name] = emoji
    if not entries:
        errors.append(f"{path.name}: нет ни одной строки стикера")
    return entries, errors


def validate_png(path: Path) -> list[str]:
    errors: list[str] = []
    try:
        width, height, rows = decode_rgba_png(path)
    except (OSError, ValueError, struct.error, zlib.error) as error:
        return [f"{path.name}: {error}"]

    if (width, height) != (512, 512):
        errors.append(f"{path.name}: размер {width}×{height}, нужен 512×512")
        return errors

    edge_pixels = {
        "верх": sum(bool(rows[0][index + 3]) for index in range(0, width * 4, 4)),
        "низ": sum(bool(rows[-1][index + 3]) for index in range(0, width * 4, 4)),
        "лево": sum(bool(row[3]) for row in rows),
        "право": sum(bool(row[-1]) for row in rows),
    }
    if any(edge_pixels.values()):
        details = ", ".join(
            f"{edge}={count}" for edge, count in edge_pixels.items() if count
        )
        errors.append(
            f"{path.name}: рисунок касается края холста ({details}); "
            "нужен прозрачный запас по всему периметру и замкнутая белая обводка"
        )

    magenta = 0
    blue_cast = 0
    for row in rows:
        for index in range(0, len(row), 4):
            red, green, blue, alpha = row[index : index + 4]
            if alpha and red > 180 and blue > 160 and green < 110:
                magenta += 1
            if path.name == "Doomscroll.png" and alpha and blue > red + 6 and blue > green + 3:
                blue_cast += 1
    if magenta:
        errors.append(f"{path.name}: осталось {magenta} маджента-пикселей хромакея")
    if blue_cast:
        errors.append(f"{path.name}: осталось {blue_cast} синих пикселей засвета")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Проверка финального Telegram-стикерпака Nyx.")
    parser.add_argument("--dir", type=Path, default=default_sticker_dir(), help="папка с финальными PNG")
    args = parser.parse_args()
    target = args.dir.expanduser().resolve()
    if not target.is_dir():
        print(f"ОШИБКА: папка не найдена: {target}")
        return 1

    errors: list[str] = []
    emoji_map_path = target / EMOJI_MAP_NAME
    if not emoji_map_path.is_file():
        errors.append(f"нет {EMOJI_MAP_NAME}")
        entries = {}
    else:
        entries, map_errors = parse_emoji_map(emoji_map_path)
        errors.extend(map_errors)

    stickers = sorted(target.glob("*.png"))
    if not stickers:
        errors.append("не найдено ни одного PNG-стикера")
    png_names = {path.stem for path in stickers}
    map_names = set(entries)
    if png_names != map_names:
        if png_names - map_names:
            errors.append("в Sticker Emojis.md нет: " + ", ".join(sorted(png_names - map_names)))
        if map_names - png_names:
            errors.append("нет PNG для: " + ", ".join(sorted(map_names - png_names)))

    svg_files = sorted(path.name for path in target.glob("*.svg"))
    if svg_files:
        errors.append("SVG не входят в финальный пак: " + ", ".join(svg_files))

    for sticker in stickers:
        errors.extend(validate_png(sticker))

    print(f"Проверено: {len(stickers)} PNG, {len(entries)} строк {EMOJI_MAP_NAME}.")
    if errors:
        for error in errors:
            print("ОШИБКА:", error)
        return 1
    print("OK — состав, эмодзи, PNG и цветовые инварианты корректны.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
