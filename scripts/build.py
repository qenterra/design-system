#!/usr/bin/env python3
"""Build the multipage and standalone QenTerra Design System reference."""

from __future__ import annotations

import json
import re
import shutil
import sys
import tempfile
from html import escape
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from lib.markdown_renderer import Section, plain_text, render, split_numbered_sections  # noqa: E402
from lib.pseudo_locales import pseudo_long, pseudo_rtl  # noqa: E402
from lib.site_locales import (  # noqa: E402
    BRAND_SECTION_KEYS,
    COPY,
    PAGE_GROUPS,
    REPOSITORY_SECTION_KEYS,
    SPECIMENS,
    icon,
)
from lib.token_tools import (  # noqa: E402
    generate_css,
    generate_swift,
    generate_token_reference,
    load_json,
)


def atomic_write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    content = "\n".join(line.rstrip() for line in content.splitlines()).rstrip() + "\n"
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=path.parent, delete=False) as handle:
        handle.write(content)
        temporary = Path(handle.name)
    temporary.replace(path)


def load_tokens() -> list[tuple[str, dict]]:
    names = ["foundation", "semantic", "typography", "motion", "components", "platforms", "products"]
    return [(name, load_json(ROOT / "tokens" / f"{name}.json")) for name in names]


def pages(locale: str) -> list[tuple[str, str, list[int], str]]:
    return [
        (slug, COPY[locale]["pages"][slug][0], numbers, COPY[locale]["pages"][slug][1])
        for slug, numbers in PAGE_GROUPS
    ]


def nav_html(current: str, root: str, standalone: bool, locale: str) -> str:
    links = []
    for slug, title, section_numbers, _ in pages(locale):
        if slug in {"brand", "repositories", "lab"}:
            prefix = {"brand": "brand", "repositories": "repository", "lab": "lab"}[slug]
            href = f"#{prefix}-overview" if standalone else f"{root}pages/{slug}.html"
            section_start = section_end = prefix
        elif standalone:
            href = f"#section-{section_numbers[0]}"
            section_start, section_end = section_numbers[0], section_numbers[-1]
        elif slug == "index":
            href = f"{root}index.html"
            section_start, section_end = section_numbers[0], section_numbers[-1]
        else:
            href = f"{root}pages/{slug}.html"
            section_start, section_end = section_numbers[0], section_numbers[-1]
        current_attr = ' aria-current="page"' if slug == current and not standalone else ""
        links.append(
            f'<a href="{href}" data-nav-slug="{slug}" data-section-start="{section_start}" '
            f'data-section-end="{section_end}"{current_attr}>'
            f'<span class="nav-glyph">{icon(slug)}</span><span>{title}</span></a>'
        )
    return "\n".join(links)


def color_specimen(locale: str) -> str:
    copy = SPECIMENS[locale]
    roles = list(zip(copy["color_roles"], [
        "--qds-surface-content", "--qds-surface-secondary", "--qds-surface-raised",
        "--qds-surface-chrome", "--qds-action-primary", "--qds-fill-selected-strong",
    ]))
    swatches = "".join(
        f'<div class="swatch" style="--swatch:var({token})"><div class="swatch-color"></div>'
        f'<div class="swatch-copy"><strong>{name}</strong><span>{token}</span></div></div>'
        for name, token in roles
    )
    return specimen(copy["color_title"], copy["color_note"], f'<div class="swatch-grid">{swatches}</div>')


def typography_specimen(locale: str) -> str:
    specimen_copy = SPECIMENS[locale]
    roles = list(zip(
        ["display", "screen-title", "section-title", "body", "metadata", "monospaced-data"],
        specimen_copy["type_examples"],
    ))
    rows = "".join(
        f'<div class="type-row"><span class="type-label">{role}</span>'
        f'<span style="font-family:var(--qds-type-{role}-family);font-size:var(--qds-type-{role}-size);'
        f'line-height:var(--qds-type-{role}-line);font-weight:var(--qds-type-{role}-weight);'
        f'letter-spacing:var(--qds-type-{role}-tracking)">{example}</span></div>'
        for role, example in roles
    )
    return specimen(
        specimen_copy["type_title"],
        specimen_copy["type_note"],
        f'<div class="type-stack">{rows}</div>',
    )


def spacing_specimen(locale: str) -> str:
    copy = SPECIMENS[locale]
    values = [("space.1", 4), ("space.2", 8), ("space.3", 12), ("space.4", 16), ("space.6", 24), ("space.8", 32), ("space.12", 48)]
    rows = "".join(
        f'<div class="spacing-row"><span class="type-label">{name} · {value}px</span>'
        f'<span class="spacing-bar" style="width:{value * 4}px"></span></div>'
        for name, value in values
    )
    return specimen(copy["spacing_title"], copy["spacing_note"], f'<div class="spacing-stack">{rows}</div>')


