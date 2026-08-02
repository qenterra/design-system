#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Проверяет универсальные PNG-ассеты Nyx без изменения файлов.

Запуск из корня design-system:
    python3 "scripts/brand/validate_nyx_assets.py"
    python3 "scripts/brand/validate_nyx_assets.py" \
      --dir "/путь/к/character-assets" \
      --manifest "/private/tmp/nyx-batch.json" \
      --report-json "/private/tmp/nyx-report.json"

Без манифеста проверяются все PNG четырёх категорий. С манифестом проверяются
только объявленные пути, а счётчики всей коллекции всё равно попадают в отчёт.
Код выхода: 0 — ошибок нет, 1 — нарушен инвариант, 2 — нет runtime-зависимостей.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from itertools import combinations
from pathlib import Path, PurePosixPath
from typing import Any


def load_runtime() -> None:
    global Image, ImageFilter, np
    try:
        import numpy as np
        from PIL import Image, ImageFilter
    except ModuleNotFoundError as error:
        print(
            "ОШИБКА: нужен Python с Pillow и NumPy; используйте настроенное окружение "
            f"или установите зависимости ({error}).",
            file=sys.stderr,
        )
        raise SystemExit(2)

TITLE_CASE_RE = re.compile(r"^[A-Z][A-Za-z0-9]*(?: [A-Z][A-Za-z0-9]*)*$")
TECHNICAL_TOKEN_RE = re.compile(
    r"(?:^| )(?:final|fixed|upscaled|generated|backup|v[0-9]+|[0-9]{4}-[0-9]{2}-[0-9]{2})(?: |$)",
    re.IGNORECASE,
)


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


def load_spec(path: Path) -> dict[str, Any]:
    try:
        spec = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"не удалось прочитать spec {path}: {error}") from error
    required = {
        "canvas",
        "categories",
        "fringe_dominance_threshold",
        "processing",
        "silhouette_duplicate_threshold",
    }
    missing = required - set(spec)
    if missing:
        raise ValueError("в spec нет ключей: " + ", ".join(sorted(missing)))
    if not isinstance(spec["categories"], dict) or not spec["categories"]:
        raise ValueError("spec.categories должен быть непустым объектом")
    for category, rules in spec["categories"].items():
        if not isinstance(category, str) or not isinstance(rules, dict):
            raise ValueError("spec.categories содержит невалидную категорию")
        if "outer_margin_min" not in rules:
            raise ValueError(f"в spec.categories.{category} нет outer_margin_min")
    processing = spec["processing"]
    required_processing = {
        "band_radius",
        "chroma_distance_threshold",
        "dominance_threshold",
        "neutralize_max_luminance",
        "neutralize_saturation",
        "noise_level",
        "scale",
    }
    if not isinstance(processing, dict) or required_processing - set(processing):
        raise ValueError("spec.processing неполон")
    return spec


def normalize_manifest_path(raw: str, categories: set[str]) -> tuple[str | None, str | None]:
    path = PurePosixPath(raw)
    if path.is_absolute() or ".." in path.parts or len(path.parts) != 2:
        return None, f"нужен относительный путь «Категория/Имя.png»: {raw!r}"
    category, filename = path.parts
    if category not in categories:
        return None, f"неизвестная категория {category!r}: {raw!r}"
    if PurePosixPath(filename).suffix.lower() != ".png":
        return None, f"ожидался PNG: {raw!r}"
    return path.as_posix(), None


def load_manifest(path: Path, categories: set[str]) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [], [f"манифест не читается: {error}"]
    raw_assets = data.get("assets") if isinstance(data, dict) else None
    if not isinstance(raw_assets, list) or not raw_assets:
        return [], ["манифест должен содержать непустой массив assets"]

    paths: list[str] = []
    for index, entry in enumerate(raw_assets, 1):
        if isinstance(entry, str):
            raw_path = entry
        elif isinstance(entry, dict) and isinstance(entry.get("path"), str):
            raw_path = entry["path"]
        else:
            errors.append(f"assets[{index}]: нужен string либо объект с полем path")
            continue
        normalized, error = normalize_manifest_path(raw_path, categories)
        if error:
            errors.append(f"assets[{index}]: {error}")
        elif normalized is not None:
            paths.append(normalized)

    duplicates = sorted({item for item in paths if paths.count(item) > 1})
    if duplicates:
        errors.append("дубли путей в манифесте: " + ", ".join(duplicates))
    basenames = [PurePosixPath(item).name.casefold() for item in paths]
    duplicate_names = sorted({item for item in basenames if basenames.count(item) > 1})
    if duplicate_names:
        errors.append("имена файлов не уникальны между категориями: " + ", ".join(duplicate_names))
    return paths, errors


