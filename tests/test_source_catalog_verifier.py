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


if __name__ == "__main__":
    unittest.main()