def component_specimen(locale: str) -> str:
    copy = SPECIMENS[locale]
    controls = copy["controls"]
    field = copy["field"]
    canvas = f"""
    <div class="specimen-canvas">
      <button class="button button-primary">{controls[0]}</button>
      <button class="button button-secondary">{controls[1]}</button>
      <button class="button button-quiet">{controls[2]}</button>
      <button class="button button-destructive">{controls[3]}</button>
      <span class="status-demo status-success"><span class="status-dot"></span>{controls[4]}</span>
      <span class="status-demo status-warning"><span class="status-dot"></span>{controls[5]}</span>
      <span class="status-demo status-destructive"><span class="status-dot"></span>{controls[6]}</span>
      <span class="key-hint">⌥ Space</span>
    </div>
    <div class="specimen-canvas">
      <div class="field-demo"><label for="demo-name">{field[0]}</label><input id="demo-name" value="{field[1]}"><small>{field[2]}</small></div>
      <div class="field-demo is-error"><label for="demo-api">{field[3]}</label><input id="demo-api" value="{field[4]}" aria-invalid="true"><small>{field[5]}</small></div>
    </div>
    """
    return specimen(copy["controls_title"], copy["controls_note"], canvas)


def settings_specimen(locale: str) -> str:
    copy = SPECIMENS[locale]
    values = copy["settings"]
    canvas = f"""
    <div class="specimen-canvas">
      <div class="settings-demo">
        <div class="settings-row"><div class="settings-copy"><strong>{values[0]}</strong><span>{values[1]}</span></div><button class="switch" type="button" role="switch" aria-checked="true" aria-label="{values[0]}"></button></div>
        <div class="settings-row"><div class="settings-copy"><strong>{values[2]}</strong><span>{values[3]}</span></div><span class="status-demo"><span class="status-dot"></span>{values[4]}</span></div>
        <div class="settings-row"><div class="settings-copy"><strong>{values[5]}</strong><span>{values[6]}</span></div><button class="button button-secondary">{values[7]}</button></div>
      </div>
    </div>
    """
    return specimen(copy["settings_title"], copy["settings_note"], canvas)


def table_specimen(locale: str) -> str:
    copy = SPECIMENS[locale]
    values = copy["table"]
    rows = f"""
    <div class="mini-table">
      <div class="mini-table-row"><strong>{values[0]}</strong><span>{values[1]}</span><span>{values[2]}</span></div>
      <div class="mini-table-row is-selected"><strong>{values[3]}</strong><span>{values[4]}</span><span>{values[5]}</span></div>
      <div class="mini-table-row"><strong>{values[6]}</strong><span>{values[7]}</span><span>{values[8]}</span></div>
    </div>
    """
    return specimen(copy["table_title"], copy["table_note"], f'<div class="specimen-canvas">{rows}</div>')


def motion_specimen(locale: str) -> str:
    copy = SPECIMENS[locale]
    cards = "".join(
        f'<div class="motion-card" tabindex="0"><span>{label}</span><small>{duration}</small></div>'
        for label, duration in zip(copy["motion"], ["80 ms", "100 ms", "150 ms", "220 ms"])
    )
    return specimen(copy["motion_title"], copy["motion_note"], f'<div class="specimen-canvas"><div class="motion-grid">{cards}</div></div>')


def product_specimen(locale: str) -> str:
    copy = SPECIMENS[locale]
    cards = []
    for name, profile, pattern in zip(
        copy["archetypes"], copy["profiles"],
        [["is-large", "", "is-accent"], ["", "is-large", ""], ["is-accent", "", "is-large"]],
    ):
        blocks = "".join(f'<div class="mini-block {kind}"></div>' for kind in pattern)
        cards.append(
            f'<article class="product-card"><div class="product-card-copy"><strong>{name}</strong><span>{profile}</span></div>'
            f'<div class="mini-shell"><div class="mini-shell-rail"></div><div class="mini-shell-body">{blocks}</div></div></article>'
        )
    return specimen(copy["products_title"], copy["products_note"], f'<div class="product-grid">{"".join(cards)}</div>')


def accessibility_specimen(locale: str) -> str:
    copy = SPECIMENS[locale]
    values = copy["accessibility"]
    canvas = f"""
    <div class="specimen-canvas">
      <button class="button button-primary">{values[0]}</button>
      <span class="status-demo status-warning"><span class="status-dot"></span>{values[1]}</span>
      <span class="status-demo status-info"><span class="status-dot"></span>{values[2]}</span>
      <span class="key-hint">Esc</span>
    </div>
    """
    return specimen(copy["accessibility_title"], copy["accessibility_note"], canvas)


