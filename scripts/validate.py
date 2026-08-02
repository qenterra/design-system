#!/usr/bin/env python3
"""Fail-closed validation for QenTerra Design System sources and outputs."""

from __future__ import annotations

import json
import math
import re
import sys
from dataclasses import dataclass
from html.parser import HTMLParser
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from lib.token_tools import flatten, get_path, load_json, resolve  # noqa: E402
from lib.markdown_renderer import split_numbered_sections  # noqa: E402


TOKEN_NAMES = ["foundation", "semantic", "typography", "motion", "components", "platforms", "products"]
PLACEHOLDERS = re.compile(r"\b(TBD|TODO|FIXME|PLACEHOLDER)\b|\?\?\?")
CSS_USED = re.compile(r"var\((--qds-[a-z0-9-]+)")
CSS_DEFINED = re.compile(r"(--qds-[a-z0-9-]+)\s*:")
TOKEN_REFERENCE = re.compile(r"^\{([^}]+)}$")


class ValidationError(Exception):
    """One or more design-system invariants failed."""


@dataclass
class HtmlRecord:
    path: Path
    language: str | None
    ids: set[str]
    duplicate_ids: set[str]
    links: list[tuple[str, str | None]]
    scripts: list[str]
    stylesheets: list[str]


class ReferenceParser(HTMLParser):
    def __init__(self, path: Path) -> None:
        super().__init__(convert_charrefs=True)
        self.path = path
        self.ids: set[str] = set()
        self.language: str | None = None
        self.duplicate_ids: set[str] = set()
        self.links: list[tuple[str, str | None]] = []
        self.scripts: list[str] = []
        self.stylesheets: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        if tag == "html":
            self.language = values.get("lang")
        identifier = values.get("id")
        if identifier:
            if identifier in self.ids:
                self.duplicate_ids.add(identifier)
            self.ids.add(identifier)
        if tag == "a" and values.get("href"):
            self.links.append((values["href"], values.get("aria-label")))
        if tag == "script" and values.get("src"):
            self.scripts.append(values["src"])
        if tag == "link" and values.get("rel") == "stylesheet" and values.get("href"):
            self.stylesheets.append(values["href"])

    def record(self) -> HtmlRecord:
        return HtmlRecord(
            self.path,
            self.language,
            self.ids,
            self.duplicate_ids,
            self.links,
            self.scripts,
            self.stylesheets,
        )


def parse_html(path: Path) -> HtmlRecord:
    parser = ReferenceParser(path)
    parser.feed(path.read_text(encoding="utf-8"))
    return parser.record()


def collect_references(value: Any, location: str = "") -> list[tuple[str, str]]:
    found: list[tuple[str, str]] = []
    if isinstance(value, dict):
        for key, child in value.items():
            found.extend(collect_references(child, f"{location}.{key}".strip(".")))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            found.extend(collect_references(child, f"{location}[{index}]"))
    elif isinstance(value, str):
        match = TOKEN_REFERENCE.match(value)
        if match:
            found.append((location, match.group(1)))
    return found


def has_reference(path: str, foundation: dict[str, Any], semantic: dict[str, Any]) -> bool:
    try:
        get_path(foundation, path)
        return True
    except KeyError:
        pass
    for mode in ("light", "dark"):
        try:
            get_path(semantic["modes"][mode], path)
            return True
        except KeyError:
            continue
    return False


def validate_token_data(version: str, tokens: dict[str, dict[str, Any]]) -> list[str]:
    errors: list[str] = []
    for name in TOKEN_NAMES:
        if name not in tokens:
            errors.append(f"Missing token file: {name}.json")
            continue
        data = tokens[name]
        meta = data.get("meta")
        if not isinstance(meta, dict):
            errors.append(f"{name}.json: missing meta object")
            continue
        for field in ("name", "version", "type", "description"):
            if not meta.get(field):
                errors.append(f"{name}.json: missing meta.{field}")
        if meta.get("version") != version:
            errors.append(f"{name}.json: version {meta.get('version')} does not match VERSION {version}")

    if errors or "foundation" not in tokens or "semantic" not in tokens:
        return errors

    foundation = tokens["foundation"]
    semantic = tokens["semantic"]
    required_foundation = ["color.graphite.950", "space.4", "radius.group", "size.controlStandard"]
    for path in required_foundation:
        try:
            get_path(foundation, path)
        except KeyError:
            errors.append(f"foundation.json: missing required token {path}")

    for name, data in tokens.items():
        for location, reference in collect_references(data):
            if not has_reference(reference, foundation, semantic):
                errors.append(f"{name}.json:{location}: unknown reference {{{reference}}}")

    light_keys = set(flatten(semantic["modes"]["light"]))
    dark_keys = set(flatten(semantic["modes"]["dark"]))
    if light_keys != dark_keys:
        errors.append(
            "semantic.json: Light/Dark key parity mismatch: "
            f"light-only={sorted(light_keys - dark_keys)}, dark-only={sorted(dark_keys - light_keys)}"
        )
    return errors


