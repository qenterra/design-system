from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GENERATOR = ROOT / "scripts/generate.py"


def load_generator():
    if not GENERATOR.is_file():
        raise AssertionError("scripts/generate.py is missing")
    spec = importlib.util.spec_from_file_location("design_system_generator", GENERATOR)
    if spec is None or spec.loader is None:
        raise AssertionError("cannot load scripts/generate.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class GenerationContractTests(unittest.TestCase):
    def test_generated_outputs_are_current(self) -> None:
        generator = load_generator()
        outputs = generator.build_outputs(ROOT)
        self.assertGreaterEqual(len(outputs), 8)
        for relative, expected in outputs.items():
            with self.subTest(relative=relative):
                path = ROOT / relative
                self.assertTrue(path.is_file(), f"{relative} is missing")
                self.assertEqual(path.read_text(encoding="utf-8"), expected)

    def test_public_generated_apis_use_active_terminology(self) -> None:
        generator = load_generator()
        outputs = generator.build_outputs(ROOT)
        css = outputs["packages/npm/design-tokens/dist/tokens.css"]
        swift = outputs[
            "packages/Sources/QenTerraDesignTokens/GeneratedTokens.swift"
        ]
        icons = outputs[
            "packages/Sources/QenTerraDesignTokens/GeneratedIcons.swift"
        ]
        self.assertIn("--design-system-action-primary", css)
        self.assertIn("public enum GeneratedTokens", swift)
        self.assertIn("public enum Opacity", swift)
        self.assertIn("public enum ZIndex", swift)
        self.assertIn("DesignColorValue", swift)
        self.assertIn("public enum DesignIcon", icons)
        for legacy in ("QDS", "qds-", "DesignSystem"):
            self.assertNotIn(legacy, css + swift + icons)

    def test_css_recipes_are_generated_from_the_public_source(self) -> None:
        generator = load_generator()
        outputs = generator.build_outputs(ROOT)
        source = (ROOT / "packages/npm/design-tokens/src/recipes.css").read_text(encoding="utf-8")
        self.assertEqual(source, outputs["packages/npm/design-tokens/dist/recipes.css"])


if __name__ == "__main__":
    unittest.main()
