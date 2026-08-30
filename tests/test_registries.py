from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from lib.schema_tools import validate_schema  # noqa: E402


VERSION = (ROOT / "VERSION").read_text(encoding="utf-8").strip()


def load(relative: str) -> dict:
    path = ROOT / relative
    if not path.is_file():
        raise AssertionError(f"{relative} is missing")
    return json.loads(path.read_text(encoding="utf-8"))


class RegistryContractTests(unittest.TestCase):
    def test_registry_does_not_claim_deleted_manual_visual_evidence(self) -> None:
        components = load("registry/components.json")
        for component in components["components"]:
            self.assertNotIn("manual", component["evidence"], component["id"])

    def test_every_registry_uses_the_canonical_version(self) -> None:
        for relative in (
            "registry/components.json",
            "registry/icons.json",
            "registry/native-patterns.json",
            "registry/packages.json",
            "registry/qenterra-components.json",
        ):
            with self.subTest(relative=relative):
                self.assertEqual(load(relative)["version"], VERSION)

    def test_component_delivery_claims_reference_registered_packages(self) -> None:
        package_ids = {item["id"] for item in load("registry/packages.json")["packages"]}
        components = load("registry/components.json")["components"]
        self.assertEqual(len({item["id"] for item in components}), len(components))

        delivered = {"button", "field", "group", "interactive-row"}
        actual_delivered = {
            item["id"]
            for item in components
            if item["delivery"]["status"] == "delivered"
        }
        self.assertEqual(actual_delivered, delivered)
        for component in components:
            packages = component["delivery"]["packages"]
            self.assertTrue(set(packages).issubset(package_ids), component["id"])
            if component["delivery"]["status"] == "delivered":
                self.assertTrue(packages, component["id"])
                self.assertIn("unit", component["evidence"])
            else:
                self.assertEqual(packages, [])

    def test_public_paths_exist_and_are_unique(self) -> None:
        packages = load("registry/packages.json")["packages"]
        paths: list[str] = []
        for package in packages:
            for relative in package["publicPaths"]:
                self.assertTrue((ROOT / relative).is_file(), relative)
                paths.append(relative)
            for relative in package["tests"]:
                self.assertTrue((ROOT / relative).is_file(), relative)
        self.assertEqual(len(paths), len(set(paths)))

    def test_qenterra_implementation_registry_has_one_file_per_component(self) -> None:
        registry = load("registry/qenterra-components.json")
        paths = [item["sourcePath"] for item in registry["components"]]
        self.assertEqual(len(paths), len(set(paths)))
        self.assertEqual(
            set(paths),
            {
                "packages/Sources/QenTerra/Components/GroupContainer.swift",
                "packages/Sources/QenTerra/Components/InteractiveRowSurface.swift",
                "packages/Sources/QenTerra/Components/PrimaryButtonStyle.swift",
            },
        )
        for relative in paths:
            self.assertTrue((ROOT / relative).is_file(), relative)

    def test_source_catalog_registries_match_their_schemas(self) -> None:
        for registry_relative, schema_relative in (
            (
                "registry/native-patterns.json",
                "schemas/native-pattern-registry.schema.json",
            ),
            (
                "registry/qenterra-components.json",
                "schemas/qenterra-component-registry.schema.json",
            ),
        ):
            with self.subTest(registry=registry_relative):
                schema_path = ROOT / schema_relative
                self.assertEqual(
                    validate_schema(load(registry_relative), load(schema_relative), schema_path),
                    [],
                )

    def test_icon_registry_contains_only_reusable_interface_roles(self) -> None:
        icons = load("registry/icons.json")["icons"]
        identifiers = [item["id"] for item in icons]
        self.assertEqual(len(identifiers), len(set(identifiers)))
        self.assertEqual(
            set(identifiers),
            {
                "accessibility",
                "search",
                "menu",
                "globe",
                "chevron",
                "add",
                "close",
                "delete",
                "success",
                "warning",
                "error",
                "information",
            },
        )


if __name__ == "__main__":
    unittest.main()