def color_channels(value: str) -> tuple[float, float, float]:
    if not re.fullmatch(r"#[0-9A-Fa-f]{6}", value):
        raise ValueError(f"Contrast validation requires a six-digit hex color, got {value}")
    return tuple(int(value[index : index + 2], 16) / 255 for index in (1, 3, 5))  # type: ignore[return-value]


def relative_luminance(value: str) -> float:
    channels = []
    for channel in color_channels(value):
        channels.append(channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4)
    return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]


def contrast_ratio(foreground: str, background: str) -> float:
    first, second = relative_luminance(foreground), relative_luminance(background)
    lighter, darker = max(first, second), min(first, second)
    return (lighter + 0.05) / (darker + 0.05)


def validate_contrast(tokens: dict[str, dict[str, Any]]) -> tuple[list[str], dict[str, float]]:
    errors: list[str] = []
    report: dict[str, float] = {}
    foundation = tokens["foundation"]
    semantic = tokens["semantic"]
    pairs = [
        ("text.primary", "surface.content", 4.5),
        ("text.secondary", "surface.content", 4.5),
        ("text.tertiary", "surface.content", 4.5),
        ("action.primaryContent", "action.primary", 4.5),
    ]
    for mode in ("light", "dark"):
        mapping = semantic["modes"][mode]
        for foreground_path, background_path, minimum in pairs:
            foreground = resolve(get_path(mapping, foreground_path), foundation)
            background = resolve(get_path(mapping, background_path), foundation)
            key = f"{mode}:{foreground_path}/{background_path}"
            try:
                ratio = contrast_ratio(foreground, background)
            except ValueError as error:
                errors.append(f"{key}: {error}")
                continue
            report[key] = round(ratio, 2)
            if ratio + 1e-9 < minimum:
                errors.append(f"{key}: contrast {ratio:.2f}:1 is below {minimum}:1")
    return errors, report


def validate_css(source_css: str, generated_css: str) -> list[str]:
    errors: list[str] = []
    defined = set(CSS_DEFINED.findall(generated_css)) | set(CSS_DEFINED.findall(source_css))
    used = set(CSS_USED.findall(source_css))
    missing = sorted(used - defined)
    if missing:
        errors.append(f"styles.css: undefined QDS variables: {', '.join(missing)}")
    if source_css.count("{") != source_css.count("}"):
        errors.append("styles.css: unbalanced braces")
    if "prefers-reduced-motion" not in source_css:
        errors.append("styles.css: missing Reduced Motion adaptation")
    if "focus-visible" not in source_css:
        errors.append("styles.css: missing focus-visible treatment")
    return errors


def validate_html_tree(dist: Path) -> list[str]:
    dist = dist.resolve()
    errors: list[str] = []
    records = {path.resolve(): parse_html(path) for path in sorted(dist.rglob("*.html"))}
    if not records:
        return ["dist: no HTML files"]

    for path, record in records.items():
        relative = path.relative_to(dist)
        if relative.parts and relative.parts[0] in {"en", "ru"} and record.language != relative.parts[0]:
            errors.append(f"{relative}: html lang must be {relative.parts[0]!r}, got {record.language!r}")
        if record.duplicate_ids:
            errors.append(f"{path.relative_to(dist)}: duplicate IDs {sorted(record.duplicate_ids)}")
        for href, _ in record.links:
            if href.startswith(("http://", "https://", "mailto:")):
                continue
            file_part, _, anchor = href.partition("#")
            target = path if not file_part else (path.parent / file_part).resolve()
            if not target.exists():
                errors.append(f"{path.relative_to(dist)}: broken link {href}")
                continue
            if anchor and target.suffix == ".html":
                target_record = records.get(target) or parse_html(target)
                if anchor not in target_record.ids:
                    errors.append(f"{path.relative_to(dist)}: missing anchor {href}")
        for asset in [*record.scripts, *record.stylesheets]:
            if asset.startswith(("http://", "https://")):
                continue
            target = (path.parent / asset).resolve()
            if not target.exists():
                errors.append(f"{path.relative_to(dist)}: missing asset {asset}")

    for locale, standalone in [
        ("en", dist / "en" / "qenterra-design-system.html"),
        ("ru", dist / "ru" / "qenterra-design-system.html"),
        ("en", dist / "qenterra-design-system.html"),
    ]:
        label = standalone.relative_to(dist)
        if not standalone.exists():
            errors.append(f"dist: missing {label}")
            continue
        record = records[standalone.resolve()]
        required = {f"section-{number}" for number in range(22)}
        missing = sorted(required - record.ids)
        if missing:
            errors.append(f"{label}: missing sections {missing}")
        text = standalone.read_text(encoding="utf-8")
        if 'src="' in text or 'rel="stylesheet"' in text:
            errors.append(f"{label}: external script or stylesheet reference found")
        if len(text.encode("utf-8")) < 100_000:
            errors.append(f"{label}: unexpectedly small; full reference may be missing")

    indexes: dict[str, list[dict[str, Any]]] = {}
    for locale in ("en", "ru"):
        path = dist / "assets" / f"search-index-{locale}.json"
        if not path.is_file():
            errors.append(f"dist: missing assets/search-index-{locale}.json")
            continue
        indexes[locale] = json.loads(path.read_text(encoding="utf-8"))
        sections = [item.get("section") for item in indexes[locale]]
        if sections != list(range(22)):
            errors.append(f"assets/search-index-{locale}.json: expected sections 0–21, got {sections}")
    if set(indexes) == {"en", "ru"}:
        if len(indexes["en"]) != len(indexes["ru"]):
            errors.append("localized search indexes have different entry counts")
        if [item.get("title") for item in indexes["en"]] == [item.get("title") for item in indexes["ru"]]:
            errors.append("Russian search index is not localized")
    return errors