def specimen(title: str, note: str, body: str) -> str:
    return f'<aside class="specimen" aria-label="{title}"><div class="specimen-header"><h3>{title}</h3><p>{note}</p></div>{body}</aside>'


def specimens_for(section_number: int, locale: str) -> str:
    return {
        3: color_specimen(locale) + typography_specimen(locale) + spacing_specimen(locale),
        5: component_specimen(locale),
        6: settings_specimen(locale) + table_specimen(locale),
        11: motion_specimen(locale),
        13: accessibility_specimen(locale),
        15: product_specimen(locale),
    }.get(section_number, "")


def render_section(section: Section, locale: str, nav_slug: str) -> str:
    return (
        f'<section class="doc-section" id="section-{section.number}" data-nav-slug="{nav_slug}">'
        f'<span class="section-number">{section.number:02d}</span>'
        f'<h2>{section.title}</h2><div class="prose">{render(section.markdown, id_prefix=f"s{section.number}-")}</div></section>'
        f'{specimens_for(section.number, locale)}'
    )


def render_audit_appendix(locale: str) -> str:
    suffix = ".ru" if locale == "ru" else ""
    appendix = COPY[locale]["appendix"]
    sources = [
        (f"audit-brief{suffix}.md", "A", appendix["audit"], "audit-app-"),
        (f"obsidian-instruction-audit{suffix}.md", "B", appendix["instructions"], "audit-instructions-"),
    ]
    sections = []
    for filename, marker, title, prefix in sources:
        audit_path = ROOT / "output" / filename
        if not audit_path.exists():
            continue
        sections.append(
            f'<section class="doc-section" id="audit-appendix-{marker.lower()}" data-nav-slug="audit"><span class="section-number">{marker}</span>'
            f'<h2>{title}</h2><div class="prose">'
            f'{render(audit_path.read_text(encoding="utf-8"), heading_offset=2, id_prefix=prefix)}</div></section>'
        )
    return "".join(sections)


def render_component_catalog(locale: str) -> str:
    filename = "COMPONENT_CATALOG.ru.md" if locale == "ru" else "COMPONENT_CATALOG.md"
    path = ROOT / "docs" / filename
    if not path.exists():
        return ""
    return (
        '<section class="doc-section" id="component-catalog" data-nav-slug="components"><span class="section-number">C</span>'
        f'<h2>{COPY[locale]["appendix"]["catalog"]}</h2><div class="prose">'
        f'{render(path.read_text(encoding="utf-8"), heading_offset=2, id_prefix="catalog-")}</div></section>'
    )


def component_registry() -> dict:
    return load_json(ROOT / "registry" / "components.json")


def lab_copy(locale: str, value: str, width: str | None) -> str:
    if width == "long":
        return pseudo_long(value)
    if width == "rtl":
        return pseudo_rtl(value)
    return value


def render_lab_sample(component_id: str, story: dict, locale: str, unique: str) -> str:
    ru = locale == "ru"
    width = story.get("localeWidth")
    label = lab_copy(locale, "Продолжить" if ru else "Continue", width)
    state = story["state"]
    if component_id == "button":
        disabled = " disabled" if state == "disabled" else ""
        variant = story.get("variant", "secondary")
        return f'<button class="qds-button" data-variant="{variant}"{disabled}>{label}</button>'
    if component_id == "field":
        control_id = f"{unique}-control"
        field_label = lab_copy(locale, "Название коллекции" if ru else "Collection name", width)
        error = "Введите непустое название." if ru else "Enter a non-empty name."
        invalid = state == "invalid"
        disabled = " disabled" if state == "disabled" else ""
        described = f' aria-describedby="{unique}-error"' if invalid else ""
        invalid_attribute = ' aria-invalid="true"' if invalid else ""
        error_html = f'<span class="lab-error" id="{unique}-error">{error}</span>' if invalid else ""
        return (
            f'<label class="lab-field" for="{control_id}"><span>{field_label}</span>'
            f'<input class="qds-field" id="{control_id}" aria-label="{escape(field_label, quote=True)}"{disabled}{described}'
            f'{invalid_attribute} value=""></label>{error_html}'
        )
    if component_id == "interactive-row":
        selected = ' aria-selected="true"' if state == "selected" else ' aria-selected="false"'
        unavailable = ' aria-disabled="true"' if state == "unavailable" else ""
        title = "Локальная библиотека" if ru else "Local library"
        detail = "Недоступно" if ru and state == "unavailable" else "Unavailable" if state == "unavailable" else "48 items"
        return f'<div class="qds-interactive-row" role="option" tabindex="0"{selected}{unavailable}><strong>{title}</strong><span>{detail}</span></div>'
    if component_id == "group":
        title = lab_copy(locale, "Хранение" if ru else "Storage", width)
        return f'<fieldset class="qds-group"><legend>{title}</legend><label><input type="checkbox" checked> {lab_copy(locale, "Сохранять историю локально" if ru else "Keep local history", width)}</label></fieldset>'
    if component_id == "dialog":
        title = "Не удалось завершить" if ru and state == "error" else "Could not complete" if state == "error" else "Удалить правило?" if ru else "Delete rule?"
        return f'<div class="lab-dialog" role="dialog" aria-modal="false" aria-labelledby="{unique}-title"><strong id="{unique}-title">{title}</strong><p>{"Изменение можно отменить позже." if ru else "You can recover this change later."}</p><button class="qds-button" data-variant="secondary">{"Отмена" if ru else "Cancel"}</button></div>'
    status_label = {"success": ("Готово", "Complete"), "warning": ("Нужно проверить", "Needs review"), "destructive": ("Не удалось", "Failed")}.get(state, ("Состояние", "Status"))
    return f'<span class="lab-status lab-status-{state}" role="status"><span aria-hidden="true">●</span>{status_label[0 if ru else 1]}</span>'


