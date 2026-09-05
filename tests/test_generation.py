from __future__ import annotations

import copy
import importlib.util
import json
import re
import tempfile
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
            "packages/Sources/QenTerra/DesignTokens/GeneratedTokens.swift"
        ]
        icons = outputs[
            "packages/Sources/QenTerra/DesignTokens/GeneratedIcons.swift"
        ]
        self.assertIn("--design-system-action-primary", css)
        self.assertIn("public enum GeneratedTokens", swift)
        self.assertIn("public enum Opacity", swift)
        self.assertIn("public enum ZIndex", swift)
        self.assertIn("DesignColorValue", swift)
        self.assertIn("public enum DesignIcon", icons)
        for legacy in ("QDS", "qds-", "DesignSystem"):
            self.assertNotIn(legacy, css + swift + icons)

    def test_product_profiles_are_generated_from_canonical_sources(self) -> None:
        generator = load_generator()
        version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
        products = json.loads((ROOT / "tokens/products.json").read_text(encoding="utf-8"))
        platforms = json.loads((ROOT / "tokens/platforms.json").read_text(encoding="utf-8"))
        components = json.loads((ROOT / "tokens/components.json").read_text(encoding="utf-8"))

        output = generator.build_outputs(ROOT)[
            "packages/Sources/QenTerra/DesignTokens/GeneratedProductProfiles.swift"
        ]
        self.assertIn("public enum GeneratedProductProfiles", output)
        self.assertIn("public static let cadence", output)
        self.assertIn("textStack: 4", output)
        self.assertIn(f"// Design System {version}", output)
        self.assertEqual(set(re.findall(r"\b\d+\.\d+\.\d+\b", output)), {version})
        self.assertEqual(
            products["immersiveContent"]["cadence"]["motion"]["cadenceModeEnterMs"],
            500,
        )

        changed_products = copy.deepcopy(products)
        changed_products["immersiveContent"]["cadence"]["layout"]["textStack"] = 99
        self.assertIn(
            "textStack: 99",
            generator.generate_swift_product_profiles(changed_products, platforms, components),
        )

        changed_platforms = copy.deepcopy(platforms)
        changed_platforms.pop("macOS")
        with self.assertRaisesRegex(ValueError, "macOS"):
            generator.generate_swift_product_profiles(products, changed_platforms, components)

    def test_component_semantic_values_preserve_their_units(self) -> None:
        generator = load_generator()
        outputs = generator.build_outputs(ROOT)
        css = outputs["packages/npm/design-tokens/dist/tokens.css"]
        swift = outputs["packages/Sources/QenTerra/DesignTokens/GeneratedTokens.swift"]
        self.assertIn("--design-system-component-panel-lyrics-inactive-opacity: 0.56;", css)
        self.assertNotIn("--design-system-component-panel-lyrics-inactive-opacity: 0.56px;", css)
        self.assertIn("--design-system-component-panel-lyrics-follow-duration-ms: 320ms;", css)
        self.assertNotIn("--design-system-component-panel-lyrics-follow-duration-ms: 320px;", css)
        self.assertIn("DesignComponentOpacity(value: 0.56)", swift)
        self.assertNotIn(
            "panelLyricsInactiveOpacity = DesignComponentMetric(points: 0.56)",
            swift,
        )
        self.assertIn("DesignComponentDuration(milliseconds: 320)", swift)
        self.assertNotIn(
            "panelLyricsFollowDurationMs = DesignComponentMetric(points: 320)",
            swift,
        )
        self.assertIn("DesignComponentMetric(points: 12)", swift)

    def test_qenterra_component_manifest_is_generated_from_private_registry(self) -> None:
        generator = load_generator()
        outputs = generator.build_outputs(ROOT)
        manifest = outputs["packages/Sources/QenTerra/manifest.json"]
        self.assertIn('"sourceRegistry": "registry/qenterra-components.json"', manifest)
        self.assertIn(
            '"sourcePath": "Sources/QenTerra/Components/PrimaryButtonStyle.swift"',
            manifest,
        )
        self.assertIn('"deliveryProduct": "QenTerraComponents"', manifest)
        self.assertIn('"sha256"', manifest)

    def test_component_manifest_rejects_delivery_product_path_mismatch(self) -> None:
        generator = load_generator()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "VERSION").write_text("1.0.1\n", encoding="utf-8")
            source = root / "packages/Sources/QenTerra/MediaComponents/MediaComponents.swift"
            source.parent.mkdir(parents=True)
            source.write_text("public enum MediaFixture {}\n", encoding="utf-8")
            registry = root / "registry/qenterra-components.json"
            registry.parent.mkdir(parents=True)
            registry.write_text(
                json.dumps(
                    {
                        "version": "1.0.1",
                        "components": [
                            {
                                "id": "media-fixture",
                                "name": "MediaFixture",
                                "category": "media",
                                "status": "stable",
                                "sourcePath": "packages/Sources/QenTerra/MediaComponents/MediaComponents.swift",
                                "deliveryProduct": "QenTerraComponents",
                                "publicSymbols": ["MediaFixture"],
                                "designTokens": True,
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "deliveryProduct"):
                generator.build_qenterra_component_manifest(root, "1.0.1")

    def test_css_recipes_are_generated_from_the_public_source(self) -> None:
        generator = load_generator()
        outputs = generator.build_outputs(ROOT)
        source = (ROOT / "packages/npm/design-tokens/src/recipes.css").read_text(encoding="utf-8")
        self.assertEqual(source, outputs["packages/npm/design-tokens/dist/recipes.css"])


if __name__ == "__main__":
    unittest.main()
