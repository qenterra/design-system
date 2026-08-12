"""Deterministic source inventory for the rendered QDS reference."""

from __future__ import annotations

import hashlib
from pathlib import Path


RENDERED_REFERENCE_INPUTS = (
    "VERSION",
    "tokens/*.json",
    "registry/components.json",
    "registry/contact-channels.json",
    "registry/email-templates.json",
    "registry/icons.json",
    "src/assets/*.css",
    "src/assets/*.js",
    "docs/MASTER.md",
    "docs/MASTER.ru.md",
    "docs/COMPONENT_CATALOG.md",
    "docs/COMPONENT_CATALOG.ru.md",
    "docs/CONSUMER_ADOPTION.md",
    "docs/CONSUMER_ADOPTION.ru.md",
    "docs/DEVELOPMENT.md",
    "docs/DEVELOPMENT.ru.md",
    "docs/CODE.md",
    "docs/CODE.ru.md",
    "docs/COMMITS.md",
    "docs/COMMITS.ru.md",
    "docs/LICENSES.md",
    "docs/LICENSES.ru.md",
    "docs/brand/MASTER.md",
    "docs/brand/MASTER.ru.md",
    "docs/brand/QENTERRA.md",
    "docs/brand/QENTERRA.ru.md",
    "docs/brand/NYX.md",
    "docs/brand/NYX.ru.md",
    "docs/brand/ASSET_CATALOG.md",
    "docs/brand/ASSET_CATALOG.ru.md",
    "docs/repository/STANDARD.md",
    "docs/repository/STANDARD.ru.md",
    "assets/brand/nyx/character-assets/portraits/Portrait Soft Smile.png",
    "assets/brand/nyx/character-assets/full-body/Open Palm Presenting.png",
    "assets/brand/nyx/character-assets/compositions/Hero Copy Left.png",
    "assets/brand/nyx/character-assets/compositions/Right Edge Peek.png",
    "evidence/screenshots.json",
    "scripts/build.py",
    "scripts/render_screenshots.js",
    "scripts/render_sf_symbols.swift",
    "scripts/lib/markdown_renderer.py",
    "scripts/lib/pseudo_locales.py",
    "scripts/lib/site_locales.py",
    "scripts/lib/token_tools.py",
)


def rendered_reference_source_paths(root: Path) -> list[Path]:
    """Return the ordered, repository-relative sources rendered into ``dist``."""
    paths: set[Path] = set()
    for pattern in RENDERED_REFERENCE_INPUTS:
        matches = sorted(root.glob(pattern))
        if not matches:
            raise FileNotFoundError(f"rendered reference source is missing: {pattern}")
        paths.update(path for path in matches if path.is_file())
    return sorted(paths, key=lambda path: path.relative_to(root).as_posix())


def rendered_reference_source_digest(root: Path) -> str:
    """Hash rendered-reference inputs without timestamps or machine-local paths."""
    digest = hashlib.sha256()
    for path in rendered_reference_source_paths(root):
        relative = path.relative_to(root).as_posix().encode("utf-8")
        digest.update(len(relative).to_bytes(4, "big"))
        digest.update(relative)
        content = path.read_bytes()
        digest.update(len(content).to_bytes(8, "big"))
        digest.update(content)
    return f"sha256:{digest.hexdigest()}"
