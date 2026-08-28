from __future__ import annotations

import base64
import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts" / "brand"))

from validate_brand_assets import lfs_paths, validate_brand_assets  # noqa: E402


PNG_1X1 = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
)


class BrandAssetValidatorTests(unittest.TestCase):
    def make_valid_root(self, directory: str) -> Path:
        root = Path(directory)
        asset = root / "assets" / "brand" / "qenterra" / "logos" / "raster" / "Logo.png"
        asset.parent.mkdir(parents=True)
        asset.write_bytes(PNG_1X1)
        digest = hashlib.sha256(PNG_1X1).hexdigest()
        manifest = {
            "schemaVersion": 1,
            "sourceLabel": "My Brandbook",
            "assetCount": 1,
            "totalBytes": len(PNG_1X1),
            "assets": [
                {
                    "sourcePath": "Logos/Raster/Logo.png",
                    "canonicalPath": "assets/brand/qenterra/logos/raster/Logo.png",
                    "category": "qenterra.logo.raster",
                    "extension": ".png",
                    "mimeType": "image/png",
                    "bytes": len(PNG_1X1),
                    "sha256": digest,
                    "width": 1,
                    "height": 1,
                    "mode": "grayscale-alpha",
                    "bitDepth": 8,
                    "lfs": True,
                }
            ],
        }
        (root / "assets" / "brand" / "manifest.json").write_text(
            json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
        )
        (root / ".gitattributes").write_text(
            "assets/brand/**/*.png filter=lfs diff=lfs merge=lfs -text\n", encoding="utf-8"
        )
        return root

    def test_valid_manifest_passes(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = self.make_valid_root(directory)
            self.assertEqual(validate_brand_assets(root), [])

    def test_missing_manifest_entry_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = self.make_valid_root(directory)
            manifest_path = root / "assets" / "brand" / "manifest.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            manifest["assets"] = []
            manifest["assetCount"] = 0
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
            errors = validate_brand_assets(root)
            self.assertTrue(any("untracked canonical assets" in error for error in errors))

    def test_hash_drift_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = self.make_valid_root(directory)
            asset = root / "assets" / "brand" / "qenterra" / "logos" / "raster" / "Logo.png"
            asset.write_bytes(PNG_1X1 + b"drift")
            errors = validate_brand_assets(root)
            self.assertTrue(any("SHA-256 drift" in error for error in errors))

    def test_duplicate_canonical_path_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = self.make_valid_root(directory)
            manifest_path = root / "assets" / "brand" / "manifest.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            manifest["assets"].append(dict(manifest["assets"][0]))
            manifest["assetCount"] = 2
            manifest["totalBytes"] *= 2
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
            errors = validate_brand_assets(root)
            self.assertTrue(any("duplicate canonicalPath" in error for error in errors))

    def test_missing_lfs_policy_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = self.make_valid_root(directory)
            (root / ".gitattributes").write_text("*.png binary\n", encoding="utf-8")
            errors = validate_brand_assets(root)
            self.assertTrue(any("Git LFS policy" in error for error in errors))

    def test_extra_ds_store_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = self.make_valid_root(directory)
            (root / "assets" / "brand" / ".DS_Store").write_bytes(b"finder")
            errors = validate_brand_assets(root)
            self.assertTrue(any("forbidden file" in error for error in errors))

    def test_lfs_inventory_ignores_paths_deleted_from_the_worktree(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            existing = root / "assets/brand/nyx/Current.png"
            existing.parent.mkdir(parents=True)
            existing.write_bytes(PNG_1X1)
            output = "assets/brand/nyx/Current.png\nassets/brand/qenterra/Deleted.png\n"
            with patch("validate_brand_assets.subprocess.run") as run:
                run.return_value.returncode = 0
                run.return_value.stdout = output
                run.return_value.stderr = ""
                self.assertEqual(lfs_paths(root), {"assets/brand/nyx/Current.png"})


if __name__ == "__main__":
    unittest.main()
