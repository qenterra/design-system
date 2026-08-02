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
    validate_brand_sources,
    validate_css,
    validate_html_tree,
    validate_localized_sources,
    validate_packages,
    validate_repository_hygiene,
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

    def test_missing_russian_master_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "docs").mkdir()
            (root / "docs" / "MASTER.md").write_text("# Master\n\n## 0. Overview\n", encoding="utf-8")
            errors = validate_localized_sources(root)
            self.assertTrue(any("MASTER.ru.md" in error for error in errors))

    def test_superpowers_directory_fails_repository_hygiene(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "docs" / "superpowers").mkdir(parents=True)
            errors = validate_repository_hygiene(root)
            self.assertTrue(any("docs/superpowers" in error for error in errors))

    def test_nested_superpowers_directory_fails_repository_hygiene(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "assets" / "brand" / "superpowers").mkdir(parents=True)
            errors = validate_repository_hygiene(root)
            self.assertTrue(any("assets/brand/superpowers" in error for error in errors))

    def test_ds_store_fails_repository_hygiene(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            hidden = root / "assets" / "brand" / ".DS_Store"
            hidden.parent.mkdir(parents=True)
            hidden.write_bytes(b"finder metadata")
            errors = validate_repository_hygiene(root)
            self.assertTrue(any("Finder metadata" in error for error in errors))

    def test_existing_product_name_fails_universal_guide(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            root.mkdir(exist_ok=True)
            (root / "README.md").write_text("A guide for Cadence", encoding="utf-8")
            errors = validate_repository_hygiene(root)
            self.assertTrue(any("universal guide contains" in error for error in errors))

    def test_css_package_version_drift_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "packages" / "css").mkdir(parents=True)
            (root / "packages" / "css" / "package.json").write_text(
                '{"version":"0.0.0","private":true}', encoding="utf-8"
            )
            errors = validate_packages(root, self.version)
            self.assertTrue(any("does not match VERSION" in error for error in errors))

    def test_repository_locale_section_drift_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            docs = root / "docs"
            repository = docs / "repository"
            repository.mkdir(parents=True)
            (docs / "MASTER.md").write_text("# Master\n", encoding="utf-8")
            (docs / "MASTER.ru.md").write_text("# Мастер\n", encoding="utf-8")
            (repository / "STANDARD.md").write_text("# Standard\n\n## Only one\n", encoding="utf-8")
            (repository / "STANDARD.ru.md").write_text("# Стандарт\n", encoding="utf-8")
            errors = validate_localized_sources(root)
            self.assertTrue(any("repository standard section counts differ" in error for error in errors))

    def test_current_brand_sources_pass(self) -> None:
        self.assertEqual(validate_brand_sources(ROOT), [])

    def test_missing_brand_pair_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "docs" / "brand").mkdir(parents=True)
            errors = validate_brand_sources(root)
            self.assertTrue(any("QENTERRA.md: missing brand reference" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
