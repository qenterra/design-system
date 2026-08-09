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

from lib.token_tools import flatten, generate_svg_sprite, generate_swift_icons, get_path, load_json, resolve  # noqa: E402
from lib.schema_tools import validate_schema  # noqa: E402
from lib.figma_export import generate_figma_exports  # noqa: E402
from lib.email_templates import validate_email_registry  # noqa: E402
from lib.markdown_renderer import split_numbered_sections  # noqa: E402
from lib.site_locales import BRAND_SECTION_KEYS, PAGE_GROUPS, REPOSITORY_SECTION_KEYS  # noqa: E402
from brand.validate_brand_assets import validate_brand_assets  # noqa: E402


TOKEN_NAMES = ["foundation", "semantic", "typography", "motion", "components", "platforms", "products"]
PLACEHOLDERS = re.compile(r"\b(TBD|TODO|FIXME|PLACEHOLDER)\b|\?\?\?")
CSS_USED = re.compile(r"var\((--qds-[a-z0-9-]+)")
CSS_DEFINED = re.compile(r"(--qds-[a-z0-9-]+)\s*:")
TOKEN_REFERENCE = re.compile(r"^\{([^}]+)}$")
MARKDOWN_LINK = re.compile(r"\[[^]]+]\(([^)]+)\)")
BRAND_DOC_PAIRS = ("MASTER", "QENTERRA", "NYX", "ASSET_CATALOG")
BRAND_TEMPLATES = {
    "brand-asset-brief.md",
    "manifest.example.json",
    "nyx-character-asset.md",
    "nyx-sticker-fix.md",
    "nyx-sticker-pack.md",
    "nyx-sticker.md",
    "nyx-wallpaper.md",
    "release-checklist.md",
}


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


def validate_token_schemas(root: Path, tokens: dict[str, dict[str, Any]]) -> list[str]:
    errors: list[str] = []
    schema_root = (root / "schemas").resolve()
    for name, data in tokens.items():
        reference = data.get("$schema")
        if not isinstance(reference, str):
            errors.append(f"{name}.json:$schema: missing focused schema reference")
            continue
        schema_path = (root / "tokens" / reference).resolve()
        if schema_root not in schema_path.parents or not schema_path.is_file():
            errors.append(f"{name}.json:$schema: invalid local schema {reference!r}")
            continue
        schema = load_json(schema_path)
        errors.extend(
            f"{name}.json:{error}" for error in validate_schema(data, schema, schema_path)
        )
    return errors


def resolved_reference_value(
    path: str,
    foundation: dict[str, Any],
    semantic: dict[str, Any],
    *,
    mode: str = "light",
    chain: tuple[str, ...] = (),
) -> Any:
    if path in chain:
        raise ValueError(f"reference cycle {' -> '.join((*chain, path))}")
    try:
        value = get_path(foundation, path)
    except KeyError:
        value = get_path(semantic["modes"][mode], path)
    if isinstance(value, str):
        match = TOKEN_REFERENCE.match(value)
        if match:
            return resolved_reference_value(
                match.group(1), foundation, semantic, mode=mode, chain=(*chain, path)
            )
    return value