def validate_localized_sources(root: Path) -> list[str]:
    errors: list[str] = []
    sections_by_locale: dict[str, list[int]] = {}
    for locale, filename in (("en", "MASTER.md"), ("ru", "MASTER.ru.md")):
        path = root / "docs" / filename
        if not path.is_file():
            errors.append(f"docs/{filename}: missing localized master")
            continue
        _, sections = split_numbered_sections(path.read_text(encoding="utf-8"))
        sections_by_locale[locale] = [section.number for section in sections]
        if sections_by_locale[locale] != list(range(22)):
            errors.append(f"docs/{filename}: expected numbered sections 0–21, got {sections_by_locale[locale]}")
    if set(sections_by_locale) == {"en", "ru"} and sections_by_locale["en"] != sections_by_locale["ru"]:
        errors.append("English and Russian master section order differs")
    for filename in ("COMPONENT_CATALOG.md", "COMPONENT_CATALOG.ru.md"):
        if not (root / "docs" / filename).is_file():
            errors.append(f"docs/{filename}: missing localized component catalog")
    return errors


def validate_repository_hygiene(root: Path) -> list[str]:
    errors: list[str] = []
    for relative in (Path(".superpowers"), Path("docs/superpowers")):
        if (root / relative).exists():
            errors.append(f"{relative}: AI working directory must stay outside the repository")
    return errors


def validate_placeholders(root: Path) -> list[str]:
    errors: list[str] = []
    scan_roots = [root / "docs", root / "tokens", root / "src", root / "dist", root / "generated", root / "output"]
    for scan_root in scan_roots:
        for path in scan_root.rglob("*"):
            if not path.is_file() or path.suffix not in {".md", ".html", ".css", ".js", ".json", ".swift"}:
                continue
            match = PLACEHOLDERS.search(path.read_text(encoding="utf-8"))
            if match:
                errors.append(f"{path.relative_to(root)}: placeholder {match.group(0)}")
    return errors


def validate_browser_evidence(root: Path) -> list[str]:
    errors: list[str] = []
    report_path = root / "output" / "reports" / "browser.json"
    if not report_path.is_file():
        return ["output/reports/browser.json: missing visual browser evidence"]
    try:
        report = json.loads(report_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        return [f"output/reports/browser.json: invalid JSON: {error}"]
    if report.get("status") != "passed":
        errors.append("output/reports/browser.json: status is not passed")
    captures = report.get("captures")
    if not isinstance(captures, list) or len(captures) < 6:
        errors.append("output/reports/browser.json: expected at least six localized responsive/appearance captures")
        return errors
    for capture in captures:
        name = capture.get("name") if isinstance(capture, dict) else None
        path = root / "output" / "screenshots" / f"{name}.png"
        if not name or not path.is_file() or path.stat().st_size < 10_000:
            errors.append(f"visual evidence missing or too small: {name!r}")
    checks = report.get("checks", {})
    for name in ("scrollSpy", "languageSwitch", "uniformSvgIcons"):
        if checks.get(name) != "passed":
            errors.append(f"output/reports/browser.json: {name} did not pass")
    return errors


def run(root: Path = ROOT) -> dict[str, Any]:
    version = (root / "VERSION").read_text(encoding="utf-8").strip()
    tokens = {name: load_json(root / "tokens" / f"{name}.json") for name in TOKEN_NAMES}
    errors = validate_token_data(version, tokens)
    contrast_errors, contrast = validate_contrast(tokens)
    errors.extend(contrast_errors)
    errors.extend(
        validate_css(
            (root / "src" / "assets" / "styles.css").read_text(encoding="utf-8"),
            (root / "generated" / "qds-tokens.css").read_text(encoding="utf-8"),
        )
    )
    errors.extend(validate_html_tree(root / "dist"))
    errors.extend(validate_localized_sources(root))
    errors.extend(validate_repository_hygiene(root))
    errors.extend(validate_placeholders(root))
    errors.extend(validate_browser_evidence(root))
    result = {"version": version, "errors": errors, "contrast": contrast}
    if errors:
        raise ValidationError("\n".join(f"- {error}" for error in errors))
    return result


def main() -> int:
    try:
        result = run()
    except (OSError, json.JSONDecodeError, ValidationError, KeyError, ValueError) as error:
        print("QDS validation failed:", file=sys.stderr)
        print(error, file=sys.stderr)
        return 1
    print(f"QDS validation passed for {result['version']}")
    print(f"  Contrast pairs: {len(result['contrast'])}")
    print(f"  HTML files: {len(list((ROOT / 'dist').rglob('*.html')))}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