def render_component_lab(locale: str) -> str:
    registry = component_registry()
    ru = locale == "ru"
    controls = (
        '<div class="lab-toolbar" aria-label="{}">'
        '<span>{}</span><button type="button" data-lab-density="compact" aria-pressed="false">{}</button>'
        '<button type="button" data-lab-density="standard" aria-pressed="true">{}</button>'
        '<span>{}</span><button type="button" data-lab-width="standard" aria-pressed="true">{}</button>'
        '<button type="button" data-lab-width="long" aria-pressed="false">Pseudo-long</button>'
        '<button type="button" data-lab-width="rtl" aria-pressed="false">Pseudo-RTL</button></div>'
    ).format(
        "Настройки лаборатории" if ru else "Lab controls",
        "Плотность" if ru else "Density",
        "Компактная" if ru else "Compact",
        "Стандартная" if ru else "Standard",
        "Текст" if ru else "Content",
        "Обычный" if ru else "Standard",
    )
    components = []
    for component in registry["components"]:
        component_id = component["id"]
        stories = []
        for story in component["stories"]:
            story_id = f"story-{component_id}-{story['id']}"
            width = story.get("localeWidth", "standard")
            stories.append(
                f'<article class="lab-story" id="{story_id}" data-lab-story data-width="{width}">'
                f'<div class="lab-story-head"><code>{component_id}/{story["id"]}</code><span>{story["state"]}</span></div>'
                f'<div class="lab-canvas" dir="{"rtl" if width == "rtl" else "ltr"}">'
                f'{render_lab_sample(component_id, story, locale, story_id)}</div></article>'
            )
        components.append(
            f'<section class="lab-component" id="lab-{component_id}"><header><h3>{component["name"][locale]}</h3>'
            f'<p>{component["summary"][locale]}</p></header><div class="lab-story-grid">{"".join(stories)}</div></section>'
        )
    return (
        '<section class="doc-section component-lab" id="lab-overview" data-nav-slug="lab" data-density="standard" data-width="all">'
        f'<span class="section-number">L</span><h2>{"Исполняемая лаборатория компонентов" if ru else "Executable component laboratory"}</h2>'
        f'<p class="lab-intro">{"Каждый пример имеет постоянный URL и проходит проверки тем, плотности и локализации." if ru else "Every story has a stable URL and participates in appearance, density, and localization checks."}</p>'
        f'{controls}{"".join(components)}</section>'
    )


def brand_sections(locale: str) -> list[tuple[str, str, str]]:
    suffix = ".ru.md" if locale == "ru" else ".md"
    documents = ("MASTER", "QENTERRA", "NYX", "ASSET_CATALOG")
    sections = []
    for key, stem in zip(BRAND_SECTION_KEYS, documents):
        filename = f"{stem}{suffix}"
        lines = (ROOT / "docs" / "brand" / filename).read_text(encoding="utf-8").splitlines()
        if not lines or not lines[0].startswith("# "):
            raise ValueError(f"docs/brand/{filename}: expected one H1 title")
        title = lines[0][2:].strip()
        markdown = "\n".join(lines[1:]).strip()
        # Repository-relative Markdown links are useful in source docs but invalid in the built site.
        # Keep their readable labels; the Brand page and catalog expose the same routes directly.
        markdown = re.sub(r"\[([^]]+)]\((?!https?://|mailto:)[^)]+\)", r"\1", markdown)
        sections.append((key, title, markdown))
    return sections


