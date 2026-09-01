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
FIXTURE = ROOT / "tests/fixtures/reui"
IMPORTER = ROOT / "scripts/reui.py"
COMMIT = "0123456789abcdef0123456789abcdef01234567"


def load_importer():
    if not IMPORTER.is_file():
        raise AssertionError("scripts/reui.py is missing")
    spec = importlib.util.spec_from_file_location("reui", IMPORTER)
    if spec is None or spec.loader is None:
        raise AssertionError("cannot load scripts/reui.py")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class ReUIParserTests(unittest.TestCase):
    def test_builds_complete_dual_base_public_union_and_excludes_pro_content(self) -> None:
        importer = load_importer()
        snapshot = importer.read_upstream_snapshot(FIXTURE, COMMIT)
        self.assertEqual(len(snapshot.items), 6)
        self.assertEqual(snapshot.example_count, 2)
        self.assertEqual(snapshot.primitive_count, 2)
        self.assertEqual(snapshot.hook_count, 2)
        self.assertEqual(
            [(item.base, item.identifier, item.kind) for item in snapshot.items],
            [
                ("base", "c-button-1", "example"),
                ("base", "alert", "primitive"),
                ("base", "use-copy-to-clipboard", "hook"),
                ("radix", "c-button-1", "example"),
                ("radix", "alert", "primitive"),
                ("radix", "use-copy-to-clipboard", "hook"),
            ],
        )
        self.assertNotIn("paid-dashboard", {item.identifier for item in snapshot.items})

    def test_preserves_exact_source_payload_and_license_bytes(self) -> None:
        importer = load_importer()
        snapshot = importer.read_upstream_snapshot(FIXTURE, COMMIT)
        item = next(
            item
            for item in snapshot.items
            if item.base == "base" and item.identifier == "c-button-1"
        )
        payload = FIXTURE / item.registry_upstream_path
        registry = json.loads(payload.read_text(encoding="utf-8"))
        source = registry["files"][0]["content"].encode("utf-8")
        self.assertEqual(item.sources[0].payload, source)
        self.assertEqual(
            item.sources[0].sha256,
            hashlib.sha256(source).hexdigest(),
        )
        self.assertEqual(item.registry_bytes, payload.read_bytes())
        self.assertEqual(
            item.sources[0].source_path,
            "Sources/ReUI/Base/Components/button/c-button-1.tsx",
        )
        self.assertEqual(
            item.sources[0].source_url,
            "https://reui.io/r/styles/base-nova/c-button-1.json?v=dpl_fixture",
        )
        self.assertEqual(
            item.registry_source_path,
            "Sources/ReUI/Registry/BaseNova/c-button-1.json",
        )
        self.assertEqual(snapshot.license_bytes, (FIXTURE / "LICENSE.md").read_bytes())
        self.assertEqual(
            snapshot.license_copyright,
            "Copyright (c) 2025 Keenthemes Inc",
        )

    def test_rejects_public_manifest_boundary_drift(self) -> None:
        importer = load_importer()
        with tempfile.TemporaryDirectory() as temporary:
            copied = Path(temporary) / "upstream"
            shutil.copytree(FIXTURE, copied)
            path = copied / "public/r/styles/base-nova/registry.json"
            manifest = json.loads(path.read_text(encoding="utf-8"))
            manifest["items"] = [
                item for item in manifest["items"] if item["name"] != "alert"
            ]
            path.write_text(json.dumps(manifest), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "public registry boundary mismatch"):
                importer.read_upstream_snapshot(copied, COMMIT)

    def test_rejects_unsafe_install_target(self) -> None:
        importer = load_importer()
        with tempfile.TemporaryDirectory() as temporary:
            copied = Path(temporary) / "upstream"
            shutil.copytree(FIXTURE, copied)
            path = copied / "public/r/styles/base-nova/alert.json"
            payload = json.loads(path.read_text(encoding="utf-8"))
            payload["files"][0]["target"] = "../secrets.ts"
            path.write_text(json.dumps(payload), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "unsafe registry target"):
                importer.read_upstream_snapshot(copied, COMMIT)

    def test_records_repository_origin_for_unchanged_published_payloads(self) -> None:
        importer = load_importer()
        with tempfile.TemporaryDirectory() as temporary:
            copied = Path(temporary) / "upstream"
            shutil.copytree(FIXTURE, copied)
            metadata_path = copied / ".reui-capture.json"
            metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
            metadata["payloadOrigins"] = {
                "base-nova": {"c-button-1": "repository"}
            }
            metadata_path.write_text(json.dumps(metadata), encoding="utf-8")
            snapshot = importer.read_upstream_snapshot(copied, COMMIT)
            item = next(
                item
                for item in snapshot.items
                if item.base == "base" and item.identifier == "c-button-1"
            )
            self.assertEqual(item.registry_origin, "repository")
            self.assertEqual(
                item.registry_url,
                "https://raw.githubusercontent.com/keenthemes/reui/"
                f"{COMMIT}/public/r/styles/base-nova/c-button-1.json",
            )


