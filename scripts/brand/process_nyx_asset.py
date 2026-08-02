#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Локально очищает, апскейлит и восстанавливает RGBA бренд-ассета Nyx.

Подкоманды:
  prepare            chroma-key -> чистый RGBA + серый RGB + alpha;
  restore            upscaled RGB + alpha -> финальный RGBA и геометрия;
  run                полный проход через внешний waifu2x-ncnn-vulkan;
  neutralize-region  локально убирает цветную линию внутри точной области.

Скрипт не скачивает модели. Work-dir обязан находиться в системной временной
директории. Существующие outputs не перезаписываются без --overwrite.
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any


def load_runtime() -> None:
    global Image, ImageDraw, ImageFilter, np
    try:
        import numpy as np
        from PIL import Image, ImageDraw, ImageFilter
    except ModuleNotFoundError as error:
        print(
            "ОШИБКА: нужен Python с Pillow и NumPy; используйте настроенное окружение "
            f"или установите зависимости ({error}).",
            file=sys.stderr,
        )
        raise SystemExit(2)

EXPECTED_KEY = (255.0, 0.0, 255.0)


def default_spec_path() -> Path:
    return Path(__file__).resolve().with_name("nyx_assets_spec.json")


def is_inside(path: Path, parent: Path) -> bool:
    try:
        path.resolve().relative_to(parent.resolve())
        return True
    except ValueError:
        return False


def ensure_temp_work_dir(path: Path) -> Path:
    resolved = path.expanduser().resolve()
    allowed = {
        Path(tempfile.gettempdir()).resolve(),
        Path("/private/tmp").resolve(),
        Path("/tmp").resolve(),
    }
    if not any(resolved != base and is_inside(resolved, base) for base in allowed):
        raise ValueError(f"work-dir должен быть внутри системной временной директории: {resolved}")
    resolved.mkdir(parents=True, exist_ok=True)
    return resolved


def require_output(path: Path, overwrite: bool) -> Path:
    resolved = path.expanduser().resolve()
    if resolved.exists() and not overwrite:
        raise ValueError(f"output уже существует; нужен --overwrite: {resolved}")
    resolved.parent.mkdir(parents=True, exist_ok=True)
    return resolved


def parse_hex(value: str) -> tuple[int, int, int]:
    raw = value.lstrip("#")
    if len(raw) != 6:
        raise ValueError(f"некорректный HEX: {value}")
    return tuple(int(raw[index : index + 2], 16) for index in (0, 2, 4))


def load_spec(path: Path) -> dict[str, Any]:
    return json.loads(path.expanduser().resolve().read_text(encoding="utf-8"))


def measured_key(rgb: np.ndarray) -> np.ndarray:
    border = np.concatenate(
        (rgb[0, :, :], rgb[-1, :, :], rgb[:, 0, :], rgb[:, -1, :]),
        axis=0,
    )
    key = np.median(border, axis=0).astype(np.float32)
    if np.linalg.norm(key - np.asarray(EXPECTED_KEY, dtype=np.float32)) > 45:
        raise ValueError(
            f"измеренный цвет периметра {key.round(1).tolist()} не похож на #FF00FF"
        )
    return key