def render_brand_module(locale: str) -> str:
    rendered = []
    for index, (key, title, markdown) in enumerate(brand_sections(locale)):
        rendered.append(
            f'<section class="doc-section" id="brand-{key}" data-nav-slug="brand">'
            f'<span class="section-number">B{index}</span><h2>{title}</h2>'
            f'<div class="prose">{render(markdown, id_prefix=f"brand-{key}-")}</div></section>'
        )
    return "".join(rendered)


def repository_sections(locale: str) -> list[tuple[str, str, str]]:
    filename = "STANDARD.ru.md" if locale == "ru" else "STANDARD.md"
    text = (ROOT / "docs" / "repository" / filename).read_text(encoding="utf-8")
    lines = text.splitlines()
    if not lines or not lines[0].startswith("# "):
        raise ValueError(f"{filename}: expected one H1 title")
    title = lines[0][2:].strip()
    headings = [index for index, line in enumerate(lines) if re.match(r"^##\s+\S", line)]
    expected = len(REPOSITORY_SECTION_KEYS) - 1
    if len(headings) != expected:
        raise ValueError(f"{filename}: expected {expected} H2 sections, got {len(headings)}")
    first_heading = headings[0] if headings else len(lines)
    intro = "\n".join(lines[1:first_heading]).strip()
    sections = [(REPOSITORY_SECTION_KEYS[0], title, intro)]
    for offset, start in enumerate(headings):
        end = headings[offset + 1] if offset + 1 < len(headings) else len(lines)
        heading = lines[start][3:].strip()
        body = "\n".join(lines[start + 1 : end]).strip()
        sections.append((REPOSITORY_SECTION_KEYS[offset + 1], heading, body))
    return sections


def render_repository_module(locale: str) -> str:
    rendered = []
    for index, (key, title, markdown) in enumerate(repository_sections(locale)):
        rendered.append(
            f'<section class="doc-section" id="repository-{key}" data-nav-slug="repositories">'
            f'<span class="section-number">R{index}</span><h2>{title}</h2>'
            f'<div class="prose">{render(markdown, id_prefix=f"repository-{key}-")}</div></section>'
        )
    return "".join(rendered)


def theme_bootstrap(locale: str) -> str:
    return (
        "<script>(function(){var t=localStorage.getItem('qds-theme');"
        "if(t==='light'||t==='dark'){document.documentElement.dataset.theme=t;}"
        f"localStorage.setItem('qds-locale','{locale}');"
        "}());</script>"
    )


def language_menu(locale: str, targets: dict[str, str]) -> str:
    ui = COPY[locale]["ui"]
    links = []
    for code, label_key in [("en", "english"), ("ru", "russian")]:
        current = ' aria-current="true"' if code == locale else ""
        links.append(
            f'<a role="menuitem" href="{targets[code]}" data-locale-target="{code}"{current}>'
            f'<span>{ui[label_key]}</span><span class="language-code">{COPY[code]["code"]}</span></a>'
        )
    return (
        '<div class="language-picker">'
        f'<button class="language-button" type="button" data-language-button aria-haspopup="menu" '
        f'aria-expanded="false" aria-label="{ui["choose_language"]}">{icon("globe")}<span>{COPY[locale]["code"]}</span></button>'
        f'<div class="language-menu" data-language-menu role="menu" aria-label="{ui["language"]}" hidden>{"".join(links)}</div>'
        '</div>'
    )