class ReUIWorkflowTests(unittest.TestCase):
    def make_repository(self, temporary: str) -> Path:
        root = Path(temporary) / "repository"
        (root / "registry").mkdir(parents=True)
        (root / "packages/Sources/ReUI").mkdir(parents=True)
        (root / "VERSION").write_text("1.0.0\n", encoding="utf-8")
        (root / "registry/packages.json").write_text(
            json.dumps(
                {
                    "version": "1.0.0",
                    "packages": [
                        {
                            "id": "repository-metadata",
                            "publicPaths": [
                                "packages/Sources/UIable/manifest.json",
                                "packages/README.md",
                            ],
                        }
                    ],
                }
            ),
            encoding="utf-8",
        )
        return root

    def test_written_catalog_is_closed_and_preserves_original_bytes(self) -> None:
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
                (root / "packages/Sources/ReUI/manifest.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertEqual(manifest["count"], 6)
            self.assertEqual(manifest["sourceFileCount"], 6)
            self.assertEqual(manifest["registryItemCount"], 6)
            self.assertEqual(manifest["fileCount"], 12)
            self.assertEqual(manifest["upstreamCommit"], COMMIT)
            self.assertEqual(manifest["registryRevision"], "dpl_fixture")
            self.assertEqual(
                [index["base"] for index in manifest["registryIndexes"]],
                ["base", "radix"],
            )
            self.assertEqual(
                manifest["registryIndexes"][0]["sourceURL"],
                "https://reui.io/r/styles/base-nova/registry.json?v=dpl_fixture",
            )
            self.assertEqual(
                (root / "packages/Sources/ReUI/LICENSE.md").read_bytes(),
                (FIXTURE / "LICENSE.md").read_bytes(),
            )
            self.assertEqual(
                (
                    root
                    / "packages/Sources/ReUI/Radix/Components/button/c-button-1.tsx"
                ).read_bytes(),
                (
                    FIXTURE
                    / "registry-reui/bases/radix/components/button/c-button-1.tsx"
                ).read_bytes(),
            )
            importer.verify_catalog(
                root / "packages",
                root / "packages/Sources/ReUI/manifest.json",
            )

    def test_verify_rejects_changed_original_bytes(self) -> None:
        importer = load_importer()
        with tempfile.TemporaryDirectory() as temporary:
            root = self.make_repository(temporary)
            importer.sync_from_checkout(FIXTURE, COMMIT, write=True, root=root)
            source = (
                root / "packages/Sources/ReUI/Base/Primitives/alert.tsx"
            )
            source.write_bytes(b"x" * len(source.read_bytes()))
            with self.assertRaisesRegex(ValueError, "hash mismatch"):
                importer.verify_catalog(
                    root / "packages",
                    root / "packages/Sources/ReUI/manifest.json",
                )

    def test_verify_rejects_source_and_registry_content_mismatch(self) -> None:
        importer = load_importer()
        with tempfile.TemporaryDirectory() as temporary:
            root = self.make_repository(temporary)
            importer.sync_from_checkout(FIXTURE, COMMIT, write=True, root=root)
            registry_path = (
                root / "packages/Sources/ReUI/Registry/BaseNova/alert.json"
            )
            payload = json.loads(registry_path.read_text(encoding="utf-8"))
            payload["files"][0]["content"] += "\n// drift"
            registry_bytes = json.dumps(payload).encode("utf-8")
            registry_path.write_bytes(registry_bytes)
            manifest_path = root / "packages/Sources/ReUI/manifest.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            record = next(
                item for item in manifest["items"] if item["id"] == "base:alert"
            )["registryItem"]
            record["bytes"] = len(registry_bytes)
            record["sha256"] = hashlib.sha256(registry_bytes).hexdigest()
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "registry content mismatch"):
                importer.verify_catalog(root / "packages", manifest_path)

    def test_public_paths_are_sorted_and_replace_only_reui_entries(self) -> None:
        importer = load_importer()
        with tempfile.TemporaryDirectory() as temporary:
            root = self.make_repository(temporary)
            importer.sync_from_checkout(FIXTURE, COMMIT, write=True, root=root)
            registry = json.loads(
                (root / "registry/packages.json").read_text(encoding="utf-8")
            )
            paths = registry["packages"][0]["publicPaths"]
            self.assertEqual(paths, sorted(paths))
            self.assertIn("packages/Sources/UIable/manifest.json", paths)
            self.assertIn("packages/Sources/ReUI/manifest.json", paths)
            self.assertIn(
                "packages/Sources/ReUI/Registry/RadixNova/alert.json",
                paths,
            )


if __name__ == "__main__":
    unittest.main()
