from __future__ import annotations

import copy
import json
import shutil
import struct
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from lib.token_tools import load_json  # noqa: E402
from compare_screenshots import pixel_changed  # noqa: E402
from validate import (  # noqa: E402
    TOKEN_NAMES,
    validate_contrast,
    validate_brand_sources,
    validate_browser_evidence,
    validate_contact_channels,
    validate_component_registry,
    validate_code_system_templates,
    validate_icon_registry,
    validate_css,
    validate_html_tree,
    validate_localized_sources,
    validate_packages,
    validate_repository_hygiene,
    validate_token_data,
    validate_token_schemas,
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

    def test_token_schema_rejects_unknown_top_level_key(self) -> None:
        tokens = copy.deepcopy(self.tokens)
        tokens["foundation"]["surprise"] = {"value": 1}
        errors = validate_token_schemas(ROOT, tokens)
        self.assertTrue(any("foundation.json:surprise" in error for error in errors))

    def test_reference_cycle_fails(self) -> None:
        tokens = copy.deepcopy(self.tokens)
        tokens["foundation"]["space"]["cycleA"] = "{space.cycleB}"
        tokens["foundation"]["space"]["cycleB"] = "{space.cycleA}"
        errors = validate_token_data(self.version, tokens)
        self.assertTrue(any("reference cycle" in error for error in errors))

    def test_unapproved_raw_component_metric_fails(self) -> None:
        tokens = copy.deepcopy(self.tokens)
        tokens["components"]["button"]["mysteryInset"] = 13
        errors = validate_token_data(self.version, tokens)
        self.assertTrue(any("raw component metric" in error for error in errors))

    def test_low_contrast_fails(self) -> None:
        tokens = copy.deepcopy(self.tokens)
        tokens["semantic"]["modes"]["light"]["text"]["secondary"] = "{color.graphite.50}"
        errors, _ = validate_contrast(tokens)
        self.assertTrue(any("contrast" in error for error in errors))

    def test_missing_css_variable_fails(self) -> None:
        errors = validate_css(".x { color: var(--qds-missing-token); }", ":root { --qds-known: #fff; }")
        self.assertTrue(any("undefined QDS variables" in error for error in errors))

    def test_css_requires_forced_colors_and_rejects_raw_visual_values(self) -> None:
        source = """
        .card {
          box-shadow: 0 12px 32px rgb(0 0 0 / 18%);
          border-color: #888;
        }
        @media (prefers-reduced-motion: reduce) {}
        .card:focus-visible {}
        """
        errors = validate_css(source, ":root { --qds-shadow-overlay: none; }")
        self.assertTrue(any("missing Forced Colors adaptation" in error for error in errors))
        self.assertTrue(any("raw visual value" in error for error in errors))

    def test_forced_colors_buttons_use_explicit_system_colors(self) -> None:
        source = (ROOT / "src" / "assets" / "styles.css").read_text(encoding="utf-8")
        forced_colors = source.split("@media (forced-colors: active)", 1)[1].split(
            ".component-lab", 1
        )[0]

        self.assertIn("forced-color-adjust: none", forced_colors)
        self.assertIn("background: ButtonFace", forced_colors)
        self.assertIn("background: Highlight", forced_colors)
        self.assertIn("color: HighlightText", forced_colors)

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

    def test_missing_code_system_document_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            docs = root / "docs"
            docs.mkdir()
            (docs / "MASTER.md").write_text("# Master\n", encoding="utf-8")
            (docs / "MASTER.ru.md").write_text("# Мастер\n", encoding="utf-8")
            errors = validate_localized_sources(root)
            self.assertTrue(any("docs/CODE.md" in error for error in errors))

    def test_code_system_template_inventory_and_json_are_validated(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            tooling = root / "templates" / "repository" / "tooling" / "typescript"
            tooling.mkdir(parents=True)
            (tooling / ".prettierrc.json").write_text("{ invalid", encoding="utf-8")
            errors = validate_code_system_templates(root)
            self.assertTrue(any(".prettierrc.json" in error for error in errors))

    def test_master_version_drift_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            shutil.copytree(ROOT / "docs", root / "docs")
            (root / "VERSION").write_text(self.version + "\n", encoding="utf-8")
            for filename in ("MASTER.md", "MASTER.ru.md"):
                path = root / "docs" / filename
                path.write_text(
                    path.read_text(encoding="utf-8").replace(self.version, "1.3.0", 1),
                    encoding="utf-8",
                )
            errors = validate_localized_sources(root)
            self.assertTrue(any("version 1.3.0 does not match VERSION" in error for error in errors))

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

    def test_css_package_version_drift_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "packages" / "css").mkdir(parents=True)
            (root / "packages" / "css" / "package.json").write_text(
                '{"version":"0.0.0","private":true}', encoding="utf-8"
            )
            errors = validate_packages(root, self.version)
            self.assertTrue(any("does not match VERSION" in error for error in errors))

    def test_package_distribution_metadata_is_required(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            css = root / "packages" / "css"
            swift = root / "packages" / "swift"
            css.mkdir(parents=True)
            swift.mkdir(parents=True)
            (css / "package.json").write_text(
                json.dumps(
                    {
                        "name": "@qenterra/design-tokens",
                        "version": self.version,
                        "private": True,
                        "publishConfig": {"access": "public"},
                    }
                ),
                encoding="utf-8",
            )
            (swift / "Package.swift").write_text("// swift-tools-version: 5.9\n", encoding="utf-8")

            errors = validate_packages(root, self.version)

            self.assertTrue(any("private field must be omitted" in error for error in errors))
            self.assertTrue(any("GitHub Packages registry" in error for error in errors))
            self.assertTrue(any("packages/swift/LICENSE" in error for error in errors))

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

    def test_repository_standard_requires_code_quality_section(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            repository = root / "docs" / "repository"
            repository.mkdir(parents=True)
            (root / "docs" / "MASTER.md").write_text("# Master\n", encoding="utf-8")
            (root / "docs" / "MASTER.ru.md").write_text("# Мастер\n", encoding="utf-8")
            (repository / "STANDARD.md").write_text("# Standard\n\n## Only one\n", encoding="utf-8")
            (repository / "STANDARD.ru.md").write_text("# Стандарт\n\n## Только один\n", encoding="utf-8")
            errors = validate_localized_sources(root)
            self.assertTrue(any("expected 12 H2 sections" in error for error in errors))

    def test_current_brand_sources_pass(self) -> None:
        self.assertEqual(validate_brand_sources(ROOT), [])

    def test_missing_brand_pair_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "docs" / "brand").mkdir(parents=True)
            errors = validate_brand_sources(root)
            self.assertTrue(any("QENTERRA.md: missing brand reference" in error for error in errors))

    def test_contact_roles_cannot_be_swapped(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            registry = root / "registry"
            schemas = root / "schemas"
            registry.mkdir()
            schemas.mkdir()
            (schemas / "contact-channels.schema.json").write_bytes(
                (ROOT / "schemas" / "contact-channels.schema.json").read_bytes()
            )
            data = (ROOT / "registry" / "contact-channels.json").read_text(encoding="utf-8")
            data = data.replace("contact@qenterra.com", "swap@qenterra.com")
            (registry / "contact-channels.json").write_text(data, encoding="utf-8")
            errors = validate_contact_channels(root, self.version)
            self.assertTrue(any("canonical roles differ" in error for error in errors))

    def test_component_registry_rejects_unknown_story_state(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            registry = root / "registry"
            schemas = root / "schemas"
            registry.mkdir()
            schemas.mkdir()
            (schemas / "component-registry.schema.json").write_bytes(
                (ROOT / "schemas" / "component-registry.schema.json").read_bytes()
            )
            data = load_json(ROOT / "registry" / "components.json")
            data["components"][0]["stories"][0]["state"] = "imaginary"
            (registry / "components.json").write_text(json.dumps(data), encoding="utf-8")
            errors = validate_component_registry(root, self.version)
            self.assertTrue(any("unknown state" in error for error in errors))

    def test_component_registry_requires_story_coverage_for_every_state(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            registry = root / "registry"
            schemas = root / "schemas"
            registry.mkdir()
            schemas.mkdir()
            (schemas / "component-registry.schema.json").write_bytes(
                (ROOT / "schemas" / "component-registry.schema.json").read_bytes()
            )
            data = load_json(ROOT / "registry" / "components.json")
            button = next(component for component in data["components"] if component["id"] == "button")
            button["stories"] = [story for story in button["stories"] if story["state"] != "focused"]
            (registry / "components.json").write_text(json.dumps(data), encoding="utf-8")
            errors = validate_component_registry(root, self.version)
            self.assertTrue(any("missing story coverage" in error and "focused" in error for error in errors))

    def test_component_registry_requires_lifecycle_contract(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            registry = root / "registry"
            schemas = root / "schemas"
            registry.mkdir()
            schemas.mkdir()
            (schemas / "component-registry.schema.json").write_bytes(
                (ROOT / "schemas" / "component-registry.schema.json").read_bytes()
            )
            data = load_json(ROOT / "registry" / "components.json")
            data["components"][0].pop("lifecycle", None)
            (registry / "components.json").write_text(json.dumps(data), encoding="utf-8")

            errors = validate_component_registry(root, self.version)

            self.assertTrue(any("lifecycle" in error for error in errors))

    def test_browser_evidence_requires_all_accessibility_axes_and_explicit_states(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "evidence").mkdir()
            (root / "output" / "reports").mkdir(parents=True)
            (root / "output" / "screenshots").mkdir(parents=True)
            (root / "VERSION").write_text(self.version + "\n", encoding="utf-8")
            manifest = load_json(ROOT / "evidence" / "screenshots.json")
            manifest["captures"] = [
                {
                    **capture,
                    "theme": "dark" if capture.get("theme") == "system" else capture.get("theme"),
                    "reducedTransparency": False,
                    "increasedContrast": False,
                    "forcedColors": False,
                }
                for capture in manifest["captures"]
            ]
            for capture in manifest["captures"]:
                capture.pop("state", None)
            (root / "evidence" / "screenshots.json").write_text(json.dumps(manifest), encoding="utf-8")
            report = {
                "status": "passed",
                "version": self.version,
                "captures": [{"name": capture["name"]} for capture in manifest["captures"]],
                "checks": {},
            }
            (root / "output" / "reports" / "browser.json").write_text(json.dumps(report), encoding="utf-8")
            errors = validate_browser_evidence(root)
            self.assertTrue(any("System theme" in error for error in errors))
            self.assertTrue(any("Reduced Transparency" in error for error in errors))
            self.assertTrue(any("Increased Contrast" in error for error in errors))
            self.assertTrue(any("Forced Colors" in error for error in errors))
            self.assertTrue(any("explicit interaction states" in error for error in errors))

    def test_full_verifier_executes_browser_and_pixel_gates_without_skips(self) -> None:
        source = (ROOT / "scripts" / "verify.py").read_text(encoding="utf-8")
        self.assertIn('run([node, "scripts/render_screenshots.js"]', source)
        self.assertIn('run([image_python, "scripts/compare_screenshots.py"]', source)
        self.assertNotIn('"not-run-missing-QDS_IMAGE_PYTHON"', source)

    def test_pixel_comparison_ignores_only_declared_channel_jitter(self) -> None:
        self.assertFalse(pixel_changed((40, 40, 42, 255), (43, 43, 45, 255), 3))
        self.assertTrue(pixel_changed((40, 40, 42, 255), (44, 43, 45, 255), 3))

    def test_capture_disables_layout_effects_before_scrolling(self) -> None:
        source = (ROOT / "scripts" / "render_screenshots.js").read_text(encoding="utf-8")
        capture_source = source.split("async function capture", 1)[1].split(
            "async function assertUniformSfSymbols", 1
        )[0]

        self.assertLess(capture_source.index("addStyleTag"), capture_source.index("scrollTarget"))
        self.assertIn("overflow-anchor: none", capture_source)
        self.assertGreaterEqual(capture_source.count("window.scrollTo"), 2)

    def test_capture_defaults_to_playwright_pinned_chromium(self) -> None:
        source = (ROOT / "scripts" / "render_screenshots.js").read_text(encoding="utf-8")

        self.assertNotIn("systemChrome", source)
        self.assertIn("requestedBrowser || undefined", source)
        self.assertIn('"--disable-gpu"', source)
        self.assertIn('"--disable-lcd-text"', source)
        self.assertIn('"--disable-font-subpixel-positioning"', source)
        self.assertIn('"--deterministic-mode"', source)

    def test_increased_contrast_uses_crisp_navigation_edges(self) -> None:
        source = (ROOT / "src" / "assets" / "styles.css").read_text(encoding="utf-8")
        contrast_rules = source.split("@media (prefers-contrast: more)", 1)[1].split(
            "@media (forced-colors: active)", 1
        )[0]

        self.assertIn(":is(.brand-mark, .site-nav a[aria-current])", contrast_rules)
        self.assertIn("border-radius: var(--qds-radius-none)", contrast_rules)

    def test_visual_evidence_declares_complete_renderer_profiles(self) -> None:
        manifest = load_json(ROOT / "evidence" / "screenshots.json")
        expected_names = sorted(capture["name"] for capture in manifest["captures"])

        self.assertEqual(manifest["profiles"], ["local", "github-macos-15-arm64"])
        for profile in manifest["profiles"]:
            baseline_root = ROOT / "output" / "screenshots"
            if profile != "local":
                baseline_root = baseline_root / "profiles" / profile
            actual_names = sorted(path.stem for path in baseline_root.glob("*.png"))
            self.assertEqual(actual_names, expected_names)

        renderer = (ROOT / "scripts" / "render_screenshots.js").read_text(encoding="utf-8")
        comparator = (ROOT / "scripts" / "compare_screenshots.py").read_text(encoding="utf-8")
        self.assertIn("QDS_SCREENSHOT_PROFILE", renderer)
        self.assertIn("QDS_SCREENSHOT_PROFILE", comparator)

    def test_icon_registry_rejects_duplicate_ids(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            registry = root / "registry"
            schemas = root / "schemas"
            generated = root / "generated"
            registry.mkdir()
            schemas.mkdir()
            generated.mkdir()
            (schemas / "icon-registry.schema.json").write_bytes(
                (ROOT / "schemas" / "icon-registry.schema.json").read_bytes()
            )
            data = load_json(ROOT / "registry" / "icons.json")
            data["icons"].append(copy.deepcopy(data["icons"][0]))
            (registry / "icons.json").write_text(json.dumps(data), encoding="utf-8")
            errors = validate_icon_registry(root, self.version)
            self.assertTrue(any("ids must be unique" in error for error in errors))

    def test_icon_registry_requires_sf_symbols_and_rejects_svg_artwork(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            registry = root / "registry"
            schemas = root / "schemas"
            registry.mkdir()
            schemas.mkdir()
            (schemas / "icon-registry.schema.json").write_bytes(
                (ROOT / "schemas" / "icon-registry.schema.json").read_bytes()
            )
            data = load_json(ROOT / "registry" / "icons.json")
            data["icons"][0].pop("sfSymbol", None)
            data["icons"][0]["svg"] = '<path d="M0 0h1v1z"/>'
            (registry / "icons.json").write_text(json.dumps(data), encoding="utf-8")

            errors = validate_icon_registry(root, self.version)

            self.assertTrue(any("sfSymbol" in error for error in errors))
            self.assertTrue(any("svg" in error for error in errors))

    def test_sf_symbol_renderer_uses_fixed_pixel_canvas(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            subprocess.run(
                [
                    "swift",
                    str(ROOT / "scripts" / "render_sf_symbols.swift"),
                    str(ROOT / "registry" / "icons.json"),
                    directory,
                ],
                check=True,
                capture_output=True,
                text=True,
            )
            dimensions = {
                struct.unpack(">II", path.read_bytes()[16:24])
                for path in Path(directory).glob("*.png")
            }

        self.assertEqual(dimensions, {(64, 64)})


if __name__ == "__main__":
    unittest.main()
