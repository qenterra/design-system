#!/usr/bin/env python3
"""Build the multipage and standalone QenTerra Design System reference."""

from __future__ import annotations

import json
import shutil
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from lib.markdown_renderer import Section, plain_text, render, split_numbered_sections  # noqa: E402
from lib.token_tools import (  # noqa: E402
    generate_css,
    generate_swift,
    generate_token_reference,
    load_json,
)


PAGES = [
    ("index", "Overview", [0, 1, 2], "Shared grammar, principles, and the layered system."),
    ("foundations", "Foundations", [3, 4], "Appearance, color, type, spacing, material, layout, and states."),
    ("components", "Components", [5, 6, 7, 8, 9], "Controls, containers, navigation, overlays, feedback, and progress."),
    ("patterns", "Patterns", [10], "Reusable task flows for risk, permissions, recovery, privacy, and settings."),
    ("motion", "Motion", [11], "Short, interruptible, state-explanatory movement."),
    ("content", "Content", [12], "UX writing, outcomes, errors, localization, and terminology."),
    ("accessibility", "Accessibility", [13], "Keyboard, screen readers, contrast, zoom, motion, and input modes."),
    ("platforms", "Platforms", [14], "macOS, iOS, iPadOS, web, and browser-extension adapters."),
    ("products", "Products", [15, 16], "Cadence, Unspool, Lilt, app icons, and migration priorities."),
    ("audit", "Evidence", [17], "Cross-product audit, screenshot confidence, and current design debt."),
    ("governance", "Governance", [18, 19, 20, 21], "Versioning, exceptions, AI protocol, maintenance, and adoption."),
]

GLYPHS = {
    "index": "01",
    "foundations": "Aa",
    "components": "□",
    "patterns": "↳",
    "motion": "→",
    "content": "Tx",
    "accessibility": "A+",
    "platforms": "⌘",
    "products": "Q",
    "audit": "✓",
    "governance": "◇",
}


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


def nav_html(current: str, root: str, standalone: bool) -> str:
    links = []
    for slug, title, section_numbers, _ in PAGES:
        if standalone:
            href = f"#section-{section_numbers[0]}"
        elif slug == "index":
            href = f"{root}index.html"
        else:
            href = f"{root}pages/{slug}.html"
        current_attr = ' aria-current="page"' if slug == current else ""
        links.append(
            f'<a href="{href}"{current_attr}><span class="nav-glyph" aria-hidden="true">'
            f'{GLYPHS[slug]}</span><span>{title}</span></a>'
        )
    return "\n".join(links)


def color_specimen() -> str:
    roles = [
        ("Content", "--qds-surface-content"),
        ("Secondary", "--qds-surface-secondary"),
        ("Raised", "--qds-surface-raised"),
        ("Chrome", "--qds-surface-chrome"),
        ("Primary action", "--qds-action-primary"),
        ("Selected", "--qds-fill-selected-strong"),
    ]
    swatches = "".join(
        f'<div class="swatch" style="--swatch:var({token})"><div class="swatch-color"></div>'
        f'<div class="swatch-copy"><strong>{name}</strong><span>{token}</span></div></div>'
        for name, token in roles
    )
    return specimen("Adaptive color roles", "Switch System, Light, and Dark in the sidebar.", f'<div class="swatch-grid">{swatches}</div>')


def typography_specimen() -> str:
    roles = [
        ("display", "Family resemblance without cloned shells"),
        ("screen-title", "Foundations and semantic roles"),
        ("section-title", "Review before risky operations"),
        ("body", "Content remains primary; chrome supports the task."),
        ("metadata", "48 files · 2.4 GB · Local only"),
        ("monospaced-data", "24-bit / 96 kHz · 03:42"),
    ]
    rows = "".join(
        f'<div class="type-row"><span class="type-label">{role}</span>'
        f'<span style="font-family:var(--qds-type-{role}-family);font-size:var(--qds-type-{role}-size);'
        f'line-height:var(--qds-type-{role}-line);font-weight:var(--qds-type-{role}-weight);'
        f'letter-spacing:var(--qds-type-{role}-tracking)">{copy}</span></div>'
        for role, copy in roles
    )
    return specimen("Semantic typography", "System fonts, explicit roles, no half-point archaeology.", f'<div class="type-stack">{rows}</div>')


