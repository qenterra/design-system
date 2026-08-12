from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from brand.build_asset_browser import build_browser  # noqa: E402


class BrandBrowserTests(unittest.TestCase):
    def test_temporary_browser_contains_manifested_assets(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = build_browser(Path(directory) / "browser")
            text = target.read_text(encoding="utf-8")
            manifest = json.loads((ROOT / "assets" / "brand" / "manifest.json").read_text(encoding="utf-8"))
            self.assertIn(f"{manifest['assetCount']} canonical files", text)
            self.assertIn("QenTerra Logo.svg", text)
            self.assertIn("data-asset", text)

    def test_repository_output_is_rejected_before_write(self) -> None:
        target = ROOT / "output" / "forbidden-brand-browser"
        with self.assertRaisesRegex(ValueError, "outside the repository"):
            build_browser(target)
        self.assertFalse(target.exists())


if __name__ == "__main__":
    unittest.main()
