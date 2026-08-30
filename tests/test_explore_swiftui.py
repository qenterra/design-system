from __future__ import annotations

import hashlib
import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "tests/fixtures/explore-swiftui"
IMPORTER = ROOT / "scripts/explore_swiftui.py"


def load_importer():
    if not IMPORTER.is_file():
        raise AssertionError("scripts/explore_swiftui.py is missing")
    spec = importlib.util.spec_from_file_location("explore_swiftui", IMPORTER)
    if spec is None or spec.loader is None:
        raise AssertionError("cannot load scripts/explore_swiftui.py")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class ExploreSwiftUIParserTests(unittest.TestCase):
    def test_discovers_only_detail_pages_in_stable_order(self) -> None:
        importer = load_importer()
        urls = importer.discover_detail_urls(
            (FIXTURES / "sitemap.xml").read_bytes()
        )
        self.assertEqual(
            urls,
            [
                "https://exploreswiftui.com/library/date-picker/graphical-date-picker",
                "https://exploreswiftui.com/library/tab-view/link",
            ],
        )

    def test_parses_exact_source_and_provenance(self) -> None:
        importer = load_importer()
        pattern = importer.parse_component_page(
            "https://exploreswiftui.com/library/tab-view/link",
            (FIXTURES / "link.html").read_bytes(),
        )
        expected = (
            "import SwiftUI\n\nstruct LinkExample: View {\n"
            "    var body: some View {\n"
            "        Link(\"Open\", destination: URL(string: \"https://example.com\")!)\n"
            "    }\n}"
        )
        self.assertEqual(pattern.identifier, "tab-view/link")
        self.assertEqual(pattern.category, "TabView")
        self.assertEqual(pattern.filename, "Link.swift")
        self.assertEqual(pattern.source, expected)
        self.assertEqual(pattern.source_bytes, expected.encode("utf-8"))
        self.assertEqual(
            pattern.sha256,
            hashlib.sha256(expected.encode("utf-8")).hexdigest(),
        )
        self.assertEqual(pattern.published_at, "2025-01-02")
        self.assertEqual(pattern.updated_at, "2025-03-04")
        self.assertEqual(
            pattern.apple_documentation_url,
            "https://developer.apple.com/documentation/swiftui/link",
        )
        self.assertEqual(pattern.tags, ("Link", "Navigation"))
        self.assertEqual(
            pattern.platforms,
            {
                "iOS": "14.0+",
                "iPadOS": "14.0+",
                "macOS": "11.0+",
                "tvOS": "14.0+",
                "visionOS": "1.0+",
                "watchOS": "7.0+",
            },
        )

    def test_catalog_rejects_duplicate_output_paths(self) -> None:
        importer = load_importer()
        first = importer.parse_component_page(
            "https://exploreswiftui.com/library/tab-view/link",
            (FIXTURES / "link.html").read_bytes(),
        )
        duplicate = importer.dataclasses.replace(
            first,
            identifier="another/link",
            url="https://exploreswiftui.com/library/another/link",
        )
        with self.assertRaisesRegex(ValueError, "duplicate source path"):
            importer.build_catalog([first, duplicate], "5.1.0")


class ExploreSwiftUIWorkflowTests(unittest.TestCase):
    def test_derive_copies_original_without_mutating_it(self) -> None:
        importer = load_importer()
        original = b"struct Original {}\n"
        manifest = {
            "version": "5.1.0",
            "source": "https://exploreswiftui.com/",
            "components": [
                {
                    "id": "controls/original",
                    "pageURL": "https://exploreswiftui.com/library/controls/original",
                    "sourcePath": "Sources/ExploreSwiftUI/Components/Controls/Original.swift",
                    "sha256": hashlib.sha256(original).hexdigest(),
                    "bytes": len(original),
                }
            ],
        }
        with tempfile.TemporaryDirectory() as temporary:
            repository_root = Path(temporary) / "repository"
            package_root = repository_root / "packages"
            original_path = package_root / manifest["components"][0]["sourcePath"]
            original_path.parent.mkdir(parents=True)
            original_path.write_bytes(original)
            manifest_path = package_root / "Sources/ExploreSwiftUI/manifest.json"
            manifest_path.parent.mkdir(parents=True, exist_ok=True)
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
            registry_path = repository_root / "registry/qenterra-components.json"
            registry_path.parent.mkdir(parents=True, exist_ok=True)
            registry_path.write_text(
                json.dumps({"version": "5.1.0", "components": []}),
                encoding="utf-8",
            )
            package_registry_path = repository_root / "registry/packages.json"
            package_registry_path.write_text(
                json.dumps(
                    {
                        "version": "5.1.0",
                        "packages": [
                            {
                                "id": "swift-components",
                                "publicPaths": ["packages/Package.swift"],
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )

            output = importer.derive_component(
                package_root=package_root,
                identifier="controls/original",
                output_name="AdaptedOriginal",
            )

            self.assertEqual(original_path.read_bytes(), original)
            self.assertEqual(output.read_bytes(), original)
            self.assertEqual(
                output,
                repository_root / "packages/Sources/QenTerra/Components/AdaptedOriginal.swift",
            )
            registry = json.loads(registry_path.read_text(encoding="utf-8"))
            self.assertEqual(
                registry["components"],
                [
                    {
                        "id": "adapted-original",
                        "name": "AdaptedOriginal",
                        "category": "adapted",
                        "status": "draft",
                        "sourcePath": "packages/Sources/QenTerra/Components/AdaptedOriginal.swift",
                        "publicSymbols": ["AdaptedOriginal"],
                        "designTokens": False,
                        "derivedFrom": {
                            "provider": "Explore SwiftUI",
                            "componentId": "controls/original",
                            "pageURL": "https://exploreswiftui.com/library/controls/original",
                            "sourceSha256": hashlib.sha256(original).hexdigest(),
                        },
                    }
                ],
            )
            package_registry = json.loads(
                package_registry_path.read_text(encoding="utf-8")
            )
            self.assertIn(
                "packages/Sources/QenTerra/Components/AdaptedOriginal.swift",
                package_registry["packages"][0]["publicPaths"],
            )

    def test_verify_rejects_changed_original_bytes(self) -> None:
        importer = load_importer()
        with tempfile.TemporaryDirectory() as temporary:
            package_root = Path(temporary)
            source = package_root / "Sources/ExploreSwiftUI/Components/Controls/Original.swift"
            source.parent.mkdir(parents=True)
            source.write_bytes(b"originaL")
            manifest = {
                "version": "5.1.0",
                "source": "https://exploreswiftui.com/",
                "components": [
                    {
                        "id": "controls/original",
                        "sourcePath": "Sources/ExploreSwiftUI/Components/Controls/Original.swift",
                        "sha256": hashlib.sha256(b"original").hexdigest(),
                        "bytes": len(b"original"),
                    }
                ],
            }
            manifest_path = package_root / "Sources/ExploreSwiftUI/manifest.json"
            manifest_path.parent.mkdir(parents=True, exist_ok=True)
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "hash mismatch"):
                importer.verify_catalog(package_root, manifest_path)


if __name__ == "__main__":
    unittest.main()