def validate_collection_structure(target: Path, categories: set[str]) -> list[str]:
    """Проверяет, что character-assets содержит только канонические папки и PNG."""
    errors: list[str] = []
    for entry in sorted(target.iterdir(), key=lambda item: item.name.casefold()):
        if entry.name not in categories:
            errors.append(f"лишний объект в корне character-assets: {entry.name}")
    for category in sorted(categories):
        directory = target / category
        if not directory.is_dir():
            errors.append(f"нет обязательной категории: {category}")
            continue
        for entry in sorted(directory.rglob("*")):
            relative = entry.relative_to(target).as_posix()
            if entry.is_dir():
                errors.append(f"в категории запрещена вложенная папка: {relative}")
            elif entry.parent != directory or entry.suffix.lower() != ".png":
                errors.append(f"в категории разрешены только PNG верхнего уровня: {relative}")
    return errors


def boundary_mask(alpha: np.ndarray, radius: int = 2) -> np.ndarray:
    visible = alpha > 0
    kernel = (radius * 2) + 1
    eroded = np.asarray(
        Image.fromarray(visible.astype(np.uint8) * 255, "L").filter(
            ImageFilter.MinFilter(kernel)
        )
    ) > 0
    return visible & ~eroded


def silhouette(alpha_image: Image.Image) -> np.ndarray:
    return np.asarray(
        alpha_image.resize((128, 128), Image.Resampling.BILINEAR),
        dtype=np.float32,
    ) / 255.0


