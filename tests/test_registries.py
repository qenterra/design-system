from __future__ import annotations

import json
import re
import subprocess
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
            "registry/icon-sources.json",
            "registry/native-patterns.json",
            "registry/magic-ui.json",
            "registry/packages.json",
            "registry/qenterra-components.json",
            "registry/reui.json",
            "registry/shadcn-ui.json",
            "registry/uiable.json",
        ):
            with self.subTest(relative=relative):
                self.assertEqual(load(relative)["version"], VERSION)

    def test_component_delivery_claims_reference_registered_packages(self) -> None:
        package_ids = {item["id"] for item in load("registry/packages.json")["packages"]}
        components = load("registry/components.json")["components"]
        self.assertEqual(len({item["id"] for item in components}), len(components))

        delivered = {
            "favorite-control",
            "media-grid",
            "media-row",
            "media-shelf",
            "media-tile",
            "playback-indicator",
            "artwork-crop-surface",
            "artwork-haze",
            "artwork-mosaic",
            "artwork-placeholder",
            "artwork-surface",
            "button",
            "content-state-view",
            "card",
            "drop-zone",
            "field",
            "group",
            "icon-button",
            "interactive-row",
            "keycap",
            "navigation-rail",
            "page-header",
            "page-scroll-view",
            "flow-layout",
            "operation-state-view",
            "resizable-split-view",
            "design-separator",
            "settings-row",
            "settings-section",
            "settings-toggle-row",
            "sort-menu",
            "status-banner",
            "rename-alert",
            "tabs",
            "workspace-pane-header",
            "about-page",
            "about-resource-row",
        }
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
        supported_products = {"QenTerraComponents", "QenTerraMediaComponents"}
        self.assertLessEqual(
            {item["deliveryProduct"] for item in registry["components"]},
            supported_products,
        )
        paths = [item["sourcePath"] for item in registry["components"]]
        self.assertEqual(len(paths), len(set(paths)))
        self.assertEqual(
            set(paths),
            {
                "packages/Sources/QenTerra/Components/Containers/CardContainer.swift",
                "packages/Sources/QenTerra/Components/Containers/SettingsRow.swift",
                "packages/Sources/QenTerra/Components/Containers/SettingsSection.swift",
                "packages/Sources/QenTerra/Components/Containers/SettingsToggleRow.swift",
                "packages/Sources/QenTerra/Components/Controls/DesignButtonStyle.swift",
                "packages/Sources/QenTerra/Components/Controls/IconActionButton.swift",
                "packages/Sources/QenTerra/Components/Controls/RowActionButtonStyle.swift",
                "packages/Sources/QenTerra/Components/Feedback/ContentStateView.swift",
                "packages/Sources/QenTerra/Components/Feedback/DropZone.swift",
                "packages/Sources/QenTerra/Components/Feedback/OperationStateView.swift",
                "packages/Sources/QenTerra/Components/Feedback/StatusBanner.swift",
                "packages/Sources/QenTerra/Components/Layout/DesignSeparator.swift",
                "packages/Sources/QenTerra/Components/Layout/FlowLayout.swift",
                "packages/Sources/QenTerra/Components/Layout/PageHeader.swift",
                "packages/Sources/QenTerra/Components/Layout/PageScrollView.swift",
                "packages/Sources/QenTerra/Components/Layout/ResizableSplitView.swift",
                "packages/Sources/QenTerra/Components/Layout/WorkspacePaneHeader.swift",
                "packages/Sources/QenTerra/Components/Navigation/NavigationRail.swift",
                "packages/Sources/QenTerra/Components/Navigation/TabStrip.swift",
                "packages/Sources/QenTerra/Components/Overlays/Keycap.swift",
                "packages/Sources/QenTerra/Components/Overlays/RenameAlert.swift",
                "packages/Sources/QenTerra/Components/Overlays/SortMenu.swift",
                "packages/Sources/QenTerra/Components/About/AboutPage.swift",
                "packages/Sources/QenTerra/Components/About/AboutResourceRow.swift",
                "packages/Sources/QenTerra/Components/GroupContainer.swift",
                "packages/Sources/QenTerra/Components/InteractiveRowSurface.swift",
                "packages/Sources/QenTerra/Components/PrimaryButtonStyle.swift",
                "packages/Sources/QenTerra/MediaComponents/Artwork/ArtworkCropSurface.swift",
                "packages/Sources/QenTerra/MediaComponents/Artwork/ArtworkHaze.swift",
                "packages/Sources/QenTerra/MediaComponents/Artwork/ArtworkMosaic.swift",
                "packages/Sources/QenTerra/MediaComponents/Artwork/ArtworkPalette.swift",
                "packages/Sources/QenTerra/MediaComponents/Artwork/ArtworkPlaceholder.swift",
                "packages/Sources/QenTerra/MediaComponents/Artwork/ArtworkPresentationState.swift",
                "packages/Sources/QenTerra/MediaComponents/Artwork/ArtworkSurface.swift",
                "packages/Sources/QenTerra/MediaComponents/Collections/MediaGrid.swift",
                "packages/Sources/QenTerra/MediaComponents/Collections/MediaItemPresentation.swift",
                "packages/Sources/QenTerra/MediaComponents/Collections/MediaRow.swift",
                "packages/Sources/QenTerra/MediaComponents/Collections/MediaShelf.swift",
                "packages/Sources/QenTerra/MediaComponents/Collections/MediaTile.swift",
                "packages/Sources/QenTerra/MediaComponents/Controls/FavoriteControl.swift",
                "packages/Sources/QenTerra/MediaComponents/Controls/PlaybackIndicator.swift",
            },
        )
        for relative in paths:
            self.assertTrue((ROOT / relative).is_file(), relative)
        for component in registry["components"]:
            expected_product = (
                "QenTerraMediaComponents"
                if "/MediaComponents/" in component["sourcePath"]
                else "QenTerraComponents"
            )
            self.assertEqual(component["deliveryProduct"], expected_product)

    def test_migration_components_are_planned_for_2_0_0_and_absent_from_v1_0_1(self) -> None:
        migration_ids = {
            "favorite-control", "media-grid", "media-row", "media-shelf",
            "media-tile", "playback-indicator",
            "artwork-crop-surface", "artwork-haze", "artwork-mosaic",
            "artwork-placeholder", "artwork-surface",
            "card", "settings-section", "settings-row", "settings-toggle-row",
            "page-header", "page-scroll-view", "flow-layout", "resizable-split-view",
            "design-separator", "workspace-pane-header", "navigation-rail", "sort-menu",
            "rename-alert", "keycap", "content-state-view", "status-banner", "drop-zone",
            "operation-state-view", "about-page-configuration", "about-page", "about-resource-row",
        }
        current = {item["id"]: item for item in load("registry/components.json")["components"]}
        self.assertTrue(migration_ids.issubset(current))
        for component_id in migration_ids:
            self.assertEqual(current[component_id]["lifecycle"]["introduced"], "2.0.0")

        tagged = json.loads(
            subprocess.check_output(
                ["git", "show", "v1.0.1:registry/components.json"],
                cwd=ROOT,
                text=True,
            )
        )
        tagged_ids = {item["id"] for item in tagged["components"]}
        self.assertTrue(migration_ids.isdisjoint(tagged_ids))

    def test_media_collection_family_is_closed_over_public_swift_delivery(self) -> None:
        package = next(
            item
            for item in load("registry/packages.json")["packages"]
            if item["id"] == "swift-components"
        )
        collection_sources = {
            "packages/Sources/QenTerra/MediaComponents/Collections/MediaGrid.swift",
            "packages/Sources/QenTerra/MediaComponents/Collections/MediaItemPresentation.swift",
            "packages/Sources/QenTerra/MediaComponents/Collections/MediaRow.swift",
            "packages/Sources/QenTerra/MediaComponents/Collections/MediaShelf.swift",
            "packages/Sources/QenTerra/MediaComponents/Collections/MediaTile.swift",
            "packages/Sources/QenTerra/MediaComponents/Controls/FavoriteControl.swift",
            "packages/Sources/QenTerra/MediaComponents/Controls/PlaybackIndicator.swift",
        }
        self.assertTrue(collection_sources.issubset(set(package["publicPaths"])))
        self.assertIn(
            "packages/Tests/QenTerraMediaComponentsTests/MediaCollectionTests.swift",
            package["tests"],
        )
        self.assertIn("media-collections", package["capabilities"])

        maintained = load("registry/qenterra-components.json")["components"]
        maintained_by_path = {item["sourcePath"]: item for item in maintained}
        self.assertTrue(collection_sources.issubset(maintained_by_path))
        for source in collection_sources:
            self.assertEqual(
                maintained_by_path[source]["deliveryProduct"],
                "QenTerraMediaComponents",
            )
        self.assertIn(
            "MediaAccessoryInteractionContext",
            maintained_by_path[
                "packages/Sources/QenTerra/MediaComponents/Collections/MediaItemPresentation.swift"
            ]["publicSymbols"],
        )
        self.assertIn(
            "InteractiveRowCornerRadius",
            maintained_by_path[
                "packages/Sources/QenTerra/Components/InteractiveRowSurface.swift"
            ]["publicSymbols"],
        )
        manifest_paths = {
            f"packages/{item['sourcePath']}"
            for item in load("packages/Sources/QenTerra/manifest.json")["components"]
        }
        self.assertTrue(collection_sources.issubset(manifest_paths))

    def test_artwork_family_is_closed_over_public_swift_delivery(self) -> None:
        package = next(
            item
            for item in load("registry/packages.json")["packages"]
            if item["id"] == "swift-components"
        )
        artwork_sources = {
            "packages/Sources/QenTerra/MediaComponents/Artwork/ArtworkCropSurface.swift",
            "packages/Sources/QenTerra/MediaComponents/Artwork/ArtworkHaze.swift",
            "packages/Sources/QenTerra/MediaComponents/Artwork/ArtworkMosaic.swift",
            "packages/Sources/QenTerra/MediaComponents/Artwork/ArtworkPalette.swift",
            "packages/Sources/QenTerra/MediaComponents/Artwork/ArtworkPlaceholder.swift",
            "packages/Sources/QenTerra/MediaComponents/Artwork/ArtworkPresentationState.swift",
            "packages/Sources/QenTerra/MediaComponents/Artwork/ArtworkSurface.swift",
        }
        self.assertLessEqual(artwork_sources, set(package["publicPaths"]))
        self.assertIn(
            "packages/Tests/QenTerraMediaComponentsTests/ArtworkComponentTests.swift",
            package["publicPaths"],
        )
        self.assertIn(
            "packages/Tests/QenTerraMediaComponentsTests/ArtworkComponentTests.swift",
            package["tests"],
        )
        self.assertIn("artwork-presentation", package["capabilities"])

    def test_artwork_sources_enforce_the_presentation_only_boundary(self) -> None:
        source_root = ROOT / "packages/Sources/QenTerra/MediaComponents/Artwork"
        expected = {
            "ArtworkCropSurface.swift",
            "ArtworkHaze.swift",
            "ArtworkMosaic.swift",
            "ArtworkPalette.swift",
            "ArtworkPlaceholder.swift",
            "ArtworkPresentationState.swift",
            "ArtworkSurface.swift",
        }
        self.assertEqual({path.name for path in source_root.glob("*.swift")}, expected)
        forbidden_imports = {"ImageIO", "CoreImage"}
        forbidden_symbols = {
            "ArtworkAsset",
            "ArtworkImageCache",
            "CadenceAppModel",
            "Data",
            "Task",
            "URL",
        }
        for path in source_root.glob("*.swift"):
            source = path.read_text(encoding="utf-8")
            imports = set(re.findall(r"^import\s+(\w+)", source, flags=re.MULTILINE))
            symbols = set(re.findall(r"\b[A-Za-z_]\w*\b", source))
            self.assertTrue(forbidden_imports.isdisjoint(imports), path.name)
            self.assertTrue(forbidden_symbols.isdisjoint(symbols), path.name)

    def test_settings_toggle_category_agrees_across_component_registries(self) -> None:
        maintained = next(
            component
            for component in load("registry/qenterra-components.json")["components"]
            if component["id"] == "settings-toggle-row"
        )
        contract = next(
            component
            for component in load("registry/components.json")["components"]
            if component["id"] == "settings-toggle-row"
        )
        self.assertEqual(maintained["category"], contract["category"])

    def test_root_and_public_manifests_deliver_media_components(self) -> None:
        for relative in ("Package.swift", "packages/Package.swift"):
            with self.subTest(relative=relative):
                manifest = (ROOT / relative).read_text(encoding="utf-8")
                self.assertIn('.library(name: "QenTerraMediaComponents"', manifest)
                self.assertIn('name: "QenTerraMediaComponents"', manifest)

    def test_source_catalog_registries_match_their_schemas(self) -> None:
        for registry_relative, schema_relative in (
            (
                "registry/icon-sources.json",
                "schemas/icon-source-registry.schema.json",
            ),
            (
                "registry/native-patterns.json",
                "schemas/native-pattern-registry.schema.json",
            ),
            (
                "registry/qenterra-components.json",
                "schemas/qenterra-component-registry.schema.json",
            ),
            (
                "registry/magic-ui.json",
                "schemas/magic-ui-registry.schema.json",
            ),
            (
                "registry/shadcn-ui.json",
                "schemas/shadcn-ui-registry.schema.json",
            ),
            (
                "registry/uiable.json",
                "schemas/uiable-registry.schema.json",
            ),
            (
                "registry/reui.json",
                "schemas/reui-registry.schema.json",
            ),
        ):
            with self.subTest(registry=registry_relative):
                schema_path = ROOT / schema_relative
                self.assertEqual(
                    validate_schema(load(registry_relative), load(schema_relative), schema_path),
                    [],
                )

    def test_qenterra_component_schema_binds_product_to_source_root(self) -> None:
        registry = load("registry/qenterra-components.json")
        schema = load("schemas/qenterra-component-registry.schema.json")
        schema_path = ROOT / "schemas/qenterra-component-registry.schema.json"
        crossed_products = (
            (
                "packages/Sources/QenTerra/MediaComponents/MediaComponent.swift",
                "QenTerraComponents",
            ),
            (
                "packages/Sources/QenTerra/Components/CoreComponent.swift",
                "QenTerraMediaComponents",
            ),
        )
        for source_path, delivery_product in crossed_products:
            with self.subTest(source_path=source_path, delivery_product=delivery_product):
                invalid = json.loads(json.dumps(registry))
                invalid["components"][0]["sourcePath"] = source_path
                invalid["components"][0]["deliveryProduct"] = delivery_product
                self.assertTrue(
                    validate_schema(invalid, schema, schema_path),
                    "schema accepted a crossed delivery product and source root",
                )

    def test_icon_source_registry_requires_one_family_per_project(self) -> None:
        registry = load("registry/icon-sources.json")
        self.assertEqual(
            [catalog["id"] for catalog in registry["catalogs"]],
            ["bootstrap-icons", "iconoir", "phosphor-icons", "tabler-icons"],
        )
        self.assertEqual(registry["selectionPolicy"]["projectFamilyLimit"], 1)
        self.assertTrue(registry["selectionPolicy"]["searchBeforeCreate"])

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
