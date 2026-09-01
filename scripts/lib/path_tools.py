"""Shared lowercase kebab-case path normalization helpers."""

from __future__ import annotations

import re
from pathlib import PurePosixPath


SPECIAL_WORDS = {
    "QenTerra": "qenterra",
    "UIable": "uiable",
    "SVGs": "svgs",
}


def _normalize_word(word: str) -> str:
    for source, destination in SPECIAL_WORDS.items():
        word = word.replace(source, destination)
    word = word.replace("'", "")
    word = re.sub(r"[^A-Za-z0-9]+", "-", word)
    word = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1-\2", word)
    word = re.sub(r"([a-z0-9])([A-Z])", r"\1-\2", word)
    return re.sub(r"-+", "-", word).strip("-").lower()


def kebab_component(name: str) -> str:
    """Normalize one ordinary path component while preserving a leading dot."""
    hidden = name.startswith(".") and name not in {".", ".."}
    body = name[1:] if hidden else name
    normalized = ".".join(_normalize_word(part) for part in body.split("."))
    return f".{normalized}" if hidden else normalized


def kebab_posix_path(path: str | PurePosixPath) -> PurePosixPath:
    """Normalize every component of a safe relative POSIX path."""
    source = PurePosixPath(path)
    if source.is_absolute() or ".." in source.parts:
        raise ValueError(f"path must be safe and relative: {source}")
    return PurePosixPath(*(kebab_component(part) for part in source.parts))
