from __future__ import annotations

import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class DocumentationAlignmentTests(unittest.TestCase):
    def test_master_references_have_the_same_numbered_structure(self) -> None:
        english = (ROOT / "docs/MASTER.md").read_text(encoding="utf-8")
        russian = (ROOT / "docs/MASTER_RU.md").read_text(encoding="utf-8")
        section = re.compile(r"^## (\d+)\. ", flags=re.MULTILINE)
        self.assertEqual(section.findall(english), [str(index) for index in range(22)])
        self.assertEqual(section.findall(russian), [str(index) for index in range(22)])

    def test_both_master_references_cover_public_package_delivery(self) -> None:
        for relative in ("docs/MASTER.md", "docs/MASTER_RU.md"):
            text = (ROOT / relative).read_text(encoding="utf-8")
            with self.subTest(relative=relative):
                self.assertIn("qenterra/packages", text)
                self.assertIn("@qenterra/design-tokens", text)
                self.assertIn("QenTerraDesignTokens", text)
                self.assertIn("QenTerraComponents", text)
                self.assertIn("Sources/ShadcnUI/", text)
                self.assertIn("scripts/shadcn_ui.py", text)
                self.assertIn("Sources/UIable/", text)
                self.assertIn("scripts/uiable.py", text)
                self.assertIn("Sources/ReUI/", text)
                self.assertIn("scripts/reui.py", text)


if __name__ == "__main__":
    unittest.main()
