from __future__ import annotations

import copy
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from lib.token_tools import load_json  # noqa: E402
from validate import (  # noqa: E402
    TOKEN_NAMES,
    validate_contrast,
    validate_css,
    validate_html_tree,
    validate_token_data,
)


class ValidatorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
        cls.tokens = {name: load_json(ROOT / "tokens" / f"{name}.json") for name in TOKEN_NAMES}

    def test_valid_tokens_pass(self) -> None:
        self.assertEqual(validate_token_data(self.version, self.tokens), [])

    def test_missing_meta_fails(self) -> None:
        tokens = copy.deepcopy(self.tokens)
        del tokens["motion"]["meta"]
        errors = validate_token_data(self.version, tokens)
        self.assertTrue(any("motion.json: missing meta" in error for error in errors))

    def test_unknown_reference_fails(self) -> None:
        tokens = copy.deepcopy(self.tokens)
        tokens["components"]["button"]["radius"] = "{radius.nonexistent}"
        errors = validate_token_data(self.version, tokens)
        self.assertTrue(any("unknown reference" in error for error in errors))

    def test_low_contrast_fails(self) -> None:
        tokens = copy.deepcopy(self.tokens)
        tokens["semantic"]["modes"]["light"]["text"]["secondary"] = "{color.graphite.50}"
        errors, _ = validate_contrast(tokens)
        self.assertTrue(any("contrast" in error for error in errors))

    def test_missing_css_variable_fails(self) -> None:
        errors = validate_css(".x { color: var(--qds-missing-token); }", ":root { --qds-known: #fff; }")
        self.assertTrue(any("undefined QDS variables" in error for error in errors))

    def test_broken_html_link_fails_without_writing_target(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            index = root / "index.html"
            index.write_text('<!doctype html><html><body><a href="missing.html">Missing</a></body></html>', encoding="utf-8")
            errors = validate_html_tree(root)
            self.assertTrue(any("broken link" in error for error in errors))
            self.assertFalse((root / "missing.html").exists())


if __name__ == "__main__":
    unittest.main()
