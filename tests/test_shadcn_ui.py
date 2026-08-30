from __future__ import annotations

import hashlib
import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "tests/fixtures/shadcn-ui"
IMPORTER = ROOT / "scripts/shadcn_ui.py"
COMMIT = "0123456789abcdef0123456789abcdef01234567"


def load_importer():
    if not IMPORTER.is_file():
        raise AssertionError("scripts/shadcn_ui.py is missing")
    spec = importlib.util.spec_from_file_location("shadcn_ui", IMPORTER)
    if spec is None or spec.loader is None:
        raise AssertionError("cannot load scripts/shadcn_ui.py")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class ShadcnUIParserTests(unittest.TestCase):
    def test_discovers_all_official_variants_in_stable_order(self) -> None:
        importer = load_importer()
        self.assertEqual(
            importer.discover_variants(FIXTURE),
            [
                importer.Variant(identifier="base", title="Base UI"),
                importer.Variant(identifier="radix", title="Radix UI"),
            ],
        )

    def test_builds_exact_component_and_license_provenance(self) -> None:
        importer = load_importer()
        snapshot = importer.read_upstream_snapshot(FIXTURE, COMMIT)
        self.assertEqual(len(snapshot.components), 2)
        component = snapshot.components[0]
        expected = (FIXTURE / component.upstream_path).read_bytes()
        self.assertEqual(component.identifier, "base/button")
        self.assertEqual(component.source_bytes, expected)
        self.assertEqual(component.sha256, hashlib.sha256(expected).hexdigest())
        self.assertEqual(
            component.source_path,
            "Sources/ShadcnUI/Components/Base/button.tsx",
        )
        self.assertIn(COMMIT, component.source_url)
        self.assertEqual(snapshot.license_bytes, (FIXTURE / "LICENSE.md").read_bytes())
        self.assertEqual(snapshot.license_copyright, "Copyright (c) 2023 shadcn")

    def test_rejects_unregistered_component_source(self) -> None:
        importer = load_importer()
        with tempfile.TemporaryDirectory() as temporary:
            copied = Path(temporary) / "upstream"
            importer.shutil.copytree(FIXTURE, copied)
            extra = copied / "apps/v4/registry/bases/base/ui/untracked.tsx"
            extra.write_text("export const Untracked = true\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "unregistered component source"):
                importer.read_upstream_snapshot(copied, COMMIT)


class ShadcnUIWorkflowTests(unittest.TestCase):
    def test_written_catalog_preserves_originals_and_license_byte_for_byte(self) -> None:
        importer = load_importer()
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / "repository"
            (root / "registry").mkdir(parents=True)
            (root / "packages/Sources/ShadcnUI").mkdir(parents=True)
            (root / "VERSION").write_text("5.2.0\n", encoding="utf-8")
            (root / "registry/packages.json").write_text(
                json.dumps(
                    {
                        "version": "5.2.0",
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
            changes = importer.sync_from_checkout(
                FIXTURE,
                COMMIT,
                write=True,
                root=root,
            )
            self.assertTrue(changes)
            manifest = json.loads(
                (root / "packages/Sources/ShadcnUI/manifest.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertEqual(manifest["count"], 2)
            self.assertEqual(manifest["fileCount"], 2)
            self.assertEqual(manifest["upstreamCommit"], COMMIT)
            self.assertEqual(
                (root / "packages/Sources/ShadcnUI/LICENSE.md").read_bytes(),
                (FIXTURE / "LICENSE.md").read_bytes(),
            )
            importer.verify_catalog(
                root / "packages",
                root / "packages/Sources/ShadcnUI/manifest.json",
            )

    def test_sync_keeps_repository_public_paths_globally_sorted(self) -> None:
        importer = load_importer()
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / "repository"
            (root / "registry").mkdir(parents=True)
            (root / "packages/Sources/ShadcnUI").mkdir(parents=True)
            (root / "VERSION").write_text("5.3.0\n", encoding="utf-8")
            registry_path = root / "registry/packages.json"
            registry_path.write_text(
                json.dumps(
                    {
                        "version": "5.3.0",
                        "packages": [
                            {
                                "id": "repository-metadata",
                                "publicPaths": [
                                    "packages/Sources/MagicUI/manifest.json",
                                    "packages/README.md",
                                ],
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )

            importer.sync_from_checkout(FIXTURE, COMMIT, write=True, root=root)

            updated = json.loads(registry_path.read_text(encoding="utf-8"))
            public_paths = updated["packages"][0]["publicPaths"]
            self.assertEqual(public_paths, sorted(public_paths))

    def test_verify_rejects_changed_original_bytes(self) -> None:
        importer = load_importer()
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / "repository"
            (root / "registry").mkdir(parents=True)
            (root / "packages/Sources/ShadcnUI").mkdir(parents=True)
            (root / "VERSION").write_text("5.2.0\n", encoding="utf-8")
            (root / "registry/packages.json").write_text(
                json.dumps(
                    {
                        "version": "5.2.0",
                        "packages": [
                            {"id": "repository-metadata", "publicPaths": []}
                        ],
                    }
                ),
                encoding="utf-8",
            )
            importer.sync_from_checkout(FIXTURE, COMMIT, write=True, root=root)
            source = root / "packages/Sources/ShadcnUI/Components/Base/button.tsx"
            source.write_bytes(b"x" * len(source.read_bytes()))
            with self.assertRaisesRegex(ValueError, "hash mismatch"):
                importer.verify_catalog(
                    root / "packages",
                    root / "packages/Sources/ShadcnUI/manifest.json",
                )


if __name__ == "__main__":
    unittest.main()
