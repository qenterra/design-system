from __future__ import annotations

import importlib.util
import json
import shutil
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "tests/fixtures/icon-catalogs"
IMPORTER = ROOT / "scripts/icon_catalogs.py"
COMMITS = {
    "tabler-icons": "1" * 40,
    "phosphor-icons": "2" * 40,
    "iconoir": "3" * 40,
    "bootstrap-icons": "4" * 40,
}


def load_importer():
    if not IMPORTER.is_file():
        raise AssertionError("scripts/icon_catalogs.py is missing")
    spec = importlib.util.spec_from_file_location("icon_catalogs", IMPORTER)
    if spec is None or spec.loader is None:
        raise AssertionError("cannot load scripts/icon_catalogs.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class IconCatalogParserTests(unittest.TestCase):
    def test_official_configs_cover_only_published_svg_roots(self) -> None:
        importer = load_importer()
        self.assertEqual(
            {
                identifier: tuple(style.upstream_root.as_posix() for style in config.styles)
                for identifier, config in importer.CATALOGS.items()
            },
            {
                "tabler-icons": ("icons/outline", "icons/filled"),
                "phosphor-icons": (
                    "assets/regular",
                    "assets/bold",
                    "assets/duotone",
                    "assets/fill",
                    "assets/light",
                    "assets/thin",
                ),
                "iconoir": ("icons/regular", "icons/solid"),
                "bootstrap-icons": ("icons",),
            },
        )

    def test_snapshots_preserve_every_style_and_exact_license(self) -> None:
        importer = load_importer()
        snapshots = importer.snapshots_from_checkouts(
            {identifier: FIXTURE / identifier for identifier in importer.CATALOGS},
            COMMITS,
        )
        self.assertEqual(
            {identifier: snapshot.file_count for identifier, snapshot in snapshots.items()},
            {
                "tabler-icons": 2,
                "phosphor-icons": 6,
                "iconoir": 2,
                "bootstrap-icons": 1,
            },
        )
        self.assertEqual(
            snapshots["tabler-icons"].license_bytes,
            (FIXTURE / "tabler-icons/LICENSE").read_bytes(),
        )
        self.assertEqual(
            [item.identifier for item in snapshots["phosphor-icons"].icons],
            sorted(item.identifier for item in snapshots["phosphor-icons"].icons),
        )


class IconCatalogWorkflowTests(unittest.TestCase):
    def make_repository(self, temporary: str) -> Path:
        root = Path(temporary) / "repository"
        (root / "registry").mkdir(parents=True)
        (root / "packages").mkdir(parents=True)
        (root / "VERSION").write_text("1.0.0\n", encoding="utf-8")
        (root / "registry/packages.json").write_text(
            json.dumps(
                {
                    "$schema": "../schemas/package-registry.schema.json",
                    "version": "1.0.0",
                    "repository": "https://github.com/qenterra/design-system",
                    "versionPolicy": "shared",
                    "packages": [
                        {
                            "id": "repository-metadata",
                            "ecosystem": "repository",
                            "name": "qenterra/design-system",
                            "version": "1.0.0",
                            "publicPaths": ["packages/README.md"],
                            "tests": [],
                            "capabilities": [],
                        }
                    ],
                }
            ),
            encoding="utf-8",
        )
        (root / "packages/README.md").write_text("fixture\n", encoding="utf-8")
        return root

    def write_fixture_catalogs(self, root: Path):
        importer = load_importer()
        return importer.sync_from_checkouts(
            {identifier: FIXTURE / identifier for identifier in importer.CATALOGS},
            COMMITS,
            write=True,
            root=root,
        )

    def test_written_catalogs_are_exact_closed_and_publicly_registered(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self.make_repository(temporary)
            snapshots = self.write_fixture_catalogs(root)
            self.assertEqual(set(snapshots), set(COMMITS))
            for identifier, config in load_importer().CATALOGS.items():
                public_root = root / "packages/Sources" / config.public_directory
                manifest = json.loads((public_root / "manifest.json").read_text())
                self.assertEqual(manifest["upstreamCommit"], COMMITS[identifier])
                self.assertEqual(manifest["fileCount"], snapshots[identifier].file_count)
                self.assertEqual(
                    (public_root / config.license_output_name).read_bytes(),
                    (FIXTURE / identifier / config.license_path).read_bytes(),
                )
                for icon in snapshots[identifier].icons:
                    self.assertEqual(
                        (root / "packages" / icon.source_path).read_bytes(),
                        icon.source_bytes,
                    )
                load_importer().verify_catalog(
                    root / "packages", public_root / "manifest.json"
                )

            registry = json.loads((root / "registry/icon-sources.json").read_text())
            self.assertEqual(
                [catalog["id"] for catalog in registry["catalogs"]],
                sorted(COMMITS),
            )
            packages = json.loads((root / "registry/packages.json").read_text())
            public_paths = packages["packages"][0]["publicPaths"]
            self.assertEqual(public_paths, sorted(public_paths))
            self.assertEqual(len(public_paths), len(set(public_paths)))

    def test_verify_rejects_changed_original_bytes(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self.make_repository(temporary)
            snapshots = self.write_fixture_catalogs(root)
            icon = snapshots["bootstrap-icons"].icons[0]
            path = root / "packages" / icon.source_path
            path.write_bytes(b"<svg>tampered</svg>\n")
            with self.assertRaisesRegex(ValueError, "hash mismatch"):
                load_importer().verify_catalog(
                    root / "packages",
                    root / "packages/Sources/BootstrapIcons/manifest.json",
                )

    def test_verify_rejects_an_undeclared_svg(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self.make_repository(temporary)
            self.write_fixture_catalogs(root)
            extra = root / "packages/Sources/Iconoir/Icons/regular/extra.svg"
            extra.write_text("<svg/>\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "untracked source"):
                load_importer().verify_catalog(
                    root / "packages",
                    root / "packages/Sources/Iconoir/manifest.json",
                )

    def test_verify_rejects_rewritten_provenance_and_style_metadata(self) -> None:
        mutations = (
            ("upstreamPath", "icons/solid/rewritten.svg", "upstream path"),
            ("style", "solid", "style metadata"),
            ("id", "solid/rewritten", "icon identifier"),
        )
        for field, value, expected in mutations:
            with self.subTest(field=field), tempfile.TemporaryDirectory() as temporary:
                root = self.make_repository(temporary)
                self.write_fixture_catalogs(root)
                manifest_path = root / "packages/Sources/Iconoir/manifest.json"
                manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
                manifest["icons"][0][field] = value
                manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
                with self.assertRaisesRegex(ValueError, expected):
                    load_importer().verify_catalog(root / "packages", manifest_path)

    def test_verify_all_rejects_registry_manifest_drift(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self.make_repository(temporary)
            self.write_fixture_catalogs(root)
            registry_path = root / "registry/icon-sources.json"
            registry = json.loads(registry_path.read_text(encoding="utf-8"))
            registry["catalogs"][0]["fileCount"] += 1
            registry_path.write_text(json.dumps(registry), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "registry.*manifest"):
                load_importer().verify_all(root)


if __name__ == "__main__":
    unittest.main()
