from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class DesignSystemV5ContractTests(unittest.TestCase):
    def test_root_skill_is_the_agent_entrypoint(self) -> None:
        skill = ROOT / "SKILL.md"
        self.assertTrue(skill.is_file(), "SKILL.md must exist at the repository root")
        content = skill.read_text(encoding="utf-8")
        for required in (
            "# Design System",
            "consume",
            "evolve",
            "audit",
            "Noetic",
            "design-system-consumer.json",
            "design-system-exceptions.json",
        ):
            self.assertIn(required, content)

    def test_major_release_and_public_packages_are_aligned(self) -> None:
        version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
        self.assertEqual(version, "5.4.0")
        npm = json.loads(
            (ROOT / "packages/npm/design-tokens/package.json").read_text(
                encoding="utf-8"
            )
        )
        self.assertEqual(npm["name"], "@qenterra/design-tokens")
        self.assertEqual(npm["version"], version)
        self.assertEqual(npm["license"], "Apache-2.0")
        self.assertEqual(npm["publishConfig"], {"access": "public"})
        self.assertFalse(npm.get("private", False))

    def test_public_notice_requires_qenterra_attribution(self) -> None:
        notice_path = ROOT / "packages/NOTICE"
        self.assertTrue(notice_path.is_file(), "public NOTICE is missing")
        notice = notice_path.read_text(encoding="utf-8")
        self.assertIn("Design System", notice)
        self.assertIn("Copyright © 2026 Nikita Melnychenko", notice)
        self.assertIn("QenTerra", notice)

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