def shell(
    *,
    page_slug: str,
    page_title: str,
    page_summary: str,
    section_html: str,
    site_root: str,
    asset_root: str,
    version: str,
    locale: str,
    language_targets: dict[str, str],
    standalone: bool = False,
    token_css: str = "",
    source_css: str = "",
    recipe_css: str = "",
    source_js: str = "",
    search_index: list[dict] | None = None,
) -> str:
    if standalone:
        inline_css = source_css.replace('@import url("./qds-tokens.css");', "").replace(
            '@import url("./qds-recipes.css");', ""
        )
        styles = f"<style>{token_css}\n{recipe_css}\n{inline_css}</style>"
        scripts = f"<script>window.QDS_SEARCH_INDEX={json.dumps(search_index or [], ensure_ascii=False)};</script><script>{source_js}</script>"
        data = f'data-root="" data-site-root="" data-standalone="true" data-locale="{locale}"'
        stylesheet = ""
    else:
        styles = ""
        scripts = f'<script src="{asset_root}assets/app.js" defer></script>'
        data = f'data-root="{asset_root}" data-site-root="{site_root}" data-standalone="false" data-locale="{locale}"'
        stylesheet = f'<link rel="stylesheet" href="{asset_root}assets/styles.css">'

    ui = COPY[locale]["ui"]
    document_title = page_title if page_title == "QenTerra Design System" else f"{page_title} · QenTerra Design System"
    data += (
        f' data-search-empty="{escape(ui["no_results"], quote=True)}"'
        f' data-section-label="{escape(ui["section"], quote=True)}"'
    )
    home = "#section-0" if standalone else f"{site_root}index.html"
    master_link = "#section-0" if standalone else f"{site_root}qenterra-design-system.html"
    foundations_link = "#section-3" if standalone else f"{site_root}pages/foundations.html"
    hero = ""
    intro_heading = "h1"
    if page_slug == "index":
        intro_heading = "h2"
        hero = f"""
        <section class="hero">
          <p class="hero-kicker">{ui["hero_kicker"].format(version=version)}</p>
          <h1>{ui["hero_title"]}</h1>
          <p class="hero-summary">{ui["hero_summary"]}</p>
          <div class="hero-actions"><a class="button button-primary" href="{foundations_link}">{ui["explore_foundations"]}</a><a class="button button-secondary" href="{master_link}">{ui["open_master"]}</a></div>
        </section>
        """

    return f"""<!doctype html>
<html lang="{locale}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="{escape(page_summary, quote=True)}">
  <meta name="color-scheme" content="light dark">
  <link rel="icon" href="data:,">
  <title>{document_title}</title>
  {theme_bootstrap(locale)}
  {stylesheet}
  {styles}
</head>
<body {data}>
  <a class="skip-link" href="#main-content">{ui["skip"]}</a>
  <div class="progress-line" data-progress aria-hidden="true"></div>
  <div class="site-shell">
    <aside class="sidebar" aria-label="{ui["navigation"]}">
      <div class="sidebar-head"><a class="brand" href="{home}"><span class="brand-mark" aria-hidden="true">Q</span><span class="brand-copy"><span class="brand-title">QenTerra Design System</span><span class="brand-meta">{ui["semantic_core"]} · {version}</span></span></a></div>
      <p class="nav-label">{ui["reference"]}</p>
      <nav class="site-nav">{nav_html(page_slug, site_root, standalone, locale)}</nav>
      <div class="sidebar-footer">
        <div class="appearance-control" role="group" aria-label="{ui["appearance"]}"><button type="button" data-theme-choice="system" aria-pressed="true">{ui["system"]}</button><button type="button" data-theme-choice="light" aria-pressed="false">{ui["light"]}</button><button type="button" data-theme-choice="dark" aria-pressed="false">{ui["dark"]}</button></div>
        <p class="sidebar-note">{ui["sidebar_note"]}</p>
      </div>
    </aside>
    <button class="scrim" data-scrim aria-label="{ui["close_navigation"]}"></button>
    <div class="main-column">
      <header class="topbar"><button class="menu-button" type="button" data-menu-button aria-expanded="false" aria-label="{ui["open_navigation"]}">{icon("menu")}</button><p class="topbar-title">{page_title}</p><div class="search-wrap"><span class="search-icon">{icon("search")}</span><input class="search-input" type="search" data-search aria-label="{ui["search_label"]}" placeholder="{ui["search_placeholder"]}" autocomplete="off"><div class="search-results" data-search-results role="region" aria-label="{ui["search_results"]}"></div></div><span class="key-hint" aria-hidden="true">⌘ K</span>{language_menu(locale, language_targets)}</header>
      <main class="content" id="main-content">
        {hero}
        <header class="page-intro"><p class="page-eyebrow">{ui["eyebrow"]}</p><{intro_heading}>{page_title}</{intro_heading}><p class="page-summary">{page_summary}</p></header>
        {section_html}
        <footer class="page-footer"><span>QenTerra Design System {version}</span><span>{ui["footer"]}</span></footer>
      </main>
    </div>
  </div>
  {scripts}
</body>
</html>
"""


