from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class DesignSystemV1ContractTests(unittest.TestCase):
    def test_repository_contains_no_agent_entrypoint(self) -> None:
        self.assertFalse((ROOT / "SKILL.md").exists())
        self.assertFalse((ROOT / "AGENTS.md").exists())
        contract = json.loads(
            (ROOT / ".github/qenterra-repository.json").read_text(encoding="utf-8")
        )
        self.assertFalse(contract["agent_control_plane"])

    def test_public_1_0_baseline_and_packages_are_aligned(self) -> None:
        version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
        self.assertEqual(version, "1.0.0")
        npm = json.loads(
            (ROOT / "packages/npm/design-tokens/package.json").read_text(
                encoding="utf-8"
            )
        )
        self.assertEqual(npm["name"], "@qenterra/design-tokens")
        self.assertEqual(npm["version"], version)
        self.assertEqual(npm["license"], "Apache-2.0")
        self.assertEqual(
            npm["repository"],
            {
                "type": "git",
                "url": "git+https://github.com/qenterra/design-system.git",
                "directory": "packages/npm/design-tokens",
            },
        )
        self.assertEqual(npm["publishConfig"], {"access": "public"})
        self.assertFalse(npm.get("private", False))
        self.assertTrue((ROOT / "Package.swift").is_file())

    def test_public_npm_scope_uses_npmjs(self) -> None:
        lines = [
            line.strip()
            for line in (ROOT / ".npmrc").read_text(encoding="utf-8").splitlines()
            if line.strip() and not line.lstrip().startswith("#")
        ]
        self.assertIn("@qenterra:registry=https://registry.npmjs.org", lines)
        self.assertNotIn("@qenterra:registry=https://npm.pkg.github.com", lines)

    def test_first_party_material_uses_apache_with_notice(self) -> None:
        root_license = (ROOT / "LICENSE").read_text(encoding="utf-8")
        package_license = (ROOT / "packages/LICENSE").read_text(encoding="utf-8")
        self.assertIn("Apache License", root_license)
        self.assertEqual(root_license, package_license)
        for relative in ("NOTICE", "packages/NOTICE", "packages/npm/design-tokens/NOTICE"):
            notice = (ROOT / relative).read_text(encoding="utf-8")
            self.assertIn("Copyright", notice)
            self.assertIn("Apache-2.0", notice)

    def test_removed_subsystems_are_absent(self) -> None:
        for relative in ("src", "dist", "output"):
            self.assertFalse((ROOT / relative).exists(), relative)
        forbidden_names = {
            "EMAIL.md",
            "EMAIL.ru.md",
            "email-composer.js",
            "email-renderer.js",
            "test_email_templates.py",
            "email_templates.py",
            "contact-channels.json",
            "contact-channels.schema.json",
        }
        found = {
            path.name
            for path in ROOT.rglob("*")
            if path.is_file() and ".git" not in path.parts
        }
        self.assertFalse(forbidden_names & found)

    def test_nyx_is_the_only_brand_asset_family(self) -> None:
        brand = ROOT / "assets/brand"
        unexpected = sorted(
            path.relative_to(brand).as_posix()
            for path in brand.iterdir()
            if path.name not in {"manifest.json", "nyx"}
        )
        self.assertEqual(unexpected, [])

    def test_public_tree_excludes_private_material(self) -> None:
        public = ROOT / "packages"
        self.assertTrue(public.is_dir(), "public export tree is missing")
        forbidden_parts = {
            "assets",
            "templates",
            "noetic",
            ".agent",
            ".agents",
            ".claude",
            ".codex",
            ".copilot",
            ".cursor",
            ".skills",
            ".superpowers",
        }
        forbidden_names = {
            "AGENTS.md",
            "SKILL.md",
            "CLAUDE.md",
            "GEMINI.md",
            "COPILOT.md",
            ".mcp.json",
            "mcp.json",
        }
        for path in public.rglob("*"):
            if not path.is_file():
                continue
            relative = path.relative_to(public)
            self.assertFalse(forbidden_parts.intersection(relative.parts), relative)
            self.assertNotIn(path.name, forbidden_names)
            self.assertNotIn("design-system-consumer", path.name)
            self.assertNotIn("design-system-exceptions", path.name)


if __name__ == "__main__":
    unittest.main()
