from __future__ import annotations

import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class SwiftPackageLayoutTests(unittest.TestCase):
    def test_reference_catalogs_are_not_swiftpm_targets(self) -> None:
        manifest = (ROOT / "packages/Package.swift").read_text(encoding="utf-8")
        self.assertNotIn("ExploreSwiftUI", manifest)
        self.assertNotIn("MagicUI", manifest)
        self.assertNotIn("ShadcnUI", manifest)
        self.assertNotIn("UIable", manifest)
        self.assertNotIn("ReUI", manifest)

    def test_products_use_explicit_qenterra_source_paths(self) -> None:
        manifest = (ROOT / "packages/Package.swift").read_text(encoding="utf-8")
        self.assertIn('path: "Sources/QenTerra/DesignTokens"', manifest)
        self.assertIn('path: "Sources/QenTerra/Components"', manifest)
        self.assertNotIn('.library(name: "ExploreSwiftUI"', manifest)
        self.assertNotIn('name: "ExploreSwiftUI"', manifest)

    def test_old_swift_source_layout_is_absent(self) -> None:
        self.assertFalse((ROOT / "packages/Sources/QenTerraDesignTokens").exists())
        self.assertFalse((ROOT / "packages/Sources/QenTerraComponents").exists())

    def test_each_qenterra_component_has_its_own_file(self) -> None:
        component_root = ROOT / "packages/Sources/QenTerra/Components"
        self.assertFalse((component_root / "Components.swift").exists())
        self.assertEqual(
            {path.name for path in component_root.glob("*.swift")},
            {
                "GroupContainer.swift",
                "InteractiveRowSurface.swift",
                "PrimaryButtonStyle.swift",
            },
        )


if __name__ == "__main__":
    unittest.main()