def spacing_specimen() -> str:
    values = [("space.1", 4), ("space.2", 8), ("space.3", 12), ("space.4", 16), ("space.6", 24), ("space.8", 32), ("space.12", 48)]
    rows = "".join(
        f'<div class="spacing-row"><span class="type-label">{name} · {value}px</span>'
        f'<span class="spacing-bar" style="width:{value * 4}px"></span></div>'
        for name, value in values
    )
    return specimen("Four-point rhythm", "Foundation scale before local compensation.", f'<div class="spacing-stack">{rows}</div>')


def component_specimen() -> str:
    canvas = """
    <div class="specimen-canvas">
      <button class="button button-primary">Continue</button>
      <button class="button button-secondary">Review Files</button>
      <button class="button button-quiet">Show Details</button>
      <button class="button button-destructive">Delete Rule</button>
      <span class="status-demo status-success"><span class="status-dot"></span>Installed</span>
      <span class="status-demo status-warning"><span class="status-dot"></span>Needs review</span>
      <span class="status-demo status-destructive"><span class="status-dot"></span>Recording</span>
      <span class="key-hint">⌥ Space</span>
    </div>
    <div class="specimen-canvas">
      <div class="field-demo"><label for="demo-name">Collection name</label><input id="demo-name" value="Evening listening"><small>Saved locally in Cadence.</small></div>
      <div class="field-demo is-error"><label for="demo-api">API ID</label><input id="demo-api" value="not-a-number" aria-invalid="true"><small>Enter a positive numeric API ID.</small></div>
    </div>
    """
    return specimen("Controls and truthful states", "One primary action. Errors wait for interaction.", canvas)


def settings_specimen() -> str:
    canvas = """
    <div class="specimen-canvas">
      <div class="settings-demo">
        <div class="settings-row"><div class="settings-copy"><strong>Follow system appearance</strong><span>Use the current macOS Light or Dark setting.</span></div><button class="switch" type="button" role="switch" aria-checked="true" aria-label="Follow system appearance"></button></div>
        <div class="settings-row"><div class="settings-copy"><strong>Keep local history</strong><span>Retain completed operations for recovery.</span></div><span class="status-demo"><span class="status-dot"></span>30 days</span></div>
        <div class="settings-row"><div class="settings-copy"><strong>Download folder</strong><span>Files remain under your control.</span></div><button class="button button-secondary">Choose…</button></div>
      </div>
    </div>
    """
    return specimen("Accessible settings grammar", "Label, consequence, and trailing control form one unit.", canvas)


def table_specimen() -> str:
    rows = """
    <div class="mini-table">
      <div class="mini-table-row"><strong>Original filename.flac</strong><span>54.2 MB</span><span>Today</span></div>
      <div class="mini-table-row is-selected"><strong>Interview notes.pdf</strong><span>1.8 MB</span><span>Jul 28</span></div>
      <div class="mini-table-row"><strong>Cover artwork.png</strong><span>3.1 MB</span><span>Jul 27</span></div>
    </div>
    """
    return specimen("Dense data without visual noise", "Stable columns, shape-based selection, dominant first field.", f'<div class="specimen-canvas">{rows}</div>')


def motion_specimen() -> str:
    cards = "".join(
        f'<div class="motion-card" tabindex="0"><span>{label}</span><small>{duration}</small></div>'
        for label, duration in [("Press", "80 ms"), ("Hover", "100 ms"), ("Replace", "150 ms"), ("Spatial", "220 ms")]
    )
    return specimen("Motion tokens", "Hover or focus. Reduced Motion removes displacement.", f'<div class="specimen-canvas"><div class="motion-grid">{cards}</div></div>')


