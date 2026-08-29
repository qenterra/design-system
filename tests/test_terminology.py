from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/verify_terminology.py"


def load_module():
    if not SCRIPT.is_file():
        raise AssertionError("scripts/verify_terminology.py is missing")
    spec = importlib.util.spec_from_file_location("terminology", SCRIPT)
    if spec is None or spec.loader is None:
        raise AssertionError("cannot load terminology verifier")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class TerminologyTests(unittest.TestCase):
    def test_active_repository_uses_design_system_name(self) -> None:
        module = load_module()
        self.assertEqual(module.validate_terminology(ROOT), [])

    def test_legacy_active_name_is_reported(self) -> None:
        module = load_module()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "README.md").write_text("Use QDS here.\n", encoding="utf-8")
            errors = module.validate_terminology(root)
        self.assertEqual(errors, ["README.md:1: legacy term 'QDS'"])

    def test_historical_records_are_allowed(self) -> None:
        module = load_module()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            decision = root / "docs/decisions/0001-old-name.md"
            decision.parent.mkdir(parents=True)
            decision.write_text("Historical QDS decision.\n", encoding="utf-8")
            errors = module.validate_terminology(root)
        self.assertEqual(errors, [])


if __name__ == "__main__":
    unittest.main()
