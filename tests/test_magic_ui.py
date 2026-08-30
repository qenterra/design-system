from __future__ import annotations

import hashlib
import importlib.util
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "tests/fixtures/magic-ui"
IMPORTER = ROOT / "scripts/magic_ui.py"
COMMIT = "0123456789abcdef0123456789abcdef01234567"


def load_importer():
    if not IMPORTER.is_file():
        raise AssertionError("scripts/magic_ui.py is missing")
    spec = importlib.util.spec_from_file_location("magic_ui", IMPORTER)
    if spec is None or spec.loader is None:
        raise AssertionError("cannot load scripts/magic_ui.py")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class MagicUIParserTests(unittest.TestCase):
    def test_discovers_the_public_docs_inventory_and_categories(self) -> None:
        importer = load_importer()
        snapshot = importer.read_upstream_snapshot(FIXTURE, COMMIT)
        self.assertEqual(
            [(category.identifier, category.title, category.count) for category in snapshot.categories],
            [
                ("components", "Components", 1),
                ("special-effects", "Special Effects", 1),
            ],
        )
        self.assertEqual(
            [component.identifier for component in snapshot.components],
            ["magic-card", "sparkles-text"],
        )

    def test_builds_exact_component_registry_and_license_provenance(self) -> None:
        importer = load_importer()
        snapshot = importer.read_upstream_snapshot(FIXTURE, COMMIT)
        component = snapshot.components[0]
        expected = (FIXTURE / component.upstream_path).read_bytes()
        self.assertEqual(component.source_bytes, expected)
        self.assertEqual(component.sha256, hashlib.sha256(expected).hexdigest())
        self.assertEqual(
            component.source_path,
            "Sources/MagicUI/Components/magic-card.tsx",
        )
        self.assertIn(COMMIT, component.source_url)
        self.assertEqual(snapshot.license_bytes, (FIXTURE / "LICENSE.md").read_bytes())
        self.assertEqual(snapshot.license_copyright, "Copyright (c) Magic UI")

    def test_ignores_internal_sources_that_are_not_on_the_public_components_page(self) -> None:
        importer = load_importer()
        snapshot = importer.read_upstream_snapshot(FIXTURE, COMMIT)
        self.assertNotIn(
            "internal-only",
            {component.identifier for component in snapshot.components},
        )

    def test_rejects_public_registry_content_that_differs_from_source(self) -> None:
        importer = load_importer()
        with tempfile.TemporaryDirectory() as temporary:
            copied = Path(temporary) / "upstream"
            shutil.copytree(FIXTURE, copied)
            registry = copied / "apps/www/public/r/magic-card.json"
            payload = json.loads(registry.read_text(encoding="utf-8"))
            payload["files"][0]["content"] = "export const Wrong = true\n"
            registry.write_text(json.dumps(payload), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "public registry content mismatch"):
                importer.read_upstream_snapshot(copied, COMMIT)


class MagicUIWorkflowTests(unittest.TestCase):
    def make_repository(self, temporary: str) -> Path:
        root = Path(temporary) / "repository"
        (root / "registry").mkdir(parents=True)
        (root / "packages/Sources/MagicUI").mkdir(parents=True)
        (root / "VERSION").write_text("5.3.0\n", encoding="utf-8")
        (root / "registry/packages.json").write_text(
            json.dumps(
                {
                    "version": "5.3.0",
                    "packages": [
                        {
                            "id": "repository-metadata",
                            "publicPaths": ["packages/README.md"],
                        }
                    ],
                }
            ),
            encoding="utf-8",
        )
        return root

    def test_written_catalog_preserves_originals_and_license_byte_for_byte(self) -> None:
        importer = load_importer()
        with tempfile.TemporaryDirectory() as temporary:
            root = self.make_repository(temporary)
            changes = importer.sync_from_checkout(
                FIXTURE,
                COMMIT,
                write=True,
                root=root,
            )
            self.assertTrue(changes)
            manifest = json.loads(
                (root / "packages/Sources/MagicUI/manifest.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertEqual(manifest["count"], 2)
            self.assertEqual(manifest["fileCount"], 4)
            self.assertEqual(manifest["registryItemCount"], 2)
            self.assertEqual(manifest["upstreamCommit"], COMMIT)
            self.assertEqual(
                (root / "packages/Sources/MagicUI/LICENSE.md").read_bytes(),
                (FIXTURE / "LICENSE.md").read_bytes(),
            )
            self.assertEqual(
                (root / "packages/Sources/MagicUI/Registry/magic-card.json").read_bytes(),
                (FIXTURE / "apps/www/public/r/magic-card.json").read_bytes(),
            )
            importer.verify_catalog(
                root / "packages",
                root / "packages/Sources/MagicUI/manifest.json",
            )

    def test_sync_keeps_repository_public_paths_globally_sorted(self) -> None:
        importer = load_importer()
        with tempfile.TemporaryDirectory() as temporary:
            root = self.make_repository(temporary)
            registry_path = root / "registry/packages.json"
            registry = json.loads(registry_path.read_text(encoding="utf-8"))
            registry["packages"][0]["publicPaths"] = [
                "packages/Sources/ShadcnUI/manifest.json",
                "packages/README.md",
            ]
            registry_path.write_text(json.dumps(registry), encoding="utf-8")

            importer.sync_from_checkout(FIXTURE, COMMIT, write=True, root=root)

            updated = json.loads(registry_path.read_text(encoding="utf-8"))
            public_paths = updated["packages"][0]["publicPaths"]
            self.assertEqual(public_paths, sorted(public_paths))

    def test_verify_rejects_changed_original_bytes(self) -> None:
        importer = load_importer()
        with tempfile.TemporaryDirectory() as temporary:
            root = self.make_repository(temporary)
            importer.sync_from_checkout(FIXTURE, COMMIT, write=True, root=root)
            source = root / "packages/Sources/MagicUI/Components/magic-card.tsx"
            source.write_bytes(b"x" * len(source.read_bytes()))
            with self.assertRaisesRegex(ValueError, "hash mismatch"):
                importer.verify_catalog(
                    root / "packages",
                    root / "packages/Sources/MagicUI/manifest.json",
                )


if __name__ == "__main__":
    unittest.main()