def product_specimen() -> str:
    cards = []
    for name, profile, pattern in [
        ("Cadence", "Immersive content", ["is-large", "", "is-accent"]),
        ("Unspool", "Operational dense", ["", "is-large", ""]),
        ("Lilt", "Transient capability", ["is-accent", "", "is-large"]),
    ]:
        blocks = "".join(f'<div class="mini-block {kind}"></div>' for kind in pattern)
        cards.append(
            f'<article class="product-card"><div class="product-card-copy"><strong>{name}</strong><span>{profile}</span></div>'
            f'<div class="mini-shell"><div class="mini-shell-rail"></div><div class="mini-shell-body">{blocks}</div></div></article>'
        )
    return specimen("One family, three shells", "Shared grammar does not erase product structure.", f'<div class="product-grid">{"".join(cards)}</div>')


def accessibility_specimen() -> str:
    canvas = """
    <div class="specimen-canvas">
      <button class="button button-primary">Visible focus</button>
      <span class="status-demo status-warning"><span class="status-dot"></span>Partial results</span>
      <span class="status-demo status-info"><span class="status-dot"></span>Copied to Clipboard</span>
      <span class="key-hint">Esc</span>
    </div>
    """
    return specimen("Meaning beyond color", "Tab through controls; status always includes words or shape.", canvas)


def specimen(title: str, note: str, body: str) -> str:
    return f'<aside class="specimen" aria-label="{title}"><div class="specimen-header"><h3>{title}</h3><p>{note}</p></div>{body}</aside>'


def specimens_for(section_number: int) -> str:
    return {
        3: color_specimen() + typography_specimen() + spacing_specimen(),
        5: component_specimen(),
        6: settings_specimen() + table_specimen(),
        11: motion_specimen(),
        13: accessibility_specimen(),
        15: product_specimen(),
    }.get(section_number, "")


def render_section(section: Section) -> str:
    return (
        f'<section class="doc-section" id="section-{section.number}">'
        f'<span class="section-number">{section.number:02d}</span>'
        f'<h2>{section.title}</h2><div class="prose">{render(section.markdown, id_prefix=f"s{section.number}-")}</div></section>'
        f'{specimens_for(section.number)}'
    )


def render_audit_appendix() -> str:
    sources = [
        ("audit-brief.md", "A", "Current-state audit", "audit-app-"),
        ("obsidian-instruction-audit.md", "B", "Instruction-system audit", "audit-instructions-"),
    ]
    sections = []
    for filename, marker, title, prefix in sources:
        audit_path = ROOT / "output" / filename
        if not audit_path.exists():
            continue
        sections.append(
            f'<section class="doc-section" id="audit-appendix-{marker.lower()}"><span class="section-number">{marker}</span>'
            f'<h2>{title}</h2><div class="prose">'
            f'{render(audit_path.read_text(encoding="utf-8"), heading_offset=2, id_prefix=prefix)}</div></section>'
        )
    return "".join(sections)


def render_component_catalog() -> str:
    path = ROOT / "docs" / "COMPONENT_CATALOG.md"
    if not path.exists():
        return ""
    return (
        '<section class="doc-section" id="component-catalog"><span class="section-number">C</span>'
        '<h2>Complete component catalog</h2><div class="prose">'
        f'{render(path.read_text(encoding="utf-8"), heading_offset=2, id_prefix="catalog-")}</div></section>'
    )


def theme_bootstrap() -> str:
    return """<script>(function(){var t=localStorage.getItem('qds-theme');if(t==='light'||t==='dark'){document.documentElement.dataset.theme=t;}})();</script>"""


