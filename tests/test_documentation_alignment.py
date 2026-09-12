from __future__ import annotations

import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class DocumentationAlignmentTests(unittest.TestCase):
    def test_changelogs_preserve_history_and_link_the_canonical_release(self) -> None:
        version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
        for relative in ("CHANGELOG.md", "packages/CHANGELOG.md"):
            text = (ROOT / relative).read_text(encoding="utf-8")
            with self.subTest(relative=relative):
                self.assertRegex(text, rf"(?m)^## \[{re.escape(version)}\] - \d{{4}}-\d{{2}}-\d{{2}}$")
                self.assertIn("## [1.0.1] - 2026-09-02", text)
                self.assertIn("## [1.0.0] - 2026-09-01", text)
                self.assertNotIn("## [1.0.0] - Pending release", text)
                self.assertIn(
                    f"[Unreleased]: https://github.com/QenTerra/design-system/compare/v{version}...HEAD",
                    text,
                )
                self.assertIn(
                    "[1.0.0]: https://github.com/QenTerra/design-system/releases/tag/v1.0.0",
                    text,
                )

    def test_master_references_have_the_same_numbered_structure(self) -> None:
        english = (ROOT / "docs/MASTER.md").read_text(encoding="utf-8")
        russian = (ROOT / "docs/MASTER_RU.md").read_text(encoding="utf-8")
        section = re.compile(r"^## (\d+)\. ", flags=re.MULTILINE)
        self.assertEqual(section.findall(english), [str(index) for index in range(21)])
        self.assertEqual(section.findall(russian), [str(index) for index in range(21)])

    def test_both_master_references_cover_public_package_delivery(self) -> None:
        for relative in ("docs/MASTER.md", "docs/MASTER_RU.md"):
            text = (ROOT / relative).read_text(encoding="utf-8")
            with self.subTest(relative=relative):
                self.assertIn("qenterra/design-system", text)
                self.assertIn("@qenterra/design-tokens", text)
                self.assertIn("QenTerraDesignTokens", text)
                self.assertIn("QenTerraComponents", text)
                self.assertIn("Sources/ShadcnUI/", text)
                self.assertIn("scripts/shadcn_ui.py", text)
                self.assertIn("Sources/UIable/", text)
                self.assertIn("scripts/uiable.py", text)
                self.assertIn("Sources/ReUI/", text)
                self.assertIn("scripts/reui.py", text)
                self.assertIn("Sources/TablerIcons/", text)
                self.assertIn("Sources/PhosphorIcons/", text)
                self.assertIn("Sources/Iconoir/", text)
                self.assertIn("Sources/BootstrapIcons/", text)
                self.assertIn("scripts/icon_catalogs.py", text)


if __name__ == "__main__":
    unittest.main()