def build() -> None:
    version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
    token_files = load_tokens()
    tokens = {name: data for name, data in token_files}
    token_css = generate_css(
        tokens["foundation"],
        tokens["semantic"],
        tokens["typography"],
        tokens["motion"],
        tokens["components"],
    )
    swift = generate_swift(
        tokens["foundation"],
        tokens["semantic"],
        tokens["typography"],
        tokens["motion"],
        tokens["components"],
    )
    token_reference = generate_token_reference(token_files)
    token_snapshot = json.dumps(
        {name: data for name, data in token_files},
        ensure_ascii=False,
        indent=2,
        sort_keys=True,
    ) + "\n"

    atomic_write(ROOT / "generated" / "qds-tokens.css", token_css)
    atomic_write(ROOT / "generated" / "QDSGeneratedTokens.swift", swift)
    atomic_write(ROOT / "generated" / "TOKEN_REFERENCE.md", token_reference)
    atomic_write(
        ROOT / "packages" / "swift" / "Sources" / "QenTerraDesignTokens" / "QDSGeneratedTokens.swift",
        swift,
    )
    atomic_write(ROOT / "packages" / "css" / "tokens.css", token_css)
    atomic_write(ROOT / "packages" / "css" / "tokens.json", token_snapshot)

    dist = ROOT / "dist"
    if dist.exists():
        shutil.rmtree(dist)
    (dist / "assets").mkdir(parents=True, exist_ok=True)
    source_css = (ROOT / "src" / "assets" / "styles.css").read_text(encoding="utf-8")
    recipe_css = (ROOT / "src" / "assets" / "recipes.css").read_text(encoding="utf-8")
    source_js = (ROOT / "src" / "assets" / "app.js").read_text(encoding="utf-8")
    atomic_write(dist / "assets" / "qds-tokens.css", token_css)
    shutil.copyfile(ROOT / "src" / "assets" / "recipes.css", dist / "assets" / "qds-recipes.css")
    shutil.copyfile(ROOT / "src" / "assets" / "styles.css", dist / "assets" / "styles.css")
    shutil.copyfile(ROOT / "src" / "assets" / "app.js", dist / "assets" / "app.js")
    shutil.copyfile(ROOT / "src" / "assets" / "recipes.css", ROOT / "packages" / "css" / "recipes.css")

    locale_builds: dict[str, tuple[str, list[Section], list[dict]]] = {}
    section_slug = {number: slug for slug, numbers in PAGE_GROUPS for number in numbers}

    for locale in ("en", "ru"):
        master_name = "MASTER.ru.md" if locale == "ru" else "MASTER.md"
        title, sections = split_numbered_sections((ROOT / "docs" / master_name).read_text(encoding="utf-8"))
        section_map = {section.number: section for section in sections}
        expected = set(range(22))
        if set(section_map) != expected:
            raise ValueError(f"{master_name} sections must be exactly 0–21; got {sorted(section_map)}")

        search_index: list[dict] = []
        for section in sections:
            slug = section_slug[section.number]
            path = "index.html" if slug == "index" else f"pages/{slug}.html"
            search_index.append(
                {
                    "section": section.number,
                    "anchor": f"section-{section.number}",
                    "order": section.number,
                    "title": section.title,
                    "page": COPY[locale]["pages"][slug][0],
                    "path": path,
                    "text": plain_text(section.markdown)[:1200],
                }
            )
        for index, (key, section_title, markdown) in enumerate(brand_sections(locale)):
            search_index.append(
                {
                    "section": f"B{index}",
                    "anchor": f"brand-{key}",
                    "order": 22 + index,
                    "title": section_title,
                    "page": COPY[locale]["pages"]["brand"][0],
                    "path": "pages/brand.html",
                    "text": plain_text(markdown)[:1200],
                }
            )
        for index, (key, section_title, markdown) in enumerate(repository_sections(locale)):
            search_index.append(
                {
                    "section": f"R{index}",
                    "anchor": f"repository-{key}",
                    "order": 22 + len(BRAND_SECTION_KEYS) + index,
                    "title": section_title,
                    "page": COPY[locale]["pages"]["repositories"][0],
                    "path": "pages/repositories.html",
                    "text": plain_text(markdown)[:1200],
                }
            )
        for index, component in enumerate(component_registry()["components"]):
            search_index.append(
                {
                    "section": f"L{index}",
                    "anchor": f"lab-{component['id']}",
                    "order": 80 + index,
                    "title": component["name"][locale],
                    "page": COPY[locale]["pages"]["lab"][0],
                    "path": "pages/lab.html",
                    "text": component["summary"][locale],
                }
            )
        atomic_write(
            dist / "assets" / f"search-index-{locale}.json",
            json.dumps(search_index, ensure_ascii=False, indent=2) + "\n",
        )
        if locale == "en":
            atomic_write(
                dist / "assets" / "search-index.json",
                json.dumps(search_index, ensure_ascii=False, indent=2) + "\n",
            )

        locale_root = dist / locale
        (locale_root / "pages").mkdir(parents=True, exist_ok=True)
        for slug, page_title, numbers, summary in pages(locale):
            if slug == "brand":
                sections_html = render_brand_module(locale)
            elif slug == "repositories":
                sections_html = render_repository_module(locale)
            elif slug == "lab":
                sections_html = render_component_lab(locale)
            else:
                sections_html = "\n".join(render_section(section_map[number], locale, slug) for number in numbers)
            if slug == "components":
                sections_html += render_component_catalog(locale)
            if slug == "audit":
                sections_html += render_audit_appendix(locale)
            is_index = slug == "index"
            site_root = "" if is_index else "../"
            asset_root = "../" if is_index else "../../"
            relative_page = "index.html" if is_index else f"pages/{slug}.html"
            language_targets = {
                code: f"../{code}/{relative_page}" if is_index else f"../../{code}/{relative_page}"
                for code in ("en", "ru")
            }
            document = shell(
                page_slug=slug,
                page_title=page_title,
                page_summary=summary,
                section_html=sections_html,
                site_root=site_root,
                asset_root=asset_root,
                version=version,
                locale=locale,
                language_targets=language_targets,
            )
            target = locale_root / relative_page
            atomic_write(target, document)

        standalone_sections = []
        for section in sections:
            slug = section_slug[section.number]
            standalone_sections.append(render_section(section, locale, slug))
            if section.number == 9:
                standalone_sections.append(render_component_catalog(locale))
                standalone_sections.append(render_component_lab(locale))
            if section.number == 17:
                standalone_sections.append(render_audit_appendix(locale))
        standalone_sections.append(render_brand_module(locale))
        standalone_sections.append(render_repository_module(locale))
        standalone = shell(
            page_slug="index",
            page_title=title,
            page_summary=COPY[locale]["ui"]["standalone_summary"],
            section_html="\n".join(standalone_sections),
            site_root="",
            asset_root="",
            version=version,
            locale=locale,
            language_targets={code: f"../{code}/qenterra-design-system.html" for code in ("en", "ru")},
            standalone=True,
            token_css=token_css,
            source_css=source_css,
            recipe_css=recipe_css,
            source_js=source_js,
            search_index=search_index,
        )
        atomic_write(locale_root / "qenterra-design-system.html", standalone)
        locale_builds[locale] = (title, sections, search_index)

    english_title, english_sections, english_search = locale_builds["en"]
    compatibility_sections = []
    for section in english_sections:
        slug = section_slug[section.number]
        compatibility_sections.append(render_section(section, "en", slug))
        if section.number == 9:
            compatibility_sections.append(render_component_catalog("en"))
            compatibility_sections.append(render_component_lab("en"))
        if section.number == 17:
            compatibility_sections.append(render_audit_appendix("en"))
    compatibility_sections.append(render_brand_module("en"))
    compatibility_sections.append(render_repository_module("en"))
    compatibility = shell(
        page_slug="index",
        page_title=english_title,
        page_summary=COPY["en"]["ui"]["standalone_summary"],
        section_html="\n".join(compatibility_sections),
        site_root="",
        asset_root="",
        version=version,
        locale="en",
        language_targets={"en": "qenterra-design-system.html", "ru": "ru/qenterra-design-system.html"},
        standalone=True,
        token_css=token_css,
        source_css=source_css,
        recipe_css=recipe_css,
        source_js=source_js,
        search_index=english_search,
    )
    atomic_write(dist / "qenterra-design-system.html", compatibility)

    (dist / "pages").mkdir(parents=True, exist_ok=True)
    for slug, page_title, _, summary in pages("en"):
        if slug == "index":
            continue
        target = f"../en/pages/{slug}.html"
        redirect = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="{escape(summary, quote=True)}">
  <meta name="color-scheme" content="light dark">
  <link rel="icon" href="data:,">
  <link rel="stylesheet" href="../assets/styles.css">
  <title>{page_title} · QenTerra Design System</title>
  <script>(function(){{location.replace('{target}'+location.search+location.hash);}}());</script>