def shell(
    *,
    page_slug: str,
    page_title: str,
    page_summary: str,
    section_html: str,
    root: str,
    version: str,
    standalone: bool = False,
    token_css: str = "",
    source_css: str = "",
    source_js: str = "",
    search_index: list[dict] | None = None,
) -> str:
    if standalone:
        inline_css = source_css.replace('@import url("./qds-tokens.css");', "")
        styles = f"<style>{token_css}\n{inline_css}</style>"
        scripts = f"<script>window.QDS_SEARCH_INDEX={json.dumps(search_index or [], ensure_ascii=False)};</script><script>{source_js}</script>"
        data = 'data-root="" data-standalone="true"'
        stylesheet = ""
    else:
        styles = ""
        scripts = f'<script src="{root}assets/app.js" defer></script>'
        data = f'data-root="{root}" data-standalone="false"'
        stylesheet = f'<link rel="stylesheet" href="{root}assets/styles.css">'

    home = "#section-0" if standalone else f"{root}index.html"
    master_link = "#section-0" if standalone else f"{root}qenterra-design-system.html"
    foundations_link = "#section-3" if standalone else f"{root}pages/foundations.html"
    hero = ""
    intro_heading = "h1"
    if page_slug == "index":
        intro_heading = "h2"
        hero = f"""
        <section class="hero">
          <p class="hero-kicker">QenTerra · Version {version}</p>
          <h1>One grammar.<br>Different products.</h1>
          <p class="hero-summary">Adaptive Soft Graphite, native behavior, honest state, short motion, and explicit recovery for Cadence, Unspool, Lilt, and whatever comes next.</p>
          <div class="hero-actions"><a class="button button-primary" href="{foundations_link}">Explore foundations</a><a class="button button-secondary" href="{master_link}">Open standalone master</a></div>
        </section>
        """

    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="{page_summary}">
  <meta name="color-scheme" content="light dark">
  <title>{page_title} · QenTerra Design System</title>
  {theme_bootstrap()}
  {stylesheet}
  {styles}
</head>
<body {data}>
  <a class="skip-link" href="#main-content">Skip to content</a>
  <div class="progress-line" data-progress aria-hidden="true"></div>
  <div class="site-shell">
    <aside class="sidebar" aria-label="Design system navigation">
      <a class="brand" href="{home}"><span class="brand-mark" aria-hidden="true">Q</span><span class="brand-copy"><span class="brand-title">QenTerra Design System</span><span class="brand-meta">Semantic core · {version}</span></span></a>
      <p class="nav-label">Reference</p>
      <nav class="site-nav">{nav_html(page_slug, root, standalone)}</nav>
      <div class="sidebar-footer">
        <div class="appearance-control" role="group" aria-label="Appearance"><button type="button" data-theme-choice="system" aria-pressed="true">System</button><button type="button" data-theme-choice="light" aria-pressed="false">Light</button><button type="button" data-theme-choice="dark" aria-pressed="false">Dark</button></div>
        <p class="sidebar-note">Exact values come from machine-readable tokens. Product shells remain deliberately distinct.</p>
      </div>
    </aside>
    <button class="scrim" data-scrim aria-label="Close navigation"></button>
    <div class="main-column">
      <header class="topbar"><button class="menu-button" type="button" data-menu-button aria-expanded="false" aria-label="Open navigation">☰</button><p class="topbar-title">{page_title}</p><div class="search-wrap"><input class="search-input" type="search" data-search aria-label="Search design system" placeholder="Search components, states, products…" autocomplete="off"><div class="search-results" data-search-results role="region" aria-label="Search results"></div></div><span class="key-hint" aria-hidden="true">⌘ K</span></header>
      <main class="content" id="main-content">
        {hero}
        <header class="page-intro"><p class="page-eyebrow">QenTerra Design System</p><{intro_heading}>{page_title}</{intro_heading}><p class="page-summary">{page_summary}</p></header>
        {section_html}
        <footer class="page-footer"><span>QenTerra Design System {version}</span><span>System first · Dark signature · Light complete</span></footer>
      </main>
    </div>
  </div>
  {scripts}