def validate_component_metrics(components: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    exceptions = components.get("extensions", {}).get("rawMetricExceptions", {})
    if not isinstance(exceptions, dict):
        return ["components.json:extensions.rawMetricExceptions must be an object"]
    values = flatten(
        {key: value for key, value in components.items() if key not in {"$schema", "meta", "extensions"}}
    )
    raw_metrics = {
        path for path, value in values.items() if isinstance(value, (int, float)) and not isinstance(value, bool)
    }
    for path in sorted(raw_metrics - set(exceptions)):
        errors.append(
            f"components.json:{path}: raw component metric requires a foundation reference or documented exception"
        )
    for path in sorted(set(exceptions) - raw_metrics):
        errors.append(f"components.json:extensions.rawMetricExceptions.{path}: exception does not name a raw metric")
    return errors


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
                continue
            for mode in ("light", "dark"):
                try:
                    value = resolved_reference_value(reference, foundation, semantic, mode=mode)
                except (KeyError, ValueError) as error:
                    errors.append(f"{name}.json:{location}: {error}")
                    break
                if name == "components" and not isinstance(value, (int, float)):
                    errors.append(
                        f"components.json:{location}: metric reference {{{reference}}} resolves to {type(value).__name__}"
                    )
                    break

    light_keys = set(flatten(semantic["modes"]["light"]))
    dark_keys = set(flatten(semantic["modes"]["dark"]))
    if light_keys != dark_keys:
        errors.append(
            "semantic.json: Light/Dark key parity mismatch: "
            f"light-only={sorted(light_keys - dark_keys)}, dark-only={sorted(dark_keys - light_keys)}"
        )
    if "components" in tokens:
        errors.extend(validate_component_metrics(tokens["components"]))
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
        required.update(f"brand-{key}" for key in BRAND_SECTION_KEYS)
        required.update(f"repository-{key}" for key in REPOSITORY_SECTION_KEYS)
        required.add("lab-overview")
        required.add("adoption-overview")
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
        numeric_sections = [item.get("section") for item in indexes[locale] if isinstance(item.get("section"), int)]
        if numeric_sections != list(range(22)):
            errors.append(
                f"assets/search-index-{locale}.json: expected numbered sections 0–21, got {numeric_sections}"
            )
        brand_anchors = [
            item.get("anchor") for item in indexes[locale] if str(item.get("section", "")).startswith("B")
        ]
        expected_brand_anchors = [f"brand-{key}" for key in BRAND_SECTION_KEYS]
        if brand_anchors != expected_brand_anchors:
            errors.append(f"assets/search-index-{locale}.json: brand anchors differ: {brand_anchors}")
        repository_anchors = [
            item.get("anchor") for item in indexes[locale] if str(item.get("section", "")).startswith("R")
        ]
        expected_anchors = [f"repository-{key}" for key in REPOSITORY_SECTION_KEYS]
        if repository_anchors != expected_anchors:
            errors.append(
                f"assets/search-index-{locale}.json: repository anchors differ: {repository_anchors}"
            )
    if set(indexes) == {"en", "ru"}:
        if len(indexes["en"]) != len(indexes["ru"]):
            errors.append("localized search indexes have different entry counts")
        if [item.get("title") for item in indexes["en"]] == [item.get("title") for item in indexes["ru"]]:
            errors.append("Russian search index is not localized")
    return errors


def validate_localized_sources(root: Path) -> list[str]:
    errors: list[str] = []
    sections_by_locale: dict[str, list[int]] = {}
    version_path = root / "VERSION"
    expected_version = version_path.read_text(encoding="utf-8").strip() if version_path.is_file() else None
    for locale, filename in (("en", "MASTER.md"), ("ru", "MASTER.ru.md")):
        path = root / "docs" / filename
        if not path.is_file():
            errors.append(f"docs/{filename}: missing localized master")
            continue
        text = path.read_text(encoding="utf-8")
        if expected_version:
            prefix = "Version" if locale == "en" else "Версия"
            match = re.search(rf"^{prefix}\s+(\d+\.\d+\.\d+)\b", text, flags=re.MULTILINE)
            if match is None:
                errors.append(f"docs/{filename}: missing normative version header")
            elif match.group(1) != expected_version:
                errors.append(
                    f"docs/{filename}: version {match.group(1)} does not match VERSION {expected_version}"
                )
        _, sections = split_numbered_sections(text)
        sections_by_locale[locale] = [section.number for section in sections]
        if sections_by_locale[locale] != list(range(22)):
            errors.append(f"docs/{filename}: expected numbered sections 0–21, got {sections_by_locale[locale]}")
    if set(sections_by_locale) == {"en", "ru"} and sections_by_locale["en"] != sections_by_locale["ru"]:
        errors.append("English and Russian master section order differs")
    for filename in ("COMPONENT_CATALOG.md", "COMPONENT_CATALOG.ru.md"):
        if not (root / "docs" / filename).is_file():
            errors.append(f"docs/{filename}: missing localized component catalog")
    for filename in ("CONSUMER_ADOPTION.md", "CONSUMER_ADOPTION.ru.md"):
        if not (root / "docs" / filename).is_file():
            errors.append(f"docs/{filename}: missing localized consumer adoption guide")
    repository_headings: dict[str, list[str]] = {}
    for locale, filename in (("en", "STANDARD.md"), ("ru", "STANDARD.ru.md")):
        path = root / "docs" / "repository" / filename
        if not path.is_file():
            errors.append(f"docs/repository/{filename}: missing localized repository standard")
            continue
        text = path.read_text(encoding="utf-8")
        repository_headings[locale] = re.findall(r"^##\s+(.+)$", text, flags=re.MULTILINE)
        if len(repository_headings[locale]) != len(REPOSITORY_SECTION_KEYS) - 1:
            errors.append(
                f"docs/repository/{filename}: expected {len(REPOSITORY_SECTION_KEYS) - 1} H2 sections, "
                f"got {len(repository_headings[locale])}"
            )
    if set(repository_headings) == {"en", "ru"} and len(repository_headings["en"]) != len(
        repository_headings["ru"]
    ):
        errors.append("English and Russian repository standard section counts differ")
    return errors


def validate_packages(root: Path, version: str) -> list[str]:
    errors: list[str] = []
    css_root = root / "packages" / "css"
    swift_root = root / "packages" / "swift"
    manifest_path = css_root / "package.json"
    if not manifest_path.is_file():
        errors.append("packages/css/package.json: missing local CSS package manifest")
    else:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        if manifest.get("version") != version:
            errors.append(f"packages/css/package.json: version {manifest.get('version')} does not match VERSION {version}")
        if manifest.get("private") is not True:
            errors.append("packages/css/package.json: local package must remain private")
        for exported in ("tokens.css", "tokens.json", "recipes.css", "icons.json"):
            if not (css_root / exported).is_file():
                errors.append(f"packages/css/{exported}: missing generated package export")
    if not (swift_root / "Package.swift").is_file():
        errors.append("packages/swift/Package.swift: missing SwiftPM manifest")
    swift_generated = swift_root / "Sources" / "QenTerraDesignTokens" / "QDSGeneratedTokens.swift"
    if not swift_generated.is_file():
        errors.append("packages/swift: missing generated Swift source")
    elif swift_generated.read_bytes() != (root / "generated" / "QDSGeneratedTokens.swift").read_bytes():
        errors.append("packages/swift: generated Swift source drifted from canonical adapter")
    swift_icons = swift_root / "Sources" / "QenTerraDesignTokens" / "QDSGeneratedIcons.swift"
    if not swift_icons.is_file() or swift_icons.read_bytes() != (root / "generated" / "QDSGeneratedIcons.swift").read_bytes():
        errors.append("packages/swift: generated icon identifiers drifted from canonical registry")
    css_generated = css_root / "tokens.css"
    if css_generated.is_file() and css_generated.read_bytes() != (root / "generated" / "qds-tokens.css").read_bytes():
        errors.append("packages/css: generated stylesheet drifted from canonical adapter")
    recipes = css_root / "recipes.css"
    recipe_source = root / "src" / "assets" / "recipes.css"
    if recipes.is_file() and recipe_source.is_file() and recipes.read_bytes() != recipe_source.read_bytes():
        errors.append("packages/css: component recipes drifted from canonical source")
    return errors


def validate_repository_hygiene(root: Path) -> list[str]:
    errors: list[str] = []
    forbidden_parts = {"superpowers", "contact-sheets", "brand-working"}
    for path in root.rglob("*"):
        if ".git" in path.relative_to(root).parts:
            continue
        relative = path.relative_to(root)
        if any(part.lower() in forbidden_parts for part in relative.parts):
            errors.append(f"{relative}: temporary or AI working path must stay outside the repository")
        if path.name == ".DS_Store":
            errors.append(f"{relative}: Finder metadata must not enter the repository")
    universal_sources = [
        root / "README.md",
        root / "docs" / "MASTER.md",
        root / "docs" / "MASTER.ru.md",
        root / "docs" / "COMPONENT_CATALOG.md",
        root / "docs" / "COMPONENT_CATALOG.ru.md",
        root / "tokens" / "products.json",
        root / "scripts" / "lib" / "site_locales.py",
        root / "scripts" / "build.py",
    ]
    product_names = re.compile(r"\b(Cadence|Unspool|Lilt)\b")
    for path in universal_sources:
        if path.is_file() and product_names.search(path.read_text(encoding="utf-8")):
            errors.append(f"{path.relative_to(root)}: universal guide contains an existing product name")
    return errors


def validate_brand_sources(root: Path) -> list[str]:
    errors: list[str] = []
    brand_docs = root / "docs" / "brand"
    for stem in BRAND_DOC_PAIRS:
        english = brand_docs / f"{stem}.md"
        russian = brand_docs / f"{stem}.ru.md"
        for path in (english, russian):
            if not path.is_file():
                errors.append(f"{path.relative_to(root)}: missing brand reference")
        if english.is_file() and russian.is_file():
            english_headings = len(re.findall(r"^#{1,3} ", english.read_text(encoding="utf-8"), re.MULTILINE))
            russian_headings = len(re.findall(r"^#{1,3} ", russian.read_text(encoding="utf-8"), re.MULTILINE))
            if english_headings != russian_headings:
                errors.append(
                    f"docs/brand/{stem}: localized heading counts differ "
                    f"({english_headings} vs {russian_headings})"
                )
    if brand_docs.is_dir():
        for path in sorted(brand_docs.glob("*.md")):
            for href in MARKDOWN_LINK.findall(path.read_text(encoding="utf-8")):
                if href.startswith(("http://", "https://", "mailto:", "#")):
                    continue
                file_part = href.split("#", 1)[0]
                if file_part and not (path.parent / file_part).resolve().exists():
                    errors.append(f"{path.relative_to(root)}: broken local link {href}")
    template_root = root / "templates" / "brand"
    actual_templates = {path.name for path in template_root.iterdir()} if template_root.is_dir() else set()
    if actual_templates != BRAND_TEMPLATES:
        errors.append(
            "templates/brand: inventory mismatch: "
            f"missing={sorted(BRAND_TEMPLATES - actual_templates)}, "
            f"extra={sorted(actual_templates - BRAND_TEMPLATES)}"
        )
    return errors


def validate_contact_channels(root: Path, version: str) -> list[str]:
    path = root / "registry" / "contact-channels.json"
    if not path.is_file():
        return ["registry/contact-channels.json: missing canonical contact roles"]
    data = load_json(path)
    schema_path = (path.parent / data.get("$schema", "")).resolve()
    if not schema_path.is_file():
        return ["registry/contact-channels.json:$schema: missing schema"]
    errors = [
        f"registry/contact-channels.json:{error}"
        for error in validate_schema(data, load_json(schema_path), schema_path)
    ]
    if data.get("version") != version:
        errors.append("registry/contact-channels.json: version does not match VERSION")
    expected = {
        "contact": "contact@qenterra.com",
        "support": "support@qenterra.com",
    }
    actual = {
        channel.get("id"): channel.get("address")
        for channel in data.get("channels", [])
        if isinstance(channel, dict)
    }
    if actual != expected:
        errors.append(f"registry/contact-channels.json: canonical roles differ: {actual!r}")
    return errors


def validate_component_registry(root: Path, version: str) -> list[str]:
    path = root / "registry" / "components.json"
    if not path.is_file():
        return ["registry/components.json: missing component registry"]
    data = load_json(path)
    schema_path = (path.parent / data.get("$schema", "")).resolve()
    if not schema_path.is_file():
        return ["registry/components.json:$schema: missing schema"]
    errors = [
        f"registry/components.json:{error}"
        for error in validate_schema(data, load_json(schema_path), schema_path)
    ]
    if data.get("version") != version:
        errors.append("registry/components.json: version does not match VERSION")
    identifiers: set[str] = set()
    for component in data.get("components", []):
        identifier = component.get("id")
        if identifier in identifiers:
            errors.append(f"registry/components.json: duplicate component id {identifier!r}")
        identifiers.add(identifier)
        states = set(component.get("states", []))
        story_ids: set[str] = set()
        for story in component.get("stories", []):
            story_id = story.get("id")
            if story_id in story_ids:
                errors.append(f"registry/components.json:{identifier}: duplicate story id {story_id!r}")
            story_ids.add(story_id)
            if story.get("state") not in states:
                errors.append(
                    f"registry/components.json:{identifier}/{story_id}: unknown state {story.get('state')!r}"
                )
            if story.get("localeWidth", "standard") not in {"standard", "long", "rtl"}:
                errors.append(f"registry/components.json:{identifier}/{story_id}: invalid localeWidth")
    return errors


def validate_icon_registry(root: Path, version: str) -> list[str]:
    path = root / "registry" / "icons.json"
    if not path.is_file():
        return ["registry/icons.json: missing semantic icon registry"]
    data = load_json(path)
    schema_path = (path.parent / data.get("$schema", "")).resolve()
    errors = (
        [
            f"registry/icons.json:{error}"
            for error in validate_schema(data, load_json(schema_path), schema_path)
        ]
        if schema_path.is_file()
        else ["registry/icons.json:$schema: missing schema"]
    )
    if data.get("version") != version:
        errors.append("registry/icons.json: version does not match VERSION")
    identifiers = [item.get("id") for item in data.get("icons", [])]
    if len(identifiers) != len(set(identifiers)):
        errors.append("registry/icons.json: icon ids must be unique")
    required = {slug for slug, _ in PAGE_GROUPS} | {"search", "menu", "globe", "chevron"}
    missing = sorted(required - set(identifiers))
    if missing:
        errors.append(f"registry/icons.json: missing required site icons {missing}")
    for item in data.get("icons", []):
        fragment = item.get("svg", "").lower()
        if any(forbidden in fragment for forbidden in ("<script", "<style", " onload=", " onclick=")):
            errors.append(f"registry/icons.json:{item.get('id')}: unsafe SVG fragment")
    generated_swift = root / "generated" / "QDSGeneratedIcons.swift"
    generated_svg = root / "generated" / "qds-icons.svg"
    if generated_swift.is_file() and generated_swift.read_text(encoding="utf-8") != generate_swift_icons(data):
        errors.append("generated/QDSGeneratedIcons.swift: drifted from icon registry")
    if generated_svg.is_file() and generated_svg.read_text(encoding="utf-8") != generate_svg_sprite(data):
        errors.append("generated/qds-icons.svg: drifted from icon registry")
    return errors


def validate_figma_exports(root: Path, tokens: dict[str, dict[str, Any]]) -> list[str]:
    components = load_json(root / "registry" / "components.json")
    icons = load_json(root / "registry" / "icons.json")
    expected = generate_figma_exports(tokens, components, icons)
    errors: list[str] = []
    for filename, payload in expected.items():
        path = root / "generated" / "figma" / filename
        if not path.is_file():
            errors.append(f"generated/figma/{filename}: missing deterministic export")
        elif load_json(path) != payload:
            errors.append(f"generated/figma/{filename}: drifted from canonical sources")
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
    version = (root / "VERSION").read_text(encoding="utf-8").strip()
    if report.get("version") != version:
        errors.append(f"output/reports/browser.json: version {report.get('version')!r} does not match {version}")
    manifest_path = root / "evidence" / "screenshots.json"
    if not manifest_path.is_file():
        return [*errors, "evidence/screenshots.json: missing exact screenshot manifest"]
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    expected_names = [capture.get("name") for capture in manifest.get("captures", [])]
    captures = report.get("captures")
    if not isinstance(captures, list):
        errors.append("output/reports/browser.json: captures must be an array")
        return errors
    actual_names = [capture.get("name") if isinstance(capture, dict) else None for capture in captures]
    if actual_names != expected_names:
        errors.append(f"output/reports/browser.json: capture manifest mismatch: {actual_names!r}")
    baseline_names = sorted(path.stem for path in (root / "output" / "screenshots").glob("*.png"))
    if baseline_names != sorted(expected_names):
        errors.append("output/screenshots: baselines do not exactly match evidence/screenshots.json")
    for capture in captures:
        name = capture.get("name") if isinstance(capture, dict) else None
        path = root / "output" / "screenshots" / f"{name}.png"
        if not name or not path.is_file() or path.stat().st_size < 10_000:
            errors.append(f"visual evidence missing or too small: {name!r}")
    diff_path = root / "output" / "reports" / "visual-diff.json"
    if not diff_path.is_file():
        errors.append("output/reports/visual-diff.json: missing exact pixel comparison")
    else:
        diff = json.loads(diff_path.read_text(encoding="utf-8"))
        if diff.get("status") != "passed" or diff.get("version") != version:
            errors.append("output/reports/visual-diff.json: current exact pixel comparison did not pass")
    checks = report.get("checks", {})
    for name in (
        "scrollSpy",
        "languageSwitch",
        "languagePickerPosition",
        "brandModule",
        "repositoryModule",
        "uniformSvgIcons",
        "componentLab",
        "emailComposer",
        "pseudoLocalization",
        "visibleFocus",
    ):
        if checks.get(name) != "passed":
            errors.append(f"output/reports/browser.json: {name} did not pass")
    return errors


def run(root: Path = ROOT) -> dict[str, Any]:
    version = (root / "VERSION").read_text(encoding="utf-8").strip()
    tokens = {name: load_json(root / "tokens" / f"{name}.json") for name in TOKEN_NAMES}
    errors = validate_token_schemas(root, tokens)
    errors.extend(validate_token_data(version, tokens))
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
    errors.extend(validate_packages(root, version))
    errors.extend(validate_repository_hygiene(root))
    errors.extend(validate_brand_sources(root))
    errors.extend(validate_contact_channels(root, version))
    errors.extend(validate_email_registry(root, version))
    errors.extend(validate_component_registry(root, version))
    errors.extend(validate_icon_registry(root, version))
    errors.extend(validate_figma_exports(root, tokens))
    errors.extend(validate_brand_assets(root, check_git_lfs=True))
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
