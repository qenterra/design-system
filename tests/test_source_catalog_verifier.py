from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
VERIFIER = ROOT / "packages/scripts/verify_source_catalogs.py"


class SourceCatalogVerifierTests(unittest.TestCase):
    def test_public_source_catalogs_are_closed_and_hash_exact(self) -> None:
        spec = importlib.util.spec_from_file_location("source_catalog_verifier", VERIFIER)
        if spec is None or spec.loader is None:
            self.fail("cannot load public source catalog verifier")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        self.assertEqual(module.validate_catalogs(ROOT / "packages"), [])

    def test_shadcn_ui_catalog_is_part_of_the_public_verifier(self) -> None:
        self.assertTrue(
            (ROOT / "packages/Sources/ShadcnUI/manifest.json").is_file(),
            "the exact shadcn/ui catalog is missing",
        )
        content = VERIFIER.read_text(encoding="utf-8")
        self.assertIn("Sources/ShadcnUI/manifest.json", content)
        self.assertIn("Sources/ShadcnUI/Components/", content)

    def test_magic_ui_catalog_is_part_of_the_public_verifier(self) -> None:
        self.assertTrue(
            (ROOT / "packages/Sources/MagicUI/manifest.json").is_file(),
            "the exact Magic UI catalog is missing",
        )
        content = VERIFIER.read_text(encoding="utf-8")
        self.assertIn("Sources/MagicUI/manifest.json", content)
        self.assertIn("Sources/MagicUI/Components/", content)
        self.assertIn("Sources/MagicUI/Registry/", content)

    def test_uiable_catalog_is_part_of_the_public_verifier(self) -> None:
        self.assertTrue(
            (ROOT / "packages/Sources/UIable/manifest.json").is_file(),
            "the exact UIable catalog is missing",
        )
        content = VERIFIER.read_text(encoding="utf-8")
        self.assertIn("Sources/UIable/manifest.json", content)
        self.assertIn("Sources/UIable/Components/", content)
        self.assertIn("Sources/UIable/Primitives/", content)
        self.assertIn("Sources/UIable/Registry/", content)

    def test_reui_catalog_is_part_of_the_public_verifier(self) -> None:
        self.assertTrue(
            (ROOT / "packages/Sources/ReUI/manifest.json").is_file(),
            "the exact ReUI catalog is missing",
        )
        content = VERIFIER.read_text(encoding="utf-8")
        self.assertIn("Sources/ReUI/manifest.json", content)
        self.assertIn("Sources/ReUI/Base/", content)
        self.assertIn("Sources/ReUI/Radix/", content)
        self.assertIn("Sources/ReUI/Registry/", content)


if __name__ == "__main__":
    unittest.main()
