#!/usr/bin/env python3
"""Build a searchable temporary HTML browser for canonical brand assets."""

from __future__ import annotations

import argparse
import html
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def inside(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
        return True
    except ValueError:
        return False


def build_browser(output: Path) -> Path:
    output = output.resolve()
    if inside(output, ROOT):
        raise ValueError("brand asset browser must be generated outside the repository")
    output.mkdir(parents=True, exist_ok=True)
    manifest = json.loads((ROOT / "assets" / "brand" / "manifest.json").read_text(encoding="utf-8"))
    cards = []
    for asset in manifest["assets"]:
        canonical = asset["canonicalPath"]
        source = (ROOT / canonical).resolve().as_uri()
        preview = (
            f'<img src="{source}" loading="lazy" alt="">'
            if asset["extension"] == ".png"
            else '<div class="vector">SVG</div>'
        )
        search = html.escape(f"{canonical} {asset['category']}", quote=True)
        cards.append(
            f'<article data-asset data-search="{search}">{preview}<strong>{html.escape(Path(canonical).name)}</strong>'
            f'<span>{html.escape(asset["category"])}</span><code>{html.escape(canonical)}</code></article>'
        )
    document = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>QenTerra Brand Asset Browser</title><style>
body{{margin:0;background:#171719;color:#fff;font:14px -apple-system,sans-serif}}header{{position:sticky;top:0;padding:16px;background:#171719eF;backdrop-filter:blur(18px);z-index:2}}input{{width:min(100%,560px);padding:10px;border:1px solid #ffffff22;border-radius:6px;background:#27272b;color:#fff}}main{{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:12px;padding:16px}}article{{display:grid;gap:8px;padding:12px;border:1px solid #ffffff16;border-radius:14px;background:#202023}}img,.vector{{width:100%;aspect-ratio:1;object-fit:contain;border-radius:10px;background:#0f0f11}}.vector{{display:grid;place-items:center;color:#94949d}}span,code{{color:#b9b9c0;font-size:11px;overflow-wrap:anywhere}}[hidden]{{display:none}}
</style></head><body><header><h1>Brand assets</h1><p>{manifest['assetCount']} canonical files · temporary read-only browser</p><input type="search" aria-label="Filter assets" placeholder="Name, category, or path" data-filter></header>
<main>{''.join(cards)}</main><script>const q=document.querySelector('[data-filter]');q.addEventListener('input',()=>{{const v=q.value.toLowerCase();document.querySelectorAll('[data-asset]').forEach(x=>x.hidden=!x.dataset.search.toLowerCase().includes(v))}})</script></body></html>"""
    target = output / "index.html"
    target.write_text(document, encoding="utf-8")
    return target


def main() -> int:
    parser = argparse.ArgumentParser(description="Build temporary QenTerra brand asset browser")
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    try:
        target = build_browser(args.output)
    except ValueError as error:
        parser.error(str(error))
    print(target)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