def validate_png(
    path: Path,
    relative: str,
    spec: dict[str, Any],
) -> tuple[dict[str, Any], list[str]]:
    errors: list[str] = []
    category = PurePosixPath(relative).parts[0]
    stem = path.stem
    if not TITLE_CASE_RE.fullmatch(stem):
        errors.append(f"{relative}: имя должно быть английским Title Case")
    if TECHNICAL_TOKEN_RE.search(stem):
        errors.append(f"{relative}: технический суффикс запрещён")

    try:
        image = Image.open(path)
        image.load()
    except (OSError, ValueError) as error:
        return {"path": relative}, [f"{relative}: PNG не читается: {error}"]

    canvas = spec["canvas"]
    expected_size = (int(canvas["width"]), int(canvas["height"]))
    if image.format != "PNG":
        errors.append(f"{relative}: формат {image.format}, нужен PNG")
    if image.size != expected_size:
        errors.append(
            f"{relative}: размер {image.width}×{image.height}, "
            f"нужен {expected_size[0]}×{expected_size[1]}"
        )
    if image.mode != canvas["mode"]:
        errors.append(f"{relative}: режим {image.mode}, нужен {canvas['mode']}")

    rgba_image = image.convert("RGBA")
    rgba = np.asarray(rgba_image, dtype=np.uint8)
    alpha = rgba[..., 3]
    perimeter_max = int(
        max(
            alpha[0, :].max(initial=0),
            alpha[-1, :].max(initial=0),
            alpha[:, 0].max(initial=0),
            alpha[:, -1].max(initial=0),
        )
    )
    if perimeter_max:
        errors.append(f"{relative}: alpha касается внешнего периметра ({perimeter_max})")

    transparent = alpha == 0
    hidden_rgb_max = int(rgba[..., :3][transparent].max(initial=0))
    if hidden_rgb_max:
        errors.append(f"{relative}: RGB в полностью прозрачных пикселях не обнулён")

    bbox = rgba_image.getchannel("A").getbbox()
    margins: dict[str, int] | None = None
    if bbox is None:
        errors.append(f"{relative}: alpha полностью пуст")
    else:
        left, top, right, bottom = bbox
        margins = {
            "left": left,
            "top": top,
            "right": expected_size[0] - right,
            "bottom": expected_size[1] - bottom,
        }
        rules = spec["categories"][category]
        outer_min = int(rules["outer_margin_min"])
        if min(margins.values()) < outer_min:
            errors.append(
                f"{relative}: минимальный внешний отступ {min(margins.values())}, "
                f"нужно не меньше {outer_min}"
            )
        if "vertical_margin_min" in rules:
            vertical_min = int(rules["vertical_margin_min"])
            actual = min(margins["top"], margins["bottom"])
            if actual < vertical_min:
                errors.append(
                    f"{relative}: вертикальный отступ {actual}, "
                    f"нужно не меньше {vertical_min}"
                )

    rgb = rgba[..., :3].astype(np.int16)
    boundary = boundary_mask(alpha)
    threshold = int(spec["fringe_dominance_threshold"])
    magenta = np.minimum(rgb[..., 0], rgb[..., 2]) - rgb[..., 1]
    green = rgb[..., 1] - np.maximum(rgb[..., 0], rgb[..., 2])
    cyan = np.minimum(rgb[..., 1], rgb[..., 2]) - rgb[..., 0]
    blue = rgb[..., 2] - np.maximum(rgb[..., 0], rgb[..., 1])
    fringe_candidates = int(
        (
            boundary
            & (
                (magenta > threshold)
                | (green > threshold)
                | (cyan > threshold)
                | (blue > threshold)
            )
        ).sum()
    )

    record = {
        "path": relative,
        "format": image.format,
        "size": list(image.size),
        "mode": image.mode,
        "bbox": list(bbox) if bbox else None,
        "margins": margins,
        "perimeter_alpha_max": perimeter_max,
        "hidden_rgb_max": hidden_rgb_max,
        "boundary_fringe_candidates": fringe_candidates,
        "_silhouette": silhouette(rgba_image.getchannel("A")),
    }
    return record, errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Проверка универсальных PNG-ассетов Nyx.")
    parser.add_argument("--dir", type=Path, default=default_asset_dir(), help="корень character-assets")
    parser.add_argument("--manifest", type=Path, help="JSON-манифест проверяемой пачки")
    parser.add_argument("--report-json", type=Path, help="куда записать подробный JSON-отчёт")
    parser.add_argument("--spec", type=Path, default=default_spec_path(), help="технический spec")
    args = parser.parse_args()
    load_runtime()

    target = args.dir.expanduser().resolve()
    if not target.is_dir():
        print(f"ОШИБКА: папка не найдена: {target}")
        return 1
    if args.report_json and is_inside(args.report_json.expanduser(), repository_root()):
        print("ОШИБКА: QA-отчёт нельзя записывать внутрь design-system")
        return 1

    try:
        spec = load_spec(args.spec.expanduser().resolve())
    except ValueError as error:
        print(f"ОШИБКА: {error}")
        return 1
    categories = set(spec["categories"])

    errors = validate_collection_structure(target, categories)
    if args.manifest:
        relative_paths, manifest_errors = load_manifest(
            args.manifest.expanduser().resolve(),
            categories,
        )
        errors.extend(manifest_errors)
    else:
        relative_paths = []
        for category in spec["categories"]:
            relative_paths.extend(
                path.relative_to(target).as_posix()
                for path in sorted((target / category).glob("*.png"))
            )
        if not relative_paths:
            errors.append("не найдено ни одного PNG в известных категориях")

    records: list[dict[str, Any]] = []
    for relative in relative_paths:
        path = target / PurePosixPath(relative)
        if not path.is_file():
            errors.append(f"{relative}: файл из манифеста не найден")
            continue
        record, file_errors = validate_png(path, relative, spec)
        records.append(record)
        errors.extend(file_errors)

    similarities: list[dict[str, Any]] = []
    duplicate_threshold = float(spec["silhouette_duplicate_threshold"])
    allowed_pairs = {
        frozenset((str(item["first"]), str(item["second"])))
        for item in spec.get("allowed_silhouette_pairs", [])
        if isinstance(item, dict) and item.get("first") and item.get("second")
    }
    for first, second in combinations(records, 2):
        a = first["_silhouette"]
        b = second["_silhouette"]
        denominator = float(np.linalg.norm(a) * np.linalg.norm(b))
        score = float((a * b).sum() / denominator) if denominator else 0.0
        similarities.append(
            {"score": score, "first": first["path"], "second": second["path"]}
        )
        pair = frozenset((first["path"], second["path"]))
        if score >= duplicate_threshold and pair not in allowed_pairs:
            errors.append(
                f"почти одинаковые alpha-силуэты: {first['path']} / "
                f"{second['path']} ({score:.4f})"
            )
    similarities.sort(key=lambda item: item["score"], reverse=True)

    collection_counts = {
        category: len(list((target / category).glob("*.png")))
        for category in spec["categories"]
    }
    for record in records:
        record.pop("_silhouette", None)
    report = {
        "target": str(target),
        "manifest": str(args.manifest.expanduser().resolve()) if args.manifest else None,
        "checked": len(records),
        "collection_counts": collection_counts,
        "collection_total": sum(collection_counts.values()),
        "failures": errors,
        "top_silhouette_similarities": similarities[:15],
        "allowed_silhouette_pairs": [sorted(pair) for pair in allowed_pairs],
        "files": records,
    }

    if args.report_json:
        output = args.report_json.expanduser().resolve()
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

    print(
        f"Проверено: {len(records)} PNG. Коллекция: "
        + ", ".join(f"{key}={value}" for key, value in collection_counts.items())
        + f"; всего={report['collection_total']}."
    )
    fringe_top = sorted(
        records,
        key=lambda item: int(item["boundary_fringe_candidates"]),
        reverse=True,
    )[:5]
    if fringe_top and int(fringe_top[0]["boundary_fringe_candidates"]):
        print(
            "Кандидаты на цветную кайму: "
            + ", ".join(
                f"{item['path']}={item['boundary_fringe_candidates']}"
                for item in fringe_top
            )
            + " (это сигнал для визуального просмотра, не автоматический брак)."
        )
    if errors:
        for error in errors:
            print("ОШИБКА:", error)
        return 1
    print("OK — пути, имена, PNG/RGBA, alpha, скрытый RGB, отступы и силуэты корректны.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