def border_connected(mask: np.ndarray) -> np.ndarray:
    channel = np.where(mask, 0, 255).astype(np.uint8)
    binary = Image.fromarray(np.repeat(channel[..., None], 3, axis=2), "RGB")
    width, height = binary.size
    step = max(1, min(width, height) // 32)
    seeds = (
        [(x, 0) for x in range(0, width, step)]
        + [(x, height - 1) for x in range(0, width, step)]
        + [(0, y) for y in range(0, height, step)]
        + [(width - 1, y) for y in range(0, height, step)]
        + [(width - 1, height - 1)]
    )
    for seed in seeds:
        if binary.getpixel(seed) == (0, 0, 0):
            ImageDraw.floodfill(binary, seed, (128, 128, 128), thresh=0)
    return np.asarray(binary, dtype=np.uint8)[..., 0] == 128


def clean_chroma(
    image: Image.Image,
    threshold: int,
    band_radius: int,
    edge_only: bool,
    dominance_threshold: float,
) -> tuple[Image.Image, np.ndarray]:
    rgb = np.asarray(image.convert("RGB"), dtype=np.float32)
    source_alpha = np.asarray(image.convert("RGBA"), dtype=np.uint8)[..., 3].astype(np.float32) / 255.0
    key = measured_key(rgb)
    distance = np.linalg.norm(rgb - key, axis=2)
    key_candidate = distance <= threshold
    background = border_connected(key_candidate) if edge_only else key_candidate

    core = Image.fromarray(background.astype(np.uint8) * 255, "L")
    narrow = np.asarray(
        core.filter(ImageFilter.MaxFilter((band_radius * 2) + 1)),
        dtype=np.uint8,
    ) > 0
    wide_radius = max(band_radius + 1, band_radius * 2)
    wide = np.asarray(
        core.filter(ImageFilter.MaxFilter((wide_radius * 2) + 1)),
        dtype=np.uint8,
    ) > 0
    narrow &= ~background
    wide &= ~background

    dominance = np.maximum(0.0, np.minimum(rgb[..., 0], rgb[..., 2]) - rgb[..., 1])
    key_dominance = max(1.0, min(key[0], key[2]) - key[1])
    estimated = np.clip(1.0 - (dominance / key_dominance), 0.0, 1.0)
    matte = narrow if edge_only else narrow | (wide & (dominance > dominance_threshold))

    alpha = source_alpha.copy()
    alpha[background] = 0.0
    alpha[matte] = np.minimum(alpha[matte], estimated[matte])
    alpha[background] = 0.0

    foreground = rgb.copy()
    safe_alpha = np.maximum(alpha[..., None], 1.0 / 255.0)
    recovered = (rgb - ((1.0 - alpha[..., None]) * key)) / safe_alpha
    foreground[matte] = recovered[matte]
    foreground = np.clip(foreground, 0.0, 255.0)

    magenta_excess = np.maximum(
        0.0,
        np.minimum(foreground[..., 0], foreground[..., 2]) - foreground[..., 1],
    )
    foreground[..., 0][matte] -= magenta_excess[matte]
    foreground[..., 2][matte] -= magenta_excess[matte]
    green_cap = np.maximum(foreground[..., 0], foreground[..., 2]) + 6.0
    foreground[..., 1][matte] = np.minimum(foreground[..., 1], green_cap)[matte]
    foreground[alpha == 0] = 0

    final_alpha = np.round(alpha * 255.0).astype(np.uint8)
    rgba = np.dstack((np.clip(foreground, 0, 255).astype(np.uint8), final_alpha))
    rgba[..., :3][final_alpha == 0] = 0
    return Image.fromarray(rgba, "RGBA"), key


def prepare_files(
    input_path: Path,
    work_dir: Path,
    spec: dict[str, Any],
    threshold: int,
    band_radius: int,
    dominance_threshold: float,
    edge_only: bool,
    overwrite: bool,
) -> dict[str, Path]:
    source = input_path.expanduser().resolve()
    if not source.is_file():
        raise ValueError(f"input не найден: {source}")
    work = ensure_temp_work_dir(work_dir)
    stem = source.stem
    paths = {
        "subject": work / f"{stem}-subject.png",
        "rgb": work / f"{stem}-upscale-rgb.png",
        "alpha": work / f"{stem}-alpha.png",
        "metadata": work / f"{stem}-metadata.json",
    }
    for path in paths.values():
        if path.exists() and not overwrite:
            raise ValueError(f"временный output уже существует; нужен --overwrite: {path}")

    with Image.open(source) as image:
        cleaned, key = clean_chroma(
            image,
            threshold=threshold,
            band_radius=band_radius,
            edge_only=edge_only,
            dominance_threshold=dominance_threshold,
        )
    background = parse_hex(spec["backgrounds"]["upscale"])
    gray = Image.new("RGBA", cleaned.size, (*background, 255))
    gray.alpha_composite(cleaned)

    cleaned.save(paths["subject"], "PNG", compress_level=9)
    gray.convert("RGB").save(paths["rgb"], "PNG", compress_level=9)
    cleaned.getchannel("A").save(paths["alpha"], "PNG", compress_level=9)
    metadata = {
        "input": str(source),
        "source_size": list(cleaned.size),
        "source_bbox": list(cleaned.getchannel("A").getbbox() or ()),
        "measured_key": [round(float(value), 3) for value in key],
        "edge_only": edge_only,
        "background": spec["backgrounds"]["upscale"],
    }
    paths["metadata"].write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return paths


def extract_upscaled(
    rgb_path: Path,
    alpha_path: Path,
    background: tuple[int, int, int],
) -> Image.Image:
    with Image.open(rgb_path) as source_rgb:
        rgb_image = source_rgb.convert("RGB")
    rgb = np.asarray(rgb_image, dtype=np.float32)
    with Image.open(alpha_path) as source_alpha:
        mask = source_alpha.convert("L").resize(rgb_image.size, Image.Resampling.LANCZOS)
    alpha = np.asarray(mask, dtype=np.float32) / 255.0
    alpha[alpha < 0.04] = 0.0
    alpha[alpha > 0.96] = 1.0

    key = np.array(background, dtype=np.float32)
    safe_alpha = np.maximum(alpha[..., None], 1.0 / 255.0)
    foreground = (rgb - ((1.0 - alpha[..., None]) * key)) / safe_alpha
    foreground = np.clip(foreground, 0.0, 255.0)
    final_alpha = np.round(alpha * 255.0).astype(np.uint8)
    foreground[final_alpha == 0] = 0
    rgba = np.dstack((foreground.astype(np.uint8), final_alpha))
    rgba[..., :3][final_alpha == 0] = 0
    return Image.fromarray(rgba, "RGBA")


def resize_premultiplied(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    rgba = np.asarray(image.convert("RGBA"), dtype=np.float32)
    alpha = rgba[..., 3:4] / 255.0
    premultiplied = np.concatenate((rgba[..., :3] * alpha, rgba[..., 3:4]), axis=2)
    source = Image.fromarray(np.clip(premultiplied, 0, 255).astype(np.uint8), "RGBA")
    resized = np.asarray(source.resize(size, Image.Resampling.LANCZOS), dtype=np.float32)
    resized_alpha = resized[..., 3:4] / 255.0
    rgb = np.zeros_like(resized[..., :3])
    np.divide(resized[..., :3], resized_alpha, out=rgb, where=resized_alpha > 0)
    result = np.concatenate((np.clip(rgb, 0, 255), resized[..., 3:4]), axis=2)
    result[resized[..., 3] == 0, :3] = 0
    return Image.fromarray(result.astype(np.uint8), "RGBA")


def place_geometry(
    image: Image.Image,
    category: str,
    spec: dict[str, Any],
    reference: Path | None,
) -> Image.Image:
    source_bbox = image.getchannel("A").getbbox()
    if source_bbox is None:
        raise ValueError("восстановленный alpha полностью пуст")
    visible = image.crop(source_bbox)

    if reference is not None:
        with Image.open(reference.expanduser().resolve()) as source_reference:
            reference_image = source_reference.convert("RGBA")
        reference_bbox = reference_image.getchannel("A").getbbox()
        if reference_bbox is None:
            raise ValueError("reference имеет пустой alpha")
        canvas_size = reference_image.size
        allowed_width = reference_bbox[2] - reference_bbox[0]
        allowed_height = reference_bbox[3] - reference_bbox[1]
        center_x = (reference_bbox[0] + reference_bbox[2]) / 2.0
        center_y = (reference_bbox[1] + reference_bbox[3]) / 2.0
    else:
        canvas = spec["canvas"]
        canvas_size = (int(canvas["width"]), int(canvas["height"]))
        rules = spec["categories"][category]
        outer = int(rules["outer_margin_min"])
        allowed_width = canvas_size[0] - (outer * 2)
        if "vertical_margin_min" in rules:
            vertical = int(rules["vertical_margin_min"])
            allowed_height = canvas_size[1] - (vertical * 2)
        else:
            allowed_height = canvas_size[1] - (outer * 2)
        center_x = canvas_size[0] / 2.0
        center_y = canvas_size[1] / 2.0

    scale = min(allowed_width / visible.width, allowed_height / visible.height)
    target_size = (
        max(1, round(visible.width * scale)),
        max(1, round(visible.height * scale)),
    )
    visible = resize_premultiplied(visible, target_size)
    x = round(center_x - (visible.width / 2.0))
    y = round(center_y - (visible.height / 2.0))
    canvas_image = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    canvas_image.alpha_composite(visible, (x, y))
    return canvas_image


def neutralize_edge_chroma(
    image: Image.Image,
    threshold: int,
    radius: int = 2,
) -> Image.Image:
    rgba = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
    rgb = rgba[..., :3].astype(np.int16)
    alpha = rgba[..., 3]
    visible = alpha > 0
    eroded = np.asarray(
        Image.fromarray(visible.astype(np.uint8) * 255, "L").filter(
            ImageFilter.MinFilter((radius * 2) + 1)
        )
    ) > 0
    boundary = visible & ~eroded
    magenta = np.minimum(rgb[..., 0], rgb[..., 2]) - rgb[..., 1]
    green = rgb[..., 1] - np.maximum(rgb[..., 0], rgb[..., 2])
    cyan = np.minimum(rgb[..., 1], rgb[..., 2]) - rgb[..., 0]
    blue = rgb[..., 2] - np.maximum(rgb[..., 0], rgb[..., 1])
    fringe = boundary & (
        (magenta >= threshold)
        | (green >= threshold)
        | (cyan >= threshold)
        | (blue >= threshold)
    )
    luminance = np.clip(
        (rgb[..., 0] * 54 + rgb[..., 1] * 183 + rgb[..., 2] * 19) // 256,
        0,
        255,
    ).astype(np.uint8)
    for channel in range(3):
        rgba[..., channel][fringe] = luminance[fringe]
    rgba[..., :3][alpha == 0] = 0
    return Image.fromarray(rgba, "RGBA")


def restore_file(
    rgb_path: Path,
    alpha_path: Path,
    output_path: Path,
    category: str,
    spec: dict[str, Any],
    reference: Path | None,
    keep_edge_color: bool,
    overwrite: bool,
) -> Path:
    rgb = rgb_path.expanduser().resolve()
    alpha = alpha_path.expanduser().resolve()
    if not rgb.is_file() or not alpha.is_file():
        raise ValueError("upscaled-rgb или alpha не найден")
    output = require_output(output_path, overwrite)
    background = parse_hex(spec["backgrounds"]["upscale"])
    restored = extract_upscaled(rgb, alpha, background)
    placed = place_geometry(restored, category, spec, reference)
    if not keep_edge_color:
        placed = neutralize_edge_chroma(
            placed,
            int(spec["fringe_dominance_threshold"]),
        )
    rgba = np.asarray(placed, dtype=np.uint8).copy()
    rgba[..., :3][rgba[..., 3] == 0] = 0
    Image.fromarray(rgba, "RGBA").save(output, "PNG", compress_level=9)
    return output


def parse_box(value: str) -> tuple[float, float, float, float]:
    try:
        numbers = tuple(float(item.strip()) for item in value.split(","))
    except ValueError as error:
        raise argparse.ArgumentTypeError("box должен быть x1,y1,x2,y2") from error
    if len(numbers) != 4 or not all(0.0 <= item <= 1.0 for item in numbers):
        raise argparse.ArgumentTypeError("box — четыре нормализованных числа от 0 до 1")
    x1, y1, x2, y2 = numbers
    if x1 >= x2 or y1 >= y2:
        raise argparse.ArgumentTypeError("box должен иметь положительную ширину и высоту")
    return numbers


def neutralize_region(
    input_path: Path,
    output_path: Path,
    box: tuple[float, float, float, float],
    saturation: int,
    max_luminance: int,
    overwrite: bool,
) -> Path:
    source = input_path.expanduser().resolve()
    if not source.is_file():
        raise ValueError(f"input не найден: {source}")
    output = require_output(output_path, overwrite)
    with Image.open(source) as image:
        rgba = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
    rgb = rgba[..., :3].astype(np.int16)
    alpha = rgba[..., 3]
    height, width = alpha.shape
    yy, xx = np.indices((height, width))
    x1, y1, x2, y2 = box
    region = (
        (xx >= round(width * x1))
        & (xx < round(width * x2))
        & (yy >= round(height * y1))
        & (yy < round(height * y2))
    )
    luminance = np.clip(
        (rgb[..., 0] * 54 + rgb[..., 1] * 183 + rgb[..., 2] * 19) // 256,
        0,
        255,
    )
    colored = (
        region
        & (alpha > 0)
        & ((rgb.max(axis=2) - rgb.min(axis=2)) >= saturation)
        & (luminance <= max_luminance)
    )
    neutral = luminance.astype(np.uint8)
    for channel in range(3):
        rgba[..., channel][colored] = neutral[colored]
    rgba[..., :3][alpha == 0] = 0
    Image.fromarray(rgba, "RGBA").save(output, "PNG", compress_level=9)
    print(f"Нейтрализовано пикселей в области: {int(colored.sum())}")
    return output


def add_prepare_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--work-dir", type=Path, required=True)
    parser.add_argument("--threshold", type=int)
    parser.add_argument("--band-radius", type=int)
    parser.add_argument("--dominance-threshold", type=float)
    parser.add_argument("--edge-only", action="store_true")
    parser.add_argument("--overwrite", action="store_true")


def add_restore_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument(
        "--category",
        required=True,
    )
    parser.add_argument("--reference", type=Path)
    parser.add_argument("--keep-edge-color", action="store_true")


def main() -> int:
    parser = argparse.ArgumentParser(description="Локальный RGBA-пайплайн бренд-ассета Nyx.")
    parser.add_argument("--spec", type=Path, default=default_spec_path())
    subparsers = parser.add_subparsers(dest="command", required=True)

    prepare = subparsers.add_parser("prepare", help="chroma -> RGBA, серый RGB и alpha")
    add_prepare_arguments(prepare)

    restore = subparsers.add_parser("restore", help="upscaled RGB + alpha -> финальный RGBA")
    restore.add_argument("--upscaled-rgb", type=Path, required=True)
    restore.add_argument("--alpha", type=Path, required=True)
    add_restore_arguments(restore)
    restore.add_argument("--overwrite", action="store_true")

    run = subparsers.add_parser("run", help="полный проход через внешний waifu2x")
    add_prepare_arguments(run)
    add_restore_arguments(run)
    run.add_argument("--waifu-bin", type=Path, required=True)
    run.add_argument("--models-dir", type=Path, required=True)
    run.add_argument("--noise-level", type=int, choices=(-1, 0, 1, 2, 3))
    run.add_argument("--scale", type=int, choices=(1, 2, 4, 8, 16, 32))

    region = subparsers.add_parser("neutralize-region", help="локальная цветная линия -> нейтраль")
    region.add_argument("--input", type=Path, required=True)
    region.add_argument("--output", type=Path, required=True)
    region.add_argument("--box", type=parse_box, required=True, help="x1,y1,x2,y2 в диапазоне 0..1")
    region.add_argument("--saturation", type=int)
    region.add_argument("--max-luminance", type=int)
    region.add_argument("--overwrite", action="store_true")

    args = parser.parse_args()
    load_runtime()
    try:
        spec = load_spec(args.spec)
        processing = spec["processing"]
        if hasattr(args, "threshold") and args.threshold is None:
            args.threshold = int(processing["chroma_distance_threshold"])
        if hasattr(args, "band_radius") and args.band_radius is None:
            args.band_radius = int(processing["band_radius"])
        if hasattr(args, "dominance_threshold") and args.dominance_threshold is None:
            args.dominance_threshold = float(processing["dominance_threshold"])
        if hasattr(args, "noise_level") and args.noise_level is None:
            args.noise_level = int(processing["noise_level"])
        if hasattr(args, "scale") and args.scale is None:
            args.scale = int(processing["scale"])
        if hasattr(args, "saturation") and args.saturation is None:
            args.saturation = int(processing["neutralize_saturation"])
        if hasattr(args, "max_luminance") and args.max_luminance is None:
            args.max_luminance = int(processing["neutralize_max_luminance"])
        if hasattr(args, "category") and args.category not in spec["categories"]:
            raise ValueError(f"неизвестная категория: {args.category}")
        if args.command == "prepare":
            paths = prepare_files(
                args.input,
                args.work_dir,
                spec,
                args.threshold,
                args.band_radius,
                args.dominance_threshold,
                args.edge_only,
                args.overwrite,
            )
            print("OK — подготовлено:", ", ".join(f"{key}={value}" for key, value in paths.items()))
        elif args.command == "restore":
            output = restore_file(
                args.upscaled_rgb,
                args.alpha,
                args.output,
                args.category,
                spec,
                args.reference,
                args.keep_edge_color,
                args.overwrite,
            )
            print(f"OK — восстановлен RGBA: {output}")
        elif args.command == "run":
            source = args.input.expanduser().resolve()
            if not source.is_file():
                raise ValueError(f"input не найден: {source}")
            final_output = args.output.expanduser().resolve()
            if final_output.exists() and not args.overwrite:
                raise ValueError(f"output уже существует; нужен --overwrite: {final_output}")
            waifu = args.waifu_bin.expanduser().resolve()
            models = args.models_dir.expanduser().resolve()
            if not waifu.is_file() or not os.access(waifu, os.X_OK):
                raise ValueError(f"waifu-bin не найден или не executable: {waifu}")
            if not models.is_dir():
                raise ValueError(f"models-dir не найден: {models}")
            work = ensure_temp_work_dir(args.work_dir)
            upscaled = work / f"{args.input.stem}-upscaled-rgb.png"
            if upscaled.exists() and not args.overwrite:
                raise ValueError(f"upscaled output уже существует; нужен --overwrite: {upscaled}")
            paths = prepare_files(
                args.input,
                work,
                spec,
                args.threshold,
                args.band_radius,
                args.dominance_threshold,
                args.edge_only,
                args.overwrite,
            )
            command = [
                str(waifu),
                "-i",
                str(paths["rgb"]),
                "-o",
                str(upscaled),
                "-n",
                str(args.noise_level),
                "-s",
                str(args.scale),
                "-m",
                str(models),
            ]
            subprocess.run(command, check=True)
            output = restore_file(
                upscaled,
                paths["alpha"],
                args.output,
                args.category,
                spec,
                args.reference,
                args.keep_edge_color,
                args.overwrite,
            )
            print(f"OK — полный проход завершён: {output}")
        else:
            output = neutralize_region(
                args.input,
                args.output,
                args.box,
                args.saturation,
                args.max_luminance,
                args.overwrite,
            )
            print(f"OK — локальная коррекция сохранена: {output}")
    except (OSError, ValueError, KeyError, json.JSONDecodeError, subprocess.CalledProcessError) as error:
        print(f"ОШИБКА: {error}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
