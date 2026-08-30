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
FIXTURE = ROOT / "tests/fixtures/uiable"
IMPORTER = ROOT / "scripts/uiable.py"
COMMIT = "0123456789abcdef0123456789abcdef01234567"


def load_importer():
    if not IMPORTER.is_file():
        raise AssertionError("scripts/uiable.py is missing")
    spec = importlib.util.spec_from_file_location("uiable", IMPORTER)
    if spec is None or spec.loader is None:
        raise AssertionError("cannot load scripts/uiable.py")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class UIableParserTests(unittest.TestCase):
    def test_builds_complete_registry_ui_union_and_excludes_blocks(self) -> None:
        importer = load_importer()
        snapshot = importer.read_upstream_snapshot(FIXTURE, COMMIT)
        self.assertEqual(len(snapshot.items), 3)
        self.assertEqual(
            [(item.identifier, item.kind) for item in snapshot.items],
            [
                ("button", "primitive"),
                ("button-default", "component"),
                ("button-outline", "component"),
            ],
        )
        self.assertNotIn("block-hero", {item.identifier for item in snapshot.items})
        self.assertEqual(snapshot.component_count, 2)
        self.assertEqual(snapshot.primitive_count, 1)

    def test_preserves_source_payload_and_license_provenance(self) -> None:
        importer = load_importer()
        snapshot = importer.read_upstream_snapshot(FIXTURE, COMMIT)
        item = next(item for item in snapshot.items if item.identifier == "button-default")
        source = (FIXTURE / item.upstream_path).read_bytes()
        payload = (FIXTURE / item.registry_upstream_path).read_bytes()
        self.assertEqual(item.source_bytes, source)
        self.assertEqual(item.sha256, hashlib.sha256(source).hexdigest())
        self.assertEqual(item.registry_bytes, payload)
        self.assertEqual(
            item.source_path,
            "Sources/UIable/Components/button/button-default.tsx",
        )
        self.assertEqual(
            item.registry_source_path,
            "Sources/UIable/Registry/Components/button-default.json",
        )
        self.assertEqual(snapshot.license_bytes, (FIXTURE / "LICENSE").read_bytes())
        self.assertEqual(snapshot.license_copyright, "Copyright (c) 2026 CodedThemes")

    def test_rejects_aggregate_registry_ui_drift(self) -> None:
        importer = load_importer()
        with tempfile.TemporaryDirectory() as temporary:
            copied = Path(temporary) / "upstream"
            shutil.copytree(FIXTURE, copied)
            registry_path = copied / "public/r/registry.json"
            registry = json.loads(registry_path.read_text(encoding="utf-8"))
            registry["items"] = [
                item for item in registry["items"] if item["name"] != "button-outline"
            ]
            registry_path.write_text(json.dumps(registry), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "public registry:ui boundary mismatch"):
                importer.read_upstream_snapshot(copied, COMMIT)

    def test_rejects_block_leakage_from_component_registry(self) -> None:
        importer = load_importer()
        with tempfile.TemporaryDirectory() as temporary:
            copied = Path(temporary) / "upstream"
            shutil.copytree(FIXTURE, copied)
            registry_path = copied / "src/components/uiable/registry.json"
            registry = json.loads(registry_path.read_text(encoding="utf-8"))
            registry["items"][0]["type"] = "registry:block"
            registry_path.write_text(json.dumps(registry), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "must contain only registry:ui items"):
                importer.read_upstream_snapshot(copied, COMMIT)

    def test_rejects_public_payload_content_that_differs_from_source(self) -> None:
        importer = load_importer()
        with tempfile.TemporaryDirectory() as temporary:
            copied = Path(temporary) / "upstream"
            shutil.copytree(FIXTURE, copied)
            payload_path = copied / "public/r/button-default.json"
            payload = json.loads(payload_path.read_text(encoding="utf-8"))
            payload["files"][0]["content"] = "export const Wrong = true\n"
            payload_path.write_text(json.dumps(payload), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "public registry content mismatch"):
                importer.read_upstream_snapshot(copied, COMMIT)


class UIableWorkflowTests(unittest.TestCase):
    def make_repository(self, temporary: str) -> Path:
        root = Path(temporary) / "repository"
        (root / "registry").mkdir(parents=True)
        (root / "packages/Sources/UIable").mkdir(parents=True)
        (root / "VERSION").write_text("5.4.0\n", encoding="utf-8")
        (root / "registry/packages.json").write_text(
            json.dumps(
                {
                    "version": "5.4.0",
                    "packages": [
                        {
                            "id": "repository-metadata",
                            "publicPaths": [
                                "packages/Sources/ShadcnUI/manifest.json",
                                "packages/README.md",
                            ],
                        }
                    ],
                }
            ),
            encoding="utf-8",
        )
        return root

    def test_written_catalog_preserves_all_original_bytes(self) -> None:
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
                (root / "packages/Sources/UIable/manifest.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertEqual(manifest["count"], 3)
            self.assertEqual(manifest["componentCount"], 2)
            self.assertEqual(manifest["primitiveCount"], 1)
            self.assertEqual(manifest["sourceFileCount"], 3)
            self.assertEqual(manifest["registryItemCount"], 3)
            self.assertEqual(manifest["fileCount"], 6)
            self.assertEqual(manifest["upstreamCommit"], COMMIT)
            self.assertEqual(
                (root / "packages/Sources/UIable/LICENSE.md").read_bytes(),
                (FIXTURE / "LICENSE").read_bytes(),
            )
            self.assertEqual(
                (root / "packages/Sources/UIable/Components/button/button-default.tsx").read_bytes(),
                (FIXTURE / "src/components/uiable/button/button-default.tsx").read_bytes(),
            )
            self.assertEqual(
                (root / "packages/Sources/UIable/Registry/Components/button-default.json").read_bytes(),
                (FIXTURE / "public/r/button-default.json").read_bytes(),
            )
            importer.verify_catalog(
                root / "packages",
                root / "packages/Sources/UIable/manifest.json",
            )

    def test_verify_rejects_changed_original_bytes(self) -> None:
        importer = load_importer()
        with tempfile.TemporaryDirectory() as temporary:
            root = self.make_repository(temporary)
            importer.sync_from_checkout(FIXTURE, COMMIT, write=True, root=root)
            source = root / "packages/Sources/UIable/Components/button/button-default.tsx"
            source.write_bytes(b"x" * len(source.read_bytes()))
            with self.assertRaisesRegex(ValueError, "hash mismatch"):
                importer.verify_catalog(
                    root / "packages",
                    root / "packages/Sources/UIable/manifest.json",
                )

    def test_sync_keeps_repository_public_paths_globally_sorted(self) -> None:
        importer = load_importer()
        with tempfile.TemporaryDirectory() as temporary:
            root = self.make_repository(temporary)
            importer.sync_from_checkout(FIXTURE, COMMIT, write=True, root=root)
            registry = json.loads(
                (root / "registry/packages.json").read_text(encoding="utf-8")
            )
            public_paths = registry["packages"][0]["publicPaths"]
            self.assertEqual(public_paths, sorted(public_paths))


if __name__ == "__main__":
    unittest.main()
