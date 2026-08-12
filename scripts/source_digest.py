#!/usr/bin/env python3
"""Print the deterministic digest for rendered QDS reference sources."""

from __future__ import annotations

from pathlib import Path

from lib.reference_sources import rendered_reference_source_digest


ROOT = Path(__file__).resolve().parents[1]


if __name__ == "__main__":
    print(rendered_reference_source_digest(ROOT))