</body>
</html>
"""


def build() -> None:
    version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
    title, sections = split_numbered_sections((ROOT / "docs" / "MASTER.md").read_text(encoding="utf-8"))
    section_map = {section.number: section for section in sections}
    expected = set(range(22))
    if set(section_map) != expected:
        raise ValueError(f"MASTER sections must be exactly 0–21; got {sorted(section_map)}")

    token_files = load_tokens()
    tokens = {name: data for name, data in token_files}
    token_css = generate_css(tokens["foundation"], tokens["semantic"], tokens["typography"], tokens["motion"])
    swift = generate_swift(tokens["foundation"], tokens["semantic"], tokens["motion"])
    token_reference = generate_token_reference(token_files)

    atomic_write(ROOT / "generated" / "qds-tokens.css", token_css)
    atomic_write(ROOT / "generated" / "QDSGeneratedTokens.swift", swift)
    atomic_write(ROOT / "generated" / "TOKEN_REFERENCE.md", token_reference)

    dist = ROOT / "dist"
    (dist / "assets").mkdir(parents=True, exist_ok=True)
    (dist / "pages").mkdir(parents=True, exist_ok=True)
    source_css = (ROOT / "src" / "assets" / "styles.css").read_text(encoding="utf-8")
    source_js = (ROOT / "src" / "assets" / "app.js").read_text(encoding="utf-8")
    atomic_write(dist / "assets" / "qds-tokens.css", token_css)
    shutil.copyfile(ROOT / "src" / "assets" / "styles.css", dist / "assets" / "styles.css")
    shutil.copyfile(ROOT / "src" / "assets" / "app.js", dist / "assets" / "app.js")

    search_index = []
    section_to_page: dict[int, tuple[str, str]] = {}
    for slug, page_title, numbers, _ in PAGES:
        path = "index.html" if slug == "index" else f"pages/{slug}.html"
        for number in numbers:
            section_to_page[number] = (path, page_title)
    for section in sections:
        path, page_title = section_to_page[section.number]
        search_index.append(
            {
                "section": section.number,
                "title": section.title,
                "page": page_title,
                "path": path,
                "text": plain_text(section.markdown)[:1200],
            }
        )
    atomic_write(dist / "assets" / "search-index.json", json.dumps(search_index, ensure_ascii=False, indent=2) + "\n")

    for slug, page_title, numbers, summary in PAGES:
        sections_html = "\n".join(render_section(section_map[number]) for number in numbers)
        if slug == "components":
            sections_html += render_component_catalog()
        if slug == "audit":
            sections_html += render_audit_appendix()
        root = "" if slug == "index" else "../"
        document = shell(
            page_slug=slug,
            page_title=page_title,
            page_summary=summary,
            section_html=sections_html,
            root=root,
            version=version,
        )
        target = dist / "index.html" if slug == "index" else dist / "pages" / f"{slug}.html"
        atomic_write(target, document)

    standalone_sections = []
    for section in sections:
        standalone_sections.append(render_section(section))
        if section.number == 9:
            standalone_sections.append(render_component_catalog())
    all_sections = "\n".join(standalone_sections) + render_audit_appendix()
    standalone = shell(
        page_slug="index",
        page_title=title,
        page_summary="Complete standalone human reference for the QenTerra family design system.",
        section_html=all_sections,
        root="",
        version=version,
        standalone=True,
        token_css=token_css,
        source_css=source_css,
        source_js=source_js,
        search_index=search_index,
    )
    atomic_write(dist / "qenterra-design-system.html", standalone)

    print(f"Built QenTerra Design System {version}")
    print(f"  Sections: {len(sections)}")
    print(f"  Pages: {len(PAGES)} + standalone")
    print(f"  Search entries: {len(search_index)}")


if __name__ == "__main__":
    build()
