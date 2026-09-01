from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class TypographyAssetValidatorTests(unittest.TestCase):
    def run_validator(self, root: Path) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                sys.executable,
                str(ROOT / "scripts" / "verify_typography_assets.py"),
                "--root",
                str(root),
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )

    def make_catalog_root(self, directory: str) -> Path:
        root = Path(directory)
        shutil.copytree(ROOT / "assets" / "typography", root / "assets" / "typography")
        return root

    def test_repository_typography_catalog_is_valid(self) -> None:
        result = self.run_validator(ROOT)

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_hash_drift_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = self.make_catalog_root(directory)
            font = root / "assets" / "typography" / "onest" / "Onest[wght].ttf"
            font.write_bytes(font.read_bytes() + b"drift")

            result = self.run_validator(root)

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("SHA-256 drift", result.stdout + result.stderr)

    def test_untracked_asset_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = self.make_catalog_root(directory)
            extra = root / "assets" / "typography" / "onest" / "forgotten.woff2"
            extra.write_bytes(b"wOF2")

            result = self.run_validator(root)

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("untracked typography assets", result.stdout + result.stderr)

    def test_universal_ui_default_change_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = self.make_catalog_root(directory)
            manifest_path = root / "assets" / "typography" / "manifest.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            manifest["universalUiDefaultsChanged"] = True
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

            result = self.run_validator(root)

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("must not change universal UI defaults", result.stdout + result.stderr)

    def test_declared_axis_drift_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = self.make_catalog_root(directory)
            manifest_path = root / "assets" / "typography" / "manifest.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            manifest["families"][1]["axes"][0]["max"] = 850.0
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

            result = self.run_validator(root)

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("axis mismatch for Onest wght", result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