</head>
<body class="language-gateway"><main class="language-gateway-card"><p class="page-eyebrow">QenTerra Design System</p><h1>{page_title}</h1><p>This reference moved to the English locale tree.</p><p><a class="button button-primary" href="{target}">Continue</a></p></main></body>
</html>"""
        atomic_write(dist / "pages" / f"{slug}.html", redirect)

    gateway = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="light dark">
  <link rel="icon" href="data:,">
  <title>QenTerra Design System</title>
  <link rel="stylesheet" href="assets/styles.css">
  <script>(function(){{var saved=localStorage.getItem('qds-locale');var lang=saved==='ru'||(!saved&&navigator.language.toLowerCase().startsWith('ru'))?'ru':'en';location.replace(lang+'/index.html'+location.hash);}}());</script>
</head>
<body class="language-gateway"><main class="language-gateway-card"><p class="page-eyebrow">QenTerra Design System</p><h1>Choose language · Выберите язык</h1><p>Open the complete reference in English or Russian.</p><p>Откройте полный справочник на русском или английском.</p><nav class="language-gateway-links" aria-label="Language · Язык"><a class="button button-primary" href="en/index.html">English</a><a class="button button-secondary" href="ru/index.html">Русский</a></nav></main></body>
</html>"""
    atomic_write(dist / "index.html", gateway)

    print(f"Built QenTerra Design System {version}")
    print(f"  Locales: {len(locale_builds)}")
    print(f"  Sections per locale: {len(english_sections)}")
    print(f"  Pages per locale: {len(PAGE_GROUPS)} + standalone")
    print(f"  Search entries per locale: {len(english_search)}")


if __name__ == "__main__":
    build()
